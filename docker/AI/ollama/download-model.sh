#!/bin/bash

# Ollama 대화형 모델 다운로드 스크립트 (CPU 최적화)

echo "=== Ollama CPU 최적화 모델 다운로드 ==="
echo ""

# Ollama 서비스 준비 대기
echo "Ollama 서비스 확인 중..."
until docker exec ollama ollama list > /dev/null 2>&1; do
    echo "Ollama 서비스 대기 중..."
    sleep 2
done

echo "✓ Ollama 서비스 준비 완료"
echo ""

# CPU 최적화 모델 목록 (빠른 순서대로)
declare -A MODELS
MODELS=(
    ["1"]="qwen2.5:0.5b|Qwen 2.5 0.5B - 가장 빠름 (352MB)"
    ["2"]="qwen2.5:1.5b|Qwen 2.5 1.5B - 매우 빠름 (934MB)"
    ["3"]="phi3.5:3.8b|Phi 3.5 3.8B - 빠름, 고품질 (2.2GB)"
    ["4"]="gemma2:2b|Gemma 2 2B - 빠름 (1.6GB)"
    ["5"]="llama3.2:3b|Llama 3.2 3B - 빠름, 범용 (2.0GB)"
    ["6"]="qwen2.5:3b|Qwen 2.5 3B - 빠름, 한국어 우수 (1.9GB)"
    ["7"]="qwen2.5:7b|Qwen 2.5 7B - 보통, 고품질 (4.7GB)"
)

while true; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPU 최적화 모델 목록 (추천순):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for i in {1..7}; do
        IFS='|' read -r model desc <<< "${MODELS[$i]}"
        echo "  $i) $desc"
    done
    echo "  0) 종료"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "다운로드할 모델 번호 입력 (여러 개는 공백으로 구분, 예: 1 3 5): " choices
    
    # 종료 체크
    if [[ "$choices" == "0" ]]; then
        echo "종료합니다."
        break
    fi
    
    # 입력된 번호 처리
    for choice in $choices; do
        if [[ -n "${MODELS[$choice]}" ]]; then
            IFS='|' read -r model desc <<< "${MODELS[$choice]}"
            echo ""
            echo ">>> $model 다운로드 중..."
            docker exec ollama ollama pull $model
            
            if [ $? -eq 0 ]; then
                echo "✓ $model 다운로드 완료"
            else
                echo "✗ $model 다운로드 실패"
            fi
            echo ""
        else
            echo "✗ 잘못된 번호: $choice"
        fi
    done
    
    echo ""
    read -p "계속 다운로드 하시겠습니까? (y/n): " continue
    if [[ "$continue" != "y" && "$continue" != "Y" ]]; then
        break
    fi
    echo ""
done

echo ""
echo "=== 현재 설치된 모델 목록 ==="
docker exec ollama ollama list
