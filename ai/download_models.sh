#!/bin/bash

# ==========================================
# OpenClaw & Jetson Orin Nano 모델 다운로더
# (무한 반복 & 번호 종료 버전)
# ==========================================

# Docker 컨테이너 이름
CONTAINER_NAME="ollama-gpu"

# 색상 변수
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. 컨테이너 실행 확인
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}[Error] '${CONTAINER_NAME}' 컨테이너가 실행 중이지 않습니다.${NC}"
    echo "먼저 'docker compose up -d'를 실행해주세요."
    exit 1
fi

# 2. 무한 반복 구간 시작
while true; do
    echo -e "\n${BLUE}=============================================${NC}"
    echo -e "${BLUE}  다운로드할 모델을 선택하세요 (Jetson 8GB)  ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo "1) Llama 3.2 (3B)       - [추천] 가장 빠르고 가벼움 (기본)"
    echo "2) Phi-3.5 (3.8B)       - [추천] 똑똑하고 논리력 좋음"
    echo "3) Qwen 2.5 (3B)        - [도구] 코딩 및 Agent 작업에 강함"
    echo "4) DeepSeek R1 (7B)     - [성능] 최신 추론 모델 (무거움 주의)"
    echo "5) Qwen 2.5 7B (Q3_K_M) - [타협] 7B 모델 경량화 버전"
    echo "6) Gemma 2 (2B)         - [초경량] 속도 극대화"
    echo "7) 직접 입력 (Custom)   - 원하는 모델명 직접 타이핑"
    echo "a) 전체 다운로드 (위 추천 모델 일괄 설치)"
    echo "---------------------------------------------"
    echo "0) 종료 (Exit)          - 스크립트 끝내기"
    echo "---------------------------------------------"

    read -p "번호 선택 > " choice

    MODEL=""

    case $choice in
        0)
            echo "다운로더를 종료합니다."
            exit 0
            ;;
        1)
            MODEL="llama3.2"
            ;;
        2)
            MODEL="phi3.5"
            ;;
        3)
            MODEL="qwen2.5:3b"
            ;;
        4)
            MODEL="deepseek-r1:7b"
            ;;
        5)
            MODEL="qwen2.5:7b-instruct-q3_K_M"
            ;;
        6)
            MODEL="gemma2:2b"
            ;;
        7)
            echo -e "${BLUE}다운로드할 모델명을 정확히 입력해주세요 (예: mistral, solar)${NC}"
            read -p "모델명 입력 > " custom_input
            if [ -z "$custom_input" ]; then
                echo -e "${RED}[Error] 모델명이 입력되지 않았습니다. 메뉴로 돌아갑니다.${NC}"
                continue
            fi
            MODEL="$custom_input"
            ;;
        a|A)
            echo -e "${GREEN}추천 모델 전체를 순차적으로 다운로드합니다...${NC}"
            docker exec -it $CONTAINER_NAME ollama pull llama3.2
            docker exec -it $CONTAINER_NAME ollama pull phi3.5
            docker exec -it $CONTAINER_NAME ollama pull qwen2.5:3b
            echo -e "${GREEN}전체 다운로드 완료! 메뉴로 돌아갑니다.${NC}"
            continue
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다. 다시 입력해주세요.${NC}"
            continue
            ;;
    esac

    # 선택한 모델 다운로드 실행
    if [ -n "$MODEL" ]; then
        echo -e "${GREEN}==> '${MODEL}' 모델 다운로드를 시작합니다...${NC}"
        docker exec -it $CONTAINER_NAME ollama pull $MODEL
        echo -e "${GREEN}==> 완료되었습니다!${NC}"
        echo "잠시 후 메뉴로 돌아갑니다..."
        sleep 2
    fi
done
