#!/bin/bash

# OPNsense ISO 다운로드 스크립트
# 작성자: Claude Assistant
# 용도: OPNsense ISO 파일을 대화식으로 다운로드

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로고 출력
print_logo() {
    echo -e "${BLUE}"
    echo "  ___  ____  _   _                        "
    echo " / _ \|  _ \| \ | |___  ___ _ __  ___  ___ "
    echo "| | | | |_) |  \| / __|/ _ \ '_ \/ __|/ _ \\"
    echo "| |_| |  __/| |\  \__ \  __/ | | \__ \  __/"
    echo " \___/|_|   |_| \_|___/\___|_| |_|___/\___|"
    echo "                                          "
    echo -e "${NC}"
    echo -e "${GREEN}OPNsense ISO 다운로드 스크립트${NC}"
    echo "=================================="
    echo
}

# 미러 서버 목록
declare -A MIRRORS=(
    ["공식 서버"]="https://pkg.opnsense.org/releases/mirror"
    ["한국 KAIST"]="https://mirror.kaist.ac.kr/opnsense/releases"
    ["일본 JAIST"]="https://ftp.jaist.ac.jp/pub/opnsense/releases"
    ["독일 FAU"]="https://ftp.fau.de/opnsense/releases"
    ["미국 MIT"]="https://opnsense.c3sl.ufpr.br/releases"
)

# 아키텍처 목록
declare -A ARCHITECTURES=(
    ["1"]="amd64"
    ["2"]="arm64"
)

# 이미지 타입
declare -A IMAGE_TYPES=(
    ["1"]="dvd"
    ["2"]="nano"
    ["3"]="serial"
    ["4"]="vga"
)

# 미러 선택 함수
select_mirror() {
    echo -e "${YELLOW}미러 서버를 선택하세요:${NC}"
    echo
    
    local i=1
    local mirror_keys=()
    for mirror in "${!MIRRORS[@]}"; do
        echo "  $i) $mirror"
        mirror_keys[$i]=$mirror
        ((i++))
    done
    echo
    
    while true; do
        read -p "미러 번호를 입력하세요 [1-${#MIRRORS[@]}]: " mirror_choice
        if [[ $mirror_choice =~ ^[1-${#MIRRORS[@]}]$ ]]; then
            SELECTED_MIRROR="${MIRRORS[${mirror_keys[$mirror_choice]}]}"
            echo -e "${GREEN}선택된 미러: ${mirror_keys[$mirror_choice]}${NC}"
            echo
            break
        else
            echo -e "${RED}올바른 번호를 입력하세요.${NC}"
        fi
    done
}

# 버전 선택 함수
select_version() {
    echo -e "${YELLOW}OPNsense 버전을 입력하세요:${NC}"
    echo "  예시: 24.1, 23.7, 24.7"
    echo "  최신 버전 확인: https://opnsense.org/download/"
    echo
    
    while true; do
        read -p "버전을 입력하세요 (예: 24.1): " version
        if [[ $version =~ ^[0-9]+\.[0-9]+$ ]]; then
            SELECTED_VERSION=$version
            echo -e "${GREEN}선택된 버전: $version${NC}"
            echo
            break
        else
            echo -e "${RED}올바른 버전 형식을 입력하세요 (예: 24.1).${NC}"
        fi
    done
}

# 아키텍처 선택 함수
select_architecture() {
    echo -e "${YELLOW}아키텍처를 선택하세요:${NC}"
    echo "  1) amd64 (Intel/AMD 64비트)"
    echo "  2) arm64 (ARM 64비트)"
    echo
    
    while true; do
        read -p "아키텍처 번호를 입력하세요 [1-2]: " arch_choice
        if [[ $arch_choice =~ ^[1-2]$ ]]; then
            SELECTED_ARCH="${ARCHITECTURES[$arch_choice]}"
            echo -e "${GREEN}선택된 아키텍처: $SELECTED_ARCH${NC}"
            echo
            break
        else
            echo -e "${RED}올바른 번호를 입력하세요.${NC}"
        fi
    done
}

# 이미지 타입 선택 함수
select_image_type() {
    echo -e "${YELLOW}이미지 타입을 선택하세요:${NC}"
    echo "  1) dvd     - 표준 설치 이미지 (권장)"
    echo "  2) nano    - 임베디드 시스템용"
    echo "  3) serial  - 시리얼 콘솔용"
    echo "  4) vga     - VGA 콘솔용"
    echo
    
    while true; do
        read -p "이미지 타입 번호를 입력하세요 [1-4]: " type_choice
        if [[ $type_choice =~ ^[1-4]$ ]]; then
            SELECTED_TYPE="${IMAGE_TYPES[$type_choice]}"
            echo -e "${GREEN}선택된 타입: $SELECTED_TYPE${NC}"
            echo
            break
        else
            echo -e "${RED}올바른 번호를 입력하세요.${NC}"
        fi
    done
}

# 다운로드 디렉토리 설정
set_download_directory() {
    echo -e "${YELLOW}다운로드 디렉토리를 설정하세요:${NC}"
    read -p "다운로드 경로를 입력하세요 [기본값: ./downloads]: " download_dir
    
    if [[ -z "$download_dir" ]]; then
        download_dir="./downloads"
    fi
    
    # 디렉토리 생성
    mkdir -p "$download_dir"
    echo -e "${GREEN}다운로드 디렉토리: $download_dir${NC}"
    echo
}

# 파일 URL 생성
generate_url() {
    local filename="OPNsense-${SELECTED_VERSION}-${SELECTED_TYPE}-${SELECTED_ARCH}.img.bz2"
    local url="${SELECTED_MIRROR}/${SELECTED_VERSION}/${filename}"
    
    echo -e "${BLUE}다운로드 정보:${NC}"
    echo "  미러: $SELECTED_MIRROR"
    echo "  버전: $SELECTED_VERSION"
    echo "  아키텍처: $SELECTED_ARCH"
    echo "  타입: $SELECTED_TYPE"
    echo "  파일명: $filename"
    echo "  URL: $url"
    echo "  저장 경로: $download_dir/$filename"
    echo
}

# 다운로드 확인
confirm_download() {
    while true; do
        read -p "다운로드를 시작하시겠습니까? [y/N]: " confirm
        case $confirm in
            [Yy]* ) return 0;;
            [Nn]* | "" ) 
                echo -e "${YELLOW}다운로드가 취소되었습니다.${NC}"
                exit 0;;
            * ) echo -e "${RED}y 또는 n을 입력하세요.${NC}";;
        esac
    done
}

# 파일 다운로드
download_file() {
    local filename="OPNsense-${SELECTED_VERSION}-${SELECTED_TYPE}-${SELECTED_ARCH}.img.bz2"
    local url="${SELECTED_MIRROR}/${SELECTED_VERSION}/${filename}"
    local output_path="$download_dir/$filename"
    
    echo -e "${GREEN}다운로드를 시작합니다...${NC}"
    echo
    
    # wget 또는 curl 사용
    if command -v wget >/dev/null 2>&1; then
        wget --progress=bar:force --show-progress -O "$output_path" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar -o "$output_path" "$url"
    else
        echo -e "${RED}오류: wget 또는 curl이 설치되어 있지 않습니다.${NC}"
        exit 1
    fi
    
    if [[ $? -eq 0 ]]; then
        echo
        echo -e "${GREEN}다운로드가 완료되었습니다!${NC}"
        echo "파일 위치: $output_path"
        
        # 파일 크기 표시
        if command -v du >/dev/null 2>&1; then
            echo "파일 크기: $(du -h "$output_path" | cut -f1)"
        fi
        
        # 압축 해제 여부 확인
        echo
        while true; do
            read -p "압축을 해제하시겠습니까? [y/N]: " decompress
            case $decompress in
                [Yy]* ) 
                    echo -e "${GREEN}압축을 해제합니다...${NC}"
                    bunzip2 "$output_path"
                    echo -e "${GREEN}압축 해제 완료: ${output_path%.bz2}${NC}"
                    break;;
                [Nn]* | "" ) 
                    echo -e "${YELLOW}압축 파일을 그대로 유지합니다.${NC}"
                    break;;
                * ) echo -e "${RED}y 또는 n을 입력하세요.${NC}";;
            esac
        done
        
    else
        echo -e "${RED}다운로드에 실패했습니다.${NC}"
        exit 1
    fi
}

