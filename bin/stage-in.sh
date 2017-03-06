#!/bin/bash

# this function rename all files in the path
function renaming {
  path_to_renaming=$1
  echo "Starting to renaming ($path_to_renaming)."  

  tar_file=""

  for f in $path_to_renaming/*
  do       
    file_name=$(basename "$f")
    file_path=$path_to_renaming/$file_name
    echo "Renaming $file_path"

    current_image_file_name=$(echo "$file_name" | sed -r "s/$original_image_name/$current_image_name/g")
    echo "Renaming $file_path to $path_to_renaming/$current_image_file_name"
    if [[ "$file_name" != *README.GTF ]];
    then
      mv $file_path $path_to_renaming/$current_image_file_name
    fi
  done
}

# this funcion rename all file tar.gz
function renaming_tar_gz {
  path_to_renaming_tar_gz=$1

  for f in $path_to_renaming_tar_gz/*
  do       
    file_name=$(basename "$f")
    file_path=$path_to_renaming_tar_gz/$file_name

    if [[ "$file_name" == *tar.gz ]];
    then
      tar_file_name=$file_name
      path_tar=$path_to_renaming_tar_gz/tar
      mkdir $path_tar
    fi

  done  

  echo "Untar $file_name to $path_tar"
  tar -zxvf $file_path -C $path_tar
  renaming $path_tar
  rm $path_to_renaming_tar_gz/$tar_file_name
  echo "tar ($path_to_renaming_tar_gz/$tar_file_name) of ($path_tar)"
  cd $path_tar
  tar -czvf $path_to_renaming_tar_gz/$tar_file_name *
  rm -r $path_tar
  echo "Tar.gz ($path_to_renaming_tar_gz) renamed."
}

# This function makes n_images copies from the same image in images_dir_path
function createImageCopies {
  echo "Creating image copies"
  for current_image_to_create in `seq 1 $n_images`
  do
    current_image_name=$original_image_name"_"$current_image_to_create"_$CURRENT_SAMPLE"
    path_sample=$images_dir_path/$current_image_name
    echo "Executing command: cp -r "$original_image_path $path_sample
    cp -r "$original_image_path" "$path_sample"

    renaming $path_sample
    renaming_tar_gz $path_sample 
  done
}

# This function transfers image input files to Crawler VM
function copyImagesToCrawler {
  SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
  for current_image_to_copy in `seq 1 $n_images`
  do
    image_name="$original_image_name"_"$current_image_to_copy"_$CURRENT_SAMPLE""
    echo "Copying input data to Crawler temporary folder"
    scp -r $SSH_OPTIONS -i $private_key_path -P $crawler_port "$images_dir_path/$image_name" $crawler_user_name@$crawler_ip:/tmp
    
    echo "Moving images to $crawler_inputs_dir"
    ssh $SSH_OPTIONS -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip "sudo mv /tmp/$image_name $crawler_inputs_dir"
  done
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

  for current_image_to_submit in `seq 1 $n_images`
  do
    image_name="$original_image_name"_"$current_image_to_submit"_$CURRENT_SAMPLE""
    echo "Submitting image $image_name to catalog"
    
    psql_cmd=
#    if [[ $CURRENT_SAMPLE -eq 1 || $CURRENT_SAMPLE -eq 2 ]]
    if [[ $CURRENT_SAMPLE -eq 10 || $CURRENT_SAMPLE -eq 20 ]]
    then
      psql_cmd="INSERT INTO $sebal_db_table_name VALUES('$image_name', 'downloadLink', 'downloaded', '$federation_member', 0, 'NE', '$fake_sebal_version', '$fake_sebal_tag', '$crawler_version', 'NE', 'NE', 'NE', now(), now(), 'available', 'no_errors');"
    else
      psql_cmd="INSERT INTO $sebal_db_table_name VALUES('$image_name', 'downloadLink', 'downloaded', '$federation_member', 0, 'NE', '$sebal_version', '$sebal_tag', '$crawler_version', 'NE', 'NE', 'NE', now(), now(), 'available', 'no_errors');"
    fi
    psql -h $scheduler_ip -U $sebal_db_user -c "$psql_cmd" $sebal_db_name
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
