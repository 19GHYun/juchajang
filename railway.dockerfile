# Railway용 Roboflow 서버 Dockerfile
FROM roboflow/roboflow-inference-server-cpu:latest

# 환경 변수 설정
ENV ALLOW_ORIGINS=*
ENV CORS_ALLOW_ORIGINS=*
ENV PORT=9001

# 포트 노출
EXPOSE 9001

# 서버 시작 (Railway는 자동으로 PORT 환경변수 설정)
CMD ["python", "-m", "inference", "--host", "0.0.0.0", "--port", "9001"]