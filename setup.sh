#!/bin/bash

# Install common utilities
apt-get update
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java
apt-get install openjdk-6-jdk
export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-amd64

# For git commit messages
export EDITOR=vim
