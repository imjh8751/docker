# 컨테이너에서 UID 1000번을 사용하기때문에 권한도 미리 셋팅합니다.

mkdir -p /data/opencloud/opencloud-config
mkdir -p /data/opencloud/opencloud-data

chown 1000:1000 /data/opencloud/opencloud-config
chown 1000:1000 /data/opencloud/opencloud-data
