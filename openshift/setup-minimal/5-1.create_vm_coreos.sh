#!/bin/bash

# ==========================================
# Proxmox 설정 변수 (환경에 맞게 수정)
# ==========================================
STORAGE="pv2-vol"
ISO_IMAGE="${STORAGE}:iso/rhcos-420-9.6.20260112-0-live-iso.x86_64.iso"
BRIDGE="vmbr0" # 기본 브릿지 네트워크

# 노드 정보: "VMID:호스트명:CPU:RAM(MB):디스크(GB)"
# (이미지의 IP 순서에 맞춰 2070번대 ID를 예시로 부여했습니다.)
NODES=(
    "2070:bootstrap.ocp4.okd.io:8:16384:100"
    "2071:master01.ocp4.okd.io:8:24576:100"
    "2072:worker01.ocp4.okd.io:8:16384:100"
    "2073:worker02.ocp4.okd.io:8:16384:100"
)

echo "▶️ Proxmox OCP4 VM 자동 생성을 시작합니다..."

for node in "${NODES[@]}"; do
    IFS=':' read -r VMID NAME CORES RAM DISK <<< "$node"
    
    echo "------------------------------------------------"
    echo "🚀 생성 중: $NAME (VMID: $VMID)"

    # 1. VM 생성 (CPU, RAM, 네트워크)
    qm create $VMID --name "$NAME" --ostype l26 --cores $CORES --memory $RAM --cpu host --machine q35 --net0 virtio,bridge=$BRIDGE
    # 2. SCSI 컨트롤러 설정 (성능 최적화)
    qm set $VMID --scsihw virtio-scsi-single

    # 3. ZFS 스토리지에 100GB 디스크 할당
    qm set $VMID --scsi0 $STORAGE:$DISK,discard=on,iothread=1,cache=writeback

    # 4. CoreOS 4.20 ISO CD-ROM 마운트
    qm set $VMID --ide2 $ISO_IMAGE,media=cdrom

    # 5. 부팅 순서 설정 (설치 전이므로 CD-ROM 우선 부팅)
    qm set $VMID --boot order=scsi0\;ide2

    echo "✅ $NAME 생성 완료!"
done

echo "------------------------------------------------"
echo "🎉 4개의 VM 생성이 완료되었습니다. Proxmox GUI에서 VM들을 시작(Start)해 주세요!"