#!/bin/bash

# Install common utilities
sudo apt-get update
sudo apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS
sudo apt-get --assume-yes install nfs-kernel-server nfs-common

# Java
sudo apt-get --assume-yes install openjdk-6-jdk maven

# Modify bashrc
cat > ~/.bashrc <<EOM
export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-amd64
export EDITOR=vim
EOM

# Modify ssh config
cat > ~/.ssh/config <<EOM
Host *
    StrictHostKeyChecking no
EOM

env > info.txt

# Download Hadoop
wget http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz
tar -xvzf hadoop-2.6.0.tar.gz

