#!/bin/bash

# 1. 변수 설정
MODEL_NAME="llama3.2-korean"
GGUF_FILE="llama-3.2-Korean-Bllossom-3B-gguf-Q4_K_M.gguf"
DOWNLOAD_URL="https://huggingface.co/Bllossom/llama-3.2-Korean-Bllossom-3B-gguf-Q4_K_M/resolve/main/llama-3.2-Korean-Bllossom-3B-gguf-Q4_K_M.gguf"

echo "--- 1. GGUF 모델 파일 다운로드 시작 ---"
if [ ! -f "$GGUF_FILE" ]; then
    wget -O "$GGUF_FILE" "$DOWNLOAD_URL"
else
    echo "파일이 이미 존재합니다. 다운로드를 건너뜁니다."
fi

echo "--- 2. Modelfile 생성 ---"
cat << 'EOF' > Modelfile
FROM ./llama-3.2-Korean-Bllossom-3B-gguf-Q4_K_M.gguf

PARAMETER temperature 0.6
PARAMETER top_p 0.9

TEMPLATE """<|start_header_id|>system<|end_header_id|>

Cutting Knowledge Date: December 2023

{{ if .System }}{{ .System }}
{{- end }}
{{- if .Tools }}When you receive a tool call response, use the output to format an answer to the orginal user question.

You are a helpful assistant with tool calling capabilities.
{{- end }}<|eot_id|>
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1 }}
{{- if eq .Role "user" }}<|start_header_id|>user<|end_header_id|>
{{- if and $.Tools $last }}

Given the following functions, please respond with a JSON for a function call with its proper arguments that best answers the given prompt.

Respond in the format {"name": function name, "parameters": dictionary of argument name and its value}. Do not use variables.

{{ range $.Tools }}
{{- . }}
{{ end }}
{{ .Content }}<|eot_id|>
{{- else }}

{{ .Content }}<|eot_id|>
{{- end }}{{ if $last }}<|start_header_id|>assistant<|end_header_id|>

{{ end }}
{{- else if eq .Role "assistant" }}<|start_header_id|>assistant<|end_header_id|>
{{- if .ToolCalls }}
{{ range .ToolCalls }}
{"name": "{{ .Function.Name }}", "parameters": {{ .Function.Arguments }}}{{ end }}
{{- else }}

{{ .Content }}
{{- end }}{{ if not $last }}<|eot_id|>{{ end }}
{{- else if eq .Role "tool" }}<|start_header_id|>ipython<|end_header_id|>

{{ .Content }}<|eot_id|>{{ if $last }}<|start_header_id|>assistant<|end_header_id|>

{{ end }}
{{- end }}
{{- end }}"""

SYSTEM """You are a helpful AI assistant. Please answer the user's questions kindly. 당신은 유능한 AI 어시스턴트 입니다. 사용자의 질문에 대해 친절하게 답변해주세요."""
EOF

echo "--- 3. Ollama 모델 생성 ($MODEL_NAME) ---"
ollama create $MODEL_NAME -f Modelfile

echo "--- 4. 설치 완료! 모델을 실행합니다. ---"
ollama run $MODEL_NAME
