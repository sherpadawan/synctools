#!/bin/bash 

if [ -z "$1" ];then
    echo "[ERROR] user@servername is required"
    exit 1
fi

echo "[INFO] Generating keys ...";
echo "" | ssh-keygen -t dsa -P ''

echo "[INFO] Copying keys to $1 ";
#cat ~/.ssh/id_dsa.pub | ssh $1 "cat - >> ~/.ssh/authorized_keys"
ssh-copy-id -i ~/.ssh/id_dsa.pub $1
