#!/bin/bash
# Crawler
# Installing dependencies
apt-get update
apt-get install nfs-kernel-server
apt-get install git
apt-get install maven

# Configuring NFS Server
mkdir -p /local/exports
echo "/local/exports *(rw,insecure,no_subtree_check,async,no_root_squash)" >> /etc/exports
service nfs-kernel-server restart

# Prepare Logs directory
mkdir -p /var/log/sebal-execution
touch /var/log/sebal-execution/sebal-execution.log
chmod 777 /var/log/sebal-execution/sebal-execution.log

# Azure always mount its disk in /mnt, what whe need is to change mounted directory from /mnt to /local/exports
umount /mnt
mount <disk-name> /local/exports

DIRNAME=`dirname $0`
# Change VM timezone
sh "$DIRNAME/change_timezone.sh"

# Prepare NTP Client
sh "$DIRNAME/prepare_ntp_client.sh"

# We need to put Fetcher public key into /home/azureuser/.ssh/authorized_keys
echo "$fetcher_key" >> /home/azureuser/.ssh/authorized_keys

# We need to put some Fmask environment variables into /root/.profile and /root/.bashrc, these variables are:
LD_LIBRARY_PATH=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/bin/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64

XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/X11/app-defaults