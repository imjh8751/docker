#!/bin/bash

# Dockerfile로 이미지 빌드
docker build -t nginx-app .
#podman build -t nginx-app .

# 컨테이너 실행
docker run -d -p 8180:80 --name nginx-app nginx-app
#podman run -d -p 8180:80 --name nginx-app nginx-app
