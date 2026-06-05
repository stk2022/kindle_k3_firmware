#!/bin/sh

#
# This is the Power diagnostic test
#

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Power HAL Functions
[ -f ${_POWER_HAL_FUNCTIONS} ] && . ${_POWER_HAL_FUNCTIONS}

# Keyboard Mappings
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Gasgauge Hal for Battery Information
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

# Audio Hal for Audio Run Modes
[ -f ${_AUDIO_HAL_FUNCTIONS} ] && . ${_AUDIO_HAL_FUNCTIONS}

# Video HAL for VCOM Adjustment
[ -f ${_VIDEO_HAL_FUNCTIONS} ] && . ${_VIDEO_HAL_FUNCTIONS}

# WAN HAL for wan_power
[ -f ${_WAN_HAL_FUNCTIONS} ] && . ${_WAN_HAL_FUNCTIONS}


#
# Delay time for dialogs in auto/cycle mode
#
export POWER_DISPLAY_TIME_AUTO_MODE=2

# Define menu selection keys
if [ "x$HAS_WAN" == "x1" ]; then
    POWER_WAN_ON_RUN_KEY=$KEY_Q
    POWER_WAN_OFF_RUN_KEY=$KEY_W
    POWER_WAN_TPH_SLEEP_KEY=$KEY_E
    POWER_WAN_OFF_SLEEP_KEY=$KEY_U
    POWER_VERIFY_WAN_TPH_SLEEP_KEY=$KEY_I
else
    POWER_SLEEP_KEY=$KEY_U
    POWER_WAN_ON_RUN_KEY=500
    POWER_WAN_OFF_RUN_KEY=501
    POWER_WAN_TPH_SLEEP_KEY=502
    POWER_VERIFY_WAN_TPH_SLEEP_KEY=503
fi
POWER_HALT_SLEEP_KEY=$KEY_T
POWER_VCOM_ADJUST_KEY=$KEY_Y


######################################################################
# Function:     do_display_battery_info
# Purpose:      Collect and display various pieces of battery information
# Paramters:    full_update : whether to perform a full update
#                   0 - Don't do full update (i.e. no clear_screen)
#                   1 - Do full update
#               cycle_count : number of times to run test
# Returns:      Result of gathering battery information.  
#   One of:
#       0 - Success
#       BATTERY_CAPACITY_FAILURE - failed reading capacity
#       BATTERY_VOLTAGE_FAILURE - failed reading voltage
#       BATTERY_CURRENT_FAILURE - failed reading current
#       BATTERY_TEMPERATURE_FAILURE - failed reading temp
#       BATTERY_CHARGE_STATUS_FAILURE - failed reading charge status
#       BATTERY_CHARGE_DRAW_CURRENT_FAILURE - failed reading current draw
######################################################################
do_display_battery_info()
{
    FULL_UPDATE=$1
    CYCLE_COUNT=$2

    # Clear the screen
    if [ $FULL_UPDATE -eq 0 ]; then
        erase_line 7
        erase_line 8
        erase_line 9
        erase_line 10
        erase_line 11
        erase_line 12
    else
        clear_screen
    fi

    #
    # Gather up the battery information
    #
    CAPACITY=`${BATTERY_CAPACITY}`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting battery capacity"
        return $BATTERY_CAPACITY_FAILURE
    fi

    VOLTAGE=`${BATTERY_VOLTAGE}`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting battery voltage"
        return $BATTERY_VOLTAGE_FAILURE
    fi

    CURRENT=`${BATTERY_CURRENT}`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting current draw"
        return $BATTERY_CURRENT_FAILURE
    fi

    TEMPERATURE=`${BATTERY_TEMPERATURE}`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting battery temperature"
        return $BATTERY_TEMPERATURE_FAILURE
    fi

    CHARGE_SETTING=`charger_setting_text`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting charger setting"
        return $BATTERY_CHARGE_STATUS_FAILURE
    fi

    CHARGE_DRAW_LIMIT=`charger_draw_limit`
    RES=$?
    if [ $RES -ne 0 ]; then
        failure "Return value $RES getting charger draw limit"
        return $BATTERY_CHARGE_DRAW_CURRENT_FAILURE
    fi

    # Print the banner and information
    ${DOUT} -n 13 4 "Battery Information"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 6 "Battery Capacity    : ${CAPACITY}Percent"
    ${DOUT} -n 8 7 "Battery Voltage     : $VOLTAGE"
    ${DOUT} -n 8 8 "Current Draw        : $CURRENT"
    ${DOUT} -n 8 9 "Current Draw Limit  : $CHARGE_DRAW_LIMIT"
    ${DOUT} -n 8 10 "Charger Mode        : $CHARGE_SETTING"
    ${DOUT} 8 11 "Battery Temperature : $TEMPERATURE"

    return 0
}


