#!/bin/sh
######################################################################
#
#   File:   dev_settings.sh
#
#   Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#   Date:   09/10/08
#
#   Copyright 2008, Lab126, Inc.  All rights reserved.
#
#   Description:
#       Contains various device setting utilities.  While it's not
#   actually a diagnostic, it is used by the factory on the production
#   line to configure various HW and OS settings.
#
#   
#   Routines
#       gather_device_information()     - Gather device info from system
#       device_set_panel_id()           - Write panel id to NOR
#       device_set_pcb_id               - Write pcb id to NOR
#       device_set_serial_number        - Write serial number to NOR
#       do_set_eink_panel_id            - Get panel id from operator, write to NOR
#       do_set_serial_number            - Get serial number from operator, write to NOR
#       do_set_pcb_id                   - Get pcb id from operator, write to NOR
#       verify_user_wants_to_set_ids    - Verify operator to use serial port for input
#       do_run_dev_settings_diag        - Display main device settings menu, field requests
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Video HAL for video_do_adjust_vcom() and video_do_update_waveform()
[ -f ${_VIDEO_HAL_FUNCTIONS} ] && . ${_VIDEO_HAL_FUNCTIONS}

# Keyboard HAL for keycode_to_label()
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Device Settings HAL
_DEV_SETTINGS_HAL_INCLUDED=
[ -f ${_DEV_SETTINGS_HAL_FUNCTIONS} ] && . ${_DEV_SETTINGS_HAL_FUNCTIONS}

# Accelerometer Calibration Function....
[ -f ${_ACCEL_HAL_FUNCTIONS} ] && . ${_ACCEL_HAL_FUNCTIONS}


#
# MAC Address
#
export DEVICE_MAC_ADDRESS="11:22:33:44:55:66"

#
# Main Device Settings Menu Items
#
DEV_SET_SERIAL_NUMBER_MENU_ITEM=$MENU_ITEM_1

# Panel ID
if [ -n "$HAS_SETABLE_PANEL_ID" ] && [ $HAS_SETABLE_PANEL_ID -eq 1 ]; then
    DEV_SET_PANEL_ID_MENU_ITEM=$MENU_ITEM_2
else
    # Use value that doesn't correspond to key
    DEV_SET_PANEL_ID_MENU_ITEM=510
fi

# PCBA ID
DEV_SET_PCB_ID_MENU_ITEM=$MENU_ITEM_3

# PCB Config Flag
if [ -n "$HAS_SETABLE_PCB_CONFIG" ] && [ $HAS_SETABLE_PCB_CONFIG -eq 1 ]; then
    DEV_SET_PCB_CONFIG_MENU_ITEM=$MENU_ITEM_4
else
    DEV_SET_PCB_CONFIG_MENU_ITEM=511
fi

# Update Waveform
DEV_UPDATE_WAVEFORM_MENU_ITEM=$MENU_ITEM_5

# Calibrate Accellerometer
if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
    DEV_CALIBRATE_ACCEL_MENU_ITEM=$MENU_ITEM_6
else
    # Use value that doesn't correspond to key
    DEV_CALIBRATE_ACCEL_MENU_ITEM=512
fi

# Set MAC Address and Manufacturer Code
if [ -n "$HAS_MAC_ADDRESS" ] && [ $HAS_MAC_ADDRESS -eq 1 ]; then
    DEV_MAC_ADDRESS_MENU_ITEM=$MENU_ITEM_7
    DEV_MANUF_CODE_MENU_ITEM=$MENU_ITEM_8
else
    # Use value that doesn't correspond to key
    DEV_MAC_ADDRESS_MENU_ITEM=513
    DEV_MANUF_CODE_MENU_ITEM=514
fi

# Display serial number barcode
DEV_DISPLAY_BARCODE_SN_MENU_ITEM=$MENU_ITEM_9


