#!/bin/sh

# For DIAGS_TARGET_ROOTFS_MD5_LIST
[ -f "/etc/sysconfig/paths" ] && . "/etc/sysconfig/paths"

md5_folder()
{
    cd $1 > /dev/null 2>&1
    for the_file in `ls`; do
        if [ -d "$the_file" ]; then
            if [ "$the_file" != "dev" ]; then
                md5_folder "$the_file"
            fi
        else
            md5sum "$the_file" > /dev/null 2>&1
        fi
    done
    cd - > /dev/null 2>&1
}

######################################################################
# Function:     movi_md5sum_fs
# Purpose:      Walk through the md5 list of components, verifying that
#               each component's md5 matches what's in the list.  If
#               any files fail checksumming and are not in the exempt
#               list, this diagnostic will fail.
# Paramters:    none
# Returns:      none
######################################################################
movi_md5sum_fs()
{
    MD5_SUM=0
    ERRORS=0
    TARGET_FILE=""
    DONE=0;

    # Verify the md5 list file exists...
    if [ -f "$DIAGS_TARGET_ROOTFS_MD5_LIST" ]; then
        while [ $DONE -eq 0 ] && [ $ERRORS -eq 0 ]; do
            read the_line
            if [ "$?" -eq 1 ]; then
                DONE=1
            else
                ERRORS=0
                FILE_PASSED=0
                MD5_SUM=`echo "$the_line" | cut -c 1-32`
                TARGET_FILE="`echo $the_line | cut -b 34-`"
                if [ -f "$TARGET_FILE" ]; then
                    calc_sum=`md5sum "$TARGET_FILE" | cut -c 1-32`
                fi
            fi
        done < "$DIAGS_TARGET_ROOTFS_MD5_LIST"
    fi
}

while [ 1 ]; do
    movi_md5sum_fs
    md5_folder "/"
done
