#!/bin/sh
#author: xurunkang

max_file_size_mb=$1
file_path=$2

current_file_path_size_mb=`du -sm $file_path|awk '{print $1}'`

# echo " max file size $max_file_size_mb "
# echo " current_file_path_size_mb $current_file_path_size_mb "

if [ $current_file_path_size_mb -gt $max_file_size_mb ]
then
    echo " 😭 eesz 磁盘占用过多, 请检查 ... ($current_file_path_size_mb MB) 😭 "
    echo " 检查这个目录 /Docs/Projects/DocsSDK/Resources/eesz ... 或者重新更新一次资源包"
    exit 1
else
    echo " 😁 eesz 磁盘占用正常 ($current_file_path_size_mb MB)  😁 "
fi