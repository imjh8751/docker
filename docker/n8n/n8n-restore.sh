#!/bin/bash

# 설정 변수
N8N_CONTAINER_NAME="n8nio-n8n"
BACKUP_DIR="./n8n_backup"
BACKUP_FILE_WORKFLOW="workflows_all.json"
BACKUP_FILE_CREDENTIAL="credentials_all.json"

WORKFLOW_PATH="$BACKUP_DIR/$BACKUP_FILE_WORKFLOW"
CREDENTIAL_PATH="$BACKUP_DIR/$BACKUP_FILE_CREDENTIAL"
CONTAINER_TEMP_DIR="/home/node/.n8n/"

if [ ! -f "$WORKFLOW_PATH" ] || [ ! -f "$CREDENTIAL_PATH" ]; then
    echo "❌ 백업 파일이 존재하지 않습니다. 백업 디렉토리 확인: $BACKUP_DIR"
    exit 1
fi

echo "--- n8n 데이터 복구 시작 ($N8N_CONTAINER_NAME) ---"

# 1. 파일들을 컨테이너로 복사
echo "📦 백업 파일을 n8n 컨테이너로 복사..."
docker cp "$WORKFLOW_PATH" "$N8N_CONTAINER_NAME:$CONTAINER_TEMP_DIR"
docker cp "$CREDENTIAL_PATH" "$N8N_CONTAINER_NAME:$CONTAINER_TEMP_DIR"

# 2. 워크플로 복구
echo "📥 워크플로 가져오기 시작..."
docker exec "$N8N_CONTAINER_NAME" n8n import:workflow --input="$CONTAINER_TEMP_DIR/$BACKUP_FILE_WORKFLOW"
if [ $? -eq 0 ]; then
    echo "✅ 워크플로 복구 완료."
else
    echo "❌ 워크플로 복구 실패! n8n 로그를 확인하세요."
    exit 1
fi

# 3. 자격 증명 복구
echo "🔑 자격 증명 가져오기 시작..."
docker exec "$N8N_CONTAINER_NAME" n8n import:credentials --input="$CONTAINER_TEMP_DIR/$BACKUP_FILE_CREDENTIAL"
if [ $? -eq 0 ]; then
    echo "✅ 자격 증명 복구 완료."
else
    echo "❌ 자격 증명 복구 실패! (특히 N8N_ENCRYPTION_KEY 일치 여부 확인)."
    exit 1
fi

# 4. 임시 파일 정리
docker exec "$N8N_CONTAINER_NAME" rm "$CONTAINER_TEMP_DIR/$BACKUP_FILE_WORKFLOW"
docker exec "$N8N_CONTAINER_NAME" rm "$CONTAINER_TEMP_DIR/$BACKUP_FILE_CREDENTIAL"

echo "--- n8n 데이터 복구 완료 ---"