######################################################################
# Function:     display_power_menu
# Purpose:      Display the options menu for power diagnostic
# Paramters:    clear_screen - whether to clear screen first
#                   0 - don't clear screen
#                   1 - clear screen first
# Returns:      none
######################################################################
display_power_menu()
{
    DFU="$1"

    # Display some battery info, full update, no automatic mode...
    do_display_battery_info $DFU 0
    ${DOUT} -n 15 16 "$PRODUCT_NAME Power Modes"
    ${DOUT} -n 8 17 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $POWER_WAN_ON_RUN_KEY`
        ${DOUT} -n 10 18 "$text) WAN ON with Audio ON"
        text=`keycode_to_label $POWER_WAN_OFF_RUN_KEY`
        ${DOUT} -n 10 19 "$text) WAN OFF with Audio ON"
        text=`keycode_to_label $POWER_WAN_TPH_SLEEP_KEY`
        ${DOUT} -n 10 20 "$text) System Sleep with WAN in TPH"
        text=`keycode_to_label $POWER_WAN_OFF_SLEEP_KEY`
        ${DOUT} -n 10 21 "$text) System Sleep with WAN OFF"
        line_number=22
    else
        text=`keycode_to_label $POWER_SLEEP_KEY`
        ${DOUT} -n 10 19 "$text) System Sleep"
        line_number=20
    fi
    text=`keycode_to_label $POWER_HALT_SLEEP_KEY`
    ${DOUT} -n 10 $line_number "$text) Shipping Power Mode"
    let line_number++
    text=`keycode_to_label $POWER_VCOM_ADJUST_KEY`
    ${DOUT} -n 10 $line_number "$text) VCOM Adjustment"
    let line_number++

    if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $POWER_VERIFY_WAN_TPH_SLEEP_KEY`
        ${DOUT} -n 10 $line_number "$text) Verify TPH System Sleep Current"
        let line_number++
    fi

    let line_number++
    ${DOUT} -n 4 $line_number "Press $EXIT_KEY_LABEL to exit $PRODUCT_NAME Power Diagnostic"
    let line_number+=2
    ${DOUT} 4 $line_number "Press the space bar to refresh battery info."
}


######################################################################
# Function:     display_tph_sleep_verify_results
# Purpose:      Display the test results from the TPH sleep current
#               verification test.  If in test mode, allow user a few
#               seconds to cancel the test.  If not in test mode,
#               require operator to acknowledge PASS/FAIL results.
# Paramters:    0 - failed - tph current was out-of-range
#               1 - passed - tph current in acceptable range
# Returns:      none
######################################################################
display_tph_sleep_verify_results()
{
    # Give the user the results
    clear_screen
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
    print_center_text "TPH Power Verification" "$base" 8 4
    if [ "$1" -eq 1 ]; then
        center_text "PASS" 8 "$base"
        ${DOUT} -n $? 9 "PASS"
        ${DOUT} -n 8 13 "Current draw of $TPH_CURRENT_DRAW mA is acceptable."
    else
        center_text "FAIL" 8 "$base"
        ${DOUT} -n $? 9 "FAIL"
        ${DOUT} -n 8 13 "Current draw of $TPH_CURRENT_DRAW mA is too high."
    fi
    banner="Press $EXIT_KEY_LABEL to continue."
    center_text "$banner" 8 "$base"
    ${DOUT} $? 17 "Press $EXIT_KEY_LABEL to continue."
    wait_for_key $EXIT_KEY
}

