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
  total_disk=$(df -Th $crawler_export_dir | awk 'NR==2 {print $3}')
  total_disk=$(echo "${total_disk%?}")
  
  input_usage=$(du -sh $crawler_export_dir/images | awk 'NR==1 {print $1}')
  input_usage=${input_usage%?}
  input_usage=$(((input_usage * 100) / $total_disk))

  output_usage=$(du -sh $crawler_export_dir/results | awk 'NR==1 {print $1}')
  output_usage=${output_usage%?}
  output_usage=$(((output_usage * 100) / $total_disk))

  date=$(date +"%H:%M:%S-%D")
  timestamp=$(date +%s)
  echo "Site: $site | Crawler Input Usage: $input_usage% | Crawler Output Usage: $output_usage% | Date: $date | Timestamp: $timestamp" >> $disk_usage_monitor_output_file
  sleep $period
done

