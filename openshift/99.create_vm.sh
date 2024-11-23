#!/bin/bash

#Go to https://getfedora.org/en/coreos/download?tab=metal_virtualized&stream=stable, replace version
# 1. Make ISO Download
VERSION=32.20201104.3.0

if [[ -f "fedora-coreos.qcow2" ]]; then
    rm fedora-coreos.qcow2
fi

wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$VERSION/x86_64/fedora-coreos-$VERSION-qemu.x86_64.qcow2.xz
unxz fedora-coreos-$VERSION-qemu.x86_64.qcow2.xz
mv fedora-coreos-$VERSION-qemu.x86_64.qcow2 fedora-coreos.qcow2

# 2. Make VM Template
ID=29999
NAME=fcos-template
STORAGE=nvme
CPU=4
RAM=16384
NET_TYPE=virtio
BRIDGE=vmbr0
VLAN=20
ADD_STORAGE=112G

/usr/sbin/qm create $ID --name $NAME --cores $CPU --memory $RAM --net0 $NET_TYPE,bridge=$BRIDGE,tag=$VLAN
/usr/sbin/qm importdisk $ID fedora-coreos.qcow2 $STORAGE
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
