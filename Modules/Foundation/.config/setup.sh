#!/bin/sh

git remote add review `git remote get-url origin`

git config --local include.path ../.config/gitconfig

cp git-review /usr/local/bin
