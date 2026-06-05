#!/bin/sh
# Load ART target image into RAM.
Help() {
	echo "Usage: $0 [options]"
	echo
	echo "With NO options, loads ART target image into RAM"
	echo
	echo "To unload, use $WORKAREA/host/support/loadAR6000.sh unloadall"
	exit 0
}

export ART_WORKAREA=${ART_WORKAREA:-/test/diags/factory/tests/wifi/art/art/bin}
 
export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}
export IMAGEPATH=${IMAGEPATH:-$ART_WORKAREA/host/.output/$ATH_PLATFORM/image}
export TARGET_BIN_1_0_PATH=${TARGET_BIN_1_0_PATH:-$ART_WORKAREA/target/ar6002/hw1.0/bin}
export TARGET_BIN_2_0_PATH=${TARGET_BIN_2_0_PATH:-$ART_WORKAREA/target/ar6002/hw2.0/bin}
export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}

echo "ATH_PLATFORM=$ATH_PLATFORM"
echo "IMAGEPATH=$IMAGEPATH"

# export IMAGEPATH=/sbin
export NETIF=${NETIF:-wlan0}
# export EEPROM=${EEPROM:-$WORKAREA/host/support/fakeBoardData_AR6002.bin}
XTALFREQ=${XTALFREQ:-26000000}

echo "loadART.sh: NETIF= $NETIF, EEPROM= $EEPROM"

LOADAR6000=${LOADAR6000:-$ART_WORKAREA/host/support/loadAR6000.sh}
if [ ! -x "$LOADAR6000" ]; then
	echo "Loader application '$LOADAR6000' not found"
	exit
fi
echo "loadART.sh: LOADAR6000 = $LOADAR6000"

# BMILOADER=${BMILOADER:-$ART_WORKAREA/host/.output/$ATH_PLATFORM/image/bmiloader}
# export BMILOADER=${BMILOADER:-$IMAGEPATH/bmiloader}
export BMILOADER=${BMILOADER:-/sbin/bmiloader}
if [ ! -x "$BMILOADER" ]; 
then
	echo "Loader application '$BMILOADER' not found"
	exit
fi

echo "BMILOADER=$BMILOADER"

echo "Loading BMI only"
$LOADAR6000 hostonly
echo "Target type $TARGET_TYPE, $LOADAR6000 hostonly done"
if [ "$TARGET_TYPE" = "" ]
then
    # Determine TARGET_TYPE
    echo "Determine TARGET_TYPE $NETIF"
    # eval export `$BMILOADER -i $NETIF --quiet --info | grep TARGET_TYPE`
    eval export `$BMILOADER -i $NETIF --quiet --info | grep TARGET_TYPE`
fi
echo TARGET TYPE is $TARGET_TYPE

if [ "$TARGET_VERSION" = "" ]
then
    # Determine TARGET_VERSION
    eval export `$BMILOADER -i $NETIF --quiet --info | grep TARGET_VERSION`
fi
AR6002_VERSION_REV2=0x20000188
echo TARGET VERSION is $TARGET_VERSION

if [ "$TARGET_TYPE" = "AR6002" ]
then
    if [ "$TARGET_VERSION" = "$AR6002_VERSION_REV2" ]
    then
        echo "export wlanapp=$ART_WORKAREA/target/AR6002/hw2.0/bin/device.bin"
        export wlanapp=$ART_WORKAREA/target/AR6002/hw2.0/bin/device.bin
    fi
fi

while [ "$#" -ne 0 ]
do
        case $1 in
	-h|--help )
		Help
		;;
        -v)
        	echo $TARGET_VERSION
        	exit 0
		;;
       * )
      	echo "Unsupported argument"
            Help
		exit -1
		shift
	esac
done

echo "Loading ART target"
#$LOADAR6000 targonly enableuartprint noresetok nostart bypasswmi 
$LOADAR6000 targonly noresetok nostart bypasswmi 

#voltage scaling control
$BMILOADER -i $NETIF --set --address=0x4110 --param=0xa1d

echo "Setting XTALFREQ"
$BMILOADER -i $NETIF --write --address=0x500478 --param=$XTALFREQ
# TBD: set hi_board_data_initialized to avoid loading eeprom.
$BMILOADER -i $NETIF --write --address=0x500458 --param=0x1

sleep 1

