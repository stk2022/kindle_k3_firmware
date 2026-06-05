#!/bin/sh

export BMILOADER=${BMILOADER:-"/sbin/bmiloader"}

export DIAG_TOOL_ROOT=${DIAG_TOOL_ROOT:-"/test/diags/factory/tools"}
export WIFI_FREQ=${WIFI_FREQ:-2412}
export WIFI_MODE=${WIFI_MODE:-11G}
export WIFI_BAND=${WIFI_BAND:-US}
export CUR_DIR=`pwd`
export ART_ROOT=${ART_ROOT:-${CUR_DIR}}

# 0: interactive mode
# 1: FCC test
# 2: wifi link test
export WIFI_ART_TEST_TYPE=2
 
export WIFI_ART_LOG_FILE="ArtLogFile.txt"
#  WIFI_ONE_BIT
#   0:  test all bit rates at once and use
#       the WIFI_TX_POWER value
#   1:  test one bit rate specified from the RATE_MASK,
#       from LSB to MSB, using the power for each rate below
export WIFI_ONE_BIT=1

export WIFI_TX_SLEEP_TIME=3000
        
# power when WIFI_ONE_BIT=0
# 
# rate mask
# power when WIFI_ONE_BIT=1

export AP_POWER____6_MBPS=20 
export AP_POWER____9_MBPS=20 
export AP_POWER___12_MBPS=20 
export AP_POWER___18_MBPS=20 
export AP_POWER___24_MBPS=20 
export AP_POWER___36_MBPS=20 
export AP_POWER___48_MBPS=20 
export AP_POWER___54_MBPS=20 
export AP_POWER___1L_MBPS=20 
export AP_POWER___2L_MBPS=20 
export AP_POWER___2S_MBPS=20 
export AP_POWER_5_5L_MBPS=20 
export AP_POWER_5_5S_MBPS=20 
export AP_POWER__11L_MBPS=20 
export AP_POWER__11S_MBPS=20 

export DEV_POWER____6_MBPS=20 
export DEV_POWER____9_MBPS=20 
export DEV_POWER___12_MBPS=20 
export DEV_POWER___18_MBPS=20 
export DEV_POWER___24_MBPS=20 
export DEV_POWER___36_MBPS=20 
export DEV_POWER___48_MBPS=20 
export DEV_POWER___54_MBPS=20 
export DEV_POWER___1L_MBPS=20 
export DEV_POWER___2L_MBPS=20 
export DEV_POWER___2S_MBPS=20 
export DEV_POWER_5_5L_MBPS=20 
export DEV_POWER_5_5S_MBPS=20 
export DEV_POWER__11L_MBPS=20 
export DEV_POWER__11S_MBPS=20 

export RATE_MASK=0x0180

export MAIN_TEST=device_id

export REMOTE_PARAM=192.168.1.25

export NETIF=wlan0
# export WIFI_ART_TEST=1

export CHIP_ALIVE_TIMEOUT=500
export WIFI_PASS_FAIL_RSSI=20
export WIFI_PASS_FAIL_PKT=10
export WIFI_NUM_TX_ITER=5
export WIFI_RX_NUM_LOOP=8
export WIFI_RX_PACKET_THRESHOLD=10

export DEEP_SLEEP=0

exe_art()
{
    echo "WORKAREA= $WORKAREA"
    echo "ATH_PLATFORM=$ATH_PLATFORM"
    echo "EEPROM=$EEPROM"
    echo "WIFI_ART_TEST_TYPE = $WIFI_ART_TEST_TYPE"
    echo "WIFI_ONE_BIT = $WIFI_ONE_BIT"
    echo "art.out \\remote=$REMOTE_PARAM \\id=$ID_PARAM"
    ${ART_ROOT}/art.out \\remote=$REMOTE_PARAM \\id=$ID_PARAM
}

