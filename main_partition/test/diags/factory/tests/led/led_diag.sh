#!/bin/sh
######################################################################################
#
#  File:   led_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/10/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the LED diagnostic.
#
#   Routines
#       led_do_cycle_diag()             - Run the run-in led diagnostic (no operator)
#       led_display_blinking_screen()   - Display led blinking screen
#       led_do_blink()                  - Blink specified led specified number of times
#       led_do_run_diag()               - Run the main led diagnostic test
#
######################################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# LED HAL Functions
[ -f ${_LED_HAL_FUNCTIONS} ] && . ${_LED_HAL_FUNCTIONS}

# Gas Gauge HAL for is_charger_on()
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

# Keyboard HAL for keycode_to_label()
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}


#
# Delay times to leave LED on/off in auto mode
#
export LED_OFF_TIME_AUTO_MODE=1
export LED_ON_TIME_AUTO_MODE=1

#
# Number of times to blink each led as part of the led diagnostics
#
export LED_BLINK_TEST_COUNT=3

######################################################################
# Function:     led_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
led_do_cycle_diag()
{
    vmsg "Starting LED Diagnostic $1 Cycle Test"

    # Perform any pre-test setup in silent mode
    led_do_prepare_for_test 0

    # Get cycle count
    LED_CYCLE_COUNT="$1"

    # Give user status...
    clear_screen
    ${DOUT} -n 15 4 "LED Run-In Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    # Verify we can light LED
    can_light_led
    LED_READY=$?
    if [ $LED_READY -eq 0 ]; then
        ${DOUT} -n 8 7 "USB power was not detected.  The LED"
        ${DOUT} -n 8 9 "diagnostic requires the device to be"
        ${DOUT} -n 8 11 "plugged into external power."
        ${DOUT} 8 13 "Aborting LED Cycle Test."
        sleep 4
        led_do_cleanup_from_test
        return
    fi

    # Loop through auto-run test
    while [ $LED_CYCLE_COUNT -ne 0 ]; do

        # Update count in dialog
        erase_line 20
        ${DOUT} -n 11 12 "...$LED_CYCLE_COUNT blink cycle tests left..."

        # Test all LED's in the test list
        for id in $LED_ID_LIST; do

            # Test the LED
            led_name=`led_id_to_label $id`
            vmsg "Blinking the $led_name LED..."

            # Update status in dialog
            erase_line 8
            ${DOUT} 8 8 "Blinking the $led_name LED now..."

            # Turn ON LED
            set_led $id "ON"
            RETVAL=$?
            if [ $RETVAL -ne 0 ]; then
                if [ "$LED_ENABLED_CHARGER" -eq 1 ]; then
                    charger off
                fi
                led_do_cleanup_from_test
                return $RETVAL
            fi
        
            # Delay...
            sleep $LED_ON_TIME_AUTO_MODE

            # Test Off
            set_led $id "OFF"
            RETVAL=$?
            if [ $RETVAL -ne 0 ]; then
                if [ "$LED_ENABLED_CHARGER" -eq 1 ]; then
                    charger off
                fi
                led_do_cleanup_from_test
                return $RETVAL
            fi

            # Delay...
            sleep $LED_OFF_TIME_AUTO_MODE
        done
        # Decrement our loop counter
        LED_CYCLE_COUNT=$(($LED_CYCLE_COUNT - 1));
    done

    led_do_cleanup_from_test
}


######################################################################
# Function:     led_display_blinking_screen
# Purpose:      Display the "Blinking the ... led" screen banner
# Paramters:    Name of led that's blinking
# Returns:      none
######################################################################
led_display_blinking_screen()
{
    led_name="$1"
    ${DOUT} -n 18 4 "LED Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    erase_line 7
    ${DOUT} 8 7 "Blinking the ${led_name} LED now...       "
}


######################################################################
# Function:     led_do_blink
# Purpose:      Blink the led the requested number of times
# Paramters:    id - id of led to blink
#               count - number of times to blink the led on/of
# Returns:      0 - test completed successfully
#               1 - user exited test
# Assumptions:  none
# Side Effect:  none
######################################################################
led_do_blink()
{
    id="$1"
    count="$2"

    while [ $count -gt 0 ]; do
        # Blink LED
        do_verify_led $id "ON" 0
        if [ "$?" -eq 1 ]; then
            return 1
        fi
        sleep 1
        do_verify_led $id "OFF" 0
        if [ "$?" -eq 1 ]; then
            return 1
        fi
        sleep 1
        let count-=1
    done
    return 0
}


