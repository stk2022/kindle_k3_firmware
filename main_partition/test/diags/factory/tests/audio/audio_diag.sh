#!/bin/sh
######################################################################
#
#  File:   audio_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/10/08
#
#  Copyright (C) 2005-2010 Amazon Technologies
#
#  Description:
#      Contains the audio diagnostic.
#
#   Constants
#       DEFAULT_VOLUME_OUT          - Default output volume for audio tests
#       DEFAULT_LEFT_VOLUME_OUT     - Default output volume for left channel tests
#       DEFAULT_RIGHT_VOLUME_OUT    - Default output volume for right channel tests
#       DEFAULT_AUTOMATED_VOLUME_OUT- Default output volume for automated speaker tests
#       CHANNEL_NONE                - No channels
#       CHANNEL_ALL                 - All channels (hp stereo, speaker stereo)
#       CHANNEL_HP_LEFT             - Left hp channel
#       CHANNEL_HP_RIGHT            - Right hp channel
#       CHANNEL_HP_STEREO           - Stereo headphone channels
#       CHANNEL_SPEAKER_LEFT        - Left speaker channel
#       CHANNEL_SPEAKER_RIGHT       - Right speaker channel
#       CHANNEL_SPEAKER_STEREO      - Stereo speaker channel
#       CHANNEL_ALL_SPEAKER         - Stereo speaker channels (for automated speaker tests)
#
#   Routines
#       audio_diag_display_menu()           - Display main audio diagnostic menu
#       show_hal_init_failure_message()     - Tell user about audio feature failure
#       display_hp_detect_menu()            - Display the headphone insertion message
#       do_run_hp_in_detect()               - Run headphone insert detection diag
#       audio_display_hp_left_menu()        - Display hp left confirmation screen
#       audio_hp_left_get_process_choice()  - Get operator response to hp left test
#       do_hp_left_diag()                   - Run headphone left diagnotic
#       audio_hp_right_display_menu()       - Display hp right confirmation screen
#       audio_hp_right_get_process_choice() - Get operator response to hp right test
#       do_hp_right_diag()                  - Run headphone right diagnotic
#       audio_hp_stereo_display_menu()      - Display hp stereo confirmation screen
#       audio_hp_stereo_get_process_choice()- Get operator response to hp stereo test
#       do_hp_stereo_diag()                 - Run headphone stereo diagnotic
#       audio_hp_out_detect_display_menu()  - Display "Remove headphones" screen
#       audio_hp_out_detect_get_process_choice() - Get operator response to hp out test
#       do_hp_out_detect_diag()             - Run headphone out diagnotic
#       audio_speaker_left_display_menu()   - Display left speaker confirmation screen
#       audio_speaker_left_get_process_choice() - Get operator response to left speaker test
#       do_left_speaker_diag()              - Run left speaker diagnostic
#       audio_speaker_right_display_menu()  - Display right speaker confirmation screen
#       audio_speaker_right_get_process_choice() - Get operator response to right speaker test
#       do_right_speaker_diag()             - Run right speaker diagnostic
#       audio_all_speaker_get_process_choice- Get operator response to automated speaker test
#       audio_all_speaker_display_menu()    - Display automated speaker test confirm screen
#       audio_speaker_stereo_display_menu() - Display stereo speaker confirmation screen
#       audio_speaker_stereo_get_process_choice() - Get operator response to stereo speaker test
#       do_stereo_speaker_diag()            - Run stereo speaker diagnostic
#       audio_run_suite()                   - Run through entire audio test suite
#       audio_do_run_diag()                 - Display main audio diagnost menu, service test requests
#       audio_start_cycle_test()            - Start a sound playing for "cycle" test
#       audio_stop_cycle_test()             - Stop any sound files currently playing
#
######################################################################

# Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Sound HAL Functions
[ -f ${_AUDIO_HAL_FUNCTIONS} ] && . ${_AUDIO_HAL_FUNCTIONS}

# USB Hal Function...
[ -f ${_USB_HAL_FUNCTIONS} ] && . ${_USB_HAL_FUNCTIONS}

#
# Default volume for the audio diagnostic tests
#
export DEFAULT_VOLUME_OUT="$DEFAULT_VOLUME"
export DEFAULT_LEFT_VOLUME_OUT="$DEFAULT_VOLUME"
export DEFAULT_RIGHT_VOLUME_OUT="$DEFAULT_VOLUME"


# audio state

export AUDIO_STATE_OFF=0
export AUDIO_STATE_BYPASS=1
export AUDIO_STATE_AUTOMATED_SPEAKER=2

export AUDIO_STATE=0

#
# Audio diagnostic menu items - map to top row of keyboard
#
AUDIO_SUITE_MENU_ITEM=$MENU_ITEM_1
AUDIO_HP_DETECT_MENU_ITEM=$MENU_ITEM_2
AUDIO_HP_LEFT_MENU_ITEM=$MENU_ITEM_3
AUDIO_HP_RIGHT_MENU_ITEM=$MENU_ITEM_4
AUDIO_HP_STEREO_MENU_ITEM=$MENU_ITEM_5
AUDIO_SPEAKER_LEFT_MENU_ITEM=$MENU_ITEM_6
AUDIO_SPEAKER_RIGHT_MENU_ITEM=$MENU_ITEM_7
AUDIO_SPEAKER_STEREO_MENU_ITEM=$MENU_ITEM_8
AUDIO_AUTOMATED_SPEAKER_MENU_ITEM=$MENU_ITEM_9

