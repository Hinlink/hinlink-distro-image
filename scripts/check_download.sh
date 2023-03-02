#!/bin/bash

IMG_TYPE=$1
IMG_VERSION=$2
IMG_ARCH=$3

tar --use-compress-program=pigz -cf rootfs.tar.gz rootfs.img
