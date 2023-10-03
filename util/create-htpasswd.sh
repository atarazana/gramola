#!/bin/sh

export USER_COUNT=50

htpasswd -c -B -b users.htpasswd user1 openshift

for i in `seq 2 $USER_COUNT` 
do
  htpasswd -bB users.htpasswd user${i} openshift
done