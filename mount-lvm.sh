# 헤놀로지 NAS SSD MOUNT 작업

# 이 오류는 마운트할 파일 시스템 유형이 잘못된 것을 나타냅니다. `linux_raid_member` 파일 시스템 유형은 RAID 배열의 일부인 것을 의미합니다. RAID 배열을 마운트하려면 다음 단계를 따르세요:

#1. **mdadm 명령어 사용**: RAID 배열을 초기화하고 마운트합니다.
mdadm --assemble --scan
mount /dev/md0 /APP
#    여기서 `/dev/md0`는 실제 RAID 디바이스 이름이며, `/APP`는 마운트할 경로입니다.

#2. **RAID 디바이스 확인**: `mdadm --detail /dev/md0` 명령어를 사용하여 RAID 디바이스 상태를 확인할 수 있습니다.


# 1. **LVM2 모듈 로드**:
modprobe dm-mod

# 2. **볼륨 그룹 초기화**:
vgscan
vgchange -ay

# 3. **볼륨 마운트**:
mount /dev/VolGroup00/LogVol00 /APP

#여기서 `VolGroup00`와 `LogVol00`는 실제 볼륨 그룹과 로그 볼륨 이름입니다. 이 단계를 통해 LVM2 레이블을 사용한 볼륨을 올바르게 초기화하고 마운트할 수 있습니다.

vgdisplay
#  --- Volume group ---
#  VG Name               VolGroup00
#  System ID
#  Format                lvm2
#  Metadata Areas        1
#  Metadata Sequence No  3
#  VG Access             read/write
#  VG Status             resizable
#  MAX LV                0
#  Cur LV                2
#  Open LV               2
#  Max PV                0
#  Cur PV                1
#  Act PV                1
#  VG Size               <20.00 GiB
#  PE Size               4.00 MiB
#  Total PE              5119
#  Alloc PE / Size       5119 / <20.00 GiB
#  Free  PE / Size       0 / 0
#  VG UUID               ABCD-1234-EFGH-5678

lvdisplay
#  --- Logical volume ---
#  LV Path                /dev/VolGroup00/LogVol00
#  LV Name                LogVol00
#  VG Name                VolGroup00
#  LV UUID                ABCD-1234-EFGH-5678
#  LV Write Access        read/write
#  LV Creation host, time hostname, 2021-01-01 00:00:00
#  LV Status              available
#  # open                 1
#  LV Size                <10.00 GiB
#  Current LE             2559
#  Segments               1
#  Allocation             inherit
#  Read ahead sectors     auto
#  - currently set to     256
#  Block device           253:0

vgs
#  VG        #PV #LV #SN Attr   VSize   VFree
#  VolGroup00   1   2   0 wz--n- <20.00g    0

lvs
#  LV       VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
#  LogVol00 VolGroup00 -wi-ao---- <10.00g                                                    
