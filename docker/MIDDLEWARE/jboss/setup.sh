#!/bin/bash

# 배포 스크립트

echo "JBoss WildFly 배포를 시작합니다..."

# 필수 디렉토리 생성
mkdir -p deployments config

# 애플리케이션 파일이 있으면 deployments 폴더로 복사
if ls *.war >/dev/null 2>&1; then
    echo "WAR 파일을 복사합니다..."
    cp *.war deployments/
fi

if ls *.ear >/dev/null 2>&1; then
    echo "EAR 파일을 복사합니다..."
    cp *.ear deployments/
fi

if ls *.jar >/dev/null 2>&1; then
    echo "JAR 파일을 복사합니다..."
    cp *.jar deployments/
fi

# Docker Compose 빌드 및 실행
echo "Docker 컨테이너를 빌드하고 실행합니다..."
docker compose down
docker compose up --build -d

echo "배포가 완료되었습니다."
echo "WildFly 관리 콘솔: http://localhost:9990"
echo "애플리케이션: http://localhost:8080"
echo ""
echo "로그 확인: docker compose logs -f jboss"
