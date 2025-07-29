#!/bin/bash

# Proxmox GPU 설치 및 설정 스크립트 v2.0
# Debian 기반 Proxmox용 (VM 및 LXC 지원)

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# root 권한 확인
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "이 스크립트는 root 권한이 필요합니다. sudo를 사용하여 실행하세요."
        exit 1
    fi
}

# GPU 감지
detect_gpu() {
    log_info "시스템의 GPU를 감지하는 중..."
    
    # lspci로 GPU 정보 확인
    nvidia_gpu=$(lspci | grep -i nvidia | wc -l)
    amd_gpu=$(lspci | grep -i amd | grep -i vga | wc -l)
    intel_gpu=$(lspci | grep -i intel | grep -i vga | wc -l)
    
    echo
    log_info "감지된 GPU:"
    lspci | grep -E "(VGA|3D|Display)"
    echo
    
    if [ $nvidia_gpu -gt 0 ]; then
        GPU_TYPE="nvidia"
        log_info "NVIDIA GPU가 감지되었습니다."
    elif [ $amd_gpu -gt 0 ]; then
        GPU_TYPE="amd"
        log_info "AMD GPU가 감지되었습니다."
    elif [ $intel_gpu -gt 0 ]; then
        GPU_TYPE="intel"
        log_info "Intel GPU가 감지되었습니다."
    else
        GPU_TYPE="unknown"
        log_warning "지원되는 GPU를 찾을 수 없습니다."
    fi
}

# 패키지 업데이트
update_system() {
    log_info "시스템 패키지를 업데이트하는 중..."
    apt update && apt upgrade -y
    log_success "시스템 업데이트 완료"
}

# 필수 패키지 설치
install_base_packages() {
    log_info "필수 패키지를 설치하는 중..."
    apt install -y \
        curl \
        wget \
        gnupg \
        software-properties-common \
        build-essential \
        dkms \
        linux-headers-$(uname -r) \
        pciutils \
        lshw \
        mesa-utils
    log_success "필수 패키지 설치 완료"
}

# NVIDIA 드라이버 설치
install_nvidia_driver() {
    log_info "NVIDIA 드라이버를 설치하는 중..."
    
    # 기존 드라이버 제거
    apt remove --purge nvidia* -y
    apt autoremove -y
    
    # NVIDIA 저장소 추가
    add-apt-repository contrib -y
    apt update
    
    # 자동으로 최적의 드라이버 감지 및 설치
    apt install -y nvidia-detect
    RECOMMENDED_DRIVER=$(nvidia-detect | grep -o 'nvidia-driver-[0-9]*')
    
    if [ -n "$RECOMMENDED_DRIVER" ]; then
        log_info "권장 드라이버: $RECOMMENDED_DRIVER"
        apt install -y $RECOMMENDED_DRIVER nvidia-settings
    else
        log_info "최신 드라이버를 설치합니다..."
        apt install -y nvidia-driver nvidia-settings
    fi
    
    # CUDA 런타임 설치 (선택사항)
    read -p "CUDA 런타임을 설치하시겠습니까? (y/n): " install_cuda
    if [ "$install_cuda" = "y" ] || [ "$install_cuda" = "Y" ]; then
        apt install -y nvidia-cuda-toolkit
        log_success "CUDA 런타임 설치 완료"
    fi
    
    log_success "NVIDIA 드라이버 설치 완료"
}

# AMD 드라이버 설치
install_amd_driver() {
    log_info "AMD 드라이버를 설치하는 중..."
    
    # Mesa 드라이버 설치
    apt install -y \
        mesa-vulkan-drivers \
        libgl1-mesa-dri \
        libglx-mesa0 \
        mesa-utils \
        xserver-xorg-video-amdgpu
    
    # Proxmox용 펌웨어 (pve-firmware 사용)
    if ! dpkg -l | grep -q pve-firmware; then
        log_info "Proxmox 펌웨어 패키지를 설치합니다..."
        apt install -y pve-firmware
    else
        log_info "Proxmox 펌웨어가 이미 설치되어 있습니다."
    fi
    
    log_success "AMD 드라이버 설치 완료"
}

# Intel 드라이버 설치
install_intel_driver() {
    log_info "Intel 드라이버를 설치하는 중..."
    
    apt install -y \
        intel-gpu-tools \
        xserver-xorg-video-intel \
        mesa-utils \
        libgl1-mesa-dri \
        intel-media-va-driver-non-free
    
    log_success "Intel 드라이버 설치 완료"
}

