#!/bin/sh
######################################################################
#
#  File:   wan_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the WAN diagnostic.
#
#   Constants
#       WAN_DISPLAY_TIME_AUTO_MODE  - Seconds to leave WAN info screen up
#                                       in cycle (run-in) mode
#
#   Routines
#       display_wan_status()    - Display target WAN power mode
#       do_run_wan_power_diag() - Main power diagnostic menu
#       wan_do_cycle_diag()     - Run the no-operator WAN diagnostic mode
#       wan_do_run_diag()       - Run the main WAN diagnostic      
#	wan_display_rf_disable_entry_failure - Inform user that the 
#					"RF Disable" proc entry is missing.
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Wan HAL Functions
[ -f ${_WAN_HAL_FUNCTIONS} ] && . ${_WAN_HAL_FUNCTIONS}

#
# Amount of time to delay while WAN info screen is up before 
#   auto-dismiss in auto (cycle) mode
#
export WAN_DISPLAY_TIME_AUTO_MODE=2


######################################################################
# Function:     display_wan_status
# Purpose:      Display a screen telling the user that we're putting
#               the WAN into a particular power mode.
# Paramters:    mode - power mode we're putting wan into
#               One of:
#                   WAN_POWER_ON
#                   WAN_POWER_OFF
#                   WAN_POWER_ON_TPH
# Returns:      none
######################################################################
display_wan_status()
{
    case "$1" in

        $WAN_POWER_ON)
            status="ON"
            ;;

        $WAN_POWER_OFF)
            status="OFF"
            ;;

        $WAN_POWER_ON_TPH)
            status="TPH Sleep"
            ;;

        *)
            status="Unknown state"
            ;;
    esac

    clear_screen
    ${DOUT} -n 14 4 "WAN Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 2 8 "Setting WAN power to $status...                         "
    ${DOUT} 2 10 "This screen will auto-dismiss when the"
    ${DOUT} 4 12 "WAN power operation is complete."
}


######################################################################
# Function:    do_run_wan_power_diag
# Purpose:     Display a menu for controlling various WAN power operations.
#               Allow user to put WAN in different power modes, have them
#               measure the power, and then confirm whether mode worked.
# Paramters:   none
# Returns:     none
# Side Effect: SUB_TEST_PASSED is cleared on any failure
######################################################################
do_run_wan_power_diag()
{
    DONE=0
    while [ $DONE -eq 0 ]; do
        #
        # The following example displays a screen and waits for the user
        # to hit the EXIT_KEY
        #
        clear_screen
        ${DOUT} -n 14 4 "WAN Diagnostics"
        ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 12 8 "$MENU_ITEM_1)  Power On WAN"
        ${DOUT} -n 12 10 "$MENU_ITEM_2)  Power Off WAN"
        ${DOUT} -n 12 12 "$MENU_ITEM_3)  Put WAN into TPH Sleep Mode"
        ${DOUT} 8 15 "Press $EXIT_KEY_LABEL to exit WAN Diagnostics."
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then

        #
        # Process key request
        case "$KEY" in

        $MENU_ITEM_1)
            vmsg "Powering ON WAN..."
            display_wan_status $WAN_POWER_ON
            wan_power $WAN_POWER_ON 0
            status="ON"
            ;;

        $MENU_ITEM_2)
            vmsg "Powering OFF WAN..."
            display_wan_status $WAN_POWER_OFF
            wan_power $WAN_POWER_OFF 0
            status="OFF"
            ;;

        $MENU_ITEM_3)
            vmsg "Putting WAN into TPH sleep mode..."
            display_wan_status $WAN_POWER_ON_TPH
            wan_power $WAN_POWER_ON_TPH 0
            status="TPH Mode"
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
            ${DOUT} -n 14 4 "WAN Diagnostics"
            ${DOUT} -n 12 5 "~~~~~~~~~~~~~~~~~~~~~"
            ${DOUT} -n 2 8 "Finished setting WAN power to $status.                     "
            ${DOUT} -n 2 8 "Press $SUCCESS_KEY_LABEL if WAN operations worked properly."
            ${DOUT} 2 10 "Press $FAILURE_KEY_LABEL if WAN operations DID NOT work properly."
            IDONE=0
            while [ $IDONE -eq 0 ]; do
                KEY=`$GET_KEYBOARD_INPUT`
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    case "$KEY" in
                        $SUCCESS_KEY)
                            success "WAN Diagnostic Test"
                            IDONE=1
                            ;;

                        $FAILURE_KEY)
                            failure "WAN Diagnostic Test"
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
# Function:     wan_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
wan_do_cycle_diag()
{
    vmsg "Starting Wan Diagnostic $1 Cycle Test"

    # Get cycle count
    WAN_CYCLE_COUNT="$1"

    # Loop through auto-run test
    while [ "$WAN_CYCLE_COUNT" -ne 0 ]; do
        # Run the WAN modem info test in "no operator verify" mode...
        wan_modem_info_test 1

        WAN_CYCLE_COUNT=`expr $WAN_CYCLE_COUNT - 1`
    done
}


######################################################################
# Function:    wan_do_run_diag
# Purpose:     WAN system diagnostic.  This diagnostic will query the
#               modem for properties and have user verify.
# Paramters:   none
# Returns:     none
######################################################################
wan_do_run_diag()
{
    # Run the WAN modem info test in "operator verify" mode...
    wan_modem_info_test 0
}


######################################################################
# Function:    wan_display_rf_disable_entry_failure
# Purpose:     Inform user that the "RF Disable" proc entry is missing.
# Paramters:   none
# Returns:     none
######################################################################
wan_display_rf_disable_entry_failure()
{
    clear_screen
    ${DOUT} -n 14 4 "WAN Diagnostics"
    ${DOUT} -n 12 5 "~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 8 "The proc entry $WAN_RF_DISABLE_PROC_ENTRY"
    ${DOUT} -n 4 10 "to disable RF could not be found."
    ${DOUT} 4 14 "Press $SUCCESS_KEY_LABEL to continue."
    wait_for_key $SUCCESS_KEY
}


case "$1" in

    stop)
        vmsg "Exiting WAN Diagnostic Test"
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting Wan Diagnostic $cycle_count Cycle Test"
        wan_hal_init
        res="$?"
        if [ "$res" -ne 0 ]; then
            case "$res" in
                1)  wan_display_rf_disable_entry_failure; ;;
                *)  ;;
            esac
        else
            wan_do_cycle_diag $cycle_count
        fi
        wan_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting WAN Diagnostic Test"
        enter_diag "WAN"
        # Clear any previous diagnostic test results
        clear_diag_fail
        wan_hal_init
        res="$?"
        if [ "$res" -ne 0 ]; then
            case "$res" in
                1) wan_display_rf_disable_entry_failure; ;;
                *) ;;
            esac
        else
            wan_do_run_diag
        fi
        wan_hal_exit
        exit_diag "WAN"
        ;;

esac