do_blink_led_test()
{
    # Clear the screen
    clear_screen

    # Test all LED's in the test list
    for id in $LED_ID_LIST; do

        # Test the LED
        led_name=`led_id_to_label $id`
        vmsg "Testing the $led_name LED..."

        # Inform user which led we're blinking...
        led_display_blinking_screen "${led_name}"

        # Blink the LED
        led_do_blink $id $LED_BLINK_TEST_COUNT
        if [ "$?" -eq 1 ]; then
            is_charger_on
            ON=$?
            if [ $ON -eq 1 ]; then
                set_led $LED_1 "ON"
            else
                set_led $LED_1 "OFF"
            fi

            # Perform any post-test cleanup
            led_do_cleanup_from_test

            return 1
        fi
    done

    # Ask user to verify results...
    clear_screen
    ${DOUT} -n 18 4 "LED Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "The LEDs should have just blinked."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if all the LEDs blinked properly.  "
    ${DOUT} 4 12 "Press $FAILURE_KEY_LABEL if the LEDs DID NOT blink properly.  "
    DONE=0
    EXIT_RESULT=0
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    success "LED Diagnostic Test"
                    DONE=1;
                    ;;

                $FAILURE_KEY)
                    failure "LED Diagnostic Test"
                    EXIT_RESULT=1
                    DONE=1;
                    ;;

                *)
                    vmsg "Wrong key $KEY pressed.."
                    ;;
            esac
        fi
    done
    return $EXIT_RESULT
}


led_debug_menu()
{
    # Define menu options
    LED_1_ON_MENU_ITEM=$MENU_ITEM_1
    LED_1_OFF_MENU_ITEM=$MENU_ITEM_2
    LED_2_ON_MENU_ITEM=$MENU_ITEM_3
    LED_2_OFF_MENU_ITEM=$MENU_ITEM_4
    DISABLE_AUTOCHARGE_MENU_ITEM=$MENU_ITEM_5
    CLEAR_ICHRG_MENU_ITEM=$MENU_ITEM_6
    LED_BLINK_TEST_MENU_ITEM=$MENU_ITEM_7

    # Display LED test options
    clear_screen
    print_center_text "LED Diagnostics" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 8 4

    # Draw On/Off options for LED 1
    led_name=`led_id_to_label $LED_1`
    text=`keycode_to_label $LED_1_ON_MENU_ITEM`
    ${DOUT} -n 8 8 "$text) $led_name LED On"
    text=`keycode_to_label $LED_1_OFF_MENU_ITEM`
    ${DOUT} -n 8 10 "$text) $led_name LED Off"

    # Draw On/Off options for LED 2
    led_name=`led_id_to_label $LED_2`
    text=`keycode_to_label $LED_2_ON_MENU_ITEM`
    ${DOUT} -n 8 12 "$text) $led_name LED On"
    text=`keycode_to_label $LED_2_OFF_MENU_ITEM`
    ${DOUT} -n 8 14 "$text) $led_name LED Off"

    #text=`keycode_to_label $DISABLE_AUTOCHARGE_MENU_ITEM`
    #${DOUT} -n 8 16 "$text) Disable autocharge"
    #text=`keycode_to_label $CLEAR_ICHRG_MENU_ITEM`
    #${DOUT} -n 8 18 "$text) Clear ichrg fields"

    # Draw Blink suite test option
    text=`keycode_to_label $LED_BLINK_TEST_MENU_ITEM`
    ${DOUT} -n 8 20 "$text) Perform LED Blink Test"

    # Tell user how to exit, then get user response
    ${DOUT} 4 24 "Press $EXIT_KEY_LABEL to exit the LED test."
    DONE=0
    while [ $DONE -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $DISABLE_AUTOCHARGE_MENU_ITEM) echo "Disable Autocharge"; $SET_DISABLE_AUTOCHARGE;  ;;
                $CLEAR_ICHRG_MENU_ITEM)     echo "Clear ichrg"; $SET_CLR_ICHRG;  ;;
                $LED_1_ON_MENU_ITEM)        echo "LED 1 ON"; $SET_LED1_ON;  ;;
                $LED_1_OFF_MENU_ITEM)       echo "LED 1 OFF"; $SET_LED1_OFF; ;;
                $LED_2_ON_MENU_ITEM)        echo "LED 2 ON"; $SET_GREEN_MAX_BRIGHT; $SET_LED2_ON;  ;;
                $LED_2_OFF_MENU_ITEM)       echo "LED 2 OFF"; $SET_LED2_OFF; ;;
                $LED_BLINK_TEST_MENU_ITEM)  do_blink_led_test; ;;
                $EXIT_KEY)                  DONE=1; ;;
                *) vmsg "Wrong key $KEY pressed.."; ;;
            esac
        fi
    done
}


######################################################################
# Function:     led_do_run_diag
# Purpose:      Run the main led diagnostic test.  Walk through the
#               LED_ID_LIST and test each led in the list.
# Paramters:    none
# Returns:      0 - Test passed
#               1 - Test failed
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
led_do_run_diag()
{
    # Perform any pre-test setup in operator mode
    led_do_prepare_for_test 1

    # Run the blink test
    do_blink_led_test
    _exit_status="$?"

    # Perform any post-test cleanup
    led_do_cleanup_from_test

    return $_exit_status
}

case "$1" in

    stop)
        vmsg "Exiting LED Diagnostic Test"
        return 0
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count="$2"
        else
            cycle_count=1
        fi
        vmsg "Starting LED Diagnostic $cycle_count Cycle Test"
        led_hal_init
        led_do_cycle_diag "$cycle_count"
        led_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting LED Diagnostic Test"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "LED"
        # Clear any previous diagnostic test results
        clear_diag_fail
        led_hal_init
        led_do_run_diag
        _led_diag_result="$?"
        led_hal_exit
        exit_diag "LED" $_status_screen_option
        did_diag_fail
        test_failed="$?"
        return $test_failed
        ;;

esac
