#!/bin/sh
####################################################################################
#
#  File:   moviNand_diag.sh
#
#  Author: Nick Vaccaro <nvaccaro@lab126.com>
#
#  Date:   09/16/08
#
#  Copyright 2008, Lab126, Inc.  All rights reserved.
#
#  Description:
#      Contains the moviNand diagnostic.
#
#   Routines
#       movi_set_failed_file()          - Remember name of failed file and reason
#       movi_get_failure_file()         - Get name of file that failed
#       movi_get_failure_reason()       - Get reason for failure
#       movi_display_results()          - Display test pass/fail status
#       movi_display_list_fnf()         - Display md5 list not found screen       
#       movi_display_rootfs_verify()    - Display main "Verifying movi.." screen
#       movi_md5_file_non_exempt()      - Determine if given file is exempt from failure
#       movi_do_md5sum_fs()             - md5sum all moviNand rootfs or diags folder contents
#       movi_do_cycle_diag()            - Run test a given number of times in cycle mode
#       do_verify_movinand()            - Displays dialog and runs verification test
#       movi_run_diag()                 - Run main moviNand diagnostic
#
####################################################################################

# Include some Useful Diagnostic Functions
[ -f ${_DIAG_FUNCTIONS} ] && . ${_DIAG_FUNCTIONS}

# moviNand HAL Functions
[ -f ${_MOVINAND_HAL_FUNCTIONS} ] && . ${_MOVINAND_HAL_FUNCTIONS}

# Include filepath info
[ -f "/etc/sysconfig/paths" ] && . "/etc/sysconfig/paths"


#
# Error constants for file failures
#
MOVI_MD5_CHECKSUM_ERR=0
MOVI_FILE_NOT_FOUND_ERR=1


#
#   Variables to hold failure filename and reason file failed the test
#
MOVINAND_FAILURE_REASON=
MOVINAND_FAILED_FILE="UNKNOWN"



######################################################################
# Function:     movi_set_failed_file
# Purpose:      Remembers the file that failed the test and the
#               reason it failed.
# Paramters:    MOVINAND_FAILED_FILE - full path filename of failure file
#               MOVINAND_FAILURE_REASON - reason for failure.  One of:
#                   MOVI_MD5_CHECKSUM_ERR - File's md5sum was wrong
#                   MOVI_FILE_NOT_FOUND_ERR - File couldn't be found
# Returns:      none
# Side Effect:  Sets the MOVINAND_FAILED_FILE and MOVINAND_FAILURE_REASON
#               globals.
######################################################################
movi_set_failed_file()
{
    MOVINAND_FAILED_FILE="$1"
    MOVINAND_FAILURE_REASON="$2"
}


######################################################################
# Function:     movi_get_failed_file
# Purpose:      Echo's the filename that failed the movinand test.
# Paramters:    none
# Returns:      none
# Side Effect:  Echo's the filename
######################################################################
movi_get_failure_file()
{
    echo "$MOVINAND_FAILED_FILE"
}


######################################################################
# Function:     movi_get_failure_reason
# Purpose:      Returns the reason for movinand diagnostic failure
# Paramters:    none
# Returns:      MOVINAND_FAILURE_REASON - reason for failure.  One of:
#                   MOVI_MD5_CHECKSUM_ERR - File's md5sum was wrong
#                   MOVI_FILE_NOT_FOUND_ERR - File couldn't be found
######################################################################
movi_get_failure_reason()
{
    return $MOVINAND_FAILURE_REASON
}


######################################################################
# Function:     movi_display_results
# Purpose:      Display the pass/fail moviNand test status.
# Paramters:    _PASSED - 1 = Test passed
#                         0 = Test failed
# Returns:      none
# Side Effect:  Waits for operator to ack before returning
######################################################################
movi_display_results()
{
    _PASSED="$1"
    if [ $_PASSED -eq 0 ]; then
        _FAILED_FILE=`movi_get_failure_file`
        movi_get_failure_reason
        _REASON="$?"
    fi

    #
    # Tell user we couldn't find md5 master list file
    #
    clear_screen
    banner="MoviNand RootFS Verification"
    base="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    center_text "$banner" 8 "$base"
    ${DOUT} -n $? 4 "$banner"
    ${DOUT} -n 8 5 "$base"
    if [ $_PASSED -eq 1 ]; then
        ${DOUT} -n 21 7 "PASSED"
        ${DOUT} -n 6 10 "The rootfs passed md5sum verification."
    else
        ${DOUT} -n 21 7 "FAILURE"
        ${DOUT} -n 6 10 "The rootfs failed md5sum verification"
        if [ $_REASON -eq 0 ]; then
            ${DOUT} -n 6 12 "because the following file had a bad md5sum:"
        else
            ${DOUT} -n 6 12 "because the following file was missing:"
        fi

        banner="$_FAILED_FILE"
        center_text "$banner" 7 "$base"
        ${DOUT} -n $? 14 "$banner"
    fi
    ${DOUT} -n 6 18 "FS Version : $SOFTWARE_FS_VERSION"
    ${DOUT} -n 6 20 "Build Date : $SOFTWARE_FS_BUILD_DATE"
    ${DOUT} 14 23 "Press $EXIT_KEY_LABEL to continue..."
    wait_for_key $EXIT_KEY
}


