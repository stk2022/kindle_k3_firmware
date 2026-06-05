#!/bin/sh
######################################################################
#
#   File:  video_diags.sh
#
#   Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#   Date:   07/18/08
#
#   Copyright 2008, Lab126, Inc.  All rights reserved.
#
#   Description:
#      Video diagnostic script for testing video.
#
#   Constants
#       DEFAULT_DELAY               - Default time to leave images up
#       VIDEO_DISPLAY_TIME_AUTO_MODE    - Display time during cycle mode tests
#       VIDEO_DISPLAY_TIME_MANUAL_MODE  - Display time during manual mode tests
#
#   Routines
#       verify_page_flip_test_worked()  - Run the test in no-operator mode
#       explain_shades_test()           - Explain how shades test works to user
#       verify_video_pattern_test_worked- Have operator verify pattern tests worked
#       do_video_pattern_test()         - Run complete pattern test
#       do_video_page_flip_test()       - Run page flip test
#       video_grayscale_test()          - Run the video grayscale test
#       video_pattern_test()            - 16 rectangle pattern test
#       video_text_readability_test()   - Run large or small text readability test
#       run_text_readability_test()     - Run large AND small text readablity test
#       video_ghosting_test()           - Run checkerboard image ghosting test
#       run_all_ghosting_tests()        - Run grayscale, pattern, readability, and
#                                           ghosting tests
#       video_do_cycle_diag()           - Run cycle-mode video test (no operator)
#       do_video_diag()                 - Run main video diagnostic suite
#
######################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# Video HAL Functions
[ -f ${_VIDEO_HAL_FUNCTIONS} ] && . ${_VIDEO_HAL_FUNCTIONS}

DEFAULT_DELAY=3

#
# Time in seconds to leave video image on display during auto (cycle) mode
#
VIDEO_DISPLAY_TIME_AUTO_MODE=1

#
# Time in seconds to leave video image on display
#
VIDEO_DISPLAY_TIME_MANUAL_MODE=7


######################################################################
# Function:     verify_page_flip_test_worked 
# Purpose:      Display screen asking operator to verify whether images
#               were displayed properly in page-flip test.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
verify_page_flip_test_worked()
{
    # User pressed the target key, verify visual via asking operator
    clear_screen
    ${DOUT} -n 14 4 " Video Page Flip Test"
    ${DOUT} -n 12 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 2 8 "Press $SUCCESS_KEY_LABEL if the images displayed properly."
    ${DOUT} 2 10 "Press $FAILURE_KEY_LABEL if the images DID NOT display properly."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    success "Page Flip Test"
                    IDONE=1;
                    ;;

                $FAILURE_KEY)
                    failure "Page Flip Test"
                    IDONE=1;
                    ;;

                *)
                    ;;
            esac
        fi
    done
}


######################################################################
# Function:     explain_shades_test
# Purpose:      Display a screen explaining how the shades video test
#               works.
# Paramters:    none
# Returns:      0 - Operator wants to start test
#               2 - Operator cancelled the test
######################################################################
explain_shades_test()
{
    EXIT_CODE=0
    clear_screen
    ${DOUT} -n 12 3 "Shades Of Gray Pattern Test"
    ${DOUT} -n 10 4 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 4 6 "This test will display a solid pattern on"
    ${DOUT} -n 4 7 "the display for 3 seconds.  Examine the"
    ${DOUT} -n 4 8 "display while the test pattern is on the"
    ${DOUT} -n 4 9 "screen, looking for problem areas on the"
    ${DOUT} -n 4 10 "screen.  After three seconds of image"
    ${DOUT} -n 4 11 "display, a verification dialog will appear"
    ${DOUT} -n 4 12 "for you to indicate whether any problems"
    ${DOUT} -n 4 13 "were seen.  Responding to this dialog will"
    ${DOUT} -n 4 14 "clear the screen and display the next test"
    ${DOUT} -n 4 15 "image to be examined."

    ${DOUT} -n 4 18 "Press $SUCCESS_KEY_LABEL to start this test and display"
    ${DOUT} -n 4 19 "the first test pattern."
    ${DOUT} 8 24 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    EXIT_CODE=2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return $EXIT_CODE    
}


######################################################################
# Function:     verify_video_pattern_test_worked
# Purpose:      Display screen asking operator to verify test results.
# Paramters:    Pattern name (string)
# Returns:      0 - Operator wants to start test
#               2 - Operator cancelled the test
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
verify_video_pattern_test_worked ()
{
    EXIT_CODE=0

    # User pressed the target key, verify visual via asking operator
    PATTERN="$1"
    clear_screen
    ${DOUT} -n 12 4 "Shades Of Gray Pattern Test"
    ${DOUT} -n 10 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 2 8 "Press $SUCCESS_KEY_LABEL if $PATTERN displayed properly."
    ${DOUT} -n 2 10 "Press $FAILURE_KEY_LABEL if $PATTERN DID NOT display properly."
    ${DOUT} 8 14 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."

    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    success "$PATTERN Pattern Test"
                    IDONE=1;
                    ;;

                $FAILURE_KEY)
                    failure "$PATTERN Pattern Test"
                    IDONE=1;
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    EXIT_CODE=2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return $EXIT_CODE    
}


