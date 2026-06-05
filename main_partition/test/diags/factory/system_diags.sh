#!/bin/sh
##################################################################################
#
#  File:   system_diags.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the main system diagnostics engine.  This script is
#       responsible for determining which product we're on and then
#       setting up the environment for use with that product.  This
#       includes including the proper environment.productName file and
#       loading appropriate hals for the DUT where applicable.
#
#       This script displays the main system diagnostic's menu, and then
#       passed control the requested diagnostic test in the ./tests folder.
#
#       NOTE:  It may seem that this file has no order to it w/ respects to
#       where functions are defined and called, as well as having includes
#       in the middle of the file, variables declared at odd places, but this is 
#       required and by design.  To re-order this file would break it.  
#       There is reason behind the apparently unorganized insanity.
#
#   Important Constants
#       DIAGNOSTIC_ROOT         - Path to root of diagnostic tests
#       DIAG_TOOL_ROOT          - Path to root of diagnostic tools directory
#       DIAGNOSTIC_VERSION_FILE - Full path filename of diagnostic's version file
#       AUTO_RUN_ENABLE_FILENAME- Name of auto-enable file for diags
#       ENABLE_DIAGS_FILE_ROOT  - Directory containing the ENABLE_DIAGS file
#       ENABLE_DIAGNOSTICS_FILE - Full path to "diags enabled" file ENABLE_DIAGS
#       ENABLE_DIAGNOSTICS_FS_FILE - Path to redundant "ENABLE_DIAGS" file in fs
#
#   Globals
#       LOG_OUTPUT_TO_LOGFILE   - 1 to log output to logfile, 0 to not.
#       PASS                    - Set to 0 if a diagnostic fails
#       SUB_TEST_PASS           - Set to 0 if a diagnostic sub-test fails
#       DIAG_VERBOSE            - Verbosity level (0 or 1)
#       VOLUMED_WAS_KILLED      - Set if we killed volumed on startup
#       POWERD_WAS_KILLED       - Set if we killed powerd on startup
#       FRAMEWORK_WAS_KILLED    - Set if we killed framework on startup
#       AUDIOSERVER_WAS_STARTED - Set if we had to start the audioserver
#
#   Routines
#       display_device_not_recognized() - Display "device not supported" screen
#       determine_platform()        - Determine which platform (product) we're on
#       set_input_driver_entries()  - Point to proper /dev/input/event* entries for
#       do_disable_diags()          - Disable diagnostics and verify it worked
#       get_sw_version()            - Get SW version from system
#       inform_user_framework_start - Tell user we quit diags and are continuing boot
#       do_set_menu_item_keys()     - Dynamically set main menu items based on enabled tests
#       display_diag_result_summary - Display the diagnostic results summary
#       disable_daemons()           - Disable any daemons that cause diags problems
#       enable_daemons()            - Enable any daemons that diags disabled
#       display_menu()              - Display the main system diagnostic's menu
#       disable_autorun()           - Disable the auto-run feature of diagnostics
#       do_create_factory_fresh_flag- Create the factory fresh flag file
#       display_user_disable_autorun_screen()   - Tell user how to re-enable diags
#       run_diagnostic_menu()       - Get and respond to user requests of main menu
#
##################################################################################

# If this is a stop command, abort now, no need to continue (we
# save processing time from in-line gets of input driver entries
if [ "$1" == "stop" ]; then
    exit 0
fi

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

# Get FLAG_FACTORY_FRESH definition for diag disable option
[ -f "/etc/sysconfig/paths" ] && . "/etc/sysconfig/paths"

# Define a variable representing the last line on the display to draw to
let EIPS_BOTTOM_LINE=$SCREEN_Y_RES/$EIPS_Y_RES-1
export EIPS_BOTTOM_LINE
export EIPS

#
# Flag indicating the WAN has powered on at least once
#
export WAN_NEVER_POWERED=1 

#
# Set to 1 to output logs to a logfile
#
export LOG_OUTPUT_TO_LOGFILE=0

# Important Locations on Target
export DIAGNOSTIC_ROOT="$DIAGS_ROOT"
export DIAG_TOOL_ROOT="$DIAGNOSTIC_ROOT/tools"
export DIAGNOSTIC_VERSION_FILE="$DIAGNOSTIC_ROOT/diags_version" 

# If a diags version file exists, source it now
if [ -f $DIAGNOSTIC_VERSION_FILE ]; then 
    . "${DIAGNOSTIC_VERSION_FILE}"
fi

#
# Determine which platform we're on first
#
export TURING_NAME="Turing"
export TURING_SUFFIX="turing"
export NELL_NAME="Nell"
export NELL_SUFFIX="nell"
export TURINGWW_NAME="Turing-WW"
export TURINGWW_SUFFIX="turingww"
export NELLWW_NAME="Nell-WW"
export NELLWW_SUFFIX="nellww"
export SHASTA_NAME="Shasta"
export SHASTA_SUFFIX="shasta"
export KINDLE_NAME="Kindle"
export KINDLE_SUFFIX="kindle"
export SHASTA_WFO_NAME="Shasta-WFO"
export SHASTA_WFO_SUFFIX="wfo"


#
# Default screen offsets (in case board_id is incorrect)
#
export SCREEN_X_OFFSET=0
export SCREEN_Y_OFFSET=0

#
# Entry to indicate diags is running
#
_RUNNING_DIAGS_CTRL=/sys/devices/platform/eink_fb.0/running_diags


#
# Entry to Disable 1725 Charger Compliance
#
_CHARGER_1725_COMPLIANCE_DISABLE_ENTRY="/sys/devices/platform/battery/disable"


#
# Define the X key locally for the display_device_not_recognized()
# routine because if we can't recognize the device, we won't source
# the environment.product file, which contains the keycode mappings.
# We'll hard-code to use X, and hope that that key is consistent
# across the HW platforms.  Worse case is that on a device with bad
# board_id, they can't dismiss dialog and must reboot.
#
# NOTE that a value of 21 is not the correct value (correct value is
#   45).  In a world where board_id is an unrecognized value, 21 is the
#   value currently returned when the X key is pressed...
#
DEVICE_KEY_X=21
CONSOLE_KEY_X=45


#
# List of Possible Commonly Supported Diagnostic Modules
# All an environment.product file needs to do is define
# the components they have by setting it to a 1.  We will
# preset all to zero to allow product scripts to ONLY enable
# components that they have, and not have to worry about what
# they don't have.
#
export HAS_VIDEO=0
export HAS_LED=0
export HAS_BUTTONS=0
export HAS_KEYBOARD=0
export HAS_FIVEWAY=0
export HAS_HAPTIC=0
export HAS_USB_DEVICE=0
export HAS_POWER=0
export HAS_GAS_GAUGE=0
export HAS_AUDIO=0
export HAS_WAN=0
export HAS_WIFI=0 
export HAS_MOVINAND=0
export HAS_ACCELLEROMETER=0
export HAS_RUN_MODES=0
export HAS_DEVICE_SETTINGS=0 
export HAS_OPERATOR_SUITE=0 
export HAS_MAC_ADDRESS=0 

#
# List of possble menu items.  We define these here to be
# values that would never be returned from the keyboard driver.
# We make a pass later to define the menu items that this product
# actually supports and change the relevant constants there.  After
# that process is complete, what we have is a list of active menu
# items that are set to valid and displayed menu items, and the
# menu item constants for component tests not supported by this product
# will be defined to values that will never be seen, effectively
# disabling these possibilities from the case statement.
#
export VIDEO_MENU_ITEM=500
export LED_MENU_ITEM=501
export BUTTON_MENU_ITEM=502
export KEYBOARD_MENU_ITEM=503
export FIVEWAY_MENU_ITEM=504
export USB_DEVICE_MENU_ITEM=505
export POWER_MENU_ITEM=506
export GAS_GAUGE_MENU_ITEM=507
export AUDIO_MENU_ITEM=508
export RUN_IN_MENU_ITEM=509
export WAN_MENU_ITEM=510
export MOVINAND_MENU_ITEM=511
export ACCELLEROMETER_MENU_ITEM=512
export DEVICE_SETTINGS_MENU_ITEM=513
export FCT_MENU_ITEM=514
export OPERATOR_SUITE_MENU_ITEM=515
export WIFI_MENU_ITEM=516
export UPDATE_DIAGS_MENU_ITEM=517
export USB_SERIAL_MENU_ITEM=518
export DIAG_MISC_MENU_ITEM=519
export CERT_MENU_ITEM=520
export FIVE_ONE_ONE_MENU_ITEM=521
export WAN_MOLB_MENU_ITEM=522
export WAN_GSM1900_MENU_ITEM=523
export EYE_ONE_MENU_ITEM=524
export BATT_CAP_ADJUST_MENU_ITEM=525
export WIFI_ART_MENU_ITEM=527
export DEBUG_POWER_HOG_MENU_ITEM=528


