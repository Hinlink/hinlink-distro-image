#!/bin/bash -e

TARGET_ROOTFS_DIR="/home/xianlee/workspace/debian/rootfs"
ROOTFS_IMAGE=rootfs.img

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

if [ ! -n "$1" ] ;then
    display_alert "need special dest directory, use default" "rootfs" "wrn"
else
    echo "the source dirctory is $1"
fi

sudo rm -rf $TARGET_ROOTFS_DIR

#sudo multistrap -a arm64 -f config/debug.conf
sudo multistrap -a arm64 -f config/arm64-server.conf

sudo cp scripts/multistrap_post_config.sh $TARGET_ROOTFS_DIR
sudo cp scripts/autologin.sh $TARGET_ROOTFS_DIR
sudo cp scripts/install-local-packages.sh $TARGET_ROOTFS_DIR

# sudo chroot $TARGET_ROOTFS_DIR bash multistrap_post_config.sh
chroot $TARGET_ROOTFS_DIR /bin/bash -c "/multistrap_post_config.sh"

# Empty root password
sudo chroot $TARGET_ROOTFS_DIR passwd -d root

# Get packages installed
chroot $TARGET_ROOTFS_DIR dpkg -l | awk '{if (NR>3) {print $2" "$3}}' > $TARGET_ROOTFS_DIR\-packages

# Install packages
chroot $TARGET_ROOTFS_DIR /bin/bash -c "apt --fix-broken install"
chroot $TARGET_ROOTFS_DIR /bin/bash -c "apt-get install -y -f"

display_alert "packages config finished" "" "info"

#---------------user system hack---------
chroot $TARGET_ROOTFS_DIR chown root:root /usr/bin/sudo
chroot $TARGET_ROOTFS_DIR chmod 4755 /usr/bin/sudo
chroot $TARGET_ROOTFS_DIR useradd -G sudo -m -s /bin/bash rock
chroot $TARGET_ROOTFS_DIR usermod -aG sudo rock
chroot $TARGET_ROOTFS_DIR /bin/bash -c "echo rock:rock | chpasswd"

# Generate locale
chroot $TARGET_ROOTFS_DIR locale-gen en_US.UTF-8

# Step 3: Configure debian rootfs

# Set hostname
filename=$TARGET_ROOTFS_DIR/etc/hostname
echo "linkstar" > $filename

display_alert "Setting hostname to" "linkstar" "info"

# Set hosts
filename=$TARGET_ROOTFS_DIR/etc/hosts
echo "127.0.0.1 localhost" > $filename
echo "127.0.1.1 linkstar" >> $filename
echo >> $filename
echo "# The following lines are desirable for IPv6 capable hosts" >> $filename
echo "::1 ip6-localhost ip6-loopback" >> $filename
echo "fe00::0 ip6-localnet" >> $filename
echo "ff00::0 ip6-mcastprefix" >> $filename
echo "ff02::1 ip6-allnodes" >> $filename
echo "ff02::2 ip6-allrouters" >> $filename
echo "ff02::3 ip6-allhosts" >> $filename

# DNS.WATCH servers
filename=$TARGET_ROOTFS_DIR/etc/resolv.conf
echo "# DNS.WATCH servers" > $filename
echo "nameserver 84.200.69.80" >> $filename
echo "nameserver 84.200.70.40" >> $filename

# Set default locale
filename=$TARGET_ROOTFS_DIR/etc/default/locale
echo "LANG=en_US.UTF-8" > $filename

display_alert "Setting system info ok" "" "info"

# Set apt repository
filename=$TARGET_ROOTFS_DIR/etc/apt/sources.list
echo "deb http://deb.debian.org/debian stable main contrib non-free" > $filename
echo "deb-src http://deb.debian.org/debian stable main contrib non-free" >> $filename
echo "" >> $filename
echo "deb http://deb.debian.org/debian-security/ stable-security main contrib non-free" >> $filename
echo "deb-src http://deb.debian.org/debian-security/ stable-security main contrib non-free" >> $filename
echo "" >> $filename
echo "deb http://deb.debian.org/debian stable-updates main contrib non-free" >> $filename
echo "deb-src http://deb.debian.org/debian stable-updates main contrib non-free" >> $filename

# Keep the rootfs up-to-date with the repos
# chroot $TARGET_ROOTFS_DIR /bin/bash -c "apt-get update && apt autoremove -y"

# Enable root autologin
filename=$TARGET_ROOTFS_DIR/lib/systemd/system/serial-getty@.service
autologin='--autologin root'
execstart='ExecStart=-\/sbin\/agetty'
if [[ ! $(grep -e "$autologin" $filename) ]]; then
    sed -i "s/$execstart/$execstart $autologin/" $filename
fi

# Enable desktop autologin
#chroot $TARGET_ROOTFS_DIR /bin/bash -c "/autologin.sh"

# Set systemd logging
filename=$TARGET_ROOTFS_DIR/etc/systemd/system.conf
for i in 'LogLevel=warning'\
    'LogTarget=journal'\
    ; do
    sed -i "/${i%=*}/c\\$i" $filename
done

# Enable root to connect to ssh with empty password
filename=$TARGET_ROOTFS_DIR/etc/ssh/sshd_config
if [[ -f $filename ]]; then
    for i in 'PermitRootLogin yes'\
        'PermitEmptyPasswords yes'\
        'UsePAM no'\
        ; do
            sed -ri "/^#?${i% *}/c\\$i" $filename
        done
fi

# Sync overlay files
display_alert "sync files ..." "$ARCH"
sudo cp -arf overlay/* $TARGET_ROOTFS_DIR/

bash -c "VERSION=release ARCH=arm64 ./scripts/copy-local-packages.sh"
chroot $TARGET_ROOTFS_DIR /bin/bash -c "/install-local-packages.sh"

chroot $TARGET_ROOTFS_DIR /bin/bash -c "history -c && history -w"

# Clean apt cache
chroot $TARGET_ROOTFS_DIR /bin/bash -c "apt clean"

# Clean bash history
chroot $TARGET_ROOTFS_DIR /bin/bash -c "history -c && history -w"

# Remove qemu binary from rootfs

display_alert "Building finished" "..." "info"
