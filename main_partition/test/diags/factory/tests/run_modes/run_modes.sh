#!/bin/sh
####################################################################################
#
#  File:   run_modes_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright (C) 2005-2010 Amazon Technologies
#
#  Description:
#      Contains the run modes diagnostics, which includes various
#       run modes and the run-in test.
#
#   Routines
#       rm_display_menu()               - Display the run modes menu
#       runin_display_result_dialog()   - Display run-in results screen
#       format_time()                   - Format time into readable string
#       display_run_in_cancel_test_message() - Display canel run-in test screen
#       set_run_in_menu_items()         - Create menu of active run-in components
#       set_run_in_default_options()    - Enable run-in componets based on defaults
#       adjust_run_in_options()         - Allow user to change which components get
#                                           tested in the run-in test.
#       runin_do_check_timeout()        - Check to see if run-in test is done
#       do_run_in_mode()                - Run the run-in test
#       rm_do_run_diag()                - Run the run modes diagnostic
#       exit_run_in_hals()              - Call hal exit routines for all init'ed hals
#       init_run_in_hals()              - Call hal init routines for run-in components
#
####################################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Run Modes HAL Functions
[ -f ${_RUN_MODES_HAL_FUNCTIONS} ] && . ${_RUN_MODES_HAL_FUNCTIONS}

# Keyboard mappings 
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Device Settings HAL for get functions for pcb id and MAC address
if [ -n "$HAS_MAC_ADDRESS" ] && [ $HAS_MAC_ADDRESS -eq 1 ]; then
    [ -f ${_DEV_SETTINGS_HAL_FUNCTIONS} ] && . ${_DEV_SETTINGS_HAL_FUNCTIONS}
fi
    
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
# mSeconds to leave the "Stop Run-in Test" dialog for user to
#  stop the run-in test...
#
export RUN_IN_DISPLAY_CANCEL_TIMEOUT=5000

#
# After run-in test is over and confirmation page is being displayed,
#  keep adjusting battery charger every END_RUN_IN_CHARGE_PERIOD mSeconds
#
export END_RUN_IN_CHARGE_PERIOD=180000

#
# Switch to enable/disable auto-verification of charger
#
export RUN_IN_CHARGER_CHECK_ENABLE_DEFAULT="ENABLED";

#
# Check to see if audio is supported in this world
#
if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ]; then
    verify_audio_system_support
    export _DONT_INCLUDE_AUDIO_TESTS=$?
else
    export _DONT_INCLUDE_AUDIO_TESTS=1
fi

# Define menu selection keys
RM_RUN_IN_TEST_KEY=$MENU_ITEM_1

if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
    RM_WAN_ENABLED_TEST_KEY=$MENU_ITEM_2
    RM_511_TEST_KEY=$MENU_ITEM_8
    RM_WAN_MOLB_TEST_KEY=$MENU_ITEM_9
    RM_WAN_GSM1900_TEST_KEY=$MENU_ITEM_10
else
    RM_WAN_ENABLED_TEST_KEY=500
    RM_511_TEST_KEY=$MENU_ITEM_8
    RM_WAN_MOLB_TEST_KEY=502
    RM_WAN_GSM1900_TEST_KEY=503
fi


