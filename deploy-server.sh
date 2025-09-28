#!/bin/bash

# 🚀 번호판 인식 웹 서버 배포 스크립트
# 사용법: chmod +x deploy-server.sh && ./deploy-server.sh your-domain.com

if [ -z "$1" ]; then
    echo "❌ 도메인을 입력해주세요!"
    echo "사용법: ./deploy-server.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo "🚀 번호판 인식 웹 서버 배포 시작..."
echo "📍 도메인: $DOMAIN"

# 1단계: 시스템 업데이트 및 Docker 설치
echo "📦 시스템 업데이트 및 Docker 설치..."
sudo apt update
sudo apt install -y docker.io nginx certbot python3-certbot-nginx

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 2단계: Roboflow Docker 컨테이너 배포
echo "🐳 Roboflow Docker 컨테이너 배포..."

# 기존 컨테이너 정리
sudo docker stop roboflow-inference-prod 2>/dev/null || true
sudo docker rm roboflow-inference-prod 2>/dev/null || true

# 새 컨테이너 실행 (내부 접근만 허용)
sudo docker run -d \
  --name roboflow-inference-prod \
  --restart unless-stopped \
  --memory="2g" \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -p 127.0.0.1:9001:9001 \
  -e ALLOW_ORIGINS="https://$DOMAIN" \
  -e CORS_ALLOW_ORIGINS="https://$DOMAIN" \
  roboflow/roboflow-inference-server-cpu

echo "⏳ Docker 컨테이너 시작 대기..."
sleep 10

# 컨테이너 상태 확인
if sudo docker ps | grep -q roboflow-inference-prod; then
    echo "✅ Roboflow Docker 컨테이너 실행 성공!"
else
    echo "❌ Docker 컨테이너 실행 실패!"
    sudo docker logs roboflow-inference-prod
    exit 1
fi

# 3단계: systemd 서비스 등록
echo "⚙️ systemd 서비스 등록..."
sudo tee /etc/systemd/system/roboflow-inference.service << EOF
[Unit]
Description=Roboflow Inference Server for License Plate Recognition
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker stop roboflow-inference-prod
ExecStartPre=-/usr/bin/docker rm roboflow-inference-prod
ExecStart=/usr/bin/docker run -d \\
  --name roboflow-inference-prod \\
  --restart unless-stopped \\
  --memory="2g" \\
  --log-driver json-file \\
  --log-opt max-size=10m \\
  --log-opt max-file=3 \\
  -p 127.0.0.1:9001:9001 \\
  -e ALLOW_ORIGINS="https://$DOMAIN" \\
  -e CORS_ALLOW_ORIGINS="https://$DOMAIN" \\
  roboflow/roboflow-inference-server-cpu
ExecStop=/usr/bin/docker stop roboflow-inference-prod
ExecStopPost=/usr/bin/docker rm roboflow-inference-prod

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable roboflow-inference

# 4단계: Nginx 설정
echo "🌐 Nginx 설정..."

# 기본 사이트 비활성화
sudo rm -f /etc/nginx/sites-enabled/default

# 새 사이트 설정
sudo tee /etc/nginx/sites-available/$DOMAIN << EOF
# HTTP -> HTTPS 리다이렉트
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS 서버
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL 인증서 (Let's Encrypt가 자동으로 설정)
    # ssl_certificate 및 ssl_private_key는 certbot이 자동 추가

    # React 정적 파일 서빙
    location / {
        root /var/www/html;
        try_files \$uri \$uri/ /index.html;
        index index.html;

        # 캐싱 설정
        location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Roboflow API 프록시 (내부 접근만)
    location /infer/ {
        proxy_pass http://127.0.0.1:9001/infer/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS 헤더
        add_header Access-Control-Allow-Origin "https://$DOMAIN" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

        # OPTIONS 요청 처리
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://$DOMAIN";
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }

        # 타임아웃 설정 (AI 추론 시간 고려)
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Spring API 프록시 (기존 백엔드)
    location /api/ {
        proxy_pass https://j13c108.p.ssafy.io/api/;
        proxy_set_header Host j13c108.p.ssafy.io;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 타임아웃 설정
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 보안 헤더
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip 압축
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# 사이트 활성화
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# 5단계: 방화벽 설정
echo "🔒 방화벽 설정..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw deny 9001  # Roboflow 포트 직접 접근 차단

# 6단계: 웹 디렉토리 준비
echo "📁 웹 디렉토리 준비..."
sudo mkdir -p /var/www/html
sudo chown -R \$USER:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 임시 index.html 생성
sudo tee /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>번호판 인식 시스템 배포 중...</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>🚗 번호판 인식 시스템</h1>
    <p>배포가 진행 중입니다. React 앱 빌드 후 업로드해주세요.</p>
</body>
</html>
EOF

# 7단계: SSL 인증서 발급
echo "🔐 SSL 인증서 발급..."
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
else
    echo "❌ Nginx 설정 오류!"
    sudo nginx -t
    exit 1
fi

# 8단계: 서비스 시작 및 확인
echo "🔄 서비스 시작 및 확인..."
sudo systemctl restart roboflow-inference
sudo systemctl restart nginx

# 상태 확인
echo "📊 서비스 상태 확인..."
echo "== Docker 컨테이너 상태 =="
sudo docker ps | grep roboflow

echo "== systemd 서비스 상태 =="
sudo systemctl status roboflow-inference --no-pager -l

echo "== Nginx 상태 =="
sudo systemctl status nginx --no-pager -l

echo "== 포트 확인 =="
sudo netstat -tlnp | grep -E ':(80|443|9001)'

# 헬스체크
echo "🩺 헬스체크..."
sleep 5

echo "Roboflow API 테스트:"
if curl -s http://127.0.0.1:9001/ | grep -q "FastAPI"; then
    echo "✅ Roboflow 서버 정상 작동"
else
    echo "❌ Roboflow 서버 문제 발생"
    sudo docker logs roboflow-inference-prod --tail 20
fi

echo ""
echo "🎉 배포 완료!"
echo "📍 사이트: https://$DOMAIN"
echo ""
echo "📋 다음 단계:"
echo "1. React 앱 빌드: npm run build"
echo "2. 빌드 파일 업로드: scp -r build/* user@server:/var/www/html/"
echo "3. 테스트: https://$DOMAIN"
echo ""
echo "🔧 관리 명령어:"
echo "- 서비스 재시작: sudo systemctl restart roboflow-inference"
echo "- 로그 확인: sudo docker logs -f roboflow-inference-prod"
echo "- SSL 갱신: sudo certbot renew"