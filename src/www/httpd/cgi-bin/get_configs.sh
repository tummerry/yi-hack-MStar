#!/bin/sh

get_conf_type()
{
    CONF="$(echo $QUERY_STRING | cut -d'=' -f1)"
    VAL="$(echo $QUERY_STRING | cut -d'=' -f2)"

    if [ "$CONF" == "conf" ] ; then
        echo $VAL
    fi
}

YI_HACK_PREFIX="/home/yi-hack"

. $YI_HACK_PREFIX/www/cgi-bin/validate.sh

if ! $(validateQueryString $QUERY_STRING); then
    printf "Content-type: application/json\r\n\r\n"
    printf "{\n"
    printf "\"%s\":\"%s\"\\n" "error" "true"
    printf "}"
    exit
fi

printf "Content-type: application/json\r\n\r\n"

CONF_TYPE="$(get_conf_type)"
CONF_FILE=""

if [ "$CONF_TYPE" == "mqtt" ] ; then
    CONF_FILE="$YI_HACK_PREFIX/etc/mqttv4.conf"
else
    CONF_FILE="$YI_HACK_PREFIX/etc/$CONF_TYPE.conf"
fi

printf "{\n"

PROXY_LIST="0"
PROXYCHAINS_SERVERS=
if [ "$CONF_TYPE" == "proxychains" ] ; then
    while IFS= read -r LINE ; do
        if [ "$PROXY_LIST" == "1" ] ; then
            PROXYCHAINS_SERVERS=${PROXYCHAINS_SERVERS}${LINE}";"
        fi
        if [ "$LINE" == "[ProxyList]" ] ; then
            PROXY_LIST="1"
        fi
    done < "$CONF_FILE"
    PROXYCHAINS_SERVERS=${PROXYCHAINS_SERVERS::-1}
    echo -e \"PROXYCHAINS_SERVERS\":\"$PROXYCHAINS_SERVERS\",
else
    while IFS= read -r LINE ; do
        if [ ! -z "$LINE" ] ; then
            if [ "$LINE" == "${LINE#\#}" ] ; then # skip comments
#                printf "\"%s\",\n" $(echo "$LINE" | sed -r 's/\\/\\\\/g;s/"/\\"/g;s/=/":"/g;') # Format to json and replace = with ":"
                echo -n "\""
                echo -n "$LINE" | sed -r 's/\\/\\\\/g;s/\"/\\"/g;s/=/":"/g;s/\\\\n/\\n/g;'
                echo "\","
            fi
        fi
    done < "$CONF_FILE"
fi

if [ "$CONF_TYPE" == "system" ] ; then
    printf "\"%s\":\"%s\",\n"  "HOSTNAME" "$(cat /etc/hostname)"
    printf "\"%s\":\"%s\",\n"  "TIMEZONE" "$(cat /etc/TZ)"
fi

# Empty values to "close" the json
printf "\"%s\":\"%s\"\n"  "NULL" "NULL"

printf "}"
