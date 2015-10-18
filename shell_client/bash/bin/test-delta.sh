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


QOS_DELTA="QOS_HTTPGTW_TEST_DELTA"
QOS_COUNTER="QOS_HTTPGTW_TEST_COUNTER"
QOS_GAUGE="QOS_HTTPGTW_TEST_GAUGE"

define_qos -o "$QOS_DELTA" -d "HTTP Gateway Test Delta QoS Type" -u "Count" -s "count" -t "Delta" -ci 1.1 -met 1
define_qos -o "$QOS_COUNTER" -d "HTTP Gateway Test Counter QoS Type" -u "Count" -s "count" -t "Counter" -ci 1.1 -met 1
define_qos -o "$QOS_GAUGE" -d "HTTP Gateway Test Gauge QoS Type" -u "Count" -s "count" -t "Gauge" -ci 1.1 -met 1

TIME=$(date +'%s')
(( TIME= TIME % 50000 ))

send_qos -o "$QOS_DELTA" -s "$(hostname -s)" -t "time 500" -v "$TIME"
send_qos -o "$QOS_COUNTER" -s "$(hostname -s)" -t "time 500" -v "$TIME"
send_qos -o "$QOS_GAUGE" -s "$(hostname -s)" -t "time 500" -v "$TIME"

rm -f "$TMPF"


exit