######################################################################
# Function:     display_device_not_recognized
# Purpose:      Display a screen telling user we couldn't ID the device.
# Paramters:    autu-reboot
#                   0 - Dont auto-reboot.  Require user to dismiss dialog
#                   1 - Don't require user to dismiss dialog before returning
# Returns:      none
######################################################################
display_device_not_recognized()
{
    # Main functions (DOUT/clear_screen) not loaded yet, load them now...
    [ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

    BOARD_ID=`cat /proc/board_id`
    clear_screen
    banner="Diagnostic Services, version $DIAGNOSTICS_VERSION"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 5 "$base"
    ${DOUT} -n $? 4 "$banner"
    ${DOUT} -n 5 5 "$base"
    ${DOUT} -n 3 7 "This device board_id $BOARD_ID is not"
    ${DOUT} -n 3 9 "a recognized device supported by diagnostics."

    if [ "$1" -eq 1 ]; then
        ${DOUT} -n 3 11 "Auto-boot function is being disabled."
        ${DOUT} -n 3 13 "Exiting diagnostics and rebooting now."
        ${DOUT} 3 17 "Please be patient while the system reboots..."
    else
        ${DOUT} -n 3 13 "Verify and correct the device board_id."
        ${DOUT} 3 17 "Press the X key to exit."

        KEYBOARD_DRIVER=`$DIAG_TOOL_ROOT/getinputentry mxckpd`

        DONE=0
        while [ $DONE -ne 1 ]; do
            # wait for the key and then return
            KEY=`"$DIAG_TOOL_ROOT/getkbdserial" $KEYBOARD_DRIVER`
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                case "$KEY" in
                    $DEVICE_KEY_X | $CONSOLE_KEY_X)
                        DONE=1
                        ;;
                    *)
                        ;;
                esac
            fi
        done
    fi
}


######################################################################
# Function:     determine_platform
# Purpose:      Determine which device we're on.  FIrst look for the
#               usb device entry point to determine if we're Kindle
#               or not.  If we're not, then check board_id to determine
#               the device type.  If there's no board_id, or it's unknown,
#               display "diag failure" message.  Make user dismiss baord_id
#               failure message if it's an unrecognized id (i.e. if it's
#               NOT a Mario or ADS board_id, which is a valid ID, just
#               not supported by diags.
# Paramters:    none
# Returns:      0 - Board ID verified properly
#               1 - Board ID Verification Failed !
######################################################################
determine_platform()
{
    # First check to see if it's Kindle
    if [ -d /sys/devices/platform/pdc/gadget/gadget-lun0/file ]; then
        export PRODUCT="$KINDLE_SUFFIX"
        export PRODUCT_NAME="$KINDLE_NAME"
    else
        # Check for Turing or Nell
        if ( is_Turing ); then
            # Turing Device
            export PRODUCT="$TURING_SUFFIX"
            export PRODUCT_NAME="$TURING_NAME"
            # Disable sleeping of serial port for diagnostics
            echo -n 0 > /sys/devices/platform/mxcintuart.0/uart_clk_state
            echo -n 0 > /proc/sys/kernel/printk
        elif ( is_Nell ); then
            # Nell Device
            export PRODUCT="$NELL_SUFFIX"
            export PRODUCT_NAME="$NELL_NAME"
            # Disable sleeping of serial port for diagnostics
            echo -n 0 > /sys/devices/platform/mxcintuart.0/uart_clk_state
            echo -n 0 > /proc/sys/kernel/printk
        elif ( is_TuringWW ); then
            # Turing World Wide Device
            export PRODUCT="$TURINGWW_SUFFIX"
            export PRODUCT_NAME="$TURINGWW_NAME"
            # Disable sleeping of serial port for diagnostics
            echo -n 0 > /sys/devices/platform/mxcintuart.0/uart_clk_state
            echo -n 0 > /proc/sys/kernel/printk
        elif ( is_NellWW ); then
            # Nell Device
            export PRODUCT="$NELLWW_SUFFIX"
            export PRODUCT_NAME="$NELLWW_NAME"
            # Disable sleeping of serial port for diagnostics
            echo -n 0 > /sys/devices/platform/mxcintuart.0/uart_clk_state
            echo -n 0 > /proc/sys/kernel/printk
        elif ( is_Shasta ); then
            # Determine which style of Shasta
	    
            if ( is_Shasta_WFO ); then
                # Shasta WFO Device
                export PRODUCT_NAME="$SHASTA_WFO_NAME"
                export PRODUCT="$SHASTA_WFO_SUFFIX"
            else
                export PRODUCT_NAME="$SHASTA_NAME"
                export PRODUCT="$SHASTA_SUFFIX"
            fi

            # Temporary for Luigi boards - disable enet to get rid of annoying
            # discovery logs
            /etc/init.d/ethernet stop > /dev/null 2>&1

            # Disable sleeping of serial port for diagnostics
            echo -n 0 > /sys/devices/platform/mxcintuart.0/uart_clk_state
            echo -n 0 > /proc/sys/kernel/printk
        else
            echo "DIAGNOSTIC FAILED detecting device id!"

            # If it's a Mario or ADS, display a dialog, disable diags and reboot.
            # If it's an unrecognized board_id, then put up dialog stating
            # such and require the operator to dismiss it (don't disable diags in
            # this case)
            if ( is_ADS ) || ( is_Mario ) || ( is_Luigi ); then
                # Disable auto-boot on this device...
                display_device_not_recognized 1
                disable_autorun
            else
                # For now, tell user to fix board_id, require them to dismiss dialog
                # Later, perhaps we put up a dialog to force user to set it...
                display_device_not_recognized 0
            fi
            reboot
            exit 0
        fi
    fi
    return 0
}


#
# Include environment variables, macros, location definitions, etc...
#
determine_platform      # Determine platform before defining environment vars
board_id_failed="$?"
if [ $board_id_failed -eq 1 ]; then
    # For now, we reboot on board_id verification failure (endless loop until board_id is fixed)
    reboot
fi


#
# Initialize and export product-specific environment variables
#
if [ -f $DIAGNOSTIC_ROOT/environment.$PRODUCT ]; then
    . "${DIAGNOSTIC_ROOT}/environment.${PRODUCT}"
else
    echo "ERROR - '$DIAGNOSTIC_ROOT/environment.$PRODUCT' not found."
    exit
fi


#
# Some functions have set keys, define those here
#
export SET_WAN_MENU_ITEM=$KEY_W
export SET_FIVE_ONE_ONE_MENU_ITEM=$KEY_E
export SET_RUN_IN_MENU_ITEM=$KEY_R
export SET_POWER_MENU_ITEM=$KEY_T
export SET_USB_SERIAL_MENU_ITEM=$KEY_C
export SET_USB_DEVICE_MENU_ITEM=$KEY_U
export SET_WIFI_MENU_ITEM=$KEY_I
export SET_WIFI_ART_MENU_ITEM=$KEY_Y
export SET_OPERATOR_SUITE_MENU_ITEM=$KEY_O
export SET_AUDIO_MENU_ITEM=$KEY_A
export SET_DEVICE_SETTINGS_MENU_ITEM=$KEY_S
export SET_FCT_MENU_ITEM=$KEY_F
export SET_ACCELLEROMETER_MENU_ITEM=$KEY_G
export SET_GAS_GAUGE_MENU_ITEM=$KEY_G
export SET_BATT_CAP_ADJUST_MENU_ITEM=$KEY_H
export SET_FIVEWAY_MENU_ITEM=$KEY_J
export SET_KEYBOARD_MENU_ITEM=$KEY_K
export SET_LED_MENU_ITEM=$KEY_L
export SET_UPDATE_DIAGS_MENU_ITEM=$KEY_Z
export SET_CERT_MENU_ITEM=$KEY_C
export SET_VIDEO_MENU_ITEM=$KEY_V
export SET_BUTTON_MENU_ITEM=$KEY_B
export SET_DIAG_MISC_MENU_ITEM=$KEY_N
export SET_MOVINAND_MENU_ITEM=$KEY_M
export SET_DISABLE_DIAGS_MENU_ITEM=$KEY_D
export SET_EYE_ONE_MENU_ITEM=$KEY_Y
export SET_WAN_MOLB_MENU_ITEM=$KEY_Z

# Out of unique keys...
export SET_WAN_GSM1900_MENU_ITEM=$KEY_H     # "Battery Adjust" won't be in same menu
export SET_HAPTIC_MENU_ITEM=$KEY_C          # haptic and USB serial never in same menu
export SET_RUN_IN_TIME_MENU_ITEM=$KEY_F     # FCT is not in the run-in menu
export SET_RUN_IN_CHARGER_CHECK_MENU_ITEM=$KEY_Z    # WAN MOLB not in run-in menu


