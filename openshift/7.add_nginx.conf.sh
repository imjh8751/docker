#!/bin/bash

echo "▶️ 1. Nginx 설치를 시작합니다..."
yum -y install nginx

# 폴더 생성
mkdir -p /usr/share/nginx/html/files

echo "▶️ 2. 기존 80번 포트 충돌 방지 설정 중..."
# 위험한 블록 주석 처리 대신, 기본 설정 파일의 포트를 80에서 8081(미사용)로 밀어냅니다.
sed -i 's/listen       80;/listen       8081;/g' /etc/nginx/nginx.conf
sed -i 's/listen       \[::\]:80;/listen       \[::\]:8081;/g' /etc/nginx/nginx.conf

echo "▶️ 3. Ignition 배포용 8080 포트 가상 서버 설정 중..."
NGINX_CONF="/etc/nginx/conf.d/default.conf"

# >> 대신 > 를 사용하여 스크립트를 여러 번 실행해도 꼬이지 않게 합니다.
cat <<EOF > $NGINX_CONF
server {
    listen       8080;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html/files;
        index  index.html index.htm;
        autoindex on;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

echo "▶️ 4. 방화벽에 8080 포트를 개방합니다..."
# 방화벽을 끄지 않고 8080 포트만 안전하게 뚫어줍니다.
if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-port=8080/tcp
  firewall-cmd --reload
fi

echo "▶️ 5. Nginx 문법 검사 및 서비스 시작..."
nginx -t

# 에러가 없다면 재부팅 시에도 자동 실행되도록 enable 처리 후 시작
systemctl enable --now nginx
systemctl restart nginx

echo "✅ Nginx 설정이 완벽하게 끝났습니다! (http://192.168.0.69:8080 접속 확인)"
