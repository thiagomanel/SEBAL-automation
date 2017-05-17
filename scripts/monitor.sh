#!/bin/bash
site=$1
period=$2
crawler_export_dir=$3

disk_usage_monitor_output_file=/home/ubuntu/disk_usage

if [ ! -f $disk_usage_monitor_output_file ]
then
  touch $disk_usage_monitor_output_file
fi

while true
do
  disk_usage=$(df -P $crawler_export_dir | awk 'NR==2 {print $5}')
  date=$(date +"%H:%M:%S-%D")
  echo "Site: $site | Crawler Volume Usage: $disk_usage | Date: $date" >> $disk_usage_monitor_output_file
  sleep $period
done

