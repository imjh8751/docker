# 💻 n8n 수동 백업 및 복구 CLI 명령어

이 문서는 n8n 워크플로와 자격 증명을 수동으로 내보내고(Export) 가져오는 핵심 명령어를 정리합니다.
(컨테이너 이름: `n8nio-n8n` 가정)

## 1. 📤 n8n 데이터 내보내기 (Export)

| 목적 | 컨테이너 내부 명령어 (docker exec 시) | Docker 호스트 명령어 (직접 실행) |
| :--- | :--- | :--- |
| **모든 워크플로 내보내기** | `n8n export:workflow --all --output=/tmp/workflows.json` | `docker exec n8nio-n8n n8n export:workflow --all --output=/tmp/workflows.json` |
| **모든 자격 증명 내보내기** | `n8n export:credentials --all --output=/tmp/credentials.json` | `docker exec n8nio-n8n n8n export:credentials --all --output=/tmp/credentials.json` |
| **호스트로 백업 파일 복사** | *(해당 없음)* | `docker cp n8nio-n8n:/tmp/workflows.json ./n8n_backup/workflows.json` |

## 2. 📥 n8n 데이터 가져오기 (Import)

> **⚠️ 주의:** 복구 전에 n8n 컨테이너가 실행 중이어야 하며, 자격 증명 복구 시 `N8N_ENCRYPTION_KEY`가 일치해야 합니다.

| 목적 | 컨테이너 내부 명령어 (docker exec 시) | Docker 호스트 명령어 (직접 실행) |
| :--- | :--- | :--- |
| **호스트의 파일 컨테이너로 복사** | *(해당 없음)* | `docker cp ./n8n_backup/workflows.json n8nio-n8n:/tmp/workflows.json` |
| **워크플로 가져오기 실행** | `n8n import:workflow --input=/tmp/workflows.json` | `docker exec n8nio-n8n n8n import:workflow --input=/tmp/workflows.json` |
| **자격 증명 가져오기 실행** | `n8n import:credentials --input=/tmp/credentials.json` | `docker exec n8nio-n8n n8n import:credentials --input=/tmp/credentials.json` |

## 3. 🧹 임시 파일 정리 (Cleanup)

| 목적 | 컨테이너 내부 명령어 (docker exec 시) | Docker 호스트 명령어 (직접 실행) |
| :--- | :--- | :--- |
| **임시 파일 모두 삭제** | `rm /tmp/workflows.json /tmp/credentials.json` | `docker exec n8nio-n8n rm /tmp/workflows.json /tmp/credentials.json` |



# 💻 n8n 수동 백업 및 복구 CLI 명령어

이 문서는 Docker Compose 환경에서 n8n CLI를 사용하여 워크플로와 자격 증명을 수동으로 내보내고(Export) 가져오는 핵심 명령어들을 정리합니다.

모든 n8n 명령어는 실행 중인 n8n 컨테이너 내부에서 **`docker exec n8nio-n8n n8n ...`** 형태로 실행됩니다. (컨테이너 이름: `n8nio-n8n` 가정)

---