if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 0 ] && [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_FLIP_PAGE_TEST_KEY=$MENU_ITEM_3
else
    RM_EINK_FLIP_PAGE_TEST_KEY=504
fi
  
if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ] && [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_WAN_TEST_KEY=$MENU_ITEM_3
else
    RM_EINK_WAN_TEST_KEY=513
fi
    
if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
    RM_USB_WAN_TEST_KEY=$MENU_ITEM_4
else
    RM_USB_WAN_TEST_KEY=505
fi

if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
    RM_EINK_USB_TEST_KEY=$MENU_ITEM_5
else
    RM_EINK_USB_TEST_KEY=506
fi

if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ] && [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
    RM_AUDIO_SPEAKER_WAN_TEST_KEY=$MENU_ITEM_6
    RM_AUDIO_HP_WAN_TEST_KEY=$MENU_ITEM_7
else
    RM_AUDIO_SPEAKER_WAN_TEST_KEY=507
    RM_AUDIO_HP_WAN_TEST_KEY=508
fi

if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
    RM_EINK_TEST_KEY=$MENU_ITEM_11
    RM_EINK_EYE_ONE_TEST_KEY=$MENU_ITEM_12
else
    RM_EINK_TEST_KEY=509
    RM_EINK_EYE_ONE_TEST_KEY=510
fi

if [ -n "HAS_TTS" ] && [ $HAS_TTS -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
    RM_TTS_TEST_KEY=$MENU_ITEM_13
else
    RM_TTS_TEST_KEY=511
fi

if [ -n "HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
    RM_WIFI_FCC_COMPLIANCE_TEST_KEY=$MENU_ITEM_14
else
    RM_WIFI_FCC_COMPLIANCE_TEST_KEY=512
fi


# Constants used when executing sub-tests via do_run_in_subtest() calls
RUNIN_VIDEO_DIAG_ID=0
RUNIN_WAN_DIAG_ID=1
RUNIN_MOVINAND_DIAG_ID=2
RUNIN_LED_DIAG_ID=3
RUNIN_BUTTON_DIAG_ID=4
RUNIN_FIVEWAY_DIAG_ID=5
RUNIN_HAPTIC_DIAG_ID=6
RUNIN_KEYBOARD_DIAG_ID=7
RUNIN_USB_DEVICE_DIAG_ID=8
RUNIN_GAS_GAUGE_DIAG_ID=9
RUNIN_POWER_DIAG_ID=10
RUNIN_AUDIO_DIAG_ID=11
RUNIN_ACCELEROMETER_DIAG_ID=12
RUNIN_WIFI_DIAG_ID=13


#
# Define some run-in test variables
#
export RUN_IN_USB_ENABLED;
export RUN_IN_WAN_ENABLED;
export RUN_IN_WIFI_ENABLED;
export RUN_IN_VIDEO_ENABLED;
export RUN_IN_LED_ENABLED;
export RUN_IN_HAPTIC_ENABLED;
export RUN_IN_AUDIO_ENABLED;
export RUN_IN_POWER_ENABLED;
export RUN_IN_GAS_GAUGE_ENABLED;
export RUN_IN_MOVINAND_ENABLED;
export RUN_IN_CHARGER_CHECK_ENABLED;

#
# Define run-in menu items to be non-selectable values
#   These get redefined later if the component is enabled
#   for the run-in test.
#
export RUN_IN_VIDEO_MENU_ITEM=500
export RUN_IN_LED_MENU_ITEM=501
export RUN_IN_BUTTON_MENU_ITEM=502
export RUN_IN_KEYBOARD_MENU_ITEM=503
export RUN_IN_FIVEWAY_MENU_ITEM=504
export RUN_IN_AUDIO_MENU_ITEM=505
export RUN_IN_POWER_MENU_ITEM=506
export RUN_IN_GAS_GAUGE_MENU_ITEM=507
export RUN_IN_MOVINAND_MENU_ITEM=509
export RUN_IN_WAN_MENU_ITEM=510
export RUN_IN_CHARGER_CHECK_MENU_ITEM=511
export RUN_IN_TIME_MENU_ITEM=512
export RUN_IN_HAPTIC_MENU_ITEM=513
export RUN_IN_WIFI_MENU_ITEM=514


######################################################################
# Function:     rm_display_menu
# Purpose:      Display the main run modes menu screen
# Paramters:    none
# Returns:      none
######################################################################
rm_display_menu()
{
    clear_screen
    ${DOUT} -n 15 4 "$PRODUCT_NAME Run Modes"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    text=`keycode_to_label $RM_RUN_IN_TEST_KEY`
    ${DOUT} -n 10 7 "$text) Start Run-in Test"
    line=9

    if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $RM_WAN_ENABLED_TEST_KEY`
        ${DOUT} -n 10 $line "$text) WAN enabled"
        let line+=2

        if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
            text=`keycode_to_label $RM_EINK_WAN_TEST_KEY`
            ${DOUT} -n 10 $line "$text) EINK with WAN enabled"
            let line+=2
        fi
        if [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
            text=`keycode_to_label $RM_USB_WAN_TEST_KEY`
            ${DOUT} -n 10 $line "$text) USB with WAN enabled"
            let line+=2
        fi
    else 
        # WFO does not have WAN so just run eInk flip page test
        if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
            text=`keycode_to_label $RM_EINK_FLIP_PAGE_TEST_KEY`
            ${DOUT} -n 10 $line "$text) EINK flip page test"
            let line+=2
        fi
    fi

    if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ] && [ -n "HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
        text=`keycode_to_label $RM_EINK_USB_TEST_KEY`
        ${DOUT} -n 10 $line "$text) EINK with USB Volume Exported"
        let line+=2
    fi

    if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ] && [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $RM_AUDIO_SPEAKER_WAN_TEST_KEY`
        ${DOUT} -n 10 $line "$text) Speakers with WAN enabled"
        let line+=2
        text=`keycode_to_label $RM_AUDIO_HP_WAN_TEST_KEY`
        ${DOUT} -n 10 $line "$text) Audio Jack with WAN enabled"
        let line+=2
    fi

    if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $RM_511_TEST_KEY`
        ${DOUT} -n 10 $line "$text) 511 WAN Test"
        let line+=2
        text=`keycode_to_label $RM_WAN_MOLB_TEST_KEY`
        ${DOUT} -n 10 $line "$text) Originate Call WAN Test"
        let line+=2
        text=`keycode_to_label $RM_WAN_GSM1900_TEST_KEY`
        ${DOUT} -n 10 $line "$text) GSM 1900 Band WAN Test"
        let line+=2
    elif ( is_Shasta_WFO ); then
        text=`keycode_to_label $RM_511_TEST_KEY`
        ${DOUT} -n 10 $line "$text) 511 Test"
        let line+=2

    fi

    if [ -n "HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
        if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
            text=`keycode_to_label $RM_EINK_TEST_KEY`
            ${DOUT} -n 10 $line "$text) EINK Flipper with Speaker Audio"
            let line+=2
        fi

        text=`keycode_to_label $RM_EINK_EYE_ONE_TEST_KEY`
        ${DOUT} -n 10 $line "$text) EINK Eye-One Optical Test"
        let line+=2
    fi

    if [ -n "$HAS_TTS" ] && [ $HAS_TTS -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
        text=`keycode_to_label $RM_TTS_TEST_KEY`
        ${DOUT} -n 10 $line "$text) Text-To-Speech"
        let line+=2
    fi

    if [ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
        text=`keycode_to_label $RM_WIFI_FCC_COMPLIANCE_TEST_KEY`
        ${DOUT} -n 10 $line "$text) Wifi FCC compliance test"
        let line+=2
    fi
    let line+=2
    ${DOUT} 8 $line "Press $EXIT_KEY_LABEL to exit $PRODUCT_NAME Run Modes."
}



######################################################################
# Function:     runin_monitor_battery_charge
# Purpose:      Monitor battery charge capacity and drive it towards
#               the target ship capacity by turing on or off the charger
#               as appropriate.
# Paramters:    none
# Returns:      Error from charger_limit_charge() - currently one of :
#               0 - charger left off
#               1 - charger left on
#               2 - Error getting battery capacity
#               3 - Battery capacity jumped larger than allowed
#               4 - Charger failed to enable
#               5 - Charger failed to disable
######################################################################
runin_monitor_battery_charge()
{
    charger_limit_charge "$RUN_IN_CHARGER_CHECK_ENABLED"
    charge_err=$?
    case $charge_err in
        2)
            export RUN_IN_TEST_FAIL=1
	        export RUN_IN_FAILURE_REASON="Failed Reading Battery Capacity"
            ;;
        3)
            # If we've already had a failure, then a battery capacity failure
            # is expected because a test likely ran longer than it should have,
            # causing the battery capacity to change more than expected.
            # Don't report this as it's an effect, not a cause
            #
            if [ $RUN_IN_TEST_FAIL -eq 0 ]; then
                export RUN_IN_TEST_FAIL=1
                runin_battery_capacity_delta_failure
            else
                do_local_echo "Battery capacity failure ignored due to previous error"
                do_local_echo "Reason: $RUN_IN_FAILURE_REASON"
            fi
            ;;
        4)
            export RUN_IN_TEST_FAIL=1
	        export RUN_IN_FAILURE_REASON="Charger failed to turn on"
            ;;
        5)
            export RUN_IN_TEST_FAIL=1
	        export RUN_IN_FAILURE_REASON="Charger failed to turn off"
            ;;
        *)
            ;;
    esac
    return $charge_err
}



######################################################################
# Function:     runin_display_result_dialog
# Purpose:      Display the results of the run-in test
# Paramters:    pass
#			0 - Test failed
#              		1 - Test passed
#		reason - reason for failure , one of:
#			0 - Sub-Test failed
#			1 - Battery capacity not at target limit
# Returns:      none
######################################################################
runin_display_result_dialog()
{
	PRINT_FAILURE_STRING=0
    clear_screen
	base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	banner="Run-in Test Mode"
	print_center_text "$banner" "$base" 10 4
    if [ "$RUN_IN_FAILURE_REASON" == "No Failure" ]; then
        export RUN_IN_FAILURE_REASON="Run-in test failed."
    fi
    case "$1" in
        0)
            RESULT_STR="FAILED"
		    PRINT_FAILURE_STRING=1
            failure "$RUN_IN_FAILURE_REASON"
            ;;
        1)
            RESULT_STR="PASSED"
            ;;
        *)
            RESULT_STR="ERROR - UNKNOWN RESULT"
            ;;
    esac
	center_text "$RESULT_STR" 10 "$base"
    ${DOUT} -n $? 9 "$RESULT_STR"
	if [ $PRINT_FAILURE_STRING -eq 1 ]; then
		center_text "$RUN_IN_FAILURE_REASON" 10 "$base"
    	${DOUT} -n $? 13 "$RUN_IN_FAILURE_REASON"
	fi
	banner="Press $EXIT_KEY_LABEL to continue."
	center_text "$banner" 10 "$base"
    ${DOUT} $? 17 "$banner"

	# Wait for operator to acknowledge
	# Adjust charger once a minute while waiting
    DONE=0
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT ${END_RUN_IN_CHARGE_PERIOD}`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            # Process key request
            case "$KEY" in
                $EXIT_KEY)
                    DONE=1
                    ;;
                *)
                    vmsg "Wrong key $Key pressed"
                    ;;
            esac
        else
    		# Adjust charger if necessary
            runin_monitor_battery_charge
        fi
    done
}


######################################################################
# Function:     format_time
# Purpose:      Echo the time in HR:MM:SS format given the time in seconds
# Paramters:    THE_TIME - time in seconds 
# Returns:      echo's the time string
######################################################################
format_time()
{
    THE_TIME="$1"
    HOUR_LEAD=""
    MIN_LEAD=""
    SEC_LEAD=""
    HOURS=`expr $THE_TIME / 3600`
    if [ $HOURS -le 9 ]; then
        HOUR_LEAD="0"
    fi
    HS=`expr $HOURS \* 3600`
    HSR=`expr $THE_TIME - $HS`
    MIN=`expr $HSR / 60`
    if [ $MIN -le 9 ]; then
        MIN_LEAD="0"
    fi
    MS=`expr $MIN \* 60`
    SEC=`expr $THE_TIME - $HS - $MS`
    if [ $SEC -le 9 ]; then
        SEC_LEAD="0"
    fi
    echo "${HOUR_LEAD}${HOURS}:${MIN_LEAD}${MIN}:${SEC_LEAD}${SEC}"
}


######################################################################
# Function:     display_run_in_cancel_test_message
# Purpose:      Display a cancel request image on the screen and wait
#               a short amount of time to allow user to cancel test
#               if they want.
# Paramters:    delay - mSeconds to leave image on screen before clearing
#               left - seconds left before end of run-in test
# Returns:      0 - User doesn't want to stop test
#               1 - User wants to stop test...
######################################################################
display_run_in_cancel_test_message()
{
    _TIMEOUT="$1"
    TIME_LEFT_STR=`format_time "$2"`
    get_timer_run_time
    RUN_IN_RUN_TIME="$?"
    RUN_IN_RUN_TIME_STR=`format_time "$RUN_IN_RUN_TIME"`
    BATTERY_LEVEL=`${BATTERY_CAPACITY} | sed s/\%//g` > /dev/null 2>&1

    RUN_IN_CUR_TIME=`date`
    clear_screen
    banner="Run-in Test Mode"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 10 "$base"
    ${DOUT} -n $? 4 "$banner"
    ${DOUT} -n 10 5 "$base"
    do_local_echo "Current Time   : $RUN_IN_CUR_TIME"
    ${DOUT} -n 10 7 "Test Run Time  : $RUN_IN_RUN_TIME_STR"
    ${DOUT} -n 10 9 "Test Time Left : $TIME_LEFT_STR"
    ${DOUT} -n 10 11 "Battery Level  : ${BATTERY_LEVEL} Percent"
    ${DOUT} -n 10 13 "Target Level   : ${RUN_IN_LOWER_CHARGE_LIMIT} to ${RUN_IN_UPPER_CHARGE_LIMIT} Percent"
    ${DOUT} 10 17 "Press $EXIT_KEY_LABEL now to stop the test."

    # Get the key request
    DONE=0
    CANCEL=0
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT ${_TIMEOUT}`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            #
            # Process key request
            case "$KEY" in

                $EXIT_KEY)
                    DONE=1
                    CANCEL=1
					export RUN_IN_FAILURE_REASON="Operator Cancelled Run-In Test"
                    ;;

                *)
                    vmsg "Wrong key $Key pressed"
                    ;;
            esac
        else
            vmsg "Key not found - timed out"
            DONE=1
        fi
    done
    return $CANCEL;

}


######################################################################
# Function:     set_run_in_menu_items
# Purpose:      Display the run-in menu with only components that have
#               been enabled for the run-in test.
# Paramters:    none
# Returns:      none
######################################################################
set_run_in_menu_items()
{
    if [ "x$HAS_VIDEO" == "x1" ]; then
        export RUN_IN_VIDEO_MENU_ITEM="$SET_VIDEO_MENU_ITEM"
    fi

    if [ "x$HAS_LED" == "x1" ]; then
        export RUN_IN_LED_MENU_ITEM="$SET_LED_MENU_ITEM"
    fi

    if [ "x$HAS_HAPTIC" == "x1" ]; then
        export RUN_IN_HAPTIC_MENU_ITEM="$SET_HAPTIC_MENU_ITEM"
    fi

    if [ "x$HAS_POWER" == "x1" ]; then
        export RUN_IN_POWER_MENU_ITEM="$SET_POWER_MENU_ITEM"
    fi

    if [ "x$HAS_GAS_GAUGE" == "x1" ]; then
        export RUN_IN_GAS_GAUGE_MENU_ITEM="$SET_GAS_GAUGE_MENU_ITEM"
    fi

    if [ "x$HAS_AUDIO" == "x1" ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
        export RUN_IN_AUDIO_MENU_ITEM="$SET_AUDIO_MENU_ITEM"
    fi

    if [ "x$HAS_WAN" == "x1" ]; then
        export RUN_IN_WAN_MENU_ITEM="$SET_WAN_MENU_ITEM"
    fi

    if [ "x$HAS_WIFI" == "x1" ]; then
        export RUN_IN_WIFI_MENU_ITEM="$SET_WIFI_MENU_ITEM"
    fi

    if [ "x$HAS_MOVINAND" == "x1" ]; then
        export RUN_IN_MOVINAND_MENU_ITEM="$SET_MOVINAND_MENU_ITEM"
    fi

    # Assign menu item to "Charger Check" disable menu item
    export RUN_IN_CHARGER_CHECK_MENU_ITEM="$SET_RUN_IN_CHARGER_CHECK_MENU_ITEM"

    # Assign menu item to "Test execution time" menu item
    export RUN_IN_TIME_MENU_ITEM="$SET_RUN_IN_TIME_MENU_ITEM"
}


######################################################################
# Function:     set_run_in_default_options
# Purpose:      Setup the run-in tests default options based on device's
#               run-in test component default values.
# Paramters:    none
# Returns:      none
######################################################################
set_run_in_default_options()
{
    # Setup defaults
    export RUN_IN_USB_ENABLED="DISABLED";
    export RUN_IN_CHARGER_CHECK_ENABLED="$RUN_IN_CHARGER_CHECK_ENABLE_DEFAULT";

    if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        export RUN_IN_WAN_ENABLED=$RUN_IN_WAN_ENABLE_DEFAULT;
    else
        export RUN_IN_WAN_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
        export RUN_IN_WIFI_ENABLED=$RUN_IN_WIFI_ENABLE_DEFAULT;
    else
        export RUN_IN_WIFI_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
        export RUN_IN_VIDEO_ENABLED=$RUN_IN_VIDEO_ENABLE_DEFAULT;
    else
        export RUN_IN_VIDEO_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_LED" ] && [ $HAS_LED -eq 1 ]; then
        export RUN_IN_LED_ENABLED=$RUN_IN_LED_ENABLE_DEFAULT;
    else
        export RUN_IN_LED_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_HAPTIC" ] && [ $HAS_HAPTIC -eq 1 ]; then
        export RUN_IN_HAPTIC_ENABLED=$RUN_IN_HAPTIC_ENABLE_DEFAULT;
    else
        export RUN_IN_HAPTIC_ENABLED="DISABLED";
    fi
    if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
        export RUN_IN_AUDIO_ENABLED=$RUN_IN_AUDIO_ENABLE_DEFAULT;
    else
        export RUN_IN_AUDIO_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_POWER" ] && [ $HAS_POWER -eq 1 ]; then
        export RUN_IN_POWER_ENABLED=$RUN_IN_POWER_ENABLE_DEFAULT;
    else
        export RUN_IN_POWER_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_GAS_GAUGE" ] && [ $HAS_GAS_GAUGE -eq 1 ]; then
        export RUN_IN_GAS_GAUGE_ENABLED=$RUN_IN_GAS_GAUGE_ENABLE_DEFAULT;
    else
        export RUN_IN_GAS_GAUGE_ENABLED="DISABLED";
    fi
    if [ -n "$HAS_MOVINAND" ] && [ $HAS_MOVINAND -eq 1 ]; then
        export RUN_IN_MOVINAND_ENABLED=$RUN_IN_MOVINAND_ENABLE_DEFAULT;
    else
        export RUN_IN_MOVINAND_ENABLED="DISABLED";
    fi
}



######################################################################
# Function:     do_get_and_set_run_in_time
# Purpose:      Allow user to specify a new duration for the lenght of
#               the run-in test (2 hours by default)
# Parameters:   none
# Returns:      none
# Side Effects: RUN_IN_DURATION_TIME is changed is user specified new 
#               test execution duration time.
######################################################################
do_get_and_set_run_in_time()
{
    # Dump any remaining CR
    dump_char

    # Print Banner
    clear_screen
    print_center_text "Run-in Test Duration" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 12 4

    # Get input from user
    _USER_RUN_IN_DURATION_TIME=""
    let RUN_IN_HOURS=$RUN_IN_DURATION_TIME/3600
    while [ 1 ]; do
        ${DOUT} -n 2 9 "Enter new test time in hours: $_USER_RUN_IN_DURATION_TIME"
        ${DOUT} 2 13 "Press $EXIT_KEY_LABEL to cancel."
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
            $KEY_ENTER)
                if [ -n "$_USER_RUN_IN_DURATION_TIME" ]; then
                    let RUN_IN_DURATION_TIME=$_USER_RUN_IN_DURATION_TIME*3600
                    export RUN_IN_DURATION_TIME
                fi
                return 0
                ;;

            $EXIT_KEY)
                echo "Not setting run-in execution time - user cancelled."
                return 1
                ;;

            $KEY_0 | $KEY_1 | $KEY_2 | $KEY_3 | $KEY_4 | $KEY_5 | $KEY_6 | \
            $KEY_7 | $KEY_8 | $KEY_9)
                _key_text=`keycode_to_label $KEY`
                _USER_RUN_IN_DURATION_TIME="${_USER_RUN_IN_DURATION_TIME}${_key_text}"
                erase_line 9
                ;;

            *)
                ;;
            esac
        fi
    done

}


######################################################################
# Function:     verify_user_has_serial_port 
# Purpose:      Ask user to verify they want to set run-in time
#               via the console before we stop accepting events from
#               on-board device keyboard (don't get user stuck if no
#               debug board is attached - allow them to bail out).
# Paramters:    none
# Returns:      0 - User DOES NOT want to continue / wants to cancel
#               1 - User wants to continue / set run-in time via
#                   serial console.
######################################################################
verify_user_has_serial_port()
{
    clear_screen
    set_option="$1"
    print_center_text "Run-in Text Execution Time" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 4 4
    ${DOUT} -n 4 7 "Changing run-in test execution time must be"
    ${DOUT} -n 4 9 "performed from the debug board console."
    ${DOUT} -n 4 13 "Press $SUCCESS_KEY_LABEL to set run-in execution time now."
    ${DOUT} 4 15 "Press $EXIT_KEY_LABEL to abort changing execution time."

    #
    # Get the key request
    #
    while [ 0 -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        case "$KEY" in
            $SUCCESS_KEY)
                # suck off any remaining enter's from serial port...
                KEY=`$GET_KEYBOARD_INPUT 1`

                erase_line 7
                erase_line 9
                erase_line 13
                erase_line 15
                ${DOUT} -n 4 7 "$set_option is being modified"
                ${DOUT} -n 4 9 "now via the serial console..."
                ${DOUT} 4 13 "This screen will disappear once complete."
                return 1
                ;;

            $EXIT_KEY)
                # suck off any remaining enter's from serial port...
                KEY=`$GET_KEYBOARD_INPUT 1`
                return 0
                ;;

            *)
                ;;
        esac
    done;
}


######################################################################
# Function:     adjust_run_in_options
# Purpose:      Display screen to allow operator to enable or disable
#               various components for the run-in test.
# Paramters:    none
# Returns:      none
# Side Effect:  Sets the RUN_IN_XXX_ENABLED variable based on operator
#               response.
######################################################################
adjust_run_in_options()
{
    # Setup product-defined defaults
    set_run_in_default_options

    # Allow operator to adjust options
    set_run_in_menu_items

    # Loop until user is done configuring test options...
    DONE=0
    CANCEL=0
    _DO_FULL_REDRAW=1
    while [ $DONE -ne 1 ]; do
        if [ $_DO_FULL_REDRAW -eq 1 ]; then
            # Print static screen contents
            clear_screen
            print_center_text "Run-in Test Mode Options" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 4 4
            _DO_REDRAW=1
            _DO_FULL_REDRAW=0
        fi

        if [ $_DO_REDRAW -eq 1 ]; then
            line=7
            # Redraw dynamic section of screen
            if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_VIDEO_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) Video is currently $RUN_IN_VIDEO_ENABLED  "
                run_in_video_line=line
                let line+=2
            fi

            if [ -n "$HAS_LED" ] && [ $HAS_LED -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_LED_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) LED is currently $RUN_IN_LED_ENABLED  "
                run_in_led_line=line
                let line+=2
            fi

            if [ -n "$HAS_HAPTIC" ] && [ $HAS_HAPTIC -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_HAPTIC_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) Haptic is currently $RUN_IN_HAPTIC_ENABLED  "
                run_in_haptic_line=line
                let line+=2
            fi

            if [ -n "$HAS_POWER" ] && [ $HAS_POWER -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_POWER_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) Power is currently $RUN_IN_POWER_ENABLED  "
                run_in_power_line=line
                let line+=2
            fi

            if [ -n "$HAS_GAS_GAUGE" ] && [ $HAS_GAS_GAUGE -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_GAS_GAUGE_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) Gas Gauge is currently $RUN_IN_GAS_GAUGE_ENABLED  "
                run_in_gas_gauge_line=line
                let line+=2
            fi

            if [ -n "HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ] && [ $_DONT_INCLUDE_AUDIO_TESTS -eq 0 ]; then
                text=`keycode_to_label $RUN_IN_AUDIO_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) Audio is currently $RUN_IN_AUDIO_ENABLED  "
                run_in_audio_line=line
                let line+=2
            fi

            if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_WAN_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) WAN is currently $RUN_IN_WAN_ENABLED  "
                run_in_wan_line=line
                let line+=2
            fi

            if [ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_WIFI_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) WIFI is currently $RUN_IN_WIFI_ENABLED  "
                run_in_wifi_line=line
                let line+=2
            fi

            if [ -n "$HAS_MOVINAND" ] && [ $HAS_MOVINAND -eq 1 ]; then
                text=`keycode_to_label $RUN_IN_MOVINAND_MENU_ITEM`
                ${DOUT} -n 4 $line "$text) MoviNand is currently $RUN_IN_MOVINAND_ENABLED  "
                run_in_movinand_line=line
                let line+=2
            fi

            text=`keycode_to_label $RUN_IN_CHARGER_CHECK_MENU_ITEM`
            ${DOUT} -n 4 $line "$text) Charge Verify is currently $RUN_IN_CHARGER_CHECK_ENABLED  "
            run_in_cc_enable_line=line

            let line+=2
            text=`keycode_to_label $RUN_IN_TIME_MENU_ITEM`
            let _time_in_hours=$RUN_IN_DURATION_TIME/3600
            ${DOUT} -n 4 $line "$text) Test execution time is $_time_in_hours hours"
            
            let line+=4
            ${DOUT} -n 4 $line "Select an item to toggle its enable status."
            let line+=2
            ${DOUT} 4 $line "Select $EXIT_KEY_LABEL to start the run-in test."
        else
            _DO_REDRAW=1
        fi

        # Get the key request
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            #
            # Process key request
            case "$KEY" in
                $RUN_IN_WAN_MENU_ITEM)
                    if [ "$RUN_IN_WAN_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_WAN_ENABLED="DISABLED"
                    else
                        export RUN_IN_WAN_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_wan_line
                    ;;
                $RUN_IN_WIFI_MENU_ITEM)
                    if [ "$RUN_IN_WIFI_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_WIFI_ENABLED="DISABLED"
                    else
                        export RUN_IN_WIFI_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_wifi_line
                    ;;
                $RUN_IN_VIDEO_MENU_ITEM)
                    if [ "$RUN_IN_VIDEO_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_VIDEO_ENABLED="DISABLED"
                    else
                        export RUN_IN_VIDEO_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_video_line
                    ;;
                $RUN_IN_LED_MENU_ITEM)
                    if [ "$RUN_IN_LED_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_LED_ENABLED="DISABLED"
                    else
                        export RUN_IN_LED_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_led_line
                    ;;
                $RUN_IN_HAPTIC_MENU_ITEM)
                    if [ "$RUN_IN_HAPTIC_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_HAPTIC_ENABLED="DISABLED"
                    else
                        export RUN_IN_HAPTIC_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_haptic_line
                    ;;
                $RUN_IN_AUDIO_MENU_ITEM)
                    if [ "$RUN_IN_AUDIO_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_AUDIO_ENABLED="DISABLED"
                    else
                        export RUN_IN_AUDIO_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_audio_line
                    ;;
                $RUN_IN_POWER_MENU_ITEM)
                    if [ "$RUN_IN_POWER_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_POWER_ENABLED="DISABLED"
                    else
                        export RUN_IN_POWER_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_power_line
                    ;;
                $RUN_IN_GAS_GAUGE_MENU_ITEM)
                    if [ "$RUN_IN_GAS_GAUGE_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_GAS_GAUGE_ENABLED="DISABLED"
                    else
                        export RUN_IN_GAS_GAUGE_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_gas_gauge_line
                    ;;
                $RUN_IN_MOVINAND_MENU_ITEM)
                    if [ "$RUN_IN_MOVINAND_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_MOVINAND_ENABLED="DISABLED"
                    else
                        export RUN_IN_MOVINAND_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_movinand_line
                    ;;
                $RUN_IN_CHARGER_CHECK_MENU_ITEM)
                    if [ "$RUN_IN_CHARGER_CHECK_ENABLED" == "ENABLED" ]; then
                        export RUN_IN_CHARGER_CHECK_ENABLED="DISABLED"
                    else
                        export RUN_IN_CHARGER_CHECK_ENABLED="ENABLED"
                    fi
                    erase_line $run_in_cc_enable_line
                    ;;
                $RUN_IN_TIME_MENU_ITEM)
                    do_get_and_set_run_in_time
                    _DO_FULL_REDRAW=1
                    echo "DONE after getting run_in time is $DONE"
                    ;;

                $EXIT_KEY)
                    DONE=1
                    _DO_REDRAW=0
                    ;;

                *)
                    vmsg "Wrong key $Key pressed"
                    _DO_FULL_REDRAW=0
                    _DO_REDRAW=0
                    ;;
            esac
        fi
    done
}


