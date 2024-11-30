#!/bin/bash

# 모든 워커 노드에 레이블을 설정하는 스크립트
# 노드 목록을 가져와서 워커 노드에 레이블을 설정
for NODE in $(kubectl get nodes --no-headers | grep -v "master\|control-plane" | awk '{print $1}')
do
  kubectl label node $NODE node-role.kubernetes.io/worker=worker --overwrite
  echo "노드 $NODE에 'node-role.kubernetes.io/worker=worker' 레이블이 설정되었습니다."
done

# label 확인 
kubectl get nodes --show-labels

# node 확인 
kubectl get nodes
