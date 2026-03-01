#!/bin/bash

# ==========================================
# 💡 1. 사용자 네트워크 환경 변수 설정
# ==========================================
# SNO가 설치될 서버의 실제 랜카드 이름과 IP 정보를 입력하세요.
INTERFACE_NAME="enp6s18"      # 예: ens18, enp6s18 등
NODE_IP="192.168.0.81/24"     # 사용할 정적 IP 및 서브넷 마스크 (CIDR 형식)
GATEWAY="192.168.0.1"         # 게이트웨이 주소
DNS="192.168.0.200"           # DNS 서버 주소
# ==========================================

# 필수 패키지 설치 (jq 및 coreos-installer를 한 번에 설치)
yum install -y jq coreos-installer

# ignition config 파일 복사 및 권한 부여
cd /root/installation_directory
cp -arp bootstrap-in-place-for-live-iso.ign /usr/share/nginx/html/files/sno.ign
chmod 644 /usr/share/nginx/html/files/*

# coreos 파일 다운로드 디렉토리로 이동
cd /usr/share/nginx/html/files

# JSON 데이터를 한 번만 불러와서 변수에 저장
JSON_DATA=$(openshift-install coreos print-stream-json)

# 다운로드 URL과 스트림 버전(예: rhcos-4.20) 추출
COREOS_URL=$(echo "$JSON_DATA" | jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location')
STREAM_VER=$(echo "$JSON_DATA" | jq -r '.stream')

# 파일명 커스텀 조립 (rhcos-420-9.6... 형태로 만들기)
PREFIX=$(echo "$STREAM_VER" | sed 's/\.//')
ORIGINAL_FILENAME=$(basename "$COREOS_URL")
BASE_NAME="${ORIGINAL_FILENAME%.iso}"
NEW_FILENAME="${PREFIX}-${BASE_NAME#rhcos-}.sno.iso"

echo "▶️ 다운로드 URL: $COREOS_URL"
echo "▶️ 저장될 파일명: $NEW_FILENAME"

# 조립한 이름으로 ISO 다운로드
wget -O "$NEW_FILENAME" "$COREOS_URL"

# ==========================================
# 💡 2. NetworkManager 설정 파일 생성 (.nmconnection)
# ==========================================
echo "▶️ 네트워크 설정 파일(nmconnection) 생성 중..."
cat <<EOF > sno-net.nmconnection
[connection]
id=sno-net
type=ethernet
interface-name=${INTERFACE_NAME}
autoconnect=true

[ipv4]
method=manual
addresses=${NODE_IP}
gateway=${GATEWAY}
dns=${DNS};
EOF

# NetworkManager는 설정 파일의 권한이 600이어야 정상적으로 인식합니다.
chmod 600 sno-net.nmconnection 

# ==========================================
# 💡 3. ISO 파일에 Network 및 Ignition Embed
# ==========================================
echo "▶️ ISO 파일에 설정 삽입을 시작합니다..."
coreos-installer --version

# 1) 네트워크 설정 삽입
coreos-installer iso network embed --keyfile sno-net.nmconnection "$NEW_FILENAME"

# 2) Ignition 파일 삽입
coreos-installer iso ignition embed -fi ./sno.ign "$NEW_FILENAME"

echo "✅ ISO 설정 삽입 완료!"

# ==========================================
# 💡 4. 마무리 작업 (Rsync 및 Hash 생성)
# ==========================================
# 조립된 새 파일명만 정확히 지정하여 전송하도록 수정했습니다.
rsync -avhP "$NEW_FILENAME" 192.168.0.101:/pv2-zfs/pv2-vol/template/iso/

# ignition hash 값 생성
sha512sum sno.ign | awk '{print $1}' > sno.hash
echo "✅ Hash 값 생성 완료 (sno.hash)"