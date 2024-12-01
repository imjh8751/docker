#!/bin/bash

# namespace 생성
kubectl create namespace argocd

# istio 가 설치되어있다면 injection 추가
#kubectl label ns argocd istio-injection=enabled

# Argo CD 설치 YAML 파일 다운로드
curl -o install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# --insecure 옵션 추가
sed -i '/- \/usr\/local\/bin\/argocd-server/a\        - --insecure' install.yaml

# Argo CD 설치
kubectl apply -n argocd -f install.yaml

# ArgoCD 초기 관리자 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode

#############################################################################################################
# 참고용
# 설치 
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 삭제
#kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