######################################################################
# Function:     do_run_power_diag
# Purpose:      Main routine for running power diagnostic.  It displays
#               the main power diagnostic menu and runs any power
#               sub-diagnostic tests based on operator request.
#               The menu contains items for the following:
#                   1) WAN On, Audio On, run mode
#                   2) WAN Off, Audio On, run mode
#                   3) System Sleep with WAN in TPH
#                   4) System sleep with WAN OFF
#                   5) Shipping Power Mode
#                   6) VCOM Adjustment
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED will get set 0 on any failures
######################################################################
do_run_power_diag()
{
    vmsg "do_run_power_diag()"

	# Dump possible return character if entry from serial port (avoids double-draw)
	dump_char

    #
    # Get the requested test from user
    #
    REDRAW=1
    DRPG_DONE=0
    while [ $DRPG_DONE -ne 1 ]; do
        display_power_menu ${REDRAW}
        REDRAW=0;
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $POWER_VERIFY_WAN_TPH_SLEEP_KEY)
                    KEEP_LOOPING=$TPH_VERIFY_RETRY_MAX 
                    _PASS_COUNT=0
                    export TPH_CURRENT_DRAW=0
                    charger off
                    # Turn the early battery read mechanism on, we need it
                    if [ -f $TPH_SLEEP_CURRENT_READ_CONTROL_ENTRY ]; then
                        echo 0 > $TPH_SLEEP_CURRENT_READ_CONTROL_ENTRY
                    else
                        do_local_echo "TPH current reading control entry missing."
                    fi
                    while [ $KEEP_LOOPING -gt 0 ]; do
                        wan_power $WAN_POWER_TPH 1
                        drpg_name=`get_power_name_from_mode_id $POWER_SLEEP_WAN_TPH`
                        display_tph_wake_message "$drpg_name" $AUTO_VERIFY_TPH_SLEEP_TIME
                        echo -n $AUTO_VERIFY_TPH_SLEEP_TIME > "$DEVICE_RTC_WAKEUP_ENTRY"
                        device_power_state $POWER_SLEEP_WAN_TPH 1
                        verify_tph_power_readings
                        _pass_res=$?
                        if [ $_pass_res -eq 1 ]; then
                            # test passed, exit retry loop
                            KEEP_LOOPING=0
                            _PASS_COUNT=1
                        elif [ "x$ENABLE_TPH_VERIFY_RETRY" == "x1" ]; then
                            let KEEP_LOOPING--
                        else
                            # We're not supporting retrying on failure, so exit now
                            KEEP_LOOPING=0
                        fi
                        wan_power $WAN_POWER_OFF 1
                    done
                    # Turn the early battery read mechanism off, we're done
                    if [ -f $TPH_SLEEP_CURRENT_READ_CONTROL_ENTRY ]; then
                        echo 1 > $TPH_SLEEP_CURRENT_READ_CONTROL_ENTRY
                    fi
                    if [ $_PASS_COUNT -ge 1 ]; then
                        success "TPH Sleep Current"
                    else
                        failure "TPH Sleep Current"
                    fi
                    display_tph_sleep_verify_results $_PASS_COUNT
                    REDRAW=1;
                    ;;
                $POWER_WAN_TPH_SLEEP_KEY)
                    wan_power $WAN_POWER_TPH 1
                    drpg_name=`get_power_name_from_mode_id $POWER_SLEEP_WAN_TPH`
                    display_wake_message "$drpg_name"
                    device_power_state $POWER_SLEEP_WAN_TPH 1
                    verify_power_readings "$drpg_name"
                    wan_power $WAN_POWER_OFF 1
                    REDRAW=1;
                    ;;
                $POWER_SLEEP_KEY)
                    drpg_name=`get_power_name_from_mode_id $POWER_SLEEP`
                    display_wake_message "$drpg_name"
                    device_power_state $POWER_SLEEP_WAN_OFF 1
                    verify_power_readings "$drpg_name"
                    REDRAW=1;
                    ;;
                $POWER_WAN_OFF_SLEEP_KEY)
                    if ! [ `cat /proc/wan/power` == "0" ]; then
                        wan_power $WAN_POWER_OFF 1
                    else
                        echo "Wan is already off..."
                    fi
                    drpg_name=`get_power_name_from_mode_id $POWER_SLEEP_WAN_OFF`
                    display_wake_message "$drpg_name"
                    device_power_state $POWER_SLEEP_WAN_OFF 1
                    verify_power_readings "$drpg_name"
                    REDRAW=1;
                    ;;
                $POWER_WAN_ON_RUN_KEY)
                    # Start wan and audio
                    wan_power $WAN_POWER_ON 1
                    audio_start_sound $CHANNEL_ALL ${RUN_IN_SPEAKER_AUDIO_VOLUME}
                    enable_headphones
                    enable_speakers
                    set_speaker_volume ${RUN_IN_SPEAKER_AUDIO_VOLUME}

                    # Tell operator to take measurements
                    drpg_name=`get_power_name_from_mode_id $POWER_ACTIVE_WAN_ON`
                    display_measure_power_message "$drpg_name"
                    device_power_state $POWER_ACTIVE_WAN_ON 1
                    verify_power_readings "$drpg_name"

                    # Turn the WAN and Audio off
                    audio_stop_sound
                    wan_power $WAN_POWER_OFF 1
                    REDRAW=1;
                    ;;
                $POWER_WAN_OFF_RUN_KEY)
                    # Power off wan and start a sound playing
                    if ! [ `cat /proc/wan/power` == "0" ]; then
                        wan_power $WAN_POWER_OFF 1
                    else
                        echo "Wan is already off..."
                    fi
                    audio_start_sound $CHANNEL_ALL ${RUN_IN_SPEAKER_AUDIO_VOLUME}
                    enable_headphones
                    enable_speakers
                    set_speaker_volume ${RUN_IN_SPEAKER_AUDIO_VOLUME}

                    # Tell operator to take measurement
                    drpg_name=`get_power_name_from_mode_id $POWER_ACTIVE_WAN_OFF`
                    display_measure_power_message "$drpg_name"
                    device_power_state $POWER_ACTIVE_WAN_OFF 1
                    verify_power_readings "$drpg_name"

                    # Turn off audio
                    audio_stop_sound
                    REDRAW=1;
                    ;;
                $POWER_HALT_SLEEP_KEY)
                    display_measure_halt_power_message
                    do_device_pre_reboot_cleanup
                    power_shipping_mode
                    ;;
                $POWER_VCOM_ADJUST_KEY)
                    video_do_adjust_vcom
                    if [ "$?" -eq 0 ]; then
                        success "VCOM Adjusted"
                    else
                        failure "VCOM Adjusted"
                    fi
                    REDRAW=1;
                    ;;
                $KEY_SPACE | $KEY_R)
				    # Dump possible return character if entry from serial port (avoids double-draw)
				    dump_char
                    vmsg "Spacebar pressed, updating battery info..."
                    REDRAW=1;
                    ;;
                $EXIT_KEY)
                    DRPG_DONE=1
                    ;;
                *)
                    REDRAW=0;
                    ;;
            esac
        fi
    done
}



