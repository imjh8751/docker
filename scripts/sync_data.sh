#!/bin/bash

# 설정
NAS_IP="192.168.0.99"
SOURCE="/DATA/outline"
TARGET="/APP/outline_bak"
MOUNT_PATH="/APP"

echo "--- 동기화 작업 시작: $(date) ---"

# 1. IP 연결 확인 (ping)
# -c 1: 패킷 1개만 보냄
# -W 2: 응답을 2초만 기다림
if ! ping -c 1 -W 2 "$NAS_IP" > /dev/null 2>&1; then
    echo "Error: NAS IP($NAS_IP)에 연결할 수 없습니다. 네트워크를 확인하세요."
    exit 1
fi
echo "Check: NAS IP 연결 양호."

# 2. 마운트 상태 확인 (timeout 사용)
if ! timeout 5s mountpoint -q "$MOUNT_PATH"; then
    echo "Error: $MOUNT_PATH 가 마운트되어 있지 않습니다. 동기화를 중단합니다."
    # 필요하다면 여기서 mount -a 실행을 시도할 수도 있습니다.
    exit 1
fi
echo "Check: 마운트 경로($MOUNT_PATH) 확인 완료."

# 3. rsync 수행
# --timeout=30: 전송 중 30초간 응답 없으면 종료
echo "Action: rsync 시작..."
rsync -avhP --timeout=30 "$SOURCE" "$TARGET"

# 결과 보고
if [ $? -eq 0 ]; then
    echo "Success: 동기화가 성공적으로 완료되었습니다."
else
    echo "Error: rsync 수행 중 오류가 발생했습니다."
    exit 1
fi

echo "--- 동기화 작업 종료: $(date) ---"
