#!/bin/bash

# Checking params
if [[ $# -ne 3 ]]; then
 echo "Usage:" $0 "number_of_samples number_of_images number_of_workers"
 exit 1
fi

# Entry params
n_samples=`expr 2 + $1`
n_images=$2
n_workers=$3

DIRNAME=`dirname $0`
source "$DIRNAME/sebal-automation.conf"
source "$DIRNAME/infra.sh"
source "$DIRNAME/collect-log-dump-db.sh"
source "$DIRNAME/sebal_clean.sh"
source "$DIRNAME/stage-in.sh"
source "$DIRNAME/../scripts/collect-image-status"

EXECUTION_UUID=`uuidgen`

echo "Preparing execution ID: $EXECUTION_UUID"
execution_samples_makespan_file="$outputs_dir_path/execution_"$EXECUTION_UUID".txt"

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

# This function monitors if images have reached a "fetched" state
function monitorExecution {
 CURRENT_SAMPLE=$1

 # !isDone 

 while true; do
   #getData
   IMAGES_STATUS=$(getImagesStatus)
   echo "IMAGES_STATUS = $IMAGES_STATUS"
   if [[ "$IMAGES_STATUS" = "Done" ]]; then
      MAKESPAN=$(calculateMakespan)
      echo "Sample: $CURRENT_SAMPLE - Execution time in seconds: $MAKESPAN" >> $execution_samples_makespan_file
      collectLogDumpDB $CURRENT_SAMPLE $n_images
      break
   elif [ "$IMAGES_STATUS" != "Idle" ] && [ "$IMAGES_STATUS" != "Running" ]; then
      echo "Breaking now!"
      break
   fi
   # sleep ?
   sleep 5
 done
}

checkParams

# run scheduler_port
# run crawler
for each_sample in `seq 1 $n_samples`; do
   echo item: $each_sample
   # clean
   echo "Starting clean sample $each_sample and n_images = $n_images"
   sebalCleanup
   # stage in
   echo "Starting stagein sample $each_sample and n_images = $n_images"
   doStageIn $each_sample $n_images
   # monitorExecution
   ## getData
   echo "Starting monitoring sample $each_sample and n_images = $n_images"
   monitorExecution $each_sample
   # finish
done