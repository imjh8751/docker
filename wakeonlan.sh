#!/bin/bash

NUM=$1

case $NUM in
    1)
        PVE="00:16:96:EC:12:25"
        ;;
    2)
        PVE="68:1D:EF:28:E6:E3"
        ;;
    3)
        PVE="88:04:5B:50:E9:0A"
        ;;
    4)
        PVE="68:1D:EF:3F:FB:88"
        ;;
    *)
        echo "Invalid input. Please enter a number between 1 and 4."
        exit 1
        ;;
esac

echo $PVE
sudo wakeonlan "$PVE"
