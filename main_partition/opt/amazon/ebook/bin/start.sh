#!/bin/sh

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

_EIPUTS=/usr/sbin/eiputs
[ -f ${_EIPUTS} ] && . ${_EIPUTS}

EVENT_QUEUE_EXCEPTION_HANDLER=com.amazon.ebook.framework.impl.device.event.EventDispatchThreadExceptionHandler
LOG="/usr/bin/logger -t `basename $0` -s"
EXCEPTION_EXIT=128
# 194 = 128 + 65 _NSIG + 1
CANNOT_RESTART_EXIT_CODE=194
RESTART_RETRIES_COUNT_FILE=$FRAMEWORK_RETRIES_COUNT_FILE
MAX_RESTART_RETRIES=5
DELAY_RESTART_RETRIES=1

FRAMEWORK_RETURN=/tmp/.framework_return
CVM_PID_FILE=/var/run/cvm.pid
DEBUG_CVM_CRASH_FILE=/mnt/us/DEBUG_CVM_CRASH
# Legacy file, will be removed shortly
DONT_RESTART_FRAMEWORK_FILE_OLD=/mnt/us/system/dont-restart-framework
FRAMEWORK_CRASH_FILE=
RESTART_FRAMEWORK=

GET_KEY_CODES=/usr/bin/waitforkey
LOGO_SCREEN=5
KEY_R=19
KEY_D=32
KEY_CODE=
KEY_VALU=

java_home=/usr/java
java_locale_data=$java_home/lib/localedata.jar
java_charset_data=$java_home/lib/charsets.jar

java=$java_home/bin/cvm

ebook_home=/opt/amazon/ebook

bookletdir=$ebook_home/booklet
libdir=$ebook_home/lib
logdir=$ebook_home/log
configdir=$ebook_home/config
securitydir=$ebook_home/security
testlibdir=/test/ebook/lib

log_pid() {
	sleep 1
	_COUNT=3
	while [ $_COUNT -gt 0 ]; do
		_PID=`pidof cvm`
		if [ -n $_PID ]; then
			echo $_PID>$CVM_PID_FILE
			return
		fi

		_COUNT=$((_COUNT-1))
		sleep 1
	done

	${LOG} "Failed to get CVM PID"
}

get_framework_crash_file() {
    FRAMEWORK_CRASH_FILE=
    if [ -f ${DEBUG_CVM_CRASH_FILE} ]; then
        FRAMEWORK_CRASH_FILE=${DEBUG_CVM_CRASH_FILE}
    elif [ -f ${DONT_RESTART_FRAMEWORK_FILE_OLD} ]; then
        FRAMEWORK_CRASH_FILE=${DONT_RESTART_FRAMEWORK_FILE_OLD}
    fi
}

put_framework_crash_message_up() {
    echo "## NOTE: Framework is set to not restart on a CVM crash. ##"
    echo "## To revert this behavior, remove file: ${FRAMEWORK_CRASH_FILE} ##"
}

set_key_codes() {
    KEY_CODE=$1
    KEY_VALU=$2
}

get_key_codes() {
    KEY_CODES="`${GET_KEY_CODES}`"
    set_key_codes ${KEY_CODES}
}

logo_screen() {
    ${EIPS} -s ${LOGO_SCREEN}
}

put_framework_crash_waitscreen_up() {
    put_framework_crash_message_up
    wake_input_devices

    logo_screen
    puts_init

    puts -b "~~~~ framework crashed ~~~~"
    puts -b
    puts -b " press the R key..."
    puts -b " ...to restart"
    puts -b
    puts -b " press the D key..."
    puts    " ...to debug"

    RESTART_FRAMEWORK=0
    _DONE=0
    while [ ${_DONE} -eq 0 ]; do
        get_key_codes

         case ${KEY_CODE} in
            ${KEY_R})
                RESTART_FRAMEWORK=1
                _DONE=1
            ;;

            ${KEY_D})
                _DONE=1
            ;;
        esac
    done
}

put_framework_debugging_screen_up() {
    logo_screen
    puts_init

    puts "~~~~ debugging crash ~~~~"
}

