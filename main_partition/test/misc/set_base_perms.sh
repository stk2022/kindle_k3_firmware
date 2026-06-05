#!/bin/sh

DEBUG="echo"

ROOTDIR=$1
VERBOSE=0
[ "x$VERBOSE" = "x1" ] && CHV="-v"

CHMOD="chmod $CHV"
CHOWN="chown $CHV"

CURRENT_USER=""
CURRENT_GROUP=""
CURRENT_PERM=""
CURRENT_MODE=""

################################################################################
## Default stuff
################################################################################
OTHERS_DEFAULTS="-R o-rwx"

OTHERS_PLUSr="/proc /dev /sys /bin /usr/bin /var /tmp /etc"
OTHERS_PLUSw="/dev/fb /dev/fb0 /var /tmp"
OTHERS_PLUSx="/var /tmp /bin /usr/bin"

OTHERS_MINUSr="/etc/fstab \
                /etc/monitrc \
                /etc/init.d \
                /etc/rcS.d \
                /etc/rc0.d \
                /etc/rc1.d \
                /etc/rc2.d \
                /etc/rc3.d \
                /etc/rc4.d \
                /etc/rc5.d \
                /etc/rc6.d \
                "
OTHERS_MINUSw="$OTHERS_MINUS_r"
OTHERS_MINUSx="$OTHERS_MINUS_w"

################################################################################
## User specific stuff
################################################################################
OUSERS="framework"
OWNUSER_framework="/tmp/framework"

################################################################################
## Group specific stuff
################################################################################
OGROUP="javausers"
OWNGROUP_javausers="/tmp/framework"



chmod_stuff()
{
	$DEBUG "In chmod_stuff $CURRENT_PERM" 
    { [ "x$CURRENT_MODE" = "x+" ] && TABMODE="PLUS"; } || TABMODE="MINUS";
	eval CURRENTTAB=\${OTHERS_$TABMODE$CURRENT_PERM}
    $DEBUG $CURRENTTAB
	for ITEM in $CURRENTTAB; do
		if [ -d $ROOTDIR$ITEM ]; then
			find $ROOTDIR$ITEM | xargs $CHMOD o$CURRENT_MODE$CURRENT_PERM
		elif [ -e $ROOTDIR$ITEM ]; then 
			$CHMOD o$CURRENT_MODE$CURRENT_PERM $ROOTDIR$ITEM
		else
			echo "File $ROOTDIR$ITEM not found. Not setting perms to o$CURRENT_MODE$CURRENT_PERM" 
		fi		
	done
}

chown_user()
{
	$DEBUG "In chown_user $CURRENT_USER" 
	eval CURRENTUSER=\${OWNUSER_$CURRENT_USER}
    $DEBUG $CURRENTUSER
	for ITEM in $CURRENTUSER; do
		if [ -d $ROOTDIR$ITEM ]; then
			find $ROOTDIR$ITEM  | xargs $CHOWN -h $CURRENT_USER
		elif [ -e $ROOTDIR$ITEM ]; then 
			$CHOWN - $CURRENT_USER $ROOTDIR$ITEM
		else
			echo "File $ROOTDIR$ITEM not found. No setting ownship to $CURRENT_USER" 
		fi		
	done
}

chown_group()
{
	$DEBUG "In chown_group $CURRENT_GROUP" 
	eval CURRENTGROUP=\${OWNGROUP_$CURRENT_GROUP}
    $DEBUG $CURRENTGROUP
	for ITEM in $CURRENTGROUP; do
		if [ -d $ROOTDIR$ITEM ]; then
			find $ROOTDIR$ITEM | xargs $CHOWN -h :$CURRENT_GROUP
		elif [ -e $ROOTDIR$ITEM ]; then
			$CHOWN -h :$CURRENT_GROUP $ROOTDIR$ITEM
		else
			echo "File $ROOTDIR$ITEM not found. No setting ownship to $CURRENT_GROUP" 
		fi
	done
}

$CHMOD $OTHERS_DEFAULTS /
CURRENT_GROUP="javausers" && chown_group
CURRENT_USER="framework" && chown_user 
CURRENT_PERM="r" && CURRENT_MODE="+" && chmod_stuff
CURRENT_PERM="w" && CURRENT_MODE="+" && chmod_stuff
CURRENT_PERM="x" && CURRENT_MODE="+" && chmod_stuff
CURRENT_PERM="r" && CURRENT_MODE="-" && chmod_stuff
CURRENT_PERM="w" && CURRENT_MODE="-" && chmod_stuff
CURRENT_PERM="x" && CURRENT_MODE="-" && chmod_stuff


