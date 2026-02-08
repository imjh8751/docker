#!/bin/bash

# 1. 변수 설정
# Qwen2.5-3B-Instruct 모델 (Q4_K_M 양자화 버전 - 약 2GB)
MODEL_NAME="qwen2.5-3b-ko"
GGUF_FILE="qwen2.5-3b-instruct-q4_k_m.gguf"
DOWNLOAD_URL="https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"

echo "--- 1. Qwen2.5-3B GGUF 모델 다운로드 시작 ---"
# 파일이 없을 때만 다운로드
if [ ! -f "$GGUF_FILE" ]; then
    wget -O "$GGUF_FILE" "$DOWNLOAD_URL"
else
    echo "파일이 이미 존재합니다. 다운로드를 건너뜁니다."
fi

echo "--- 2. Modelfile 생성 (ChatML 템플릿 적용) ---"
# Qwen 모델은 ChatML 템플릿을 사용하는 것이 성능상 유리합니다.
cat << 'EOF' > Modelfile
FROM ./qwen2.5-3b-instruct-q4_k_m.gguf

# Jetson Orin Nano의 자원을 고려한 파라미터 설정
PARAMETER temperature 0.7
PARAMETER top_p 0.8
PARAMETER repeat_penalty 1.05

# Qwen2.5 공식 ChatML 템플릿
TEMPLATE """<|im_start|>system
{{ .System }}<|im_end|>
<|im_start|>user
{{ .Prompt }}<|im_end|>
<|im_start|>assistant
"""

SYSTEM """You are Qwen, a helpful AI assistant. You answer the user's questions accurately and kindly in Korean.
당신은 Qwen입니다. 사용자의 질문에 한국어로 정확하고 친절하게 답변해주세요."""
EOF

echo "--- 3. Ollama 모델 빌드 ($MODEL_NAME) ---"
ollama create $MODEL_NAME -f Modelfile

echo "--- 4. 모델 실행 (메모리 점유율 확인을 위해 jtop을 별도로 켜두세요) ---"
echo "실행 명령어: ollama run $MODEL_NAME"
ollama run $MODEL_NAME
