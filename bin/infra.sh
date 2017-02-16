#!/bin/bash

DIRNAME=`dirname $0`
. "$DIRNAME/sebal-automation.conf"

# This function checks if components (Crawler, Scheduler and Fetcher) are responding
function checkComponentsResponse {
#TODO we may extract ping to a function
  if ! ping -c 5 $crawler_ip &> /dev/null
  then
    echo "Crawler is down, please establish infrastructure first"
    exit 1
  fi

  if ! ping -c 5 $scheduler_ip &> /dev/null
  then
    echo "Scheduler is down, please establish infrastructure first"
    exit 1
  fi

  if ! ping -c 5 $fetcher_ip &> /dev/null
  then
    echo "Fetcher is down, please establish infrastructure first"
    exit 1
  fi
}

# This function activates Scheduler component
function runScheduler {
  run_scheduler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$scheduler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$scheduler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.scheduler.SebalMain /home/$scheduler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $n_workers &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${run_scheduler_cmd}
}

# This function activates Crawler component
function runCrawler {
  run_crawler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$crawler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$crawler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.crawler.CrawlerMain /home/$crawler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_nfs_port $federation_member &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${run_crawler_cmd}
}

# This function activates Fetcher component
function runFetcher {
  run_fetcher_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$fetcher_debug_port,suspend=n -Dlog4j.configuration=file:/home/$fetcher_user_name/sebal-engine/config/log4j.properties -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.fetcher.FetcherMain /home/$fetcher_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_port &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $fetcher_port -i $private_key_path  $fetcher_user_name@$fetcher_ip ${run_fetcher_cmd}
}

# This function will verify if all components (Scheduler, Crawler and Fetcher) are running
function checkIfComponentsAreRunning {
  check_running_app_cmd="sudo bash scripts/check-running-app.sh"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Scheduler is not running! Trying to activate it again..."
    activateScheduler
  fi

  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Crawler is not running! Trying to activate it again..."
    activateCrawler
  fi

  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $fetcher_port -i $private_key_path  $fetcher_user_name@$fetcher_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Fetcher is not running! Trying to activate it again..."
    activateFetcher
  fi
}
