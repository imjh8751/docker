#!/bin/bash
# 파일명: /root/docker/mount-check.sh

# NFS 마운트 정보 (mount-nfs.sh에서 사용하는 값으로 수정 필요)
NFS_SERVER="192.168.0.98"
NFS_SHARE="/pv4-zfs/pv4-nas/DOCKER"
MOUNT_POINT="/APP"

# 로그 함수
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> /var/log/mount-checker.log
}

# NFS 서버 연결 가능 여부 확인
check_nfs_server() {
    ping -c 1 $NFS_SERVER > /dev/null 2>&1
    return $?
}

# 마운트 상태 확인
is_mounted() {
    mount | grep -q "$MOUNT_POINT"
    return $?
}

# 메인 로직
log "NFS 마운트 상태 확인 시작"

if is_mounted; then
    log "NFS가 이미 마운트되어 있습니다. 작업 필요 없음."
    exit 0
fi

if check_nfs_server; then
    log "NFS 서버가 응답합니다. 마운트 시도 중..."
    # mount-nfs.sh 스크립트 실행
    bash /root/docker/mount-docker.sh
    
    if is_mounted; then
        log "NFS 마운트 성공"
    else
        log "NFS 마운트 실패. 다음 주기에 재시도합니다."
    fi
else
    log "NFS 서버에 연결할 수 없습니다. 다음 주기에 재시도합니다."
fi

exit 0