if [ -n "$HAS_MICROPHONE" ] && [ "$HAS_MICROPHONE" -ne 0 ]; then
	AUDIO_MIC_MENU_ITEM=$MENU_ITEM_10
	AUDIO_MIC_CAPTURE_MENU_ITEM=501
else
	AUDIO_MIC_MENU_ITEM=500
	AUDIO_MIC_CAPTURE_MENU_ITEM=501
fi

# Enable audio debug menu if requested
if [ -n "$HAS_AUDIO_DEBUG" ] && [ "$HAS_AUDIO_DEBUG" -ne 0 ]; then
    AUDIO_DEBUG_MENU_ITEM=$MENU_ITEM_11
else
    # disable the menu item
    AUDIO_DEBUG_MENU_ITEM=502
fi

#
# Sound channel constants for use as parameter when calling
#    enable_channel() and disable_channel()
#
export  CHANNEL_NONE=0
export  CHANNEL_ALL=1
export  CHANNEL_HP_LEFT=2
export  CHANNEL_HP_RIGHT=3
export  CHANNEL_HP_STEREO=4
export  CHANNEL_SPEAKER_LEFT=5
export  CHANNEL_SPEAKER_RIGHT=6
export  CHANNEL_SPEAKER_STEREO=7



######################################################################
# Function:     audio_diag_display_menu
# Purpose:      Display the main audio diagnostic menu.
# Paramters:    none
# Returns:      none
######################################################################
audio_diag_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    text=`keycode_to_label $AUDIO_SUITE_MENU_ITEM`
    ${DOUT} -n 8 8 "$text) Run Full Test Suite"
    text=`keycode_to_label $AUDIO_HP_DETECT_MENU_ITEM`
    ${DOUT} -n 8 10 "$text) Headphone Detect"
    text=`keycode_to_label $AUDIO_HP_LEFT_MENU_ITEM`
    ${DOUT} -n 8 12 "$text) Headphone Left Channel"
    text=`keycode_to_label $AUDIO_HP_RIGHT_MENU_ITEM`
    ${DOUT} -n 8 14 "$text) Headphone Right Channel"
    text=`keycode_to_label $AUDIO_HP_STEREO_MENU_ITEM`
    ${DOUT} -n 8 16 "$text) Headphone Left and Right Channels"
    text=`keycode_to_label $AUDIO_SPEAKER_LEFT_MENU_ITEM`
    ${DOUT} -n 8 18 "$text) Speaker Left Channel"
    text=`keycode_to_label $AUDIO_SPEAKER_RIGHT_MENU_ITEM`
    ${DOUT} -n 8 20 "$text) Speaker Right Channel"
    text=`keycode_to_label $AUDIO_SPEAKER_STEREO_MENU_ITEM`
    ${DOUT} -n 8 22 "$text) Speaker Left and Right Channels"
    text=`keycode_to_label $AUDIO_AUTOMATED_SPEAKER_MENU_ITEM`
    ${DOUT} -n 8 24 "$text) Automated Speaker Test"
    if [ -n "$HAS MICROPHONE" ] && [ "$HAS_MICROPHONE" -ne 0 ]; then
		text=`keycode_to_label $AUDIO_MIC_MENU_ITEM`
		${DOUT} -n 8 26 "$text) Mic Test"
	fi

    # Special debug menu
    if [ -n "$HAS_AUDIO_DEBUG" ] && [ "$HAS_AUDIO_DEBUG" -ne 0 ]; then
        text=`keycode_to_label $AUDIO_DEBUG_MENU_ITEM`
        ${DOUT} -n 8 28 "$text) Audio debug"
    fi
    
    ${DOUT} 8 30 "Press $EXIT_KEY_LABEL to exit audio diagnostics."
}