######################################################################
# Function:     exit_run_in_hals
# Purpose:      Call the exit routine for all hals that were initialized
# Paramters:    none
# Returns:      none
######################################################################
exit_run_in_hals()
{
    # Init Audio hal if requested
    if [ "$RUN_IN_AUDIO_ENABLED" == "ENABLED" ]; then
        audio_hal_exit
    fi

    # Init USB hal if requested
    if [ "$RUN_IN_USB_ENABLED" == "ENABLED" ]; then
        usb_hal_exit
    fi

    # Init Video hal if requested
    if [ "$RUN_IN_VIDEO_ENABLED" == "ENABLED" ]; then
        video_hal_exit
    fi

    # Run WAN test hal if requested
    if [ "$RUN_IN_WAN_ENABLED" == "ENABLED" ]; then
        wan_hal_exit
    fi

    # Run Gas Gauge test hal if requested
    if [ "$RUN_IN_GAS_GAUGE_ENABLED" == "ENABLED" ]; then
        gas_gauge_hal_exit
    fi

    # Run Haptic test hal if requested
    if [ "$RUN_IN_HAPTIC_ENABLED" == "ENABLED" ]; then
        fiveway_hal_exit
    fi

    # Run LED test hal if requested
    if [ "$RUN_IN_LED_ENABLED" == "ENABLED" ]; then
        led_hal_exit
    fi

    # Run Power test hal if requested
    if [ "$RUN_IN_POWER_ENABLED" == "ENABLED" ]; then
        power_hal_exit
    fi

    # Run MoviNand test hal if requested
    if [ "$RUN_IN_MOVINAND_ENABLED" == "ENABLED" ]; then
        movinand_hal_exit
    fi
}


