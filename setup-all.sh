#!/bin/bash

# General system software update
apt-get update

# Install common utilities
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS stuff
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java stuff
apt-get --assume-yes install openjdk-7-jdk maven

# Collect slave names and IPs in the cluster
while read -r ip linkin linkout hostname
do 
  if [[ $hostname =~ ^n[0-9]+$ ]] 
  then
    slavenames=("${slavenames[@]}" "$hostname") 
    slaveips=("${ips[@]}" "$ip") 
  fi 
done < /etc/hosts

IFS=$'\n' slavenames=($(sort <<<"${slavenames[*]}"))
IFS=$'\n' slaveips=($(sort <<<"${slaveips[*]}"))
unset IFS

# Set some environment variables
cat > /etc/profile <<EOM

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
export EDITOR=vim
export SLAVEIPS="${slaveips[@]}"
export SLAVENAMES="${slavenames[@]}"
export HOSTNAMES="master ${slavenames[@]}"
EOM

# Modify ssh config
cat > /etc/ssh/ssh_config <<EOM
    StrictHostKeyChecking no
EOM

# Copy root key 
for user in $(ls /users/)
do 
  cat ~/.ssh/authorized_keys >> /users/$user/.ssh/authorized_keys
  cp ~/.ssh/id_rsa /users/$user/.ssh/
  chown $user:ramcloud-PG0 /users/$user/.ssh/id_rsa
done

# Download hadoop-2.6.0 to /opt
wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz -O /opt/hadoop-2.6.0.tar.gz
tar -C /opt -xzf /opt/hadoop-2.6.0.tar.gz
chown -R root:root /opt/hadoop-2.6.0
chmod -R g=u /opt/hadoop-2.6.0

# Write hadoop configuration files
cp /local/repository/hadoop.conf/* /opt/hadoop-2.6.0/etc/hadoop/

# Write out slave hostnames into slaves file
for slave in ${slavenames[@]}
do
  echo $slave >> /opt/hadoop-2.6.0/etc/hadoop/slaves
done

# Make the hadoop data directory writable by users
chmod g=u /local/hadoop
