#!/bin/bash

# install bootstrap and master
openshift-install --dir /root/installation_directory wait-for bootstrap-complete --log-level=info