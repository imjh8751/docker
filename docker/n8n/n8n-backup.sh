#!/bin/bash

# 설정 변수
N8N_CONTAINER_NAME="n8nio-n8n"
BACKUP_DIR="./n8n_backup"
BACKUP_FILE_WORKFLOW="workflows_all.json"
BACKUP_FILE_CREDENTIAL="credentials_all.json"

# 백업 디렉토리 생성
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "✅ 백업 디렉토리 '$BACKUP_DIR' 생성 완료."
fi

WORKFLOW_PATH="$BACKUP_DIR/$BACKUP_FILE_WORKFLOW"
CREDENTIAL_PATH="$BACKUP_DIR/$BACKUP_FILE_CREDENTIAL"

echo "--- n8n 데이터 백업 시작 ($N8N_CONTAINER_NAME) ---"

# 1. 워크플로 백업
echo "📤 모든 워크플로를 '$WORKFLOW_PATH' 로 내보내기..."
docker exec "$N8N_CONTAINER_NAME" n8n export:workflow --all --output="/home/node/.n8n/$BACKUP_FILE_WORKFLOW"
if [ $? -eq 0 ]; then
    docker cp "$N8N_CONTAINER_NAME:/home/node/.n8n/$BACKUP_FILE_WORKFLOW" "$WORKFLOW_PATH"
    echo "✅ 워크플로 백업 완료."
else
    echo "❌ 워크플로 백업 실패!"
    exit 1
fi

# 2. 자격 증명 백업
# --decrypted 옵션은 암호화 키가 변경될 때만 사용하며, 보안에 취약합니다.
# 일반적으로 암호화된 상태로 내보냅니다.
echo "🔑 모든 자격 증명을 '$CREDENTIAL_PATH' 로 내보내기 (암호화된 상태)..."
docker exec "$N8N_CONTAINER_NAME" n8n export:credentials --all --output="/home/node/.n8n/$BACKUP_FILE_CREDENTIAL"
if [ $? -eq 0 ]; then
    docker cp "$N8N_CONTAINER_NAME:/home/node/.n8n/$BACKUP_FILE_CREDENTIAL" "$CREDENTIAL_PATH"
    echo "✅ 자격 증명 백업 완료."
else
    echo "❌ 자격 증명 백업 실패!"
    exit 1
fi

echo "--- n8n 데이터 백업 완료 (파일 위치: $BACKUP_DIR) ---"
