#!/bin/bash

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Error: Root privileges required."
  exit 1
fi

# 2. Host & IP Info
echo "Host: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo ""

# 3. Disk List (총 용량 포함)
echo "[Disk_List]"
lsblk -d -e 1,7,11 -o NAME,SIZE,TYPE,ROTA,MODEL | awk 'NR>1 {print}' | while read -r name size type rota model; do
    disk_type="Unknown"
    if [[ "$name" == nvme* ]]; then disk_type="NVMe"
    elif [[ "$name" == mmcblk* ]]; then disk_type="eMMC/SD"
    elif [ "$rota" == "0" ]; then disk_type="SSD"
    elif [ "$rota" == "1" ]; then disk_type="HDD"
    fi
    echo "Device: /dev/$name, Type: $disk_type, Total_Capacity: $size, Model: $model"
done
echo ""

# 4. Health & SMART Status (ID 번호 기반 추출 로직으로 완전 교체)
echo "[Health_Status]"
lsblk -d -e 1,7,11 -o NAME | awk 'NR>1 {print}' | while read -r name; do
    dev_path="/dev/$name"
    echo "Device: $dev_path"
    
    if [[ "$name" == nvme* ]]; then
        if command -v nvme &> /dev/null; then
            nvme smart-log "$dev_path" | awk -F ':' '/critical_warning|temperature|percentage_used|power_on_hours|media_errors/ { gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); print $1 ": " $2 }'
        else
            echo "Error: nvme-cli missing"
        fi
    elif [[ "$name" == mmcblk* ]]; then
        if command -v mmc &> /dev/null; then
            mmc_info=$(mmc extcsd read "$dev_path" 2>/dev/null)
            life_a=$(echo "$mmc_info" | grep -i "Life Time Estimation A" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            life_b=$(echo "$mmc_info" | grep -i "Life Time Estimation B" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            if [ -n "$life_a" ]; then echo "Wear_Estimation_A: $life_a"; fi
            if [ -n "$life_b" ]; then echo "Wear_Estimation_B: $life_b"; fi
            if [ -z "$life_a" ]; then echo "Status: No detailed life info"; fi
        else
            echo "Error: mmc-utils missing"
        fi
    else
        # 일반 SATA/HDD (SMART ID 번호로 정확하게 타겟팅)
        if command -v smartctl &> /dev/null; then
            smart_out=$(smartctl -A "$dev_path" 2>/dev/null)
            
            # 남은 수명: ID 169, 177, 202, 231, 233의 'VALUE' 열($4). (+0으로 098을 98로 숫자 변환)
            life_val=$(echo "$smart_out" | awk '$1=="202" || $1=="231" || $1=="233" || $1=="177" || $1=="169" {print $4+0; exit}')
            
            # 불량 섹터: ID 5 의 'RAW_VALUE' 열($NF)
            bad_val=$(echo "$smart_out" | awk '$1=="5" {print $NF; exit}')
            
            # SATA 통신 에러: ID 199 의 'RAW_VALUE' 열($NF) - 사진에서 발견된 증상
            crc_val=$(echo "$smart_out" | awk '$1=="199" {print $NF; exit}')
            
            # 사용 시간: ID 9 의 'RAW_VALUE' 열($NF)
            power_val=$(echo "$smart_out" | awk '$1=="9" {print $NF; exit}')
            
            if [ -n "$life_val" ]; then echo "Life_Remaining_Percent: $life_val"; fi
            if [ -n "$bad_val" ]; then echo "Bad_Sectors: $bad_val"; fi
            if [ -n "$crc_val" ]; then echo "CRC_Errors: $crc_val"; fi
            if [ -n "$power_val" ]; then echo "Power_On_Hours: $power_val"; fi
            
            if [ -z "$life_val" ] && [ -z "$bad_val" ] && [ -z "$power_val" ]; then
               echo "Status: SMART not supported"
            fi
        else
            echo "Error: smartmontools missing"
        fi
    fi
done
echo ""

# 5. Mount Status (총 용량, 사용량, 남은 용량 등 상세 지표 명시)
echo "[Mount_Status]"
df -h -T -x tmpfs -x devtmpfs -x squashfs -x nfs -x nfs4 -x cifs -x smb3 -x overlay -x efivarfs | awk 'NR>1 {print "Partition: "$1", Type: "$2", Total_Capacity: "$3", Used_Capacity: "$4", Use%: "$6", Mountpoint: "$7}'
