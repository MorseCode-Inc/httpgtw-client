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


QOS1="QOS_HTTPGTW_TEST_COUNTER"
QOS2="QOS_HTTPGTW_DELTA_TEST"

define_qos -o "$QOS1" -d "HTTP Gateway Test Counter QoS Type Counter" -u "Count" -s "count" -t "Counter" -ci 1.1

TIME=$(date +'%s')
(( TIME= TIME % 500 ))
(( R= 100 + RANDOM % 5000 ))

send_qos -o "$QOS1" -s "$(hostname -s)" -t "max 50k" -v "$TIME"

define_qos -o "$QOS2" -d "HTTP Gateway Test Counter QoS Type Delta" -u "Count" -s "count" -t "Delta" -ci 1.1
send_qos -o "$QOS1" -s "$(hostname -s)" -t "random" -v "$R"
send_qos -o "$QOS2" -s "$(hostname -s)" -t "max 50k" -v "$TIME"
send_qos -o "$QOS2" -s "$(hostname -s)" -t "random" -v "$R"

rm -f "$TMPF"


exit
