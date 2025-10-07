#!/bin/bash

# Proxmox LXC 설정 파일에 장치 패스스루 및 권한 설정 변경 (최종)

# 1. 컨테이너 ID 입력받기
read -p "장치를 설정할 LXC 컨테이너 ID를 입력하십시오 (예: 101): " CTID

# 입력 검증
if ! [[ "$CTID" =~ ^[0-9]+$ ]]; then
    echo "🚨 오류: 유효한 컨테이너 ID를 입력하십시오. 스크립트를 종료합니다."
    exit 1
fi

# 컨테이너 설정 파일 경로
CONF_DIR="/etc/pve/lxc"
CONF_FILE="${CONF_DIR}/${CTID}.conf"

if [ ! -f "$CONF_FILE" ]; then
    echo "🚨 오류: 컨테이너 ID ${CTID}의 설정 파일 (${CONF_FILE})을 찾을 수 없습니다. 스크립트를 종료합니다."
    exit 1
fi

echo "✅ 컨테이너 ID ${CTID}의 설정 파일 (${CONF_FILE})을 확인했습니다."

# --- 현재 설정 표시 ---
## 2. 현재 설정 파일 내용 표시
echo
echo "=================================================="
echo "   [ ${CTID}.conf ] 현재 설정 파일 내용"
echo "=================================================="
cat "$CONF_FILE"
echo "=================================================="
echo

read -p "👆 위의 설정 파일에 장치 패스스루 및 권한 설정을 변경/추가하시겠습니까? (y/n): " PROCEED
if ! [[ "$PROCEED" =~ ^[Yy]$ ]]; then
    echo "작업을 취소합니다. 스크립트를 종료합니다."
    exit 0
fi

# 3. 설정 파일 백업
BACKUP_FILE="${CONF_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$CONF_FILE" "$BACKUP_FILE"
echo "💾 설정 파일을 백업했습니다: **${BACKUP_FILE}**"

# --- LXC 권한 설정 변경 ---
## 4. 루트 권한(Privileged) 설정 적용
echo
echo "--- LXC 컨테이너 루트 권한(Privileged) 설정 ---"

# unprivileged: 1 설정 확인
if grep -q "unprivileged: 1" "$CONF_FILE"; then
    echo "⚠️ **경고**: 현재 컨테이너는 **비권한(Unprivileged)** 상태입니다."
    read -p "➡️ 이 컨테이너를 **권한 있는(Privileged)** 상태로 변경하시겠습니까? (보안 위험 증가) (y/n): " CHANGE_PRIVILEGE
    
    if [[ "$CHANGE_PRIVILEGE" =~ ^[Yy]$ ]]; then
        # 'unprivileged: 1' 라인을 삭제하여 권한 있는 컨테이너로 변경
        # Privileged 컨테이너는 unprivileged: 0 이거나 해당 라인이 없습니다.
        sed -i '/unprivileged: 1/d' "$CONF_FILE"
        echo "   ✅ **unprivileged: 1** 라인을 삭제했습니다. 컨테이너는 **권한 있는 (Privileged)** 상태로 실행됩니다."
    else
        echo "   ℹ️ 권한 설정을 변경하지 않고 넘어갑니다."
    fi
elif grep -q "unprivileged: 0" "$CONF_FILE"; then
    echo "   ℹ️ 컨테이너는 이미 **권한 있는 (Privileged)** 상태로 설정되어 있습니다 (unprivileged: 0)."
else
    echo "   ℹ️ 'unprivileged' 설정이 명시되지 않았거나, 이미 권한 있는 상태입니다. (기본값: Privileged)"
fi

# 5. 장치 추가 함수 정의 (Proxmox 8.1+ devN: 방식)
add_device_passthrough() {
    local DEVICE_PATH="$1"
    local DESCRIPTION="$2"

    # 설정 파일에서 devN: 으로 시작하고 해당 장치 경로를 포함하는 라인 확인
    if grep -qE "^dev[0-9]+: ${DEVICE_PATH}," "$CONF_FILE"; then
        echo "   ℹ️ **${DESCRIPTION}** (${DEVICE_PATH}) 설정은 이미 존재합니다. 스킵합니다."
    else
        # 다음 devN 번호를 찾기
        LAST_DEV_NUM=$(grep -oE "^dev[0-9]+:" "$CONF_FILE" | grep -oE "[0-9]+" | sort -n | tail -n 1)
        NEXT_DEV_NUM=0
        if [ -n "$LAST_DEV_NUM" ]; then
            NEXT_DEV_NUM=$((LAST_DEV_NUM + 1))
        fi

        NEW_ENTRY="dev${NEXT_DEV_NUM}: ${DEVICE_PATH},mountpoint=${DEVICE_PATH}"

        # 파일에 추가
        echo "$NEW_ENTRY" >> "$CONF_FILE"
        echo "   ➕ **${DESCRIPTION}** (${DEVICE_PATH}) 설정을 추가했습니다: ${NEW_ENTRY}"
    fi
}

