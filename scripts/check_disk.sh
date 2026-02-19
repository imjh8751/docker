#!/bin/bash

# 1. Root 권한 체크
if [ "$EUID" -ne 0 ]; then
  echo "[오류] 디스크의 물리적 수명(S.M.A.R.T 및 eMMC)을 읽으려면 root 권한이 필요합니다."
  echo "실행 방법: sudo $0"
  exit 1
fi

echo "=================================================="
echo "       로컬 물리 디스크 상태 및 수명 점검         "
echo "=================================================="

# 2. 필수 패키지 설치 여부 점검 (자동 설치 프롬프트 포함)
if ! command -v smartctl &> /dev/null; then
    echo "[알림] smartmontools가 설치되어 있지 않아 일반 HDD/SSD 수명을 확인할 수 없습니다."
fi

if lsblk -d -o NAME | grep -q "^nvme"; then
    if ! command -v nvme &> /dev/null; then
        echo -e "\n[알림] 시스템에 NVMe 디스크가 감지되었으나, 'nvme-cli' 툴이 없습니다."
        read -p "OS를 자동 감지하여 nvme-cli를 설치하시겠습니까? (y/n): " choice_nvme
        case "$choice_nvme" in
            y|Y|yes|YES)
                if command -v apt-get &> /dev/null; then apt-get update -qq && apt-get install -y nvme-cli
                elif command -v dnf &> /dev/null; then dnf install -y nvme-cli
                elif command -v yum &> /dev/null; then yum install -y nvme-cli
                fi
                ;;
        esac
    fi
fi

if lsblk -d -o NAME | grep -q "^mmcblk"; then
    if ! command -v mmc &> /dev/null; then
        echo -e "\n[알림] 시스템에 eMMC/SD카드(mmcblk)가 감지되었으나, 'mmc-utils' 툴이 없습니다."
        read -p "OS를 자동 감지하여 mmc-utils를 설치하시겠습니까? (y/n): " choice_mmc
        case "$choice_mmc" in
            y|Y|yes|YES)
                if command -v apt-get &> /dev/null; then apt-get update -qq && apt-get install -y mmc-utils
                elif command -v dnf &> /dev/null; then dnf install -y mmc-utils
                elif command -v yum &> /dev/null; then yum install -y mmc-utils
                fi
                ;;
        esac
    fi
fi

echo -e "\n[1] 장착된 로컬 디스크 목록 및 종류"
echo "--------------------------------------------------"
lsblk -d -e 1,7,11 -o NAME,SIZE,TYPE,ROTA,MODEL | awk 'NR>1 {print}' | while read -r name size type rota model; do
    disk_type="알 수 없음"
    if [[ "$name" == nvme* ]]; then disk_type="NVMe SSD"
    elif [[ "$name" == mmcblk* ]]; then disk_type="eMMC / SD카드"
    elif [ "$rota" == "0" ]; then disk_type="SATA/SAS SSD"
    elif [ "$rota" == "1" ]; then disk_type="HDD"
    fi
    echo "✅ 디스크: /dev/$name | 종류: $disk_type | 용량: $size | 모델: $model"
done

echo -e "\n[2] 디스크별 건강 상태 및 수명"
echo "--------------------------------------------------"
lsblk -d -e 1,7,11 -o NAME | awk 'NR>1 {print}' | while read -r name; do
    dev_path="/dev/$name"
    echo -e "\n▶ 대상: $dev_path"
    
    if [[ "$name" == nvme* ]]; then
        if command -v nvme &> /dev/null; then
            echo "  [NVMe 상태]"
            nvme smart-log "$dev_path" | awk -F ':' '/critical_warning|temperature|percentage_used|power_on_hours|media_errors/ { printf "  - %-20s : %s\n", $1, $2 }'
        else
            echo "  - nvme-cli 미설치로 정보 생략"
        fi
    elif [[ "$name" == mmcblk* ]]; then
        if command -v mmc &> /dev/null; then
            echo "  [eMMC / SD카드 상태]"
            mmc_info=$(mmc extcsd read "$dev_path" 2>/dev/null)
            life_a=$(echo "$mmc_info" | grep -i "Life Time Estimation A" | awk -F: '{print $2}' | xargs)
            life_b=$(echo "$mmc_info" | grep -i "Life Time Estimation B" | awk -F: '{print $2}' | xargs)
            eol_info=$(echo "$mmc_info" | grep -i "Pre EOL information" | awk -F: '{print $2}' | xargs)
            
            if [ -n "$life_a" ]; then echo "  - 수명 예측 A (SLC) : $life_a (0x01에 가까울수록 새것)"; fi
            if [ -n "$life_b" ]; then echo "  - 수명 예측 B (MLC) : $life_b (0x01에 가까울수록 새것)"; fi
            if [ -n "$eol_info" ]; then echo "  - EOL(수명 종료) 징후 : $eol_info (0x01=정상)"; fi
            if [ -z "$life_a" ] && [ -z "$eol_info" ]; then echo "  - 상세 수명 정보를 제공하지 않는 일반 SD카드입니다."; fi
        else
            echo "  - mmc-utils 미설치로 정보 생략"
        fi
    else
        if command -v smartctl &> /dev/null; then
            echo "  [SATA/HDD 상태]"
            smart_out=$(smartctl -A "$dev_path" 2>/dev/null)
            
            # 개선된 추출 방식: Crucial, Samsung 등 다양한 이름 대응 및 제일 마지막 값($NF) 무조건 추출
            wear_info=$(echo "$smart_out" | awk 'tolower($0) ~ /media_wearout_indicator|percentage_used|percent_lifetime_remain/ {print "  - 수명 지표 (" $2 ") : " $NF; exit}')
            bad_info=$(echo "$smart_out" | awk 'tolower($0) ~ /reallocated_sector_ct/ {print "  - 배드섹터 (" $2 ") : " $NF; exit}')
            power_info=$(echo "$smart_out" | awk 'tolower($0) ~ /power_on_hours/ {print "  - 총 사용 시간 (" $2 ") : " $NF " 시간"; exit}')
            
            if [ -n "$wear_info" ]; then echo "$wear_info"; fi
            if [ -n "$bad_info" ]; then echo "$bad_info"; fi
            if [ -n "$power_info" ]; then echo "$power_info"; fi
            
            if [ -z "$wear_info" ] && [ -z "$bad_info" ] && [ -z "$power_info" ]; then
               echo "  - S.M.A.R.T 정보를 불러올 수 없는 디스크입니다."
            fi
        else
            echo "  - smartmontools 미설치로 정보 생략"
        fi
    fi
done

echo -e "\n[3] 로컬 파티션 마운트 상태 및 여유 용량"
echo "--------------------------------------------------"
df -h -T -x tmpfs -x devtmpfs -x squashfs -x nfs -x nfs4 -x cifs -x smb3 -x overlay -x efivarfs
echo "=================================================="
