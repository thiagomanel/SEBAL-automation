#!/bin/bash
DIRNAME=`dirname $0`

FOGBOW_CLI_JAR=""
MANAGER_IP=""
MANAGER_PORT=""
AUTH_TOKEN=""

DEFAULT_CAPACITY_INSTANCES=5
global_monitor_instances=true

function count_instances_of {
	local federation_member=$1
	local path_response_instance="/tmp/response_intance"
	$(java -cp $FOGBOW_CLI_JAR org.fogbowcloud.cli.Main instance --get --url $MANAGER_IP:$MANAGER_PORT --auth-token $AUTH_TOKEN > $path_response_instance)

	local count=$(cat $path_response_instance | grep $federation_member | wc -l)
	$(rm $path_response_instance)
	echo $count
}

function sites {
  cut -d" " -f1 $DIRNAME/sebal-sites.conf | grep -v "#"
}

function monitor_instances {
	echo "Stating monitor instances..."
	local uuid=$(uuidgen)
	while [ $global_monitor_instances ]; do
	    for site in `sites $DIRNAME/sebal-sites.conf`
	    do
	      local count=$(count_instances_of $site)
	      local instances_percent=$((($count * 100) / $DEFAULT_CAPACITY_INSTANCES))
	      local date=$(date)
	      echo "$date - Amount instances of $site : $count of $DEFAULT_CAPACITY_INSTANCES ($instances_percent %)" >> "monitor_instances_$uuid.log"
	    done		
        sleep 10
	done
}

function stop_monitor_instances {
	global_monitor_instances=false
}

monitor_instances