######################################################################
# Function:     display_measure_halt_power_message
# Purpose:      Display battery information and display the 
#               "Putting into shipping mode" screen for the 
#               "Shipping Power Mode" diagnostic.
# Paramters:    none
# Returns:      none
######################################################################
display_measure_halt_power_message()
{
    # Display some battery info, full update, no automatic mode...
    do_display_battery_info 1 0
    ${DOUT} -n 15 16 "Power Diagnostics"
    ${DOUT} -n 8 17 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 18 "Putting device into shipping mode."
    ${DOUT} -n 8 21 "Wait for screen to clear and then"
    ${DOUT} -n 8 22 "measure the current draw."
    ${DOUT} -n 6 30 "Press the device power button to reboot"
    ${DOUT} 6 32 "device back into the diagnostics menu."
}


######################################################################
# Function:     display_measure_power_message
# Purpose:      Display the battery information and an informative
#               message about what mode we're currently in, instructing
#               the operator to take power measurements now.  Requires
#               operator to select the success key to continue.
# Paramters:    String for the power mode we're currently in
# Returns:      none
######################################################################
display_measure_power_message()
{
    # Display some battery info, full update, no automatic mode...
    do_display_battery_info 1 0

    IDONE=0
    while [ $IDONE -eq 0 ]; do
        ${DOUT} -n 15 16 "Power Diagnostics"
        ${DOUT} -n 8 17 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 8 18 "The device is now running in the "
        ${DOUT} -n 8 20 "$1 power mode."
        ${DOUT} -n 8 24 "Measure the current draw now."
        ${DOUT} -n 4 28 "Press $SUCCESS_KEY_LABEL to continue the test."
        ${DOUT} 4 30 "Press the space bar to refresh battery info."

        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    ;;
                $KEY_SPACE | $KEY_R)
                    # Dump possible return character from serial port
                    dump_char
                    vmsg "Spacebar pressed, updating battery info..."
                    do_display_battery_info 0 0
                    ;;
                *)
                    ;;
            esac
        fi
    done
}


