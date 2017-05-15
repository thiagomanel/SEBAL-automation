#!/bin/bash
echo "Starting script."

DIRNAME=`dirname $0`
source "$DIRNAME/saps.cconf"

function scp_to_crawler {
  local source_path=$1
  local destiny_path=$2
  scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $crawler_port -i $private_key_file $source_path $crawler_user_name@$crawler_ip:/$destiny_path
}

function run_command_crawler {
  local remote_command=$1
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_file  $crawler_user_name@$crawler_ip ${remote_command}
}

bash bin/control.sh