######################################################################
# Function:     init_run_in_hals
# Purpose:      Call the init routine for all hals we use for run-in.
# Paramters:    none
# Returns:      none
######################################################################
init_run_in_hals()
{
    # Init Audio hal if requested
    if [ "$RUN_IN_AUDIO_ENABLED" == "ENABLED" ]; then
        audio_hal_init
    fi

    # Init USB hal if requested
    if [ "$RUN_IN_USB_ENABLED" == "ENABLED" ]; then
        usb_hal_init
    fi

    # Init Video hal if requested
    if [ "$RUN_IN_VIDEO_ENABLED" == "ENABLED" ]; then
        video_hal_init
    fi

    # Run WAN test hal if requested
    if [ "$RUN_IN_WAN_ENABLED" == "ENABLED" ]; then
        wan_hal_init
    fi

    # Run Gas Gauge test hal if requested
    if [ "$RUN_IN_GAS_GAUGE_ENABLED" == "ENABLED" ]; then
        gas_gauge_hal_init
    fi

    # Run Haptic test hal if requested
    if [ "$RUN_IN_HAPTIC_ENABLED" == "ENABLED" ]; then
        fiveway_hal_init
    fi

    # Run LED test hal if requested
    if [ "$RUN_IN_LED_ENABLED" == "ENABLED" ]; then
        led_hal_init
    fi

    # Run Power test hal if requested
    if [ "$RUN_IN_POWER_ENABLED" == "ENABLED" ]; then
        power_hal_init
    fi

    # Run MoviNand test hal if requested
    if [ "$RUN_IN_MOVINAND_ENABLED" == "ENABLED" ]; then
        movinand_hal_init
    fi

}


