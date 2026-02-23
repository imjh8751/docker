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

# =========================================================================
# 🚨 수정된 부분: ping 실패 시 set -e로 인한 강제 종료 방지 (구조는 원본 유지)
# =========================================================================
cat <<'EOF' > "$CHECK_SCRIPT"
#!/bin/bash
set -e

LOG_FILE="/var/log/mount-checker.log"
RESTART_DOCKER=0

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

  # 🔥 변경점: ping이 실패해도 스크립트가 죽지 않고 계속 진행되도록 if문 조건식 안으로 이동
  if ! ping -c 1 -W 2 "$server_ip" > /dev/null 2>&1; then
    log "❌ [$mount_point] 서버($server_ip) 응답 없음"
    return
  fi

  log "🔄 [$mount_point] 마운트 시도: $nfs_path"
  if mount -t nfs -o soft,timeo=3,retrans=2,bg,tcp,nolock "$nfs_path" "$mount_point"; then
    log "✅ [$mount_point] 마운트 성공"
    RESTART_DOCKER=1
  else
    log "❌ [$mount_point] 마운트 실패"
  fi
}

for mp in "${!MOUNT_TARGETS[@]}"; do
  check_and_remount "$mp" "${MOUNT_TARGETS[$mp]}"
done

# ==========================================
# 🚨 Docker 자동 복구 (부팅 데드락 방지)
# ==========================================
if [[ $RESTART_DOCKER -eq 1 ]]; then
  # 부팅 시점에는 Docker가 아직 켜지기 전이므로 재시작할 필요가 없습니다.
  if systemctl is-active --quiet docker; then
    log "🔄 마운트가 갱신되었습니다. 컨테이너 볼륨 정상화를 위해 Docker를 백그라운드에서 재시작합니다."
    systemctl restart --no-block docker && log "✅ Docker 재시작 명령 전송 완료"
  else
    log "✅ 부팅 마운트 완료 (Docker는 시스템 시퀀스에 따라 곧 자동 시작됩니다.)"
  fi

elif ! systemctl is-active --quiet docker; then
  # 서버 부팅(starting)이 완전히 끝난, 정상 운영 상태에서만 Watchdog이 개입하도록 방어
  if [[ "$(systemctl is-system-running 2>/dev/null)" != "starting" ]]; then
    log "⚠️ Docker 데몬 중지 감지. 자동 복구를 시도합니다."
    systemctl start --no-block docker && log "✅ Docker 자동 복구 명령 전송 완료"
  fi
fi
EOF
# =========================================================================

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
echo "🚀 부팅 시 Docker보다 먼저 마운트가 수행되며, 이후 5분마다 점검 및 Docker 상태를 감시합니다."
echo "📁 로그: tail -f /var/log/mount-checker.log"
echo "📡 서비스 상태: systemctl status mount-docker.service"
echo "⏱️ 타이머 상태: systemctl status mount-docker.timer"
