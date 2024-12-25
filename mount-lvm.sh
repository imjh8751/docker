# 헤놀로지 NAS SSD MOUNT 작업

# 1. **LVM2 모듈 로드**:
sudo modprobe dm-mod

# 2. **볼륨 그룹 초기화**:
sudo vgscan
sudo vgchange -ay

# 3. **볼륨 마운트**:
sudo mount /dev/VolGroup00/LogVol00 /APP

#여기서 `VolGroup00`와 `LogVol00`는 실제 볼륨 그룹과 로그 볼륨 이름입니다. 이 단계를 통해 LVM2 레이블을 사용한 볼륨을 올바르게 초기화하고 마운트할 수 있습니다.

sudo vgdisplay
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

sudo lvdisplay
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

sudo vgs
#  VG        #PV #LV #SN Attr   VSize   VFree
#  VolGroup00   1   2   0 wz--n- <20.00g    0

sudo lvs
#  LV       VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
#  LogVol00 VolGroup00 -wi-ao---- <10.00g                                                    
