#!/bin/bash
##############################################
### 1. k3s 설치
# 1. **필수 패키지 설치**
#sudo apt-get update
#sudo apt-get install -y curl

TOKEN='K1076ac5a5f89d15ff22af99283eae6350cf17921a165e2579780bb1ac0dc2afd21::server:2f3aab1e75b91398b8da48e97a25c3a7'

# 환경 변수 설정
export K3S_TOKEN=$TOKEN
export INSTALL_K3S_EXEC="--disable=traefik"

# 2. k3s 설치
curl -sfL https://get.k3s.io | sh -

# 3. **설치 확인**
#sudo systemctl status k3s

##############################################
### 2. kubectl 설정
# 1. **kubeconfig 파일 설정**
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 2. **환경 변수 설정**
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc

##############################################
### 3. kubectl 설치
# 1 k3s 복사
sudo cp /usr/local/bin/k3s /usr/bin/
sudo cp /usr/local/bin/kubectl /usr/bin/

# 3. 버전확인
kubectl version --client

##############################################
# kubectl 자동 완성 활성화
source <(kubectl completion bash)

# kubectl 단축 명령어 설정
alias k='kubectl'

# bash 자동 완성 설정
complete -o default -F __start_kubectl k

echo "kubectl 자동 완성과 alias가 설정되었습니다."

##############################################
### 4. 노드 및 파드 확인
# 1. **노드 확인**
k get nodes

# 2. **파드 확인**
k get pods --all-namespaces

##############################################
# 모든 워커 노드에 레이블을 설정하는 스크립트
# 노드 목록을 가져와서 워커 노드에 레이블을 설정
for NODE in $(kubectl get nodes --no-headers | grep "master\|control-plane" | awk '{print $1}')
do
  kubectl label node $NODE node-role.kubernetes.io/worker=worker --overwrite
  echo "노드 $NODE에 'node-role.kubernetes.io/worker=worker' 레이블이 설정되었습니다."
done

# label 확인 
kubectl get nodes --show-labels

# node 확인 
kubectl get nodes
