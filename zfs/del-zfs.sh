#!/bin/bash

FS_NAME=$1

# delete filesystem
zfs destroy pv-zfs/$FS_NAME

# zfs quota list
zfs get quota pv-zfs/$FS_NAME

# zfs list
zfs list pv-zfs/$FS_NAME

# delete zfs pool 
#zpool destroy pv-zfs
