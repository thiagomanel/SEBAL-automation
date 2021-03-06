#!/bin/bash

# Checking params
if [[ $# -ne 3 ]]; then
  echo "Usage:" $0 "number_of_samples number_of_images number_of_workers"
  exit 1
fi

# Entry params
n_samples=$1
n_images=$2
n_workers=$3

DIRNAME=`dirname $0`
. "$DIRNAME/sebal-automation.conf"

# This function checks parameters consistency
function checkParamsConsistency {
  if [ $n_samples -le 0 ]
  then
    echo $n_samples "is not a valid number of samples"
    exit 1
  fi

  if [ $n_images -le 0 ]
  then
    echo $n_images "is not a valid number of samples"
    exit 1
  fi

  if [ $n_workers -le 0 ]
  then
    echo $n_workers "is not a valid number of samples"
    exit 1
  fi
}

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

# This function makes n_images copies from the same image in images_dir_path
function createImageCopies {
  #TODO: see if i will be present at the end of file names too, and not only in image directory name
  for i in $n_images
  do
    for j in $n_samples
    do
      cp -r $original_image_path $images_dir_path/$original_image_name"_"$i"_sample_$j"
    done
  done
}

# This function transfers image input files to Crawler VM
function copyImagesToCrawler {
  echo "Copying input data to $inputs_dir in Crawler"
  scp -r -i $private_key_path -P $crawler_port $images_dir_path $crawler_user_name@$crawler_ip:$inputs_dir
}

# This function sumits n_samples of n_images to Scheduler database
function submitImagesIntoDB {
  #TODO: maybe we will have a file with image data, so we can get it and use here
  for i in $n_images
  do
    for j in $n_samples
    do
      #TODO: priority will follow j?
      submit_images_cmd="sudo su postgres -c \"echo -e \"$sebal_db_password\n\" | psql -d $sebal_db_name -U $sebal_db_user -c \"INSERT INTO $sebal_db_table_name VALUES($original_image_name"_"$i"_sample_$j", 'downloadLink', 'downloaded', '$federation_member', priority, 'stationId', 'sebal_version', 'sebal_tag', 'crawler_version', 'fetcher_version', 'blowout_version', now(), now(), 'image_status', 'error_msg');\"\""
      ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${submit_images_cmd}
    done
  done
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

# This function gathers all output data
function gatherOutputData {
  swift_auth_token=$(bash $fogbow_cli_path/bin/fogbow-cli token --create -DprojectId=$project_id -DuserId=$user_id -Dpassword=$password -DauthUrl=$auth_url --type $token_type)

  for i in $n_images
  do
    for j in $n_samples
    do
      downloadFile $i $j
    done
  done
}

# This function lists all files from a given image in swift and download them 
function downloadFile {
  local i=$1
  local j=$2
  
  before_image_file_path=
  for complete_image_file_path in `swift --os-auth-token $swift_auth_token --os-storage-url $swift_storage_url list $swift_container_name | grep -o $original_image_name"_"$i"_sample_$j"`
  do
    if [ "$complete_image_file_path" != "$before_image_file_path" ]
    then
      echo "Downloading file $complete_image_file_path"
      filename=${complete_image_file_path##*/}
      swift --os-auth-token $swift_auth_token --os-storage-url $swift_storage_url download $swift_container_name $swift_pseudo_folder/$complete_image_file_path -o $outputs_dir_path/$filename
      before_image_file_path="$complete_image_file_path"
    fi
  done
}

checkParamsConsistency
checkCrawlerComponentResponse
activateCrawler
checkIfCrawlerComponentIsRunning