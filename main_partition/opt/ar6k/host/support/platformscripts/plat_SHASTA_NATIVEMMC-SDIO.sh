#!/bin/sh
#
# Linux Native MMC-SDIO stack platform setup script
#
#

case $1 in
	loadbus)
	# MMC stack is part of kernel so nothing to here
	;;
	
	unloadbus)
	# nothing to do for native MMC stack
	;;
	
	loadAR6K)
	recEvent $AR6K_TGT_LOGFILE /dev/null 2>&1 &
	modprobe $AR6K_MODULE_NAME $AR6K_MODULE_ARGS
	if [ $? -ne 0 ]; then
		echo "*** Failed to install AR6K Module"
		exit -1
	fi
	;;
	
	unloadAR6K)
	/sbin/rmmod -w $AR6K_MODULE_NAME.ko
 	killall recEvent
	;;
	*)
		echo "Unknown option : $1"
	
esac