# 체크섬 검증 (선택사항)
verify_checksum() {
    echo
    while true; do
        read -p "체크섬을 검증하시겠습니까? [y/N]: " verify
        case $verify in
            [Yy]* ) 
                local checksum_url="${SELECTED_MIRROR}/${SELECTED_VERSION}/OPNsense-${SELECTED_VERSION}-checksums-${SELECTED_ARCH}.sha256"
                echo -e "${GREEN}체크섬 파일을 다운로드합니다...${NC}"
                
                if command -v wget >/dev/null 2>&1; then
                    wget -O "$download_dir/checksums.sha256" "$checksum_url"
                elif command -v curl >/dev/null 2>&1; then
                    curl -L -o "$download_dir/checksums.sha256" "$checksum_url"
                fi
                
                echo -e "${GREEN}체크섬을 검증합니다...${NC}"
                cd "$download_dir"
                if sha256sum -c checksums.sha256 2>/dev/null | grep -q "OK"; then
                    echo -e "${GREEN}체크섬 검증이 성공했습니다!${NC}"
                else
                    echo -e "${YELLOW}체크섬 검증에 실패했거나 파일을 찾을 수 없습니다.${NC}"
                fi
                break;;
            [Nn]* | "" ) 
                echo -e "${YELLOW}체크섬 검증을 건너뜁니다.${NC}"
                break;;
            * ) echo -e "${RED}y 또는 n을 입력하세요.${NC}";;
        esac
    done
}

# 메인 함수
main() {
    print_logo
    
    # 필수 도구 확인
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}오류: wget 또는 curl이 필요합니다.${NC}"
        echo "설치 명령어:"
        echo "  Ubuntu/Debian: sudo apt-get install wget"
        echo "  CentOS/RHEL: sudo yum install wget"
        echo "  macOS: brew install wget"
        exit 1
    fi
    
    select_mirror
    select_version
    select_architecture
    select_image_type
    set_download_directory
    generate_url
    confirm_download
    download_file
    verify_checksum
    
    echo
    echo -e "${GREEN}=== 다운로드 완료 ===${NC}"
    echo "이제 VM에서 ISO 파일을 사용하여 OPNsense를 설치할 수 있습니다."
    echo "자세한 설치 방법은 README.md 파일을 참조하세요."
}

# 스크립트 실행
main "$@"
