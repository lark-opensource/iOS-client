#!/bin/sh

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'

echo "${NC}1. check brew..."
if [ -f "/usr/local/bin/brew" ]
then
    echo "${GREEN}brew found!"
else
    echo "${NC}install brew..."
    echo `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
fi

echo "${NC}4. check git-lfs"
if [ -f "/usr/local/bin/git-lfs" ]
then
   echo "${GREEN}git-lfs found "
else
   echo "${NC}install git-lfs"
   echo `brew install git-lfs`
   echo "${NC}setup git-lfs"
   echo `git lfs install --local`
   echo `git lfs pull`
   echo "${NC}cleanup git-lfs"
   echo `git lfs uninstall --local`
   echo `brew uninstall git-lfs`
fi

