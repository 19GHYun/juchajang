# 주차장 번호판 인식 시스템 배포 가이드

## 📋 시스템 구성
- **React 웹앱**: 주차장 번호판 인식 인터페이스
- **Roboflow 추론 서버**: 번호판 좌표 감지 (Docker)
- **Spring 백엔드**: OCR 및 주차 데이터 처리 (기존 서버)

## 🚀 빠른 배포 (권장)

### 1. Docker Compose 방식 (간단함)
```bash
# 저장소 클론
git clone <your-repo-url>
cd plate_pay-web_test

# 실행 권한 부여
chmod +x deploy-simple.sh

# 배포 실행
./deploy-simple.sh your-domain.com
```

### 2. 전체 시스템 배포 방식 (고급)
```bash
# 실행 권한 부여
chmod +x deploy-server.sh

# 배포 실행
./deploy-server.sh your-domain.com
```

## 📦 배포 구성 요소

### 1. Docker 컨테이너
- **roboflow-inference-prod**: 번호판 좌표 감지 AI 서버
  - 포트: 127.0.0.1:9001 (내부 접근만)
  - 메모리 제한: 2GB
  - 자동 재시작 활성화

### 2. Nginx 설정
- **HTTPS 강제 리다이렉트**: HTTP → HTTPS
- **정적 파일 서빙**: React 빌드 파일
- **API 프록시**:
  - `/infer/*` → Roboflow 서버 (내부)
  - `/api/*` → Spring 백엔드 (외부)
- **SSL 인증서**: Let's Encrypt 자동 발급

### 3. 보안 설정
- Roboflow 포트 9001 외부 차단
- 방화벽 설정 (SSH, HTTP, HTTPS만 허용)
- 보안 헤더 추가
- CORS 설정

## 🔧 환경 설정

### 필수 환경 변수 (.env.production)
```bash
REACT_APP_ENV=production
REACT_APP_ROBOFLOW_API_URL=/infer
REACT_APP_SPRING_API_URL=/api
REACT_APP_ROBOFLOW_MODEL_ID=yolov8-anpr/1
REACT_APP_ROBOFLOW_API_KEY=IMv3ZjNtl2lvMVUKOZCr
```

### 주차장 설정
```bash
REACT_APP_DEFAULT_PARKING_LOT_ID=1
REACT_APP_DEFAULT_PARKING_ACTION=enter
```

## 📝 사용법

### 개발자용 로컬 테스트
```bash
# 의존성 설치
npm install

# 로컬 Roboflow 서버 시작
docker run -d --rm -p 9001:9001 -e ALLOW_ORIGINS="*" -e CORS_ALLOW_ORIGINS="*" roboflow/roboflow-inference-server-cpu

# 개발 서버 시작
npm start
```

### 프로덕션 빌드
```bash
# 빌드
npm run build

# 빌드 파일 확인
ls -la build/
```

## 🔄 관리 명령어

### Docker Compose 방식
```bash
# 서비스 상태 확인
sudo docker-compose ps

# 로그 확인
sudo docker-compose logs -f

# 서비스 재시작
sudo docker-compose restart

# 서비스 중지
sudo docker-compose down

# 서비스 시작
sudo docker-compose up -d
```

### SystemD 방식 (deploy-server.sh 사용 시)
```bash
# Roboflow 서비스 상태
sudo systemctl status roboflow-inference

# Roboflow 서비스 재시작
sudo systemctl restart roboflow-inference

# Docker 로그 확인
sudo docker logs -f roboflow-inference-prod

# Nginx 재시작
sudo systemctl restart nginx
```

## 🩺 헬스체크 및 모니터링

### API 엔드포인트 테스트
```bash
# Roboflow 서버 상태
curl http://localhost:9001/

# 웹사이트 헬스체크
curl https://your-domain.com/health

# Spring 백엔드 연결 테스트
curl https://j13c108.p.ssafy.io/api/v1/plates/health
```

### 로그 확인
```bash
# Nginx 로그
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Docker 로그
sudo docker logs -f roboflow-inference-prod
```

## 🔒 보안 고려사항

1. **방화벽 설정**: UFW로 필요한 포트만 열기
2. **SSL 인증서**: Let's Encrypt 자동 갱신 설정
3. **API 키 보안**: 환경 변수로 관리
4. **내부 접근 제한**: Roboflow 서버는 127.0.0.1만 접근 허용

## 🛠️ 트러블슈팅

### 일반적인 문제
1. **Roboflow 서버 연결 실패**
   - Docker 컨테이너 상태 확인: `sudo docker ps`
   - 포트 확인: `sudo netstat -tlnp | grep 9001`

2. **SSL 인증서 문제**
   - 인증서 상태: `sudo certbot certificates`
   - 수동 갱신: `sudo certbot renew`

3. **React 앱 로딩 실패**
   - 빌드 파일 확인: `ls -la /var/www/html/`
   - Nginx 설정 테스트: `sudo nginx -t`

### 로그 확인 명령어
```bash
# 모든 서비스 로그 한번에 보기
sudo docker-compose logs
sudo systemctl status nginx roboflow-inference
sudo tail -f /var/log/nginx/error.log
```

## 📞 지원

문제가 발생하면 다음 정보와 함께 문의:
- 배포 방식 (Docker Compose / SystemD)
- 오류 메시지
- 관련 로그
- 서버 환경 (Ubuntu 버전, Docker 버전 등)