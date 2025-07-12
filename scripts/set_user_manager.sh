#!/bin/bash

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 제목 출력
echo -e "${BLUE}=============================="
echo -e "  🛠️  리눅스 계정 관리 도구"
echo -e "==============================${NC}"

# 메뉴 출력
echo -e "${YELLOW}원하는 작업을 선택하세요:${NC}"
echo "1) 계정 생성 (useradd)"
echo "2) 계정 삭제 (userdel)"
echo "3) 계정 비밀번호 설정 (passwd)"
echo "4) 계정 잠금/잠금 해제 (usermod)"
echo "5) 그룹 추가 (groupadd)"
echo "6) 사용자 그룹에 추가 (usermod -aG)"
echo "7) 사용자 정보 보기 (id, groups)"
echo "8) 종료"

read -p "선택 번호 입력: " choice

case $choice in
  1)
    read -p "생성할 계정명 입력: " username
    read -p "홈 디렉토리 생성할까요? (y/n): " makehome
    if [ "$makehome" == "y" ]; then
      echo -e "${GREEN}▶ 명령어: useradd -m $username${NC}"
      useradd -m "$username"
    else
      echo -e "${GREEN}▶ 명령어: useradd $username${NC}"
      useradd "$username"
    fi
    echo -e "${BLUE}✅ 계정 '$username' 생성 완료${NC}"
    ;;
  2)
    read -p "삭제할 계정명 입력: " username
    read -p "홈 디렉토리도 같이 삭제할까요? (y/n): " removehome
    if [ "$removehome" == "y" ]; then
      echo -e "${GREEN}▶ 명령어: userdel -r $username${NC}"
      userdel -r "$username"
    else
      echo -e "${GREEN}▶ 명령어: userdel $username${NC}"
      userdel "$username"
    fi
    echo -e "${BLUE}✅ 계정 '$username' 삭제 완료${NC}"
    ;;
  3)
    read -p "비밀번호 설정할 계정명 입력: " username
    echo -e "${GREEN}▶ 명령어: passwd $username${NC}"
    passwd "$username"
    ;;
  4)
    read -p "계정명 입력: " username
    read -p "잠금(lock) 또는 해제(unlock)? (lock/unlock): " action
    if [ "$action" == "lock" ]; then
      echo -e "${GREEN}▶ 명령어: usermod -L $username${NC}"
      usermod -L "$username"
      echo -e "${BLUE}✅ '$username' 계정 잠금 완료${NC}"
    else
      echo -e "${GREEN}▶ 명령어: usermod -U $username${NC}"
      usermod -U "$username"
      echo -e "${BLUE}✅ '$username' 계정 잠금 해제 완료${NC}"
    fi
    ;;
  5)
    read -p "추가할 그룹명 입력: " groupname
    echo -e "${GREEN}▶ 명령어: groupadd $groupname${NC}"
    groupadd "$groupname"
    echo -e "${BLUE}✅ 그룹 '$groupname' 추가 완료${NC}"
    ;;
  6)
    read -p "추가할 계정명 입력: " username
    read -p "추가할 그룹명 입력: " groupname
    echo -e "${GREEN}▶ 명령어: usermod -aG $groupname $username${NC}"
    usermod -aG "$groupname" "$username"
    echo -e "${BLUE}✅ '$username' → '$groupname' 그룹에 추가 완료${NC}"
    ;;
  7)
    read -p "정보를 확인할 계정명 입력: " username
    echo -e "${GREEN}▶ 명령어: id $username${NC}"
    id "$username"
    echo -e "${GREEN}▶ 명령어: groups $username${NC}"
    groups "$username"
    ;;
  8)
    echo -e "${YELLOW}👋 종료합니다.${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}❌ 잘못된 입력입니다. 1~8 중에서 선택해주세요.${NC}"
    ;;
esac