######################################################################
# Function:     movi_display_list_fnf
# Purpose:      Display error screen to inform operator that the main 
#               moviNand md5 root filesystem checklist is missing.
# Paramters:    md5_list file name
# Returns:      none
# Side Effect:  Waits for operator to ack before returning
######################################################################
movi_display_list_fnf()
{
    #
    # Tell user we couldn't find md5 master list file
    #
    MD5_LIST="$1"
    clear_screen
    ${DOUT} -n 11 4 "MoviNand RootFS Verification"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 21 7 "FAILURE"
    ${DOUT} -n 2 9 "$MD5_LIST not found."
    ${DOUT} -n 6 12 "FS Version : $SOFTWARE_FS_VERSION"
    ${DOUT} -n 6 14 "Build Date : $SOFTWARE_FS_BUILD_DATE"
    ${DOUT} 14 17 "Press $EXIT_KEY_LABEL to continue..."
    wait_for_key $EXIT_KEY
}


######################################################################
# Function:     movi_display_rootfs_verify
# Purpose:      Display the main "Verifying moviNand..." screen
# Paramters:    none
# Returns:      none
######################################################################
movi_display_rootfs_verify()
{
    #
    # Ask user to verify status of LED
    #
    clear_screen
    ${DOUT} -n 11 4 "MoviNand RootFS Verification"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} -n 6 7 "Verifying the contents of the rootfs"
    ${DOUT} -n 6 9 "stored in moviNand."
    ${DOUT} -n 6 12 "FS Version : $SOFTWARE_FS_VERSION"
    ${DOUT} -n 6 14 "Build Date : $SOFTWARE_FS_BUILD_DATE"
    ${DOUT} 6 18 "This can take several minutes..."
}


######################################################################
# Function:     movi_md5_file_non_exempt
# Purpose:      Given a file, return whether file is exempt from test
#               failure or not.  This routine walks the 
#               MOVI_ROOTFS_MD5_EXEMPT list to look for the given file.
#               If the given file is in the list, return 0.
# Paramters:    The file to look for (full path)
# Returns:      0 - File exempt from failure
#               1 - File NOT exempt from failure
######################################################################
movi_md5_file_non_exempt()
{
    the_file="$1"
    for item in $MOVI_ROOTFS_MD5_EXEMPT; do
        if [ "$item" == "$the_file" ]; then
            return 0
        else
            awk "BEGIN { if ( \"$the_file\" ~ \"$item\" ) { exit 0; } else { exit 1; } }"
            if [ "$?" -eq 0 ]; then
                return 0
            fi
        fi
    done
    return 1
}


