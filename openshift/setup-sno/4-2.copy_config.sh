#!/bin/bash

yum install -y jq

# ignition config 파일 복사 및 권한 부여
cd /root/installation_directory
#cp -arp *.ign /usr/share/nginx/html/files/
cp -arp bootstrap-in-place-for-live-iso.ign /usr/share/nginx/html/files/sno.ign # 이름 변경하여 복사
chmod 644 /usr/share/nginx/html/files/*

# coreos 파일 다운로드
cd /usr/share/nginx/html/files

# 1. JSON 데이터를 한 번만 불러와서 변수에 저장합니다.
JSON_DATA=$(openshift-install coreos print-stream-json)

# 2. 다운로드 URL과 스트림 버전(예: rhcos-4.20)을 각각 추출합니다.
COREOS_URL=$(echo "$JSON_DATA" | jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location')
STREAM_VER=$(echo "$JSON_DATA" | jq -r '.stream')

# 3. 파일명 커스텀 조립 (rhcos-420-9.6... 형태로 만들기)
# STREAM_VER(rhcos-4.20)에서 점(.)을 제거하여 'rhcos-420'으로 만듭니다.
PREFIX=$(echo "$STREAM_VER" | sed 's/\.//')

# 원본 파일명 (예: rhcos-9.6.20260112-0-live-iso.x86_64.iso)
ORIGINAL_FILENAME=$(basename "$COREOS_URL")

# 3. 확장자(.iso)를 제거한 기본 이름 추출
BASE_NAME="${ORIGINAL_FILENAME%.iso}"

# 4. [핵심] 새로운 프리픽스 + 원본 내용(rhcos- 제외) + .sno.iso 결합
# 결과 예시: rhcos-420-416.94.202410211619-0-live.x86_64.sno.iso
NEW_FILENAME="${PREFIX}-${BASE_NAME#rhcos-}.sno.iso"

echo "▶️ 다운로드 URL: $COREOS_URL"
echo "▶️ 저장될 파일명: $NEW_FILENAME"

# 4. 새로 조립한 이름(-O 옵션)으로 다운로드합니다.
wget -O "$NEW_FILENAME" "$COREOS_URL"

# SNO 설치 시 주석 해제
yum install -y coreos-installer
coreos-installer --version
coreos-installer iso ignition embed -fi ./sno.ign "$NEW_FILENAME"

#wget https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202409120353-0/x86_64/rhcos-417.94.202409120353-0-live.x86_64.iso
rsync -avhP rhcos*.iso 192.168.0.101:/pv2-zfs/pv2-vol/template/iso 

# igition hash 값 생성
cd /usr/share/nginx/html/files
sha512sum sno.ign | awk '{print $1}' > sno.hash