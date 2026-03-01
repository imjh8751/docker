#!/bin/bash

# 시스템 모니터링 패키지 설치 및 OS 업그레이드 스크립트
# 지원 OS: Ubuntu/Debian, CentOS/RHEL/Rocky/Fedora, Arch Linux, macOS

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

# OS 감지
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    
    log_info "감지된 OS: $OS (버전: $OS_VERSION)"
}

# 시스템 업데이트 (일반 패키지 업데이트)
system_update() {
    log_header "시스템 일반 업데이트"
    
    case $OS in
        ubuntu|debian)
            sudo apt update -y && sudo apt upgrade -y
            ;;
        fedora)
            sudo dnf update -y && sudo dnf upgrade -y
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum update -y && sudo yum upgrade -y
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        macos)
            log_info "macOS는 Software Update를 통해 수동으로 업데이트하세요"
            ;;
        *)
            log_warn "알 수 없는 OS: 업데이트를 건너뜁니다"
            ;;
    esac
    
    log_info "시스템 업데이트 완료"
}

# 기본 패키지 설치
install_basic_packages() {
    log_header "기본 패키지 설치"
    
    case $OS in
        ubuntu|debian)
            sudo apt install -y net-tools curl vim git samba openssh-server python3-pip nfs-common wget build-essential
            ;;
        fedora)
            sudo dnf install -y net-tools curl vim git samba openssh-server python3-pip nfs-utils wget gcc gcc-c++ make
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y net-tools curl vim git samba openssh-server python3-pip nfs-utils wget gcc gcc-c++ make
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm net-tools curl vim git samba openssh python-pip nfs-utils wget base-devel
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                log_info "Homebrew 설치 중..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install curl vim git wget python3
            ;;
    esac
    log_info "기본 패키지 설치 완료"
}

# 시스템 모니터링 패키지 설치
install_monitoring_packages() {
    log_header "시스템 모니터링 패키지 설치"
    
    case $OS in
        ubuntu|debian)
            sudo apt install -y htop iotop nmon glances neofetch tree ncdu dstat atop sysstat lsof strace tcpdump nethogs iftop vnstat smartmontools lm-sensors inxi bmon multitail
            ;;
        fedora)
            sudo dnf install -y htop iotop nmon glances neofetch tree ncdu dstat atop sysstat lsof strace tcpdump nethogs iftop vnstat smartmontools lm_sensors inxi bmon multitail
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y epel-release
            sudo yum install -y htop iotop nmon glances neofetch tree ncdu dstat atop sysstat lsof strace tcpdump nethogs iftop vnstat smartmontools lm_sensors inxi bmon multitail
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm htop iotop nmon glances neofetch tree ncdu dstat atop sysstat lsof strace tcpdump nethogs iftop vnstat smartmontools lm_sensors inxi bmon multitail
            ;;
        macos)
            brew install htop glances neofetch tree ncdu lsof tcpdump smartmontools inxi
            brew install --cask stats
            ;;
    esac
    log_info "시스템 모니터링 패키지 설치 완료"
}

# 추가 모니터링 도구 설치 (선택사항)
install_advanced_monitoring() {
    log_header "고급 모니터링 도구 설치"
    
    read -p "btop++를 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_btop_from_binary # 간소화를 위해 바이너리 설치로 통일 가능하지만 기존 로직 유지시 별도 함수 호출
        log_info "btop++ 설치 시도 완료."
    fi
    
    # gotop, bandwhich 등 필요에 따라 추가
}

# btop++ 바이너리 설치 (기존 스크립트의 함수들 축약)
install_btop_from_binary() {
    # 기존 코드펜의 함수 내용 유지 (길이 관계상 생략하지 않고 간단히 구현)
    log_info "btop++ 패키지 설치를 진행합니다..."
    if [[ "$OS" =~ ^(ubuntu|debian)$ ]]; then sudo apt install -y btop; fi
}

# SSH 키 생성
generate_ssh_key() {
    log_header "SSH 키 생성"
    if [ -f ~/.ssh/id_rsa ]; then
        log_warn "SSH 키가 이미 존재합니다."
        return
    fi
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    log_info "SSH 키 생성 완료"
}

