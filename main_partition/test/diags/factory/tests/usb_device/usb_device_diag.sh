#!/bin/sh
######################################################################
#
#   File:   usb_device_diags.sh
#
#   Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#   Date:   07/18/08
#
#   Copyright 2008, Lab126, Inc.  All rights reserved.
#
#   Description:
#      USB Device diagnostic script for testing usb device mode.  
#
#   Routines
#       usb_do_cycle_diag()         - Run the test in no-operator mode
#       do_run_usb_device_diag()    - Run the usb device diagnostic test
#       wait_user_cancel()          - Display screen asking operator to verify
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# USB Hal Function...
[ -f ${_USB_HAL_FUNCTIONS} ] && . ${_USB_HAL_FUNCTIONS}


######################################################################
# Function:     usb_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we simply export the device volume.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
usb_do_cycle_diag()
{
    #
    # Export the USB volume...
    #
    do_export_usb_volumes "USB Device Mode Diagnostics"
}


######################################################################
# Function:     do_run_usb_device_diag
# Purpose:      Run the main usb device mode diagnostic test.  This
#               test exports the usb volume, tells the operator to
#               copy data to/from the volume and then verify the results.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED is cleared on any failure
######################################################################
do_run_usb_device_diag()
{
    #
    # Tell user to plug in USB, then export the usb volumes
    #
    do_export_usb_volumes "USB Device Mode Diagnostics"

    #
    # Wait for user to end the test
    #
    wait_user_cancel

    #
    # Unexport the volume
    #
    un_export_usb_volumes
}


######################################################################
# Function:     wait_user_cancel
# Purpose:      Dispaly the screen instructing the operator to copy
#               data to/from device and verify the results.
# Paramters:    none
# Returns:      none
# Side Effect:  Requires operator to acknowledge test results before
#               returning.
######################################################################
wait_user_cancel()
{
    clear_screen
    ${DOUT} -n 10 4 "USB Device Mode Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 8 "The USB volume has been exported."
    ${DOUT} -n 2 11 "Copy data between the USB exported volume"
    ${DOUT} -n 3 12 "and the PC.  Verify checksum of the copies."
    ${DOUT} 2 15 "Press $SUCCESS_KEY_LABEL to stop test and return to diag menu."

    wait_for_key $SUCCESS_KEY
    clear_screen

    ${DOUT} -n 10 4 "USB Device Mode Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 2 7 "Press $SUCCESS_KEY_LABEL if exported USB volume worked properly."
    ${DOUT} 2 9 "Press $FAILURE_KEY_LABEL if exported volume DID NOT work."

    DONE=0
    while [ $DONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
            $SUCCESS_KEY)
                success "USB Device Mode Diagnostic Test"
                DONE=1;
                ;;

            $FAILURE_KEY)
                failure "USB Device Mode Diagnostic Test"
                DONE=1;
                ;;

            *)
                vmsg "Wrong key "$KEY" pressed.."
                ;;
            esac
        fi
    done
    clear_screen
}



case "$1" in

    cycle_stop|stop)
        vmsg "Exiting USB Device Mode Diagnostics Test"
        un_export_usb_volumes
        usb_hal_exit
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting USB Device Mode Diagnostics $cycle_count Cycle Test"
        usb_hal_init
        usb_do_cycle_diag $cycle_count
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting USB Device Mode Diagnostics Test"
        enter_diag "USB Device Mode"
        # Clear any previous diagnostic test results
        clear_diag_fail
        usb_hal_init
        do_run_usb_device_diag
        usb_hal_exit
        exit_diag "USB Device Mode"
        ;;

esac
