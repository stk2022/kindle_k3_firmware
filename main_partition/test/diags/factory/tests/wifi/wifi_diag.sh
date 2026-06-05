#!/bin/sh
######################################################################
#
#  File:   wifi_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the WIFI diagnostic.
#
#   Constants
#       WIFI_DISPLAY_TIME_AUTO_MODE  - Seconds to leave WIFI info screen up
#                                       in cycle (run-in) mode
#
#   Routines
#       display_wifi_status()    - Display target wifi power mode
#       do_run_wifi_power_diag() - Main power diagnostic menu
#       wifi_do_cycle_diag()     - Run the no-operator wifi diagnostic mode
#       wifi_do_run_diag()       - Run the main wifi diagnostic      
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# WIFI HAL Functions
[ -f ${_WIFI_HAL_FUNCTIONS} ] && . ${_WIFI_HAL_FUNCTIONS}

#
# Amount of time to delay while WIFI info screen is up before 
#   auto-dismiss in auto (cycle) mode
#
export WIFI_DISPLAY_TIME_AUTO_MODE=2



######################################################################
# Function:     display_wifi_status
# Purpose:      Display a screen telling the user that we're putting
#               the wifi into a particular power mode.
# Paramters:    mode - power mode we're putting wifi into
#               One of:
#                   WIFI_POWER_ON
#                   WIFI_POWER_OFF
# Returns:      none
######################################################################
display_wifi_status()
{
    case "$1" in

        $WIFI_POWER_ON)
            status="ON"
            ;;

        $WIFI_POWER_OFF)
            status="OFF"
            ;;

        *)
            status="Unknown state"
            ;;
    esac

    clear_screen
    ${DOUT} -n 14 4 "WIFI Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 2 8 "Setting WIFI power to $status...                         "
    ${DOUT} 2 10 "This screen will auto-dismiss when the"
    ${DOUT} 4 12 "WIFI power operation is complete."
}



######################################################################
# Function:    do_run_wifi_power_diag
# Purpose:     Display a menu for controlling various W power operations.
#              Allow user to put WIFI in different power modes, have them
#              measure the power, and then confirm whether mode worked.
# Paramters:   none
# Returns:     none
# Side Effect: SUB_TEST_PASSED is cleared on any failure
######################################################################
do_run_wifi_power_diag()
{
    DONE=0
    while [ $DONE -eq 0 ]; do
        #
        # The following example displays a screen and waits for the user
        # to hit the EXIT_KEY
        #
        clear_screen
        ${DOUT} -n 14 4 "WIFI Power Diagnostics"
        ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 12 8 "$MENU_ITEM_1)  Power On WIFI"
        ${DOUT} -n 12 10 "$MENU_ITEM_2)  Power Off WIFI"
        ${DOUT} 8 15 "Press $EXIT_KEY_LABEL to exit WIFI Diagnostics."
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then

        #
        # Process key request
        case "$KEY" in

        $MENU_ITEM_1)
            vmsg "Powering ON WIFI..."
            display_wifi_status $WIFI_POWER_ON
            wifi_power $WIFI_POWER_ON 0
            status="ON"
            ;;

        $MENU_ITEM_2)
            vmsg "Powering OFF WIFI..."
            display_wifi_status $WIFI_POWER_OFF
            wifi_power $WIFI_POWER_OFF 0
            status="OFF"
            ;;

        $EXIT_KEY)
            # User pressed the target key, verify visual via asking operator
            DONE=1
            ;;

        *)
            DONE=1
            ;;

        esac


        # If not done yet, report status...
        if [ $DONE -eq 0 ]; then
            clear_screen
            ${DOUT} -n 14 4 "WIFI Diagnostics"
            ${DOUT} -n 12 5 "~~~~~~~~~~~~~~~~~~~~~"
            ${DOUT} -n 2 8 "Finished setting WIFI power to $status.                     "
            ${DOUT} -n 2 10 "Press $SUCCESS_KEY_LABEL if WIFI operations worked properly."
            ${DOUT} 2 12 "Press $FAILURE_KEY_LABEL if WIFI operations DID NOT work properly."
            IDONE=0
            while [ $IDONE -eq 0 ]; do
                KEY=`$GET_KEYBOARD_INPUT`
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    case "$KEY" in
                        $SUCCESS_KEY)
                            success "WIFI Diagnostic Test"
                            IDONE=1
                            ;;

                        $FAILURE_KEY)
                            failure "WIFI Diagnostic Test"
                            IDONE=1
                            ;;

                        *)
                            ;;
                    esac
                fi
            done
        fi
      fi
    done
}


######################################################################
# Function:     wifi_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
wifi_do_cycle_diag()
{
    vmsg "Starting WIFI Diagnostic $1 Cycle Test"

    # Get cycle count
    WIFI_CYCLE_COUNT="$1"

    # Loop through auto-run test
    while [ "$WIFI_CYCLE_COUNT" -ne 0 ]; do
        # Run the WIFI modem info test in "no operator verify" mode...
        wifi_do_run_diag 1

        WIFI_CYCLE_COUNT=`expr $WIFI_CYCLE_COUNT - 1`
    done
}


######################################################################
# Function:     wifi_do_run_diag
# Purpose:      WIFI system diagnostic.  This diagnostic will query the
#               modem for properties and have user verify.
# Parameters:   cycle mode
#                   0 - operator driven, can display ack screens
#                   1 - cycle mode, no operator, disable ack screens
# Returns:      0 - Wifi chip responding properly
#               1 - Wifi chip didn't respond properly
######################################################################
wifi_do_run_diag()
{
    # Run the WIFI modem info test in "operator verify" mode...
    # This call will power on the wifi
    wifi_verify_chip_alive $1
    if [ $? -eq 0 ]; then
        # Don't log successes during cycle (run-in) mode
        if [ $1 -ne 1 ]; then
            success "WIFI chip is responding."
        fi
        _exit_code=0
    else
        failure "WIFI chip is not responding"
        _exit_code=1
    fi

    return $_exit_code
}



case "$1" in

    stop)
        vmsg "Exiting WIFI Diagnostic Test"
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting WIFI Diagnostic $cycle_count Cycle Test"
        wifi_hal_init
        res="$?"
        if [ "$res" -ne 0 ]; then
            echo "wifi_hal_init() failure"
        else
            wifi_do_cycle_diag $cycle_count
        fi
        wifi_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting WIFI Diagnostic Test"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "WIFI"
        # Clear any previous diagnostic test results
        clear_diag_fail
        wifi_hal_init
        res="$?"
	    if [ "$res" -ne 0 ]; then
			echo "wifi_hal_init() failure"
	    else
            wifi_do_run_diag 1
	    fi
        wifi_hal_exit
        exit_diag "WIFI" $_status_screen_option
        ;;

esac