######################################################################
# Function:     runin_do_check_timeout
# Purpose:      Check to see if the run-in time has expired.  If it has,
#               check the battery capacity and fail if it's not within
#               1% of target.
# Paramters:    none
# Returns:      0 - Timer not expired yet
#               1 - Timer expired, test over, battery within 1% of target.
#               2 - Timer expired, but battery not within 1% of target
#               3 - Operator cancelled
######################################################################
runin_do_check_timeout()
{
    # See if we need to time out and quit...
    check_timeout
    TIME_LEFT=$?
    if [ $TIME_LEFT -ne 0 ]; then
        # See if user wants to quit...
        display_run_in_cancel_test_message ${RUN_IN_DISPLAY_CANCEL_TIMEOUT} $TIME_LEFT
        if [ $? -eq 1 ]; then
            RUN_IN_DONE=3
        fi
    else
        vmsg "Run-in test complete"

        # See if our battery is where we want it capacity wise.
        # If it's not, fail the run-in test....
        #
        is_battery_at_limit
        battery_not_ready="$?"
        cap=`${BATTERY_CAPACITY}`
        if [ $battery_not_ready -ne 0 ]; then
            failure "Post Run-in Battery Capacity at $cap" 
			export RUN_IN_FAILURE_REASON="Battery Capacity Out-Of-Bounds At $cap"
            RUN_IN_DONE=2
        else
            success "Post Run-in Battery Capacity at $cap" 
            RUN_IN_DONE=1
        fi

        # Disable charger after run-in is complete
        charger off
    fi
    return $RUN_IN_DONE
}


