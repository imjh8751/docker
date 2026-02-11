# v2.10.0 온라인 인스톨러 다운로드 (버전은 상황에 맞게 변경)
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz

# 압축 해제 및 디렉터리 이동
tar xvf harbor-online-installer-v2.10.0.tgz
cd harbor

cp harbor.yml.tmpl harbor.yml
vi harbor.yml
