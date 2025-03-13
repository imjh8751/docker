#!/bin/bash

# https://github.com/Arachni/arachni/releases/download/

# 방법 1 : 변수 지
docker build --build-arg VERSION=1.6.1.3 --build-arg WEB_VERSION=0.6.1.1 -t arachni .

# 방법 2 : 기본 값
# docker-compose build

# 방법 3 : docker-compose 수행
docker compose up -d web

# 계정
admin@admin.admin / administrator