######################################################################
# Function:     show_hal_init_failure_message
# Purpose:      Show user why the audio hal failed to initialize
# Parameters:   reason - number representing reason for failure 
#               One of:
#                 AUDIO_MIX_TOOL_BROKEN - Mixer tool broken/missing
#                 AUDIO_PLAY_TOOL_BROKEN - Audio Play tool is missing/broken
#                 AUDIO_VOLUME_TOOL_BROKEN - Volume command not supported
#                 AUDIO_BALANCE_TOOL_BROKEN - Balance command not supported
#                 AUDIO_ENTRY_FOR_CODEC_MISSING - Sys entries for codec access missing
#                 AUDIO_SERVER_MISSING - audioServer tool could not be found
# Returns:      none
# Side Effect:  Displays dialog, waits for user to respond before returning
######################################################################
show_hal_init_failure_message()
{
    FAILURE_REASON="$1"
    clear_screen
    ${DOUT} -n 8 4 "Audio Diagnostic Services Failure"
    ${DOUT} -n 6 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 8 "Audio diagnostics failed to load because"
    case "$1" in
        $AUDIO_MIX_TOOL_BROKEN)
            ${DOUT} -n 4 10 "the audio mixer tool is missing/broken."
            ;;
        $AUDIO_PLAY_TOOL_BROKEN)
            ${DOUT} -n 4 10 "the audio play tool is missing/broken."
            ;;
        $AUDIO_VOLUME_TOOL_BROKEN)
            ${DOUT} -n 4 10 "system volume adjustment support is broken."
            ;;
        $AUDIO_BALANCE_TOOL_BROKEN)
            ${DOUT} -n 4 10 "system balance adjustment support is broken."
            ;;
        $AUDIO_ENTRY_FOR_CODEC_MISSING)
            ${DOUT} -n 4 10 "sys entries to access the codec are missing."
            ;;
        $AUDIO_SERVER_MISSING)
            ${DOUT} -n 4 10 "the audioServer tool is missing."
            ;;
        *)
            ${DOUT} -n 4 10 "of an unknown error."
            ;;
    esac
    ${DOUT} 6 30 "Press $EXIT_KEY_LABEL to exit audio diagnostics."
    wait_for_key $EXIT_KEY
}
	

######################################################################
# Function:     do_hp_ack
# Purpose:      Display instructions to insert or remove the headphones 
#				and require the operator to acknowledge before continuing.
# Paramters:    none
# Returns:      none
######################################################################
do_hp_ack()
{
    clear_screen
    print_center_text "$Product Audio Diagnostic" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 10 4
	# Set out direction strings
	if [ "$1" = "in" ]; then
		_cmd_str="Insert headphones into"
		_direction_str="inserted"
	else
		_cmd_str="Remove headphones from"
		_direction_str="removed"
	fi
    ${DOUT} -n 4 8 "${_cmd_str} the heaphone jack now."
    ${DOUT} 4 11 "Press $SUCCESS_KEY_LABEL once headphones have been ${_direction_str}."
	wait_for_key $SUCCESS_KEY
}



######################################################################
# Function:     display_hp_detect_menu
# Purpose:      Display instructions for the headphone jack detection
#               test.
# Paramters:    none
# Returns:      none
######################################################################
display_hp_detect_menu()
{
    _display=$1

    if [ $_display -ne 1 ]; then
	 clear_screen
        ${DOUT} -n 10 4 "Audio Diagnostic Services"
	 ${DOUT} -n 8  5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	 ${DOUT} 4  7 "  Insert the head phone      "
	 #${DOUT} 4  14 "  Press $EXIT_KEY_LABEL to do MIC test"              
    else
        clear_screen
        ${DOUT} -n 10 4 "Audio Headphone Detection Test"
        ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ${DOUT} -n 4 7 "Verifying headphone jack detection."
        ${DOUT} 4 10 "Insert headphones into the heaphone jack now..."
        #${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if this screen did NOT go"
        #${DOUT} 4 15 "away after you inserted the headphones."
    fi
}



######################################################################
# Function:     do_run_hp_in_detect
# Purpose:      Display instructions on the screen for operator to
#               insert headphones.  Watch for headphone insertion and
#               fail if the operator says it didn't happen or we time
#               out.
# Paramters:    display - display a screen telling user to insert headphones
# Returns:      none
# Side Effect:  Headphones are enabled
#               SUB_TEST_PASS is cleared on a failure
######################################################################
do_run_hp_in_detect()
{
    # Remember whether we're to display screen or not
    _display=$1

    # TODO:  remove the DISABLE_HEADPHONE_DETECTION once the head phone detection
    #        is tested 
    if [ -n "$DISABLE_HEADPHONE_DETECTION" ] && [ $DISABLE_HEADPHONE_DETECTION -eq 1 ]; then
	    # Have user insert headphones and acknowledge since we can't do headphone detection
	    do_hp_ack "in"
    else
    	 vmsg "Starting Audio Headphone Detection Test"

        # Start the pcm to initialize the audio driver
        # and install the headset detection interrupt.
        # The sound driver must be open for the headset detect
        # to work, so we play a sound with volume muted while doing detection
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
	        audio_start_sound $CHANNEL_HP_STEREO $MUTE_AUDIO
        fi
        
        display_hp_detect_menu $_display

    	 #
    	 # Wait for headphones to be plugged in
    	 #
    	 audio_wait_hp_detect in
    	 RESULT="$?"
    	 #
    	 # Did we detect headphone insertion?
    	 #
    	 if [ $RESULT -ne $HEADPHONES_DETECTED ]; then
        	failure "Audio Headphone Insertion Detection"
    	 else
        	success "Audio Headphone Insertion Detection"
    	 fi

        # Stop the sound from playing
        audio_stop_sound

    	 enable_headphones
    fi
}


######################################################################
# Function:     audio_display_hp_left_menu
# Purpose:      Display the confirmation screen for the headphone left
#               channel diagnostic test
# Paramters:    none
# Returns:      none
######################################################################
audio_display_hp_left_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out left headphone channel..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of left"
    ${DOUT} -n 4 11 "headphone channel."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "left headphone channel."
}


