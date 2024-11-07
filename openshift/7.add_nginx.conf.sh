#!/bin/bash

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

echo "Server configuration has been added to $NGINX_CONF"

# 폴더 생성
mkdir /usr/share/nginx/html/files

# 방화벽 중지
systemctl stop firewalld

# nginx 재기동
nginx -t
systemctl restart nginx
