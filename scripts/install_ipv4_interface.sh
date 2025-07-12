#!/bin/bash

set -e

# 📌 설정값 (필요시 수정)
INTERFACE="ens18"
STATIC_IP="192.168.0.90/24"
GATEWAY="192.168.0.1"
DNS1="192.168.0.1"
DNS2="8.8.8.8"
DNS3="8.8.4.4"

# 🔐 Root 권한 체크
if [ "$(id -u)" -ne 0 ]; then
    echo "🔴 이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

# OS 확인
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "🔴 OS 식별 불가"
    exit 1
fi

echo "📌 인터페이스: $INTERFACE"
echo "📌 IP 주소: $STATIC_IP"
echo "📌 게이트웨이: $GATEWAY"
echo "📌 DNS: $DNS1, $DNS2, $DNS3"
echo "🖥️ 감지된 OS: $OS_ID"

# OS 별 분기 처리
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    echo "🟢 Ubuntu/Debian - Netplan 사용"

    NETPLAN_FILE="/etc/netplan/01-network-manager-all.yaml"

    # 백업
    cp -p "$NETPLAN_FILE" "${NETPLAN_FILE}.org.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

    # Netplan 설정 파일 쓰기
    cat <<EOF > "$NETPLAN_FILE"
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      addresses:
        - $STATIC_IP
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses: [$DNS1, $DNS2, $DNS3]
EOF

    chmod 600 "$NETPLAN_FILE"
    echo "✅ Netplan 구성 완료. 적용 중..."
    netplan apply
    echo "✅ IP 설정 적용 완료."

elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]; then
    echo "🟡 RHEL/CentOS 계열 - ifcfg 또는 nmcli 사용"

    IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${INTERFACE}"

    # 백업
    [ -f "$IFCFG_FILE" ] && cp -p "$IFCFG_FILE" "${IFCFG_FILE}.bak.$(date +%Y%m%d%H%M%S)"

    # 분해 IP/Prefix
    IP_ADDR="${STATIC_IP%%/*}"
    PREFIX="${STATIC_IP##*/}"

    # ifcfg 파일 쓰기
    cat <<EOF > "$IFCFG_FILE"
DEVICE=$INTERFACE
BOOTPROTO=static
ONBOOT=yes
IPADDR=$IP_ADDR
PREFIX=$PREFIX
GATEWAY=$GATEWAY
DNS1=$DNS1
DNS2=$DNS2
DNS3=$DNS3
EOF

    chmod 600 "$IFCFG_FILE"
    echo "✅ 네트워크 설정 파일 구성 완료. 적용 중..."
    nmcli con reload || true
    ifdown "$INTERFACE" 2>/dev/null || true
    ifup "$INTERFACE" || nmcli con up "$INTERFACE" || systemctl restart network
    echo "✅ IP 설정 적용 완료."

else
    echo "🔴 이 OS는 자동 설정을 지원하지 않습니다. 수동 설정 필요."
    exit 1
fi

# 결과 출력
echo "📡 현재 IP 주소:"
ip addr show "$INTERFACE"
