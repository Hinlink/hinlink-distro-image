#!/bin/bash

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#chmod +x /etc/rc.local

APT_INSTALL="DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -o Dpkg::Options::=\"--force-overwrite\" install -fy --allow-downgrades"

apt update

#---------------power management --------------
/bin/bash -c "$APT_INSTALL bsdmainutils"

#---------------Rga--------------
/bin/bash -c "$APT_INSTALL /packages/rga2/*.deb"

echo -e "\033[36m Setup Video.................... \033[0m"
/bin/bash -c "$APT_INSTALL gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-alsa \
gstreamer1.0-plugins-base-apps qtmultimedia5-examples"

/bin/bash -c "$APT_INSTALL /packages/mpp/*"
/bin/bash -c "$APT_INSTALL /packages/gst-rkmpp/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gstreamer/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gst-plugins-base1.0/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gst-plugins-bad1.0/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gst-plugins-good1.0/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gst-plugins-ugly1.0/*.deb"
/bin/bash -c "$APT_INSTALL /packages/gst-libav1.0/*.deb"

#---------Camera---------
echo -e "\033[36m Install camera.................... \033[0m"
/bin/bash -c "$APT_INSTALL cheese v4l-utils"
/bin/bash -c "$APT_INSTALL /packages/libv4l/*.deb"

#---------Xserver---------
echo -e "\033[36m Install Xserver.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/xserver/*.deb"

apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy

#---------------Openbox--------------
echo -e "\033[36m Install openbox.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/openbox/*.deb"

#---------update chromium-----
/bin/bash -c "$APT_INSTALL /packages/chromium/*.deb"

#------------------libdrm------------
echo -e "\033[36m Install libdrm.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/libdrm/*.deb"

#------------------libdrm-cursor------------
echo -e "\033[36m Install libdrm-cursor.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/libdrm-cursor/*.deb"

#------------------blueman------------
echo -e "\033[36m Install blueman.................... \033[0m"
/bin/bash -c "$APT_INSTALL blueman"
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
/bin/bash -c "$APT_INSTALL blueman"
rm -f /usr/sbin/policy-rc.d

#------------------blueman------------
echo -e "\033[36m Install blueman.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/blueman/*.deb"

#------------------rkwifibt------------
echo -e "\033[36m Install rkwifibt.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/rkwifibt/*.deb"
ln -s /system/etc/firmware /vendor/etc/

#------------------glmark2------------
echo -e "\033[36m Install glmark2.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/glmark2/*.deb"

if [ -e "/usr/lib/aarch64-linux-gnu" ] ;
then
#------------------rknpu2------------
echo -e "\033[36m move rknpu2.................... \033[0m"
mv /packages/rknpu2/*.tar  /
fi

#------------------rktoolkit------------
echo -e "\033[36m Install rktoolkit.................... \033[0m"
/bin/bash -c "$APT_INSTALL /packages/rktoolkit/*.deb"

echo -e "\033[36m Install Chinese fonts.................... \033[0m"
# Uncomment en_US.UTF-8 for inclusion in generation
sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/default/locale

# Generate locale
locale-gen

# Export env vars
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

source ~/.bashrc

/bin/bash -c "$APT_INSTALL ttf-wqy-zenhei fonts-aenigma"

# HACK debian11.3 to fix bug
/bin/bash -c "$APT_INSTALL fontconfig --reinstall"

cp /packages/libmali/libmali-*-x11*.deb /
cp -rf /packages/rkisp/*.deb /
cp -rf /packages/rkaiq/*.deb /
cp -rf /usr/lib/firmware/rockchip/ /

# mark package to hold
apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------Clean--------------
if [ -e "/usr/lib/arm-linux-gnueabihf/dri" ] ;
then
        # Only preload libdrm-cursor for X
        sed -i "1aexport LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libdrm-cursor.so.1" /usr/bin/X
        cd /usr/lib/arm-linux-gnueabihf/dri/
        cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
        rm /usr/lib/arm-linux-gnueabihf/dri/*.so
        mv /*.so /usr/lib/arm-linux-gnueabihf/dri/
elif [ -e "/usr/lib/aarch64-linux-gnu/dri" ];
then
        # Only preload libdrm-cursor for X
        sed -i "1aexport LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libdrm-cursor.so.1" /usr/bin/X
        cd /usr/lib/aarch64-linux-gnu/dri/
        cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
        rm /usr/lib/aarch64-linux-gnu/dri/*.so
        mv /*.so /usr/lib/aarch64-linux-gnu/dri/
        rm /etc/profile.d/qt.sh
fi

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/

echo -e "\033[36m Install local packages finished... \033[0m"
