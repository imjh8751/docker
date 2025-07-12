#!/bin/bash

set -e

# 🔐 루트 권한 체크
if [ "$(id -u)" -ne 0 ]; then
    echo "이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

# 📌 OS 정보 확인
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "지원되지 않는 OS입니다."
    exit 1
fi

# 📥 사용자 입력 받기
read -rp "📦 마운트할 프로토콜 선택 (nfs/smb/ftp/webdav): " PROTOCOL
read -rp "🔐 계정 (필요없으면 엔터): " USERNAME
read -rsp "🔑 비밀번호 (필요없으면 엔터): " PASSWORD
echo
read -rp "🌐 서버 IP 또는 도메인: " SERVER
read -rp "📍 포트 (기본값 자동 적용하려면 엔터): " PORT
read -rp "📂 원격 공유 디렉토리 (예: /share, /volume1/data): " REMOTE_PATH
read -rp "📁 마운트 경로 이름 (예: mymount → /mnt/mymount): " MOUNT_NAME

MOUNT_POINT="/mnt/$MOUNT_NAME"
mkdir -p "$MOUNT_POINT"

echo "▶️ 선택된 프로토콜: $PROTOCOL"
echo "📍 마운트 지점: $MOUNT_POINT"

### 📦 OS별 패키지 설치
install_package() {
  if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    apt update
    apt install -y "$@"
  elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]; then
    yum install -y "$@"
  else
    echo "🔴 패키지 설치 불가: 지원되지 않는 OS"
    exit 1
  fi
}

### 🚀 프로토콜별 마운트 처리
case "$PROTOCOL" in
  nfs)
    echo "📡 NFS 마운트 중..."
    install_package nfs-common
    mount -t nfs "${SERVER}:${REMOTE_PATH}" "$MOUNT_POINT"
    ;;
  
  smb|cifs)
    echo "📡 SMB/CIFS 마운트 중..."
    install_package cifs-utils

    # credentials 파일 생성 (보안)
    CRED_FILE="/tmp/cred_$MOUNT_NAME"
    echo "username=$USERNAME" > "$CRED_FILE"
    echo "password=$PASSWORD" >> "$CRED_FILE"
    chmod 600 "$CRED_FILE"

    mount -t cifs "//${SERVER}${REMOTE_PATH}" "$MOUNT_POINT" \
      -o credentials="$CRED_FILE",vers=3.0,iocharset=utf8

    ;;
  
  ftp)
    echo "📡 FTP(curlftpfs) 마운트 중..."
    install_package curlftpfs

    PORT=${PORT:-21}
    curlftpfs "${USERNAME}:${PASSWORD}@${SERVER}:${PORT}${REMOTE_PATH}" "$MOUNT_POINT" \
      -o allow_other,uid=$(id -u),gid=$(id -g)
    ;;
  
  webdav)
    echo "📡 WebDAV(davfs2) 마운트 중..."
    install_package davfs2

    echo "${USERNAME}" > /etc/davfs2/secrets
    echo "${PASSWORD}" >> /etc/davfs2/secrets
    chmod 600 /etc/davfs2/secrets

    PORT=${PORT:-80}
    URL="http://${SERVER}:${PORT}${REMOTE_PATH}"
    mount -t davfs "$URL" "$MOUNT_POINT"
    ;;
  
  *)
    echo "🔴 지원되지 않는 프로토콜입니다: $PROTOCOL"
    exit 1
    ;;
esac

echo "✅ 마운트 완료: $MOUNT_POINT"
df -h | grep "$MOUNT_POINT"