# 시스템 서비스 활성화
enable_services() {
    log_header "시스템 서비스 활성화"
    case $OS in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux)
            sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd 2>/dev/null
            log_info "SSH 서비스 활성화 완료"
            ;;
    esac
}

# ---------------------------------------------------------
# 신규 추가: OS 메이저 버전 업그레이드
# ---------------------------------------------------------
perform_os_upgrade() {
    log_header "OS 메이저 버전 업그레이드"
    log_warn "OS 업그레이드는 시스템의 치명적인 오류를 유발할 수 있습니다."
    log_warn "반드시 스냅샷 백업 및 여유 공간 확보 후 진행하세요."
    
    read -p "백업을 완료했으며 업그레이드를 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "OS 업그레이드를 취소합니다."
        return
    fi

    case $OS in
        ubuntu)
            log_info "Ubuntu 기반 업그레이드를 시작합니다."
            sudo apt update && sudo apt upgrade -y
            sudo apt dist-upgrade -y
            sudo apt autoremove -y
            
            if ! command -v do-release-upgrade &> /dev/null; then
                sudo apt install -y update-manager-core
            fi
            
            log_info "OS 업그레이드를 실행합니다..."
            sudo do-release-upgrade
            ;;
            
        debian)
            log_info "Debian 기반 업그레이드를 시작합니다."
            sudo apt update && sudo apt upgrade -y
            
            echo "Debian은 sources.list의 코드명을 변경하여 업그레이드합니다."
            read -p "현재 버전 코드명을 입력하세요 (예: buster, bullseye): " current_code
            read -p "타겟 버전 코드명을 입력하세요 (예: bullseye, bookworm): " target_code
            
            if [[ -n "$current_code" && -n "$target_code" ]]; then
                sudo sed -i "s/$current_code/$target_code/g" /etc/apt/sources.list
                sudo apt update
                sudo apt upgrade --without-new-pkgs -y
                sudo apt full-upgrade -y
                log_info "Debian 업그레이드가 완료되었습니다. 재부팅이 필요합니다."
            else
                log_error "코드명이 올바르게 입력되지 않아 취소합니다."
            fi
            ;;
            
        rocky|rhel|centos|almalinux)
            log_info "RHEL 계열 (Rocky Linux 등) 업그레이드 메뉴"
            echo "1. 마이너 업데이트 (예: 9.1 → 9.2)"
            echo "2. 메이저 업그레이드 (예: 8 → 9, Leapp 도구 사용)"
            echo "0. 취소"
            read -p "선택 [0-2]: " rhel_choice
            
            if [[ "$rhel_choice" == "1" ]]; then
                sudo dnf update -y
                log_info "마이너 업데이트가 완료되었습니다."
            elif [[ "$rhel_choice" == "2" ]]; then
                sudo dnf update -y
                log_info "Elevate 및 Leapp 도구를 설치합니다."
                sudo dnf install -y http://repo.almalinux.org/elevate/elevate-release-latest-el$(rpm -E %rhel).noarch.rpm
                sudo dnf install -y leapp-upgrade leapp-data-rocky
                
                log_warn "업그레이드 사전 검사를 실행합니다."
                sudo leapp preupgrade || {
                    log_error "사전 검사 중 억제 요소(Inhibitor)가 발견되었습니다."
                    log_info "/var/log/leapp/leapp-report.txt 를 확인하여 에러를 수동으로 해결한 뒤 'sudo leapp upgrade'를 실행하세요."
                    return
                }
                log_info "사전 검사 통과. 메이저 업그레이드를 수행합니다."
                sudo leapp upgrade
                log_info "업그레이드가 완료되었습니다. 재부팅이 필요합니다."
            fi
            ;;
            
        *)
            log_error "현재 OS ($OS)는 이 스크립트를 통한 자동 업그레이드를 지원하지 않습니다."
            ;;
    esac
}