######################################################################
# Function:     audio_hp_left_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the left headphone channel diagnotic test.
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_hp_left_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_display_hp_left_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in hp left test!!"
            audio_start_sound $CHANNEL_HP_LEFT $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_LEFT $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_LEFT $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Left Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Left Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$LEFT_HP_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_hp_left_diag
# Purpose:      Enable headphone left channel only, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_hp_left_diag()
{
    vmsg "Starting Audio Headphone Left Channel Test"

    # Set audio to headphones, left channel
    audio_start_sound $CHANNEL_HP_LEFT $DEFAULT_LEFT_VOLUME_OUT
            
    # Ask user if everything is working properly
    audio_hp_left_get_process_choice

    # Stop sound from playing
    audio_stop_sound

    vmsg "Exiting Audio Headphone Left Channel Test"
}


######################################################################
# Function:     audio_hp_right_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               this sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_hp_right_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out right headphone channel..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of right"
    ${DOUT} -n 4 11 "headphone channel."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "right headphone channel."
}


######################################################################
# Function:     audio_hp_right_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the right headphone channel diagnotic test.
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_hp_right_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_hp_right_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in hp right!!"
            audio_start_sound $CHANNEL_HP_RIGHT $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_RIGHT $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_RIGHT $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Right Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Right Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$RIGHT_HP_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_hp_right_diag
# Purpose:      Enable headphone right channel only, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_hp_right_diag()
{
    vmsg "Starting Audio Headphone Right Channel Test"

    # Set audio to headphones, right channel
    audio_start_sound $CHANNEL_HP_RIGHT $DEFAULT_RIGHT_VOLUME_OUT

    # Ask user if everything is working properly
    audio_hp_right_get_process_choice

    # Stop sound
    audio_stop_sound

    vmsg "Exiting Audio Headphone Right Channel Test"

}


######################################################################
# Function:     audio_hp_stereo_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               the stereo headphone channels sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_hp_stereo_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out both headphone channels..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of both"
    ${DOUT} -n 4 11 "headphone channels."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "both headphone channels."
}


######################################################################
# Function:     audio_hp_stereo_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the stereo headphone channel diagnotic test.
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_hp_stereo_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_hp_stereo_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in hp stereo!!"
            audio_start_sound $CHANNEL_HP_STEREO $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_STEREO $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_HP_STEREO $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Stereo Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Stereo Headphone Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$STEREO_HP_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_hp_stereo_diag
# Purpose:      Enable both headphone channels, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_hp_stereo_diag()
{
    vmsg "Starting Audio Headphone Stereo Channel Test"

    # Set audio to headphones, both channels
    audio_start_sound $CHANNEL_HP_STEREO $DEFAULT_VOLUME_OUT
    
    # Ask user if everything is working properly
    audio_hp_stereo_get_process_choice

    # Stop sound
    audio_stop_sound

    vmsg "Exiting Audio Headphone Stereo Channel Test"

}

######################################################################
# Function:     audio_hp_out_detect_display_menu
# Purpose:      Display a screen asking operator to remove the headphones.
# Paramters:    none
# Returns:      none
######################################################################
audio_hp_out_detect_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Remove headphones from the headphone"
    ${DOUT} 4 9 "jack now..."
    #${DOUT} 4 12 "Press $SUCCESS_KEY_LABEL once headphones have been removed."
    #${DOUT} 4 12 "Press $SUCCESS_KEY_LABEL once headphones have been removed."
}


######################################################################
# Function:     audio_hp_out_detect_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the stereo headphone removal detection diagnostic
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_hp_out_detect_get_process_choice()
{
	# Put up the splash screen to tell user to unplug headphones
	#
	audio_hp_out_detect_display_menu

	#
	# Wait for headphones to be removed
	#
	audio_wait_hp_detect out
	RESULT="$?"

	#
	# Did we detect headphone insertion?
	#
	if [ $RESULT -ne $HEADPHONES_NOT_DETECTED ]; then
		failure "Audio Headphone Removal Detection"
	else
    	success "Audio Headphone Removal Detection"
	fi
}


######################################################################
# Function:     do_hp_out_detect_diag
# Purpose:      Ask operator to remove headphones, and once operator
#               confirms, disable headphones and enable speakers.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
#               Headphones disabled
#               Speakers enabled
######################################################################
do_hp_out_detect_diag()
{
	vmsg "Starting Audio Headphone Removal Message"
    if [ -n "$DISABLE_HEADPHONE_DETECTION" ] && [ $DISABLE_HEADPHONE_DETECTION -eq 1 ]; then
		# Have user remove headphones and acknowledge since we can't do headphone detection
		do_hp_ack "out"
	else
        # Start the pcm to initialize the audio driver
        # and install the headset detection interrupt.
        # The sound driver must be open for the headset detect
        # to work, so we play a sound with volume muted while doing detection
        audio_start_sound $CHANNEL_HP_STEREO $MUTE_AUDIO
    	audio_hp_out_detect_get_process_choice
    	disable_headphones
    	enable_speakers
        audio_stop_sound
	fi
	vmsg "Exiting Audio Headphone Removal Message"
}


