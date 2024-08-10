#!/bin/bash

mkdir -p /APP
umount /APP
mount 192.168.0.10:/volume2/DOCKER /APP