######################################################################
# Function:     display_tph_wake_message
# Purpose:      Displays a message to the operator telling them that
#               we're putting the device into the requested power mode
#               and that we will auto-wake it back up in a short time.
# Parameters:   mode - string representing sleep mode
#               snooze - Sleep time before device auto-wakes in seconds
# Returns:      none
######################################################################
display_tph_wake_message()
{
    # If user wants to continue, test next power state
    clear_screen
    ${DOUT} -n 15 4 "Power Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 8 "Putting the device into the "
    ${DOUT} -n 8 10 "$1 power mode."
    ${DOUT} 4 14 "The device will wake back up in $2 seconds..."
}


######################################################################
# Function:     display_wake_message
# Purpose:      Displays a message to the operator telling them that
#               we're putting the device into the requested power mode
#               and to take the power measurement and then press the
#               power key to wake the device back up.  This routine
#               returns without waiting for any operator response (i.e.
#               caller must field key presses)
# Paramters:    String for the power mode we're going into
# Returns:      none
######################################################################
display_wake_message()
{
    
    # If user wants to continue, test next power state
    clear_screen
    ${DOUT} -n 15 4 "Power Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 8 "Putting the device into the "
    ${DOUT} -n 8 10 "$1 power mode."
    ${DOUT} -n 4 14 "Measure the current draw and then press the"
    ${DOUT} -n 4 16 "Power key to wake the device and continue"
    ${DOUT} 4 18 "the test."
}


