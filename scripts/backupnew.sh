#!/bin/bash


echo  "boot dev"
findmnt -n -o SOURCE /

echo "not mounted"
findmnt -rno SOURCE

echo "non-noot-devices"
lsblk -ndo NAME | sed 's|^|/dev/|'

echo "all devices"
lsblk -ndo NAME,SIZE,MOUNTPOINT,TYPE| grep -v -e 'zram\|loop'

echgo "more"
lsblk -no NAME,SIZE,MOUNTPOINT,TYPE| grep -v -e 'zram\|loop'