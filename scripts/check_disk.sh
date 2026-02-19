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

# 2. 필수 패키지 설치 여부 및 자동 설치 점검

# 일반 HDD/SSD용 패키지 점검
if ! command -v smartctl &> /dev/null; then
    echo "[알림] smartmontools가 설치되어 있지 않아 일반 HDD/SSD 수명을 확인할 수 없습니다."
fi

# NVMe 장치 존재 여부 확인 후 자동 설치 프롬프트
if lsblk -d -o NAME | grep -q "^nvme"; then
    if ! command -v nvme &> /dev/null; then
        echo -e "\n[알림] 시스템에 NVMe 디스크가 감지되었으나, 'nvme-cli' 툴이 없습니다."
        read -p "OS를 자동 감지하여 nvme-cli를 설치하시겠습니까? (y/n): " choice_nvme
        case "$choice_nvme" in
            y|Y|yes|YES)
                echo "=> 설치를 진행합니다..."
                if command -v apt-get &> /dev/null; then apt-get update -qq && apt-get install -y nvme-cli
                elif command -v dnf &> /dev/null; then dnf install -y nvme-cli
                elif command -v yum &> /dev/null; then yum install -y nvme-cli
                fi
                ;;
        esac
    fi
fi

# eMMC / SD카드 장치 존재 여부 확인 후 자동 설치 프롬프트
if lsblk -d -o NAME | grep -q "^mmcblk"; then
    if ! command -v mmc &> /dev/null; then
        echo -e "\n[알림] 시스템에 eMMC/SD카드(mmcblk)가 감지되었으나, 'mmc-utils' 툴이 없습니다."
        read -p "OS를 자동 감지하여 mmc-utils를 설치하시겠습니까? (y/n): " choice_mmc
        case "$choice_mmc" in
            y|Y|yes|YES)
                echo "=> 설치를 진행합니다..."
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
# lsblk에서 루프백(7), CD-ROM(11)과 더불어 램디스크(1)를 원천 제외 (-e 1,7,11)
lsblk -d -e 1,7,11 -o NAME,SIZE,TYPE,ROTA,MODEL | awk 'NR>1 {print}' | while read -r name size type rota model; do
    disk_type="알 수 없음"
    # 이름과 ROTA(회전 여부) 값을 통해 디스크 종류 판별
    if [[ "$name" == nvme* ]]; then
        disk_type="NVMe SSD"
    elif [[ "$name" == mmcblk* ]]; then
        disk_type="eMMC / SD카드"
    elif [ "$rota" == "0" ]; then
        disk_type="SATA/SAS SSD"
    elif [ "$rota" == "1" ]; then
        disk_type="HDD"
    fi
    echo "✅ 디스크: /dev/$name | 종류: $disk_type | 용량: $size | 모델: $model"
done

echo -e "\n[2] 디스크별 건강 상태 및 수명"
echo "--------------------------------------------------"
lsblk -d -e 1,7,11 -o NAME | awk 'NR>1 {print}' | while read -r name; do
    dev_path="/dev/$name"
    echo -e "\n▶ 대상: $dev_path"
    
    if [[ "$name" == nvme* ]]; then
        # NVMe 디스크 처리
        if command -v nvme &> /dev/null; then
            echo "  [NVMe 상태]"
            nvme smart-log "$dev_path" | awk -F ':' '/critical_warning|temperature|percentage_used|power_on_hours/ { printf "  - %-20s : %s\n", $1, $2 }'
        else
            echo "  - nvme-cli 미설치로 정보 생략"
        fi
    elif [[ "$name" == mmcblk* ]]; then
        # eMMC / SD카드 처리
        if command -v mmc &> /dev/null; then
            echo "  [eMMC / SD카드 상태]"
            mmc_info=$(mmc extcsd read "$dev_path" 2>/dev/null)
            
            # 수명 정보 추출 (0x01 = 0~10%, 0x02 = 10~20% ... 0x0A = 90~100%, 0x0B = 수명초과)
            life_a=$(echo "$mmc_info" | grep -i "Life Time Estimation A" | awk -F: '{print $2}' | xargs)
            life_b=$(echo "$mmc_info" | grep -i "Life Time Estimation B" | awk -F: '{print $2}' | xargs)
            eol_info=$(echo "$mmc_info" | grep -i "Pre EOL information" | awk -F: '{print $2}' | xargs)
            
            if [ -n "$life_a" ]; then echo "  - 수명 예측 A (SLC) : $life_a (0x01에 가까울수록 새것)"; fi
            if [ -n "$life_b" ]; then echo "  - 수명 예측 B (MLC) : $life_b (0x01에 가까울수록 새것)"; fi
            if [ -n "$eol_info" ]; then echo "  - EOL(수명 종료) 징후 : $eol_info (0x01=정상)"; fi
            
            if [ -z "$life_a" ] && [ -z "$eol_info" ]; then
                echo "  - 상세 수명 정보를 제공하지 않는 일반 SD카드입니다."
            fi
        else
            echo "  - mmc-utils 미설치로 정보 생략"
        fi
    else
        # 일반 SATA/SAS HDD 및 SSD 처리
        if command -v smartctl &> /dev/null; then
            echo "  [SATA/HDD 상태]"
            smart_out=$(smartctl -A "$dev_path" 2>/dev/null)
            
            wear_out=$(echo "$smart_out" | grep -i -E 'Media_Wearout_Indicator|Percentage_Used' | awk '{print "수명 마모도(Percentage Used) : " $10}')
            reallocated=$(echo "$smart_out" | grep -i 'Reallocated_Sector_Ct' | awk '{print "배드섹터(Reallocated Sector) : " $10}')
            power_on=$(echo "$smart_out" | grep -i 'Power_On_Hours' | awk '{print "총 사용 시간(Power On Hours) : " $10 " 시간"}')
            
            if [ -n "$wear_out" ]; then echo "  - $wear_out"; fi
            if [ -n "$reallocated" ]; then echo "  - $reallocated"; fi
            if [ -n "$power_on" ]; then echo "  - $power_on"; fi
            
            if [ -z "$wear_out" ] && [ -z "$reallocated" ] && [ -z "$power_on" ]; then
               echo "  - S.M.A.R.T 정보를 불러올 수 없는 디스크입니다."
            fi
        else
            echo "  - smartmontools 미설치로 정보 생략"
        fi
    fi
done

echo -e "\n[3] 로컬 파티션 마운트 상태 및 여유 용량"
echo "--------------------------------------------------"
# 불필요한 가상 시스템 완벽 제외 (네트워크, overlay, efivarfs 등)
df -h -T -x tmpfs -x devtmpfs -x squashfs -x nfs -x nfs4 -x cifs -x smb3 -x overlay -x efivarfs
echo "=================================================="
