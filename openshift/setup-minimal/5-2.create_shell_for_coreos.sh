#!/bin/bash

# 기본 설정 (환경에 맞게 고정)
NGINX_DIR="/usr/share/nginx/html/files"
BASTION_IP="192.168.0.69"
PORT="8080"
GATEWAY="192.168.0.1"
DNS="192.168.0.200"

# 폴더가 없으면 생성
mkdir -p $NGINX_DIR

# ---------------------------------------------------------
# 공통 스크립트 생성 함수
# ---------------------------------------------------------
create_script() {
    local node_name=$1
    local node_ip=$2
    local role=$3

    # Nginx 경로에 쉘 스크립트 파일 생성
    cat <<EOF > $NGINX_DIR/${node_name}.sh
#!/bin/bash
echo "================================================="
echo " 🚀 $node_name ($node_ip) 설치 자동화를 시작합니다."
echo "================================================="

# 1. NetworkManager 영구 프로필 생성 (Proxmox 기본 인터페이스인 ens18 기준)
# 이 설정이 OS 설치 후 --copy-network 옵션을 통해 그대로 이관됩니다.
echo "▶️ 정적 IP 설정 중 ($node_ip)..."
sudo nmcli con add type ethernet con-name okd-net ifname ens18 ipv4.addresses $node_ip/24 ipv4.gateway $GATEWAY ipv4.dns $DNS ipv4.method manual 2>/dev/null
sudo nmcli con up okd-net
sleep 3

# 2. Ignition Hash 값 가져오기
echo "▶️ Ignition Hash 확인 중..."
HASH=\$(curl -s http://$BASTION_IP:$PORT/${role}.hash)

# 3. CoreOS 설치 (네트워크 설정 포함)
echo "▶️ CoreOS 설치 진행 중 (수 분 정도 소요됩니다)..."
sudo coreos-installer install --copy-network --ignition-url http://$BASTION_IP:$PORT/${role}.ign /dev/sda --ignition-hash sha512-\${HASH}

# 4. 재부팅
echo "✅ 설치가 완료되었습니다! 5초 후 자동 재부팅됩니다."
sleep 5
sudo reboot
EOF

    # 생성된 스크립트에 실행 권한 부여
    chmod +x $NGINX_DIR/${node_name}.sh
    echo "✅ 생성 완료: http://$BASTION_IP:$PORT/${node_name}.sh"
}

# ---------------------------------------------------------
# 각 노드별 스크립트 찍어내기
# ---------------------------------------------------------
echo "▶️ 각 VM용 자동화 쉘 스크립트를 생성합니다..."
create_script "bootstrap" "192.168.0.70" "bootstrap"
create_script "master01"  "192.168.0.71" "master"
create_script "worker01"  "192.168.0.72" "worker"
create_script "worker02"  "192.168.0.73" "worker"

echo "🎉 모든 스크립트가 Nginx 경로에 성공적으로 준비되었습니다!"