# 베이스 이미지로 Node.js 사용
FROM node:16

# 작업 디렉토리 설정
WORKDIR /usr/src/app

# 패키지 파일 복사 및 설치
COPY package*.json ./
RUN npm install

# 애플리케이션 소스 복사
COPY . .

# 애플리케이션 포트 설정
EXPOSE 3000

# 애플리케이션 실행 명령어
CMD ["node", "app.js"]
