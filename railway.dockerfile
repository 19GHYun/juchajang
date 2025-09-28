# Railway용 Roboflow 서버 Dockerfile
FROM roboflow/roboflow-inference-server-cpu:latest

# 환경 변수 설정
ENV ALLOW_ORIGINS=*
ENV CORS_ALLOW_ORIGINS=*
ENV ROBOFLOW_API_KEY=IMv3ZjNtl2lvMVUKOZCr

# Railway PORT 환경변수 사용 (Railway가 자동 설정하는 포트 사용)
CMD ["sh", "-c", "python -m inference --host 0.0.0.0 --port ${PORT:-8000}"]