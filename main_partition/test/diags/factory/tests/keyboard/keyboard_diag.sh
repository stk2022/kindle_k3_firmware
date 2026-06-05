#!/bin/sh
######################################################################
#
#  File:   keyboard_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the keyboard diagnostic.
#
#   Routines
#       keyboard_do_run_diag()    - Run the keyboard diagnostic
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Keyboard HAL functions
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}


######################################################################
# Function:    test_key
# Purpose:     While watching for key activity, ask the operator
#               to press and release the specified key and verify that
#               the system sees the key pressed and released.
# Paramters:   key - Character for key to press and release (i.e. 'A')
# Returns:     result - result of testing the key.  One of:
#               0 - Test Failed
#               1 - Test Passed
#               2 - User Canceled
# Assumptions: none
# Side Effect: SUB_TEST_PASS is set based on result
######################################################################
test_key()
{
    vmsg "test_key($1)"

    # Get target key to test
    TEST_KEY="$1"
    if [ $TEST_KEY -eq $EXIT_KEY ]; then
        LOCAL_EXIT_KEY=$ALTERNATE_EXIT_KEY
    else
        LOCAL_EXIT_KEY=$EXIT_KEY
    fi
    LOCAL_EXIT_KEY_LABEL=`keycode_to_label $LOCAL_EXIT_KEY`

    # Print instructions into existing template window already showing
    # Use spaces at end of string to clean up previous line...
    TEST_KEY_LABEL=`keycode_to_label $TEST_KEY`
    erase_line 8
    erase_line 12
    ${DOUT} -n 8 8 "Press and release the $TEST_KEY_LABEL key now."
    ${DOUT} 6 12 "Press $LOCAL_EXIT_KEY_LABEL to exit keyboard diagnostics."

    # Get the key.
    # FIXME - NOTE that this does not test both pressed and released
    DONE=0
    local_key_test_passed=1
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_ONLY_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $LOCAL_EXIT_KEY)
                    local_key_test_passed=2
                    failure "Operator canceled keyboard diagnostic"
                    ;;
                $TEST_KEY)
                    success "$TEST_KEY_LABEL Key Diagnostic"
                    ;;
                *)
                    FAIL_KEY_LABEL=`keycode_to_label $KEY`
                    failure "$TEST_KEY_LABEL Key Diagnostic, expected $TEST_KEY, saw $FAIL_KEY_LABEL ($KEY)"
                    local_key_test_passed=0
            esac
            DONE=1
        fi
    done
    return $local_key_test_passed
}


######################################################################
# Function:     test_alt_key
# Purpose:      Test the ALT key.  This process is different from the
#               other key tests because the Nell and Turing keyboard
#               drivers WILL NOT return that the ALT key was pressed
#               UNLESS another key was also hit.  Thus, we need to make
#               this test a multi-key-press test.
# Paramters:    none
# Returns:      0 - success
#               1 - failure
#               2 - user cancelled
# Side Effect:  SUB_TEST_PASS is set based on result
######################################################################
test_alt_key()
{
    vmsg "test_alt_key()"

    # Test the ALT key...
    TEST_KEY="$KEY_ALT"
    SECOND_KEY="$KEY_Z"

    if [ $TEST_KEY = $EXIT_KEY ]; then
        TEMP_EXIT_KEY=$SECOND_KEY
    else
        TEMP_EXIT_KEY=$EXIT_KEY
    fi

    # Tell the user what to do...
    TEST_KEY_LABEL=`keycode_to_label $TEST_KEY`
    SECOND_KEY_LABEL=`keycode_to_label $SECOND_KEY`
    TEMP_EXIT_KEY_LABEL=`keycode_to_label $TEMP_EXIT_KEY`
    clear_screen
    ${DOUT} -n 13 4 "Keyboard Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "Press the $TEST_KEY_LABEL key, then"
    ${DOUT} -n 10 9 "press and release the $SECOND_KEY_LABEL key, and then"
    ${DOUT} 8 11 "release the $TEST_KEY_LABEL key."
    ${DOUT} 8 15 "Press $TEMP_EXIT_KEY_LABEL to exit the keyboard diagnostic."
    # Get the key.
    DONE=0
    _exit_status=1
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_ONLY_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $TEST_KEY)
                    success "$TEST_KEY_LABEL Key Diagnostic"
                    _exit_status=0
                    DONE=1
                    ;;
                *)
                    failure "$TEST_KEY_LABEL Key Diagnostic (saw $KEY)"
                    _exit_status=1
                    DONE=1
                    ;;
                $TEMP_EXIT_KEY)
                    _exit_status=2
                    DONE=1
                    ;;
            esac
        else
            echo "GET_KEYBOARD_ONLY_INPUT returned $RETVAL"
        fi
    done
    return ${_exit_status}
}


######################################################################
# Function:     keyboard_do_run_diag
# Purpose:      Walk through the device list of keys to test, asking
#               operator to press and release each one and verify that
#               the system sees the keys pressed and released.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED is cleared on any failure
######################################################################
keyboard_do_run_diag()
{
    # First, test the ALT key because the process is a little
    # different than the other keys...
    test_alt_key

    # Display the keyboard diagnostic template screen
    clear_screen
    ${DOUT} -n 13 4 "Keyboard Diagnostics"
    ${DOUT} 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    # For each key in our test array, verify it works...
    for key in $KEY_TEST_ARRAY; do
        vmsg "Testing "$key" key.."
        test_key "$key"
        RETVAL=$?
        case "$RETVAL" in
            0|2)    # Test Failed or Operator Cancelled
                return
                ;;
            1|*)    # Test Passed
                ;;
        esac
    done
}


case "$1" in

    stop)
        vmsg "Exiting Keyboard Diagnostic Test"
        ;;

    cycle)
        vmsg "Nothing to do for Keyboard Cycle Diagnostic Test"
        return 0
        ;;
        
    start|*)
        vmsg "Starting Keyboard Diagnostic Test"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "Keyboard"
        # Clear any previous diagnostic test results
        clear_diag_fail
        keyboard_hal_init
        keyboard_do_run_diag
        keyboard_hal_exit
        exit_diag "Keyboard" $_status_screen_option
        ;;

esac
