#!/bin/bash

#DIRNAME=`dirname $0`
#. "$DIRNAME/sebal-automation.conf"

# This function starts Crawler component
function start_crawler {
  run_crawler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$crawler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$crawler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.crawler.CrawlerMain /home/$crawler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_nfs_port $federation_member &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${run_crawler_cmd}
}

# This function will verify if component (Crawler) are running
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