######################################################################
# Function:     set_input_driver_entries
# Purpose:      Based on the product that we're on, get the entry points
#               for getting input data from buttons, keyboard, VNC, and
#               fiveway (i.e. the /dev/input/eventX entry).
#
#               NOTE that the order of this is important (execute after 
#               environment.PRODUCT, but before environment.vars)
# Paramters:    none
# Returns:      0 - Success
#               1 - Error getting Button driver input entry
#               2 - Error getting Keyboard driver input entry
#               3 - Error getting VND driver input entry
#               4 - Error getting Fiveway driver input entry
#               5 - Error getting volume driver input entry
# Side Effect:  Sets driver globals to point to the right /dev/input/eventX
#               entry for said driver.
######################################################################
set_input_driver_entries()
{
    if [ "x$HAS_PREDEFINED_INPUT_ENTRIES" == "x1" ]; then
        return 0
    fi

    # Set Button Driver...
    export BUTTON_DRIVER=`$DIAG_TOOL_ROOT/getinputentry "$BUTTON_DRIVER_NAME"`
    _err="$?"
    if [ $_err -ne 0 ] || [ -z "$BUTTON_DRIVER" ]; then
        echo "Error getting button driver input entry."
        return 1
    else
        echo "Button driver input entry = $BUTTON_DRIVER"
    fi 

    # Set Keyboard Driver...
    export KEYBOARD_DRIVER=`$DIAG_TOOL_ROOT/getinputentry  "$KEYBOARD_DRIVER_NAME"`
    _err="$?"
    if [ $_err -ne 0 ] || [ -z "$KEYBOARD_DRIVER" ]; then
        echo "Error getting keyboard driver input entry."
        return 2
    else
        echo "Keyboard driver input entry = $KEYBOARD_DRIVER"
    fi 

    # Set Fiveway Driver...
    export FIVEWAY_DRIVER=`$DIAG_TOOL_ROOT/getinputentry  "$FIVEWAY_DRIVER_NAME"`
    _err="$?"
    if [ $_err -ne 0 ] || [ -z "$FIVEWAY_DRIVER" ]; then
        echo "Error getting fiveway driver input entry."
        return 4
    else
        echo "Fiveway driver input entry = $FIVEWAY_DRIVER"
    fi 

    # Set Volume Driver if one exists...
    if [ -n "$HAS_VOLUME_BUTTON_DRIVER" ] && [ $HAS_VOLUME_BUTTON_DRIVER -eq 1 ]; then
        export VOLUME_BUTTON_DRIVER=`$DIAG_TOOL_ROOT/getinputentry "$VOLUME_BUTTON_DRIVER_NAME"`
        _err="$?"
        if [ $_err -ne 0 ] || [ -z "$VOLUME_BUTTON_DRIVER" ]; then
            echo "Error getting volume button driver input entry."
            return 5
        else
            echo "Volume button driver input entry = $VOLUME_BUTTON_DRIVER"
        fi 
    fi

    # Set vnc Driver...
#    export VNC_DRIVER=`$DIAG_TOOL_ROOT/getinputentry  "$VNC_DRIVER_NAME"`
#    _err="$?"
#    if [ $_err -ne 0 ] || [ -z "$VNC_DRIVER" ]; then
#        echo "Error getting VNC driver input entry."
#        return 3
#    else
#        echo "VNC driver input entry = $VNC_DRIVER"
#    fi 

    # Set USB Serial...
    if [ -n "$HAS_USB_SERIAL_SUPPORT" ] && [ $HAS_USB_SERIAL_SUPPORT -eq 1 ]; then
        export SERIAL_USB_DRIVER="/dev/$SERIAL_USB_DRIVER_NAME"
    fi

    # Success
    return 0
}

######################################################################
# Function:     display_user_disable_autorun_screen
# Purpose:      Tell user we've disabled diagnostics auto-run feature,
#               and explain how to re-enable it if they desire.
# Paramters:    autorun_disabled - 0 if disabling failed, 1 if we're disabled
# Returns:      none
######################################################################
display_user_disable_autorun_screen()
{
    AUTORUN_DISABLE_WORKED="$1"

    # Tell user what's going on and how to re-enable diags...
    clear_screen
    print_center_text "$PRODUCT_NAME Diagnostic Services" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 5 4

    if [ $AUTORUN_DISABLE_WORKED -eq 1 ]; then
        ${DOUT} -n 6 7 "System diagnostics will no longer be"
        ${DOUT} -n 6 9 "executed automatically at boot."
        ${DOUT} -n 6 12 "To re-enable auto-boot, create the"
        ${DOUT} -n 6 14 "following file on the user store:"
        ${DOUT} -n 6 16 "$AUTO_RUN_ENABLE_FILENAME"
        ${DOUT} 6 20 "Rebooting the device now..."
    else
        ${DOUT} -n 6 7 "Disabling of the auto-boot feature failed."
        ${DOUT} -n 6 9 "Please verify that the following directory"
        ${DOUT} -n 6 11 "on the device is writable:"
        ${DOUT} -n 6 13 "$ENABLE_DIAGS_FILE_ROOT"
        ${DOUT} 8 19 "Press $SUCCESS_KEY_LABEL to continue."
        wait_for_key $SUCCESS_KEY
    fi
}


######################################################################
# Function:     do_display_no_serial_number_error
# Purpose:      Operator wanted to disable diagnostics, but device
#				serial number is not set.  Tell operator that device
#				serial number isn't set but must be in order to disable
#				diagnostics.
# Paramters:    none
# Returns:      none
######################################################################
do_display_no_serial_number_error()
{
    clear_screen
	base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    print_center_text "$PRODUCT_NAME Diagnostic Services" "$base" 6 4
    center_text "ERROR" 6 "$base"
    ${DOUT} -n $? 7 "ERROR"
    ${DOUT} -n 6 9 "Device serial number is not set."
    ${DOUT} -n 6 11 "Device serial number must be set before"
    ${DOUT} -n 6 13 "diagnostics can be disabled."
    ${DOUT} -n 6 19 "Disabling of the auto-boot feature failed."
    ${DOUT} 6 23 "Press $EXIT_KEY_LABEL to return to main menu."
    wait_for_key $EXIT_KEY
}


######################################################################
# Function:     do_disable_diags
# Purpose:      Disable diagnostics.  It does this by deleting the
#               ENABLE_DIAGS file on the USB user store as well as the
#               redundant one in the filesystem.
# Paramters:    none
# Returns:      0 - Diagnostics disabled
#				1 - Diagnostics NOT disabled (serial number not set)
# Side Effect:  Disables the auto-launch of diagnostics on boot
######################################################################
do_disable_diags()
{
	# Make sure device serial number is set before allowing diags to be disabled
	dev_get_serial_number
	if [ "$DEVICE_SERIAL_NUMBER" = "0000000000000000" ] || [ "$DEVICE_SERIAL_NUMER" = "uninitialized" ]; then
		do_display_no_serial_number_error
		return 1
	else
		echo "Device Serial Number is $DEVICE_SERIAL_NUMBER"
	fi

    # Make filesystem writable, delete both enable files, and then restore
    # read-only permissions for file system
    mntroot_rw
	if [ -f $ENABLE_DIAGNOSTICS_FILE ]; then
    	echo "Removing $ENABLE_DIAGNOSTICS_FILE"
    	rm $ENABLE_DIAGNOSTICS_FILE > /dev/null 2>&1
	fi
	if [ -f $ENABLE_DIAGNOSTICS_FS_FILE ]; then
    	echo "Removing $ENABLE_DIAGNOSTICS_FS_FILE"
    	rm $ENABLE_DIAGNOSTICS_FS_FILE > /dev/null 2>&1
	fi
	if [ -f $ENABLE_DIAGNOSTICS_FILE ]; then
    	echo "Delete of $ENABLE_DIAGNOSTICS_FILE failed !"
	fi
	if [ -f $ENABLE_DIAGNOSTICS_FS_FILE ]; then
    	echo "Delete of $ENABLE_DIAGNOSTICS_FS_FILE failed !"
	fi
    sync
    mntroot_ro
	return 0
}


######################################################################
# Function:     disable_autorun
# Purpose:      Disable diagnostics and then verify that we were 
#               successful.
# Paramters:    none
# Returns:      0 - Diagnostics auto-run has been disabled
#               1 - Error occurred, diagnostics auto-run is not disabled
#               2 - Serial number empty, failed to disable diags
# Side Effect:  Disables auto-run on boot feature of diagnostics
######################################################################
disable_autorun()
{
    do_disable_diags
	_status="$?"
	if [ $_status -eq 1 ]; then
		return 2
	fi

    if [ -f $ENABLE_DIAGNOSTICS_FILE ] || [ -f $ENABLE_DIAGNOSTICS_FS_FILE ]; then
        # Something went wrong, file didn't get deleted...
        return 1
    else
        return 0
    fi
}



#
# Set our input driver entries
#
set_input_driver_entries
_input_err="$?"

##################################################################################
#
# Once we're here, we have determined we have a valid product and are pointing to
# the proper places to retrieve operator input.
# We will now initialize the proper environment variables files for this device.
# We can also include HALs now that we know which device we're on...
#
##################################################################################


#
# Initialize and export all environment variables
#
export EN_VARS="$DIAGNOSTIC_ROOT/environment.vars"
[ -f ${EN_VARS} ] && . ${EN_VARS}

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Include enable/disable_accessories_port
[ -f ${_POWER_HAL_FUNCTIONS} ] && . ${_POWER_HAL_FUNCTIONS}

# Include key mappings
[ -f ${_KEYBOARD_HAL_FUNCTIONS} ] && . ${_KEYBOARD_HAL_FUNCTIONS}

# Include USB_EXPORT_VOLUME for disable mechanism
[ -f ${_USB_HAL_FUNCTIONS} ] && . ${_USB_HAL_FUNCTIONS}

# Include WAN hal for wan_info_power() call
[ -f ${_WAN_HAL_FUNCTIONS} ] && . ${_WAN_HAL_FUNCTIONS}

# Include WIFI hal for wifi_511_test() call
[ -f ${_WIFI_HAL_FUNCTIONS} ] && . ${_WIFI_HAL_FUNCTIONS}

# Include Gas Gauge hal for adjust_battery_to_ship_mode() call
[ -f ${_GAS_GAUGE_HAL_FUNCTIONS} ] && . ${_GAS_GAUGE_HAL_FUNCTIONS}

# Include DEVICE SETTINGS HAL 
[ -f ${_DEV_SETTINGS_HAL_FUNCTIONS} ] && . ${_DEV_SETTINGS_HAL_FUNCTIONS}

# Initialize the USB paths for our logfile support
usb_hal_init

# Global Variables
export PASS=1
export SUB_TEST_PASS=1

# Verbosity Level
export DIAG_VERBOSE=0

# Enviroment control variables
export VOLUMED_WAS_KILLED=0
export POWERD_WAS_KILLED=0
export FRAMEWORK_WAS_KILLED=0
export AUDIOSERVER_WAS_STARTED=0

