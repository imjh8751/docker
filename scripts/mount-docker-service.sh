#!/bin/bash
set -e

# 💡 변수 정의
NFS_SERVER="192.168.0.99"
NFS_SHARE="/pv4-zfs/pv4-nas/DOCKER"
MOUNT_POINT="/APP"
CHECK_SCRIPT="/root/shell/mount-check.sh"
MOUNT_SCRIPT="/root/shell/mount-docker.sh"
LOG_FILE="/var/log/mount-checker.log"

# ✅ 1. mount 스크립트 작성 (/root/shell/mount-docker.sh)
mkdir -p /root/shell

cat <<EOF > "$MOUNT_SCRIPT"
#!/bin/bash
mkdir -p $MOUNT_POINT
umount -f $MOUNT_POINT 2>/dev/null || true
mount -t nfs -o soft,timeo=3,retrans=2,bg,tcp,nolock $NFS_SERVER:$NFS_SHARE $MOUNT_POINT
EOF

chmod +x "$MOUNT_SCRIPT"

# ✅ 2. 상태 체크 스크립트 작성 (/root/shell/mount-check.sh)
cat <<EOF > "$CHECK_SCRIPT"
#!/bin/bash

log() {
    echo "\$(date +'%Y-%m-%d %H:%M:%S') - \$1" >> "$LOG_FILE"
}

check_nfs_server() {
    ping -c 1 -W 2 $NFS_SERVER > /dev/null 2>&1
    return \$?
}

is_mounted() {
    mount | grep -q "$MOUNT_POINT"
    return \$?
}

log "🔍 NFS 마운트 상태 확인 시작"

if is_mounted; then
    log "✅ NFS는 이미 마운트되어 있습니다. 작업 없음."
    exit 0
fi

if check_nfs_server; then
    log "🔄 NFS 서버 응답 확인됨. 마운트 재시도 중..."
    bash "$MOUNT_SCRIPT"
    if is_mounted; then
        log "✅ 마운트 성공"
    else
        log "❌ 마운트 실패"
    fi
else
    log "❗ NFS 서버 응답 없음. 다음 주기에 재시도합니다."
fi

exit 0
EOF

chmod 750 "$CHECK_SCRIPT"

# ✅ 3. systemd 서비스 생성
cat <<EOF > /etc/systemd/system/mount-docker.service
[Unit]
Description=Check NFS Mount Status
After=network.target

[Service]
Type=oneshot
ExecStart=$CHECK_SCRIPT
RemainAfterExit=no
EOF

# ✅ 4. systemd 타이머 생성 (5분 주기 실행)
cat <<EOF > /etc/systemd/system/mount-docker.timer
[Unit]
Description=Run NFS mount check periodically

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# ✅ 5. systemd 적용 및 시작
systemctl daemon-reload
systemctl enable --now mount-docker.timer

# ✅ 6. 첫 실행 수동으로 수행
bash "$CHECK_SCRIPT"

# ✅ 완료 메시지
echo "✅ NFS 마운트 체커 서비스 및 타이머가 설치되었습니다."
echo "⏱️ 5분마다 마운트 상태 확인 및 자동 재마운트를 수행합니다."
echo "📁 로그 파일: $LOG_FILE"
echo "🔍 확인: systemctl status mount-docker.timer"
