#!/bin/sh

set -e


unmount () {
    for f in $(lsblk -lpno NAME | grep -oE "^$1.+$") ; do
        printf "Unmounting %s.. " "$f"
        udisksctl unmount --no-user-interaction --force -b "$f" >/dev/null
        printf "OK\n"
    done

    sleep 1

    if [ $(lsblk -lpno NAME | grep -oE "^$1$") ] ; then
        printf "Removing loop-device %s.. " "$1"
        udisksctl loop-delete --no-user-interaction -b "$1" >/dev/null
        printf "OK\n"
    fi
}

mount () {
    printf "Mounting loop device.. "
    dev=$(udisksctl loop-setup --no-user-interaction -f "$1" | grep -o "/dev/loop[0-9]*")
    printf "%s\n" "$dev"
}


if [ ! -f "$1" ] ; then
    echo "usage: $0 IMAGE" 2>&1
    exit 1
fi

mount "$1"
if [ "${dev}" ] ; then
    trap "unmount ${dev}" EXIT
    sleep 1
fi

dir=$(lsblk -lpno MOUNTPOINT,FSTYPE "${dev}" | awk '/.*vfat/ { print $1 }')
if [ ! -d "${dir}" ] ; then
    echo "No vfat partition found" 2>&1
    exit 1
fi
printf "Found vfat partition in %s\n" "$dir"

if [ ! -f "${dir}/g_ether_enabled" ] ; then
    printf "Enabling ethernet gadget.. "

    tmpfile=$(mktemp)
    sed "s/rootwait quiet/rootwait modules-load=dwc2,g_ether quiet/" \
        "${dir}/cmdline.txt" > "$tmpfile"
    mv "$tmpfile" "${dir}/cmdline.txt"

    echo 'dtoverlay=dwc2' >> "${dir}/config.txt"
    touch "${dir}/g_ether_enabled"

    printf "OK\n"
else
    printf "\e[31;40mEthernet gadget already enabled\n\e[0m"
fi
