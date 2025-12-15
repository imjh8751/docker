# 💾 n8n 수동 백업 및 복구 CLI 명령어 가이드

이 문서는 Docker 환경에서 n8n 워크플로와 자격 증명(Credentials)을 수동으로 내보내고(Export) 가져오는 핵심 명령어들을 정리합니다.

모든 명령어는 Docker 호스트에서 실행되며, n8n 컨테이너 이름은 **`n8nio-n8n`**으로 가정합니다.

---

## 1. 📤 백업 (Export) 절차

### 1.1. 데이터 내보내기 (n8n Export)

n8n CLI 명령을 사용하여 데이터를 JSON 파일로 내보내고, 컨테이너의 `/tmp` 디렉토리에 저장합니다.

| 목적 | Docker 호스트에서 실행할 명령어 |
| :--- | :--- |
| **모든 워크플로 내보내기** | `docker exec n8nio-n8n n8n export:workflow --all --output=/tmp/workflows.json` |
| **모든 자격 증명 내보내기** | `docker exec n8nio-n8n n8n export:credentials --all --output=/tmp/credentials.json` |

### 1.2. 호스트로 복사 (Docker Copy)

컨테이너 `/tmp`에 있는 파일을 호스트 시스템의 백업 디렉토리(`./n8n_backup`)로 복사합니다.

| 목적 | Docker 호스트에서 실행할 명령어 |
| :--- | :--- |
| **워크플로 파일 복사** | `docker cp n8nio-n8n:/tmp/workflows.json ./n8n_backup/workflows.json` |
| **자격 증명 파일 복사** | `docker cp n8nio-n8n:/tmp/credentials.json ./n8n_backup/credentials.json` |

---

## 2. 📥 복구 (Import) 절차

### 2.1. 컨테이너로 복사 (Docker Copy)

호스트 시스템의 백업 파일을 n8n 컨테이너 `/tmp` 디렉토리로 복사합니다.

| 목적 | Docker 호스트에서 실행할 명령어 |
| :--- | :--- |
| **워크플로 파일 복사** | `docker cp ./n8n_backup/workflows.json n8nio-n8n:/tmp/workflows.json` |
| **자격 증명 파일 복사** | `docker cp ./n8n_backup/credentials.json n8nio-n8n:/tmp/credentials.json` |

### 2.2. 데이터 가져오기 (n8n Import)

n8n CLI 명령을 사용하여 `/tmp`에 있는 JSON 파일을 데이터베이스로 가져와 반영합니다.

> **⚠️ 주의:** 자격 증명을 복구하려면 n8n 컨테이너의 환경 변수 `N8N_ENCRYPTION_KEY`가 백업 시 사용된 키와 **반드시 일치**해야 합니다.

| 목적 | Docker 호스트에서 실행할 명령어 |
| :--- | :--- |
| **워크플로 가져오기 실행** | `docker exec n8nio-n8n n8n import:workflow --input=/tmp/workflows.json` |
| **자격 증명 가져오기 실행** | `docker exec n8nio-n8n n8n import:credentials --input=/tmp/credentials.json` |

---

## 3. 🧹 임시 파일 정리 (Cleanup)

데이터 처리 완료 후, 컨테이너 내부에 남아있는 임시 백업 파일을 삭제합니다.

| 목적 | Docker 호스트에서 실행할 명령어 |
| :--- | :--- |
| **임시 파일 모두 삭제** | `docker exec n8nio-n8n rm /tmp/workflows.json /tmp/credentials.json` |
