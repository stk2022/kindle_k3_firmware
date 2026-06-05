#!/bin/sh
####################################################################################
#
#  File:   cert_tests.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   02/02/10
#
#  Copyright (C) 2005-2010 Amazon Technologies
#
#  Description:
#      Contains various run modes used for certification testing purposes
#
#   Routines
#       cert_display_menu()             - Display the certification tests menu
#       cert_do_run_diag()              - Handles the main certification test menu
#
####################################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Load certification test hal
[ -f ${_CERT_HAL_FUNCTIONS} ] && . ${_CERT_HAL_FUNCTIONS}

# Keyboard mappings 
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Button mappings 
[ -f ${_BUTTON_HAL_FUNCTIONS} ] && . ${_BUTTON_HAL_FUNCTIONS}

# Gas Gauge functions (for BATTERY_CAPACITY)
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

# Audio functions 
[ -f ${_AUDIO_HAL_FUNCTIONS} ] && . ${_AUDIO_HAL_FUNCTIONS}

# Fiveway Hal Function...
[ -f ${_FIVEWAY_HAL_FUNCTIONS} ] && . ${_FIVEWAY_HAL_FUNCTIONS}

# Video Hal Function...
[ -f ${_VIDEO_HAL_FUNCTIONS} ] && . ${_VIDEO_HAL_FUNCTIONS}

# USB Hal Function...
[ -f ${_USB_HAL_FUNCTIONS} ] && . ${_USB_HAL_FUNCTIONS}

# LED Hal Function...
[ -f ${_LED_HAL_FUNCTIONS} ] && . ${_LED_HAL_FUNCTIONS}

# Power Hal Function...
[ -f ${_POWER_HAL_FUNCTIONS} ] && . ${_POWER_HAL_FUNCTIONS}

# WAN Hal Function...
[ -f ${_WAN_HAL_FUNCTIONS} ] && . ${_WAN_HAL_FUNCTIONS}

# MoviNand Hal Function...
[ -f ${_MOVINAND_HAL_FUNCTIONS} ] && . ${_MOVINAND_HAL_FUNCTIONS}

# WIFI Hal Function...
[ -f ${_WIFI_HAL_FUNCTIONS} ] && . ${_WIFI_HAL_FUNCTIONS}
              
#
# Assign menu keys
#
RM_WAN_ENABLED_TEST_KEY=500
RM_EINK_FLIP_PAGE_TEST_KEY=501
RM_EINK_WAN_TEST_KEY=502
RM_USB_WAN_TEST_KEY=503
RM_EINK_USB_TEST_KEY=504
RM_AUDIO_SPEAKER_WAN_TEST_KEY=505
RM_AUDIO_HP_WAN_TEST_KEY=506
RM_EINK_TEST_KEY=507
RM_TTS_TEST_KEY=508
RM_WIFI_FCC_KEY=509

if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
    RM_WAN_ENABLED_TEST_KEY=$MENU_ITEM_1
fi

