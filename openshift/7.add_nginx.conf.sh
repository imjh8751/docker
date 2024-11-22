#!/bin/bash

yum -y install nginx
NGINX_CONF="/etc/nginx/conf.d/default.conf"

cat <<EOF >> $NGINX_CONF

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

# nginx.conf 파일 경로 설정
CONFIG_FILE="/etc/nginx/nginx.conf"

# 80번 포트를 사용하는 server 블록 주석 처리
sudo sed -i '/server {/,/}/ {/listen 80;/,/}/ s/^/#/' "$CONFIG_FILE"

echo "Server configuration has been added to $NGINX_CONF"

# 폴더 생성
mkdir -p /usr/share/nginx/html/files

# 방화벽 중지
systemctl stop firewalld

# nginx 재기동
nginx -t
systemctl restart nginx
