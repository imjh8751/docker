#!/bin/bash

# Pending 상태의 node-bootstrapper CSR을 찾고 승인하는 스크립트

# Pending CSR 목록 추출
#pending_csrs=$(oc get csr | grep Pending | grep node-bootstrapper | awk '{print $1}')
pending_csrs=$(oc get csr | grep Pending | awk '{print $1}')

# CSR 승인
for csr in $pending_csrs; do
  oc adm certificate approve $csr
  echo "Approved CSR: $csr"
done

# 인증서가 만료되어 bastion에서 oc 명령어 수행이 되지 않을 경우 갱신 방법
#ssh core@master01 sudo export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-int.kubeconfig
#ssh core@master01 sudo oc get csr -o name | xargs oc adm certificate approve