get_sleep_current_in_floating_point_format()
{
    let ma=$1
    let mAp=$ma/1000
    let uAp=$ma%1000
    if [ $uAp -lt 0 ]; then
        let uAp*=-1
    fi

    echo $mAp.$uAp

}
######################################################################
# Function:     verify_tph_power_readings
# Purpose:      Read the current draw and see if it's within acceptable
#               range, indicating PASS or FAIL accordingly.
# Parameters:   none
# Returns:      1 - Passed - current within spec
#               0 - Failed - current draw out-of-spec
# Side Effect:  Sets TPH_CURRENT_DRAW with sleep current reading
######################################################################
verify_tph_power_readings()
{
    # Get the current draw.  Since we just woke up and if we're fast
    # enough, this should be the sleep current (gas gauge hasn't updated yet)
    if [ -f "$SLEEP_CURRENT_READ_ENTRY" ]; then
        TPH_CURRENT_DRAW_RAW=`cat $SLEEP_CURRENT_READ_ENTRY`
        let tph_current_draw_uA=$TPH_CURRENT_DRAW_RAW/2
        # convert to positive number
        if [ $tph_current_draw_uA -lt 0 ]; then
            let tph_current_draw_uA*=-1
        fi 
        
        # Check to see if we're in valid range
        export CURRENT_DRAW_TPH_SLEEP_MAX_uA=`expr $CURRENT_DRAW_TPH_SLEEP_MAX \* 1000`
        export TPH_CURRENT_DRAW=`get_sleep_current_in_floating_point_format $tph_current_draw_uA`

        if [ $tph_current_draw_uA -le $CURRENT_DRAW_TPH_SLEEP_MAX_uA ]; then
           do_local_echo "Passed TPH Sleep Current of $TPH_CURRENT_DRAW mA"
           return 1
        else
           do_local_echo "Failed TPH Sleep Current of $TPH_CURRENT_DRAW mA"
           return 0
        fi

    else
        _CURRENT=`${TPH_BATTERY_CURRENT}`
        do_local_echo "$SLEEP_CURRENT_READ_ENTRY not found"
        do_local_echo "Using gasgauge-util method instead."
        # Strip resulting string down to just a number
        # use the old way
        export TPH_CURRENT_DRAW=`echo $_CURRENT | sed -e "s/[^0-9]//g;"`
        if [ $TPH_CURRENT_DRAW -le $CURRENT_DRAW_TPH_SLEEP_MAX ]; then
           do_local_echo "Passed TPH Sleep Current of $TPH_CURRENT_DRAW mA"
           return 1
        else
           do_local_echo "Failed TPH Sleep Current of $TPH_CURRENT_DRAW mA"
           return 0
        fi

    fi
}


verify_power_readings()
{
    #
    # We just finished a power mode, ask user for the results
    #
    clear_screen
    ${DOUT} -n 15 4 "Power Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 8 "The device just exited from the"
    ${DOUT} -n 8 10 "$1 power mode."
    ${DOUT} -n 2 14 "Press $SUCCESS_KEY_LABEL if power consumption was as expected."
    ${DOUT} 2 16 "Press $FAILURE_KEY_LABEL if consumption was WORSE than expected."

    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    success "Power $1 Diagnostic"
                    IDONE=1;
                    ;;

                $FAILURE_KEY)
                    failure "Power $1 Diagnostic"
                    IDONE=1;
                    ;;

                *)
                    vmsg "Wrong key "$KEY" pressed.."
                    ;;
            esac
        fi
    done
}


######################################################################
# Function:     power_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
power_do_cycle_diag()
{
    vmsg "power_do_cycle_diag($1)"

    # Get cycle count
    POWER_CYCLE_COUNT=$1

    # Loop through auto-run test
    while [ $POWER_CYCLE_COUNT -ne 0 ]; do

        for POWER_MODE in $POWER_AUTO_MODE_LIST; do
            STATE_TEXT=`get_power_name_from_mode_id $POWER_MODE`

            # If user wants to continue, test next power state
            if [ "$EXIT_STATUS" -eq 0 ]; then
                clear_screen
                ${DOUT} -n 15 4 "Power Diagnostics"
                ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                ${DOUT} -n 8 8 "Putting the device into the "
                ${DOUT} 8 10 "$STATE_TEXT power mode."

                device_power_state $POWER_MODE 1

                #
                # Delay in this power mode
                #
                sleep $POWER_DISPLAY_TIME_AUTO_MODE
            else
                return
            fi
        done
    
        # Update loop counter
        POWER_CYCLE_COUNT=`expr $POWER_CYCLE_COUNT - 1`
    done
}


