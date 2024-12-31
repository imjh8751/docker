#!/bin/bash

# 인증서 정보 설정
DOMAIN="itapi.io"
WILDCARD_DOMAIN="*.${DOMAIN}"
DAYS_VALID=3650
COUNTRY="KR"
STATE="Gyeonggi-do"
LOCALITY="Republic ITAPI"
ORGANIZATION="ITAPI"
ORG_UNIT="ITAPI Company"
EMAIL="imjh8751@gmail.com"

# 키와 인증서 경로 설정
KEY_PATH="${DOMAIN}.key"
CERT_PATH="${DOMAIN}.crt"
CSR_PATH="${DOMAIN}.csr"

# 개인 키 생성
openssl genpkey -algorithm RSA -out $KEY_PATH -pkeyopt rsa_keygen_bits:2048

# CSR (Certificate Signing Request) 생성
openssl req -new -key $KEY_PATH -out $CSR_PATH -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$WILDCARD_DOMAIN/emailAddress=$EMAIL"

# 인증서 생성
openssl x509 -req -days $DAYS_VALID -in $CSR_PATH -signkey $KEY_PATH -out $CERT_PATH

# PEM 형식으로 변환
cat $CERT_PATH $KEY_PATH > "${DOMAIN}.pem"

# 생성된 파일 확인
echo "Generated files:"
echo "Private Key: $KEY_PATH"
echo "Certificate: $CERT_PATH"
echo "PEM File: ${DOMAIN}.pem"
