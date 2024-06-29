#!/bin/bash

mkdir -p /APP
umount /APP
mount 192.168.0.102:/export/DOCKER /APP
