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
PASSWORD="your_password_here"  # 원하는 비밀번호로 변경하세요

# 키와 인증서 경로 설정
KEY_PATH="${DOMAIN}.key"
CERT_PATH="${DOMAIN}.crt"
CSR_PATH="${DOMAIN}.csr"
PEM_PATH="${DOMAIN}.pem"
KEY_ENCRYPTED_PATH="${DOMAIN}-encrypted.key"

# 개인 키 생성
openssl genpkey -algorithm RSA -out $KEY_PATH -pkeyopt rsa_keygen_bits:2048

# 개인 키를 비밀번호로 암호화
openssl rsa -in $KEY_PATH -out $KEY_ENCRYPTED_PATH -aes256 -passout pass:$PASSWORD

# CSR (Certificate Signing Request) 생성
openssl req -new -key $KEY_PATH -out $CSR_PATH -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$WILDCARD_DOMAIN/emailAddress=$EMAIL"

# 인증서 생성
openssl x509 -req -days $DAYS_VALID -in $CSR_PATH -signkey $KEY_PATH -out $CERT_PATH

# PEM 형식으로 변환
cat $CERT_PATH $KEY_ENCRYPTED_PATH > $PEM_PATH

# 생성된 파일 확인
echo "Generated files:"
echo "Private Key: $KEY_PATH"
echo "Encrypted Private Key: $KEY_ENCRYPTED_PATH"
echo "Certificate: $CERT_PATH"
echo "PEM File: $PEM_PATH"
