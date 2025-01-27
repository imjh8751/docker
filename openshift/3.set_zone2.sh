#!/bin/bash

ZONE_FILE="/var/named/0.168.192.rev.zone"
ZONE_FILE2="/var/named/0.168.192.rev.min.zone"
ZONE_FILE3="/var/named/0.168.192.rev.sno.zone"

cat <<EOF >> $ZONE_FILE
\$TTL 60
@ IN    SOA    ocp.ocp4.okd.io.    root (
                            2023012001    ; serial
                            1D       ; refresh
                            1H       ; retry
                            1W      ; expire
                            3H )    ; minimum

           IN    NS    ocp.ocp4.okd.io.

69         IN    PTR    api.ocp4.okd.io.
69         IN    PTR    api-int.ocp4.okd.io.

70         IN    PTR    bootstrap.ocp4.okd.io.

71         IN    PTR    master01.ocp4.okd.io.
72         IN    PTR    master02.ocp4.okd.io.
73         IN    PTR    master03.ocp4.okd.io.

74         IN    PTR    worker01.ocp4.okd.io.
75         IN    PTR    worker02.ocp4.okd.io.
EOF


cat <<EOF >> $ZONE_FILE2
\$TTL 60
@ IN    SOA    ocp.ocp4.okd.io.    root (
                            2023012001    ; serial
                            1D       ; refresh
                            1H       ; retry
                            1W      ; expire
                            3H )    ; minimum

           IN    NS    ocp.ocp4.okd.io.

69         IN    PTR    api.ocp4.okd.io.
69         IN    PTR    api-int.ocp4.okd.io.

70         IN    PTR    bootstrap.ocp4.okd.io.

71         IN    PTR    master01.ocp4.okd.io.

72         IN    PTR    worker01.ocp4.okd.io.
73         IN    PTR    worker02.ocp4.okd.io.
EOF


cat <<EOF >> $ZONE_FILE3
\$TTL 60
@ IN    SOA    ocp.ocp4.okd.io.    root (
                            2023012001    ; serial
                            1D       ; refresh
                            1H       ; retry
                            1W      ; expire
                            3H )    ; minimum

           IN    NS    ocp.ocp4.okd.io.

69         IN    PTR    api.ocp4.okd.io.
69         IN    PTR    api-int.ocp4.okd.io.

70         IN    PTR    bootstrap.ocp4.okd.io.

71         IN    PTR    master01.ocp4.okd.io.
EOF

chown root:named /var/named/0.168.*.zone
echo "Reverse DNS records have been added to $ZONE_FILE"