######################################################################
# Function:     movi_do_md5sum_fs
# Purpose:      Walk through the md5 list of components, verifying that
#               each component's md5 matches what's in the list.  If
#               any files fail checksumming and are not in the exempt
#               list, this diagnostic will fail.
# Paramters:    filesystem - the filesystem to checksum.
#                   One of:
#                       rootfs - checksum contents of root file system
#                       diags - checksum contents of diagnostics folder
# Returns:      0 - No errors
#               1 - Errors occurred (md5sum failure or file missing)
#               2 - The main md5sum list is missing
# Side Effect:  Sets SUB_TEST_PASSED to 0 on any failures
######################################################################
movi_do_md5sum_fs()
{
    FILESYSTEM="$1"
    MD5_SUM=0
    ERRORS=0
    TARGET_FILE=""
    DONE=0;

    case "$FILESYSTEM" in
        diags)
            echo "md5summing diagnostics folder contents..."
            export MOVI_MD5_FILE="$DIAGS_TARGET_DIAGS_MD5_LIST"
            ;;
        rootfs|*)  
            echo "md5summing rootfs folder contents..."
            export MOVI_MD5_FILE="$DIAGS_TARGET_ROOTFS_MD5_LIST"
            ;;
    esac

    # Verify the md5 list file exists...
    if ! [ -f "$MOVI_MD5_FILE" ]; then
        failure "$MOVI_MD5_FILE not found."
        do_local_echo "Failure - $MOVI_MD5_FILE not found"
        ERRORS=2
        movi_display_list_fnf "$MOVI_MD5_FILE"
    else
        while [ $DONE -eq 0 ] && [ $ERRORS -eq 0 ]; do
            read the_line
            if [ "$?" -eq 1 ]; then
                DONE=1
            else
                ERRORS=0 
                FILE_PASSED=0 
                FAILURE_COUNT=0
                # Do at least one, or try up to three times on a failure
                while ( [ $FILE_PASSED -eq 0 ] || [ $ERRORS -eq 1 ] ) && [ $FAILURE_COUNT -lt 3 ]; do
                    MD5_SUM=`echo "$the_line" | cut -c 1-32`
                    TARGET_FILE="`echo $the_line | cut -b 34-`"
                    if ! [ -f "$TARGET_FILE" ]; then
                        movi_md5_file_non_exempt "$TARGET_FILE"
                        FILE_NOT_EXEMPT=$?
                        if [ $FILE_NOT_EXEMPT -eq 1 ]; then
                            failure "md5sum - $TARGET_FILE not found"
                            do_local_echo "FAILURE: moviNand Rootfs Content Verificaiton Failure"
                            do_local_echo "Could not find file $TARGET_FILE"
                            movi_set_failed_file "$TARGET_FILE" $MOVI_FILE_NOT_FOUND_ERR
                            ERRORS=1
                            let FAILURE_COUNT++
                        else
                            vmsg "OK for Absent File Failure on $TARGET_FILE"
                            FILE_PASSED=1
                            ERRORS=0
                        fi
                    else
                        calc_sum=`md5sum "$TARGET_FILE" | cut -c 1-32`
                        if [ "$calc_sum" != "$MD5_SUM" ]; then
                            movi_md5_file_non_exempt $TARGET_FILE
                            FILE_NOT_EXEMPT=$?
                            if [ $FILE_NOT_EXEMPT -eq 1 ]; then
                                failure "md5sum failed on $TARGET_FILE"
                                do_local_echo "FAILURE: moviNand Rootfs Content Verificaiton Failure"
                                do_local_echo "MD5 Checksum Failure on $TARGET_FILE"
                                do_local_echo "Should have been $MD5_SUM, but calculated to $calc_sum"

                                # Print out some debug information, chasing a bug under here somewhere...
                                # njv 07/29/09
                                do_local_echo "System Memory Information:"
                                MEM_STR="`cat /proc/meminfo | grep Free`"
                                do_local_echo "$MEM_STR"
                                do_local_echo "TARGET_FILE: $TARGET_FILE"
                                do_local_echo "the_line: ${the_line}<eol>"
                                do_local_echo "CalcSum: ${calc_sum}<eos>"
                                do_local_echo "MD5sum : ${MD5_SUM}<eos>"
                                do_local_echo "Performing MD5_SUM=echo $the_line | cut -c 1-32"
                                _md5=`echo "$the_line" | cut -c 1-32`
                                do_local_echo "$_md5"
                                md5sum "$TARGET_FILE"
                                do_local_echo "md5sum error : $?"
                                do_local_echo "End of information"
                                movi_set_failed_file "$TARGET_FILE" $MOVI_MD5_CHECKSUM_ERR
                                ERRORS=1
                                let FAILURE_COUNT++
                                if [ $FAILURE_COUNT -eq 2 ]; then
                                    do_local_echo "Sleeping for 1 minute..."
                                    sleep 60
                                fi
                            else
                                vmsg "OK for MD5 Checksum Failure on $TARGET_FILE"
                                vmsg "$TARGET_FILE is EXEMPT from md5sum failure"
                                FILE_PASSED=1
                                ERRORS=0
                            fi
                        else
                            FILE_PASSED=1
                            ERRORS=0
                        fi
                    fi
                done;
            fi
        done < "$MOVI_MD5_FILE"
    fi

    if [ $ERRORS -eq 0 ]; then
        do_local_echo "SUCCESS: moviNand Rootfs Content Verification"
    fi

    return $ERRORS
}


