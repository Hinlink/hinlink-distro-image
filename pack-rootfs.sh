#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="rootfs_temp"
ROOTFS_UUID="614e0000-0000-4b53-8000-1d28000054a9"
ROOTFS_IMAGE=rootfs.img
IMAGE_SIZE=6144

source scripts/general.sh

if [[ "${EUID}" == "0" ]] ; then
    :
else
    display_alert "This script requires root privileges, trying to use sudo" "" "wrn"
    sudo "$0" "$@"
    exit $?
fi

display_alert "Building for" "$ARCH"
display_alert "Building version" "$VERSION"

function create_rootfs_img() {
    display_alert "[1/8]Creat disk image" "EXT4"
    rm $1 -f
    dd if=/dev/zero of=$1 bs=1MiB count=$2
    mkfs.ext4 -U $ROOTFS_UUID -q -m 2 -O ^64bit,^metadata_csum $1
    echo "origin rootfs: `shasum $1`"
}

function build_host_clean() {
    rm -rf $TARGET_ROOTFS_DIR
}

function finish() {
    display_alert "Erro found" "abort"

    umount $TARGET_ROOTFS_DIR

    build_host_clean
	exit -1
}

# trap finish ERR
# trap finish SIGINT

if [ ! -n "$1" ] ;then
    display_alert "need param2" "abort"
else
    echo "the source dirctory is $1"
fi

sudo mkdir -p $TARGET_ROOTFS_DIR

create_rootfs_img $ROOTFS_IMAGE $IMAGE_SIZE
mount $ROOTFS_IMAGE $TARGET_ROOTFS_DIR
rsync -atHAXrlD --info=progress2 $1/* $TARGET_ROOTFS_DIR/
umount $TARGET_ROOTFS_DIR

sudo e2fsck -f $ROOTFS_IMAGE
sudo resize2fs -M $ROOTFS_IMAGE

sudo rm -rf $TARGET_ROOTFS_DIR
