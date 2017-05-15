#!/bin/bash
echo "Starting script."

# Checking params
if [[ $# -ne 1 ]]; then
 echo "Usage:" $0 "start | monitor | stop | crawler-allocate [site] | crawler-deallocate [site]"
 exit 1
fi

mode=$1
DIRNAME=`dirname $0`
source "$DIRNAME/saps.cconf"
#source "$DIRNAME/sebal-sites.conf"
#source "$DIRNAME/sebal-automation.conf"
#source "$DIRNAME/infra.sh"
#source "$DIRNAME/collect-log-dump-db.sh"
#source "$DIRNAME/sebal_clean.sh"
#echo "Preparing execution ID: $EXECUTION_UUID"

SIZE_FAKE_DATA_GB=1

function sites {
    cut -d" " -f1 $DIRNAME/sebal-sites.conf | grep -v "#"
}

function components {
    local site=$1
    site_conf=`grep $site $DIRNAME/sebal-sites.conf`
    echo $site_conf | cut -d" " -s -f2-
}

function start_component {
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

function monitor {
  local site=$1
  local period=$2
  local comp=`components $site`

  if [ ! -f $disk_usage_monitor_output_file ]
  then
    touch $disk_usage_monitor_output_file
  fi
  
  while true
  do
    disk_usage=$(df -P $crawler_export_dir | awk 'NR==2 {print $5}')
    date=$(date +"%H:%M:%S-%D")
    echo "Site: $site | Crawler Volume Usage: $disk_usage | Date: $date" >> $disk_usage_monitor_output_file
    sleep $period 
  done
}

function crawler-allocate {
    local site=$1
    local comp=`components $site`

    local path=$crawler_export_dir/fake-data
    local cmd="fallocate -l 1g " $path
    run_command_crawler $cmd
}

function crawler-deallocate {
    local site=$1
    local path=$crawler_export_dir/fake-data
    local cmd="rm $path"
    run_command_crawler $cmd
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
	shift;
	site=$1
	period=$2
	monitor $site $period
	;;
    stop)
	;;
    crawler-allocate)
	;;
    crawler-deallocate)
	;;
    *)
	;;
esac
