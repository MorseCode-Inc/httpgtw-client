#!/bin/bash


BINDIR="${0%/*}"
CMD="${0##*/}"
CMD="${CMD%\.*}"
TMPDIR="$BINDIR/../tmp"
LOGDIR="$BINDIR/../logs"
LOGF="$LOGDIR/${CMD}.log"
TMPF="$TMPDIR/tmp.$$-${CMD}.tmp"


if [ -f "$BINDIR/common.functions" ]
then
	. "$BINDIR/common.functions"
fi

CLIENT="$BINDIR/client.sh"


# define the QoS Object(s) that we will be sending data for.
define_qos -o QOS_HTTPGTW_CPU_COUNTERS -u ticks -s ticks -d "CPU Time Ticks" -t Counter -ci 1.5 -met 8


if [ ! -f "/proc/stat" ]
then
	echo "ERR: /proc/stat does not exist. This script may not be compatible with this distribution $(uname -n)"
	exit
fi

CPU_STATS=$(grep "^cpu " /proc/stat)
set -- $CPU_STATS
shift
USER_TIME="$1"; shift
NICE_TIME="$1"; shift
SYSTEM_TIME="$1"; shift
IDLE_TIME="$1"; shift
IOWAIT="$1"; shift
IRQ="$1"; shift
SOFTIRQ="$1"; shift
(( TOTAL= USER_TIME + NICE_TIME + SYSTEM_TIME + IDLE_TIME + IOWAIT + IRQ + SOFTIRQ ))
(( TOTAL_BUSY= USER_TIME + NICE_TIME + SYSTEM_TIME + IOWAIT + IRQ + SOFTIRQ ))



send_qos -o QOS_HTTPGTW_CPU_COUNTERS \
	-ciname "$(hostname -s)" \
	-host "$(hostname -s)" \
	-s "$(hostname -s)" \
	-t "user" \
	-v "$USER_TIME"


send_qos -o QOS_HTTPGTW_CPU_COUNTERS -ciname "$(hostname -s)" -s "$(hostname -s)" -t "system" -v "$SYSTEM_TIME"
send_qos -o QOS_HTTPGTW_CPU_COUNTERS -ciname "$(hostname -s)" -s "$(hostname -s)" -t "idle" -v "$IDLE_TIME"
send_qos -o QOS_HTTPGTW_CPU_COUNTERS -ciname "$(hostname -s)" -s "$(hostname -s)" -t "iowait" -v "$IOWAIT"
send_qos -o QOS_HTTPGTW_CPU_COUNTERS -ciname "$(hostname -s)" -s "$(hostname -s)" -t "busy" -v "$TOTAL_BUSY"
send_qos -o QOS_HTTPGTW_CPU_COUNTERS -ciname "$(hostname -s)" -s "$(hostname -s)" -t "total" -v "$TOTAL"

rm -f "$TMPF"


exit
