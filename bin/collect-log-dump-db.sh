#!/bin/bash

# This function get result execution
function getResultExecution {
  EXECUTION_UUID=$1

  for i in $n_images
  do
    image_name=$(echo | getImageName $i $CURRENT_SAMPLE)

    if [ ! -d $outputs_dir_path/$image_name ]
    then
      mkdir $outputs_dir_path/$image_name
    fi

    echo "Getting $image_name result files"
    path_output_logs=$outputs_dir_path/$EXECUTION_UUID"_"$image_name"_sample_"$CURRENT_SAMPLE
    mkdir $path_output_logs
    scp -r $crawler_user_name@$crawler_ip:$crawler_outputs_dir/$image_name"/temp-worker*" $path_output_logs
    echo "Finished $image_name result files"
  done
}

# This function do a pg_dump of catalog database
function getDatabaseDump {
  EXECUTION_UUID=$1

  # Setting password to access db
  file="$HOME/.pgpass"
  if [ -f "$file" ]
  then
    echo "Replacing $file now."
    rm -f $file
  else
    echo "$file not found. Creating one now"
  fi

  # Writing password in .pgpass and changing permissions
  echo "$scheduler_ip:$scheduler_db_port:$sebal_db_name:$sebal_db_user:$sebal_db_password" >> $file
  chmod 0600 "$file"

  sample_dir_path=$outputs_dir_path/$EXECUTION_UUID"_"$image_name"_sample_"$CURRENT_SAMPLE
  if [ ! -d $sample_dir_path ]
  then
    mkdir -p $sample_dir_path
  fi

  echo "Dumping database in $sample_dir_path"
  scheduler_db_dump=$sample_dir_path/catalog.dump
  pg_dump -h $scheduler_ip -U $sebal_db_user -f $scheduler_db_dump
}

# This function checks if previous process executed successfully
function checkProcessOutput {
  PROCESS_OUTPUT=$?

  if [ $PROCESS_OUTPUT -ne 0 ]
  then
    exit $PROCESS_OUTPUT
  fi
}

function collectLogDumpDB {
  CURRENT_SAMPLE=$1
  n_images=$2
  EXECUTION_UUID=$3
  getResultExecution $EXECUTION_UUID
  checkProcessOutput
  getDatabaseDump $EXECUTION_UUID
  checkProcessOutput
}
