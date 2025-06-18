# Node.js 18 Alpine 기반 이미지 사용
FROM node:18-alpine

# 네트워크 도구 설치 (traceroute, iputils)
RUN apk add --no-cache \
    traceroute \
    iputils \
    bind-tools

# 작업 디렉토리 설정
WORKDIR /app

# package.json과 package-lock.json 복사
COPY package*.json ./

# 의존성 설치
RUN npm ci --only=production

# 애플리케이션 소스 복사
COPY app.js .

# 포트 3333 노출
EXPOSE 3333

# 컨테이너 실행 시 애플리케이션 시작
CMD ["node", "app.js"]
