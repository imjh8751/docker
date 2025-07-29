#!/bin/bash

# Gemini CLI 설치 스크립트
# OS별로 Node.js와 Gemini CLI를 설치합니다

set -e  # 에러 발생시 스크립트 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
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

# 저장소 정리 함수
fix_repositories() {
    log_info "저장소 설정을 확인하고 수정합니다..."
    
    # 백업 생성
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
    
    # 문제가 있는 저장소 비활성화
    if grep -q "bullseye-backports" /etc/apt/sources.list; then
        log_info "문제가 있는 bullseye-backports 저장소를 비활성화합니다..."
        sudo sed -i 's/^deb.*bullseye-backports.*/#&/' /etc/apt/sources.list
    fi
    
    # sources.list.d 디렉토리도 확인
    if [ -d "/etc/apt/sources.list.d" ]; then
        for file in /etc/apt/sources.list.d/*.list; do
            if [ -f "$file" ] && grep -q "bullseye-backports" "$file"; then
                log_info "$(basename $file)에서 문제가 있는 저장소를 비활성화합니다..."
                sudo sed -i 's/^deb.*bullseye-backports.*/#&/' "$file"
            fi
        done
    fi
    
    # 캐시 정리
    sudo apt clean
    sudo rm -rf /var/lib/apt/lists/*
}

# OS 감지 함수
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        elif type lsb_release >/dev/null 2>&1; then
            OS=$(lsb_release -si)
            VER=$(lsb_release -sr)
        else
            OS=$(uname -s)
            VER=$(uname -r)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="Windows"
        VER=$(cmd //c ver 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# Node.js 버전 확인 함수
check_nodejs() {
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        REQUIRED_VERSION="18.0.0"
        
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            log_success "Node.js $NODE_VERSION 이미 설치됨 (요구사항: v18+)"
            return 0
        else
            log_warning "Node.js $NODE_VERSION 설치됨, 하지만 v18+ 필요"
            return 1
        fi
    else
        log_info "Node.js가 설치되지 않음"
        return 1
    fi
}

# macOS용 설치 함수
install_macos() {
    log_info "macOS 환경에서 설치를 시작합니다..."
    
    # Homebrew 확인 및 설치
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Homebrew 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # PATH 설정 (Apple Silicon Mac의 경우)
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "Node.js 설치 중..."
        brew install node
    fi
    
    # npm 업데이트
    log_info "npm 업데이트 중..."
    npm install -g npm@latest
}

# 기존 Node.js 완전 제거 함수
clean_nodejs() {
    log_info "기존 Node.js 설치를 완전히 제거합니다..."
    
    # 모든 Node.js 관련 패키지 제거
    sudo apt remove --purge -y nodejs npm nodejs-legacy node-gyp 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
    
    # 추가적인 정리
    sudo rm -rf /usr/local/bin/npm /usr/local/share/man/man1/node* /usr/local/lib/dtrace/node.d
    sudo rm -rf ~/.npm ~/.node-gyp /opt/local/bin/node /opt/local/include/node /opt/local/lib/node_modules
    sudo rm -rf /usr/local/lib/node* /usr/local/include/node* /usr/local/bin/node*
    
    # dpkg 상태 정리
    sudo dpkg --configure -a 2>/dev/null || true
    sudo apt --fix-broken install -y 2>/dev/null || true
    
    log_success "기존 Node.js 제거 완료"
}

# 프록시 설정 해제 함수
disable_proxy() {
    log_info "프록시 설정을 확인하고 해제합니다..."
    
    # 환경변수 프록시 해제
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    
    # apt 프록시 설정 확인 및 임시 해제
    if [ -f /etc/apt/apt.conf ]; then
        sudo mv /etc/apt/apt.conf /etc/apt/apt.conf.backup 2>/dev/null || true
    fi
    
    if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then
        sudo mv /etc/apt/apt.conf.d/proxy.conf /etc/apt/apt.conf.d/proxy.conf.backup 2>/dev/null || true
    fi
    
    log_success "프록시 설정 해제 완료"
}

# Ubuntu/Debian용 설치 함수
install_ubuntu_debian() {
    log_info "Ubuntu/Debian 환경에서 설치를 시작합니다..."
    
    # 프록시 설정 해제
    disable_proxy
    
    # 저장소 문제 해결
    fix_repositories
    
    # 패키지 목록 업데이트
    log_info "패키지 목록을 업데이트합니다..."
    sudo apt update || {
        log_warning "일부 저장소에서 업데이트 실패, 계속 진행합니다..."
    }
    
    # curl 설치 (없는 경우)
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl 설치 중..."
        sudo apt install -y curl
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        # 기존 Node.js 완전 제거
        clean_nodejs
        
        log_info "Node.js 설치 방법을 선택합니다..."
        
        # 방법 1: NodeSource 저장소 사용 (프록시 없이)
        log_info "NodeSource repository 추가 시도..."
        if curl -fsSL --connect-timeout 10 https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
            log_info "NodeSource에서 Node.js 설치 중..."
            sudo apt install -y nodejs
        else
            log_warning "NodeSource 접근 실패, nvm으로 설치 시도..."
            
            # 방법 2: nvm 사용
            log_info "nvm을 통해 Node.js 설치 중..."
            if curl -o- --connect-timeout 10 https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash; then
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                nvm install --lts
                nvm use --lts
                nvm alias default lts/*
            else
                log_warning "nvm 설치 실패, 바이너리 직접 설치 시도..."
                
                # 방법 3: 직접 바이너리 다운로드
                install_nodejs_binary
            fi
        fi
    fi
}

# Node.js 바이너리 직접 설치 함수
install_nodejs_binary() {
    log_info "Node.js 바이너리를 직접 다운로드하여 설치합니다..."
    
    # 아키텍처 감지
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) NODE_ARCH="x64" ;;
        aarch64|arm64) NODE_ARCH="arm64" ;;
        armv7l) NODE_ARCH="armv7l" ;;
        *) log_error "지원하지 않는 아키텍처: $ARCH"; exit 1 ;;
    esac
    
    NODE_VERSION="20.11.0"  # LTS 버전
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
    
    # 임시 디렉토리에 다운로드
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if wget -T 30 "$NODE_URL" || curl -L -o "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" "$NODE_URL"; then
        tar -xf "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
        
        # /usr/local에 설치
        sudo cp -r "node-v${NODE_VERSION}-linux-${NODE_ARCH}"/* /usr/local/
        
        # 심볼릭 링크 생성
        sudo ln -sf /usr/local/bin/node /usr/bin/node
        sudo ln -sf /usr/local/bin/npm /usr/bin/npm
        sudo ln -sf /usr/local/bin/npx /usr/bin/npx
        
        # PATH 업데이트
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
        export PATH="/usr/local/bin:$PATH"
        
        log_success "Node.js 바이너리 설치 완료"
    else
        log_error "Node.js 다운로드에 실패했습니다. 인터넷 연결을 확인하세요."
        exit 1
    fi
    
    # 정리
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

# CentOS/RHEL/Fedora용 설치 함수
install_redhat() {
    log_info "Red Hat 계열 환경에서 설치를 시작합니다..."
    
    # 패키지 매니저 감지
    if command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        log_error "지원하지 않는 패키지 매니저입니다"
        exit 1
    fi
    
    # curl 설치 (없는 경우)
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl 설치 중..."
        sudo $PKG_MANAGER install -y curl
    fi
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "NodeSource repository 추가 중..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        
        log_info "Node.js 설치 중..."
        sudo $PKG_MANAGER install -y nodejs
    fi
}

# Arch Linux용 설치 함수
install_arch() {
    log_info "Arch Linux 환경에서 설치를 시작합니다..."
    
    # 패키지 데이터베이스 업데이트
    sudo pacman -Sy
    
    # Node.js 설치
    if ! check_nodejs; then
        log_info "Node.js 설치 중..."
        sudo pacman -S --noconfirm nodejs npm
    fi
}

# Windows (WSL/Git Bash/MSYS2)용 설치 함수
install_windows() {
    log_info "Windows 환경에서 설치를 시작합니다..."
    log_warning "Windows에서는 Node.js를 수동으로 설치하는 것을 권장합니다."
    log_info "https://nodejs.org에서 Node.js를 다운로드하여 설치하세요."
    
    if ! check_nodejs; then
        log_error "Node.js가 설치되지 않았습니다. 수동으로 설치 후 다시 실행하세요."
        exit 1
    fi
}

# npm 전역 디렉토리 설정 함수
setup_npm_global() {
    log_info "npm 전역 디렉토리를 사용자 홈으로 설정합니다..."
    
    # 전역 설치 디렉토리를 사용자 홈으로 변경
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    # PATH에 추가
    if ! grep -q "~/.npm-global/bin" ~/.bashrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    fi
    
    if ! grep -q "~/.npm-global/bin" ~/.profile; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile
    fi
    
    # 현재 세션에 적용
    export PATH=~/.npm-global/bin:$PATH
    
    log_success "npm 전역 디렉토리 설정 완료"
}

# Gemini CLI 설치 함수
install_gemini_cli() {
    log_info "Gemini CLI 설치 중..."
    
    # 방법 1: npm 전역 디렉토리 설정 후 설치
    setup_npm_global
    
    if npm install -g @google/gemini-cli; then
        log_success "Gemini CLI가 성공적으로 설치되었습니다!"
        return 0
    fi
    
    log_warning "사용자 디렉토리 설치 실패, sudo로 시도합니다..."
    
    # 방법 2: sudo로 설치 (권장하지 않지만 대안)
    if sudo npm install -g @google/gemini-cli --unsafe-perm=true --allow-root; then
        log_success "Gemini CLI가 성공적으로 설치되었습니다!"
        
        # 사용자가 실행할 수 있도록 권한 설정
        sudo chown -R $(whoami) /usr/lib/node_modules/@google 2>/dev/null || true
        return 0
    fi
    
    log_warning "전역 설치 실패, 로컬 설치를 시도합니다..."
    
    # 방법 3: 로컬 설치 후 심볼릭 링크
    mkdir -p ~/gemini-cli
    cd ~/gemini-cli
    
    if npm install @google/gemini-cli; then
        # 실행 가능한 심볼릭 링크 생성
        mkdir -p ~/.local/bin
        ln -sf ~/gemini-cli/node_modules/.bin/gemini ~/.local/bin/gemini
        
        # PATH에 추가
        if ! grep -q "~/.local/bin" ~/.bashrc; then
            echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc
        fi
        export PATH=~/.local/bin:$PATH
        
        log_success "Gemini CLI가 로컬에 성공적으로 설치되었습니다!"
        cd - > /dev/null
        return 0
    fi
    
    log_error "모든 설치 방법이 실패했습니다."
    cd - > /dev/null
    exit 1
}

# 설치 후 설정 안내
post_install_info() {
    log_success "설치가 완료되었습니다!"
    echo
    log_info "다음 단계:"
    echo "1. API 키 설정 (선택사항 - Google 계정으로도 로그인 가능):"
    echo "   export GEMINI_API_KEY=\"YOUR_API_KEY\""
    echo "   또는 ~/.bashrc 또는 ~/.zshrc에 추가"
    echo
    echo "2. Google AI Studio에서 API 키 생성:"
    echo "   https://aistudio.google.com/apikey"
    echo
    echo "3. Gemini CLI 실행:"
    echo "   gemini"
    echo
    echo "4. 프로젝트 디렉토리에서 실행하여 코드베이스와 상호작용:"
    echo "   cd your-project"
    echo "   gemini"
    echo
    log_info "무료 사용량: 60 요청/분, 1000 요청/일 (Google 계정 로그인 시)"
}

# 메인 함수
main() {
    echo "================================"
    echo "    Gemini CLI 설치 스크립트    "
    echo "================================"
    echo
    
    # OS 감지
    detect_os
    log_info "감지된 OS: $OS $VER"
    echo
    
    # OS별 설치
    case "$OS" in
        "macOS")
            install_macos
            ;;
        "Ubuntu"*|"Debian"*)
            install_ubuntu_debian
            ;;
        "CentOS"*|"Red Hat"*|"Fedora"*|"Rocky"*|"AlmaLinux"*)
            install_redhat
            ;;
        "Arch"*|"Manjaro"*)
            install_arch
            ;;
        "Windows"*)
            install_windows
            ;;
        *)
            log_warning "지원하지 않는 OS입니다: $OS"
            log_info "Node.js v18+를 수동으로 설치한 후 계속 진행합니다..."
            if ! check_nodejs; then
                log_error "Node.js v18+가 필요합니다. 설치 후 다시 실행하세요."
                exit 1
            fi
            ;;
    esac
    
    # Node.js 설치 확인
    if ! check_nodejs; then
        log_error "Node.js 설치에 실패했습니다."
        exit 1
    fi
    
    # Gemini CLI 설치
    install_gemini_cli
    
    # 설치 후 안내
    post_install_info
}

# 스크립트 실행
main "$@"
