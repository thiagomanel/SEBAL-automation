#!/bin/bash

#Souce config file
. "../bin/sebal-automation.conf"

#Geting info about db
ip=$scheduler_ip
port=$scheduler_port
db_name=$sebal_db_name
db_username=$sebal_db_user
db_password=$sebal_db_password

# Setting password to access db 
file="$HOME/.pgpass"
if [ -f "$file" ]
then
	echo "Replacing $file now."
	rm -f $file

else
	echo "$file not found. Creating one now"

fi

#Writing password in .pgpass and changing permissions
echo "$ip:$port:$db_name:$db_username:$db_password" >> $file
chmod 0600 "$HOME/.pgpass"


# Generating CSV files for result of the queries 
psql -h $ip -U$db_username -c "COPY (SELECT image_name, state, utime, federation_member FROM nasa_images WHERE state = 'queued') TO STDOUT WITH CSV" sebal >> queued.csv
psql -h $ip -U$db_username -c "COPY (SELECT image_name, state, utime, federation_member FROM nasa_images WHERE state = 'finished') TO STDOUT WITH CSV" sebal >> finished.csv
psql -h $ip -U$db_username -c "COPY (SELECT image_name, state, utime, federation_member FROM nasa_images WHERE state = 'running') TO STDOUT WITH CSV" sebal >> running.csv


#Variables that are going to be checked after query in the database
running=$(cat running.csv | xargs -l echo | wc -l)
finished=$(cat finished.csv | xargs -l echo | wc -l)
queued=$(cat queued.csv | xargs -l echo | wc -l) 


#Condition to give status of the images
if [[ $running > 0 || $queued > 0 ]]
then 
    echo "Running"
elif [ $finished > 0]
then
    echo "Done"
else 
    echo "Idle"            
fi


#Erasing files that are not required anymore
rm running.csv
rm finished.csv
rm queued.csv