# VM GPU 패스스루 설정 (IOMMU)
setup_vm_gpu_passthrough() {
    log_info "VM GPU 패스스루를 위한 IOMMU 설정..."
    
    # GRUB 설정 백업
    cp /etc/default/grub /etc/default/grub.backup
    
    # Intel CPU인지 AMD CPU인지 확인
    cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')
    
    if [[ $cpu_vendor == "GenuineIntel" ]]; then
        iommu_setting="intel_iommu=on"
    elif [[ $cpu_vendor == "AuthenticAMD" ]]; then
        iommu_setting="amd_iommu=on"
    else
        iommu_setting="intel_iommu=on amd_iommu=on"
    fi
    
    # GRUB 설정 수정
    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $iommu_setting iommu=pt\"/" /etc/default/grub
    
    # GRUB 업데이트
    update-grub
    
    # VFIO 모듈 설정
    echo "vfio" >> /etc/modules
    echo "vfio_iommu_type1" >> /etc/modules
    echo "vfio_pci" >> /etc/modules
    echo "vfio_virqfd" >> /etc/modules
    
    update-initramfs -u
    
    log_success "VM GPU 패스스루 설정 완료"
    log_warning "재부팅이 필요합니다."
}

# LXC GPU 패스스루 설정
setup_lxc_gpu_passthrough() {
    log_info "LXC GPU 패스스루 설정을 시작합니다..."
    
    # DRI 디바이스 확인
    log_info "현재 DRI 디바이스 확인..."
    ls -la /dev/dri/
    
    # 디바이스 번호 확인
    log_info "GPU 디바이스 번호 확인..."
    if [ -c /dev/dri/card0 ]; then
        stat /dev/dri/card0 | grep -o "Device: .*" || true
    fi
    if [ -c /dev/dri/renderD128 ]; then
        stat /dev/dri/renderD128 | grep -o "Device: .*" || true
    fi
    
    # udev 규칙 생성 (권한 설정)
    log_info "GPU 디바이스 권한을 위한 udev 규칙 생성..."
    cat > /etc/udev/rules.d/99-gpu-chmod666.rules << 'EOF'
KERNEL=="renderD128", MODE="0666"
KERNEL=="card0", MODE="0666"
KERNEL=="card*", MODE="0666"
KERNEL=="renderD*", MODE="0666"
EOF
    
    # udev 규칙 적용
    udevadm control --reload-rules
    udevadm trigger
    
    log_info "LXC 컨테이너 설정 예시를 생성합니다..."
    
    # LXC 설정 예시 파일 생성
    cat > /tmp/lxc_gpu_config_example.txt << 'EOF'
# AMD GPU LXC 패스스루 설정 예시
# 다음 내용을 /etc/pve/lxc/[CONTAINER_ID].conf 파일에 추가하세요

# GPU 디바이스 허용 (cgroup2 설정)
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm

# DRI 디바이스 마운트
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file

# 권한이 없는 컨테이너의 경우 (unprivileged=1)
# render 그룹 매핑이 필요할 수 있습니다
# lxc.idmap: g 0 100000 44
# lxc.idmap: g 44 44 1  
# lxc.idmap: g 45 100045 59
# lxc.idmap: g 104 104 1
# lxc.idmap: g 105 100105 65431
EOF
    
    log_success "LXC GPU 패스스루 설정 준비 완료!"
    echo
    log_info "설정 예시 파일: /tmp/lxc_gpu_config_example.txt"
    log_info "다음 단계:"
    echo "1. LXC 컨테이너를 생성하세요"
    echo "2. /etc/pve/lxc/[CONTAINER_ID].conf 파일을 편집하세요"
    echo "3. 위 설정 예시를 파일에 추가하세요"
    echo "4. 컨테이너를 재시작하세요"
    echo "5. 컨테이너 내에서 'ls -la /dev/dri/'로 확인하세요"
    echo
    
    # 설정 도우미 제공
    read -p "LXC 컨테이너 ID를 입력하면 자동으로 설정을 적용하시겠습니까? (컨테이너 ID 입력 또는 Enter로 건너뛰기): " container_id
    
    if [ -n "$container_id" ] && [ "$container_id" -gt 0 ] 2>/dev/null; then
        config_file="/etc/pve/lxc/${container_id}.conf"
        
        if [ -f "$config_file" ]; then
            log_info "컨테이너 $container_id 설정 파일에 GPU 패스스루 설정을 추가합니다..."
            
            # 기존 GPU 설정이 있는지 확인
            if grep -q "lxc.cgroup2.devices.allow: c 226:" "$config_file"; then
                log_warning "이미 GPU 설정이 존재합니다. 수동으로 확인해주세요."
            else
                # GPU 설정 추가
                echo "" >> "$config_file"
                echo "# AMD GPU passthrough settings" >> "$config_file"
                echo "lxc.cgroup2.devices.allow: c 226:0 rwm" >> "$config_file"
                echo "lxc.cgroup2.devices.allow: c 226:128 rwm" >> "$config_file"
                echo "lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir" >> "$config_file"
                echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file" >> "$config_file"
                echo "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file" >> "$config_file"
                
                log_success "컨테이너 $container_id에 GPU 설정이 추가되었습니다!"
                log_warning "컨테이너를 재시작해야 설정이 적용됩니다."
            fi
        else
            log_error "컨테이너 $container_id의 설정 파일을 찾을 수 없습니다."
        fi
    fi
}

