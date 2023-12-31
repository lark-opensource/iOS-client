#!/bin/sh

username=$1

kinit ${username}@BYTEDANCE.COM
sed "s/username/${username}/g" ssh_config >> ~/.ssh/config

brew install git-lfs
git lfs install
