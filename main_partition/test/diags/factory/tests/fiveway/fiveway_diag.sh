#!/bin/sh
######################################################################
#
#  File:   fiveway_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/10/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the fiveway diagnostic.
#
#   Routines
#       do_test_haptic()        - Thump haptic device, have operator verify
#       fiveway_do_cycle_diag() - Run operator-free haptic diagnostic
#       fiveay_do_run_diag()    - Run fiveway diagnostic    
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# 5-way HAL Functions
[ -f ${_FIVEWAY_HAL_FUNCTIONS} ] && . ${_FIVEWAY_HAL_FUNCTIONS}


######################################################################
# Function:    do_test_haptic
# Purpose:     Test the haptic device by thumping it and having user
#               verify it worked.
# Paramters:   none
# Returns:     none
# Assumptions: none
# Side Effect: Sets subtest result for fiveway diagnostic
######################################################################
do_test_haptic()
{
    #
    # Put up common test banner
    #
    TRIGGER_KEY_LABEL=`fiveway_button_id_to_label "$HAPTIC_TRIGGER_KEY"`
    clear_screen
    ${DOUT} -n 13 4 "5-Way Haptic Response"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "Press the $TRIGGER_KEY_LABEL fiveway control"
    ${DOUT} -n 8 8 "to trigger the haptic response and"
    ${DOUT} -n 8 9 "cause it to vibrate."
    ${DOUT} -n 2 15 "Press $SUCCESS_KEY_LABEL if haptic device worked properly."
    ${DOUT} 2 17 "Press $FAILURE_KEY_LABEL if haptic device DID NOT work properly."
    DONE=0
    HAPTIC_RUN=0
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KBD_FIVEWAY_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
            $SUCCESS_KEY)
                if [ $HAPTIC_RUN -eq 1 ]; then
                    success "Fiveway Haptic"
                else
                    clear_screen
                    ${DOUT} -n 14 4 "5-Way Haptic Response"
                    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                    ${DOUT} -n 8 7 "You indicated success but never"
                    ${DOUT} -n 8 8 "triggered the haptic device."
                    ${DOUT} -n 8 11 "Failing haptic diagnostic due to"
                    ${DOUT} -n 8 12 "not having run the test."
                    ${DOUT} 8 16 "Press $FAILURE_KEY_LABEL to continue."
                    wait_for_key $FAILURE_KEY
                    failure "Fiveway Haptic"
                fi
                DONE=1
                ;;

            $FAILURE_KEY)
                failure "Fiveway Haptic"
                DONE=1
                ;;

            $HAPTIC_TRIGGER_KEY)
                fiveway_thump_haptic
                HAPTIC_RUN=1
                ;;

            *)
                vmsg "Wrong key "$KEY" pressed.."
                ;;
            esac
        fi
    done
}




######################################################################
# Function:     fiveway_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
fiveway_do_cycle_diag()
{
    vmsg "Starting 5-Way Diagnostic $1 Cycle Test"

    # Get cycle count
    FIVEWAY_CYCLE_COUNT=$1

    # Loop through auto-run test
    while [ $FIVEWAY_CYCLE_COUNT -ne 0 ]; do
        fiveway_thump_haptic
        FIVEWAY_CYCLE_COUNT=`expr $FIVEWAY_CYCLE_COUNT - 1`
    done
}


######################################################################
# Function:    fiveway_do_run_diag
# Purpose:     Iterate through each 5-way control, having operator 
#               press the control and verifying that the system sees 
#               the corresponding 5-way control pressed and released.
# Paramters:   name - string representing name of the control to press
# Returns:     none
# Assumptions: none
# Side Effect: none
######################################################################
fiveway_do_run_diag()
{
    #
    # Put up common test banner
    #
    clear_screen
    ${DOUT} -n 15 4 "5-Way Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    #
    # For each control on the 5-way, ask the user to press and release 
    # the control and verify that the system sees the control was pressed.
    #
    for control_id in $FIVEWAY_CONTROL_ID_LIST; do
        fiveway_do_test_control "$control_id"
    done

    
    # Test Haptic Response if device has a haptic component
    if [ -n "$HAS_HAPTIC" ] && [ $HAS_HAPTIC -eq 1 ]; then
        do_test_haptic
    fi
}


case "$1" in

    stop)
        vmsg "Exiting 5-Way Diagnostic Test"
        ;;

    cycle)
        vmsg "Starting 5-Way Diagnostic Cycle Test"
        fiveway_hal_init
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        fiveway_do_cycle_diag $cycle_count
        fiveway_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting 5-Way Diagnostic Test"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "5-Way"
        # Clear any previous diagnostic test results
        clear_diag_fail
        fiveway_hal_init
        fiveway_do_run_diag
        fiveway_hal_exit
        exit_diag "5-Way" $_status_screen_option
        ;;

esac
