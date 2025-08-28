#!/bin/bash

echo "WebSphere 설정 초기화 스크립트 (UID 1001, GID 0)"
echo "================================================"

# 호스트 디렉토리 생성 및 권한 설정
echo "1. 호스트 디렉토리 생성 및 권한 설정..."
mkdir -p ./websphere/{profiles,logs,config,installedApps,applications,deployedApps,backup,temp,wstemp,javacore,heapdump}

# 호스트에서 권한 설정 (UID 1001, GID 0)
echo "2. 디렉토리 권한 설정 (1001:0)..."
sudo chown -R 1001:0 ./websphere/ 2>/dev/null || {
    echo "Warning: sudo 권한이 없어 권한 설정을 건너뜁니다."
    echo "필요시 수동으로 실행: sudo chown -R 1001:0 ./websphere/"
}

sudo chmod -R 755 ./websphere/ 2>/dev/null || {
    echo "Warning: sudo 권한이 없어 권한 설정을 건너뜁니다."
    echo "필요시 수동으로 실행: sudo chmod -R 755 ./websphere/"
}

# WebSphere 컨테이너에서 호스트로 디렉토리 복사 스크립트
CONTAINER_NAME="websphere"
HOST_BASE_DIR="./websphere"

echo "WebSphere 디렉토리 복사 스크립트"
echo "==============================="
echo "컨테이너: $CONTAINER_NAME"
echo "호스트 기본 디렉토리: $HOST_BASE_DIR"
echo ""

# 컨테이너 실행 상태 확인
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Error: 컨테이너 '$CONTAINER_NAME'이 실행 중이지 않습니다."
    echo "다음 명령어로 컨테이너를 먼저 실행하세요:"
    echo "docker-compose up -d websphere"
    exit 1
fi

# 호스트 디렉토리 생성
echo "1. 호스트 디렉토리 생성..."
mkdir -p $HOST_BASE_DIR/{profiles,logs,config,installedApps,applications,deployedApps,backup,temp,wstemp,javacore,heapdump}

echo "2. WebSphere 주요 디렉토리 복사 시작..."

# WebSphere 주요 디렉토리들
echo "  - profiles 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/. $HOST_BASE_DIR/profiles/ 2>/dev/null || echo "    Warning: profiles 디렉토리 복사 실패 또는 비어있음"

echo "  - logs 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/logs/. $HOST_BASE_DIR/logs/ 2>/dev/null || echo "    Warning: logs 디렉토리 복사 실패 또는 비어있음"

echo "  - config 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/config/. $HOST_BASE_DIR/config/ 2>/dev/null || echo "    Warning: config 디렉토리 복사 실패 또는 비어있음"

echo "  - installedApps 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/installedApps/. $HOST_BASE_DIR/installedApps/ 2>/dev/null || echo "    Warning: installedApps 디렉토리 복사 실패 또는 비어있음"

echo "  - applications 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/applications/. $HOST_BASE_DIR/applications/ 2>/dev/null || echo "    Warning: applications 디렉토리 복사 실패 또는 비어있음"

echo "  - deployedApps 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/config/cells/DefaultCell01/applications/. $HOST_BASE_DIR/deployedApps/ 2>/dev/null || echo "    Warning: deployedApps 디렉토리 복사 실패 또는 비어있음"

# 백업 및 설정 파일들
echo "  - backup 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/backup/. $HOST_BASE_DIR/backup/ 2>/dev/null || echo "    Warning: backup 디렉토리 복사 실패 또는 비어있음"

echo "  - temp 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/temp/. $HOST_BASE_DIR/temp/ 2>/dev/null || echo "    Warning: temp 디렉토리 복사 실패 또는 비어있음"

echo "  - wstemp 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/wstemp/. $HOST_BASE_DIR/wstemp/ 2>/dev/null || echo "    Warning: wstemp 디렉토리 복사 실패 또는 비어있음"

# JVM 로그 및 덤프
echo "  - javacore 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/javacore/. $HOST_BASE_DIR/javacore/ 2>/dev/null || echo "    Warning: javacore 디렉토리 복사 실패 또는 비어있음"

echo "  - heapdump 복사..."
docker cp $CONTAINER_NAME:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/heapdump/. $HOST_BASE_DIR/heapdump/ 2>/dev/null || echo "    Warning: heapdump 디렉토리 복사 실패 또는 비어있음"

echo ""
echo "3. 권한 설정..."
# 복사된 파일들 권한 설정 (UID 1001, GID 0)
sudo chown -R 1001:0 $HOST_BASE_DIR/ 2>/dev/null || {
    echo "Warning: sudo 권한이 없어 권한 설정을 건너뜁니다."
    echo "필요시 수동으로 실행: sudo chown -R 1001:0 $HOST_BASE_DIR/"
}

sudo chmod -R 755 $HOST_BASE_DIR/ 2>/dev/null || {
    echo "Warning: sudo 권한이 없어 권한 설정을 건너뜁니다."
    echo "필요시 수동으로 실행: sudo chmod -R 755 $HOST_BASE_DIR/"
}

echo ""
echo "4. 복사 완료! 결과 확인:"
echo "================================"
for dir in profiles logs config installedApps applications deployedApps backup temp wstemp javacore heapdump; do
    if [ -d "$HOST_BASE_DIR/$dir" ] && [ "$(ls -A $HOST_BASE_DIR/$dir 2>/dev/null)" ]; then
        file_count=$(find $HOST_BASE_DIR/$dir -type f | wc -l)
        echo "✓ $dir: $file_count 개 파일 복사됨"
    else
        echo "✗ $dir: 비어있음 또는 복사 실패"
    fi
done

echo ""
echo "복사 완료!"
echo "이제 다음 단계를 진행하세요:"
echo "1. 컨테이너 중지: docker-compose down"
echo "2. docker-compose.yml에서 볼륨 마운트 주석 해제"
echo "3. 컨테이너 재시작: docker-compose up -d websphere"
