#!/bin/bash

mkdir -p /APP
umount /APP
mount 192.168.0.98:/pv4-zfs/pv4-nas/DOCKER /APP
