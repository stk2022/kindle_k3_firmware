#!/bin/sh
##############################################################################
#
#  File:   gas_gauge_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the gas gauge diagnostic.
#
#   Constants
#       GAS_GAUGE_DISPLAY_TIME_AUTO_MODE    - Time to display info screen in cycle mode
#       BATTERY_CAPACITY_FAILURE            - Failed reading battery capacity
#       BATTERY_CURRENT_FAILURE             - Failed reading battery current draw
#       BATTERY_VOLTAGE_FAILURE             - Failed reading battery voltage
#       BATTERY_TEMPERATURE_FAILURE         - Failed reading battery temperature
#       BATTERY_CHARGE_STATUS_FAILURE       - Failed getting charger status
#       BATTERY_CHARGE_DRAW_CURRENT_FAILURE - Failed getting charger current draw
#       BATTERY_VOLTAGE_CHECK_FAILURE       - PMIC and Gas Gauge voltages are off
#
#   Routines
#       display_gas_gauge_failure_message() - Display gas gauge failure screen
#       display_gg_voltage_check_failure_message()  - Display voltage mismatch screen
#       do_display_gas_gauge_status()       - Read and display gas gauge values
#       gg_do_cycle_diag()                  - Execute test in no-operator (cycle) mode
#       gg_do_run_diag()                    - Run operator-acknowledge diagnostic
#
##############################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Gas Gauge HAL Functions
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

#
# Seconds to leave gas gauge info screen up before auto-dismiss in auto (cycle) mode
#
export GAS_GAUGE_DISPLAY_TIME_AUTO_MODE=1


#
# Error codes for gasgauge failure cases
#
BATTERY_CAPACITY_FAILURE=1
BATTERY_CURRENT_FAILURE=2
BATTERY_VOLTAGE_FAILURE=3
BATTERY_TEMPERATURE_FAILURE=4
BATTERY_CHARGE_STATUS_FAILURE=5
BATTERY_CHARGE_DRAW_CURRENT_FAILURE=6
BATTERY_VOLTAGE_CHECK_FAILURE=7


######################################################################
# Function:     display_gas_gauge_failure_message
# Purpose:      Display gas gauge failure screen
# Paramters:    none
# Returns:      none
# Side Effect:  Waits for user to acknowledge before returning
######################################################################
display_gas_gauge_failure_message()
{
    clear_screen
    ${DOUT} -n 13 4 "Gas Gauge Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 16 7 "FAILURE DETECTED"
    ${DOUT} -n 3 10 "A failure occurred reading the gas gauge."
    ${DOUT} -n 5 13 "CHECK DEVICE BATTERY FOR FAULT CONDITION."
    ${DOUT} 6 16 "Press $EXIT_KEY_LABEL to exit Gas Gauge Diagnostics."
    wait_for_key $EXIT_KEY
}


######################################################################
# Function:     display_gg_voltage_check_failure_message
# Purpose:      Display an "out-of-spec" message caused by PMIC and gas
#               gauge voltage readings not being within spec when compared
#               to each other.
# Paramters:    none
# Returns:      none
# Side Effect:  Waits for user to acknowledge before returning
######################################################################
display_gg_voltage_check_failure_message()
{
    # Get PMIC voltage and Gas Gauge voltage
    clear_screen
    ${DOUT} -n 13 4 "Gas Gauge Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 16 7 "FAILURE DETECTED"
    ${DOUT} -n 6 10 "The voltage read from the gas gauge chip"
    ${DOUT} -n 6 11 "was not within specification when compared"
    ${DOUT} -n 6 12 "to PMIC voltage (delta greater than $MAX_VOLTAGE_DELTA)."
    ${DOUT} -n 6 14 "PMIC Voltage      :  $BATTERY_FAILURE_PMIC_VOLTAGE mV"
    ${DOUT} -n 6 15 "Gas Gauge Voltage :  $BATTERY_FAILURE_GG_VOLTAGE mV"
    ${DOUT} -n 6 16 "Voltage Delta     :  $BATTERY_FAILURE_VOLTAGE_DELTA mV"
    ${DOUT} 6 18 "Press $EXIT_KEY_LABEL to exit Gas Gauge Diagnostics."
    wait_for_key $EXIT_KEY
}


