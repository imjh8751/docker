# LXC 설정 파일 수정:
# Proxmox의 쉘에 접속합니다.
# /etc/pve/lxc 디렉토리로 이동합니다.
cd /etc/pve/lxc

# 설정하려는 LXC 컨테이너의 설정 파일을 엽니다. 예를 들어, 컨테이너 ID가 100이라면:
vi 100.conf

# 파일의 끝에 다음 줄을 추가합니다:
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 29:0 rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