######################################################################
# Function:     gather_device_information
# Purpose:      Gather up information about the device, including
#                   Device Serial Number --> DEVICE_SERIAL_NUMBER
#                   Device Panel Id -------> DEVICE_PANEL_ID
#                   Device PCB Id ---------> DEVICE_PCB_ID    
#                   Accelerometer Offsets -->ACCEL_X_OFFSET, ACCEL_Y_OFFSET,
#                                               ACCEL_Z_OFFSET
#                   DEVICE_MAC_ADDRESS ----> DEVICE_MAC_ADDRESS
#                   DEVICE_MANUF_CODE----> DEVICE_MANUF_CODE
# Paramters:    none
# Returns:      none
# Side Effect:  Loads up global variables noted above
######################################################################
gather_device_information()
{
	# Load DEVICE_SERIAL_NUMBER
	dev_get_serial_number

    # Load DEVICE_PANEL_ID
    video_get_panel_id

    dev_get_pcb_id
    
    # Get accelerometer data, if present...
    if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
        # Get acelerometer offsets
        accel_do_get_offsets
    fi

    # Get MAC Address
    if [ -n "$HAS_MAC_ADDRESS" ] && [ $HAS_MAC_ADDRESS -eq 1 ]; then
        dev_get_mac_address
        dev_get_manuf_code
    fi

    # Get VCOM value
    if [ -n "$HAS_DISPLAY_VCOM" ] && [ $HAS_DISPLAY_VCOM -eq 1 ]; then
        video_get_vcom
    fi
}


######################################################################
# Function:     do_set_eink_panel_id
# Purpose:      Tell the operator to set the panel_id now (they've already
#               been instructed to use serial-port only for this operation).
#               Read panel_id from serial port input and write it to
#               the system (NOR flash)
# Paramters:    none
# Returns:      1 - Panel ID set
#               0 - Panel ID not set
# Side Effect:  Sets device panel id in NOR
######################################################################
do_set_eink_panel_id()
{
    echo "DEVICE_PANEL_ID = $DEVICE_PANEL_ID"
    echo -n "Enter panel_id now (enter to cancel) : "
    read USER_DEVICE_PANEL_ID
    if [ -n "$USER_DEVICE_PANEL_ID" ]; then
        vmsg "User entered $USER_DEVICE_PANEL_ID"
        export DEVICE_PANEL_ID="$USER_DEVICE_PANEL_ID"
        device_set_panel_id
        return 1
    else
        echo "Not setting panel id - user cancelled."
    fi
    return 0
}


######################################################################
# Function:     do_set_manuf_code
# Purpose:      Tell the operator to set the manufacturer code now (they've
#               already been instructed to use serial-port only for this
#               operation).  Read value from serial port input 
#               and store it off in flash
# Paramters:    none
# Returns:      1 - Manufacturer code set
#               0 - Manufacturer code not set
# Side Effect:  Writes manufacturer code in flash
######################################################################
do_set_manuf_code()
{
    # Get input from user for device manufacturer code
    echo "DEVICE MANUFACTURER CODE = $DEVICE_MANUF_CODE"
    echo -n "Enter device manufacturer code now (enter to cancel) : "
    read USER_DEVICE_MANUF_CODE
    vmsg "User entered $USER_DEVICE_MANUF_CODE"
    if [ -n "$USER_DEVICE_MANUF_CODE" ]; then
        export DEVICE_MANUF_CODE=$USER_DEVICE_MANUF_CODE;
        device_set_manuf_code "$DEVICE_MANUF_CODE"
        return 1
    else
        echo "Not setting device manufacturer code - user cancelled."
    fi
    return 0
}


######################################################################
# Function:     do_set_mac_address
# Purpose:      Tell the operator to set the MAC address now (they've
#               already been instructed to use serial-port only for this
#               operation).  Read MAC address from serial port input 
#               and store it off in flash
# Paramters:    none
# Returns:      1 - MAC address set
#               0 - MAC address not set
# Side Effect:  Sets MAC address in flash
######################################################################
do_set_mac_address()
{
    # Get input from user for device serial number
    echo "DEVICE_MAC_ADDRESS = $DEVICE_MAC_ADDRESS"
    echo -n "Enter device MAC address now (enter to cancel) : "
    read USER_DEVICE_MAC_ADDRESS
    vmsg "User entered $USER_DEVICE_MAC_ADDRESS"
    if [ -n "$USER_DEVICE_MAC_ADDRESS" ]; then
        export DEVICE_MAC_ADDRESS=$USER_DEVICE_MAC_ADDRESS;
        dev_set_mac_address "$DEVICE_MAC_ADDRESS"
        return 1
    else
        echo "Not setting device MAC address - user cancelled."
    fi
    return 0
}