######################################################################
# Function:     runin_battery_capacity_delta_failure
# Purpose:      Run-in test detected a jump in battery capacity larger
#               than that allowed.  Set the RUN_IN_TEST_FAIL and the
#               RUN_IN_FAILURE_REASON variables accordingly
# Paramters:    none
# Returns:		none
######################################################################
runin_battery_capacity_delta_failure()
{
    local_cap=`get_battery_capacity`
    if [ $? -eq 0 ]; then
	    export RUN_IN_FAILURE_REASON="Battery Capacity Change Too Large (was $LAST_BATTERY_CAPACITY, now $local_cap)"
    else
	    export RUN_IN_FAILURE_REASON="Battery Capacity Change Too Large (was $LAST_BATTERY_CAPACITY, now Unknown)"
    fi

    # reset the battery capacity so that the run-in test charge monitor can continue
    # to run without complaining
    reset_last_battery_capacity
}


######################################################################
# Function:     do_run_in_subtest
# Purpose:      Execute the diagnostic subtest in it's auto-run mode.
#               Sync the filesystem afterwards and then adjust battery
#               charger if needed
# Paramters:    ID of subtest to run.  One of:
#                   $RUNIN_VIDEO_DIAG_ID - Video
#                   $RUNIN_WAN_DIAG_ID - WAN
#                   $RUNIN_WIFI_DIAG_ID - WIFI
#                   $RUNIN_MOVINAND_DIAG_ID - moviNand
#                   $RUNIN_LED_DIAG_ID - LED
#                   $RUNIN_HAPTIC_DIAG_ID - Haptic
#                   $RUNIN_USB_DEVICE_DIAG_ID - Usb Device
#                   $RUNIN_GAS_GAUGE_DIAG_ID - Gas Gauge
#                   $RUNIN_POWER_DIAG_ID - Power
#                   $RUNIN_AUDIO_DIAG_ID - Audio
# Returns:      0 - Test was executed, filesystem synced, and battery charge monitored
#               1 - Subtest is not supported
#               2 - Reqeust was for a test that is disabled for run-in
######################################################################
do_run_in_subtest()
{
    case "$1" in
        $RUNIN_VIDEO_DIAG_ID)
            _runin_name="Video"
            _runin_test="$CYCLE_RUN_VIDEO"
            _runin_test_enabled="$RUN_IN_VIDEO_ENABLED"
            ;;
        $RUNIN_WIFI_DIAG_ID)
            _runin_name="WIFI"
            _runin_test="$CYCLE_RUN_WIFI"
            _runin_test_enabled="$RUN_IN_WIFI_ENABLED"
            ;;
        $RUNIN_WAN_DIAG_ID)
            _runin_name="WAN"
            _runin_test="$CYCLE_RUN_WAN"
            _runin_test_enabled="$RUN_IN_WAN_ENABLED"
            ;;
        $RUNIN_MOVINAND_DIAG_ID)
            _runin_name="MoviNand"
            _runin_test="$CYCLE_RUN_MOVINAND"
            _runin_test_enabled="$RUN_IN_MOVINAND_ENABLED"
            ;;
        $RUNIN_LED_DIAG_ID)
            _runin_name="LED"
            _runin_test="$CYCLE_RUN_LED"
            _runin_test_enabled="$RUN_IN_LED_ENABLED"
            ;;
        $RUNIN_HAPTIC_DIAG_ID)
            _runin_name="Haptic"
            _runin_test="$CYCLE_RUN_HAPTIC"
            _runin_test_enabled="$RUN_IN_HAPTIC_ENABLED"
            ;;
        $RUNIN_USB_DEVICE_DIAG_ID)
            _runin_name="USB Device Export Volume"
            _runin_test="$CYCLE_RUN_USB_DEVICE"
            _runin_test_enabled="$RUN_IN_USB_ENABLED"
            ;;
        $RUNIN_GAS_GAUGE_DIAG_ID)
            _runin_name="Gas Gauge"
            _runin_test="$CYCLE_RUN_GAS_GAUGE"
            _runin_test_enabled="$RUN_IN_GAS_GAUGE_ENABLED"
            ;;
        $RUNIN_POWER_DIAG_ID)
            _runin_name="Power"
            _runin_test="$CYCLE_RUN_POWER"
            _runin_test_enabled="$RUN_IN_POWER_ENABLED"
            ;;
        $RUNIN_AUDIO_DIAG_ID)
            _runin_name="Audio"
            _runin_test="$CYCLE_RUN_AUDIO"
            _runin_test_enabled="$RUN_IN_AUDIO_ENABLED"
            ;;
        *)
            # Subtest is not supported as a run-in test
            return 1
            ;;
    esac

    # If the test is enabled for run-in and run-in is still going (no errors), execute that test now..
    if [ "${_runin_test_enabled}" == "ENABLED" ] && [ $RUN_IN_DONE -eq 0 ] && [ $RUN_IN_TEST_FAIL -eq 0 ]; then

        # Execute the run-in subtest...
        do_local_echo "Run-In: Starting ${_runin_name} Test..."
        ${_runin_test} 1
        RUN_IN_TEST_FAIL="$?"
        do_local_echo "Run-In: Finished ${_runin_name} Test..."
        if [ $RUN_IN_TEST_FAIL -eq 0 ]; then
            # See if we're done or if user wants to cancel
            runin_do_check_timeout
            RUN_IN_DONE="$?"
        fi

        # Sync the filesystem so if we hang, we have our logfile somewhat recent
        sync

        # Adjust charger if necessary
        runin_monitor_battery_charge

        # Return test run status
        return 0
    fi;

    # If we're here, we were called for a disabled test
    return 2
}