#
# Auto-launch diagnostics enable/disable macros
#
AUTO_RUN_ENABLE_FILENAME="ENABLE_DIAGS"
ENABLE_DIAGS_FILE_ROOT="${USB_EXPORT_VOLUME}"
ENABLE_DIAGNOSTICS_FILE="${ENABLE_DIAGS_FILE_ROOT}/${AUTO_RUN_ENABLE_FILENAME}"
export ENABLE_DIAGNOSTICS_FS_FILE="/${AUTO_RUN_ENABLE_FILENAME}"


#
# Verify that we got our input drivers properly (don't care about vnc)
#
if [ ${_input_err} -ne 0 ] && [ ${_input_err} -ne 3 ]; then
    # Main functions (DOUT/clear_screen) not loaded yet, load them now...
    [ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

    case "${_input_err}" in
        1)  
            _driver_name="$BUTTON_DRIVER_NAME"
            ;;
        2)  
            _driver_name="$KEYBOARD_DRIVER_NAME"
            ;;
        3)  
            _driver_name="$VNC_DRIVER_NAME"
            ;;
        4)  
            _driver_name="$FIVEWAY_DRIVER_NAME"
            ;;
        *)
            _driver_name="UNKNOWN"
            ;;
    esac

    # Tell the user what happened
    clear_screen
    print_center_text "Diagnostic Services, version $DIAGNOSTICS_VERSION" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 5 4
    ${DOUT} -n 3 7 "ERROR getting input entry for the ${_driver_name} input driver."
    ${DOUT} -n 3 11 "Auto-boot function is being disabled."
    ${DOUT} -n 3 13 "Exiting diagnostics and rebooting now."
    ${DOUT} 3 17 "Please be patient while the system reboots..."
    disable_autorun
    user_disable_failed="$?"
    if [ $user_disable_failed -eq 1 ]; then
        display_user_disable_autorun_screen 1
    fi
    reboot
fi


######################################################################
# Function:     get_sw_version
# Purpose:      Get the version of software on the device
# Paramters:    none
# Returns:      none
# Side Effect:  SOFTWARE_FS_VERSION is set to the filesystem version
#               SOFTWARE_FS_BUILD_DATE is set to the software build date
######################################################################
get_sw_version()
{
    eval `cat /etc/version.txt | awk 'FNR==1 { split($0, arr, /:[ ]*/); print "VERSION=\"" arr[2] "\""; } FNR==2 { print "VER_DATE=\"" $0 "\"" }'`
    export SOFTWARE_FS_VERSION="$VERSION"
    export SOFTWARE_FS_BUILD_DATE="$VER_DATE"
}


######################################################################
# Function:     inform_user_framework_start
# Purpose:      Inform the user that we're exiting diagnostics and
#               continuing the boot process.
# Paramters:    none
# Returns:      none
######################################################################
inform_user_framework_start()
{
    clear_screen
    ${DOUT} -n 10 4 "$PRODUCT_NAME Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Exiting diagnostics and continuing the"
    ${DOUT} -n 4 9 "device boot process."
    ${DOUT} 4 14 "Please be patient while the system boots..."
}


######################################################################
# Function:     do_set_misc_menu_item_keys
# Purpose:      Dynamically match menu selection keys to enabled
#               diagnostics.
# Paramters:    none
# Returns:      number of active menu items
# Side Effects: Sets the various COMPONENT_MENU_ITEM variables
######################################################################
do_set_misc_menu_item_keys()
{
    if [ "x$HAS_VIDEO" == "x1" ]; then
        export VIDEO_MENU_ITEM="$SET_VIDEO_MENU_ITEM"
    fi

    if [ "x$HAS_LED" == "x1" ]; then
        export LED_MENU_ITEM="$SET_LED_MENU_ITEM"
    fi

    if [ "x$HAS_BUTTONS" == "x1" ]; then
        export BUTTON_MENU_ITEM="$SET_BUTTON_MENU_ITEM"
    fi

    if [ "x$HAS_KEYBOARD" == "x1" ]; then
        export KEYBOARD_MENU_ITEM="$SET_KEYBOARD_MENU_ITEM"
    fi

    if [ "x$HAS_FIVEWAY" == "x1" ]; then
        export FIVEWAY_MENU_ITEM="$SET_FIVEWAY_MENU_ITEM"
    fi

    if [ "x$HAS_WAN" == "x1" ]; then
        export WAN_MENU_ITEM="$SET_WAN_MENU_ITEM"
    fi

    if [ "x$HAS_WIFI" == "x1" ]; then
        export WIFI_MENU_ITEM="$SET_WIFI_MENU_ITEM"
    fi

    # Assign the certification tests menu item
    export CERT_MENU_ITEM="$SET_CERT_MENU_ITEM"

    if [ "x$HAS_VIDEO" == "x1" ]; then
        export EYE_ONE_MENU_ITEM="$SET_EYE_ONE_MENU_ITEM"
    fi

    if [ "x$HAS_WAN" == "x1" ]; then
        export WAN_MOLB_MENU_ITEM="$SET_WAN_MOLB_MENU_ITEM"
        export WAN_GSM1900_MENU_ITEM="$SET_WAN_GSM1900_MENU_ITEM"
    fi
}


######################################################################
# Function:     do_set_menu_item_keys
# Purpose:      Dynamically match menu selection keys to enabled
#               diagnostics.
# Paramters:    none
# Returns:      number of active menu items
# Side Effects: Sets the various COMPONENT_MENU_ITEM variables
######################################################################
do_set_menu_item_keys()
{
        if [ -n "$HAS_MOVINAND" ] && [ $HAS_MOVINAND -eq 1 ]; then
            export MOVINAND_MENU_ITEM=$SET_MOVINAND_MENU_ITEM
        fi

        if [ -n "$HAS_DEVICE_SETTINGS" ] && [ $HAS_DEVICE_SETTINGS -eq 1 ]; then
            export DEVICE_SETTINGS_MENU_ITEM=$SET_DEVICE_SETTINGS_MENU_ITEM
        fi

        if [ -n "$HAS_FCT" ] && [ $HAS_FCT -eq 1 ]; then
            export FCT_MENU_ITEM=$SET_FCT_MENU_ITEM
        fi

        if [ -n "$HAS_OPERATOR_SUITE" ] && [ $HAS_OPERATOR_SUITE -eq 1 ]; then
            export OPERATOR_SUITE_MENU_ITEM=$SET_OPERATOR_SUITE_MENU_ITEM
        fi

        if [ -n "$HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ]; then
            export AUDIO_MENU_ITEM=$SET_AUDIO_MENU_ITEM
        fi

        if [ -n "$HAS_ACCELLEROMETER" ] && [ $HAS_ACCELLEROMETER -eq 1 ]; then
            export ACCELLEROMETER_MENU_ITEM=$SET_ACCELLEROMETER_MENU_ITEM
        fi

        if ([ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]) || 
            ([ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]); then
            export FIVE_ONE_ONE_MENU_ITEM=$SET_FIVE_ONE_ONE_MENU_ITEM
        fi

        if [ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
            export WIFI_ART_MENU_ITEM=$SET_WIFI_ART_MENU_ITEM
        fi

        if [ -n "$HAS_RUN_IN" ] && [ $HAS_RUN_IN -eq 1 ]; then
            export RUN_IN_MENU_ITEM=$SET_RUN_IN_MENU_ITEM
        fi

        export BATT_CAP_ADJUST_MENU_ITEM=$SET_BATT_CAP_ADJUST_MENU_ITEM

        if [ "x$DEBUG_POWER_HOG" == "x1" ]; then
            export DEBUG_POWER_HOG_MENU_ITEM="$KEY_Z"
        fi

        if [ -n "$HAS_USB_DEVICE" ] && [ $HAS_USB_DEVICE -eq 1 ]; then
            export USB_DEVICE_MENU_ITEM=$SET_USB_DEVICE_MENU_ITEM
        fi

        if [ -n "$HAS_POWER" ] && [ $HAS_POWER -eq 1 ]; then
            export POWER_MENU_ITEM=$SET_POWER_MENU_ITEM
        fi

        if [ -n "$HAS_GAS_GAUGE" ] && [ $HAS_GAS_GAUGE -eq 1 ]; then
            export GAS_GAUGE_MENU_ITEM=$SET_GAS_GAUGE_MENU_ITEM
        fi

# for development only
#        if [ -n "$HAS_USB_SERIAL_SUPPORT" ] && [ $HAS_USB_SERIAL_SUPPORT -eq 1 ]; then
#            export USB_SERIAL_MENU_ITEM=$SET_USB_SERIAL_MENU_ITEM
#        fi

        if [ -n "$HAS_UPDATE_DIAGS_MENU" ] && [ $HAS_UPDATE_DIAGS_MENU -eq 1 ]; then
            export UPDATE_DIAGS_MENU_ITEM=$SET_UPDATE_DIAGS_MENU_ITEM
        fi

        # Assign the misc diagnostics menu item
        export DIAG_MISC_MENU_ITEM=$SET_DIAG_MISC_MENU_ITEM

        # Everyone supports disable
        DISABLE_DIAGS_MENU_ITEM=$SET_DISABLE_DIAGS_MENU_ITEM
}


######################################################################
# Function:     display_diag_result_summary
# Purpose:      Display a screen with an overall PASSED/FAILED analysis
#               of the system diagnostic results.  If ANY test failed,
#               we fail.  
#
#               If no tests were run, we bypass this dialog.
#
#               Waits for user to hit EXIT_KEY before continuing/clearing
#               screen.
# Paramters:    none
# Returns:      none
######################################################################
display_diag_result_summary()
{
    DO_DISPLAY_SCREEN=1 
    did_system_diags_fail
    RETVAL=$?
    case "$RETVAL" in
        0)  # Diags Passed
            clear_screen
            ${DOUT} -n 20 10 "PASSED"
            ${DOUT} -n 8 16 "System Diagnostic Tests Passed"
            ;;

        2)  # Diags were never run
            DO_DISPLAY_SCREEN=0 
            ;;

        1|*)  # Diags Failed
            clear_screen
            ${DOUT} -n 20 10 "FAILED"
            ${DOUT} -n 8 16 "System Diagnostic Tests Failed"
            ;;
    esac

    if [ $DO_DISPLAY_SCREEN -eq 1 ]; then

        banner="$PRODUCT_NAME Diagnostic Services, version $DIAGNOSTICS_VERSION"
        base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        center_text "$banner" 4 "$base"
        ${DOUT} -n $? 4 "$banner"
        ${DOUT} -n 4 5 "$base"
        ${DOUT} 15 21 "Press $EXIT_KEY_LABEL to continue."
        wait_for_key $EXIT_KEY
    fi
}


