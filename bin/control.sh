#!/bin/bash
echo "Starting script."

# Checking params
if [[ $# -ne 1 ]]; then
 echo "Usage:" $0 "start | monitor [site] [period] | stop | crawler-allocate [site] | crawler-deallocate [site]"
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

function scp_to_crawler {
  local source_path=$1
  local destiny_path=$2
  scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $crawler_port -i $private_key_file $source_path $crawler_user_name@$crawler_ip:/$destiny_path
}

function run_command_crawler {
  local remote_command=$1
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_file  $crawler_user_name@$crawler_ip ${remote_command}
}

function monitor {
  site=$1
  period=$2

  scp_to_crawler $local_scripts_path/monitor.sh $remote_scripts_path
  remote_command="sudo sh $remote_scripts_path/monitor.sh $site $period"
  run_command_crawler ${remote_command}
}

function crawler-allocate {
  local site=$1
  local size=$2
  local file=$3
  local comp=`components $site`

  local path=$crawler_export_dir/$file
  local cmd="sudo fallocate -l $size $path"
  run_command_crawler $cmd
}

function crawler-deallocate {
  local site=$1
  local file=$2
  local path=$crawler_export_dir/$file
  local cmd="sudo rm $path"
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
    shift;
    site=$1
    size=$2
    file=$3
    crawler-allocate $site $size $file
    ;;
  crawler-deallocate)
    shift;
    site=$1
    file=$2
    crawler-deallocate $site $file
    ;;
  *)
    ;;
esac
