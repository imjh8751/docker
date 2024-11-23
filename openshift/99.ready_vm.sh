#!/bin/bash

# 1. Make ISO Download
if [[ -f "rhcos-live.iso" ]]; then
    rm rhcos-live.iso
fi

RHCOS_VER='4.17'
# coreos 파일 다운로드 
# https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/ 여기서 알맞는 iso 다운로드
#openshift-install coreos print-stream-json | grep '.iso[^.]' | grep x86_64
#wget -O rhcos-live.iso https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202409120353-0/x86_64/rhcos-417.94.202409120353-0-live.x86_64.iso
wget -O rhcos-live.iso https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/$RHCOS_VER/$RHCOS_VER.0/rhcos-$RHCOS_VER.0-x86_64-live.x86_64.iso

# 2. Make VM Template
# 변수 설정
ID=29999
NAME=rhcos-template
STORAGE=local-lvm
CPU=4
RAM=16384
NET_TYPE=virtio
BRIDGE=vmbr0
ADD_STORAGE=100G

# VM 생성
/usr/sbin/qm create $ID --name $NAME --cores $CPU --memory $RAM --net0 $NET_TYPE,bridge=$BRIDGE --cpu host

# ISO 파일 설정
ISO_PATH="local:iso/rhcos-417.94.202409120353-0-live.x86_64.iso"
/usr/sbin/qm set $ID --ide2 $ISO_PATH,media=cdrom

# 디스크 이미지 가져오기
DISK_PATH="$STORAGE:base-$ID-disk-0"
/usr/sbin/qm importdisk $ID rhcos-live.iso $STORAGE

# 디스크 설정
/usr/sbin/qm set $ID --scsihw virtio-scsi-single --scsi0 $STORAGE:vm-$ID-disk-0,cache=writeback,iothread=1,size=$ADD_STORAGE

# 부팅 순서 설정
/usr/sbin/qm set $ID --boot order='scsi0;ide2;net0'

# NUMA 설정
/usr/sbin/qm set $ID --numa 0

# OS 타입 설정
/usr/sbin/qm set $ID --ostype l26

# VM을 템플릿으로 변환
/usr/sbin/qm template $ID

# 완료 메시지 출력
echo "VM Template $NAME with ID $ID has been created successfully."
