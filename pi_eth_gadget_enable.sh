#!/bin/sh

set -e

if [ ! -f "$1" ] ; then
    echo "usage: $0 ISO_IMAGE" 2>&1
    exit 1
fi

if [ $(id -u) != 0 ] ; then
    echo "must be run as root" 2>&1
    exit 1
fi


printf "Mounting loop device.. "
dev=$(losetup -fP --show "$1")
sleep 1
printf "%s\n" "$dev"

part=$(lsblk -lpno NAME,FSTYPE "${dev}" | awk '/.*vfat/ { print $1 }')
printf "Found vfat partition on %s\n" "$part"

printf "Mounting %s in /mnt.. " "$part"
mount "$part" /mnt
printf "OK\n"

if [ ! -f /mnt/g_ether_enabled ] ; then
    printf "Enabling ethernet gadget.."

    tmpfile=$(mktemp)
    sed "s/rootwait quiet/rootwait modules-load=dwc2,g_ether quiet/" \
        /mnt/cmdline.txt > "$tmpfile"
    mv "$tmpfile" /mnt/cmdline.txt

    echo 'dtoverlay=dwc2' >> /mnt/config.txt
    touch /mnt/g_ether_enabled

    printf "OK\n"
else
    printf "\e[31;40mEthernet gadget already enabled\n\e[0m"
fi

printf "Unmounting %s.. " "$part"
umount "$part"
printf "OK\n"

printf "Removing loop device %s.. " "$dev"
losetup -d "$dev"
printf "OK\n"