######################################################################
# Function:     do_run_in_mode
# Purpose:      Execute the diagnostic tests in their auto-run mode.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    none
# Returns:		0 - test failed
#               1 - tests passed
######################################################################
do_run_in_mode()
{
    # Display options set for run-in, allowing user to change
    adjust_run_in_options

    # Execute all hal initialization routines
    init_run_in_hals

    # Default to run for two hours
    set_timeout $RUN_IN_DURATION_TIME

    # Make sure our RUN_IN_TEST_FAIL variable is reset
    export RUN_IN_TEST_FAIL=0
    export RUN_IN_DONE=0
    export RUN_IN_FAILURE_REASON="No Failure"

    # Make sure the SUB_TEST_PASSED variable is reset
    clear_diag_fail

    # Log console to logfile
    do_enable_console_logfile

    # Reset LAST_BATTERY_CAPACITY for detecting battery capacity jumps that are out-of-spec
    reset_last_battery_capacity

    # To test the battery capacity jump failure detection mechanism,
    # uncomment the following line and/or move in between different subcalls below...:
    #clear_last_battery_capacity

    # Fire up one-time-only tests, like USB export and audio mode....
    # do_run_in_subtest "$RUNIN_USB_DEVICE_DIAG_ID"
    do_run_in_subtest "$RUNIN_AUDIO_DIAG_ID"

    # Cycle through the tests until we time out or user stops tests
    while [ $RUN_IN_DONE -eq 0 ] && [ $RUN_IN_TEST_FAIL -eq 0 ]; do
        # Run Video if requested
        do_run_in_subtest  $RUNIN_VIDEO_DIAG_ID

        # Run WAN test if requested
        do_run_in_subtest  $RUNIN_WAN_DIAG_ID

        # Run WIFI test if requested
        do_run_in_subtest  $RUNIN_WIFI_DIAG_ID

        # Run Gas Gauge test if requested
        do_run_in_subtest  $RUNIN_GAS_GAUGE_DIAG_ID

        # Run Haptic test if requested
        do_run_in_subtest  $RUNIN_HAPTIC_DIAG_ID

        # Run LED test if requested
        do_run_in_subtest  $RUNIN_LED_DIAG_ID

        # Run Power test if requested
        do_run_in_subtest  $RUNIN_POWER_DIAG_ID

        # Run MoviNand test if requested
        do_run_in_subtest  $RUNIN_MOVINAND_DIAG_ID

        # See if we're done or if user wants to cancel
        if [ $RUN_IN_DONE -eq 0 ] && [ $RUN_IN_TEST_FAIL -eq 0 ]; then
            # In case user running with all diags disabled...
            runin_do_check_timeout
            RUN_IN_DONE="$?"
        fi
    done

    if [ $RUN_IN_DONE -eq 2 ] || [ $RUN_IN_DONE -eq 3 ]; then
        RUN_IN_TEST_FAIL=1;
    fi

    # Done with the timer, releasing it
    disable_diag_timer

    # Stop the remaining running tests
    if [ "$RUN_IN_AUDIO_ENABLED" == "ENABLED" ]; then
        $CYCLE_STOP_AUDIO
    fi
    if [ "$RUN_IN_USB_ENABLED" == "ENABLED" ]; then
        $CYCLE_STOP_USB_DEVICE
    fi

    # Execute all hal exit routines
    exit_run_in_hals

    # Disable logging console to logfile
    do_disable_console_logfile

    if [ $RUN_IN_TEST_FAIL -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

######################################################################
# Function:     rm_do_run_diag
# Purpose:      Run the main run modes diagnostic, displaying a menu
#               and allowing operator to choose test.
# Paramters:    none
# Returns:      none
######################################################################
rm_do_run_diag()
{
    do_run_in_mode
    RESULT="$?"
    runin_display_result_dialog "$RESULT"

    # Turn the charger back on before completely exiting...
    charger on
}


case "$1" in

    stop)
        vmsg "Exiting Run Modes"
        ;;

    cycle)
        vmsg "Starting Cycle Run-in Mode"
        enter_diag "Run-in Mode"
        run_modes_hal_init
        do_run_in_mode
        run_in_pass="$?"
        runin_display_result_dialog "$run_in_pass"
        run_modes_hal_exit
        exit_diag "Run-in Mode" 0
        ;;


    start|*)
        vmsg "Starting Run Modes"
        enter_diag "Run Modes"
        # Clear any previous diagnostic test results
        clear_diag_fail
        run_modes_hal_init
        rm_do_run_diag
        run_modes_hal_exit
        exit_diag "Run Modes" 0
        ;;

esac