# The ART program can be used in different configurations
# - REMOTE_PARAM:
#     sdio:  running ART though local sdio in Shasta device
#     IP address: run ART to control the AP (Access Point)
# - MAIN_TEST
#     device id   : to read the Atheros chip device id
#     ap_test     : run wifi link test to control the AP using ethenet
#     interactive : run ART in Shasta using default menu manually
#     FCC         : automate the "continuous Tx/Rx" mode for FCC test.  
#     device_test : manufacturing Wifi test on Shasta device
#     device_host : emulate the AP (Access Point) on the host side using 
#                   a second Shasta device.  The manufactoring test needs
#                   both host and device side to test.
#     chip alive  : to test to see if chip is alive.  This test is obsolete
#                   since it will hang if wlan0 is not available.
#     deep_sleep  : put the Wifi chip to deep sleep mode.


usage_print()
{
    echo "usage @0 "
    
    echo " "
    echo "  -r REMOTE_PARAM"
    echo "      sdio         : DUT"
    echo "      192.168.1.25 : Ip of the AP, default is 192.168.1.25"

    echo " "
    echo "  -s MAIN_TEST"
    echo "      device_id    : get the device id"
    echo "      ap_test      : wifi link test  on the AP"
    echo "      interactive  : interactive mode"
    echo "      FCC      : FCC compliance test"
    echo "      device_test  : wifi link test on the device"
    echo "      device_host  : wifi link host emulation on the device"
    echo "                     emulate the host AP side for factory test"
    echo "      device_ap    : device in AP mode"
    echo "      chip_alive   : check if Wifi chip is alive"
    echo "      deep_sleep   : put the Wifi chip into deep sleep mode"
    
    echo " "
    echo "  -b WIFI_ONE_BIT: "
    echo "      0: All bit rates at the same time"
    echo "      1: One bit rate at a time"
    
    echo " "
    echo "  -? Usage "
    return
}

while [ $# -ge 1 ]
do
    case "$1" in
        
        -s) 
            export MAIN_TEST="$2"
            shift 2
            ;;    
            -r) 
            export REMOTE_PARAM="$2"
            shift 2
            ;;
        -b) 
            export WIFI_ONE_BIT="$2"
            shift 2
            ;;
        -\?) 
            export MAIN_TEST="usage"
            shift 1
            ;;
    esac
done                  
 
# echo "MAIN_TEST = $MAIN_TEST"