######################################################################
# Function:     disable_daemons
# Purpose:      Disable any daemons that cause problems for diagnostics.
# Paramters:    none
# Returns:      none
# Side Effect:  Sets cpufreq into "performance" mode
#               Sets various XX_WAS_KILLED variables
######################################################################
disable_daemons()
{
    # This code chunk is no longer needed as we no longer support running
    # diagnostics from run level 5...  Leaving this commented out in case
    # that changes in the future...
    #
    # Start audioServer if it's not running
    process_running "audioServer"
    running=$?
    if [ $running -ne 1 ]; then
        vmsg "disable_daemons(): Starting audioServer..."
        echo "disable_daemons(): Starting audioServer..."
        # /usr/bin/audioServer &
        /etc/init.d/audio stop  > /dev/null 2>&1
        AUDIOSERVER_WAS_STARTED=1
    fi

    # volumd interferes with USB diagnostics (takes over screen)
    process_running "volumd"
    running=$?
    if [ $running -eq 1 ]; then
        vmsg "disable_daemons(): Killing volumd..."
        echo "disable_daemons(): Killing volumd..."
        /etc/init.d/volumd stop > /dev/null 2>&1
        VOLUMED_WAS_KILLED=1
    else
        vmsg "disable_daemons(): volumd not running to kill..."
    fi

    # powerd interferes in that it will sleep the system, and won't
    # like diags driving power from beneath it.
    process_running "powerd"
    running=$?
    if [ $running -eq 1 ]; then
        vmsg "disable_daemons(): Killing powerd..."
        echo "disable_daemons(): Killing powerd..."
        /etc/init.d/powerd stop > /dev/null 2>&1
        POWERD_WAS_KILLED=1
    else
        vmsg "disable_daemons(): powerd not running to kill..."
    fi

    # framework interferes with many things (input, output, etc)
    # This will not be running unless user executed diags manually
    # (i.e. in init sequence, framework launches AFTER diags quits)
    process_running "framework"
    running=$?
    if [ $running -eq 1 ]; then
        vmsg "disable_daemons(): Killing framework..."
        echo "disable_daemons(): Killing framework..."
        /etc/init.d/framework stop > /dev/null 2>&1
        FRAMEWORK_WAS_KILLED=1
    else
        vmsg "disable_daemons(): framework not running to kill..."
    fi

    # According to Manish, we require the performance governor to do
    # audio, so we're going to set it that way for the entire
    # diagnostics run...
    echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}


######################################################################
# Function:     enable_daemons
# Purpose:      Enable any daemons that we previously disabled.
# Paramters:    none
# Returns:      none
# Side Effect:  Sets cpufreq into "performance" mode
#               Sets various XX_WAS_KILLED variables back to 0
######################################################################
enable_daemons()
{
    if [ $AUDIOSERVER_WAS_STARTED -eq 1 ]; then
        vmsg "enable_daemons(): Starting audioServer..."
        /etc/init.d/audio start > /dev/null 2>&1
        AUDIOSERVER_WAS_STARTED=0
    fi
    if [ $VOLUMED_WAS_KILLED -eq 1 ]; then
        vmsg "enable_daemons(): Starting volumd..."
        /etc/init.d/volumd start > /dev/null 2>&1
        VOLUMED_WAS_KILLED=0
    fi
    if [ $POWERD_WAS_KILLED -eq 1 ]; then
        vmsg "enable_daemons(): Starting powerd..."
        /etc/init.d/powerd start > /dev/null 2>&1
        POWERD_WAS_KILLED=0
    fi
    if [ $FRAMEWORK_WAS_KILLED -eq 1 ]; then
        vmsg "enable_daemons(): Starting framework..."
        /etc/init.d/framework start > /dev/null 2>&1
        FRAMEWORK_WAS_KILLED=0
    fi
    inform_user_framework_start
}


######################################################################
# Function:     display_misc_menu
# Purpose:      Display the misc system diagnostics menu.  This menu
#               is built dynamically based on which diagnostic tests
#               are enabled for this product/platform (defined in
#               the environment.PRODUCT file).
# Paramters:    none
# Returns:      none
######################################################################
display_misc_menu()
{
    clear_screen
    banner="$PRODUCT_NAME Misc Diagnostics"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 4 "$base"
    ${DOUT} -n $? 4 "$banner"
    ${DOUT} -n 4 5 "$base"
    line=7

    if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
        text=`keycode_to_label $VIDEO_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Video"
        let line+=2
    fi
    if [ -n "$HAS_LED" ] && [ $HAS_LED -eq 1 ]; then
        text=`keycode_to_label $LED_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) LED"
        let line+=2
    fi
    if [ -n "$HAS_BUTTONS" ] && [ $HAS_BUTTONS -eq 1 ]; then
        text=`keycode_to_label $BUTTON_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Buttons"
        let line+=2
    fi
    if [ -n "$HAS_KEYBOARD" ] && [ $HAS_KEYBOARD -eq 1 ]; then
        text=`keycode_to_label $KEYBOARD_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Keyboard"
        let line+=2
    fi
    if [ -n "$HAS_FIVEWAY" ] && [ $HAS_FIVEWAY -eq 1 ]; then
        text=`keycode_to_label $FIVEWAY_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) 5-Way"
        let line+=2
    fi
    if [ -n "$HAS_AUDIO" ] && [ $HAS_AUDIO -eq 1 ]; then
        text=`keycode_to_label $AUDIO_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Audio"
        let line+=2
    fi
    if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $WAN_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) WAN"
        let line+=2
    fi
    if [ -n "$HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
        text=`keycode_to_label $WIFI_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) WIFI"
        let line+=2
    fi

    # All products support Certification Tests
    text=`keycode_to_label $CERT_MENU_ITEM`
    ${DOUT} -n 8 $line "$text) Certification Test Modes"
    let line+=2

    if [ -n "$HAS_VIDEO" ] && [ $HAS_VIDEO -eq 1 ]; then
        text=`keycode_to_label $EYE_ONE_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Eye-One Optical Test"
        let line+=2
    fi

    if [ -n "$HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
        text=`keycode_to_label $WAN_MOLB_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Originate Call WAN Test"
        let line+=2
        text=`keycode_to_label $WAN_GSM1900_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) GSM 1900 Band WAN Test"
        let line+=2
    fi

    # All devices support exit
    let line+=2
    ${DOUT} 8 $line "$EXIT_KEY_LABEL) Return to main diagnostic menu"
}


