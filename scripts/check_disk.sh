#!/bin/bash

# 1. Root 권한 체크 (S.M.A.R.T 정보 조회용)
if [ "$EUID" -ne 0 ]; then
  echo "[오류] 디스크의 물리적 수명(S.M.A.R.T)을 읽으려면 root 권한이 필요합니다."
  echo "실행 방법: sudo $0"
  exit 1
fi

echo "=================================================="
echo "       로컬 물리 디스크 상태 및 수명 점검         "
echo "=================================================="

# 2. 필수 패키지 설치 여부 점검
if ! command -v smartctl &> /dev/null; then
    echo "[알림] smartmontools가 설치되어 있지 않아 일반 HDD/SSD 수명을 확인할 수 없습니다."
    echo "       설치 권장: sudo apt install smartmontools (또는 yum install smartmontools)"
fi

if ! command -v nvme &> /dev/null; then
    echo "[알림] nvme-cli가 설치되어 있지 않아 NVMe 디스크 수명을 확인할 수 없습니다."
    echo "       설치 권장: sudo apt install nvme-cli (또는 yum install nvme-cli)"
fi

echo -e "\n[1] 장착된 로컬 디스크 목록 및 종류"
echo "--------------------------------------------------"
# lsblk로 물리 디스크(-d)만 조회. 루프백(7), CD-ROM(11) 제외.
lsblk -d -e 7,11 -o NAME,SIZE,TYPE,ROTA,MODEL | grep "disk" | while read -r name size type rota model; do
    disk_type="알 수 없음"
    # 이름과 ROTA(회전 여부) 값을 통해 디스크 종류 판별
    if [[ "$name" == nvme* ]]; then
        disk_type="NVMe SSD"
    elif [ "$rota" == "0" ]; then
        disk_type="SATA/SAS SSD"
    elif [ "$rota" == "1" ]; then
        disk_type="HDD"
    fi
    echo "✅ 디스크: /dev/$name | 종류: $disk_type | 용량: $size | 모델: $model"
done

echo -e "\n[2] 디스크별 건강 상태 및 수명 (S.M.A.R.T)"
echo "--------------------------------------------------"
lsblk -d -e 7,11 -o NAME,TYPE | grep "disk" | awk '{print $1}' | while read -r name; do
    dev_path="/dev/$name"
    echo -e "\n▶ 대상: $dev_path"
    
    if [[ "$name" == nvme* ]]; then
        # NVMe 디스크 처리
        if command -v nvme &> /dev/null; then
            echo "  [NVMe 상태]"
            # 주요 지표 추출: 경고, 온도, 사용률(수명), 사용시간
            nvme smart-log "$dev_path" | awk -F ':' '/critical_warning|temperature|percentage_used|power_on_hours/ { printf "  - %-20s : %s\n", $1, $2 }'
        else
            echo "  - nvme-cli 미설치로 정보 생략"
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
# -x 옵션을 사용해 네트워크(nfs, cifs, smb3) 및 불필요한 가상 시스템(tmpfs, squashfs 등) 완벽히 제외
df -h -T -x tmpfs -x devtmpfs -x squashfs -x nfs -x nfs4 -x cifs -x smb3
echo "=================================================="
