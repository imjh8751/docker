#!/bin/bash
set -e

# 💡 변수 정의
NFS_SERVER="192.168.0.101"
CHECK_SCRIPT="/root/pve-backup/mount-check.sh"
MOUNT_SCRIPT="/root/pve-backup/mount-pve-backup.sh"
LOG_FILE="/var/log/pve-backup-mount.log"

# ✅ 1. mount 스크립트 작성 (/root/pve-backup/mount-pve-backup.sh)
mkdir -p /root/pve-backup

cat <<EOF > "$MOUNT_SCRIPT"
#!/bin/bash
# PVE 백업용 NFS 마운트 스크립트

log() {
    echo "\$(date +'%Y-%m-%d %H:%M:%S') - \$1" | tee -a "$LOG_FILE"
}

log "🔄 PVE 백업 NFS 마운트 작업 시작"

# 1부터 4까지 반복하여 각 PVE 백업 디렉토리 마운트
for i in {1..4}
do
  LOCAL_MOUNT_POINT="/APP/PVE\${i}-BACKUP"
  REMOTE_NFS_SHARE="/pv2-zfs/pv2-backup/PVE\${i}-BACKUP"
  
  log "PVE\${i} 마운트 작업 시작..."
  
  # 로컬 마운트 포인트 디렉토리 생성
  if [ ! -d "\$LOCAL_MOUNT_POINT" ]; then
    log "  디렉토리 \$LOCAL_MOUNT_POINT 생성 중..."
    mkdir -p "\$LOCAL_MOUNT_POINT"
  fi
  
  # 기존 마운트가 있다면 언마운트
  umount -f "\$LOCAL_MOUNT_POINT" 2>/dev/null || true
  
  # NFS 마운트 실행
  mount -t nfs -o vers=4.1,hard,intr,tcp,bg "$NFS_SERVER:\$REMOTE_NFS_SHARE" "\$LOCAL_MOUNT_POINT"
  
  # 마운트 성공 여부 확인
  if [ \$? -eq 0 ]; then
    log "  ✅ 성공: $NFS_SERVER:\$REMOTE_NFS_SHARE -> \$LOCAL_MOUNT_POINT"
  else
    log "  ❌ 실패: $NFS_SERVER:\$REMOTE_NFS_SHARE"
  fi
done

log "📊 현재 PVE 백업 마운트 상태:"
df -h | grep "/APP/PVE" | while read line; do
  log "  \$line"
done

log "🔄 PVE 백업 NFS 마운트 작업 완료"
EOF

chmod +x "$MOUNT_SCRIPT"

# ✅ 2. 상태 체크 스크립트 작성 (/root/pve-backup/mount-check.sh)
cat <<EOF > "$CHECK_SCRIPT"
#!/bin/bash

log() {
    echo "\$(date +'%Y-%m-%d %H:%M:%S') - \$1" >> "$LOG_FILE"
}

check_nfs_server() {
    ping -c 1 -W 2 $NFS_SERVER > /dev/null 2>&1
    return \$?
}

check_all_mounts() {
    local all_mounted=true
    for i in {1..4}
    do
        if ! mount | grep -q "/APP/PVE\${i}-BACKUP"; then
            all_mounted=false
            break
        fi
    done
    
    if [ "\$all_mounted" = true ]; then
        return 0
    else
        return 1
    fi
}

log "🔍 PVE 백업 NFS 마운트 상태 확인 시작"

if check_all_mounts; then
    log "✅ 모든 PVE 백업 NFS가 이미 마운트되어 있습니다. 작업 없음."
    exit 0
fi

if check_nfs_server; then
    log "🔄 NFS 서버 응답 확인됨. 마운트 재시도 중..."
    bash "$MOUNT_SCRIPT"
    
    if check_all_mounts; then
        log "✅ 모든 PVE 백업 마운트 성공"
    else
        log "❌ 일부 PVE 백업 마운트 실패"
    fi
else
    log "❗ NFS 서버($NFS_SERVER) 응답 없음. 다음 주기에 재시도합니다."
fi

exit 0
EOF

chmod 750 "$CHECK_SCRIPT"

# ✅ 3. systemd 서비스 생성
cat <<EOF > /etc/systemd/system/pve-backup-mount.service
[Unit]
Description=Check PVE Backup NFS Mount Status
After=network.target

[Service]
Type=oneshot
ExecStart=$CHECK_SCRIPT
RemainAfterExit=no
EOF

# ✅ 4. systemd 타이머 생성 (5분 주기 실행)
cat <<EOF > /etc/systemd/system/pve-backup-mount.timer
[Unit]
Description=Run PVE Backup NFS mount check periodically

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# ✅ 5. systemd 적용 및 시작
systemctl daemon-reload
systemctl enable --now pve-backup-mount.timer

# ✅ 6. 첫 실행 수동으로 수행
bash "$CHECK_SCRIPT"

# ✅ 완료 메시지
echo "✅ PVE 백업 NFS 마운트 체커 서비스 및 타이머가 설치되었습니다."
echo "⏱️ 5분마다 마운트 상태 확인 및 자동 재마운트를 수행합니다."
echo "📁 로그 파일: $LOG_FILE"
echo "🔍 타이머 상태 확인: systemctl status pve-backup-mount.timer"
echo "🔍 서비스 로그 확인: tail -f $LOG_FILE"
