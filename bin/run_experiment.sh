#!/bin/bash

# Checking params
if [[ $# -ne 3 ]]; then
 echo "Usage:" $0 "number_of_samples number_of_images number_of_workers"
 exit 1
fi

# Entry params
n_samples=$1
n_images=$2
n_workers=$3

DIRNAME=`dirname $0`
source "$DIRNAME/sebal-automation.conf"
source "$DIRNAME/infra.sh"
source "$DIRNAME/collect-log-dump-db.sh"
source "$DIRNAME/sebal_clean.sh"
source "$DIRNAME/stage-in.sh"

checkParams

# run scheduler_port
# run crawler

for i in $n_samples ; do
   echo item: $i
   # clean
   sebalCleanup
   # stage in
   doStageIn
   # monitorExecution
   ## getData
   monitorExecution
   # finish
   
done


# This function checks parameters consistency
function checkParams {
 if [ $n_samples -le 0 ]
 then
   echo $n_samples "is not a valid number of samples"
   exit 1
 fi

 if [ $n_images -le 0 ]
 then
   echo $n_images "is not a valid number of samples"
   exit 1
 fi

 if [ $n_workers -le 0 ]
 then
   echo $n_workers "is not a valid number of samples"
   exit 1
 fi
}

# This function verifies the state of a given image
function stateVerifier {
 local image_name=$1

 execution_monitor_cmd="sudo su postgres -c \"echo -e \"$sebal_db_password\n\" | psql -d $sebal_db_name -U $sebal_db_user -c \"SELECT state FROM nasa_images WHERE image_name = '$image_name';\"\""
 state=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port -i $private_key_path  $scheduler_user_name@$scheduler_ip ${execution_monitor_cmd})
 sed -i '1d' $state
 sed -i '1d' $state
 sed -i '$d' $state
 return $state
}

# This function monitors if images have reached a "fetched" state
function monitorExecution {
 images_count=0

 # !isDone 
 statusCondition=false
 while true
   #getData
   ## function defined in get_result_data.sh
   getResultExecution
   # sleep ?
 done
}