######################################################################
# Function:     audio_speaker_left_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               the left speaker channel sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_speaker_left_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out left speaker channel..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of left"
    ${DOUT} -n 4 11 "speaker channel."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "left speaker channel."
}


######################################################################
# Function:     audio_speaker_left_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the left speaker diagnostic
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_speaker_left_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_speaker_left_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in speaker left!!"
            audio_start_sound $CHANNEL_SPEAKER_LEFT $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_LEFT $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_LEFT $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Left Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Left Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$LEFT_SPEAKER_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_left_speaker_diag
# Purpose:      Enable left speaker channel, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_left_speaker_diag()
{
    vmsg "Starting Audio Speaker Left Channel Test"

    # Set audio to speakers, left channel
    audio_start_sound $CHANNEL_SPEAKER_LEFT $DEFAULT_LEFT_VOLUME_OUT

    # Ask user if everything is working properly
    audio_speaker_left_get_process_choice

    audio_stop_sound

    vmsg "Exiting Audio Speaker Left Channel Test"

}

######################################################################
# Function:     audio_speaker_right_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               the right speaker channel sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_speaker_right_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out right speaker channel..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of right"
    ${DOUT} -n 4 11 "speaker channel."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "right speaker channel."
}


######################################################################
# Function:     audio_speaker_right_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the right speaker diagnostic
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_speaker_right_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_speaker_right_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in speaker right!!"
            audio_start_sound $CHANNEL_SPEAKER_RIGHT $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_RIGHT $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_RIGHT $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Right Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Right Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$RIGHT_SPEAKER_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_right_speaker_diag
# Purpose:      Enable right speaker channel, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_right_speaker_diag()
{
    vmsg "Starting Audio Speaker Right Channel Test"

    # Set audio to speakers, right channel
    audio_start_sound $CHANNEL_SPEAKER_RIGHT $DEFAULT_RIGHT_VOLUME_OUT

    # Ask user if everything is working properly
    audio_speaker_right_get_process_choice

    audio_stop_sound

    vmsg "Exiting Audio Speaker Right Channel Test"

}


######################################################################
# Function:     audio_all_speaker_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               the automated speaker sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_all_speaker_display_menu()
{
    clear_screen
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 12 4 "Audio Diagnostic Services"
    ${DOUT} -n 10 5 "$base"
    ${DOUT} -n 3 7 "The automation sound sample was just played."
    banner="Press $SUCCESS_KEY_LABEL if the test passed."
    center_text "$banner" 10 "$base"
    ${DOUT} -n $? 10 "$banner"
    banner="Press $FAILURE_KEY_LABEL if the test failed."
    center_text "$banner" 10 "$base"
    ${DOUT} $? 12 "$banner"
}


######################################################################
# Function:     audio_all_speaker_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the automated speaker diagnostic
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_all_speaker_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_all_speaker_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_ALL_SPEAKER $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_ALL_SPEAKER $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Automated Speaker Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Automated Speaker Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$ALL_SPEAKER_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     audio_speaker_stereo_display_menu
# Purpose:      Display a screen asking operator to confirm status of
#               the stereo speaker channels sound test.
# Paramters:    none
# Returns:      none
######################################################################
audio_speaker_stereo_display_menu()
{
    clear_screen
    ${DOUT} -n 10 4 "Audio Diagnostic Services"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 7 "Playing sound out both speaker channels..."
    ${DOUT} -n 4 10 "Press $SUCCESS_KEY_LABEL if sound is coming out of left and"
    ${DOUT} -n 4 11 "right speaker channels."
    ${DOUT} -n 4 14 "Press $FAILURE_KEY_LABEL if sound is NOT coming from"
    ${DOUT} 4 15 "left and right speaker channels."
}


######################################################################
# Function:     audio_speaker_stereo_get_process_choice
# Purpose:      Get the operator response as to success or failure of
#               the stereo speaker channels diagnostic
# Paramters:    none
# Returns:      none
# Side Effects: SUB_TEST_PASSED is cleared on a failure
######################################################################
audio_speaker_stereo_get_process_choice()
{
    # Put up the splash screen if we're manually starting up the framework.
    #
    audio_speaker_stereo_display_menu

	# Get the current volume setting
	#
	THE_CURRENT_VOLUME=`get_volume_out`

    #
    # Loop until a valid response is seen
    #
    DONE=0
    while [ $DONE -ne 1 ]; do
        process_running "pcm" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo "PCM tool is not running in speaker stereo!!"
            audio_start_sound $CHANNEL_SPEAKER_STEREO $THE_CURRENT_VOLUME
        fi

        #
        # Get the key request
        #
        KEY=`$GET_KBD_VOLUME_BUTTON_INPUT`

        #
        # Process key request
        case "$KEY" in

		$VOLUME_UP)
			if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -gt $MAX_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MAX_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_STEREO $THE_CURRENT_VOLUME
            fi
            ;;

        $VOLUME_DOWN)
        	if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                if [ $THE_CURRENT_VOLUME -lt $MIN_VOLUME ]; then
                    let THE_CURRENT_VOLUME=$MIN_VOLUME;
                fi 
                audio_set_parms $CHANNEL_SPEAKER_STEREO $THE_CURRENT_VOLUME
            fi
            ;;

        $SUCCESS_KEY)
            success "Audio Stereo Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            DONE=1
            ;;

        $FAILURE_KEY)
            failure "Audio Stereo Speaker Channel Test"
            vmsg "Returning to main audio diagnostic test..."
            dump_codec_regs_to_file "$STEREO_SPEAKER_CODEC_LOGFILE"
            DONE=1
            ;;

        *)
            ;;

        esac
    done
}