######################################################################
# Function:     do_verify_movinand
# Purpose:      Verify movinand by md5sum'ing the contents of the
#               rootfs.
# Paramters:    none
# Returns:      0 - movinand verified 
#               1 - failed movinand verification
#               2 - The main md5sum list is missing
# Side Effect:  Sets the SUB_TEST_PASS variable via call to success() 
#               or failure()
######################################################################
do_verify_movinand()
{
    movi_display_rootfs_verify
    movi_do_md5sum_fs rootfs
    _err="$?"
    if [ "$_err" -eq 0 ]; then
        movi_do_md5sum_fs diags
        _err="$?"
    fi
    return "$_err"
}


######################################################################
# Function:     movi_do_cycle_diag
# Purpose:      Execute some number of "cycles" of this diagnostic.
#               For this mode, we run whatever we can that does not
#               require operator-intervention.
# Paramters:    count - number of cycles to execute
# Returns:      0 - filesystem verified OK
#               1 - FAILURE verifying rootfs
#               2 - The main md5sum list is missing
######################################################################
movi_do_cycle_diag()
{
    vmsg "Starting moviNand Diagnostic $1 Cycle Test"

    # Get cycle count
    MOVI_CYCLE_COUNT="$1"

    # Give user status...
    clear_screen
    ${DOUT} -n 15 4 "moviNand Run-In Diagnostics"
    ${DOUT} -n 8 5 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${DOUT} 8 7 "Verifying moviNand Rootfs content now..."

    # Loop through auto-run test
    ERRORS=0
    while [ $MOVI_CYCLE_COUNT -ne 0 ] && [ $ERRORS -eq 0 ]; do

        # Update count in dialog
        erase_line 11 
        ${DOUT} 8 11 "...$MOVI_CYCLE_COUNT verification cycle tests left.."

        # Make a verify pass
        do_verify_movinand
        ERRORS="$?"

        # Decrement our loop counter
        let MOVI_CYCLE_COUNT-=1
    done
    return $ERRORS
}


######################################################################
# Function:     movi_run_diag
# Purpose:      Run the main movinand diagnostic
# Paramters:    none
# Returns:      0 - filesystem verified OK
#               1 - FAILURE verifying rootfs
#               2 - The main md5sum list is missing
######################################################################
movi_run_diag()
{
    do_verify_movinand
    return "$?"
}


######################################################################
# Function:     show_movinand_test_invalid
# Purpose:      Put up a dialog to inform user that movinand test is
#               no longer valid.
# Parameters:   require_response, one of
#                   0 - Don't wait for response
#                   1 - Wait for operator ack before returning
# Returns:      0 - filesystem verified OK
#               1 - FAILURE verifying rootfs
#               2 - The main md5sum list is missing
######################################################################
show_movinand_test_invalid()
{
    require_response=$1
    clear_screen
    print_center_text "Movinand Test Is Not Valid" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 10 4
    $DOUT -n 8 7 "The movinand test is no longer"
    $DOUT -n 8 9 "a valid test because System "
    $DOUT -n 8 11 "Diagnostics have previously been"
    $DOUT -n 8 13 "disabled.  The test has already"

    if [ $require_response -eq 1 ]; then
        $DOUT -n 8 15 "served its purpose."
        $DOUT 8 19 "Press $EXIT_KEY_LABEL to return to main menu."
        wait_for_key $EXIT_KEY
    else
        $DOUT 8 15 "served its purpose."
    fi
}

case "$1" in

    stop)
        vmsg "Exiting moviNand Diagnostic Test"
        return 0
        ;;

    cycle)
        if [ $# -eq 2 ];  then
            cycle_count="$2"
        else
            cycle_count=1
        fi

        if ! ( has_diags_been_disabled ); then
            vmsg "Starting moviNand Diagnostic $cycle_count Cycle Test"
            movinand_hal_init
            movi_do_cycle_diag "$cycle_count"
            movinand_hal_exit
            did_diag_fail
            return "$?"
        else
            show_movinand_test_invalid 0

            # Don't count as a failure during run-in or it will stop
            # the test.  Instead, let it run, but run-in final result
            # will still be a failure, as it should be.
            return 0
        fi
        ;;

    start|*)
        if ! ( has_diags_been_disabled ); then
            vmsg "Starting MoviNand Diagnostic Test"
            enter_diag "MoviNand"
            # Clear any previous diagnostic test results
            clear_diag_fail
            movinand_hal_init
            movi_run_diag
            MOVI_RESULT="$?"
            movinand_hal_exit
            if [ $MOVI_RESULT -ne 2 ]; then
                did_diag_pass
                res="$?"
                movi_display_results "$res"
            fi
            exit_diag "MoviNand" 0
        else
            show_movinand_test_invalid 1
        fi
        ;;

esac
