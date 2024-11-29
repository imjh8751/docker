#!/bin/bash

# k3s 에이전트 중지
sudo systemctl stop k3s-agent

# k3s 관련 프로세스 종료
sudo /usr/local/bin/k3s-killall.sh

# k3s 에이전트 서비스 비활성화
sudo systemctl disable k3s-agent

echo "k3s 워커 노드가 마스터 노드에서 성공적으로 종료되었습니다."
