#!/bin/bash

# 변수 초기화
TOKEN=`curl http://192.168.0.69:8080/k3s_token.log`
MASTER_URL='https://192.168.0.75:6443'

# Master에 JOIN
curl -sfL https://get.k3s.io | K3S_URL=$MASTER_URL K3S_TOKEN=$TOKEN sh -
