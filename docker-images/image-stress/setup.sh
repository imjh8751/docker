# Dockerfile로 이미지 빌드
docker build -t stress-test-app .
#podman build -t stress-test-app .

# 컨테이너 실행
#docker run -d -p 8080:8080 stress-test-app
#podman run -d -p 8080:8080 stress-test-app

# OOM 발생 제한 필요하다면 Docker 실행 시 메모리 제한을 걸어 OOM을 더 빨리 발생시킴
docker run -d -p 8880:8080 --memory=512m --name stress-test-app stress-test-app
#podman run -d -p 8880:8080 --memory=512m --name stress-test-app stress-test-app
