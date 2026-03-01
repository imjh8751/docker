#!/bin/bash

echo "export KUBECONFIG=/root/installation_directory_sno/auth/kubeconfig" >> ~/.bash_profile
export KUBECONFIG=/root/installation_directory_sno/auth/kubeconfig
. /root/.bash_profile

# bash completion code file 생성
oc completion bash > oc_bash_completion

# /etc/bash_completion.d/에 파일 복사
cp oc_bash_completion /etc/bash_completion.d/