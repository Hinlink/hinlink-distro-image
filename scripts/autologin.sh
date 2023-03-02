#!/bin/bash

username=rock

# 修改lightdm配置文件
sed -i "s/#autologin-user=/autologin-user=$username/g" /etc/lightdm/lightdm.conf

systemctl restart lightdm.service