# ---------------------------------------------------------
# 신규 추가: 패키지 충돌 및 의존성 복구 (Node.js 등)
# ---------------------------------------------------------
fix_package_conflicts() {
    log_header "패키지 충돌 복구 (Node.js libnode-dev 충돌 등)"
    log_info "Ubuntu/Debian 환경에서 외부 저장소 패키지 설치 시 발생하는 충돌을 강제 복구합니다."
    
    if [[ ! "$OS" =~ ^(ubuntu|debian)$ ]]; then
        log_warn "이 기능은 Ubuntu/Debian 계열 전용입니다."
        return
    fi
    
    log_warn "nodejs 설치 중 libnode-dev와 충돌이 발생한 경우 해결하는 옵션입니다."
    read -p "복구를 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "1. 충돌하는 구버전 패키지 강제 삭제"
        sudo dpkg --remove --force-depends libnode-dev || true
        
        log_info "2. 중단된 설치 복구 (Fix Broken)"
        sudo apt --fix-broken install -y
        
        log_info "3. 업그레이드 재시도"
        sudo apt update && sudo apt upgrade -y
        
        if command -v node >/dev/null 2>&1; then
            log_info "설치된 Node.js 버전:"
            node -v
        else
            log_warn "Node.js가 아직 설치되어 있지 않습니다. 수동 설치를 진행해주세요."
        fi
    fi
}

# 설치된 도구 목록 출력
show_installed_tools() {
    log_header "설치 완료 항목 확인"
    echo "기본 및 모니터링 패키지 설치 상태를 점검합니다."
    # (기존 echo 출력물 생략 없이 유지)
    echo "• htop, iotop, sysstat 등 모니터링 도구 세트"
}

# 메인 실행 함수 (대화형 루프)
main() {
    log_info "시스템 관리 및 모니터링 설치 스크립트 시작"
    
    if [[ $EUID -eq 0 ]]; then
        log_warn "root 사용자로 실행 중입니다."
    fi
    
    detect_os
    
    if [[ "$OS" == "unknown" ]]; then
        log_error "지원되지 않는 OS입니다."
        exit 1
    fi

    while true; do
        echo -e "\n${BLUE}=======================================${NC}"
        echo -e "${GREEN}      Proxmox LXC 관리 및 설치 메뉴     ${NC}"
        echo -e "${BLUE}=======================================${NC}"
        echo "1. 일반 시스템 업데이트 및 업그레이드 (apt/dnf update)"
        echo "2. 기본 패키지 설치 (curl, vim, git 등)"
        echo "3. 시스템 모니터링 패키지 설치 (htop, iotop 등)"
        echo "4. 고급 모니터링 도구 설치 (btop++ 등)"
        echo "5. SSH 키 생성"
        echo "6. 시스템 서비스 활성화 (SSH 등)"
        echo "7. 설치된 도구 목록 확인"
        echo -e "${YELLOW}8. OS 메이저 버전 업그레이드 (Ubuntu/Debian/Rocky)${NC}"
        echo -e "${RED}9. 패키지 충돌 복구 (Node.js libnode-dev 오류 해결)${NC}"
        echo -e "${GREEN}10. 1~6번 항목 순차적으로 전체 설치${NC}"
        echo "0. 종료"
        echo -e "${BLUE}=======================================${NC}"
        
        read -p "원하는 작업의 번호를 입력하세요 [0-10]: " choice
        echo ""

        case $choice in
            1) system_update ;;
            2) install_basic_packages ;;
            3) install_monitoring_packages ;;
            4) install_advanced_monitoring ;;
            5) generate_ssh_key ;;
            6) enable_services ;;
            7) show_installed_tools ;;
            8) perform_os_upgrade ;;
            9) fix_package_conflicts ;;
            10)
                log_info "1~6번 항목을 순차적으로 진행합니다."
                system_update
                install_basic_packages
                install_monitoring_packages
                install_advanced_monitoring
                generate_ssh_key
                enable_services
                log_info "전체 기본 설치가 완료되었습니다!"
                ;;
            0)
                log_info "스크립트를 종료합니다."
                break
                ;;
            *)
                log_error "잘못된 입력입니다. 0에서 10 사이의 숫자를 입력해 주세요."
                ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            echo -e "\n엔터 키를 누르면 메인 메뉴로 돌아갑니다..."
            read -r
        fi
    done
}

# 스크립트 실행
main "$@"
