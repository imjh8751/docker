# Alpine Linux 기반 Nginx 이미지 사용
FROM nginx:alpine

# 필요한 패키지 설치
RUN apk update && apk add --no-cache vim

# Nginx 설정 파일 복사
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

# 포트 노출
EXPOSE 80

# 시작 스크립트 복사 및 권한 부여 (필요한 경우)
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 컨테이너 시작 시 실행될 명령
CMD ["nginx", "-g", "daemon off;"]
