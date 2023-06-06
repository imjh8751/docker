git clone https://github.com/rhymix/rhymix.git

# 이렇게 하면 rhymix라는 폴더가 생성되고, 그 안에 라이믹스가 다운로드됩니다. 
# rhymix 폴더를 원하시지 않는 경우 상위 폴더에서 아래의 명령을 사용하여 rhymix 폴더의 내용(숨김파일 포함)을 모두 상위 폴더로 옮겨주시기 바랍니다.
shopt -s dotglob
mv rhymix/* .
shopt -u dotglob

# git으로 다운로드하면 기본으로 정식버전(master 브랜치)이 선택됩니다. develop 브랜치로 전환하시려면 아래의 명령을 내리면 됩니다.
#git checkout develop

# 라이믹스를 다운로드한 경로에 files 폴더를 생성하고, 퍼미션을 777 또는 707로 변경합니다.
mkdir files
chmod 777 files
