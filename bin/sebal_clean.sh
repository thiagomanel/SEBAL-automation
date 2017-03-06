#!/bin/bash

function sebalCleanup {
	# need to set config to vms IP
	# clean catalog database
	pgpass_file="$HOME/.pgpass"
	echo $pgpass_string >> "$pgpass_file"
	chmod 600 "$pgpass_file"

	# SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	# truncate table NASA_IMAGES
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE NASA_IMAGES" $sebal_db_name

	# truncate table STATES_TIMESTAMPS
	psql -h $scheduler_ip -U $sebal_db_user -c "TRUNCATE STATES_TIMESTAMPS" $sebal_db_name
}