if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 0 ] && [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_FLIP_PAGE_TEST_KEY=$MENU_ITEM_2
fi
  
if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ] && [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_WAN_TEST_KEY=$MENU_ITEM_3
fi
    
if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
    RM_USB_WAN_TEST_KEY=$MENU_ITEM_4
fi

if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
    RM_EINK_USB_TEST_KEY=$MENU_ITEM_5
fi

if [ -n "$HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
    RM_AUDIO_SPEAKER_WAN_TEST_KEY=$MENU_ITEM_6
    RM_AUDIO_HP_WAN_TEST_KEY=$MENU_ITEM_7
fi

if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_TEST_KEY=$MENU_ITEM_8
fi

if [ -n "$HAS_TTS" ] && [ $HAS_TTS -eq 1 ]; then
    RM_TTS_TEST_KEY=$MENU_ITEM_9
fi

if [ "x$HAS_WIFI" == "x1" ]; then
    RM_WIFI_FCC_KEY=$MENU_ITEM_10
fi


######################################################################
# Function:     cert_display_menu
# Purpose:      Display the certification test's menu screen
# Paramters:    none
# Returns:      none
######################################################################
cert_display_menu()
{
    clear_screen
    print_center_text "$PRODUCT_NAME Certification Test Modes" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 5 4
    line=7

    if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $RM_WAN_ENABLED_TEST_KEY`
        ${DOUT} -n 8 $line "$text) WAN enabled"
        let line+=2

        if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
            text=`keycode_to_label $RM_EINK_WAN_TEST_KEY`
            ${DOUT} -n 8 $line "$text) EINK with WAN enabled"
            let line+=2
        fi
        if [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
            text=`keycode_to_label $RM_USB_WAN_TEST_KEY`
            ${DOUT} -n 8 $line "$text) USB with WAN enabled"
            let line+=2
        fi
    else 
        # WFO does not have WAN so just run eInk flip page test
        if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
            text=`keycode_to_label $RM_EINK_FLIP_PAGE_TEST_KEY`
            ${DOUT} -n 8 $line "$text) EINK flip page test"
            let line+=2
        fi
    fi

    if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
        text=`keycode_to_label $RM_EINK_USB_TEST_KEY`
        ${DOUT} -n 8 $line "$text) EINK with USB Volume Exported"
        let line+=2
    fi

    if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $RM_AUDIO_SPEAKER_WAN_TEST_KEY`
        ${DOUT} -n 8 $line "$text) Speakers with WAN enabled"
        let line+=2
        text=`keycode_to_label $RM_AUDIO_HP_WAN_TEST_KEY`
        ${DOUT} -n 8 $line "$text) Audio Jack with WAN enabled"
        let line+=2
    fi

    if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ] && [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ]; then
        text=`keycode_to_label $RM_EINK_TEST_KEY`
        ${DOUT} -n 8 $line "$text) EINK Flipper with Speaker Audio"
        let line+=2
    fi

    if [ -n "$HAS_TTS" ] && [ $HAS_TTS -eq 1 ]; then
        text=`keycode_to_label $RM_TTS_TEST_KEY`
        ${DOUT} -n 8 $line "$text) Text-To-Speech"
        let line+=2
    fi

    if [ "x$HAS_WIFI" == "x1" ]; then
        text=`keycode_to_label $RM_WIFI_FCC_KEY`
        ${DOUT} -n 8 $line "$text) Wifi FCC Compliance Test"
        let line+=2
    fi

    let line+=2
    ${DOUT} 8 $line "$EXIT_KEY_LABEL) Exit $PRODUCT_NAME Certification Tests"
}



######################################################################
# Function:     cert_do_run_diag
# Purpose:      Run the main run modes diagnostic, displaying a menu
#               and allowing operator to choose test.
# Paramters:    none
# Returns:      none
######################################################################
cert_do_run_diag()
{
    #
    # Get the requested test from user
    #
    DO_RUN_DIAG_REDRAW=1
    RM_DONE=0
    while [ $RM_DONE -ne 1 ]; do
        if [ $DO_RUN_DIAG_REDRAW -eq 1 ]; then
            # Display the test choices...
            cert_display_menu
        else
            DO_RUN_DIAG_REDRAW=1
        fi

        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
            $RM_WAN_ENABLED_TEST_KEY)
                do_run_mode_wan_enabled
                ;;
            $RM_EINK_WAN_TEST_KEY)
                do_run_mode_eink_wan
                ;;
            $RM_USB_WAN_TEST_KEY)
                do_run_mode_usb_wan
                ;;
            $RM_AUDIO_SPEAKER_WAN_TEST_KEY)
                do_run_mode_speaker_wan
                ;;
            $RM_AUDIO_HP_WAN_TEST_KEY)
                do_run_mode_hp_wan
                ;;
            $RM_EINK_USB_TEST_KEY)
                do_run_mode_eink_usb
                ;;
            $RM_EINK_FLIP_PAGE_TEST_KEY)
                do_run_mode_eink_flip_page
                ;;
            $RM_EINK_TEST_KEY)
                do_run_mode_eink
                ;;
            $RM_TTS_TEST_KEY)
                do_run_tts_test
                ;;
            $RM_WIFI_FCC_KEY)
                do_wifi_menu
                ;;
            $EXIT_KEY)
                RM_DONE=1
                ;;
            *)
                vmsg "Wrong key "$KEY" pressed.."
                DO_RUN_DIAG_REDRAW=0;
                ;;
            esac
        fi
    done
}


case "$1" in

    stop)
        vmsg "Exiting Certification Tests"
        ;;

    start|*)
        vmsg "Starting Certification Tests"
        enter_diag "Certification"
        # Clear any previous diagnostic test results
        clear_diag_fail
        cert_hal_init
        cert_do_run_diag
        cert_hal_exit
        exit_diag "Certification" 0
        ;;

esac
