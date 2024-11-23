#!/bin/bash

# 1. Make ISO Download
if [[ -f "rhcos-live.iso" ]]; then
    rm rhcos-live.iso
fi

# coreos 파일 다운로드
openshift-install coreos print-stream-json | grep '.iso[^.]' | grep x86_64
wget -O rhcos-live.iso https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.17-9.4/builds/417.94.202409120353-0/x86_64/rhcos-417.94.202409120353-0-live.x86_64.iso

# 2. Make VM Template
ID=29999
NAME=rhcos-template
STORAGE=nvme
CPU=4
RAM=16384
NET_TYPE=virtio
BRIDGE=vmbr0
VLAN=20
ADD_STORAGE=112G

/usr/sbin/qm create $ID --name $NAME --cores $CPU --memory $RAM --net0 $NET_TYPE,bridge=$BRIDGE,tag=$VLAN
/usr/sbin/qm importdisk $ID rhcos-live.iso $STORAGE
/usr/sbin/qm set $ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$ID-disk-0
/usr/sbin/qm set $ID --boot c --bootdisk scsi0
/usr/sbin/qm resize $ID scsi0 +$ADD_STORAGE
/usr/sbin/qm template $ID

# 3. Deploy VM 
ID_BOOTSTRAP=30000
MAC_BOOTSTRAP=72:3E:E6:0C:0B:B3

ID_MASTER0=30001
MAC_MASTER0=d6:d8:4d:d5:39:08
ID_MASTER1=30002
MAC_MASTER1=46:69:a9:bc:0f:54
ID_MASTER2=30003
MAC_MASTER2=36:37:ad:87:85:63

./scripts/create-vm.sh $ID_BOOTSTRAP okd-bootstrap $MAC_BOOTSTRAP
./scripts/create-vm.sh $ID_MASTER0 okd-master-0 $MAC_MASTER0
./scripts/create-vm.sh $ID_MASTER1 okd-master-1 $MAC_MASTER1
./scripts/create-vm.sh $ID_MASTER2 okd-master-2 $MAC_MASTER2
