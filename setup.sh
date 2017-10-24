#!/bin/bash

# Do this from User's home folder
cd ~

# Install common utilities
apt-get update
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java
apt-get --assume-yes install openjdk-6-jdk maven
echo "export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-amd64" >> ~/.bashrc

# For git commit messages
echo "export EDITOR=vim" >> ~/.bashrc

cat > ~/.ssh/config <<EOM
Host *
    StrictHostKeyChecking no
EOM

# Download Hadoop
wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz
tar -xvzf hadoop-2.6.0.tar.gz

echo $USER > /home/jde/username.txt
