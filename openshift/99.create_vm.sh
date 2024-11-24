#!/bin/bash

# OKD 클러스터 VM 생성에 필요한 변수 선언
OKD_GATEWAY=192.168.0.1
OKD_DNS=192.168.0.69

ID_BOOTSTRAP=30009
MAC_BOOTSTRAP=72:3E:E6:0C:0B:B3
IP_BOOTSTRAP=192.168.0.79

ID_MASTER1=30001
MAC_MASTER1=d6:d8:4d:d5:39:08
IP_MASTER1=192.168.0.71

ID_MASTER2=30002
MAC_MASTER2=46:69:a9:bc:0f:54
IP_MASTER2=192.168.0.72

ID_MASTER3=30003
MAC_MASTER3=36:37:ad:87:85:63
IP_MASTER3=192.168.0.73

ID_WORKER1=30004
MAC_WORKER1=52:54:00:12:34:56
IP_WORKER1=192.168.0.72

ID_WORKER2=30005
MAC_WORKER2=52:54:00:12:34:57
IP_WORKER2=192.168.0.73

# 스크립트에 필요한 변수 설정
NET_TYPE=virtio
BRIDGE=vmbr0

# 현재 경로 저장
PATH=$(pwd)
BASE=29999

# Ignition 설정 파일 다운로드
/usr/local/bin/wget -O bootstrap.ign http://192.168.0.69:8080/bootstrap.ign
/usr/local/bin/wget -O master.ign http://192.168.0.69:8080/master.ign
/usr/local/bin/wget -O worker.ign http://192.168.0.69:8080/worker.ign

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
    if [[ "$NAME" == *"bootstrap"* ]]; then
        IGNITION=bootstrap
    elif [[ "$NAME" == *"worker"* ]]; then
        IGNITION=worker
    else
        IGNITION=master
    fi
    
    # Ignition 파일 경로를 VM 설정에 추가
    echo "args: -fw_cfg name=opt/com.coreos/config,file=$PATH/$IGNITION.ign" >> /etc/pve/qemu-server/$ID.conf

    # Cloud-Init 설정 추가
    /usr/sbin/qm set $ID --ipconfig0 ip=$IPADDR/24,gw=$OKD_GATEWAY --nameserver $OKD_DNS
    
    # VM 시작
    /usr/sbin/qm start $ID
    
    # 완료 메시지 출력
    echo "VM $NAME with ID $ID has been created and started successfully."
}

# VM 생성
create_vm $ID_BOOTSTRAP "bootstrap.ocp4.okd.io" $MAC_BOOTSTRAP $IP_BOOTSTRAP
create_vm $ID_MASTER1 "master01.ocp4.okd.io" $MAC_MASTER1 $IP_MASTER1
#create_vm $ID_MASTER2 "master02.ocp4.okd.io" $MAC_MASTER2 $IP_MASTER2
#create_vm $ID_MASTER3 "master03.ocp4.okd.io" $MAC_MASTER3 $IP_MASTER3
create_vm $ID_WORKER1 "worker01.ocp4.okd.io" $MAC_WORKER1 $IP_WORKER1
create_vm $ID_WORKER2 "worker02.ocp4.okd.io" $MAC_WORKER2 $IP_WORKER2
