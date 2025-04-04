#!/bin/bash
# NFS 마운트 체커 스크립트에 실행 권한 부여
chmod 750 /root/docker/mount-check.sh

# 주기적으로 실행할 서비스 파일 생성
cat <<EOF > /etc/systemd/system/mount-docker.service
[Unit]
Description=Check NFS Mount Status
After=network.target

[Service]
Type=oneshot
ExecStart=/root/docker/mount-check.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# 타이머 파일 생성 (5분마다 실행)
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

# systemd 다시 로드 및 타이머 활성화
systemctl daemon-reload
systemctl enable mount-docker.timer
systemctl start mount-docker.timer

echo "NFS 마운트 체커 서비스 및 타이머가 설치되었습니다."
echo "5분마다 NFS 마운트 상태를 확인하고 필요시 재마운트를 시도합니다."
