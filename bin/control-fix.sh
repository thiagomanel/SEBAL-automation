#!/bin/bash
DIRNAME=`dirname $0`
source "$DIRNAME/saps.conf"

print_menu() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo "Commands are start, monitor, stop, crawler-allocate and crawler-deallocate"
  echo "  start"
  echo "  stop"
  echo "  monitor --site [site] --period [period]"
  echo "  crawler-allocate --site [site]"
  echo "  crawler-deallocate --site [site]"
  exit 1
}

define_parameters() {
  while [ ! -z $1 ]; do
    case $1 in
      --site)
        shift;
	site=$1;
	;;
      --period)
	shift;
        period=$1;
	;;
    esac
    shift
  done
}

function scp_to_crawler {
  local source_path=$1
  local destiny_path=$2
  scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $crawler_port -i $private_key_file $source_path $crawler_user_name@$crawler_ip:$destiny_path
}

function run_command_crawler {
  local remote_command=$1
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_file  $crawler_user_name@$crawler_ip "${remote_command}"
}

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

do_start() {
  for site in `sites $DIRNAME/sebal-sites.conf`
  do
    echo $site
    for component in `components $site`
    do
      start_component $component
    done
  done
}

do_monitor() {
  if [ ! $# -lt 4 ]
  then
    site=$2
    period=$4
		
    scp_to_crawler $local_scripts_path/monitor.sh $remote_scripts_path
    remote_command="sudo sh $remote_scripts_path/monitor.sh $site $period"
    run_command_crawler "${remote_command}"
  else
    print_menu
    exit 1
  fi
}

crawler_allocate() {
  if [ ! $# -lt 6 ]
  then
    site=$2
    size=$4
    file=$6
    comp=`components $site`

    path=$crawler_export_dir/$file
    cmd="sudo fallocate -l $size $path"
    run_command_crawler "$cmd"
  else
    print_menu
    exit 1
  fi
}

crawler_deallocate() {
  if [ ! $# -lt 6 ]
  then
    site=$2
    size=$4
    file=$6
    comp=`components $site`

    path=$crawler_export_dir/$file
    cmd="sudo rm $path"
    run_command_crawler "$cmd"
  else
    print_menu
    exit 1
  fi
}

if [ $# -gt 0 ]
then
    op=$1
    case "$op" in
        start)
            shift
            do_start
        ;;
        monitor)
            shift
            do_monitor $@
        ;;
	stop)
	    shift
	    do_stop
	;;
        crawler-allocate)
            shift
            crawler_allocate $@
        ;;
        crawler-deallocate)
            shift
            crawler-deallocate $@
        ;;
        *)
            print_menu
            exit 1
        ;;
    esac
else
	print_menu
	exit 1
fi