######################################################################
# Function:     do_display_gas_gauge_status
# Purpose:      Read the various gas gauge values from the gas gauge
#               chip.  Compare the voltage read from gas gauge against
#               the voltage read from the PMIC and fail if the delta is
#               not within spec.  If voltage compare is good, display 
#               the main gas gauge screen.
# Paramters:    none
# Returns:      result - results of the test.  One of:
#       0 - Success
#       BATTERY_CAPACITY_FAILURE - failed reading capacity
#       BATTERY_VOLTAGE_FAILURE - failed reading voltage
#       BATTERY_CURRENT_FAILURE - failed reading current
#       BATTERY_TEMPERATURE_FAILURE - failed reading temp
#       BATTERY_CHARGE_STATUS_FAILURE - failed reading charge status
#       BATTERY_CHARGE_DRAW_CURRENT_FAILURE - failed reading current draw
#       BATTERY_VOLTAGE_CHECK_FAILURE -  Voltage compare against PMIC failed
#               
# Assumptions:  none
# Side Effect:  none
######################################################################
do_display_gas_gauge_status()
{
    FULL_UPDATE=$1
    CYCLE_COUNT=$2

    CAPACITY=`${BATTERY_CAPACITY}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from capacity command"
        return $BATTERY_CAPACITY_FAILURE
    fi

    VOLTAGE=`${BATTERY_VOLTAGE}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from voltage command"
        return $BATTERY_VOLTAGE_FAILURE
    fi

    CURRENT=`${BATTERY_CURRENT}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from current command"
        return $BATTERY_CURRENT_FAILURE
    fi

    TEMPERATURE=`${BATTERY_TEMPERATURE}`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from temperature command"
        return $BATTERY_TEMPERATURE_FAILURE
    fi

    CHARGE_SETTING=`charger_setting_text`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from charger_setting"
        return $BATTERY_CHARGE_STATUS_FAILURE
    fi

    CHARGE_DRAW_LIMIT=`charger_draw_limit`
    RES=$?
    if [ $RES -ne 0 ]; then
        vmsg "ERROR - Non-zero return from charger_draw_limit"
        return $BATTERY_CHARGE_DRAW_CURRENT_FAILURE
    fi

    # Get battery cycle information
    GG_BATTERY_CYCLE_COUNT=`gg_get_battery_cycle_info`
    GG_BATTERY_CYCLE_LEARNING_COUNT=`gg_get_battery_cycle_learning_info`
    GG_BATTERY_LMD=`gg_get_battery_lmd`
    #GG_BATTERY_TEMP=`gg_get_battery_temperature`
    GG_BATTERY_FLAGS=`gg_get_battery_flags`

    # Erase screen...
    if [ $FULL_UPDATE -eq 0 ]; then
        erase_line 7
        erase_line 8
        erase_line 9
        erase_line 10
        erase_line 11
        erase_line 12
        erase_line 13
        erase_line 14
    else
        clear_screen
    fi

    # Append mA to charge draw limit if it's a number and not On or Off...
    if [ $CHARGE_DRAW_LIMIT != "On" ] && [ $CHARGE_DRAW_LIMIT != "Off" ]; then
        CHARGE_DRAW_LIMIT="$CHARGE_DRAW_LIMIT mA"
    fi

    ${DOUT} -n 13 4 "Gas Gauge Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "Battery Capacity    : ${CAPACITY}Percent"
    ${DOUT} -n 8 8 "Battery Voltage     : $VOLTAGE mV"
    ${DOUT} -n 8 9 "Current Draw        : $CURRENT mA"
    ${DOUT} -n 8 10 "Current Draw Limit  : $CHARGE_DRAW_LIMIT"
    ${DOUT} -n 8 11 "Charger Mode        : $CHARGE_SETTING"
    ${DOUT} -n 8 12 "Battery Temperature : $TEMPERATURE degree F"
    ${DOUT} -n 8 13 "Charge Cycle Count  : $GG_BATTERY_CYCLE_COUNT"
    ${DOUT} -n 8 14 "Charge Cycle Learn  : $GG_BATTERY_CYCLE_LEARNING_COUNT"
    ${DOUT} -n 8 15 "Battery LMD         : $GG_BATTERY_LMD mAh"
    if [ "$cycle_count" -eq 0 ]; then
        ${DOUT} -n 8 16 "Battery Flags       : $GG_BATTERY_FLAGS"
        ${DOUT} -n 8 21 "Press R to refresh values..."
        ${DOUT} 8 23 "Press $EXIT_KEY_LABEL to exit Gas Gauge Diagnostics."
    else
        ${DOUT} 8 16 "Battery Flags       : $GG_BATTERY_FLAGS"
    fi
    return 0
}



######################################################################
# Function:     gg_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
gg_do_cycle_diag()
{
    vmsg "Starting Gas Gauge Diagnostic $1 Cycle Test"

    # Get cycle count
    GAS_GAUGE_CYCLE_COUNT=$1

    # Loop through auto-run test
    GG_ERR=0
    while [ $GAS_GAUGE_CYCLE_COUNT -ne 0 ] && [ $GG_ERR -eq 0 ]; do
        gg_do_run_diag 1
	GG_ERR=$?
        GAS_GAUGE_CYCLE_COUNT=`expr $GAS_GAUGE_CYCLE_COUNT - 1`
    done
}



######################################################################
# Function:     gg_do_run_diag
# Purpose:      Collect up all gas gauge information, display it on the
#               screen, and ask the operator to verify readings.
# Paramters:    Number of times to run the test.  If non-zero, this 
#               routine will not require operator acknowledgement.
# Returns:      0 - Test passed
#               1 - Test failed
# Side Effect:  Sets SUB_TEST_PASSED to 0 on failure
######################################################################
gg_do_run_diag()
{
    CYCLE_COUNT="$1"

    #
    # Verify the battery part number
    #
    if [ -n "$HAS_VERIFY_BATTERY_PART_NUMBER" ] && [ $HAS_VERIFY_BATTERY_PART_NUMBER -eq 1 ]; then
        gg_confirm_battery_id
        if [ $? -ne 0 ]; then
            failure "Battery Part Number Invalid"
            return 1
        else
            if [ $CYCLE_COUNT -eq 0 ]; then
                success "Battery Part Number Validated"
            fi
        fi
    fi


    #
    # Read and display the gas gauge information and wait for user
    # to hit the EXIT_KEY
    #
    GG_REFRESH=1
    GG_DONE=0
    GG_ERR=0
    GG_STATUS=0
    while [ $GG_DONE -ne 1 ]; do
        do_display_gas_gauge_status $GG_REFRESH $CYCLE_COUNT
        GG_STATUS=$?
        if [ $GG_STATUS -ne 0 ]; then
            GG_ERR=$GG_STATUS
            case "$GG_STATUS" in
                $BATTERY_VOLTAGE_CHECK_FAILURE)
                    failure "Voltage Compare Verification"
                    ;;
                $BATTERY_CAPACITY_FAILURE)
                    failure "Capacity Check"
                    ;;
                $BATTERY_VOLTAGE_FAILURE)
                    failure "Voltage Check"
                    ;;
                $BATTERY_CURRENT_FAILURE)
                    failure "Current Check"
                    ;;
                $BATTERY_TEMPERATURE_FAILURE)
                    failure "Temperature Check"
                    ;;
                $BATTERY_CHARGE_STATUS_FAILURE)
                    failure "Charger Setting Check"
                    ;;
                $BATTERY_CHARGE_DRAW_CURRENT_FAILURE)
                    failure "Current Draw Limit Check"
                    ;;
                *)
                    vmsg "Unknown error $GG_STATUS from do_display_gas_gauge_status"
                    failure "Gas Gauge General"
                    ;;
            esac
            # Only display failure dialog if NOT in cycle mode
            # if [ $CYCLE_COUNT -eq 0 ]; then
                if [ $GG_STATUS -eq $BATTERY_VOLTAGE_CHECK_FAILURE ]; then
                    display_gg_voltage_check_failure_message
                else
                    display_gas_gauge_failure_message
                fi
            # fi
            return $GG_STATUS
        fi

        if [ "$CYCLE_COUNT" -ne 0 ]; then
            sleep $GAS_GAUGE_DISPLAY_TIME_AUTO_MODE
            GG_DONE=1
        else
            GG_REFRESH=0
            EXIT_OK=0
            while [ $EXIT_OK -eq 0 ]; do
                KEY=`$GET_KEYBOARD_INPUT`
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    case "$KEY" in
                    $KEY_R)
                        # looping will cause values to update...
                        EXIT_OK=1
                        ;;

                    $EXIT_KEY)
                        GG_DONE=1
                        EXIT_OK=1
                        ;;

                    *)
                        # looping will cause values to update...
                        vmsg "Wrong key "$KEY" pressed.."
                        ;;
                    esac
                fi
            done
        fi
    done
    return $GG_ERR
}

case "$1" in

    stop)
        vmsg "Exiting Gas Gauge Diagnostic Test"
        return 0
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting Gas Gauge Diagnostic $cycle_count Cycle Test"
        gas_gauge_hal_init
        gg_do_cycle_diag $cycle_count
        gas_gauge_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting Gas Gauge Diagnostic Test"
        enter_diag "Gas Gauge"
        gas_gauge_hal_init

        # Clear any previous failures from gas gauge diagnostic
        # This fixes a false-failure case if "battery level adjust"
        # diag is aborted prior to this test being run.
        clear_diag_fail

        gg_do_run_diag 0
        test_failure_seen=$?
        if [ $test_failure_seen -eq 0 ]; then
            subtest_verify "   Gas Gauge Diagnostics"
        fi
        gas_gauge_hal_exit
        exit_diag "Gas Gauge"
        did_diag_fail
        test_failed="$?"
        return "$test_failed"
        ;;

esac
