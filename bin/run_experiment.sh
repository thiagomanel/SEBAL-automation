#!/bin/bash
echo "Starting script."

# Checking params
if [[ $# -ne 1 ]]; then
 echo "Usage:" $0 "mode [start,monitor,stop]"
 exit 1
fi


#DIRNAME=`dirname $0`
#source "$DIRNAME/sebal-automation.conf"
#source "$DIRNAME/infra.sh"
#source "$DIRNAME/collect-log-dump-db.sh"
#source "$DIRNAME/sebal_clean.sh"
#source "$DIRNAME/stage-in.sh"
#source "$DIRNAME/../scripts/collect-image-status"
#source "$DIRNAME/image_util.sh"

#EXECUTION_UUID=`uuidgen`
#echo "Preparing execution ID: $EXECUTION_UUID"

checkParams

case $mode in
    start)
	;;
    monitor)
	;;
    stop)
	;;
    *)
	;;
esac
