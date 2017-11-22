#!/bin/bash
# Script for doing user-specific setup. This script is executed by setup.sh as
# the given user.

# Get the absolute path of this script on the system.
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Download hadoop-2.6.0
wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz
tar -xvzf hadoop-2.6.0.tar.gz

# Write hadoop configuration files
cp /local/repository/hadoop.conf/* ./hadoop-2.6.0/etc/hadoop/

# Collect slave names and IPs in the cluster
while read -r ip hostname alias1 alias2 alias3
do 
  if [[ $hostname =~ ^n[0-9]+-clan$ ]] 
  then
    slavenames=("${slavenames[@]}" "$hostname") 
  fi 
done < /etc/hosts
IFS=$'\n' slavenames=($(sort <<<"${slavenames[*]}"))
unset IFS

# Write out slave hostnames into slaves file
for slave in ${slavenames[@]}
do
  echo $slave >> ./hadoop-2.6.0/etc/hadoop/slaves
done

# Download LDBC SNB datagenerator
git clone https://github.com/ldbc/ldbc_snb_datagen.git
cp /local/repository/ldbc_snb_datagen.conf/* ./ldbc_snb_datagen/
