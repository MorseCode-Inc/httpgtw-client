#!/bin/bash

usage() {
cat << EOF

Usage
${0##*/} [options] -p|-g [-h host] [-np port] uri_path

    POST data from a file
    ${0##*/} [options] -p <filename> [-h host] [-np port] uri_path

    POST data from STDIN
    ${0##*/} [options] -p - [-h host] [-np port] uri_path

    GET
    ${0##*/} [options] -g [-h host] [-np port] uri_path

All Options:
-h <host>		Hostname or IP of the http_gateway probe
			default = localhost

-np <port>		Specify a different TCP port
			default = 3801

-g 			HTTP GET. Only uses URL query parameters
			If neither -p or -g are specified, -g is assumed

-p <file>		POST existing data file
			Use '-' as the filename to specify STDIN data source

-v			More verbose output including HTTP headers
-?			This help page
		
Examples:

    ${0##*/} -g env
    ${0##*/} -g robot/list
    ${0##*/} -g qos/list

Because -g is implied by default, the following examples are equivalent

    ${0##*/} env
    ${0##*/} robot/list
    ${0##*/} qos/list




EOF
}

abspath() {
	DIR="${1%/*}"
	FILE="${1##*/}"
	if [ ! -d "$DIR" ]
	then
		echo "ERR $DIR must be a directory" >&2
		exit 2
	fi

	cd "$DIR" >/dev/null 2>&1
	echo "$(pwd)/$FILE"
	cd - >/dev/null 2>&1

}

BINDIR="${0%/*}"
CMD="${0##*/}"
CMD="${CMD%\.*}"
TMPDIR="$BINDIR/../tmp"
LOGDIR="$BINDIR/../logs"
LOGF="$LOGDIR/${CMD}.log"
TMPF="$TMPDIR/tmp.$$-${CMD}.tmp"
DATAF="$TMPDIR/${CMD}.dat"
COOKIES="$TMPDIR/${CMD}.cache"

if [ ! -d "$TMPDIR" ]; then mkdir -p "$TMPDIR"; fi
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi

CONTENT_TYPE="application/json"
WEBSERVER="localhost"
#WEBSERVER="support.morsecode-inc.com"
WEBSERVER="dash.morsecode-inc.com"
PORT="3081"
#PORT="3080"


## parse parameters
while [ -n "$1" ] && [ -z "${1%%-*}" ]
do
	OPT="$1"
	shift
	case "$OPT" in
	-p)	# POST
		MODE="POST"
		DATAF="$1"
		shift
		if [ "$DATAF" == "-" ]
		then
			while read LINE; do echo "$LINE"; done > "$TMPF.post"
			DATAF="$TMPF.post"
		else
			DATAF=$(abspath "$DATAF")
			shift
			if [ ! -f "$DATAF" ]
			then
				echo "POST $DATAF must be a file or - to read from STDIN." >&2
				exit 2
			fi
		fi
		DATAF="-d @$DATAF"
		CONTENT_TYPE="application/json"
		;;
	-h)	# set the hostname
		WEBSERVER="$1"
		shift
		;;
	-np)	# set the port
		PORT="$1"
		shift
		;;
	-g)	# GET
		DATAF=""
		;;
	-curl)
		CURLOPTS="$1"
		shift
		;;
	-v)
		VERBOSE="1"
		;;
	-\?|-help|--help)
		usage
		exit 0
		;;
	esac
done

#CURL_OPTS="-v $CURL_OPTS"
CURL_OPTS="-s $CURL_OPTS"
CURL_OPTS="-c $COOKIES $CURL_OPTS"
if [ -f "$COOKIES" ]
then
	CURL_OPTS="-b $COOKIES $CURL_OPTS"
fi

URL_BASE="http://$WEBSERVER:$PORT/nimbus"
ALARM="nimbus/alarm/create"
QOS="nimbus/qos/definition"
QOS="nimbus/qos/data"
ENDPOINT="$1"

if [ -f "$DATAF" ] || [ -f "${DATAF#*@}" ]
then
	echo ">>"
	cat "${DATAF#*@}"
	echo "<<"
else
	DATAF=""
fi

if [ -n "$VERBOSE" ]
then
	echo curl -v $CURL_OPTS -H "content-type: $CONTENT_TYPE" $DATAF "$URL_BASE/$ENDPOINT" 
	if [ -n "$DATAF" ]
	then
		:cat "${DATAF#*@}"
	fi
fi
	echo curl -v $CURL_OPTS -H "content-type: $CONTENT_TYPE" $DATAF "$URL_BASE/$ENDPOINT" 

RESPONSE=$(curl -v $CURL_OPTS -H "content-type: $CONTENT_TYPE" $DATAF "$URL_BASE/$ENDPOINT" >"$TMPF.out" 2>"$TMPF.err")
RC="$?"

sed -i -e "s/\r//g" "$TMPF.out"
sed -i -e "s/\r//g" "$TMPF.err"

echo "$(cat "$TMPF.out")"
echo

if [ -n "$VERBOSE" ]
then
	cat "$TMPF.err" 
fi

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
	RC="$2"
	;;
esac

rm -f "$TMPF.post"
rm -f "$TMPF.err"
rm -f "$TMPF.out"
rm -f "$TMPF"


exit "$RC"