######################################################################
# Function:     do_stereo_speaker_diag
# Purpose:      Enable both speaker channels, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  Stop sound once operator has responded.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_stereo_speaker_diag()
{
    vmsg "Starting Audio Stereo Speaker Channel Test"

    # Set audio to speakers, both channels
    audio_start_sound $CHANNEL_SPEAKER_STEREO $DEFAULT_VOLUME_OUT

    # Ask user if everything is working properly
    audio_speaker_stereo_get_process_choice

    audio_stop_sound

    vmsg "Exiting Audio Stereo Speaker Channel Test"
}


######################################################################
# Function:     do_automated_speaker_diag
# Purpose:      Enable both speaker channels, start a sound playing,
#               then display a screen asking operator to confirm test
#               results.  This test is used for the automated audio
#               tester used in the factory.  It actually plays a sample
#               out the left channel first, then the right channel, then
#               in stereo (speaker ONLY).
# Parameters:   none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
do_automated_speaker_diag()
{
    vmsg "Starting Automated Audio Speaker Test"

    do_speaker_test
    
    # Set audio to automated speakers
    audio_start_sound $CHANNEL_ALL_SPEAKER $DEFAULT_AUTOMATED_VOLUME_OUT

    # Wait for sound file to finish playing before redrawing parent menu
    # This fixes race condition of starting new automated sound playing 
    # before old one finished.
    PLAYING=1
    while [ $PLAYING -eq 1 ]; do
        process_running "$AUTOMATED_PLAY_TOOL_NAME"> /dev/null 2>&1
        PLAYING=$?
        if [ $PLAYING -eq 1 ]; then
            sleep 1
        fi
    done

    vmsg "Exiting Automated Audio Speaker Test"
}


