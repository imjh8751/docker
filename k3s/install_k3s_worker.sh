#!/bin/bash

# 변수 초기화
TOKEN=`curl http://192.168.0.69:8080/k3s_token.log`
MASTER_URL='https://192.168.0.75:6443'
HOSTNAME=$(hostname)

# 변수 출력
echo "The hostname of this machine is: $HOSTNAME"
echo "The TOKEN is : $TOKEN"
echo "The MASTER_URL is : $MASTER_URL"

# Master에 JOIN
curl -sfL https://get.k3s.io | K3S_URL=$MASTER_URL K3S_TOKEN=$TOKEN sh -

# worker node label 추가
kubectl label node $HOSTNAME node-role.kubernetes.io/worker=worker

# label 확인 
kubectl get nodes --show-labels

# node 확인 
kubectl get nodes
