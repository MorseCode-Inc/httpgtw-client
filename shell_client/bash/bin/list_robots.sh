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
SOURCE=$(hostname -s)

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

$CLIENT robot/list

exit 0
