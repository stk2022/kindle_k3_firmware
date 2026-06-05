#!/bin/sh

#
# This is the FCT diagnostic test
# 

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Power HAL Functions
[ -f ${_POWER_HAL_FUNCTIONS} ] && . ${_POWER_HAL_FUNCTIONS}

# Keyboard Mappings
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Audio Hal for Audio Run Modes
[ -f ${_AUDIO_HAL_FUNCTIONS} ] && . ${_AUDIO_HAL_FUNCTIONS}

# Video HAL for VCOM Adjustment
[ -f ${_VIDEO_HAL_FUNCTIONS} ] && . ${_VIDEO_HAL_FUNCTIONS}

# WAN HAL for WAN power functions
[ -f ${_WAN_HAL_FUNCTIONS} ] && . ${_WAN_HAL_FUNCTIONS}

# FCT HAL
[ -f ${_FCT_HAL_FUNCTIONS} ] && . ${_FCT_HAL_FUNCTIONS}

# Gas Gauge HAL Functions
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

# Device Settings for dev_get_pcb_id()
[ -f ${_DEV_SETTINGS_HAL_FUNCTIONS} ] && . ${_DEV_SETTINGS_HAL_FUNCTIONS}

######################################################################
# Function:     display_fct_screen
# Purpose:      Display a screen informing operator what's going on,
#               giving them an oportunity to cancel the test in case
#               they entered it by accident.
# Paramters:    none
# Returns:      0 - Start test
#               1 - Test was cancelled
######################################################################
display_fct_screen()
{
    clear_screen
    banner="$PRODUCT_NAME FCT Diagnostic"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 8 "$base"
    ${DOUT} -n $? 4 "$banner"
    ${DOUT} -n 8 5 "$base"
    ${DOUT} -n 4 7 "This test is driven completely from the"
    ${DOUT} -n 4 9 "serial console."
    ${DOUT} -n 4 12 "To exit this screen manually and return to"
    ${DOUT} -n 4 14 "the main menu, press the $EXIT_KEY_LABEL key."
    ${DOUT} -n 4 17 "Otherwise, this screen will disappear once"
    ${DOUT} -n 4 19 "the fixture test is complete."
    ${DOUT} -n 4 25 "Press $EXIT_KEY_LABEL to exit the $PRODUCT_NAME FCT Diagnostic"
    ${DOUT} 4 27 "Fixture: Press $SUCCESS_KEY_LABEL to start the test now."

    while [ 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $EXIT_KEY)
                    return 1
                    ;;
                $SUCCESS_KEY)
                    return 0
                    ;;
                *)
                    ;;
            esac
        fi
    done
}

export FCT_BATT_CURRENT_DRAW=
export FCT_BATT_VOLTAGE=
export FCT_BATT_CAPACITY=

######################################################################
# Function:     fct_gather_device_information
# Purpose:      Gather up information about the device, including
#                   Device Serial Number --> DEVICE_SERIAL_NUMBER
#                   Device Panel Id -------> DEVICE_PANEL_ID
#                   Device PCB Id ---------> DEVICE_PCB_ID
#                   Batt Current Draw -----> FCT_BATT_CURRENT_DRAW
#                   Batt Voltage ----------> FCT_BATT_VOLTAGE
#                   Batt Capacity ---------> FCT_BATT_CAPACITY
# Paramters:    none
# Returns:      none
# Side Effect:  Loads up global variables noted above
######################################################################
fct_gather_device_information()
{
    dev_get_pcb_id

    if [ -f "$DEVICE_SERIAL_NUMBER_ENTRY" ]; then
        export DEVICE_SERIAL_NUMBER=`cat $DEVICE_SERIAL_NUMBER_ENTRY`
    else
        export DEVICE_SERIAL_NUMBER="uninitialized"
    fi
    if [ -f "$DEVICE_PANEL_ID_ENTRY" ]; then
        export DEVICE_PANEL_ID=`cat $DEVICE_PANEL_ID_ENTRY`
    else
        export DEVICE_PANEL_ID="uninitialized"
    fi

    export FCT_BATT_CURRENT_DRAW=`${BATTERY_CURRENT}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from current command"
        export FCT_BATT_CURRENT_DRAW="error"
    fi

    export FCT_BATT_VOLTAGE=`${BATTERY_VOLTAGE}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from voltage command"
        export FCT_BATT_VOLTAGE="error"
    fi

    export FCT_BATT_CAPACITY=`${BATTERY_CAPACITY}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from capacity command"
        export FCT_BATT_CAPACITY="error"
    fi
}


case "$1" in

    stop)
        vmsg "Exiting Power Diagnostic Test"
        return 0
        ;;

    cycle)
        vmsg "FCT Cycle Test not supported."
        return 0
        ;;

    start|*)
        vmsg "Starting FCT Diagnostic..."
        enter_diag "FCT"
        # Clear any previous diagnostic test results
        clear_diag_fail
        fct_hal_init
        do_run_fct

        # If everything worked, we'll never get here....

        fct_hal_exit
        exit_diag "FCT" 0
        did_diag_fail
        test_failed="$?"
        return $test_failed
        ;;
esac
