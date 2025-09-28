# Railway용 Roboflow 서버 Dockerfile
FROM roboflow/roboflow-inference-server-cpu:latest

# 환경 변수 설정
ENV ALLOW_ORIGINS=*
ENV CORS_ALLOW_ORIGINS=*
ENV PORT=9001
ENV ROBOFLOW_API_KEY=IMv3ZjNtl2lvMVUKOZCr

# 포트 노출
EXPOSE 9001

# Railway PORT 환경변수 사용 (Railway가 자동 설정)
CMD ["sh", "-c", "python -m inference --host 0.0.0.0 --port ${PORT:-9001}"]