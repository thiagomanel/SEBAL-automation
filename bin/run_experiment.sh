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
source "$DIRNAME/../scripts/collect-image-status"

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
   if [ "$IMAGES_STATUS" = "Done" ]; then
      collectLogDumpDB $CURRENT_SAMPLE $n_images
   elif [ "$IMAGES_STATUS" != "Idle" && "$IMAGES_STATUS" != "Running" ]; then
      break
   fi
   # sleep ?
 done
}

checkParams

# run scheduler_port
# run crawler

for i in $(seq 1 $n_samples); do
   echo item: $i
   # clean
   sebalCleanup
   # stage in
   doStageIn $i $n_images
   # monitorExecution
   ## getData
   monitorExecution $i
   # finish

done