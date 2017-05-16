#!/bin/bash
echo "Starting script."

DIRNAME=`dirname $0`
source "$DIRNAME/conf/saps.cconf"

# Crawlers Constants
UFSCAR_CRAWLER_VOLUME_DISK=/dev/vdb1
LSD_CRAWLER_VOLUME_DISK=/dev/vdb1

# Scripts Constants
SEBAL_AUTOMATION_CONTROL=bin/control.sh

# Federation Constants
SITE_UFSCAR=manager.naf.ufscar.br
SITE_LSD=experimento.manager.naf.lsd.ufcg.edu.br

# Util Constants
DEFAULT_MONITOR_PERIOD=1h
DEFAULT_SLEEP_TIME=30

# Fake File Constants
UFSCAR_FAKE_FILE_NAME=fake-file
UFSCAR_FAKE_FILE_SIZE=78g
LSD_FAKE_FILE_NAME=fake-file
LSD_FAKE_FILE_SIZE=1g

function scp_to_crawler {
  local source_path=$1
  local destiny_path=$2
  scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $crawler_port -i $private_key_file $source_path $crawler_user_name@$crawler_ip:$destiny_path
}

function run_command_crawler {
  local site=$1
  local remote_command=$2
  
  if [ $site == $SITE_UFSCAR ]
  then
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $ufscar_crawler_port -i $private_key_file  $ufscar_crawler_user_name@$ufscar_crawler_ip ${remote_command}
  else
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $lsd_crawler_port -i $private_key_file  $lsd_crawler_user_name@$lsd_crawler_ip ${remote_command}
  fi
}

bash $SEBAL_AUTOMATION_CONTROL monitor $SITE_UFSCAR $DEFAULT_MONITOR_PERIOD
bash $SEBAL_AUTOMATION_CONTROL crawler-allocate $SITE_UFSCAR $UFSCAR_FAKE_FILE_SIZE $UFSCAR_FAKE_FILE_NAME

crawler_activate_command="cd sebal-engine; bash bin/start-crawler &"
run_command_crawler $SITE_UFSCAR "$crawler_activate_command"

bash $SEBAL_AUTOMATION_CONTROL monitor $SITE_LSD $DEFAULT_MONITOR_PERIOD
run_command_crawler $SITE_LSD "$crawler_activate_command"

count=0
remains_disk=true
while [ "$remains_disk" = true ]
do
  remote_command="df -h $LSD_CRAWLER_VOLUME_DISK --output=used"
  response=$(run_command_crawler $SITE_LSD $remote_command | sed -n 2p)
  used_disk=$(echo "${response//G}")

  if [ $used_disk -lt 79 ]
  then
    bash $SEBAL_AUTOMATION_CONTROL crawler-allocate $SITE_LSD $LSD_FAKE_FILE_SIZE $LSD_FAKE_FILE_NAME"_"$count
    count=$((count + 1))
  else
    remains_disk=false
  fi
  
  sleep $DEFAULT_SLEEP_TIME
done
