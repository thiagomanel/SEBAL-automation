#!/bin/bash

# This function makes n_images copies from the same image in images_dir_path
function createImageCopies {
  echo "Creating image copies"
  for i in `seq 1 $n_images`
  do
    echo "Executing command: sudo cp -r "$original_image_path $images_dir_path"/"$original_image_name"_"$i"_"$CURRENT_SAMPLE
    sudo cp -r $original_image_path $images_dir_path/$original_image_name"_"$i"_$CURRENT_SAMPLE"
  done
}

# This function transfers image input files to Crawler VM
function copyImagesToCrawler {
  SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
  echo "Copying input data to Crawler temporary folder"
  sudo scp -r $SSH_OPTIONS -i $private_key_path -P $crawler_port $images_dir_path/* $crawler_user_name@$crawler_ip:/tmp
  
  echo "Moving images to $crawler_inputs_dir"
  move_files_cmd="sudo mv /tmp/$original_image_name* $crawler_inputs_dir"
  ssh -v $SSH_OPTIONS -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip "sudo mv /tmp/$original_image_name* $crawler_inputs_dir"
}

# This function submits n_images from CURRENT_SAMPLE to Scheduler database
function submitImagesIntoDB {
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

  for i in `seq 1 $n_images`
  do
    image_name="$original_image_name"_"$i"_$CURRENT_SAMPLE""
    echo "Submitting image $image_name to catalog"
    psql_cmd="INSERT INTO $sebal_db_table_name VALUES('$image_name', 'downloadLink', 'downloaded', '$federation_member', 0, 'NE', '$sebal_version', '$sebal_tag', '$crawler_version', 'NE', 'NE', 'NE', now(), now(), 'available', 'no_errors');"
    psql -h $scheduler_ip -U $sebal_db_user -c "$psql_cmd"
  done
}

# This function checks if previous process executed successfully
function checkProcessOutput {
  PROCESS_OUTPUT=$?

  if [ $PROCESS_OUTPUT -ne 0 ]
  then
    exit $PROCESS_OUTPUT
  fi
}

function doStageIn {
  CURRENT_SAMPLE=$1
  n_images=$2
  createImageCopies
  checkProcessOutput
  copyImagesToCrawler
  checkProcessOutput
  submitImagesIntoDB
  checkProcessOutput
}
