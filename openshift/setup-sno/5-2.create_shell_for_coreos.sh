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
    # 'EOF'에 따옴표를 붙이면 내부의 $ 변수들이 치환되지 않고 그대로 파일에 기록됩니다.
    cat <<'EOF' > $NGINX_DIR/${node_name}.sh
#!/bin/bash
# 설치 시점에 전달받은 변수들을 하드코딩 형태로 주입하기 위해 sed 등으로 처리하거나 
# 아래처럼 직접 변수를 다시 정의해주는 것이 깔끔합니다.
EOF

    # VM 내부에서 사용할 변수들을 스크립트 상단에 주입
    sed -i "2i NODE_NAME=\"$node_name\"\nNODE_IP=\"$node_ip\"\nROLE=\"$role\"\nBASTION_IP=\"$BASTION_IP\"\nPORT=\"$PORT\"\nGATEWAY=\"$GATEWAY\"\nDNS=\"$DNS\"" $NGINX_DIR/${node_name}.sh

    # 실제 실행될 로직 추가
    cat <<'EOF' >> $NGINX_DIR/${node_name}.sh
echo "================================================="
echo " 🚀 [$NODE_NAME] CoreOS 설치 자동화를 시작합니다."
echo "================================================="

# 랜카드 이름 자동 감지 (ens18, enp6s18 등 환경에 맞게 자동 선택)
IFNAME=$(nmcli -t -f DEVICE,TYPE device | grep ethernet | cut -d: -f1 | head -n 1)
echo "▶️ 감지된 네트워크 인터페이스: ${IFNAME}"

echo "▶️ 1. 네트워크 IP 설정 적용 중 ($NODE_IP)..."
# 기존 연결 삭제 후 정적 IP 프로필 생성
sudo nmcli con delete "Wired connection 1" 2>/dev/null
sudo nmcli con add type ethernet con-name okd-net ifname ${IFNAME} ipv4.addresses $NODE_IP/24 ipv4.gateway $GATEWAY ipv4.dns $DNS ipv4.method manual
sudo nmcli con up okd-net
sleep 3

echo "▶️ 2. Ignition Hash 값 가져오는 중..."
hash=$(curl -s http://$BASTION_IP:$PORT/${ROLE}.hash)

echo "▶️ 3. CoreOS 설치 진행 중 (수 분 소요)..."
sudo coreos-installer install --copy-network --ignition-url http://$BASTION_IP:$PORT/${ROLE}.ign /dev/sda --ignition-hash sha512-${hash}

echo "✅ 4. 설치 완료! 5초 후 재부팅합니다."
sleep 60
sudo reboot
EOF

    chmod +x $NGINX_DIR/${node_name}.sh
    echo "✅ 생성 완료: http://$BASTION_IP:$PORT/${node_name}.sh"
}

# ---------------------------------------------------------
# 각 노드별 스크립트 찍어내기
# ---------------------------------------------------------
echo "▶️ 각 VM용 자동화 쉘 스크립트를 생성합니다..."
create_script "master01"  "192.168.0.71" "sno"

echo "🎉 모든 스크립트가 Nginx 경로에 성공적으로 준비되었습니다!"