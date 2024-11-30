#!/bin/bash

# istio 다운로드
curl -L https://istio.io/downloadIstio | sh -

# istioctl 복
cd istio*
cp ./bin/istioctl /usr/local/bin/

# demo 버전 설치
istioctl install --set profile=demo -y

# default namespace injection 추가
kubectl label namespace default istio-injection=enabled
