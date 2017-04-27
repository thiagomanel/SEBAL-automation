#!/bin/bash

#DIRNAME=`dirname $0`
#. "$DIRNAME/sebal-automation.conf"

# This function checks if component (Crawler) are responding
function checkCrawlerComponentResponse {
  if ! ping -c 5 $crawler_ip &> /dev/null
  then
    echo "Crawler is down, please establish infrastructure first"
    exit 1
  fi
}

# This function activates Crawler component
function activateCrawler {
  run_crawler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$crawler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$crawler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.crawler.CrawlerMain /home/$crawler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $crawler_ip $crawler_nfs_port $federation_member &"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${run_crawler_cmd}
}

# This function will verify if component (Crawler) are running
function checkIfCrawlerComponentIsRunning {
  check_running_app_cmd="sudo bash scripts/check-running-app.sh"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip ${check_running_app_cmd}
  process_output=$?

  if [ $process_output -ne 0 ]
  then
    echo "Crawler is not running! Trying to activate it again..."
    activateCrawler
  fi
}

# This function verifies the state of a given image
function stateVerifier {
  local image_name=$1

  execution_monitor_cmd="sudo su postgres -c \"echo -e \"$sebal_db_password\n\" | psql -d $sebal_db_name -U $sebal_db_user -c \"SELECT state FROM nasa_images WHERE image_name = '$image_name';\"\""
  state=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${execution_monitor_cmd})
  sed -i '1d' $state
  sed -i '1d' $state
  sed -i '$d' $state
  return $state
}

# This function monitors if images have reached a "fetched" state
function monitorExecution {
  images_count=0

  while true
  do
    for i in $n_images
    do
      for j in $n_samples
      do
        state=`stateVerifier $original_image_name"_"$i"_sample_$j"`
        if [ "$state" == "fetched" ]
        then
          echo "Image $original_image_name"_"$i"_sample_$j" was fetched!"
          images_count=$(($images_count+1))
        fi
        if [ $images_count -ge $(($n_images * $n_samples)) ]
        then
          echo "All images were processed!"
          return 0
        fi
      done
    done
  done
}
