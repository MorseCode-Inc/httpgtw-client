#!/bin/bash


BINDIR="${0%/*}"
CMD="${0##*/}"
CMD="${CMD%\.*}"
echo "$CMD"
TMPDIR="$BINDIR/../tmp"
LOGDIR="$BINDIR/../logs"
LOGF="$LOGDIR/${CMD}.log"
TMPF="$TMPDIR/tmp.$$-${CMD}.tmp"
DATF="$TMPDIR/${CMD}.dat"
COOKIES="$TMPDIR/${CMD}.cache"

if [ ! -d "$TMPDIR" ]; then mkdir -p "$TMPDIR"; fi
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi

echo '
{
	"error": false
	, "npx": false
	, "test": "true"
	, "bad-key": "true"
}
' > "$DATF"

#CURL_OPTS="-v $CURL_OPTS"
CURL_OPTS="-s $CURL_OPTS"
CURL_OPTS="-c $COOKIES $CURL_OPTS"
WEBSERVER="localhost"
PORT="3081"

URL_BASE="http://$WEBSERVER:$PORT"
ALARM="nimbus/alarm/create"
QOS="nimbus/qos/definition"
QOS="nimbus/qos/data"

RESPONSE=$(curl -v $CURL_OPTS -H "content-type: application/json" -d "@$DATF" "$URL_BASE/$ALARM" >"$TMPF.out" 2>"$TMPF.err")
RC="$?"

sed -i -e "s/\r//g" "$TMPF.out"
sed -i -e "s/\r//g" "$TMPF.err"

cat "$TMPF.out"
echo
#cat "$TMPF.err" 

if [ "$RC" != 0 ]
then
	{
	echo ERROR
	cat "$TMPF.err" 
	echo
	} >&2
fi

# see if we got HTTP 200
HTTP_RESP=$(grep "^< HTTP" "$TMPF.err" | head -1)
set -- $HTTP_RESP
shift
case "$2"
in
200)
	;;
*)
	echo "$*" >&2
	exit $2
	;;
esac

#rm -f "$TMPF.err"
rm -f "$TMPF.out"
rm -f "$TMPF"


exit "$RC"
