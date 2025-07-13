#!/bin/bash

set -e

# ✅ root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "🔴 이 스크립트는 root 권한으로 실행해야 합니다."
    exit 1
fi

echo "🛠️ 메모리 캐시 자동 삭제 서비스 설치를 시작합니다..."

# 1. 메모리 캐시 삭제 스크립트 생성
SCRIPT_PATH="/usr/local/bin/drop_memory_cache.sh"
cat <<'EOF' > "$SCRIPT_PATH"
#!/bin/bash
set -e

LOGFILE="/var/log/drop_cache.log"

echo "[INFO] $(date '+%F %T') - Dropping caches..." >> "$LOGFILE"
sync
echo 2 > /proc/sys/vm/drop_caches
echo "[INFO] $(date '+%F %T') - Done." >> "$LOGFILE"
EOF

chmod +x "$SCRIPT_PATH"
echo "✅ 캐시 삭제 스크립트 생성: $SCRIPT_PATH"

# 2. systemd 서비스 파일 생성
SERVICE_FILE="/etc/systemd/system/drop-cache.service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Drop Linux memory cache
Wants=drop-cache.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

echo "✅ 서비스 파일 생성: $SERVICE_FILE"

# 3. systemd 타이머 파일 생성
TIMER_FILE="/etc/systemd/system/drop-cache.timer"
cat <<EOF > "$TIMER_FILE"
[Unit]
Description=Timer for dropping Linux memory cache

[Timer]
OnBootSec=5min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "✅ 타이머 파일 생성: $TIMER_FILE"

# 4. systemd 등록 및 시작
systemctl daemon-reload
systemctl enable --now drop-cache.timer

echo "✅ systemd 타이머가 등록되어 10분마다 캐시를 자동 삭제합니다."
echo "🔍 상태 확인: systemctl status drop-cache.timer"
echo "📝 로그 확인: tail -f /var/log/drop_cache.log"