# GPU 상태 확인
check_gpu_status() {
    log_info "GPU 상태를 확인하는 중..."
    
    echo
    echo "=== GPU 정보 ==="
    lspci | grep -E "(VGA|3D|Display)"
    
    echo
    echo "=== 로드된 그래픽 모듈 ==="
    lsmod | grep -E "(nvidia|amdgpu|i915|nouveau)"
    
    if command -v nvidia-smi &> /dev/null; then
        echo
        echo "=== NVIDIA GPU 상태 ==="
        nvidia-smi
    fi
    
    # Proxmox 환경에서는 X11이 없으므로 다른 방법으로 GPU 상태 확인
    echo
    echo "=== GPU 메모리 정보 ==="
    if [ -d /sys/class/drm ]; then
        for card in /sys/class/drm/card*; do
            if [ -f "$card/device/vendor" ] && [ -f "$card/device/device" ]; then
                vendor=$(cat "$card/device/vendor")
                device=$(cat "$card/device/device")
                echo "카드: $(basename $card), Vendor: $vendor, Device: $device"
            fi
        done
    fi
    
    echo
    echo "=== DRM 디바이스 ==="
    ls -la /dev/dri/ 2>/dev/null || echo "DRM 디바이스를 찾을 수 없습니다."
    
    echo
    echo "=== GPU 온도 및 클록 (가능한 경우) ==="
    if [ -d /sys/class/drm/card0/device/hwmon ]; then
        for hwmon in /sys/class/drm/card0/device/hwmon/hwmon*; do
            if [ -f "$hwmon/temp1_input" ]; then
                temp=$(($(cat "$hwmon/temp1_input") / 1000))
                echo "GPU 온도: ${temp}°C"
            fi
        done
    fi
    
    # Proxmox 환경 안내
    echo
    echo "=== Proxmox 환경 안내 ==="
    log_info "Proxmox는 서버 OS이므로 GUI 환경이 없습니다."
    log_info "OpenGL 오류는 정상이며, GPU는 VM/LXC 패스스루용으로 사용 가능합니다."
    log_info "VM에서 GPU를 사용하려면 Proxmox 웹 인터페이스에서 GPU를 할당하세요."
    log_info "LXC에서 GPU를 사용하려면 컨테이너 설정에 디바이스를 마운트하세요."
}

# 메인 메뉴
show_menu() {
    clear
    echo "======================================"
    echo "    Proxmox GPU 설치 스크립트 v2.0"
    echo "======================================"
    echo "1. 시스템 업데이트"
    echo "2. GPU 감지"
    echo "3. NVIDIA 드라이버 설치"
    echo "4. AMD 드라이버 설치"
    echo "5. Intel 드라이버 설치"
    echo "6. VM GPU 패스스루 설정 (IOMMU)"
    echo "7. LXC GPU 패스스루 설정"
    echo "8. GPU 상태 확인"
    echo "9. 전체 자동 설치"
    echo "10. 종료"
    echo "======================================"
}

# 자동 설치
auto_install() {
    log_info "자동 설치를 시작합니다..."
    
    update_system
    install_base_packages
    detect_gpu
    
    case $GPU_TYPE in
        "nvidia")
            install_nvidia_driver
            ;;
        "amd")
            install_amd_driver
            ;;
        "intel")
            install_intel_driver
            ;;
        *)
            log_warning "지원되지 않는 GPU 타입입니다."
            ;;
    esac
    
    echo
    log_info "패스스루 설정 옵션을 선택하세요:"
    echo "1. VM GPU 패스스루 (IOMMU)"
    echo "2. LXC GPU 패스스루"
    echo "3. 패스스루 설정 안함"
    read -p "선택 (1-3): " passthrough_choice
    
    case $passthrough_choice in
        1)
            setup_vm_gpu_passthrough
            ;;
        2)
            setup_lxc_gpu_passthrough
            ;;
        3)
            log_info "패스스루 설정을 건너뜁니다."
            ;;
        *)
            log_warning "잘못된 선택입니다. 패스스루 설정을 건너뜁니다."
            ;;
    esac
    
    check_gpu_status
    
    log_success "자동 설치가 완료되었습니다!"
    if [ "$passthrough_choice" = "1" ]; then
        log_warning "VM 패스스루 설정을 위해 시스템 재부팅이 필요합니다."
    fi
}

# 메인 실행
main() {
    check_root
    
    while true; do
        show_menu
        read -p "선택하세요 (1-10): " choice
        
        case $choice in
            1)
                update_system
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            2)
                detect_gpu
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            3)
                install_nvidia_driver
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            4)
                install_amd_driver
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            5)
                install_intel_driver
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            6)
                setup_vm_gpu_passthrough
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            7)
                setup_lxc_gpu_passthrough
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            8)
                check_gpu_status
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            9)
                auto_install
                read -p "계속하려면 Enter를 누르세요..."
                ;;
            10)
                log_info "스크립트를 종료합니다."
                exit 0
                ;;
            *)
                log_error "잘못된 선택입니다. 다시 선택해주세요."
                read -p "계속하려면 Enter를 누르세요..."
                ;;
        esac
    done
}

# 스크립트 실행
main "$@"
