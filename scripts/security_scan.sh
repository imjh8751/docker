#!/bin/bash

# =========================================================
# === 경고: 학습 및 테스트 목적 외 사용 금지! ===
# === 실제 악성코드를 설치하지 않습니다. ===
# =========================================================

# 1. 초기 설정
echo "--- 1. 시스템 업데이트 및 필수 보안 도구 설치 ---"
sudo apt update
# clamav, rkhunter, chkrootkit 설치
sudo apt install -y clamav clamav-daemon rkhunter chkrootkit

# 2. ClamAV 데이터베이스 업데이트
echo "--- 2. ClamAV 바이러스 데이터베이스 업데이트 ---"
sudo freshclam

# 3. 더미 악성코드 파일 생성 (EICAR 테스트 파일)
# 모든 안티바이러스 프로그램이 탐지하도록 설계된 표준 테스트 파일
DUMMY_MALWARE_DIR="/tmp/security_test"
DUMMY_MALWARE_FILE="$DUMMY_MALWARE_DIR/eicar.com"
EICAR_STRING='X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'

echo ""
echo "--- 3. 더미 악성코드 파일 생성 ($DUMMY_MALWARE_FILE) ---"
mkdir -p "$DUMMY_MALWARE_DIR"
echo "$EICAR_STRING" > "$DUMMY_MALWARE_FILE"
if [ -f "$DUMMY_MALWARE_FILE" ]; then
    echo "✅ EICAR 테스트 파일 생성 완료."
else
    echo "❌ 파일 생성 실패."
    exit 1
fi

# 4. 악성코드 검사 (ClamAV)
echo ""
echo "--- 4. ClamAV를 사용하여 악성코드 검사 실행 (상세 진행률 포함) ---"
# -r: 재귀적 검사, -i: 감염된 파일만 출력, -v: 상세 출력 (검사 진행 파일 표시)
# 검사 범위를 홈 디렉토리(~)로 한정하여 시간을 절약
clamscan -r -i -v "$DUMMY_MALWARE_DIR"
CLAM_EXIT_CODE=$?

if [ $CLAM_EXIT_CODE -eq 1 ]; then
    echo "✅ ClamAV가 EICAR 테스트 파일을 성공적으로 탐지했습니다."
elif [ $CLAM_EXIT_CODE -eq 0 ]; then
    echo "⚠️ ClamAV 검사 완료. (탐지된 위협 없음 또는 오류 발생)"
else
    echo "❌ ClamAV 검사 중 오류가 발생했습니다. 종료 코드: $CLAM_EXIT_CODE"
fi

# 5. 더미 루트킷 파일 준비
DUMMY_ROOTKIT_FILE="/tmp/test_hidden_file"
echo ""
echo "--- 5. 더미 루트킷 탐지용 파일 생성 ($DUMMY_ROOTKIT_FILE) ---"
echo "This is a suspicious script content." > "$DUMMY_ROOTKIT_FILE"
echo "✅ 더미 탐지용 파일 생성 완료."

# 6. 루트킷 검사 (rkhunter)
echo ""
echo "--- 6. rkhunter를 사용하여 루트킷 검사 실행 (단계별 진행) ---"
# rkhunter는 기본적으로 상세한 진행 단계를 출력합니다.
sudo rkhunter --check --skip-keypress
RKHUNTER_EXIT_CODE=$?

if [ $RKHUNTER_EXIT_CODE -eq 0 ]; then
    echo "✅ rkhunter 검사 완료. (자세한 결과는 출력된 로그를 확인하세요.)"
else
    echo "❌ rkhunter 검사 중 오류가 발생했습니다. 종료 코드: $RKHUNTER_EXIT_CODE"
fi

# 7. 루트킷 검사 (chkrootkit)
echo ""
echo "--- 7. chkrootkit을 사용하여 루트킷 검사 실행 (순차 진행) ---"
# chkrootkit은 검사하는 항목을 순차적으로 출력합니다.
sudo chkrootkit
echo "✅ chkrootkit 검사 완료. (결과 메시지를 확인하세요.)"


# 8. 정리 (Cleanup)
echo ""
echo "--- 8. 테스트용 파일 정리 ---"
rm -rf "$DUMMY_MALWARE_DIR"
rm -f "$DUMMY_ROOTKIT_FILE"
echo "✅ 테스트용 파일 및 디렉토리 삭제 완료."

echo "--- 테스트 스크립트 완료 ---"
