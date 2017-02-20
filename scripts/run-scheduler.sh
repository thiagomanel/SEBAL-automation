#!/bin/bash

function runScheduler{
	
    n_workers=$1
    run_scheduler_cmd="sudo java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$scheduler_debug_port,suspend=n -Dlog4j.configuration=file:/home/$scheduler_user_name/sebal-engine/config/log4j.properties -Djava.library.path=/usr/local/lib/ -cp target/sebal-scheduler-0.0.1-SNAPSHOT.jar:target/lib/* org.fogbowcloud.sebal.engine.scheduler.SebalMain /home/$scheduler_user_name/sebal-engine/config/sebal.conf $scheduler_ip $scheduler_db_port $n_workers &"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $scheduler_port  $scheduler_user_name@$scheduler_ip ${run_scheduler_cmd}

}
