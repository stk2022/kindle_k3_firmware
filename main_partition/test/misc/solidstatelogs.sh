#!/bin/sh

mkdir -p /tmp/logtmp
mkdir -p /var/local/tmplog
killall -SIGHUP syslog-ng
cp -ar /var/log/* /tmp/logtmp/.
rm -rf /var/log
ln -sf /var/local/tmplog /var/log
mv -f /tmp/logtmp/* /var/log/.