do_audio_debug()
{
    DONE=0
    THE_CURRENT_VOLUME=$DEFAULT_VOLUME_OUT 
    ACTIVE_CHANNEL=$CHANNEL_SPEAKER_STEREO 
    SPEAKER_ENABLED=1
    DONT_REDRAW=0
    clear_screen
    while [ $DONE -ne 1 ]; do
        if [ $DONT_REDRAW -ne 1 ]; then
            ${DOUT} -n 10 4 "Audio Debug Services"
            ${DOUT} -n 8  5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            text=`keycode_to_label $MENU_ITEM_1`
            ${DOUT} -n 8  7 "$text) Start stereo sound playing"
            text=`keycode_to_label $MENU_ITEM_2`
            ${DOUT} -n 8  9 "$text) Balance Left"
            text=`keycode_to_label $MENU_ITEM_3`
            ${DOUT} -n 8  11 "$text) Balance Right"
            text=`keycode_to_label $MENU_ITEM_4`
            ${DOUT} -n 8  13 "$text) Balance Stereo"
            text=`keycode_to_label $MENU_ITEM_5`
            ${DOUT} -n 8  15 "$text) Speaker Disable"
            text=`keycode_to_label $MENU_ITEM_6`
            ${DOUT} -n 8  17 "$text) Speaker Enable"
            text=`keycode_to_label $MENU_ITEM_7`
            ${DOUT} -n 8  19 "$text) HP Disable"
            text=`keycode_to_label $MENU_ITEM_8`
            ${DOUT} -n 8  21 "$text) HP Enable"
            text=`keycode_to_label $MENU_ITEM_9`
            ${DOUT} -n 8  23 "$text) Volume Up"
            text=`keycode_to_label $MENU_ITEM_10`
            ${DOUT} -n 8  25 "$text) Volume Down"
            text=`keycode_to_label $MENU_ITEM_11`
            ${DOUT} -n 8  27 "$text) Stop sound playing"
            text=`keycode_to_label $MENU_ITEM_12`
            ${DOUT} -n 8  29 "$text) Check pcm"
            text=`keycode_to_label $MENU_ITEM_13`
            ${DOUT} -n 8  31 "$text) Dump codec registers"
            text=`keycode_to_label $MENU_ITEM_14`
            ${DOUT} -n 8  33 "$text) Dump codec registers to logfile"
            ${DOUT} -n 8  35 "VOLUME : $THE_CURRENT_VOLUME   "
            ${DOUT}    8  38 "Press $EXIT_KEY_LABEL to exit test"
        else
            DONT_REDRAW=0
        fi

        KEY=`$GET_KEYBOARD_INPUT`
        case "$KEY" in
            $MENU_ITEM_1)
                audio_start_sound $CHANNEL_SPEAKER_STEREO $THE_CURRENT_VOLUME
                ;;
            $MENU_ITEM_2)
                if [ $SPEAKER_ENABLED -eq 1 ]; then
                    audio_set_parms $CHANNEL_SPEAKER_LEFT $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_SPEAKER_LEFT
                else
                    audio_set_parms $CHANNEL_HP_LEFT $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_HP_LEFT
                fi
                ;;
            $MENU_ITEM_3)
                if [ $SPEAKER_ENABLED -eq 1 ]; then
                    audio_set_parms $CHANNEL_SPEAKER_RIGHT $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_SPEAKER_RIGHT
                else
                    audio_set_parms $CHANNEL_HP_RIGHT $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_HP_RIGHT
                fi
                ;;
            $MENU_ITEM_4)
                if [ $SPEAKER_ENABLED -eq 1 ]; then
                    audio_set_parms $CHANNEL_SPEAKER_STEREO $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_SPEAKER_STEREO
                else
                    audio_set_parms $CHANNEL_HP_STEREO $THE_CURRENT_VOLUME
                    export ACTIVE_CHANNEL=$CHANNEL_HP_STEREO
                fi
                ;;
            $MENU_ITEM_5)
                disable_speakers
                SPEAKER_ENABLED=0
                ;;

            $MENU_ITEM_6)
                enable_speakers
                SPEAKER_ENABLED=1
                ;;
            $MENU_ITEM_7)
                disable_headphones
                ;;
            $MENU_ITEM_8)
                enable_headphones
                ;;

            $MENU_ITEM_9)
			    if [ $THE_CURRENT_VOLUME -lt $MAX_VOLUME ]; then
            	    let THE_CURRENT_VOLUME+=$VOLUME_PER_STEP
                    if [ $THE_CURRENT_VOLUME -gt 100 ]; then
                        THE_CURRENT_VOLUME=100 
                    fi
                    audio_set_parms $ACTIVE_CHANNEL $THE_CURRENT_VOLUME
                fi
                ;;

            $MENU_ITEM_10)
        	    if [ $THE_CURRENT_VOLUME -gt $MIN_VOLUME ]; then
            	    let THE_CURRENT_VOLUME-=$VOLUME_PER_STEP
                    if [ $THE_CURRENT_VOLUME -lt 0 ]; then
                        THE_CURRENT_VOLUME=0 
                    fi
                    audio_set_parms $ACTIVE_CHANNEL $THE_CURRENT_VOLUME
                fi
                ;;

            $MENU_ITEM_11)
                audio_stop_sound
                ;;

            $MENU_ITEM_12)
                # Check to see if pcm is still running
                process_running "pcm"
                if [ $? -eq 0 ]; then
                    echo "PCM is NOT running !"
                else
                    echo "PCM is running !"
                fi
                ;;

            $MENU_ITEM_13)
                do_read_codec_regs
                ;;

            $MENU_ITEM_14)
                dump_codec_regs_to_file "$REG_DUMP_CODEC_LOGFILE"
                ;;

            $EXIT_KEY)
                audio_stop_sound
                DONE=1;
                ;;
            *)
                DONT_REDRAW=1
                ;;
        esac
    done
}


######################################################################
# Function:     audio_run_suite
# Purpose:      Walk through each audio diagnostic sub-test.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
audio_run_suite()
{
    # Headphone Detect Test...
    do_run_hp_in_detect 1

    # Headphone Left Channel Test...
    do_hp_left_diag

    # Headphone Right Channel Test...
    do_hp_right_diag

    # Audio Headphone Left & Right Channel Test...
    do_hp_stereo_diag

    # Headphone Detect Test...
    do_hp_out_detect_diag

    # Audio Speaker Left Channel Test...
    do_left_speaker_diag

    # Audio Speaker Right Channel Test...
    do_right_speaker_diag

    # Audio Speaker Left & Right Channel Test...
    do_stereo_speaker_diag
    
    if [ -n "$HAS MICROPHONE" ] && [ $HAS_MICROPHONE -ne 0 ]; then
        # Check for headset
        do_run_hp_in_detect 0

        # Mic test
        AUDIO_STATE=$AUDIO_STATE_BYPASS
        do_mic_test
        AUDIO_STATE=$AUDIO_STATE_OFF
    fi
}


