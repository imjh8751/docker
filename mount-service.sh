#!/bin/bash

# 도커 실행 권한 부여
chmod 750 /root/docker/*.sh

# /etc/systemd/system/mount-docker.service 파일 생성
cat <<EOF > /etc/systemd/system/mount-docker.service
[Unit]
Description=Mount Script Service
After=network.target

[Service]
Type=oneshot
ExecStart=/root/docker/mount-docker.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# systemctl daemon-reload, enable, start 추가 작성
sudo systemctl daemon-reload
sudo systemctl enable mount-docker.service
sudo systemctl start mount-docker.service

# 도커 실행
bash /root/docker/mount-docker.sh
