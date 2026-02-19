#!/bin/bash
set -e

# ✅ root 권한 확인
if [[ "$(id -u)" -ne 0 ]]; then
    echo "❗ 이 스크립트는 root 권한으로 실행되어야 합니다."
    exit 1
fi

echo "📦 NAS 마운트 디렉토리 생성 중..."
MOUNT_MAP=(
  "/DOCKER_NAS2=192.168.0.102:/export/DOCKER"
  #"/DATA_NAS2=192.168.0.101:/pv2-zfs/pv2-files/TEMP"
  #"/DATA_NAS3=192.168.0.100:/mnt/pve/pv"
  "/DATA_NAS1=192.168.0.102:/export/ALBUM"
  #"/DATA_NAS4=192.168.0.102:/export/UTIL"
  #"/DATA_NAS5=192.168.0.101:/pv2-zfs-data/pv2-files"
  #"/DATA_NAS6=192.168.0.99:/pv3-zfs/pv3-files"
  #"/DATA_NAS7=192.168.0.98:/pv4-zfs/pv4-files"
  "/DOCKER_NAS1=192.168.0.99:/pv4-zfs/pv4-nas/DOCKER"
  #"/DATA_NAS8=192.168.0.101:/pv2-zfs/pv2-vol"
)

for item in "${MOUNT_MAP[@]}"; do
  DIR="${item%%=*}"
  mkdir -p "$DIR"
done

echo "🧹 기존 마운트 해제 중..."
for item in "${MOUNT_MAP[@]}"; do
  DIR="${item%%=*}"
  umount -f "$DIR" 2>/dev/null || true
done

# 📥 안전한 마운트 함수
safe_mount() {
    local server_path=$1
    local mount_point=$2

    echo "🔗 마운트 시도: $server_path -> $mount_point"
    mount -t nfs -o soft,timeo=3,retrans=2,bg,tcp,nolock "$server_path" "$mount_point" 2>/dev/null \
        && echo "✅ 마운트 성공: $mount_point" \
        || echo "⚠️ 마운트 실패: $mount_point"
}

echo "📥 마운트 수행 중..."
for item in "${MOUNT_MAP[@]}"; do
  DIR="${item%%=*}"
  NFS="${item#*=}"
  safe_mount "$NFS" "$DIR"
done

# ✅ mount-check.sh 생성
CHECK_SCRIPT="/home/orangepi/shell/mount-check.sh"
mkdir -p /home/orangepi/shell

cat <<'EOF' > "$CHECK_SCRIPT"
#!/bin/bash
set -e

LOG_FILE="/var/log/mount-checker.log"

declare -A MOUNT_TARGETS=(
  ["/DOCKER_NAS2"]="192.168.0.102:/export/DOCKER"
  #["/DATA_NAS2"]="192.168.0.101:/pv2-zfs/pv2-files/TEMP"
  #["/DATA_NAS3"]="192.168.0.100:/mnt/pve/pv1-files"
  ["/DATA_NAS1"]="192.168.0.102:/export/ALBUM"
  #["/DATA_NAS4"]="192.168.0.102:/export/UTIL"
  #["/DATA_NAS5"]="192.168.0.101:/pv2-zfs-data/pv2-files"
  #["/DATA_NAS6"]="192.168.0.99:/pv3-zfs/pv3-files"
  #["/DATA_NAS7"]="192.168.0.98:/pv4-zfs/pv4-files"
  ["/DOCKER_NAS1"]="192.168.0.99:/pv4-zfs/pv4-nas/DOCKER"
)

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_and_remount() {
  local mount_point=$1
  local nfs_path=$2
  local server_ip=${nfs_path%%:*}

  log "🔍 [$mount_point] 상태 점검 중"

  if mount | grep -q "on $mount_point "; then
    log "✅ [$mount_point] 이미 마운트됨"
    return
  fi

  ping -c 1 -W 2 "$server_ip" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    log "❌ [$mount_point] 서버($server_ip) 응답 없음"
    return
  fi

  log "🔄 [$mount_point] 마운트 시도: $nfs_path"
  mount -t nfs -o soft,timeo=3,retrans=2,bg,tcp,nolock "$nfs_path" "$mount_point" \
    && log "✅ [$mount_point] 마운트 성공" \
    || log "❌ [$mount_point] 마운트 실패"
}

for mp in "${!MOUNT_TARGETS[@]}"; do
  check_and_remount "$mp" "${MOUNT_TARGETS[$mp]}"
done
EOF

chmod +x "$CHECK_SCRIPT"

# ✅ 서비스 파일 (수정됨: 네트워크 연결 후, Docker 시작 전에 실행)
cat <<EOF > /etc/systemd/system/mount-docker.service
[Unit]
Description=Check and remount all NFS mounts
Wants=network-online.target
After=network-online.target
Before=docker.service docker.socket

[Service]
Type=oneshot
ExecStart=$CHECK_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# ✅ 타이머 파일 (유지)
cat <<EOF > /etc/systemd/system/mount-docker.timer
[Unit]
Description=Run NFS mount check every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

echo "🔄 systemd 적용 및 서비스/타이머 시작"
systemctl daemon-reload

# 1. 부팅 시 Docker보다 먼저 한 번 실행되도록 서비스 활성화
systemctl enable mount-docker.service

# 2. 5분 주기 점검을 위해 타이머 활성화 및 시작
systemctl enable --now mount-docker.timer

echo -e "\n✅ 모든 설정 완료!"
echo "🚀 부팅 시 Docker보다 먼저 마운트가 수행되며, 이후 5분마다 점검합니다."
echo "📁 로그: tail -f /var/log/mount-checker.log"
echo "📡 서비스 상태: systemctl status mount-docker.service"
echo "⏱️ 타이머 상태: systemctl status mount-docker.timer"
