#!/bin/bash

# General system software update
apt-get update

# Install common utilities
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS stuff
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java stuff
apt-get --assume-yes install openjdk-6-jdk maven

# Set some environment variables
cat > /etc/profile <<EOM

export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-amd64
export EDITOR=vim
EOM

# Modify ssh config
cat > /etc/ssh/ssh_config <<EOM
    StrictHostKeyChecking no
EOM
