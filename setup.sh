#!/bin/bash
# Script for setting up the cluster after initial booting and configuration by
# CloudLab.

# Get the absolute path of this script on the system.
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# === Parameters decided by profile.py ===
# Place where a local blockstore has been mounted on each server.
LOCAL_BLOCKSTORE_MOUNT_POINT=$1
# Place where CloudLab datasets will be mounted (on NFS server only).
REMOTE_BLOCKSTORE_MOUNT_POINT=$2
# Directory for NFS shared user home directories.
NFS_SHARED_HOME_DIR=$3
# Directory for NFS shared datasets.
NFS_SHARED_DATASETS_DIR=$4
# Account in which various software should be setup.
USERNAME=$5

# General system software update
apt-get update
# Install common utilities
apt-get --assume-yes install mosh vim tmux pdsh tree axel htop ctags 
# NFS stuff
apt-get --assume-yes install nfs-kernel-server nfs-common
# Java stuff
apt-get --assume-yes install openjdk-7-jdk maven

# Configure some environment variables and settings for all users on all
# machines.
cat >> /etc/profile.d/etc.sh <<EOM
export EDITOR=vim
EOM
chmod ugo+x /etc/profile.d/etc.sh

# Modify ssh config
cat >> /etc/ssh/ssh_config <<EOM
    StrictHostKeyChecking no
EOM

# If this server is the NFS server, export the local disk partition and any
# mounted remote datasets over NFS.
if [ $(hostname --short) == "nfs" ]
then
  # Make the file system rwx by all.
  chmod 777 $LOCAL_BLOCKSTORE_MOUNT_POINT
  chmod 777 $REMOTE_BLOCKSTORE_MOUNT_POINT

  # Make the NFS exported file system readable and writeable by all hosts in
  # the system (/etc/exports is the access control list for NFS exported file
  # systems, see exports(5) for more information).
	echo "$LOCAL_BLOCKSTORE_MOUNT_POINT *(rw,sync,no_root_squash)" >> /etc/exports
	echo "$REMOTE_BLOCKSTORE_MOUNT_POINT *(rw,sync,no_root_squash)" >> /etc/exports
  for dataset in $(ls $REMOTE_BLOCKSTORE_MOUNT_POINT)
  do
    echo "$REMOTE_BLOCKSTORE_MOUNT_POINT/$dataset *(rw,sync,no_root_squash)" >> /etc/exports
  done

  # Start the NFS service.
  /etc/init.d/nfs-kernel-server start

  # Give it a second to start-up
  sleep 5

  > /local/setup-nfs-done
fi

# Wait until nfs is properly set up. 
while [ "$(ssh nfs "[ -f /local/setup-nfs-done ] && echo 1 || echo 0")" != "1" ]; do
    sleep 1
done

# NFS clients setup
nfs_clan_ip=`grep "nfs-clan" /etc/hosts | cut -d$'\t' -f1`
my_clan_ip=`grep "$(hostname --short)-clan" /etc/hosts | cut -d$'\t' -f1`
mkdir $NFS_SHARED_HOME_DIR; mount -t nfs4 $nfs_clan_ip:$LOCAL_BLOCKSTORE_MOUNT_POINT $NFS_SHARED_HOME_DIR
echo "$nfs_clan_ip:$LOCAL_BLOCKSTORE_MOUNT_POINT $NFS_SHARED_HOME_DIR nfs4 rw,sync,hard,intr,addr=$my_clan_ip 0 0" >> /etc/fstab

mkdir $NFS_SHARED_DATASETS_DIR; mount -t nfs4 $nfs_clan_ip:$REMOTE_BLOCKSTORE_MOUNT_POINT $NFS_SHARED_DATASETS_DIR
echo "$nfs_clan_ip:$REMOTE_BLOCKSTORE_MOUNT_POINT $NFS_SHARED_DATASETS_DIR nfs4 rw,sync,hard,intr,addr=$my_clan_ip 0 0" >> /etc/fstab

# Move user accounts onto the shared directory. The master server is
# responsible for physically moving user files to shared folder. All other
# nodes just change the home directory in /etc/passwd. This avoids the problem
# of all servers trying to move files to the same place at the same time.
if [ $(hostname --short) == "master" ]
then
  for user in $(ls /users/)
  do
    usermod --move-home --home $NFS_SHARED_HOME_DIR/$user $user
  done
else
  for user in $(ls /users/)
  do
    usermod --home $NFS_SHARED_HOME_DIR/$user $user
  done
fi

# Setup password-less ssh between nodes
if [ $(hostname --short) == "master" ]
then
  for user in $(ls $NFS_SHARED_HOME_DIR)
  do
    ssh_dir=$NFS_SHARED_HOME_DIR/$user/.ssh
    /usr/bin/geni-get key > $ssh_dir/id_rsa
    chmod 600 $ssh_dir/id_rsa
    chown $user: $ssh_dir/id_rsa
    ssh-keygen -y -f $ssh_dir/id_rsa > $ssh_dir/id_rsa.pub
    cat $ssh_dir/id_rsa.pub >> $ssh_dir/authorized_keys
    chmod 644 $ssh_dir/authorized_keys
  done
fi

# Do some specific master setup here
if [ $(hostname --short) == "master" ]
then
  # Make tmux start automatically when logging into master
  cat >> /etc/profile.d/etc.sh <<EOM

if [[ -z "\$TMUX" ]] && [ "\$SSH_CONNECTION" != "" ]
then
  tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
fi
EOM
fi

# Give all users access to the node local partition.
chmod g=u $LOCAL_BLOCKSTORE_MOUNT_POINT

# Do user-specific setup here only on master (since user's home folder is on a
# shared filesystem.
if [ $(hostname --short) == "master" ]
then
  sudo --login -u $USERNAME $SCRIPTPATH/setup-user.sh
fi
