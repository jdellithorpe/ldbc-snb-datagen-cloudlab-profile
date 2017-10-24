#!/bin/bash

while read -r ip linkin linkout hostname
do 
  if [ "$ip" != "127.0.0.1" ]
  then
		echo "Running setup @ $ip..."
    USERNAME=$USER
    sudo ssh -o StrictHostKeyChecking=no -n root@$ip "sudo su $USERNAME; cd ~; /local/repository/setup.sh" &
  fi
done < /etc/hosts

wait
