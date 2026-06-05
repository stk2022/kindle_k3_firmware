#!/bin/sh

# This script calibrates the mma7455L accelerometer found in Nell EVT1 units

# Does this system have the mma7455L accelerometer?
ACCEL=`lsmod | grep mma7455L`
if [ -z "$ACCEL" ]; then
   echo "mma7455L driver is not present in this system.  Calibration cannot be done."
   exit 1
fi

# Prompt user to put unit flat before calibrating
echo "mma7455L accelerometer calibration about to start"
echo "**** PLACE NELL FACE UP ON A FLAT SURFACE; THEN PRESS <ENTER> ****"
read REPLY

# Send calibration command to driver
echo "calibrate" > /proc/accelerometer

# Get calibration settings for use after reboot
cat /proc/calibration > /var/local/calibration.sh
chmod +x /var/local/calibration.sh
sync

echo "mma7455L calibration done."
