#!/bin/bash

function sebalCleanup {
	# need to set config to vms IP
	# clean catalog database
	echo $pgpass_string >> "$HOME/.pgpass"
	SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	# truncate table NASA_IMAGES
	COMMAND_TRUNCATE_NASA_IMAGES="psql -U$sebal_db_user \"TRUNCATE NASA_IMAGES\" $sebal_db_name"
	ssh $SSH_OPTIONS -c "$COMMAND_TRUNCATE_NASA_IMAGES" -i $private_key_path azureuser@$scheduler_ip

	# truncate table STATES_TIMESTAMPS
	COMMAND_TRUNCATE_STATES_TIMESTAMPS="psql -U$sebal_db_user \"TRUNCATE STATES_TIMESTAMPS\" $sebal_db_name"
	ssh $SSH_OPTIONS -c "$COMMAND_TRUNCATE_STATES_TIMESTAMPS" -i $private_key_path azureuser@$scheduler_ip
}