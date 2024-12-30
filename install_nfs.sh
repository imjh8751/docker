# 리눅스에서 특정 폴더를 NFS(Network File System) 공유 폴더로 설정하는 방법을 안내해드릴게요. 다음 단계를 따라 설정할 수 있습니다:

### 1. NFS 서버 패키지 설치
# 먼저 NFS 서버 패키지를 설치합니다:
sudo apt update
sudo apt install -y nfs-kernel-server

### 2. 공유 폴더 설정
# `/etc/exports` 파일을 편집하여 공유 폴더를 설정합니다:
# vi /etc/exports

# 파일에 다음 내용을 추가합니다:
# /volume2/DOCKER 192.168.0.0/24(rw,sync,no_subtree_check)

# 이 예시에서는 `192.168.1.0/24` 네트워크에 있는 클라이언트가 폴더 `/path/to/share`를 읽고 쓸 수 있도록 설정합니다.

### 3. NFS 서비스 시작
# NFS 서비스를 시작하고 자동 시작을 설정합니다:
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server

### 4. NFS 서버 확인
# NFS 서버가 올바르게 작동하는지 확인합니다:
exportfs -v

### 5. 클라이언트에서 마운트 설정
# 클라이언트에서 NFS 공유 폴더를 마운트합니다:
# mount 192.168.0.0/24:/volume2/DOCKER /APP
