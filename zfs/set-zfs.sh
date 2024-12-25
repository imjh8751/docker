#!/bin/bash

FS_NAME=$1

# create filesystem
zfs create pv-zfs/$FS_NAME

# set quota filesystem
zfs set quota=1TB pv-zfs/$FS_NAME

# zfs quota list
zfs get quota pv-zfs/$FS_NAME

# zfs list
zfs list pv-zfs/$FS_NAME

# set unlimit quota
#zfs set quota=none pv-zfs/FS_NAME
