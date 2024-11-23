#!/bin/bash

# 스크립트에 필요한 변수 설정
ID=$1
NAME=$2
MACADDR=$3
NET_TYPE=virtio
BRIDGE=vmbr0

# IP, GATEWAY, DNS 설정 추가
IPADDR=$4
GATEWAY=$5
OKD_DNS=192.168.0.69

# 현재 경로 저장
PATH=$(pwd)
BASE=29999

# VM 생성 함수
create_vm() {
    local ID=$1
    local NAME=$2
    local MACADDR=$3
    local IPADDR=$4

    # VM 클론 생성
    /usr/sbin/qm clone $BASE $ID --name $NAME
    
    # 네트워크 설정
    /usr/sbin/qm set $ID --net0 $NET_TYPE,bridge=$BRIDGE,macaddr=$MACADDR

    # Ignition 파일 설정
    if [ "$NAME" = "bootstrap" ]; then
        IGNITION=bootstrap
    elif [ "$NAME" = "worker" ]; then
        IGNITION=worker
    else
        IGNITION=master
    fi

    # Ignition 파일 경로를 VM 설정에 추가
    echo "args: -fw_cfg name=opt/com.coreos/config,file=$PATH/ignitions/$IGNITION.ign" >> /etc/pve/qemu-server/$ID.conf
    
    # 네트워크 설정에 IP, GATEWAY, DNS 추가
    echo "ip=$IPADDR::192.168.0.1:255.255.255.0::eth0:none" >> /etc/pve/qemu-server/$ID.conf
    echo "nameserver=$OKD_DNS" >> /etc/pve/qemu-server/$ID.conf

    # VM 시작
    /usr/sbin/qm start $ID
    
    # 완료 메시지 출력
    echo "VM $NAME with ID $ID has been created and started successfully."
}

# VM 생성
create_vm $ID_BOOTSTRAP "bootstrap" $MAC_BOOTSTRAP $IP_BOOTSTRAP
create_vm $ID_MASTER0 "master0" $MAC_MASTER0 $IP_MASTER0
create_vm $ID_MASTER1 "master1" $MAC_MASTER1 $IP_MASTER1
create_vm $ID_MASTER2 "master2" $MAC_MASTER2 $IP_MASTER2
create_vm $ID_WORKER1 "worker1" $MAC_WORKER1 $IP_WORKER1
create_vm $ID_WORKER2 "worker2" $MAC_WORKER2 $IP_WORKER2
create_vm $ID_WORKER3 "worker3" $MAC_WORKER3 $IP_WORKER3
