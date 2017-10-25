#!/bin/bash

# General system software update
apt-get update

# Install common utilities
apt-get --assume-yes install mosh vim tmux pdsh tree axel

# NFS stuff
apt-get --assume-yes install nfs-kernel-server nfs-common

# Java stuff
apt-get --assume-yes install openjdk-6-jdk maven

