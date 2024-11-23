#!/bin/bash

# 삭제할 VMID 목록
VM_IDS=(30000 30001 30002 30003 30004 30005 30006)

# 각 VMID에 대해 삭제 명령어 실행
for VMID in "${VM_IDS[@]}"; do
    echo "Deleting VM with ID $VMID..."
    qm destroy $VMID --purge
    echo "VM with ID $VMID has been deleted."
done