# --- 장치 추가 요청 및 실행 ---
echo
echo "--- 장치 패스스루 추가 ---"
echo

# /dev/kvm (KVM 가상화)
read -p "➡️ /dev/kvm (KVM 가상화) 장치 패스스루를 추가하시겠습니까? (y/n): " ADD_KVM
if [[ "$ADD_KVM" =~ ^[Yy]$ ]]; then
    if [ ! -e "/dev/kvm" ]; then
        echo "   ⚠️ 경고: 호스트에 /dev/kvm 장치가 존재하지 않습니다."
    fi
    add_device_passthrough "/dev/kvm" "KVM Virtualization"
fi

# /dev/dri (통합 GPU 가속)
read -p "➡️ /dev/dri (통합 GPU 가속) 장치 패스스루를 추가하시겠습니까? (y/n): " ADD_DRI
if [[ "$ADD_DRI" =~ ^[Yy]$ ]]; then
    DRI_DEVICES=$(find /dev/dri -type c 2>/dev/null)
    if [ -z "$DRI_DEVICES" ]; then
        echo "   ⚠️ 경고: 호스트에 /dev/dri 장치가 없습니다."
    else
        echo "   🔎 /dev/dri 장치들을 찾았습니다. 모든 장치를 추가합니다."
        for DEV_PATH in $DRI_DEVICES; do
            if [ -c "$DEV_PATH" ]; then
                add_device_passthrough "$DEV_PATH" "DRI Device"
            fi
        done
        echo "   ⚙️ 참고: GPU 가속을 위해 컨테이너 내부에서 권한 설정 (gid 등)이 추가로 필요할 수 있습니다."
    fi
fi

# /dev/kfd (AMD GPU Compute)
read -p "➡️ /dev/kfd (AMD GPU Compute) 장치 패스스루를 추가하시겠습니까? (y/n): " ADD_KFD
if [[ "$ADD_KFD" =~ ^[Yy]$ ]]; then
    if [ ! -e "/dev/kfd" ]; then
        echo "   ⚠️ 경고: 호스트에 /dev/kfd 장치가 존재하지 않습니다."
    fi
    add_device_passthrough "/dev/kfd" "AMD GPU Compute (KFD)"
fi

# /dev/net/tun (VPN, WireGuard 등)
read -p "➡️ /dev/net/tun (VPN/TUN/TAP) 장치 패스스루를 추가하시겠습니까? (y/n): " ADD_TUN
if [[ "$ADD_TUN" =~ ^[Yy]$ ]]; then
    if [ ! -e "/dev/net/tun" ]; then
        echo "   ⚠️ 경고: 호스트에 /dev/net/tun 장치가 존재하지 않습니다."
    fi

    echo "   ⚙️ /dev/net/tun 장치에는 lxc.cgroup2.devices.allow 및 lxc.mount.entry가 필요합니다."
    
    CGROUP_LINE="lxc.cgroup2.devices.allow: c 10:200 rwm"
    MOUNT_LINE="lxc.mount.entry: /dev/net/tun dev/net/tun none bind,optional,create=file"

    # Cgroup 설정 중복 확인 및 추가
    if grep -qF "$CGROUP_LINE" "$CONF_FILE"; then
        echo "   ℹ️ Cgroup 설정은 이미 존재합니다. 스킵합니다."
    else
        echo "$CGROUP_LINE" >> "$CONF_FILE"
        echo "   ➕ Cgroup 설정 추가: $CGROUP_LINE"
    fi

    # Mount Entry 설정 중복 확인 및 추가
    if grep -qF "$MOUNT_LINE" "$CONF_FILE"; then
        echo "   ℹ️ Mount Entry 설정은 이미 존재합니다. 스킵합니다."
    else
        echo "$MOUNT_LINE" >> "$CONF_FILE"
        echo "   ➕ Mount Entry 설정 추가: $MOUNT_LINE"
    fi
fi

# 6. 완료 메시지
echo
echo "=================================================="
echo "✅ 작업이 완료되었습니다."
echo "   수정된 설정 파일: ${CONF_FILE}"
echo "   백업 파일: **${BACKUP_FILE}**"
echo "   변경 사항을 적용하려면 컨테이너를 **재시작**해야 합니다."
echo "=================================================="

exit 0
