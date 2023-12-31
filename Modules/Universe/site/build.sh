#!/bin/bash
set -e
# 切换node版本 change node version
source /etc/profile
nvm use 12.14.1

cd site
eden pipeline