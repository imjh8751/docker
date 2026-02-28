#!/bin/bash

echo "export KUBECONFIG=/root/installation_directory/auth/kubeconfig" >> ~/.bash_profile
export KUBECONFIG=/root/installation_directory/auth/kubeconfig
. /root/.bash_profile

# bash completion code file 생성
oc completion bash > oc_bash_completion

# /etc/bash_completion.d/에 파일 복사
cp oc_bash_completion /etc/bash_completion.d/

# 또 다른 방법
#oc completion bash > oc_completion.sh

# .bashrc 마지막에 아래 내용 추가(파일 저장 위치 확인 필요)
# source oc_completion.sh
