#!/bin/bash

# NAS 마운트 포인트와 IP를 정의합니다.
nas_mount_points=(
/APP/2T_NFS
/APP/4T_NFS
/APP/hdd
)
nas_ips=("192.168.0.102" "192.168.0.103" "192.168.0.104")

# 각 NAS 별로 헬스 체크를 수행합니다.
for ((i=0; i<${#nas_ips[@]}; i++)); do
    nas_ip="${nas_ips[i]}"

    # NAS에 Ping을 보내서 연결 상태를 확인합니다.
    if ! ping -c 1 "$nas_ip" &> /dev/null; then
        echo "NAS $nas_ip 에 Ping을 보낼 수 없습니다. 연결 상태를 확인해주세요!"
        continue
    fi

    echo "NAS $nas_ip 헬스 체크 완료!"
done

for ((i=0; i<${#nas_mount_points[@]}; i++)); do
    nas_mount_point="${nas_mount_points[i]}"

    # NAS가 마운트되어 있는지 확인합니다.
    if ! mountpoint -q "$nas_mount_point"; then
        echo "NAS 마운트 포인트 $nas_mount_point 가 마운트되지 않았습니다!"
        continue
    fi

    echo "NAS $nas_mount_point 헬스 체크 완료!"
done

echo "모든 NAS 헬스 체크가 완료되었습니다."
