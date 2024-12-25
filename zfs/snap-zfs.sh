#!/bin/bash

FS_NAME=$1
YYYYMMDD=$(date +%Y%m%d)

# 스냅샷 생성
zfs snapshot pv-zfs/$FS_NAME@snapshot1

# list snapshot
zfs list -t snapshot

# 스냅샷을 파일로 출력
zfs send pv-zfs/$FS_NAME@snapshot1 > /root/backup/snapshot1.zfs

# 출력된 파일 확인
ls -lh /root/backup/snapshot1.zfs

# 파일 시스템 복원 (옵션)
#zfs receive pv-zfs/$FS_NAME < /root/backup/snapshot1.zfs

# restore snapshot
#zfs rollback pv-zfs/$FS_NAME@snapshot1