######################################################################
# Function:     do_run_iterate_power_diag
# Purpose:      Walks through the list of power modes to test (held
#               in POWER_MODE_LIST), informing the user what we're
#               doing and driving the device into each test power
#               mode.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED is set to 0 on any failure
######################################################################
do_run_iterate_power_diag()
{
    vmsg "do_run_iterate_power_diag()"

    for POWER_MODE in $POWER_MODE_LIST; do

        STATE_TEXT=`get_power_name_from_mode_id $POWER_MODE`

        #
        # We're ready to go to sleep
        #
        clear_screen
        ${DOUT} -n 15 4 "Power Diagnostics"
        ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 8 8 "Press $SUCCESS_KEY_LABEL to start the"
        ${DOUT} -n 8 10 "$STATE_TEXT"
        ${DOUT} -n 8 12 "power diagnostic test..."
        ${DOUT} 8 15 "Press $EXIT_KEY_LABEL to exit Power Diagnostics."
        READY=0
        while [ $READY -eq 0 ]; do
            KEY=`$GET_KEYBOARD_INPUT`
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                case "$KEY" in
                    $SUCCESS_KEY)
                        READY=1;
                        EXIT_STATUS=0
                        ;;
                    $EXIT_KEY)
                        READY=1;
                        EXIT_STATUS=1
                        ;;
                    *)
                        ;;
                esac
            fi
        done

        # If user wants to continue, test next power state
        if [ $EXIT_STATUS -eq 0 ]; then
            clear_screen
            ${DOUT} -n 15 4 "Power Diagnostics"
            ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            ${DOUT} -n 8 8 "Putting the device into the "
            ${DOUT} -n 8 10 "$STATE_TEXT power mode."
            ${DOUT} -n 4 14 "Measure the current draw and then press the"
            ${DOUT} -n 4 16 "power key to wake the device and continue"
            ${DOUT} 4 18 "the test."

            device_power_state $POWER_MODE 1

            #
            # We just woke up, get result status from user
            #
            clear_screen
            ${DOUT} -n 15 4 "Power Diagnostics"
            ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            ${DOUT} -n 8 8 "The device just woke up from the"
            ${DOUT} -n 8 10 "$STATE_TEXT power mode."
            ${DOUT} -n 2 14 "Press $SUCCESS_KEY_LABEL if power consumption was as expected."
            ${DOUT} 2 16 "Press $FAILURE_KEY_LABEL if consumption was WORSE than expected."

            IDONE=0
            while [ $IDONE -eq 0 ]; do
                KEY=`$GET_KEYBOARD_INPUT`
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    case "$KEY" in
                        $SUCCESS_KEY)
                            success "Power $STATE_TEXT Diagnostic"
                            IDONE=1;
                            ;;

                        $FAILURE_KEY)
                            failure "Power $STATE_TEXT Diagnostic"
                            IDONE=1;
                            ;;

                        *)
                            vmsg "Wrong key "$KEY" pressed.."
                            ;;
                    esac
                fi
            done
        else
            return
        fi
    done
}


case "$1" in

    stop)
        vmsg "Exiting Power Diagnostic Test"
        return 0
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting Power Diagnostic $cycle_count Cycle Test"
        power_hal_init
        power_do_cycle_diag $cycle_count
        power_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting Power Diagnostic Test"
        enter_diag "Power"
        # Clear any previous diagnostic test results
        clear_diag_fail
        power_hal_init
        do_run_power_diag
        power_hal_exit
        exit_diag "Power"
        did_diag_fail
        test_failed="$?"
        return $test_failed
        ;;

esac
