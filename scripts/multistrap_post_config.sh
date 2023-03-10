#!/bin/sh
#
# This script will configure the partially built debian system.
# It is expected to be run as root, in a chroot, using the target
# architecture, after multistrap has been run

# Mount proc, if needed
if [ ! -e /proc/uptime ]; then
    mount proc -t proc /proc
    PROC_NEEDS_UMOUNT=1
fi

/var/lib/dpkg/info/dash.preinst install

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C

echo "**************************PKG CONFIG**********************"
dpkg --configure -a
echo "*********************PKG CONFIG TWICE*********************"
dpkg --configure -a
echo "*********************END OF PKG CONFIG********************"

# NOTE
# - the dpkg --configure starts up all the services..  Which can be fixed
# by installing a /usr/sbin/policy-rc.d during the installation process
# (Not done in this example)

if [ "$PROC_NEEDS_UMOUNT" = 1 ]; then
    umount /proc
fi

exit 0

