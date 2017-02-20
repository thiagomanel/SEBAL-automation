#!/bin/bash
DIRNAME=`dirname $0`
CURRENT_SAMPLE=$1
n_images=$2
source "$DIRNAME/sebal-automation.conf"

# This function get result execution
function getResultExecution {

  for i in $n_images
  do
    image_name=$original_image_name"_"$i"_"$CURRENT_SAMPLE

    if [ ! -d $outputs_dir_path/$image_name ]
    then
      mkdir $outputs_dir_path/$image_name
    fi

    echo "Getting $image_name result files"
    scp -r $crawler_user_name@$crawler_ip:$crawler_outputs_dir/$image_name $outputs_dir_path
  done
}

# This function do a pg_dump of catalog database
function getDatabaseDump {
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

  sample_dir_path=$outputs_dir_path/sample_$CURRENT_SAMPLE
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

getResultExecution
checkProcessOutput
getDatabaseDump
checkProcessOutput
