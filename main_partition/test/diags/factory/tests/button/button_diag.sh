#!/bin/sh
######################################################################
#
#  File:   button_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/10/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the button diagnostic.
#
#   Routines
#       button_do_run_diag()    - Run the button diagnostic
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Button HAL Functions
[ -f ${_BUTTON_HAL_FUNCTIONS} ] && . ${_BUTTON_HAL_FUNCTIONS}

######################################################################
# Function:    button_do_run_diag
# Purpose:     Iterate through each button in the BUTTON_ID_LIST, 
#              having the operator press the button and verify that 
#               the system sees the button pressed and released.
# Paramters:   name - string representing name of the button to press
# Returns:     none
# Side Effect: SUB_TEST_PASS is cleared on any failure
######################################################################
button_do_run_diag()
{
    #
    # For each button on the device, ask the user to press and release 
    # the button and verify that the system sees the button was pressed.
    #
    clear_screen

    #
    # For each button on the device, ask the user to press and release
    # the button and verify that the system sees the button was pressed.
    #
    ${DOUT} -n 14 4 "Button Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    # Test all buttons in main list
    for id in $BUTTON_ID_LIST; do
        do_test_button "$id" 0
    done

    # Test volume buttons if they're separate
    if [ -n "$HAS_VOLUME_BUTTON_DRIVER" ] && [ $HAS_VOLUME_BUTTON_DRIVER -eq 1 ]; then
        for id in $VOLUME_BUTTON_ID_LIST; do
            do_test_button "$id" 1
        done
    fi

}


case "$1" in

    stop)
        vmsg "Exiting Button Diagnostic Test"
        ;;

    cycle)
        vmsg "Nothing to do for Button Cycle Diagnostic Test"
        return 0
        ;;

    start|*)
        vmsg "Starting Button Diagnostic Test"
        enter_diag "Button"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        # Clear any previous diagnostic test results
        clear_diag_fail
        button_hal_init
        button_do_run_diag
        button_hal_exit
        exit_diag "Button" $_status_screen_option
        ;;

esac
