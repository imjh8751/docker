#!/bin/bash

# namespace 생성
kubectl create namespace argocd

# istio 가 설치되어있다면 injection 추가
kubectl label ns argocd istio-injection=enabled

# Argo CD 설치 YAML 파일 다운로드
curl -o install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# --insecure 옵션 추가
sed -i '/containers:/!b;n;/args:/!b;n;a\        - --insecure' install.yaml

# Argo CD 설치
kubectl apply -f install.yaml




#############################################################################################################
# 참고용
# 설치 
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 삭제
#kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
