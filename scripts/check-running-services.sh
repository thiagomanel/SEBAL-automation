#!/bin/bash

#Souce config file
. "../bin/sebal-automation.conf"

#Commands to filter process of crawler and scheduler 
check_running_crawler="pgrep -f crawler"
check_running_scheduler="pgrep -f scheduler"

#SSH access and execution of commands 
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $crawler_user_name@$crawler_ip ${check_running_crawler} > /dev/null
crawler_output=$?

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $scheduler_user_name@$scheduler_ip ${check_running_scheduler} > /dev/null
scheduler_output=$?

#Conditions to print the state of each one of the two services
if [  $crawler_output == 1 ]
then
    echo "Crawler is down... try to restart it."
elif [  $crawler_output == 0 ]
then
    echo "Crawler is running."
fi

if [ $scheduler_output == 1 ]
then 
    echo "Scheduler is down... try to restart it."
elif [ $scheduler_output == 0 ]
then
    echo "Scheduler is running."
fi
