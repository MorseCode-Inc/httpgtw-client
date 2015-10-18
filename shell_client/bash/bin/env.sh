#!/bin/bash


BINDIR="${0%/*}"
CMD="${0##*/}"
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
	, "npx": true
	, "test": "true"
	, "bad-key": "true"
}
' > "$DATF"

#CURL_OPTS="-v $CURL_OPTS"
CURL_OPTS="-s $CURL_OPTS"
CURL_OPTS="-c $COOKIES $CURL_OPTS"
WEBSERVER="168.235.144.13"
WEBSERVER="localhost"
WEBSERVER="support.morsecode-inc.com"
PORT="3081"

URL_BASE="http://$WEBSERVER:$PORT"
ALARM="nimbus/alarm/create"
QOS="nimbus/qos/definition"
QOS="nimbus/qos/data"
ENV="nimbus/env"

RESPONSE=$(curl -v $CURL_OPTS "$URL_BASE/$ENV" >"$TMPF.out" 2>"$TMPF.err")
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
