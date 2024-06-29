#!/bin/bash

sudo mkdir -p /APP
sudo umount /APP
sudo mount 192.168.0.102:/export/DOCKER /APP
