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

# 3. Disk List
echo "[Disk_List]"
lsblk -d -e 1,7,11 -o NAME,SIZE,TYPE,ROTA,MODEL | awk 'NR>1 {print}' | while read -r name size type rota model; do
    disk_type="Unknown"
    if [[ "$name" == nvme* ]]; then disk_type="NVMe"
    elif [[ "$name" == mmcblk* ]]; then disk_type="eMMC/SD"
    elif [ "$rota" == "0" ]; then disk_type="SSD"
    elif [ "$rota" == "1" ]; then disk_type="HDD"
    fi
    echo "Device: /dev/$name, Type: $disk_type, Size: $size, Model: $model"
done
echo ""

# 4. Health & SMART Status
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
            eol_info=$(echo "$mmc_info" | grep -i "Pre EOL information" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            
            if [ -n "$life_a" ]; then echo "Wear_Estimation_A: $life_a"; fi
            if [ -n "$life_b" ]; then echo "Wear_Estimation_B: $life_b"; fi
            if [ -n "$eol_info" ]; then echo "Pre_EOL_Warning: $eol_info"; fi
            if [ -z "$life_a" ] && [ -z "$eol_info" ]; then echo "Status: No detailed life info"; fi
        else
            echo "Error: mmc-utils missing"
        fi
    else
        # 일반 SATA/HDD (규격화된 Key 추출)
        if command -v smartctl &> /dev/null; then
            smart_out=$(smartctl -A "$dev_path" 2>/dev/null)
            
            # 각각의 항목을 정확히 grep으로 낚아채어 맨 마지막 열($NF)의 숫자만 추출
            wear_raw=$(echo "$smart_out" | grep -i -E "media_wearout_indicator|percentage_used|percent_lifetime_remain" | head -n 1 | awk '{print $NF}')
            bad_raw=$(echo "$smart_out" | grep -i "reallocated_sector_ct" | head -n 1 | awk '{print $NF}')
            power_raw=$(echo "$smart_out" | grep -i "power_on_hours" | head -n 1 | awk '{print $NF}')
            
            # AI가 읽기 쉽도록 통일된 이름(Key)으로 출력
            if [ -n "$wear_raw" ]; then echo "Wear_Indicator: $wear_raw"; fi
            if [ -n "$bad_raw" ]; then echo "Bad_Sectors: $bad_raw"; fi
            if [ -n "$power_raw" ]; then echo "Power_On_Hours: $power_raw"; fi
            
            if [ -z "$wear_raw" ] && [ -z "$bad_raw" ] && [ -z "$power_raw" ]; then
               echo "Status: SMART not supported"
            fi
        else
            echo "Error: smartmontools missing"
        fi
    fi
done
echo ""

# 5. Mount Status
echo "[Mount_Status]"
df -h -T -x tmpfs -x devtmpfs -x squashfs -x nfs -x nfs4 -x cifs -x smb3 -x overlay -x efivarfs | awk 'NR>1 {print "Filesystem: "$1", Type: "$2", Size: "$3", Used: "$4", Avail: "$5", Use%: "$6", Mountpoint: "$7}'