######################################################################
# Function:     do_set_serial_number
# Purpose:      Tell the operator to set the serial number now (they've
#               already been instructed to use serial-port only for this
#               operation).  Read serial number from serial port input 
#               and write it to the system (NOR flash)
# Paramters:    none
# Returns:      1 - Serial Number set
#               0 - Serial Number not set
# Side Effect:  Sets device serial number in NOR
######################################################################
do_set_serial_number()
{
    # Get input from user for device serial number
    echo "DEVICE_SERIAL_NUMBER = $DEVICE_SERIAL_NUMBER"
    echo -n "Enter device serial number now (enter to cancel) : "
    read USER_DEVICE_SERIAL_NUMBER
    vmsg "User entered $USER_DEVICE_SERIAL_NUMBER"
    if [ -n "$USER_DEVICE_SERIAL_NUMBER" ]; then
        export DEVICE_SERIAL_NUMBER=$USER_DEVICE_SERIAL_NUMBER;
        device_set_serial_number
        return 1
    else
        echo "Not setting device serial number - user cancelled."
    fi
    return 0
}


######################################################################
# Function:     do_set_pcb_id
# Purpose:      Tell the operator to set the pcb id now (they've
#               already been instructed to use serial-port only for this
#               operation).  Read serial number from serial port input 
#               and write it to the system (NOR flash)
# Paramters:    none
# Returns:      1 - PCB Id set
#               0 - PCB Id not set
# Side Effect:  Sets device serial number in NOR
######################################################################
do_set_pcb_id()
{
    dev_get_pcb_id
    echo "DEVICE_PCB_ID = $DEVICE_PCB_ID"
    echo -n "Enter PCB ID now (enter to cancel) : "
    read USER_DEVICE_PCB_ID
    if [ -n "$USER_DEVICE_PCB_ID" ]; then
        vmsg "User entered $USER_DEVICE_PCB_ID"
        export DEVICE_PCB_ID=$USER_DEVICE_PCB_ID
        device_set_pcb_id
        return 1
    else
        echo "Not setting pcb id - user cancelled."
    fi
    return 0
}


######################################################################
# Function:     verify_user_wants_to_set_ids
# Purpose:      Ask user to verify they want to set device parameters
#               via the console before we stop accepting events from
#               on-board device keyboard (don't get user stuck if no
#               debug board is attached - allow them to bail out).
# Paramters:    option - name of option being set
# Returns:      0 - User DOES NOT want to continue / wants to cancel
#               1 - User wants to continue / set device parms via
#                   serial console.
# Assumptions: none
######################################################################
verify_user_wants_to_set_ids()
{
    clear_screen
    set_option="$1"
    ${DOUT} -n 13 4 "Device ID Initialization"
    ${DOUT} -n 5 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 5 7 "Device ID initialization must be performed"
    ${DOUT} -n 5 9 "from the debug board console."
    ${DOUT} -n 5 13 "Press $SUCCESS_KEY_LABEL to set $set_option now."
    ${DOUT} 5 15 "Press $EXIT_KEY_LABEL to abort setting $set_option now."

    #
    # Get the key request
    #
    while [ 0 -ne 1 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        case "$KEY" in
            $SUCCESS_KEY)
                # suck off any remaining enter's from serial port...
                KEY=`$GET_KEYBOARD_INPUT 1`

                erase_line 7
                erase_line 9
                erase_line 13
                erase_line 15
                ${DOUT} -n 5 7 "$set_option is being initialized now"
                ${DOUT} -n 5 9 "via the serial console..."
                ${DOUT} 5 13 "This screen will disappear once complete."
                return 1
                ;;

            $EXIT_KEY)
                # suck off any remaining enter's from serial port...
                KEY=`$GET_KEYBOARD_INPUT 1`
                return 0
                ;;

            *)
                ;;
        esac
    done;
}


