# 기본 Node.js 이미지 사용
FROM node:22-alpine

# 작업 디렉토리 설정
WORKDIR /app

# package.json과 package-lock.json 복사 (캐싱 활용을 위해)
COPY package*.json ./

# 의존성 패키지 설치
RUN npm install

# 소스 코드 복사
COPY . .

# public 디렉토리 생성 (없을 경우)
RUN mkdir -p public

# 필요한 포트 노출 (Node.js 서버 두 개가 사용하는 포트)
EXPOSE 3000 3001

# 두 서버를 동시에 실행
CMD ["npm", "run", "start-both"]
