#!/bin/bash

# backup
sudo cp -p /etc/netplan/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml.org

# netplan 설정 파일을 업데이트합니다.
cat <<EOF > /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:  # 인터페이스 이름은 시스템에 맞게 변경하세요.
      addresses:
        - 192.168.0.90/24
      routes:
        - to: 0.0.0.0/0
          via: 192.168.0.1
      nameservers:
        addresses: [192.168.0.1, 8.8.8.8, 8.8.4.4]
EOF

# 권한변경
sudo chmod 600 /etc/netplan/01-network-manager-all.yaml

# 변경사항을 적용합니다.
sudo netplan apply

# IP 주소를 확인합니다.
ip address show
