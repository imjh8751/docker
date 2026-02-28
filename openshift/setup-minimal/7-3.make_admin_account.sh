#!/bin/bash

# 1. HTPasswd 파일 및 Secret 생성 (기존과 동일)
htpasswd_file="ocp_users.htpasswd"
htpasswd -c -B -b $htpasswd_file itapi itapi
oc create secret generic htpass-secret --from-file=htpasswd=$htpasswd_file -n openshift-config --dry-run=client -o yaml | oc apply -f -

# 2. LDAP Bind Secret 생성 (기존과 동일)
oc create secret generic ad-ldap-secret --from-literal=bindPassword='Admin2580!' -n openshift-config --dry-run=client -o yaml | oc apply -f -

# 3. [핵심] 통합 OAuth 설정 적용 (HTPasswd + LDAP를 하나의 리스트로 구성)
cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local_HTPasswd_Provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
  - name: AD_LDAP_Provider
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id: ["sAMAccountName"] # dn 대신 sAMAccountName으로 변경하여 고유 ID 생성
        email: ["mail"]
        name: ["displayName"]
        preferredUsername: ["sAMAccountName"]
      bindDN: "CN=ldapadm,OU=adm,DC=itapi,DC=org"
      bindPassword:
        name: ad-ldap-secret
      insecure: true
      url: "ldap://192.168.0.200:389/DC=itapi,DC=org?sAMAccountName?sub?"
EOF

echo "HTPasswd와 LDAP 통합 OAuth 설정이 적용되었습니다."

# 권한 부여 (사용자가 한 번이라도 로그인한 후에 수행하거나, 미리 생성)
# 4. OpenShift 내부에 그룹 생성
oc adm groups new ocp-admins

# 5. 그룹에 cluster-admin 권한 부여
oc adm policy add-cluster-role-to-group cluster-admin ocp-admins

# 6. 해당 그룹에 AD 유저 ID 추가 (로그인 전 미리 가능)
oc adm groups add-users ocp-admins itapi