#!/bin/bash

set -e

# root 권한 체크
if [ "$(id -u)" -ne 0 ]; then
    echo "🔴 이 스크립트는 root 권한으로 실행해야 합니다."
    echo "    예: sudo $0 또는 su 후 실행"
    exit 1
fi

echo "▶️ QEMU Guest Agent 설치를 시작합니다..."

# OS 식별
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_NAME=$NAME
else
    echo "🔴 OS 정보를 식별할 수 없습니다."
    exit 1
fi

echo "🖥️ OS 감지됨: $OS_NAME"

# 설치 및 설정
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    echo "🟢 Debian/Ubuntu 계열 - apt 사용"
    apt update
    apt install -y qemu-guest-agent
elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]; then
    echo "🟡 RHEL/CentOS 계열 - yum 사용"
    yum install -y qemu-guest-agent
else
    echo "🔴 지원되지 않는 OS입니다: $OS_ID"
    exit 1
fi

# 서비스 시작 및 자동 실행 설정
echo "▶️ qemu-guest-agent 서비스 시작 및 활성화"
systemctl start qemu-guest-agent
systemctl enable qemu-guest-agent

echo "✅ qemu-guest-agent 설치 및 설정이 완료되었습니다!"
systemctl status qemu-guest-agent --no-pager
