#!/bin/bash

# HTPasswd 파일 생성
htpasswd_file="ocp_users.htpasswd"

# 유저 신규 생성
htpasswd -c -B -b $htpasswd_file itapi itapi

# 유저 추가
#htpasswd -B -b $htpasswd_file user2 password2

# OpenShift 클러스터에 Secret 생성
oc create secret generic htpass-secret --from-file=htpasswd=$htpasswd_file -n openshift-config

# HTPasswd IDP(Resource) 생성
cat <<EOF > htpasswd-idp.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

# HTPasswd IDP(Resource) 적용
oc apply -f htpasswd-idp.yaml

echo "HTPasswd를 이용한 OAuth가 적용되었습니다!"

# 사용자 이름
USER="itapi"

# 사용자에게 cluster-admin 권한 부여
oc adm policy add-cluster-role-to-user cluster-admin $USER

echo "Cluster-admin 권한이 $USER 사용자에게 부여되었습니다."
