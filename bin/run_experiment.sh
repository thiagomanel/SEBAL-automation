#!/bin/bash
echo "Starting script."

# Checking params
if [[ $# -ne 1 ]]; then
 echo "Usage:" $0 "mode [start,monitor,stop]"
 exit 1
fi

mode=$1
DIRNAME=`dirname $0`
#source "$DIRNAME/sebal-sites.conf"
#source "$DIRNAME/sebal-automation.conf"
#source "$DIRNAME/infra.sh"
#source "$DIRNAME/collect-log-dump-db.sh"
#source "$DIRNAME/sebal_clean.sh"
#source "$DIRNAME/stage-in.sh"
#source "$DIRNAME/../scripts/collect-image-status"
#source "$DIRNAME/image_util.sh"
#EXECUTION_UUID=`uuidgen`
#echo "Preparing execution ID: $EXECUTION_UUID"

function sites {
    cut -d" " -f1 $DIRNAME/sebal-sites.conf | grep -v "#"
}

function components {
    local site=$1
    site_conf=`grep $site $DIRNAME/sebal-sites.conf`
    echo $site_conf | cut -d" " -s -f2-
}

functin start_component {
    local component=$1
    comp_name=`echo $component | cut -d":" -f1`
    comp_address=`echo $component | cut -d":" -f2`
    echo $site $component
    case $comp_name in
        crawler)
	    ;;
	archiver)
	    ;;
	catalog)
	    ;;
	*)
	    ;;
    esac
}

case $mode in
    start)
        for site in `sites $DIRNAME/sebal-sites.conf`
	    do
	        echo $site
	        for component in `components $site`
		do
		    start_component $component
		done
	    done
        ;;
    monitor)
	;;
    stop)
	;;
    *)
	;;
esac
