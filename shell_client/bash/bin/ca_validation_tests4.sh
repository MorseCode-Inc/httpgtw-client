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

while [ -z "${1##-*}" ] && [ -n "$1" ]
do
	OPT="$1"
	shift
	case "$OPT" in
	-ttl) 
		TTL="$1"
		shift
		;;

	esac
done

##
## send a heartbeat

SOURCE=$(hostname -s)
echo '{ "ttl": '900' , "source": "'$SOURCE'" } ' | $CLIENT -p - robot/heartbeat

if [ -n "$1" ]
then
	SOURCE="$1"
	shift
	echo '{ "ttl": '300' , "source": "'$SOURCE'" } ' | $CLIENT -p - robot/heartbeat
fi

if [ -n "$1" ]
then
	OCTET="$1"
	shift
else
	(( OCTET = RANDOM % 250 + 1 ))
fi

##
## QOS Defintions
define_qos -o "QOS_HTTPGTW_CAVALID_COUNTER" -d "HTTPGTW CA Validation Counter QoS" -u "Count" -s "count" -t Counter -ci "1" -met 1
define_qos -o "QOS_HTTPGTW_CAVALID_GAUGE" -d "HTTPGTW CA Validation Gauge QoS" -u "Data" -s "d" -t Gauge -ci "1" -met 2
define_qos -o "QOS_HTTPGTW_CAVALID_CPU" -d "HTTPGTW CA Validation CPU QoS" -u "Percent" -s "%" -t Gauge -ci "1.5" -met 15

##
## show QOS
#$CLIENT qos/list

CINAME="$SOURCE"

TNT2DATA='"hostname": "'$SOURCE'", "ci_ipaddress": "'10.1.100.$OCTET'", "source": "'$SOURCE'",'
#TNT2DATA='"hostname": "'$SOURCE'", "ci_ipaddress": "'10.1.100.$OCTET'", "ci_name": "'$SOURCE'", "source": "'$SOURCE'", '

TARGET="qos-target"
VALUE="120"
echo ' { '$TNT2DATA' "object": "QOS_HTTPGTW_CAVALID_COUNTER", "target": "'$TARGET'", "value": '$VALUE' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data
echo ' { '$TNT2DATA' "object": "QOS_HTTPGTW_CAVALID_GAUGE", "target": "'$TARGET'", "value": '$VALUE' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data

VALUE="400"
(( RND= RANDOM % 100 ))
(( IDLE= 100 - RND ))
echo ' { '$TNT2DATA' "ci_name": "cpu total", "source": "'$SOURCE'", "object": "QOS_HTTPGTW_CAVALID_CPU", "target": "'cpu total'", "value": '$RND' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data
echo ' { '$TNT2DATA' "ci_name": "cpu idle", "source": "'$SOURCE'", "object": "QOS_HTTPGTW_CAVALID_CPU", "target": "'cpu idle'", "value": '$IDLE' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data

sleep 5
(( RND= RANDOM % 100 ))
(( IDLE= 100 - RND ))
echo ' { '$TNT2DATA' "source": "'$SOURCE'", "object": "QOS_HTTPGTW_CAVALID_CPU", "target": "'cpu total'", "value": '$RND' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data
echo ' { '$TNT2DATA' "source": "'$SOURCE'", "object": "QOS_HTTPGTW_CAVALID_CPU", "target": "'cpu idle'", "value": '$IDLE' } ' | $CLIENT $CLIENT_VERBOSE -p - qos/data

if [ "$RND" -gt 40 ]
then
	echo ' { '$TNT2DATA' "ci_path": "1.5", "ci_name": "cpu total", "metric_id": 15, "source": "'$SOURCE'", "message": "Alarm Message CPU > 40 ('$RND')", "severity": "minor" } ' | $CLIENT $CLIENT_VERBOSE -p - alarm/create
else
	echo ' { '$TNT2DATA' "ci_path": "1.5", "ci_name": "cpu total", "metric_id": 15, "source": "'$SOURCE'", "message": "Alarm Message CPU < 40 ('$RND')", "severity": "info" } ' | $CLIENT $CLIENT_VERBOSE -p - alarm/create
fi


exit 0
