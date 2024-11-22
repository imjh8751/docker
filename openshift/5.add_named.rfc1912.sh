#!/bin/bash

ZONE_CONFIG_FILE="/etc/named.rfc1912.zones"

cat <<EOF >> $ZONE_CONFIG_FILE

zone "okd.io" IN {
        type master;
        #file "okd.io.zone";  # MASTER 3, WORKER 2, BOOTSTRAP 1, BASTION 1
        file "okd.io.min.zone";  # MASTER 1, WORKER 2, BOOTSTRAP 1, BASTION 1
        #file "okd.io.sno.zone";  # MASTER 3, WORKER 2, BOOTSTRAP 1, BASTION 1
        allow-update { none; };
};

zone "0.168.192.in-addr.arpa" IN {
        type master;
        #file "0.168.192.rev.zone";  # MASTER 3, WORKER 2, BOOTSTRAP 1, BASTION 1
        file "0.168.192.rev.min.zone";  # MASTER 1, WORKER 2, BOOTSTRAP 1, BASTION 1
        #file "0.168.192.rev.sno.zone";  # MASTER 1, BOOTSTRAP 1, BASTION 1
        allow-update { none; };
};
EOF

echo "Zone configurations have been added to $ZONE_CONFIG_FILE"
