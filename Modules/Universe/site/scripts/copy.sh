#!/usr/bin/env bash

set -e

ROOT_PATH=`git rev-parse --show-toplevel`;
SITE_PATH="$ROOT_PATH/site"
SOURCE_PATH="$ROOT_PATH/../es-design/client"

# 复制目录

# 安装依赖
yarn
