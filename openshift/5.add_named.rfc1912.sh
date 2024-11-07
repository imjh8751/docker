#!/bin/bash

ZONE_CONFIG_FILE="/etc/named.rfc1912.zones"

cat <<EOF >> $ZONE_CONFIG_FILE

zone "okd.io" IN {
        type master;
        file "okd.io.zone";
        allow-update { none; };
};

zone "0.168.192.in-addr.arpa" IN {
        type master;
        file "0.168.192.rev.zone";
        allow-update { none; };
};
EOF

echo "Zone configurations have been added to $ZONE_CONFIG_FILE"