######################################################################
# Function:     display_menu
# Purpose:      Display the main system diagnostics menu.  This menu
#               is built dynamically based on which diagnostic tests
#               are enabled for this product/platform (defined in
#               the environment.PRODUCT file).
# Paramters:    none
# Returns:      none
######################################################################
display_menu()
{
    clear_screen
    banner="$PRODUCT_NAME Diagnostic Services, version $DIAGNOSTICS_VERSION"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 4 "$base"
    ${DOUT} -n $? 2 "$banner"
    ${DOUT} -n 4 3 "$base"
    line=5

    if [ "x$HAS_MOVINAND" == "x1" ]; then
        text=`keycode_to_label $MOVINAND_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) MoviNand"
        let line+=2
    fi

    if [ "x$HAS_DEVICE_SETTINGS" == "x1" ]; then
        text=`keycode_to_label $DEVICE_SETTINGS_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Device Settings"
        let line+=2
    fi

    if [ "x$HAS_FCT" == "x1" ]; then
        text=`keycode_to_label $FCT_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) FCT"
        let line+=2
    fi

    if [ "x$HAS_OPERATOR_SUITE" == "x1" ]; then
        text=`keycode_to_label $OPERATOR_SUITE_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Operator Test Suite"
        let line+=2
    fi

    if [ "x$HAS_ACCELLEROMETER" == "x1" ]; then
        text=`keycode_to_label $ACCELLEROMETER_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Accelerometer"
        let line+=2
    fi

    if ([ "x$HAS_WAN" == "x1" ]) || ([ "x$HAS_WIFI" == "x1" ]); then
        text=`keycode_to_label $FIVE_ONE_ONE_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) 511"
        let line+=2
    fi

    if [ "x$HAS_RUN_IN" == "x1" ]; then
        text=`keycode_to_label $RUN_IN_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Run-in"
        let line+=2
    fi
    
    if [ "x$HAS_WIFI" == "x1" ]; then
        text=`keycode_to_label $WIFI_ART_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) WIFI ART"
        let line+=2
    fi

    if [ "x$HAS_AUDIO" == "x1" ]; then
        text=`keycode_to_label $AUDIO_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Audio"
        let line+=2
    fi

    text=`keycode_to_label $BATT_CAP_ADJUST_MENU_ITEM`
    ${DOUT} -n 8 $line "$text) Adjust Battery Level For Ship"
    let line+=2

    if [ "x$DEBUG_POWER_HOG" == "x1" ]; then
        text=`keycode_to_label $DEBUG_POWER_HOG_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Debug Power Hogs"
        let line+=2
    fi

    if [ "x$HAS_USB_DEVICE" == "x1" ]; then
        text=`keycode_to_label $USB_DEVICE_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) USB Device Mode"
        let line+=2
    fi

    if [ "x$HAS_POWER" == "x1" ]; then
        text=`keycode_to_label $POWER_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Power"
        let line+=2
    fi

    if [ "x$HAS_GAS_GAUGE" == "x1" ]; then
        text=`keycode_to_label $GAS_GAUGE_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Gas Gauge"
        let line+=2
    fi

    # Put up MISC menu
    text=`keycode_to_label $DIAG_MISC_MENU_ITEM`
    ${DOUT} -n 8 $line "$text) Misc Individual Diagnostics"
    let line+=2

# for development only
#    if [ -n "$HAS_USB_SERIAL_SUPPORT" ] && [ $HAS_USB_SERIAL_SUPPORT -eq 1 ]; then
#        text=`keycode_to_label $USB_SERIAL_MENU_ITEM`
#        ${DOUT} -n 8 $line "$text) Serial Over USB"
#        let line+=2
#    fi

    if [ "x$HAS_UPDATE_DIAGS_MENU" == "x1" ]; then
        text=`keycode_to_label $UPDATE_DIAGS_MENU_ITEM`
        ${DOUT} -n 8 $line "$text) Update System Diagnostics"
        let line+=2
    fi

    # All devices support disable
    text=`keycode_to_label $DISABLE_DIAGS_MENU_ITEM`
    ${DOUT} -n 8 $line "$text) Disable Auto-run Of Diagnostics"

    # All devices support exit
    let line+=2
    ${DOUT} 8 $line "$EXIT_KEY_LABEL) Exit Diagnostic Services"
}


######################################################################
# Function:     do_create_factory_fresh_flag
# Purpose:      Create the factory fresh flag, and tell the user if
#               something bad happened and we couldn't create the flag.
# Paramters:    none
# Returns:      none
######################################################################
do_create_factory_fresh_flag()
{
    # Crete factory fresh flag...
    echo 0 > "${FLAG_FACTORY_FRESH}"
    if ! [ -f "${FLAG_FACTORY_FRESH}" ]; then
        echo "Failed to create FLAG_FACTORY_FRESH file ${FLAG_FACTORY_FRESH}"
        clear_screen
        ${DOUT} -n 10 4 "$PRODUCT_NAME Diagnostic Services"
        ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 6 7 "Failed to create the FLAG_FACTORY_FRESH file"
        ${DOUT} -n 6 9 "${FLAG_FACTORY_FRESH}."
        ${DOUT} 6 13 "Press $EXIT_KEY_LABEL to continue."
        wait_for_key $EXIT_KEY
    fi
}


######################################################################
# Function:     ask_retest_operator_suite
# Purpose:      Ask operator if they want to rerun the tests that failed
# Parameters:   none
# Returns:      0 - Do not rerun failed tests
#				1 - Rerun failed tests
######################################################################
ask_retest_operator_suite()
{
    clear_screen
    ${DOUT} -n 10 4 "$PRODUCT_NAME Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 6 7 "Do you want to rerun the failed tests?"
    ${DOUT} -n 6 11 "YES) Press $SUCCESS_KEY_LABEL to rerun failed tests"
    ${DOUT} 6 13 "NO) Press $FAILURE_KEY_LABEL to exit Operator Test Suite".

    _DONE=0
    while [ ${_DONE} -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        case "$KEY" in
            $SUCCESS_KEY) return 1; ;;
            $FAILURE_KEY) return 0; ;;
            *) ;;
        esac
    done
}


######################################################################
# Function:     run_operator_suite
# Purpose:      Run suite of operator-based diagnostics
# Paramters:    none
# Returns:      0 - All tests passed
#				2 - One or more of the subtests failed
######################################################################
run_operator_suite()
{
    # Initialize the diagnostic logfile so it starts with operator_suite results
    init_diaglog

	# Reset any previous failure status
	clear_diag_fail
    _SUITE_RESULT=0
    _OVERALL_SUITE_RESULT=0
    _OP_VIDEO_PASSED=0
    _OP_LED_PASSED=0
    _OP_BUTTONS_PASSED=0
    _OP_KEYBOARD_PASSED=0
    _OP_FIVEWAY_PASSED=0
    _OP_AUDIO_PASSED=0
    _OP_WIFI_PASSED=0
    _OP_WAN_PASSED=0
    _LOOP=1

    while [ ${_LOOP} -eq 1 ]; do
        if [ "x$HAS_WAN" == "x1" ] && [ $WAN_NEVER_POWERED -eq 1 ]; then
            # First time WAN launches, it takes an extra 20 seconds (see SHA-4719).
            # We soak it up by powering WAN on in the background while running these
            # other tests.  This violates our "only power HW on when testing it", but
            # saves the factory 20 seconds on the line.
            wan_power_cycle_modem &
        fi

        if [ "x$HAS_VIDEO" == "x1" ] && [ ${_OP_VIDEO_PASSED} -eq 0 ]; then
            vmsg "Starting Video Test..."
            ${RUN_VIDEO} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_VIDEO_PASSED=1
    		fi
        fi

        if [ "x$HAS_LED" == "x1" ] && [ ${_OP_LED_PASSED} -eq 0 ]; then
            vmsg "Starting LED Test..."
            ${RUN_LED} $BYPASS_SUCCESS_DIALOGS
     		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_LED_PASSED=1
    		fi
        fi

        if [ "x$HAS_BUTTONS" == "x1" ] && [ ${_OP_BUTTONS_PASSED} -eq 0 ]; then
            vmsg "Starting Button Test..."
            ${RUN_BUTTON} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_BUTTONS_PASSED=1
    		fi
        fi

        if [ "x$HAS_KEYBOARD" == "x1" ] && [ ${_OP_KEYBOARD_PASSED} -eq 0 ]; then
            vmsg "Starting Keyboard Test..."
            ${RUN_KEYBOARD} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_KEYBOARD_PASSED=1
    		fi
        fi

        if [ "x$HAS_FIVEWAY" == "x1" ] && [ ${_OP_FIVEWAY_PASSED} -eq 0 ]; then
            vmsg "Starting 5-Way Test..."
            ${RUN_5WAY} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_FIVEWAY_PASSED=1
    		fi
        fi

        if [ "x$HAS_AUDIO" == "x1" ] && [ ${_OP_AUDIO_PASSED} -eq 0 ]; then
            vmsg "Starting Audio Test..."
            # Bypass success dialogs and jump directly into Full Test Suite
            ${RUN_AUDIO_FULL_SUITE} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_AUDIO_PASSED=1
    		fi
        fi

        if [ "x$HAS_WIFI" == "x1" ] && [ ${_OP_WIFI_PASSED} -eq 0 ]; then
            vmsg "Starting WIFI Test..."
            ${RUN_WIFI} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_WIFI_PASSED=1
    		fi
        fi
    

        #
        # Make sure WAN power down operation has finished
        # Otherwise, error will get flagged in WAN test below
        #
        if [ "x$HAS_WAN" == "x1" ] && [ $WAN_NEVER_POWERED -eq 1 ]; then
            # Make sure the power cycle has completed
            wan_power_verify_fct $WAN_POWER_OFF
            if [ $? -eq 0 ]; then
                export WAN_NEVER_POWERED=0 
            fi
        fi

        if [ "x$HAS_WAN" == "x1" ] && [ ${_OP_WAN_PASSED} -eq 0 ]; then
            vmsg "Starting WAN Test..."
            ${RUN_WAN} $BYPASS_SUCCESS_DIALOGS
    		if [ "$?" -ne 0 ]; then
                _SUITE_RESULT=2
            else
                _OP_WAN_PASSED=1
    		fi
        fi

        # If we had any failures, see if they want to try those again
        if [ ${_SUITE_RESULT} -ne 0 ]; then
            echo "Asking for retest..."
            # Remember the failure
            _OVERALL_SUITE_RESULT=2
            ask_retest_operator_suite
            if [ $? -eq 0 ]; then
                # Exit while loop, operator does not wish to retest
                _LOOP=0
            else
                # Reset our local result for the next pass
                _SUITE_RESULT=0
            fi
        else
            _LOOP=0
        fi
    done

    # Create and save operator logfile, don't overwrite (make unique)
    save_diaglog 0 1

    return ${_OVERALL_SUITE_RESULT}
}

do_diagnostic_folder_export()
{
    do_export_usb_volumes "Diagnostics Updater"
    clear_screen
    _base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
    _banner="System Diagnostics Updater" 
    print_center_text "$_banner" "$_base" 5 4
    ${DOUT} -n 4 8 "The USB volume has been exported."
    ${DOUT} -n 4 11 "Copy diagnostics factory folder to"
    ${DOUT} -n 4 12 "the exported volume."
    ${DOUT} 4 15 "Press $SUCCESS_KEY_LABEL when done to install new diags."

    wait_for_key $SUCCESS_KEY
    un_export_usb_volumes "Diagnostics Updater"

    # If we haven't determined yet where user store is, do so now
    if ! [ -n $DEVICE_USER_STORE ]; then
        _USER_STORE_PARTITION="`kdb get system/driver/filesystem/DEV_PART_USERSTORE`"
        _DEVICE_ROOT="`kdb get system/driver/filesystem/DEV_ROOT`"
        export DEVICE_USER_STORE="${_DEVICE_ROOT}${_USER_STORE_PARTITION}"
    fi

    # Copy the new diags from user store into place
    _DIAG_SRC_DIR="$USB_EXPORT_VOLUME/factory"
    if [ -d "$_DIAG_SRC_DIR" ]; then
        clear_screen
        print_center_text "$_banner" "$_base" 5 4
        _line_banner="Updating diagnostics now."
        center_text "$_line_banner" 5 "$_base"
        ${DOUT} -n $? 8 "$_line_banner"
        _line_banner="This screen will disappear when done."
        center_text "$_line_banner" 5 "$_base"
        ${DOUT} $? 11 "$_line_banner"
        mntroot_rw
        cp -a ${_DIAG_SRC_DIR}/* /test/diags/factory/.
        sync
        mntroot_ro > /dev/null 2>&1
        if ! [ -d /test/diags/factory/tests ]; then
            clear_screen
            print_center_text "$_banner" "$_base" 5 4
            ${DOUT} -n 4 8 "ERROR updating diagnostics !"
            ${DOUT} 4 15 "Press $SUCCESS_KEY_LABEL to reboot now."
            wait_for_key $SUCCESS_KEY
        fi
        echo "Rebooting to activate new diagnostics...."
        reboot
        sleep 100
    else
        clear_screen
        print_center_text "$_banner" "$_base" 5 4
        center_text "$_DIAG_SRC_DIR not found." 5 "$_base"
        ${DOUT} -n 4 8 "$_DIAG_SRC_DIR not found."
        ${DOUT} 4 15 "Press $SUCCESS_KEY_LABEL to return to main menu."
        wait_for_key $SUCCESS_KEY
    fi
}


# temporary way to modify the code while in diags mode.
# this implementation is to help debugging the SSP station.
# will be removed later.
# TODO: remove the code after the SSP station is up and running.
executing_external_cmd()
{
    export CMD_SRC_DIR="/mnt/base-us"
    export CMD_DEST_DIR="/var/tmp/root"
    if [ -s "$CMD_SRC_DIR/cmd.sh" ]; then
        cp $CMD_SRC_DIR/cmd.sh $CMD_DEST_DIR/cmd.sh
        chmod +x $CMD_DEST_DIR/cmd.sh
        $CMD_DEST_DIR/cmd.sh
    fi
}

######################################################################
# Function:     run_diagnostic_misc_menu
# Purpose:      Sub-menu area for executing individual diagnostic
#               tests that are now part of the operator test suite
# Paramters:    none
# Returns:      none
######################################################################
run_diagnostic_misc_menu()
{
  DO_EXIT=0
  DONT_REDRAW_MENU=0
    
  DIAGS_HAVE_BEEN_DISABLED=0

  # Define menu keys
  do_set_misc_menu_item_keys

  # Process user requests
  while [ $DO_EXIT -ne 1 ]; do

    # Put up main diagnostic menu
    #
    if [ $DONT_REDRAW_MENU -eq 0 ]; then
        display_misc_menu
    else
        # DONT_REDRAW_MENU is a one-shot, so reset it now
        DONT_REDRAW_MENU=0
    fi
 
    #
    # Get the key request
    #
    KEY=`$GET_KEYBOARD_INPUT`

    #
    # Process key request
    case "$KEY" in

    $VIDEO_MENU_ITEM)
        vmsg "Starting Video Test..."
        logger -t diags_menu -s "MISC: Video selected"
        ${RUN_VIDEO}
        ;;

    $LED_MENU_ITEM)
        vmsg "Starting LED Test..."
        logger -t diags_menu -s "MISC: LED selected"
        ${RUN_LED}
        ;;

    $BUTTON_MENU_ITEM)
        vmsg "Starting Button Test..."
        logger -t diags_menu -s "MISC: Button selected"
        ${RUN_BUTTON}
        ;;

    $KEYBOARD_MENU_ITEM)
        vmsg "Starting Keyboard Test..."
        logger -t diags_menu -s "MISC: Keyboard selected"
        ${RUN_KEYBOARD}
        ;;

    $FIVEWAY_MENU_ITEM)
        vmsg "Starting 5-Way Test..."
        logger -t diags_menu -s "MISC: Fiveway selected"
        ${RUN_5WAY}
        ;;

    $AUDIO_MENU_ITEM)
        vmsg "Starting Audio Test..."
        logger -t diags_menu -s "MISC: Audio selected"
        ${RUN_AUDIO}
        ;;

    $WAN_MENU_ITEM)
        vmsg "Starting WAN Test..."
        logger -t diags_menu -s "MISC: WAN selected"
        ${RUN_WAN}
        ;;

    $WIFI_MENU_ITEM)
        vmsg "Staring WIFI Test..."
        logger -t diags_menu -s "MISC: WIFI selected"
        ${RUN_WIFI}
        ;;

    $CERT_MENU_ITEM)
        vmsg "Staring Certification Menu..."
        logger -t diags_menu -s "MISC: Certification selected"
        clear_screen
        print_center_text "Certification Test Initialization" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 5 4
        ${DOUT} 5 7 "Initializing Certification Module Now..."
        ${RUN_CERT}
        ;;

    $EYE_ONE_MENU_ITEM)
        logger -t diags_menu -s "MISC: Eye-one selected"
        video_do_eye_one_test
        ;;
   
    $WAN_MOLB_MENU_ITEM)
        logger -t diags_menu -s "MISC: MOLB selected"
        wan_molb_test
        ;;

    $WAN_GSM1900_MENU_ITEM)
        logger -t diags_menu -s "MISC: GSM1900 selected"
        wan_gsm_1900_test
        ;;

# for development only
#    $USB_SERIAL_MENU_ITEM)
#        vmsg "Staring USB Serial Test..."
#        logger -t diags_menu -s "MISC: USB Serial selected"
#        do_usb_serial
#        ;;

    $EXIT_KEY)
        logger -t diags_menu -s "MISC: Exit selected"
        vmsg "Exiting back to main Diagnostic Services menu..."
        DO_EXIT=1
        ;;

    *)
        DONT_REDRAW_MENU=1
        ;;
    esac
  done;
}



######################################################################
# Function:     run_diagnostic_menu
# Purpose:      Drives main diagnostic menu
# Paramters:    none
# Returns:      0 - Diags have not yet been disabled
#               1 - Diags have been disabled
######################################################################
run_diagnostic_menu()
{
  DO_RETURN=0
  DONT_REDRAW_MENU=0
    
  DIAGS_HAVE_BEEN_DISABLED=0

  # Define menu keys
  do_set_menu_item_keys

  # Report System Diagnostic information to logfile
  logger -t diags -s "$PRODUCT_NAME Diagnostic Services $DIAGNOSTICS_VERSION"
  logger -t diags -s "FS Version: $SOFTWARE_FS_VERSION"
  logger -t diags -s "FS Build Date: $SOFTWARE_FS_BUILD_DATE"

  # Process user requests
  while [ $DO_RETURN -ne 1 ]; do

    # Put up main diagnostic menu
    #
    if [ $DONT_REDRAW_MENU -eq 0 ]; then
        display_menu
    else
        # DONT_REDRAW_MENU is a one-shot, so reset it now
        DONT_REDRAW_MENU=0
    fi
 
    #
    # Get the key request
    #
    KEY=`$GET_KEYBOARD_INPUT`

    #
    # Process key request
    case "$KEY" in

    $DIAG_MISC_MENU_ITEM)
        vmsg "Diagnostic Misc. Menu selected..."
        logger -t diags_menu -s "Diagnostic Misc. Menu selected"
        run_diagnostic_misc_menu
        ;;

    $FIVE_ONE_ONE_MENU_ITEM)
        vmsg "Starting 511 Test..."
        logger -t diags_menu -s "511 selected"
        if [ -n "HAS_WAN" ] && [ $HAS_WAN -eq 1 ]; then
            wan_511_test
        elif [ -n "HAS_WIFI" ] && [ $HAS_WIFI -eq 1 ]; then
            wifi_511_test
        fi
        ;;
        
    $USB_DEVICE_MENU_ITEM)
        vmsg "Starting USB Device Test..."
        logger -t diags_menu -s "USB Device selected"
        ${RUN_USB_DEVICE}
        ;;

    $POWER_MENU_ITEM)
        vmsg "Starting Power Test..."
        logger -t diags_menu -s "Power selected"
        ${RUN_POWER}
        ;;

    $GAS_GAUGE_MENU_ITEM)
        vmsg "Starting Gas Gauge Test..."
        logger -t diags_menu -s "Gas Gauge selected"
        ${RUN_GAS_GAUGE}
        ;;

    $UPDATE_DIAGS_MENU_ITEM)
        vmsg "Exporting diagnostics folder..."
        logger -t diags_menu -s "Update Diagnotic Folder selected"
        do_diagnostic_folder_export
        ;;

    $WIFI_ART_MENU_ITEM)
        vmsg "Staring WIFI ART factory Test..."
        logger -t diags_menu -s "WIFI ART factory test selected"
        # ${RUN_WIFI_ART}
        do_run_wifi_art_factory_diag
        ;;
                     
    $AUDIO_MENU_ITEM)
        vmsg "Starting Audio Test..."
        logger -t diags_menu -s "Audio selected"
        ${RUN_AUDIO}
        ;;

# for development only
#    $USB_SERIAL_MENU_ITEM)
#        vmsg "Staring USB Serial Test..."
#        logger -t diags_menu -s "USB Serial Test selected"
#        do_usb_serial
#        ;;

    $MOVINAND_MENU_ITEM)
        vmsg "Staring moviNand Test..."
        logger -t diags_menu -s "MoviNand selected"
        ${RUN_MOVINAND}
        ;;

    $RUN_IN_MENU_ITEM)
        vmsg "Displaying Run-in enable menu..."
        logger -t diags_menu -s "Run-in selected"
        # It takes the run modes feature a few seconds to initialize
        # as it includes all the hals...
        # Put up a screen here informing user that we're processing their request...
        clear_screen
        print_center_text "Run-in Initialization" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 5 4
        ${DOUT} 7 7 "Initializing Run-in module now..."
        ${RUN_MODES}
        ;;

    $DEBUG_POWER_HOG_MENU_ITEM)
        vmsg "Starting Power hog debug..."
        logger -t diags_menu -s "Power hog debug selected"
        debug_power_hog
        ;;

    $BATT_CAP_ADJUST_MENU_ITEM)
        vmsg "Starting Ship Battery Capacity Adjustment..."
        logger -t diags_menu -s "Adjust Battery Capacity to Ship Level selected"
        START_TIME=`date`
        START_CAP=`${BATTERY_CAPACITY}`
        adjust_battery_to_ship_mode
        END_TIME=`date`
        END_CAP=`${BATTERY_CAPACITY}`
        echo "Start Time: $START_TIME"
        echo "End Time: $END_TIME"
        echo "Start Capacity: $START_CAP"
        echo "Final Capacity: $END_CAP"
        ;;

    $ACCELLEROMETER_MENU_ITEM)
        vmsg "Staring Accelerometer Test..."
        logger -t diags_menu -s "Accelerometer selected"
        ${RUN_ACCELEROMETER}
        ;;

    $DISABLE_DIAGS_MENU_ITEM)
        vmsg "Disable diagnostics menu item selected"
        logger -t diags_menu -s "Disable diagnostics selected"

        # Suck off possible return character
        KEY=`$GET_KEYBOARD_INPUT 1`
        clear_screen


        # Save logfile, don't overwrite (make unique), no operator log
        save_diaglog 0 0

        # Copy log files to user store and export them
        showlog | gzip > "$DIAG_LOG_ROOT/messages.gz"

		# Create the device info file
		dev_create_device_info_log

		# Export the user store
        export_usb_volumes

        text=`keycode_to_label $MENU_ITEM_1`
        banner="Disable Diagnostics Auto-run"
        base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        center_text "$banner" 5 "$base"
        ${DOUT} -n $? 4 "$banner"
        ${DOUT} -n 5 5 "$base"
        ${DOUT} -n 5 7 "The diagnostic log files have been exported."
        ${DOUT} -n 5 9 "Connect the device to a PC with the USB"
        ${DOUT} -n 5 11 "cable now if you want to pull diagnostic"
        ${DOUT} -n 5 13 "log files."
        ${DOUT} -n 5 17 "Press $text now to disable diagnostics."
        ${DOUT} 5 19 "Press any other key to cancel."
        KEY=`$GET_KEYBOARD_INPUT`
        case "$KEY" in 
            $MENU_ITEM_1)
                un_export_usb_volumes
                echo "Disabling auto-run of system-level diagnostics..."
                vmsg "Disabling auto-run of system-level diagnostics..."
                disable_autorun
                user_disable_failed="$?"
                if [ $user_disable_failed -eq 1 ]; then
                    display_user_disable_autorun_screen 0
                elif [ $user_disable_failed -eq 0 ]; then
                    DO_RETURN=1
                    DIAGS_HAVE_BEEN_DISABLED=1
                    do_create_factory_fresh_flag
                fi
                ;;
            *)
                un_export_usb_volumes
                if [ -f "$DIAG_TARGET_LOGFILE" ]; then
                    rm -rf "$DIAG_TARGET_LOGFILE"
                fi
                ;;
        esac
        ;;

    $DEVICE_SETTINGS_MENU_ITEM)
        vmsg "Launching device settings module..."
        logger -t diags_menu -s "Device Settings selected"
        # Put up screen to let user know this takes a few seconds.
        clear_screen
        ${DOUT} -n 16 4 "Device Settings"
        ${DOUT} -n 5 5  "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 7 7 "Gathering device information."
        ${DOUT} 7 9 "This will take a few seconds..."
        ${RUN_DEVICE_SETTINGS}
        _DONT_REBOOT_DEVICE="$?"
        if [ ${_DONT_REBOOT_DEVICE} -eq 0 ]; then
            # Setting device parameters requires a reboot...
            clear_screen
            ${DOUT} -n 16 4 "Device Settings"
            ${DOUT} -n 5 5  "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            ${DOUT} -n 7 7 "Device settings have been changed."
            ${DOUT} 7 9 "Rebooting now so changes take effect..."
            sleep 3
            DO_RETURN=1
        fi
        ;;

    $FCT_MENU_ITEM)
        vmsg "Staring FCT..."
        logger -t diags_menu -s "FCT selected"
        # this code is to help debugging the SSP station.
        # TODO: need to remove the code after the SSP station is up and running
        # executing_external_cmd
        ${RUN_FCT}
        ;;

    $OPERATOR_SUITE_MENU_ITEM)
        vmsg "Starting Operator Suite..."
        logger -t diags_menu -s "Operator Test Suite selected"
        run_operator_suite
        ;;
        
    $EXIT_KEY)
        vmsg "Exiting Diagnostic Services..."
        logger -t diags_menu -s "Exit Diagnostic Services selected"
        DO_RETURN=1
        ;;

    *)
        DONT_REDRAW_MENU=1
        ;;
    esac
  done;
  return $DIAGS_HAVE_BEEN_DISABLED
}

case "$1" in

    stop)
        vmsg "Stopping Diagnostic Services..."
        ;;

    start|*)
        vmsg "Starting Diagnostic Services..."
        logger -t diags -s "Starting System Diagnostics version $DIAGNOSTICS_VERSION"


        # Set printk level up to maximum
        echo 7 > /proc/sys/kernel/printk

        # Load up file system version, date variables, and
        # specific device information
        get_sw_version

        #
        # Tell the EINK driver that diagnostics is running so
        # that it doesn't limit display control on us....
        #
        if [ -f ${_RUNNING_DIAGS_CTRL} ]; then
            echo 1 > ${_RUNNING_DIAGS_CTRL} 
        else
            echo "ERROR: Can not find ${_RUNNING_DIAGS_CTRL}"
        fi

        # This call to disable_daemons() should only be needed if 
        # trying to run diags from run level 5.  It takes time to
        # run it, and is not needed in normal operation, so I'm 
        # disabling it.
        #
        # disable_daemons

        #
        # Disable the 1725 compliance mechanism (avoid strict charge/battery behaviors)
        #
        if [ -f "$_CHARGER_1725_COMPLIANCE_DISABLE_ENTRY" ]; then
            echo "Disabling 1725 charger compliance"
            echo "1" > "$_CHARGER_1725_COMPLIANCE_DISABLE_ENTRY"
        else
            echo "1725 charger compliance sys entry not found..."
        fi

        init_diaglog

        # If the previous session aborted, delete flag file and echo status
        if [ -f ${DIAGNOSTIC_PROC_ABORTED_FILE} ]; then
            do_local_echo "ERROR: Previous diagnostic session aborted !!"
            rm -rf "${DIAGNOSTIC_PROC_ABORTED_FILE}"
        fi

        # If we have WAN (not on a WFO), start wand in diagnostic mode
        # WARNING - this will call wand on a wifi-only device if it's
        # a boot cycle prior to the operator using Device Settings diagnostic
        # to set the PCB ID (which is how Shasta_WFO is identified).
        # If it becomes a problem to call wand without modem module, then 
        # check to make sure PCB ID is set prior to checking is_Shasta_WFO()
        # and skip wand call if we're on a Shasta and the PCB ID is not set.
        #
        if ! ( is_Shasta_WFO ); then
            do_local_echo "Starting wand in diags mode..."
            /usr/sbin/wand -D > /dev/null 2>&1
        fi

        # Enable the accessories port
        if [ "x$HAS_ACCESSORY_PORT" == "x1" ]; then
            enable_accessory_port
        fi

        logger -t diags -s "Displaying main System Diags Menu"

        run_diagnostic_menu
        diags_disabled="$?"

        display_diag_result_summary
        dump_diaglog

        # Clear screen before rebooting
        if [ $diags_disabled -eq 0 ]; then
            clear_screen
            # Save logfile, don't overwrite (make unique)
            save_diaglog 0
        else
            display_user_disable_autorun_screen 1
        fi

        # Disable the accessories port
        if [ "x$HAS_ACCESSORY_PORT" == "x1" ]; then
            disable_accessory_port
        fi

        # For now, don't allow exit to framework...
        # instead, reboot device to assure a prestine
        # runtime environment.
        # If user didn't disable diags, we're back here again...
        reboot

        # With reboot above, we never reach here...
        enable_daemons
        ;;

esac