case "$MAIN_TEST" in
    
    usage)
        usage_print
        ;;

    FCC)
        cd ${ART_ROOT}     
        export WORKAREA=/opt/ar6k
        export ART_WORKAREA=`pwd`
        export KEYBOARD_DRIVER=`/test/diags/factory/tools/getinputentry mxckpd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}
        export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}
        
        # 0: interactive mode                                                                                    
        # 1: FCC test                                                                                            
        # 2: wifi link test                                                                                      
        export WIFI_ART_TEST_TYPE=1          
        # do not change                                                                                          
        export REMOTE_PARAM=sdio                                                                                 
        export ID_PARAM=6041              
        /etc/init.d/wifi stop                     
        cd ${ART_ROOT}
        # if [ ! -f /lib/libdevlib.so ]; then                 
        mntroot rw                                                         
        cp ${ART_ROOT}/libdevlib.so /lib/.            
        sync                                                                   
        # mntroot ro                                
        # fi                                                  
        exe_art
        ;;
    device_id)
        cd ${ART_ROOT}
        export ART_WORKAREA=`pwd`
        # $ART_WORKAREA/host/support/loadART.sh -v | awk '/VERSION/ { print $4 }'
        echo "0x20000188"
        ;;
    chip_alive)                                              
        # check if the wlan0 exists                          
        wlan_list=`iwconfig | grep wlan0`
        if [ -z "$wlan_list" ]; then 
             echo "wlan0 not found, skip checking the Atheros chip using bmiloader"           
             return 0 
        fi
        let time_out=$CHIP_ALIVE_TIMEOUT                    
        ${BMILOADER} -i $NETIF --info &    
        CHIP_ALIVE=0                       
        while [ $time_out -gt 0 ]; do      
            proc_list=`ps ux | grep bmiloader | grep -v grep`
            # echo "proc_list = $proc_list"     
            if [ -z "$proc_list" ]; then      
                 CHIP_ALIVE=1                  
                 echo "SUCCESS"                                                 
                 return 0
            # else                              
                 # echo "time_out = $time_out"   
            fi                                
            let time_out--                           
        done                                                 
        echo "FAIL"                                          
        killall -9  ${BMILOADER}                           
        return 1
        ;;                 
    ap_test)
        export ART_WORKAREA=`pwd`
        export ART_ROOT=`pwd`
        export WORKAREA=`pwd`
        export ATH_PLATFORM=LOCAL_i686-SDIO
        export LD_LIBRARY_PATH=.:${LD_LIBRARY_PATH}

        # 0: AP test
        # 1: ARM (shasta) test
        # 2: wifi link test                                                            
        export WIFI_ART_TEST_TYPE=2 
    
        # 0: AP test
        # 1: ARM (shasta) test
        export WIFI_ART_DEVICE_TEST=0
        
        export WIFI_USE_TARGET_POWER=0

        export WIFI_TX_DELAY_ITER=4000

        # for AP side only
        export WIFI_TX_POWER=20

        export WIFI_AP_TIME_OUT=8000
        export WIFI_ARM_TIME_OUT=4000   
        export WIFI_AP_WAIT_TIME=15000    
        export WIFI_ARM_WAIT_TIME=15000  
        
        # do not change
        export ID_PARAM=a034
        exe_art
        ;;
    interactive)
        cd ${ART_ROOT}                             
        export WORKAREA=/opt/ar6k                  
        export ART_WORKAREA=`pwd`
        export KEYBOARD_DRIVER=`/test/diags/factory/tools/getinputentry mxckpd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}             
        export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}

        export RATE_MASK=0x4181
        export WIFI_ART_TEST=0

        export VERBOSE_LEVEL=0
        # 0: AP test
        # 1: ARM (shasta) test
        # 2: wifi link test                                                            
        export WIFI_ART_TEST_TYPE=0
    
        # 0: AP test
        # 1: ARM (shasta) test
        export WIFI_ART_DEVICE_TEST=0
        
        export WIFI_USE_TARGET_POWER=0

        export WIFI_TX_DELAY_ITER=1000

        # for AP side only
        export WIFI_TX_POWER=20

        export WIFI_AP_TIME_OUT=8000
        export WIFI_ARM_TIME_OUT=16000   
        export WIFI_AP_WAIT_TIME=5000    
        export WIFI_ARM_WAIT_TIME=10000  
        
        # do not change
        export REMOTE_PARAM=sdio
        export ID_PARAM=6041
        /etc/init.d/wifi stop
        cd ${ART_ROOT}
        mntroot rw
        cp ${ART_ROOT}/libdevlib.so /lib/.
        sync
        exe_art
        ;;
        
    device_ap)
        cd ${ART_ROOT}
        export WORKAREA=/opt/ar6k
        export ART_WORKAREA=`pwd`
        export KEYBOARD_DRIVER=`/test/diags/factory/tools/getinputentry mxckpd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}
        export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}

        # 0: AP test
        # 1: ARM (shasta) test
        # 2: wifi link test
        export WIFI_ART_TEST_TYPE=0

        # 0: AP test
        # 1: ARM (shasta) test
        export WIFI_ART_DEVICE_TEST=0

        export WIFI_USE_TARGET_POWER=0

        export WIFI_TX_DELAY_ITER=1000

        # for AP side only
        export WIFI_TX_POWER=20

        export WIFI_AP_TIME_OUT=8000
        export WIFI_ARM_TIME_OUT=4000
        export WIFI_AP_WAIT_TIME=15000
        export WIFI_ARM_WAIT_TIME=10000

        # do not change
        export ID_PARAM=a034
        export REMOTE_PARAM=sdio
        export ID_PARAM=6041
        /etc/init.d/wifi stop
        cd ${ART_ROOT}                                                                                          
        mntroot rw
        cp ${ART_ROOT}/libdevlib.so /lib/.                                                                      
        sync
        exe_art
        ;;
    
    device_host)
        # use to emulate Shasta to Shasta factory test
        # this option emulate the AP GUI host side
        cd ${ART_ROOT}
        export WORKAREA=/opt/ar6k
        export ART_WORKAREA=`pwd`
        export KEYBOARD_DRIVER=`/test/diags/factory/tools/getinputentry mxckpd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}
        export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}

        export WIFI_ART_LOG_FILE="/mnt/us/ArtLogFile.txt"

        # 0: interactive mode                                                          
        # 1: FCC test                                                                  
        # 2: wifi link test                                                            
        export WIFI_ART_TEST_TYPE=2     
    
        # do not change
        # 0: AP test
        # 1: ARM (shasta) test
        # 2: ARM (shasta) host emulation
        export WIFI_ART_DEVICE_TEST=2
        
        export WIFI_USE_TARGET_POWER=0
        
        # export WIFI_TX_POWER=20

        export WIFI_AP_TIME_OUT=10000
        export WIFI_ARM_TIME_OUT=10000
        export WIFI_AP_WAIT_TIME=10000
        export WIFI_ARM_WAIT_TIME=10000
        export WIFI_TX_DELAY_ITER=1000
        
        # do not change
        export REMOTE_PARAM=sdio
        export ID_PARAM=6041
        /etc/init.d/wifi stop
        cd ${ART_ROOT}                                                                                           
        mntroot rw
        cp ${ART_ROOT}/libdevlib.so /lib/.                                                                       
        sync
        exe_art
        ;;    
        
    deep_sleep)
        # use to emulate Shasta to Shasta factory test
        # this option emulate the AP GUI host side
        cd ${ART_ROOT}
        export WORKAREA=/opt/ar6k
        export ART_WORKAREA=`pwd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}

        /etc/init.d/wifi stop
        ${ART_ROOT}/host/support/loadAR6000.sh --deep_sleep
        ;;    

    *)    
        cd ${ART_ROOT}
        export WORKAREA=/opt/ar6k
        export ART_WORKAREA=`pwd`
        export KEYBOARD_DRIVER=`/test/diags/factory/tools/getinputentry mxckpd`
        export ATH_PLATFORM=${ATH_PLATFORM:-SHASTA_NATIVEMMC-SDIO}
        export EEPROM=${EEPROM:-$ART_WORKAREA/lab126_15dBm_nodiv_WWR_CTL.bin}

        export WIFI_ART_LOG_FILE="/mnt/us/ArtLogFile.txt"

        # 0: interactive mode                                                          
        # 1: FCC test                                                                  
        # 2: wifi link test                                                            
        export WIFI_ART_TEST_TYPE=2     
    
        # do not change
        # 0: AP test
        # 1: ARM (shasta) test
        export WIFI_ART_DEVICE_TEST=1
        
        export WIFI_USE_TARGET_POWER=0
        
        # export WIFI_TX_POWER=20

        export WIFI_AP_TIME_OUT=10000
        export WIFI_ARM_TIME_OUT=10000
        export WIFI_AP_WAIT_TIME=10000
        export WIFI_ARM_WAIT_TIME=10000
        export WIFI_TX_DELAY_ITER=1000
        
        # do not change
        export REMOTE_PARAM=sdio
        export ID_PARAM=6041
        /etc/init.d/wifi stop
        cd ${ART_ROOT}                                                                                           
# if [ ! -f /lib/libdevlib.so ]; then
        mntroot rw
        cp ${ART_ROOT}/libdevlib.so /lib/.                                                                       
        sync
        # mntroot ro
# fi
        exe_art
        ;;
esac


