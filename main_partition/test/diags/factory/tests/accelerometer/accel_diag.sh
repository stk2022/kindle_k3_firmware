#!/bin/sh
######################################################################
#
#  File:   accel_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/10/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the accelerometer diagnostic.
#
#   Routines
#       accel_do_run_diag() - Run the accelerometer diagnostic
#
######################################################################
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

# Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Accelerometer HAL Functions
[ -f ${_ACCEL_HAL_FUNCTIONS} ] && . ${_ACCEL_HAL_FUNCTIONS}


######################################################################
# Function:     accel_start_position
# Purpose:      Display an image to instruct the operator to put the 
#               device into the starting position for the test, and 
#               then press a key when ready.
# Paramters:    orientation - orientation to instruct operator to put
#                   device into.
#                   One of:
#                       ORIENTATION_UP
#                       ORIENTATION_FACE_UP
# Returns:      0 - Success
#               1 - Unknown starting orientation
#               2 - Can't find image file
######################################################################
accel_start_position()
{
    POSITION="$1"
    POSITION_STR=`accel_position_to_label $POSITION`
    do_local_echo "Turn the device $POSITION_STR"
    do_local_echo "Press $SUCCESS_KEY_LABEL when device is in the $POSITION_STR position."

    case "$POSITION" in
        $ORIENTATION_UP)
            _accel_image_file="$STARTING_UP_ACCELEROMETER_IMAGE"
            ;;
        $ORIENTATION_FACE_UP)
            _accel_image_file="$STARTING_FACE_UP_ACCELEROMETER_IMAGE"
            ;;
        *)
            echo "Unknown starting orientation $1"
            return 1
            ;;
    esac

    # If the file isn't there, complain now and return
    if ! [ -f $_accel_image_file ]; then
        echo "ERROR - Can't find image file $_accel_image_file"
        return 2;
    fi

    ${EIPS} -g "$_accel_image_file"
    wait_for_key $SUCCESS_KEY
    return 0
}


######################################################################
# Function:    accel_do_run_diag
# Purpose:     Have the operator drive the accelerometer through various
#              orientations.
# Paramters:   none
# Returns:     0 - passed
#              1 - failed
######################################################################
accel_do_run_diag()
{
    clear_screen

    # Test first domain
    for position in $ACCEL_ORIENTATION_LIST_D1; do
        accel_test_position "$position"
        if [ $? -eq 1 ]; then
            return 1
        fi
    done

    # Test second domain
    for position in $ACCEL_ORIENTATION_LIST_D2; do
        accel_test_position "$position"
        if [ $? -eq 1 ]; then
            return 1
        fi
    done
    return 0
}


######################################################################
# Function:     accel_display_no_entry_error
# Purpose:      Display a "Can't find the accelerometer proc entry"
#               dialog and require user to acknowledge via pressing
#               the exit key.
# Paramters:    none
# Returns:      none
######################################################################
accel_display_no_entry_error()
{
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    clear_screen
    ${DOUT} -n 11 4 "Accelerometer Diagnostics"
    ${DOUT} -n 8 5 "$base"
    center_text "FAILURE" 8 "$base"
    ${DOUT} -n $? 8 "FAILURE"
    banner="The $ACCELEROMETER_ENTRY entry could not be found."
    center_text "$banner" 8 "$base"
    ${DOUT} -n $? 11 "$banner" 
    banner="Press $EXIT_KEY_LABEL to exit the accelerometer test." 
    center_text "$banner" 8 "$base"
    ${DOUT} $? 15 "$banner"
    wait_for_key $EXIT_KEY
}


case "$1" in

    stop)
        vmsg "Exiting Accelerometer Diagnostic Test"
        ;;

    cycle)
        vmsg "Nothing to do for Accelerometer Cycle Diagnostic Test"
        return 0
        ;;

    start|*)
        vmsg "Starting Accelerometer Diagnostic Test"
        enter_diag "Accelerometer"
        # Clear any previous diagnostic test results
        clear_diag_fail
        accel_hal_init
        ACCEL_INIT_ERR="$?"
        if [ $ACCEL_INIT_ERR -eq 1 ]; then
            failure "Accelerometer proc entry is missing"
            accel_display_no_entry_error
        else
            accel_do_run_diag
        fi
        accel_hal_exit
        exit_diag "Accelerometer"
        ;;

esac
