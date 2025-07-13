#!/bin/bash

set -e

# ✅ root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

echo "🛠️ Wake-on-LAN(WOL) systemd 서비스 설치 시작..."

# 1. ethtool 설치 (필요 시)
if ! command -v ethtool &> /dev/null; then
    echo "📦 ethtool 설치 필요: 자동 설치 시도 중..."
    if [ -f /etc/debian_version ]; then
        apt update && apt install -y ethtool
    elif [ -f /etc/redhat-release ]; then
        yum install -y ethtool
    else
        echo "❗ ethtool 설치는 수동으로 진행해야 합니다."
    fi
fi

# 2. 서비스 파일 작성
SERVICE_FILE="/etc/systemd/system/wol-enable.service"

cat <<'EOF' > "$SERVICE_FILE"
[Unit]
Description=Enable Wake On LAN
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'for iface in $(ls /sys/class/net/ | grep -v lo | grep ^en); do /sbin/ethtool -s $iface wol g; done'
ExecStop=/bin/sh -c 'for iface in $(ls /sys/class/net/ | grep -v lo | grep ^en); do /sbin/ethtool -s $iface wol g; done'

[Install]
WantedBy=multi-user.target
EOF

echo "✅ WOL 서비스 파일 생성됨: $SERVICE_FILE"

# 3. systemd 적용 및 서비스 활성화
systemctl daemon-reload
systemctl enable --now wol-enable.service

echo "✅ WOL 서비스가 등록되고 즉시 실행되었습니다."
echo "🔍 상태 확인: systemctl status wol-enable.service"
