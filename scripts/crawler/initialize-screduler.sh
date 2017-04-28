#!/bin/bash

# TODO change to real settings.conf
DIRNAME=`dirname $0`
source "$DIRNAME/settings.conf"

SEBAL_ENGINE_PROJET_NAME="sebal-engine"
FOGBOW_MANAGER_PROJET_NAME="fogbow-manager"
BLOWOUT_PROJET_NAME="blowout"

SEBAL_CONF_FILE="sebal.conf.txt"
FMASK_VARIABLES_FILE="fmask-variables.txt"
DEFAULT_SSH_COMMAND_PREFIX="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $SETTINGS_CRAWLER_PORT -i $SETTINGS_PRIVATE_KEY  $SETTINGS_USERNAME_CRAWLER@$SETTINGS_CRAWLER_IP"

function show_cmd_response {
	local cmd=$1
	local response=$2	

	echo "Command : $cmd | Response: $response"
}

# TODO 
function mount_particion() {
	echo "--------Start mount---------"
	local to_format=$1	
	local dirname="/local/exports"
	# TODO investigate if will be used only in openstack ?
	local default_paticion_name="/dev/vdb"
	echo "Mounting paticion($default_paticion_name) in $dirname"

	local cmd="sudo mkdir -p $dirname"
	local response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	if [ "$to_format" = true ]; then
		echo "Formating $default_paticion_name ..."		
		cmd="sudo mkfs.ext4 $default_paticion_name"
		response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
		show_cmd_response "$cmd" "$response"
	fi

	cmd="sudo mount $default_paticion_name $dirname"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check

	echo "--------End mount---------"
}

function install_dependecies() {
	echo "--------Start install dependecies---------"
	local cmd="sudo apt-get install git"
	local response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	cmd="sudo apt-get install openjdk-7-jdk"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"	

	cmd="sudo apt-get install maven"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check

	echo "--------End install dependecies---------"
}

function put_fetch_key() {
	echo "--------Start fetch key---------"

	# TODO check if there is the key in the authorizedd

	local authorized_keys_path="/home/$SETTINGS_USERNAME_CRAWLER/.ssh/authorized_keys"
	local public_key_fetch=$(cat $SETTINGS_PUBLIC_KEY_FETCH_FILE)
	local cmd="echo $public_key_fetch >> $authorized_keys_path"
	local response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check 

	echo "--------End fetch key---------"
}

function set_fmask_variables() {
	echo "--------Start set fmask variables---------"

	local path_profile="/root/.profile"
	local path_bashrc="/root/.bashrc"

	local fmask_variables_line_one=$(cat $DIRNAME/$FMASK_VARIABLES_FILE | head -1 | tail -1)
	local fmask_variables_line_two=$(cat $DIRNAME/$FMASK_VARIABLES_FILE | head -2 | tail -1)
	local cmd="sudo sh -c \"echo $fmask_variables_line_one >> $path_profile\" && sudo sh -c \"echo $fmask_variables_line_two >> $path_profile\""
	local response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check 

	echo "--------End set fmask variables---------"
}

function install_sebal_engine() {
	echo "--------Start install sebal engine---------"

	local home_path="/home/$SETTINGS_USERNAME_CRAWLER/"

	# git clone sebal engine
	local cmd="git clone $SETTINGS_SEBAL_ENGINE_URL $home_path$SEBAL_ENGINE_PROJET_NAME"
	local response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# checkout
	cmd="cd $home_path$SEBAL_ENGINE_PROJET_NAME && git checkout $SETTINGS_DEFAULT_SEBAL_ENGINE_TAG"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# git clone manager
	cmd="git clone $SETTINGS_FOGBOW_MANAGER_URL $home_path$FOGBOW_MANAGER_PROJET_NAME"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# git clone blowout
	cmd="git clone $SETTINGS_BLOWOUT_URL $home_path$BLOWOUT_PROJET_NAME"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# checkout
	cmd="cd $home_path$BLOWOUT_PROJET_NAME && git checkout $SETTINGS_DEFAULT_BLOWOUT_TAG"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# mvn install manager
	cmd="cd $home_path$FOGBOW_MANAGER_PROJET_NAME && mvn install -Dmaven.test.skip=true"
	response=`$DEFAULT_SSH_COMMAND_PREFIX ${cmd}`
	show_cmd_response "$cmd" "$response"

	# mvn install blowout
	cmd="cd $home_path$BLOWOUT_PROJET_NAME && mvn install -Dmaven.test.skip=true"
	response=`$DEFAULT_SSH_COMMAND_PREFIX ${cmd}`
	show_cmd_response "$cmd" "$response"

	# mvn install sebal engine
	cmd="cd $home_path$SEBAL_ENGINE_PROJET_NAME && mvn install -Dmaven.test.skip=true"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	local sebal_conf=$(cat $DIRNAME/$SEBAL_CONF_FILE)	
	local path_sebal_conf="$home_path$SEBAL_ENGINE_PROJET_NAME/$config/sebal.conf"
	cmd="echo $sebal_conf > $path_sebal_conf"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check 

	echo "--------End install sebal engine---------"
}

function start_crawler() {
	echo "--------Start start crawler---------"

	local path_sebal_engine="/home/$SETTINGS_USERNAME_CRAWLER/$SEBAL_ENGINE_PROJET_NAME"

	local cmd="cd $path_sebal_engine && sudo java -Dlog4j.configuration=file:$path_sebal_engine/config/log4j.properties -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.sebal.crawler.CrawlerMain $path_sebal_engine/config/sebal.conf $SETTINGS_SCHEDULER_DB_IP $SETTINGS_SCHEDULER_DB_PORT $SETTINGS_CRAWLER_IP $SETTINGS_CRAWLER_NFS_PORT $SETTINGS_FEDERATION_MEMBER_TO_CRAWLER &"
	response=$($DEFAULT_SSH_COMMAND_PREFIX ${cmd})
	show_cmd_response "$cmd" "$response"

	# TODO check 

	echo "--------End start crawler---------"
}

function main() {
	echo " ############# Start crawler implantation #############"

	if [ "$SETTINGS_ONLY_START_CRAWLER" = true ] 
		then
			mount_particion true
			install_dependecies
			put_fetch_key
			set_fmask_variables
			install_sebal_engine
	fi
	start_crawler

	echo " ############# End crawler implantation #############"
}

main