######################################################################
# Function:     do_video_pattern_test
# Purpose:      Run the complete video pattern test.  This routine walks
#               through the device's IMAGE_PATTERN_LIST, testing each 
#               pattern in the list.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
do_video_pattern_test()
{
    explain_shades_test
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        return $RETVAL
    fi
    for PATTERN_ID in ${IMAGE_PATTERN_LIST}; do
        video_draw_pattern "$PATTERN_ID"
        NAME=`image_pattern_to_label $PATTERN_ID`
        sleep $VIDEO_DISPLAY_TIME_MANUAL_MODE
        verify_video_pattern_test_worked "$NAME"
        RETVAL=$?
        if [ $RETVAL -eq 1 ]; then
            return $RETVAL
        fi
    done
    return 0
}


######################################################################
# Function:     do_video_page_flip_test
# Purpose:      Run the complete video page flip test.  This routine
#               flips pages until user stops tests, then asks operator
#               to verify results before returning.
# Paramters:    none
# Returns:      none
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
do_video_page_flip_test()
{
    # during manual diagnostic mode Page flip until user cancels....
    page_flip $DEFAULT_DELAY "Video Page Flip Test"

    # Verify page flip worked properly
    verify_page_flip_test_worked 
}


######################################################################
# Function:     video_grayscale_test
# Purpose:      Run the grayscale video diagnostic.  This test will
#               display all the shades of gray supported and ask operator
#               to verify they're correct.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
video_grayscale_test()
{
    # Display test instructions, wait for operator to ack
    clear_display_full_gc16
    
    ${DOUT} -n 14 4 " Video Grayscale Test"
    ${DOUT} -n 12 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 6 7 "Please look at the screen after the test"
    ${DOUT} -n 6 9 "image is displayed."
    ${DOUT} -n 6 13 "Note how many shades of gray you see."
    ${DOUT} -n 6 17 "There should be 16 distinct colors."
    ${DOUT} 6 21 "Press $EXIT_KEY_LABEL to start the test."
    wait_for_key $EXIT_KEY

    #-------------------------------------
    clear_display_full_gc16
    restore_display_full_gc16

    # Display the first pattern
    ${EIPS} -n -g 0 0 "${VIDEO_IMAGES_ROOT}/grayscale_16.png"
    update_display_full_gc16
    # Delay for a bit while pattern is on the screen
    # sleep 3
    sleep $VIDEO_DISPLAY_TIME_MANUAL_MODE

    # Display the temperature?
    eink_temp=`cat /proc/eink_fb/temperature`

    # Display test instructions, wait for operator to ack
    clear_display_full_gc16
    ${DOUT} -n 14 4 " Video Grayscale Test"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "EINK Temperature : ${eink_temp} Celsius"
    ${DOUT} -n 8 11 "Did you see all 16 colors (none of"
    ${DOUT} -n 8 13 "the colors blended together)?"
    ${DOUT} -n 2 17 "Press $SUCCESS_KEY_LABEL if you saw all 16 colors, no blending."
    ${DOUT} -n 2 19 "Press $FAILURE_KEY_LABEL if the colors blended together."
    ${DOUT} 2 21 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    success "Grayscale"
                    ;;

                $FAILURE_KEY)
                    failure "Grayscale"
                    return 1
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    return 2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return 0
}


