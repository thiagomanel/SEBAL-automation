#!/bin/bash

DIRNAME=`dirname $0`
CURRENT_SAMPLE=$1
. "$DIRNAME/sebal-automation.conf"

# This function makes n_images copies from the same image in images_dir_path
function createImageCopies {
  #TODO: see if i will be present at the end of file names too, and not only in image directory name
  for i in `seq 1 $n_images`
  do
    cp -r $original_image_path $images_dir_path/$original_image_name"_"$i"_$CURRENT_SAMPLE"
  done
}

# This function transfers image input files to Crawler VM
function copyImagesToCrawler {
#TODO note that the destination directory should be empty before running this
  echo "Copying input data to $inputs_dir in Crawler"
  scp -r -i $private_key_path -P $crawler_port $images_dir_path $crawler_user_name@$crawler_ip:$inputs_dir
}

# This function sumits n_samples of n_images to Scheduler database
function submitImagesIntoDB {
  #TODO: maybe we will have a file with image data, so we can get it and use here
  for i in `seq 1 $n_images`
  do
    echo "Submitting image $original_image_name"_"$i"_$CURRENT_SAMPLE" to catalog"
    submit_images_cmd="sudo su postgres -c \"echo -e \"$sebal_db_password\n\" | psql -d $sebal_db_name -U $sebal_db_user -c \"INSERT INTO $sebal_db_table_name VALUES($original_image_name"_"$i"_$CURRENT_SAMPLE", 'downloadLink', 'downloaded', '$federation_member', 0, 'NE', '$sebal_version', '$sebal_tag', '$crawler_version', 'NE', 'NE', now(), now(), 'available', 'no_errors');\"\""
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${submit_images_cmd}
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

createImageCopies
checkProcessOutput
copyImagesToCrawler
checkProcessOutput
submitImagesIntoDB
checkProcessOutput