######################################################################
# Function:     do_run_dev_settings_diag
# Purpose:      Gather up system information, display it to the user,
#               and then display the device settings menu.
#               Field operator menu requests.
# Paramters:    none
# Returns:      0 - Reboot is requested
#               1 - No reboot requested
######################################################################
do_run_dev_settings_diag()
{
    _NO_REBOOT=0
    _DONE_=0
    REDRAW=1

    banner="Current Device Settings"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 6 "$base"
    _bannerX="$?"
    while [ $_DONE_ -ne 1 ]; do
        if [ $REDRAW -eq 1 ]; then
            if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
                clear_screen
                ${DOUT} -n ${_bannerX} 4 "$banner"
                ${DOUT} -n 6 5 "$base"
                ${DOUT} 0 7 "Gathering accelerometer data, please be patient..."
            fi

            # Get device information now...
            gather_device_information

            if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
                # Go grab an average...
                accel_get_average_offsets 2
                accel_range_check
                if [ $? -eq 0 ]; then
                    CAL_STRING="NEEDS CALIBRATION"
                else
                    CAL_STRING="CALIBRATED"
                fi
            fi
            clear_screen
            ${DOUT} -n ${_bannerX} 1 "$banner"
            ${DOUT} -n 6 2 "$base"
            ${DOUT} -n 6 4 "Serial Number     : $DEVICE_SERIAL_NUMBER"
            ${DOUT} -n 6 6 "      PCBA ID     : $DEVICE_PCB_ID"
            ${DOUT} -n 6 8 "EINK Panel ID     : $DEVICE_PANEL_ID"
            let next_line=12

            if [ -n "$HAS_DISPLAY_VCOM" ] && [ $HAS_DISPLAY_VCOM -eq 1 ]; then
                ${DOUT} -n 6 $next_line "VCOM Setting      : $VCOM_SETTING"
                let next_line+=2
            fi

            if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
                ${DOUT} -n 6 $next_line "Accelerometer     : $CAL_STRING ($ACCEL_X_AVERAGE, $ACCEL_Y_AVERAGE, $ACCEL_Z_AVERAGE)"
                let next_line+=2
                ${DOUT} -n 6 $next_line "Accel Offsets     : $ACCEL_X_OFFSET, $ACCEL_Y_OFFSET, $ACCEL_Z_OFFSET"
                let next_line+=2
            fi
            if [ -n "$HAS_MAC_ADDRESS" ] && [ $HAS_MAC_ADDRESS -eq 1 ]; then
                ${DOUT} -n 6 $next_line "  MAC Address     : $DEVICE_MAC_ADDRESS"
                let next_line+=2
                ${DOUT} -n 6 $next_line "Manufacturer Code : $DEVICE_MANUF_CODE"
                let next_line+=2
            fi

            # Advance an extra two lines to let menu below stand out
            let next_line+=1

            ${DOUT} -n 10 $next_line "Change Device Settings Options"
            let next_line+=1
            ${DOUT} -n 8 $next_line "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            let next_line+=2

            # Set Serial Number Menu Item
            text=`keycode_to_label $DEV_SET_SERIAL_NUMBER_MENU_ITEM`
            ${DOUT} -n 10 $next_line "$text) Set Serial Number"
            let next_line+=2

            # Set Panel ID Menu Item
            if [ -n "$HAS_SETABLE_PANEL_ID" ] && [ $HAS_SETABLE_PANEL_ID -eq 1 ]; then
                text=`keycode_to_label $DEV_SET_PANEL_ID_MENU_ITEM`
                ${DOUT} -n 10 $next_line "$text) Set EINK Panel ID"
                let next_line+=2
            fi

            # Set PCBA ID Menu Item
            text=`keycode_to_label $DEV_SET_PCB_ID_MENU_ITEM`
            ${DOUT} -n 10 $next_line "$text) Set PCBA ID"
            let next_line+=2

            # Set PCBA Config Menu Item
            if [ -n "$HAS_SETABLE_PCB_CONFIG" ] && [ $HAS_SETABLE_PCB_CONFIG -eq 1 ]; then
                text=`keycode_to_label $DEV_SET_PCB_CONFIG_MENU_ITEM`
                ${DOUT} -n 10 $next_line "$text) Set PCB Config"
                let next_line+=2
            fi

            # Set MAC Address Menu Item
            if [ -n "$HAS_MAC_ADDRESS" ] && [ $HAS_MAC_ADDRESS -eq 1 ]; then
                text=`keycode_to_label $DEV_MAC_ADDRESS_MENU_ITEM`
                ${DOUT} -n 10 $next_line "$text) Set MAC Address"
                let next_line+=2
                text=`keycode_to_label $DEV_MANUF_CODE_MENU_ITEM`
                ${DOUT} -n 10 $next_line "$text) Set Manufacturer Code"
                let next_line+=2
            fi

            # Update EINK Waveform
            text=`keycode_to_label $DEV_UPDATE_WAVEFORM_MENU_ITEM`
            ${DOUT} -n 10 $next_line "$text) Update EINK Waveform"
            let next_line+=2

            # Calibrate Accelerometer Menu Item
            if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
                text=`keycode_to_label $DEV_CALIBRATE_ACCEL_MENU_ITEM`
                ${DOUT} -n 10 $next_line "$text) Calibrate Accelerometer"
                let next_line+=2
            fi

            # Barcode serial number display
            text=`keycode_to_label $DEV_DISPLAY_BARCODE_SN_MENU_ITEM`
            ${DOUT} -n 10 $next_line "$text) Display Serial Number Barcode"
            let next_line+=2

            let next_line+=1
            ${DOUT} -n 5 $next_line "Press $EXIT_KEY_LABEL to exit device settings and reboot."
            let next_line+=2
            ${DOUT} 5 $next_line "Press $ALTERNATE_EXIT_KEY_LABEL to exit without rebooting."
        else
            REDRAW=1
        fi
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL="$?"
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $DEV_SET_SERIAL_NUMBER_MENU_ITEM)
                    verify_user_wants_to_set_ids "Serial Number"
                    if [ "$?" -eq 1 ]; then
                        do_set_serial_number
                    fi
                    ;;

                $DEV_UPDATE_WAVEFORM_MENU_ITEM)
                    video_do_update_waveform
                    ;;
	
                $DEV_DISPLAY_BARCODE_SN_MENU_ITEM)
                    clear_screen
                    eips -r $DEVICE_SERIAL_NUMBER
                    eips 10 $EIPS_BOTTOM_LINE "Press $EXIT_KEY_LABEL to exit this screen."
                    do_local_echo  "Displaying the BARCODE serial number: $DEVICE_SERIAL_NUMBER"
                    do_local_echo  "Press $EXIT_KEY_LABEL to exit this screen."
                    wait_for_key $EXIT_KEY
                    ;;

                $DEV_CALIBRATE_ACCEL_MENU_ITEM)
                    if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
                        accel_do_calibrate
                        REDRAW=1
                    else
                        vmsg "Wrong key $KEY pressed.."
                        REDRAW=0
                    fi
                    ;;

                $DEV_SET_PCB_ID_MENU_ITEM)
                    verify_user_wants_to_set_ids "PCBA ID"
                    if [ "$?" -eq 1 ]; then
                        do_set_pcb_id
                    fi
                    ;;

                $DEV_SET_PANEL_ID_MENU_ITEM)
                    verify_user_wants_to_set_ids "Panel ID"
                    if [ "$?" -eq 1 ]; then
                        do_set_eink_panel_id
                    fi
                    ;;

                $DEV_MANUF_CODE_MENU_ITEM)
                    verify_user_wants_to_set_ids "Manufacturer Code"
                    if [ "$?" -eq 1 ]; then
                        do_set_manuf_code
                    fi
                    ;;


                $DEV_MAC_ADDRESS_MENU_ITEM)
                    verify_user_wants_to_set_ids "MAC Address"
                    if [ "$?" -eq 1 ]; then
                        do_set_mac_address
                    fi
                    ;;

                $EXIT_KEY)
                    _DONE_=1
                    ;;

                $ALTERNATE_EXIT_KEY)
                    _DONE_=1
                    _NO_REBOOT=1
                    ;;
                     
                *)
                    vmsg "Wrong key $KEY pressed.."
                    REDRAW=0
                    ;;
            esac
        fi
    done
    return ${_NO_REBOOT}
}

case "$1" in

    stop)
        vmsg "Exiting Device Settings Module"
        ;;

    cycle)
        vmsg "Cycle mode not supported by the Device Settings Module"
        return 0
        ;;

    start|*)
        vmsg "Starting Device Settings Module"
        enter_diag "Device Settings"
        # Clear any previous diagnostic test results
        clear_diag_fail
        dev_settings_hal_init
        do_run_dev_settings_diag
        _DONT_REBOOT_DEVICE="$?"
        dev_settings_hal_exit
        exit_diag "Device Settings" 0 ${_DONT_REBOOT_DEVICE}
        ;;

esac
