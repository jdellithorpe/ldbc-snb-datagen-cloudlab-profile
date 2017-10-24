#!/bin/bash
USERNAME="jde"
HOME="/users/$USERNAME"

# Install common utilities
apt-get update
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java
apt-get --assume-yes install openjdk-6-jdk maven

# Modify bashrc
cat > $HOME/.bashrc <<EOM
export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-amd64
export EDITOR=vim
EOM

# Modify ssh config
cat > $HOME/.ssh/config <<EOM
Host *
    StrictHostKeyChecking no
EOM

while read -r ip linkin linkout hostname
do 
  if [ "$ip" != "127.0.0.1" ]
  then
    ssh -o StrictHostKeyChecking=no -n root@$ip "cat .ssh/authorized_keys >> $HOME/.ssh/authorized_keys; cp .ssh/id_rsa $HOME/.ssh/id_rsa; chown $USERNAME:ramcloud-PG0 $HOME/.ssh/id_rsa"
  fi
done < /etc/hosts

# Download Hadoop
cd $HOME
wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz
chown $USERNAME:ramcloud-PG0 hadoop-2.6.0.tar.gz
tar -xvzf hadoop-2.6.0.tar.gz
chown -R $USERNAME:ramcloud-PG0 hadoop-2.6.0
