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


# 3. Deploy VM ID_BOOTSTRAP=30000
OKD_GATEWAY=192.168.0.1
OKD_DNS=192.168.0.69

MAC_BOOTSTRAP=72:3E:E6:0C:0B:B3
IP_BOOTSTRAP=192.168.0.79

ID_MASTER1=30001
MAC_MASTER1=d6:d8:4d:d5:39:08
IP_MASTER1=192.168.0.71

#ID_MASTER2=30002
#MAC_MASTER2=46:69:a9:bc:0f:54
#IP_MASTER2=192.168.0.72

#ID_MASTER3=30003
#MAC_MASTER3=36:37:ad:87:85:63
#IP_MASTER3=192.168.0.73

ID_WORKER1=30004
MAC_WORKER1=52:54:00:12:34:56
IP_WORKER1=192.168.0.72

ID_WORKER2=30005
MAC_WORKER2=52:54:00:12:34:57
IP_WORKER2=192.168.0.73

./99.create-vm.sh $ID_BOOTSTRAP bootstrap.ocp4.okd.io $MAC_BOOTSTRAP $IP_BOOTSTRAP $OKD_GATEWAY $OKD_DNS
#./99.create-vm.sh $ID_MASTER1 master1.ocp4.okd.io $MAC_MASTER1 $IP_MASTER1 $OKD_GATEWAY $OKD_DNS
#./99.create-vm.sh $ID_MASTER2 master2.ocp4.okd.io $MAC_MASTER2 $IP_MASTER2 $OKD_GATEWAY $OKD_DNS
#./99.create-vm.sh $ID_MASTER3 master3.ocp4.okd.io $MAC_MASTER3 $IP_MASTER3 $OKD_GATEWAY $OKD_DNS
#./99.create-vm.sh $ID_WORKER1 worker1.ocp4.okd.io $MAC_WORKER1 $IP_WORKER1 $OKD_GATEWAY $OKD_DNS
#./99.create-vm.sh $ID_WORKER2 worker2.ocp4.okd.io $MAC_WORKER2 $IP_WORKER2 $OKD_GATEWAY $OKD_DNS
