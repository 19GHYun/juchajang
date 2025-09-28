# 🆓 주차장 시스템 무료 배포 가이드

## 📋 무료 배포 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React 웹앱     │    │  Roboflow 서버   │    │  Spring 백엔드   │
│   (Vercel)      │───▶│   (Railway)     │    │   (기존 서버)    │
│   🆓 무료        │    │   🆓 무료        │    │   💰 유지       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Step 1: Roboflow 서버 배포 (Railway 추천)

### 1-1. Railway에서 배포하기 ⭐ 추천

1. **Railway 계정 생성**
   - [railway.app](https://railway.app) 접속
   - GitHub 계정으로 로그인

2. **새 프로젝트 생성**
   ```bash
   # GitHub 저장소와 연결
   - "New Project" → "Deploy from GitHub repo"
   - 본 저장소 선택
   ```

3. **서비스 설정**
   ```bash
   # Settings에서 설정:
   - Build Command: (비어두기)
   - Dockerfile Path: ./railway.dockerfile
   ```

4. **환경 변수 설정**
   ```bash
   ALLOW_ORIGINS=*
   CORS_ALLOW_ORIGINS=*
   PORT=9001
   ```

5. **배포 완료**
   - 자동으로 URL 생성됨: `https://your-app.railway.app`
   - 이 URL을 기록해둡니다

### 1-2. Render에서 배포하기 (대안)

1. **Render 계정 생성**
   - [render.com](https://render.com) 접속
   - GitHub 계정으로 로그인

2. **새 웹 서비스 생성**
   ```bash
   - "New" → "Web Service"
   - GitHub 저장소 연결
   - Docker 선택
   - Dockerfile: ./railway.dockerfile
   ```

3. **무료 플랜 선택**
   - Free tier 선택 (월 750시간 무료)

## 🚀 Step 2: React 웹앱 배포 (Vercel)

### 2-1. Vercel 설정 파일 수정

먼저 `vercel.json` 파일에서 Roboflow 서버 URL을 업데이트:

```json
{
  "routes": [
    {
      "src": "/infer/(.*)",
      "dest": "https://your-roboflow-app.railway.app/infer/$1"
    }
  ]
}
```

### 2-2. Vercel에서 배포하기

1. **Vercel 계정 생성**
   - [vercel.com](https://vercel.com) 접속
   - GitHub 계정으로 로그인

2. **프로젝트 배포**
   ```bash
   # 방법 1: 웹에서 배포
   - "New Project" 클릭
   - GitHub 저장소 선택
   - 자동 배포 시작

   # 방법 2: CLI로 배포
   npm i -g vercel
   vercel login
   vercel --prod
   ```

3. **환경 변수 설정**
   - Vercel 대시보드 → Settings → Environment Variables
   ```bash
   REACT_APP_ENV=production
   REACT_APP_ROBOFLOW_API_URL=/infer
   REACT_APP_SPRING_API_URL=/api
   ```

## 🚀 Step 3: 최종 설정

### 3-1. URL 업데이트
배포 완료 후 실제 URL들로 업데이트:

1. **vercel.json 수정**
   ```json
   {
     "routes": [
       {
         "src": "/infer/(.*)",
         "dest": "https://actual-roboflow-url.railway.app/infer/$1"
       }
     ]
   }
   ```

2. **재배포**
   ```bash
   git add .
   git commit -m "Update Roboflow URL"
   git push origin main
   # Vercel에서 자동 재배포됨
   ```

### 3-2. 테스트
1. **Roboflow 서버 테스트**
   ```bash
   curl https://your-roboflow-app.railway.app/
   # "FastAPI" 응답 확인
   ```

2. **React 앱 테스트**
   - Vercel URL 접속
   - 테스트 이미지 업로드해서 번호판 인식 테스트

## 💰 비용 및 제한사항

### Railway (Roboflow 서버)
- ✅ **무료**: 월 500시간 실행 시간
- ✅ **메모리**: 512MB RAM
- ✅ **트래픽**: 제한 없음
- ⚠️ **제한**: 30분 비활성 시 자동 슬립

### Vercel (React 웹앱)
- ✅ **무료**: 월 100GB 대역폭
- ✅ **빌드**: 월 6000분
- ✅ **도메인**: 무료 subdomain 제공
- ✅ **SSL**: 자동 HTTPS

### Spring 백엔드
- 💰 **기존 서버 유지** (이미 있음)

## 🔧 트러블슈팅

### 1. Railway 슬립 문제
```bash
# 해결책: Keep-alive 서비스 사용
# UptimeRobot 같은 무료 모니터링 서비스로 5분마다 ping
```

### 2. CORS 에러
```bash
# Railway 환경변수 확인:
ALLOW_ORIGINS=*
CORS_ALLOW_ORIGINS=*
```

### 3. Vercel 빌드 실패
```bash
# package.json scripts 확인:
"scripts": {
  "build": "react-scripts build"
}
```

## 🎯 최종 배포 순서

1. **Railway에 Roboflow 서버 배포** (10분)
2. **Railway URL 확인 및 기록**
3. **vercel.json에 Railway URL 업데이트**
4. **Vercel에 React 앱 배포** (5분)
5. **테스트 및 확인**

## 📞 지원

각 서비스별 지원:
- **Railway**: [railway.app/help](https://railway.app/help)
- **Vercel**: [vercel.com/docs](https://vercel.com/docs)
- **Render**: [render.com/docs](https://render.com/docs)

## 🎉 완료!

총 배포 시간: **약 15-20분**
총 비용: **$0 (완전 무료)** 🎉

이제 URL만 공유하면 누구나 주차장 번호판 인식 시스템을 사용할 수 있습니다!