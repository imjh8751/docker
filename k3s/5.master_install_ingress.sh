#!/bin/bash

# Helm 설치 스크립트

# 최신 버전의 Helm 설치 스크립트 다운로드
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# 스크립트 실행 권한 부여
chmod 700 get_helm.sh

# Helm 설치 스크립트 실행
./get_helm.sh

# 설치된 Helm 버전 확인
helm version

########################################################################
# 변수 설정
NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
CHART_NAME="ingress-nginx/ingress-nginx"

# 최신 버전 가져오기
LATEST_VERSION=$(helm search repo $CHART_NAME --devel | grep $CHART_NAME | awk '{print $2}' | head -n 1)

# 설치 함수
install_ingress_nginx() {
  echo "Installing ingress-nginx version $LATEST_VERSION..."
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  helm install $RELEASE_NAME $CHART_NAME --namespace $NAMESPACE --create-namespace --version $LATEST_VERSION
  echo "Ingress-nginx installed successfully."
}

# 삭제 함수
uninstall_ingress_nginx() {
  echo "Uninstalling ingress-nginx..."
  helm uninstall $RELEASE_NAME --namespace $NAMESPACE
  kubectl delete namespace $NAMESPACE
  echo "Ingress-nginx uninstalled successfully."
}

# 사용법 안내
usage() {
  echo "Usage: $0 {install|uninstall}"
  exit 1
}

# 스크립트 실행
if [ "$1" == "install" ]; then
  install_ingress_nginx
elif [ "$1" == "uninstall" ]; then
  uninstall_ingress_nginx
else
  usage
fi
