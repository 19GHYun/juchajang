#!/bin/bash

# 🚀 간단한 배포 스크립트 (Docker Compose 사용)
# 사용법: chmod +x deploy-simple.sh && ./deploy-simple.sh your-domain.com

if [ -z "$1" ]; then
    echo "❌ 도메인을 입력해주세요!"
    echo "사용법: ./deploy-simple.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo "🚀 주차장 시스템 배포 시작 (Docker Compose 방식)..."
echo "📍 도메인: $DOMAIN"

# 환경 변수 설정
export DOMAIN_URL="https://$DOMAIN"

# 1단계: 시스템 업데이트 및 Docker 설치
echo "📦 시스템 업데이트 및 Docker 설치..."
sudo apt update
sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 2단계: React 앱 빌드
echo "⚛️ React 앱 빌드..."
npm install
npm run build

# 3단계: SSL 인증서 발급 (먼저)
echo "🔐 SSL 인증서 발급..."

# 임시 nginx 설정
sudo tee /etc/nginx/sites-available/temp-$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/temp-$DOMAIN /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# certbot으로 SSL 인증서 발급
sudo certbot certonly --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# 4단계: nginx 설정 업데이트 (SSL 경로 포함)
echo "🌐 nginx 설정 업데이트..."
sed -i "s|ssl_certificate /etc/letsencrypt/live/your-domain/|ssl_certificate /etc/letsencrypt/live/$DOMAIN/|g" nginx.conf
sed -i "s|ssl_private_key /etc/letsencrypt/live/your-domain/|ssl_private_key /etc/letsencrypt/live/$DOMAIN/|g" nginx.conf

# 5단계: Docker Compose로 서비스 시작
echo "🐳 Docker Compose로 서비스 시작..."

# 기존 컨테이너 정리
sudo docker-compose down 2>/dev/null || true

# 새 컨테이너 시작
sudo docker-compose up -d

# 6단계: 서비스 상태 확인
echo "📊 서비스 상태 확인..."
sleep 10

echo "== Docker 컨테이너 상태 =="
sudo docker-compose ps

echo "== 포트 확인 =="
sudo netstat -tlnp | grep -E ':(80|443|9001)'

# 7단계: 헬스체크
echo "🩺 헬스체크..."
sleep 5

echo "Roboflow API 테스트:"
if curl -s http://localhost:9001/ | grep -q "FastAPI"; then
    echo "✅ Roboflow 서버 정상 작동"
else
    echo "❌ Roboflow 서버 문제 발생"
    sudo docker-compose logs roboflow-inference
fi

echo "웹사이트 테스트:"
if curl -s -k https://$DOMAIN/health | grep -q "healthy"; then
    echo "✅ 웹사이트 정상 작동"
else
    echo "❌ 웹사이트 문제 발생"
    sudo docker-compose logs nginx
fi

echo ""
echo "🎉 배포 완료!"
echo "📍 사이트: https://$DOMAIN"
echo ""
echo "🔧 관리 명령어:"
echo "- 서비스 재시작: sudo docker-compose restart"
echo "- 로그 확인: sudo docker-compose logs -f"
echo "- 서비스 중지: sudo docker-compose down"
echo "- SSL 갱신: sudo certbot renew"