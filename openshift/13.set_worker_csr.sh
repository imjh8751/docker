#!/bin/bash

# Pending 상태의 node-bootstrapper CSR을 찾고 승인하는 스크립트

# Pending CSR 목록 추출
pending_csrs=$(oc get csr | grep Pending | grep node-bootstrapper | awk '{print $1}')

# CSR 승인
for csr in $pending_csrs; do
  oc adm certificate approve $csr
  echo "Approved CSR: $csr"
done