######################################################################
# Function:     audio_do_run_diag()
# Purpose:      Display the main audio diagnostic menu, field operator
#               requests and run any sub-test requests.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASS is cleared on a failure
######################################################################
audio_do_run_diag()
{
  DO_RETURN=0
  DONT_REDRAW_MENU=0 

  if [ -n "$HAS_USB_SERIAL_SUPPORT" ] && [ "$HAS_USB_SERIAL_SUPPORT" -eq 1 ]; then
      switch_io_to_serial_over_usb 1
  fi

  while [ $DO_RETURN -ne 1 ]; do

    # Put up the splash screen if we're manually starting up the framework.
    #
    if [ $DONT_REDRAW_MENU -eq 0 ]; then
        audio_diag_display_menu
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

    $AUDIO_SUITE_MENU_ITEM)
        vmsg "Running Complete Audio Test Suite..."
        audio_run_suite
        ;;

    $AUDIO_HP_DETECT_MENU_ITEM)
        # Headphone Detect Test...
        do_run_hp_in_detect 1
        RETVAL=$?
        ;;

    $AUDIO_HP_LEFT_MENU_ITEM)
        # Headphone Left Channel Test...
        do_hp_left_diag
        RETVAL=$?
        ;;

    $AUDIO_HP_RIGHT_MENU_ITEM)
        # Headphone Right Channel Test...
        do_hp_right_diag
        RETVAL=$?
        ;;

    $AUDIO_HP_STEREO_MENU_ITEM)
        # Audio Headphone Left & Right Channel Test...
        do_hp_stereo_diag
        RETVAL=$?
        ;;

    $AUDIO_SPEAKER_LEFT_MENU_ITEM)
        # Audio Speaker Left Channel Test...
        do_left_speaker_diag
        RETVAL=$?
        ;;

    $AUDIO_SPEAKER_RIGHT_MENU_ITEM)
        # Audio Speaker Right Channel Test...
        do_right_speaker_diag
        RETVAL=$?
        ;;

    $AUDIO_SPEAKER_STEREO_MENU_ITEM)
        # Audio Speaker Left & Right Channel Test...
        do_stereo_speaker_diag
        RETVAL=$?
        ;;

    $AUDIO_AUTOMATED_SPEAKER_MENU_ITEM)
        # Automated Audio Speaker Left, Right, and Stereo Channel Test...
        AUDIO_STATE=$AUDIO_STATE_AUTOMATED_SPEAKER
        do_automated_speaker_diag
        RETVAL=$?
        AUDIO_STATE=$AUDIO_STATE_OFF
        ;;

    $AUDIO_MIC_MENU_ITEM)
        # Check for headset
        do_run_hp_in_detect 0

        # Mic test
        AUDIO_STATE=$AUDIO_STATE_BYPASS
        do_mic_test
        RETVAL=$?
        AUDIO_STATE=$AUDIO_STATE_OFF
        ;;

    $AUDIO_MIC_CAPTURE_MENU_ITEM)
	 # Call capture code
	 ;;

    $AUDIO_DEBUG_MENU_ITEM)
        do_audio_debug
        ;;

    $EXIT_KEY)
        vmsg "Exiting Audio Diagnostic Test..."
        if [ -n "$HAS_USB_SERIAL_SUPPORT" ] && [ "$HAS_USB_SERIAL_SUPPORT" -eq 1 ]; then
            switch_io_to_debug_port
        fi
	    DO_RETURN=1
        ;;

    *)
        DONT_REDRAW_MENU=1
        ;;

    esac
done

}


######################################################################
# Function:     audio_start_cycle_test()
# Purpose:      Start a sound playing.
# Paramters:    none
# Returns:      none
# Side Effect:  A sound clip starts playing.
######################################################################
audio_start_cycle_test()
{
    audio_start_sound $CHANNEL_ALL $RUN_IN_SPEAKER_AUDIO_VOLUME
}


######################################################################
# Function:     audio_stop_cycle_test()
# Purpose:      Stop the sound from playing, then disable headphones
#               and speakers.
# Paramters:    none
# Returns:      none
# Side Effect:  The sound clip stops playing.
######################################################################
audio_stop_cycle_test()
{
    audio_stop_sound
    disable_headphones
    disable_speakers
}

case "$1" in

    stop)
        vmsg "Exiting Audio Diagnostic Tests"
        ;;

    cycle_stop)
        vmsg "Exiting Audio Cycle Diagnostic Tests"
        audio_stop_cycle_test
        audio_hal_exit
        did_diag_fail
        diag_test_failed="$?"
        return $diag_test_failed
        ;;

    cycle)
        vmsg "Starting Audio Cycle Diagnostic Test"
        audio_hal_init
        audio_start_cycle_test
        did_diag_fail
        return "$?"
        ;;

    suite)
        vmsg "Running Audio Diagnostic Full Test Suite"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "Audio"
        audio_hal_init
        RETVAL=$?
        if [ "$RETVAL" -eq 0 ]; then
            audio_run_suite
        else
            show_hal_init_failure_message "$RETVAL"
        fi
        audio_hal_exit
        exit_diag "Audio" $_status_screen_option
        did_diag_fail
        diag_test_failed="$?"
        return $diag_test_failed
        ;;

    start|*)
        vmsg "Displaying Audio Diagnostic Services Menu"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "Audio"
        # Clear any previous diagnostic test results
        clear_diag_fail
        audio_hal_init
        RETVAL=$?
        if [ "$RETVAL" -eq 0 ]; then
            audio_do_run_diag
        else
            show_hal_init_failure_message "$RETVAL"
        fi
        audio_hal_exit
        exit_diag "Audio" $_status_screen_option
        did_diag_fail
        diag_test_failed="$?"
        return $diag_test_failed
        ;;
esac


