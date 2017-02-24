#!/bin/bash

function sebalCleanup {
	# need to set config to vms IP
	# clean catalog database
	pgpass_file="$HOME/.pgpass"
	echo $pgpass_string >> "$pgpass_file"
	chmod 600 "$pgpass_file"

	# SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	# truncate table NASA_IMAGES
	#COMMAND_TRUNCATE_NASA_IMAGES="psql -U $sebal_db_user \"TRUNCATE NASA_IMAGES\" $sebal_db_name"
	#ssh $SSH_OPTIONS -i $private_key_path $scheduler_user_name@$scheduler_ip "$COMMAND_TRUNCATE_NASA_IMAGES"
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE NASA_IMAGES" $sebal_db_name

	# truncate table STATES_TIMESTAMPS
	#COMMAND_TRUNCATE_STATES_TIMESTAMPS="psql -U$sebal_db_user \"TRUNCATE STATES_TIMESTAMPS\" $sebal_db_name"
	#ssh $SSH_OPTIONS -i $private_key_path $scheduler_user_name@$scheduler_ip "$COMMAND_TRUNCATE_STATES_TIMESTAMPS"
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE STATES_TIMESTAMPS" $sebal_db_name
}