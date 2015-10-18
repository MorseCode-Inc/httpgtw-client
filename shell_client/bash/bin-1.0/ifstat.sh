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


QOS_RX_BYTES="QOS_HTTPGTW_IFSTATS_RX_BYTES"
QOS_TX_BYTES="QOS_HTTPGTW_IFSTATS_TX_BYTES"
QOS_BYTES="QOS_HTTPGTW_IFSTATS_BYTES"

#define_qos -o "$QOS_RX_BYTES" -d "Interface Bytes Received" -u "Bytes" -s "b" -t "Counter"
#define_qos -o "$QOS_RX_BYTES" -d "Interface Bytes Received" -u "Bytes" -s "b" -t "Counter"
define_qos -o "$QOS_TX_BYTES" -d "Interface Bytes Sent" -u "Bytes" -s "b" -t "Counter"


#
#
#Inter-|   Receive                                                |  Transmit
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#    lo:153719420  936109    0    0    0     0          0         0 153719420  936109    0    0    0     0       0          0
#  eth0:2634347242 2599037    1    0    0     0          0         0 404850776 2099844    0    0    0     0       0          0
#  eth1:  231910     607    0    0    0     0          0         0    81351     437    0    0    0     0       0          0
#  eth2:  228945     527    0    0    0     0          0         0     7971      61    0    0    0     0       0          0


DEVICES=$(grep : /proc/net/dev | cut -d: -f1 | sed -e "s/ //g")

for DEVICE in $DEVICES
do

	STATS=$(grep "$DEVICE:" /proc/net/dev)
	set -- $STATS
	shift
	RX_BYTES="$1"; shift
	RX_PACKETS="$1"; shift
	RX_ERRORS="$1"; shift
	RX_DROPPED="$1"; shift
	RX_FIFO="$1"; shift
	RX_FRAME="$1"; shift
	RX_COMPRESSED="$1"; shift
	RX_MULTICAST="$1"; shift
	TX_BYTES="$1"; shift
	TX_PACKETS="$1"; shift
	TX_ERRORS="$1"; shift
	TX_DROPPED="$1"; shift
	TX_FIFO="$1"; shift
	TX_FRAME="$1"; shift
	TX_COMPRESSED="$1"; shift


	(( BYTES= RX_BYTES + TX_BYTES ))

	send_qos -o "$QOS_RX_BYTES" -s "$(hostname -s)" -t "$DEVICE" -v "$RX_BYTES"
	send_qos -o "$QOS_TX_BYTES" -s "$(hostname -s)" -t "$DEVICE" -v "$TX_BYTES"
	send_qos -o "$QOS_BYTES" -s "$(hostname -s)" -t "$DEVICE" -v "$BYTES"
	#echo ' { "connection":"keep-alive", "object": "'$QOS_OBJECT'" , "value": '$USER_TIME' , "sampletime": '$(date +'%s')' , "target": "User" } ' | $CLIENT -p - qos/data


done

#echo ' { "connection":"keep-alive", "object": "'$QOS_OBJECT'" , "value": '$IDLE_TIME' , "sampletime": '$(date +'%s')' , "target": "Idle" } ' | $CLIENT -p - qos/data
#echo ' { "connection":"close", "object": "'$QOS_OBJECT'" , "value": '$WAIT_TIME' , "sampletime": '$(date +'%s')' , "target": "Wait" } ' | $CLIENT -p - qos/data

rm -f "$TMPF"


exit
