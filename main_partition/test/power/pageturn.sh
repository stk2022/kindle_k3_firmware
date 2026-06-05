#!/bin/sh

# This pageturn script goes into an endless loop of page turn.
# TIMEOUT sets the number of seconds between page turn
# The script loops through a NextPage-PrevPage sequence so that, if the document
# opened prior to starting the run contains at least 2 pages, the behavior will
# be exactly as expected. Beware though is may biased the result of power drain
# measurement because of the actual content displayed is limited to the 2 pages
# the script loops through (image content may not be present...) 

# Go grab some helpers to ease the logging part of things
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

# This is the time the script sleeps between pageturn 
{ [ "x$1" = "x" ] && TIMEOUT=30; } || TIMEOUT=$1

# Settting the date to something easy to track
date 010100002008.01

# The big loop
X=0
while true ; do
    # Send NextPage, log some basic things and sleep $TIMEOUT seconds
    next_page
    X=$((X + 1))
    msg "Page: $X -- `date` -- battery at `lipc-get-prop com.lab126.powerd battLevel`%" I
    sleep $TIMEOUT

    # Sending PrevPage, log some basic things and sleep $TIMEOUT seconds
    prev_page
    X=$((X + 1))
    msg "Page: $X -- `date` -- battery at `lipc-get-prop com.lab126.powerd battLevel`%" I
    sleep $TIMEOUT
    
    # Every 50 page turns, log some more stuff
	if [ "x$((X % 50))" == "x0" ]; then
		lipc-get-prop com.lab126.powerd status
	fi
done

