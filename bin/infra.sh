#!/bin/bash

# This function starts Scheduler component
function start_scheduler {
  run_scheduler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$scheduler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$scheduler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.scheduler.SebalMain /home/$scheduler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $n_workers &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${run_scheduler_cmd}
}

# This function starts Crawler component
function start_crawler {
  run_crawler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$crawler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$crawler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.crawler.CrawlerMain /home/$crawler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_nfs_port $federation_member &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${run_crawler_cmd}
}

# This function starts Fetcher component
function start_fetcher {
  run_fetcher_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$fetcher_debug_port,suspend=n -Dlog4j.configuration=file:/home/$fetcher_user_name/sebal-engine/config/log4j.properties -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.fetcher.FetcherMain /home/$fetcher_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_port &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $fetcher_port -i $private_key_path  $fetcher_user_name@$fetcher_ip ${run_fetcher_cmd}
}

function is_scheduler_up {
  check_running_app_cmd="sudo bash scripts/check-running-app.sh"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Scheduler is not running! Trying to activate it again..."
    activateScheduler
  fi
}

function is_crawler_up {
  check_running_app_cmd="sudo bash scripts/check-running-app.sh"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Crawler is not running! Trying to activate it again..."
    activateCrawler
  fi
}

function is_fetcher_up {
  check_running_app_cmd="sudo bash scripts/check-running-app.sh"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $fetcher_port -i $private_key_path  $fetcher_user_name@$fetcher_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Fetcher is not running! Trying to activate it again..."
    activateFetcher
  fi
}

function run_command_crawler {
  local cmd=$1
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Remote command <" $cmd "> did not work"
  fi
}