start_framework() {
	clazzpath=
	if [ -d "$libdir" ]; then
		for i in "$libdir"/*.jar; do
		    clazzpath="$clazzpath":"$i"
		done
	fi
	if [ -d "$bookletdir" ]; then
		for i in "$bookletdir"/*.jar; do
		    clazzpath="$clazzpath":"$i"
		done
	fi
	if [ -d "$testlibdir" ]; then
		for i in "$testlibdir"/*.jar; do
		    clazzpath="$clazzpath":"$i"
		done
	fi

	# get_mem_total, defined in features, returns total memory as reported
	# by /proc/meminfo
	mem=`get_mem_total`
	if [ "x$mem" != "x" -a $mem -gt 256000 ]; then
		jvm_heap_options="-Xmx20m -Xgc:youngGen=3m"
	else
		jvm_heap_options="-Xmx16m -Xgc:youngGen=1m"
	fi

	jvm_opt="$jvm_heap_options \
-Dsun.awt.exception.handler=$EVENT_QUEUE_EXCEPTION_HANDLER \
-Xbootclasspath/a:$java_locale_data:$java_charset_data \
-Dsun.boot.library.path=$java_home/lib \
-cp $clazzpath:$ebook_home/lib/portability-impl.jar"

# -Ddebug: debugging log output 1 = none, 2 = all debugging levels (0-9), 3 = profiling

# -DUI_TIMEOUT: used to monitor AWT event processing, set to ZERO to disable
# a number of milliseconds to wait while processing AWT events (keys, paints, etc.)
# if time is exceeded, a "cvm-dumpstack" is issued

# DENABLE_SEARCH_INDEXING_THREAD: set to FALSE to disable indexing on device

# -Djava.awt.DebugPaint: set to TRUE to enable stack dumps of all AWT repaint sources

# -DUSE_KWGRAPHICS: set to TRUE to return Kwindow.KWGraphics graphics wrapper class from KWindow.getGraphics(), useful for debuggin drawing logic

app_opt="
-Ddebug=1 \
-Dcheck_comm_stack=true \
-Dsun.net.client.defaultReadTimeout=120000 \
-Dhttp.keepalive.timeout=60000 \
-DUI_TIMEOUT=0 \
-Dhttp.maxConnections=16 \
-Dallow_demo=false \
-Djava.awt.SyncOnPaint=false \
-Dextkeyboard=false \
-Dconfig=$configdir/framework.luigi.conf \
-DPLATFORM_CLASS_FILE=/opt/amazon/ebook/config/platform.conf \
-DENABLE_SEARCH_INDEXING_THREAD=true \
-Dpolicy.home=$securitydir \
-Djava.security.manager \
-Djava.awt.DebugPaint=false \
-DUSE_KWGRAPHICS=false"

	# use either jvmpi or jvmti, not both
	#jvmpihprof_opt="-Xrunhprof:heap=all,thread=y,file=/mnt/base-us/framework.$$.hprof.txt"
	#jvmtihprof_opt="-Xbootclasspath/a:/usr/java/lib/java_crw_demo.jar \
	#                -agentlib:jvmtihprof=cpu=times,heap=sites,thread=y,file=/mnt/us/framework.$$.hprof.txt"

    # uncomment next line to enable source level debugging on device
	#debug_opt="-agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend=y -Xdebug -DMinimumKindletTimeoutMillis=60000"

	opts="$jvm_opt $jit_opt $jvmpihprof_opt $jvmtihprof_opt $debug_opt $app_opt"

	echo $opts

	app=com.lab126.linux.arm.LuigiServiceProvider

    get_framework_crash_file
    if [ -n "${FRAMEWORK_CRASH_FILE}" ]; then
        put_framework_crash_message_up
        # Sun chose env variable name after we set up file
        # /mnt/us/DEBUG_CVM_CRASH.  Leaving the file as it is, but using
        # Sun's env variable.
        export CVM_CRASH_DEBUG=1
    fi

	log_pid &
	LD_PRELOAD=$java_home/lib/libmicrowindowsawt.so $java $opts $app 2>&1
	echo "$?">${FRAMEWORK_RETURN}
	rm -rf $CVM_PID_FILE 2>/dev/null
}

############## START OF SCRIPT ################

while [ ! -f ${FRAMEWORK_STOP_FILE} ]; do
    if [ -e ${RESTART_RETRIES_COUNT_FILE} ]; then
		_COUNT=`cat  ${RESTART_RETRIES_COUNT_FILE}`
       	RESTART_RETRIES_COUNT=`expr ${_COUNT} + 1`
       	echo -n ${RESTART_RETRIES_COUNT} > ${RESTART_RETRIES_COUNT_FILE}
	else
	   	RESTART_RETRIES_COUNT=1
		echo -n 1 > ${RESTART_RETRIES_COUNT_FILE}
	fi

	if [ ${RESTART_RETRIES_COUNT} -gt ${MAX_RESTART_RETRIES} ]; then
        if [ -e ${FRAMEWORK_REBOOT_COUNT_FILE} ]; then
            echo -n 2 > ${FRAMEWORK_REBOOT_COUNT_FILE}
        else
    		echo -n 1 > ${FRAMEWORK_REBOOT_COUNT_FILE}
        fi
		reboot
		exit 17
	fi

    ${LOG} "starting framework"

    start_framework | logger -p local2.debug

    # Stop all audio
    lipc-set-prop -i com.lab126.audio Control 3

    # Note:  When we're in DEBUG_CVM_CRASH mode, we don't always get back here without
    #        manually invoking "killall -KILL cvm" from the command line.
    #
    if ! ( is_Framework_Stopped ); then
        get_framework_crash_file
        if [ -n "${FRAMEWORK_CRASH_FILE}" ]; then
            put_framework_crash_waitscreen_up

            if [ ${RESTART_FRAMEWORK} -eq 0 ]; then
                put_framework_debugging_screen_up
                echo 0 >${FRAMEWORK_RUNNING}
                export CVM_CRASH_DEBUG=
                exit 18
            else
                clean_reboot
            fi
        fi
    fi

    _EXITVAL=`cat ${FRAMEWORK_RETURN}`

    if [ ${_EXITVAL} -ge ${EXCEPTION_EXIT} ]; then

        if [ ${_EXITVAL} -eq ${CANNOT_RESTART_EXIT_CODE} ]; then
            msg "signal=${_EXCEPTION_VALUE},exitval=${_EXITVAL}: Restart from framework failed.  Restarting from outside" W restart
            restart
            exit
        fi

        _EXCEPTION_VALUE=`expr ${_EXITVAL} - ${EXCEPTION_EXIT}`

        if [ ${_EXCEPTION_VALUE} -eq 15 ]; then
            msg "signal=${_EXCEPTION_VALUE},exitval=${_EXITVAL}:CVM stopped using SIGTERM" I stop
        else
            msg "signal=${_EXCEPTION_VALUE},exitval=${_EXITVAL}:FATAL EXCEPTION: CVM received fatal signal" C crash
        fi
        echo ${_EXCEPTION_VALUE} >${FRAMEWORK_EXCEPTION_FILE}

    else
        ${LOG} "framework exited (${_EXITVAL})"
        echo ${_EXITVAL} >${FRAMEWORK_EXCEPTION_FILE}
    fi

	sleep 1

	_TERM_RETRIES=5
	_COUNT=0

	while [ ${_COUNT} -lt ${_TERM_RETRIES} ]; do

		if [ -z "`pidof cvm`" ]; then
			break
		fi

		killall -KILL cvm

		_COUNT=`expr ${_COUNT} + 1`

		sleep ${DELAY_RESTART_RETRIES}

	done

    # Pretend that we're rebooting by ensuring that we're back in portrait orientation, and then put
    # up the logo screen along with the starting boot progress bar.  The Framework will then fill up
    # the rest of the progress bar as it finishes coming back up.
    #
    if ! ( is_Framework_Stopped ); then

        # Let the world know that the Framework is no longer running.
        #
        echo 0 >${FRAMEWORK_RUNNING}

        # Get the display back into its usual booting-up state.
        #
        display_logo_screen

        # Tell the world that we're starting the Framework back up.
        #
        echo 1 >${FRAMEWORK_STARTED}

    fi

done

rm -f ${FRAMEWORK_STOP_FILE}