######################################################################
# Function:     video_pattern_test
# Purpose:      Run the pattern video diagnostic.  This test will
#               display 15 rectangles with bars in them, asking operator
#               to verify they're correct.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
video_pattern_test()
{
    # Display test instructions, wait for operator to ack
    clear_display_full_gc16
    
    ${DOUT} -n 17 4 "Video Pattern Test"
    ${DOUT} -n 10 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 3 7 "Please look at the screen after the test"
    ${DOUT} -n 3 9 "image is displayed."
    ${DOUT} -n 3 13 "Sixteen rectangles will appear on the screen."
    ${DOUT} -n 3 15 "Each rectangle has a number of bars inside it."
    ${DOUT} -n 3 17 "Note if you cannot see any bars in any one of"
    ${DOUT} -n 3 19 "the sixteen rectangles."
    ${DOUT} -n 3 23 "There should be 16 distinct colors."
    ${DOUT} 3 27 "Press $EXIT_KEY_LABEL to start the test."
    wait_for_key $EXIT_KEY

    #-------------------------------------
    clear_display_full_gc16
    restore_display_full_gc16

    # Display the second pattern
    ${EIPS} -n -g 0 0 "${VIDEO_IMAGES_ROOT}/test_pattern.png"
    update_display_full_gc16
    # Delay for a bit while pattern is on the screen
    # sleep 3
    sleep $VIDEO_DISPLAY_TIME_MANUAL_MODE

    # Display the temperature?
    eink_temp=`cat /proc/eink_fb/temperature`

    # Display test instructions, wait for operator to ack
    clear_display_full_gc16
    ${DOUT} -n 17 4 "Video Pattern Test"
    ${DOUT} -n 10 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 12 7 "EINK Temperature : ${eink_temp} Celsius"
    ${DOUT} -n 2 11 "Press $SUCCESS_KEY_LABEL if you saw bars in all 16 rectangles."
    ${DOUT} -n 2 13 "Press $FAILURE_KEY_LABEL if you didnt see bars in all rectangles."
    ${DOUT} 2 15 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    success "Pattern Test"
                    ;;

                $FAILURE_KEY)
                    failure "Pattern Test"
                    return 1
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    return 2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return 0
}


######################################################################
# Function:     video_text_readability_test
# Purpose:      Given a text size (large or small), displays a screen
#               containing test of said size, and then asks operator
#               to confirm they could read the content.
# Paramters:    1 - Run small text size test
#               2 - Run large text size test
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
video_text_readability_test()
{
    text_size="$1"
    case "$text_size" in
        1)
            test_image="${VIDEO_IMAGES_ROOT}/text_small.png"
            text_size="small"
            text_size_cap="Small"
            ;;
        2|*)
            test_image="${VIDEO_IMAGES_ROOT}/text_large.png"
            text_size="large"
            text_size_cap="Large"
            ;;
    esac

    # Display test instructions, wait for operator to ack
    clear_screen
    ${DOUT} -n 12 4 "Video Text Readability Test"
    ${DOUT} -n 10 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 6 7 "Please look at the screen after the test"
    ${DOUT} -n 6 9 "image is displayed."
    ${DOUT} -n 6 13 "A page of text will appear."
    ${DOUT} -n 6 15 "See if you can read the $text_size text."
    ${DOUT} 6 19 "Press $EXIT_KEY_LABEL to start the test."
    wait_for_key $EXIT_KEY

    #-------------------------------------
    clear_screen

    # Display the test image
    ${EIPS} -g 0 0 "${test_image}"

    # Delay for a bit while pattern is on the screen
    sleep $VIDEO_DISPLAY_TIME_MANUAL_MODE

    # Display the temperature?
    eink_temp=`cat /proc/eink_fb/temperature`

    # Display test instructions, wait for operator to ack
    clear_screen
    ${DOUT} -n 12 4 "Video Text Readability Test"
    ${DOUT} -n 10 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 11 7 "EINK Temperature : ${eink_temp} Celsius"
    ${DOUT} -n 2 11 "Press $SUCCESS_KEY_LABEL if you could read the $text_size text."
    ${DOUT} -n 2 13 "Press $FAILURE_KEY_LABEL if you could not read the $text_size text."
    ${DOUT} 2 15 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    success "$text_size_cap Text Readability"
                    ;;

                $FAILURE_KEY)
                    failure "$text_size_cap Text Readability"
                    return 1
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    return 2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return 0
}


######################################################################
# Function:     run_text_readability_test
# Purpose:      Execute the small and large text readability tests.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
run_text_readability_test()
{
    # Run small text test
    video_text_readability_test 1
    result="$?"
    if [ "$result" -eq 0 ]; then
        video_text_readability_test 2
        result="$?"
    fi
    return $result
}


