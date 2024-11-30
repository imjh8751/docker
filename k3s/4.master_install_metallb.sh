#!/bin/bash

# MetalLB 최신 버전 가져오기
#latest_version=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
latest_version='v0.12.1'

# MetalLB 네임스페이스 생성
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$latest_version/manifests/namespace.yaml

# MetalLB secret 생성
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# MetalLB 컨트롤러 배포
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$latest_version/manifests/metallb.yaml

echo "MetalLB가 설치되었습니다."
echo "다음 단계로 configmap을 설정하여 IP 풀을 설정하세요."

# IP 풀 구성 :
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.0.240-192.168.0.250 #IP 충돌되지 않게 대역대 유의
EOF
