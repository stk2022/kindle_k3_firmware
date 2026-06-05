#!/bin/sh

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

mntroot_rw
cp /test/misc/bootchartd /sbin/.
cp /test/misc/bootchartd.conf /etc/.
mntroot_ro

echo "Rebooting in 5 seconds"
echo "Make sure your bootargs line contains:"
echo " init=/sbin/bootchartd"
echo "Once the system has fully rebooted, login, invoke "
echo " bootchartd stop;usbnetwork;"
echo "On your host invoke:"
echo " cd trunk/mario/image/tools;"
echo " sudo ifconfig usb0 192.168.15.200 netmask 255.255.255.0;"
echo " scp root@192.168.15.244:/var/log/boot* .;"
echo " java -jar bootchart.jar -n bootchart.tgz ;"
echo " firefox bootchart.png"
sleep 5
reboot

