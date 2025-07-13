#!/bin/bash

# 🔐 root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "❗ 이 스크립트는 root 권한으로 실행해야 합니다."
    echo "   sudo ./send_wol.sh 1 또는 su 후 실행하세요."
    exit 1
fi

# 🧰 필요한 도구 확인
if ! command -v wakeonlan &>/dev/null; then
    echo "🔧 'wakeonlan' 명령어가 설치되어 있지 않습니다."
    echo "    설치 방법: apt install wakeonlan 또는 yum install wakeonlan"
    exit 1
fi

# 🧾 MAC 주소 목록 정의
declare -A PVE_LIST=(
    [1]="00:16:96:EC:12:25"
    [2]="84:47:09:47:9C:E3"
    [3]="88:04:5B:50:E9:0A"
    [4]="68:1D:EF:3F:FB:88"
)

# 📝 로그 설정 (선택)
LOG_FILE="/var/log/wol.log"

# 📥 입력값 처리
NUM=$1

if [[ "$NUM" == "--list" || "$NUM" == "-l" ]]; then
    echo "📋 Wake-on-LAN 대상 목록:"
    for key in "${!PVE_LIST[@]}"; do
        echo "  [$key] ${PVE_LIST[$key]}"
    done
    exit 0
fi

if [[ -z "$NUM" ]]; then
    echo "⚠️ 사용법: $0 [번호]"
    echo "예: $0 1"
    echo "번호 목록 보려면: $0 --list"
    exit 1
fi

MAC=${PVE_LIST[$NUM]}

if [[ -z "$MAC" ]]; then
    echo "❌ 잘못된 번호입니다. 1~4 사이의 숫자를 입력하세요."
    exit 1
fi

echo "📡 Wake-on-LAN 전송 중... 대상 MAC: $MAC"
wakeonlan "$MAC"

# 🪵 로그 기록
echo "$(date '+%F %T') - Sent WOL to $MAC" >> "$LOG_FILE"
