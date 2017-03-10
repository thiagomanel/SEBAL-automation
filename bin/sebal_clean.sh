#!/bin/bash

function sebalCleanup {
	# need to set config to vms IP
	# clean catalog database
	pgpass_file="$HOME/.pgpass"
	echo $pgpass_string >> "$pgpass_file"
	chmod 600 "$pgpass_file"

	# truncate table NASA_IMAGES
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE NASA_IMAGES" $sebal_db_name

	# truncate table STATES_TIMESTAMPS
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE STATES_TIMESTAMPS" $sebal_db_name
}

function clearOlderLogs {
	SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	for current_image_to_copy in `seq 1 $n_images`
  	do
	    image_name=$(echo | getImageName $current_image_to_copy)
	    
	    echo "Cleaning older datas in the image($image_name) to the crawler in path : $crawler_inputs_dir ."
	    ssh $SSH_OPTIONS -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip "sudo rm "$crawler_outputs_dir/$image_name"/temp-worker*"
	    ssh $SSH_OPTIONS -p $crawler_port -i $private_key_path  $crawler_user_name@$crawler_ip "sudo rm "$crawler_outputs_dir/$image_name"/*"
  	done
}