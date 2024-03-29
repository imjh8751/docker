# vim /etc/netplan/01-network-manager-all.yaml

=======================================================
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:  # 여기서 ens33은 실제 사용 중인 인터페이스 이름입니다. 본인 시스템에 맞게 변경하세요.
      addresses: # 변경 후 IP 주소:
        - 192.168.0.90/24
      routes:
        - to: 0.0.0.0/0  # 모든 트래픽에 대한 기본 경로
          via: 192.168.0.1  # 게이트웨이 IP 주소
      nameservers:
        addresses: [192.168.0.1, 8.8.8.8, 8.8.4.4]
=======================================================

# sudo netplan apply
# ip address show
