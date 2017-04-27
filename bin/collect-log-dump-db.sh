#!/bin/bash

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

  sample_dir_path=$outputs_dir_path/
  if [ ! -d $sample_dir_path ]
  then
    mkdir -p $sample_dir_path
  fi

  echo "Dumping database in $sample_dir_path"
  scheduler_db_dump=$sample_dir_path/catalog.dump
  pg_dump -h $scheduler_ip -U $sebal_db_user -f $scheduler_db_dump
}

getDatabaseDump
