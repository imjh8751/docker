#!/bin/bash

ZONE_FILE="/var/named/okd.io.zone"

cat <<EOF >> $ZONE_FILE
\$TTL 60
@ IN    SOA    ocp.ocp4.okd.io.    root (
                            2023012001    ; serial
                            1D       ; refresh
                            1H       ; retry
                            1W      ; expire
                            3H )    ; minimum

                 IN      NS      ocp.ocp4.okd.io.

ocp4             IN      A        192.168.0.69
ocp.ocp4         IN      A        192.168.0.69
helper.ocp4      IN      A        192.168.0.69
api.ocp4         IN      A        192.168.0.69
api-int.ocp4     IN      A        192.168.0.69
*.ocp4           IN      A        192.168.0.69

bootstrap.ocp4   IN      A        192.168.0.70

master01.ocp4    IN      A        192.168.0.71
master02.ocp4    IN      A        192.168.0.72
master03.ocp4    IN      A        192.168.0.73

worker01.ocp4    IN      A        192.168.0.74
worker02.ocp4    IN      A        192.168.0.75
EOF

echo "DNS records have been added to $ZONE_FILE"