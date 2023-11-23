#!/usr/bin/sh
set -e
if [ -f $1 ] 
 then
   echo "Existing Installation Lock File Found: "$1
   echo -n 'Installer Status: ' 
   if [ ! -s $1 ]
    then
        echo 'In Progress'
    else
        state=$(cat $1)
        if [ $state -eq 0 ]
            then
                echo 'Completed'
                SVC_NAME=k3s-agent
                if [ $3 = "master" ]
                 then
                  SVC_NAME=k3s
                  kubectl get nodes
                 fi 
                systemctl --no-pager status $SVC_NAME | head
                exit 0
            else
                echo 'Failed' 
                tail /home/$SUDO_USER/appliance_init.out
                exit 0
        fi   
    fi
    tail -f /home/$SUDO_USER/appliance_init.out
 else
   exit 0
fi
