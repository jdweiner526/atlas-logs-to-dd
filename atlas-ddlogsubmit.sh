#!/bin/bash
set -e -u -o pipefail

DEBUG=false
${DEBUG} && set -x 

DDAPIKEY=ADD_YOUR_DATADOG_KEY_HERE

SOURCEHOST=$1

while read INLINE ; do
	# add fields to INLINE
	# jq '. += {"foo":"bar"}'

	# add DD-appropriate timestamp, taken from .t.$date
	INLINE=$(echo ${INLINE} | jq -c '. += {"@timestamp": .t."$date"}')

	# add source attribute
	INLINE=$(echo ${INLINE} | jq -c '. += {"source": "MongoDB_Atlas"}')
	
	# add host attribute
	INLINE=$(echo ${INLINE} | jq -c --arg SOURCEHOST "$SOURCEHOST" '. += {"host": $SOURCEHOST}')

	# add "remoteip", taken from "remote"
	INLINE=$(echo ${INLINE} | jq -c '. += {"remoteip": (.attr.remote | scan("[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")?)}')

	${DEBUG} && echo ${INLINE}

	${DEBUG} || echo "${DDAPIKEY} ${INLINE}" | openssl s_client -connect intake.logs.datadoghq.com:10516 2>/dev/null
	${DEBUG} && echo "Logging ${INLINE}"

	sleep 0.1

done
