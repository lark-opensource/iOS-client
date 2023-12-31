#!/bin/bash

podDirect=$(cd `dirname $0`; cd ..; pwd)
fileName='src/Business/Common/Models/Doc/UserDefaultKeys.swift'
sourefile=${podDirect}/${fileName}
echo $sourefile

awk -F "[()]" '$2~/major.*[0-9]+.*keyIndex/{print $2}'  $sourefile | sed 's/[[:space:]]//g'  > ./checkUserDefaultKeyTemp.txt

var=$(sort ./checkUserDefaultKeyTemp.txt | uniq -d)
if [[ "$var" != "" ]]
then
    echo "UserDefaultKeys.swift重复定义下面的key"
    echo $var
    exit 1

fi

rm -f ./checkUserDefaultKeyTemp.txt