######################################################################
# Function:     video_ghosting_test
# Purpose:      Run the video ghosting test.  This test will display
#               a checkerboard image for 5 seconds, clear the screen,
#               and ask the operator to verify there's no ghosting.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
video_ghosting_test()
{
    # Display test instructions, wait for operator to ack
    clear_display_full_gc4
    
    ${DOUT} -n 14 4 "Video Ghosting Test"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 6 7 "Please look at the screen after the test"
    ${DOUT} -n 6 9 "image is displayed."
    ${DOUT} -n 6 13 "A checkered image will appear for"
    ${DOUT} -n 6 15 "5 seconds and then disappear."
    ${DOUT} -n 6 19 "Note if you see a ghost after the image"
    ${DOUT} -n 6 21 "is removed."
    ${DOUT} 6 25 "Press $EXIT_KEY_LABEL to start the test."
    wait_for_key $EXIT_KEY

    #-------------------------------------
    clear_display_full_gc4
    restore_display_full_gc16

    # Display the test image
    ${EIPS} -n -g 0 0 "${VIDEO_IMAGES_ROOT}/checkered.png"
    update_display_full_gc4
    # Delay for a bit while pattern is on the screen
    sleep 5
 
    # echo "first time flashing"
    ${EIPS} -n -g 0 0 "${VIDEO_IMAGES_ROOT}/gray_1111.png"
    update_display_full_gc4
    sleep 3

    #restore_display_full_gc4
    ${EIPS} 0 0 .

    # echo "second time flashing"
    ${EIPS} -n -g 0 0 "${VIDEO_IMAGES_ROOT}/gray_1111.png"
    update_display_full_gc4 
    sleep $VIDEO_DISPLAY_TIME_MANUAL_MODE

    # Display the temperature?
    eink_temp=`cat /proc/eink_fb/temperature`

    # Display test instructions, wait for operator to ack
    ${DOUT} -n 14 4 "Video Ghosting Test"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 8 7 "EINK Temperature : ${eink_temp} Celsius"
    ${DOUT} -n 6 11 "Press $SUCCESS_KEY_LABEL if you did not see ghosting."
    ${DOUT} -n 6 13 "Press $FAILURE_KEY_LABEL if you saw ghosting."
    ${DOUT} 6 15 "Press $EXIT_KEY_LABEL to exit Video Diagnostics."
    IDONE=0
    while [ $IDONE -eq 0 ]; do
        KEY=`$GET_KEYBOARD_INPUT`
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            case "$KEY" in
                $SUCCESS_KEY)
                    IDONE=1;
                    success "Ghosting"
                    ;;

                $FAILURE_KEY)
                    failure "Ghosting"
                    return 1
                    ;;

                $EXIT_KEY)
                    IDONE=1;
                    return 2
                    ;;

                *)
                    ;;
            esac
        fi
    done
    return 0
}


######################################################################
# Function:     run_all_ghosting_tests
# Purpose:      Run all video test, including grayscale, pattern, 
#               readability, and ghosting.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
run_all_ghosting_tests()
{
    # Run Video Grayscale Test
    video_grayscale_test
    result="$?"
    if [ $result -ne 0 ]; then
        return $result 
    fi

    # Run Video Pattern Test
    video_pattern_test
    result="$?"
    if [ $result -ne 0 ]; then
        return $result 
    fi

    # Run Text Readability Test removed per factory request, approved by Amish

    # Run Ghosting Test
    video_ghosting_test
    result="$?"
    return $result
}


######################################################################
# Function:     video_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      none
######################################################################
video_do_cycle_diag()
{
    vmsg "Starting Video Diagnostic $1 Cycle Test"

    # Get cycle count
    VIDEO_CYCLE_COUNT=$1

    # Loop through auto-run test
    while [ $VIDEO_CYCLE_COUNT -ne 0 ]; do

        # Display each pattern
        for PATTERN_ID in ${IMAGE_PATTERN_LIST}; do
            video_draw_pattern "$PATTERN_ID"
            sleep $VIDEO_DISPLAY_TIME_AUTO_MODE
        done
        
        # Decrement loop counter
        VIDEO_CYCLE_COUNT=`expr $VIDEO_CYCLE_COUNT - 1`
    done
}


######################################################################
# Function:     do_video_diag
# Purpose:      Execute the main video diagnostic test suite.
# Paramters:    none
# Returns:      0 - Tests passed
#               1 - Tests failed
#               2 - Operator cancelled
# Side Effect:  SUB_TEST_PASSED is cleared on any failures
######################################################################
do_video_diag()
{
    clear_display_full_gc16

    # Check / Verify any video parameters
    video_verify_parameters
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        return $RETVAL
    fi

    # Verify no ghosting exists
    run_all_ghosting_tests
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        return $RETVAL
    fi

    return 0
}

case "$1" in

    stop)
        vmsg "Exiting Video Diagnostics Test"
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count=$2
        else
            cycle_count=1
        fi
        vmsg "Starting Video Diagnostic $cycle_count Cycle Test"
        video_hal_init
        video_do_cycle_diag $cycle_count
        video_hal_exit
        did_diag_fail
        return "$?"
        ;;

    start|*)
        vmsg "Starting Video Diagnostics Test"
        if [ $# -ge 2 ]; then
            # Caller determines whether to show pass/fail status
            _status_screen_option="$2"
        else
            # Default to showing pass/fail status
            _status_screen_option=1
        fi
        enter_diag "Video"
        # Clear any previous diagnostic test results
        clear_diag_fail
        do_video_diag
        _video_diag_result="$?"
        if [ "$_video_diag_result" -eq 2 ]; then
            exit_diag "Video" 0
        else
            exit_diag "Video" $_status_screen_option
        fi
        ;;

esac
