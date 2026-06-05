#!/bin/sh

# Go grab some helpers to ease the logging part of things
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

# This is the time the script sleeps between pageturn 
TIMEOUT=30

# Settting the date to something easy to track
date 010100002008.01

the_loop()
{
    X=0
    while true ; do
        CHARGING=`lipc-get-prop com.lab126.powerd status | sed '/Charging/!d; s/Charging:\s*\([Yes|No]\)/\1/g'`
        # Every 16 cycles, log some more stuff
    	if [ "x$((X % 16))" = "x0" ]; then
            if [ "x$CHARGING" = "xYes" ]; then msg "`date` -- battery is not charging anymore "; break ; fi
    	fi

        # Log some basic things and sleep $TIMEOUT seconds
        BATTLEVEL=`lipc-get-prop com.lab126.powerd battLevel`

        msg "`date` -- battery at `gasgauge-info -v` and `lipc-get-prop com.lab126.powerd battLevel`%"
        X=$((X + 1))
        sleep $TIMEOUT
    done

}
	
the_loop
	
