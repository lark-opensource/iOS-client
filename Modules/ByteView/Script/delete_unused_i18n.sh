#!/bin/bash

MODULE_NAME=$1
if [ -z "$MODULE_NAME" ]; then
	MODULE_NAME="ByteView"
fi

ROOT_PATH="$(cd "$(dirname $(dirname "$0"))"; pwd)"

echo "ROOT_PATH = $ROOT_PATH"
echo "MODULE_NAME = $MODULE_NAME"

python3 "$ROOT_PATH/Script/python_scripts/delete_unused_i18n.py" "$ROOT_PATH" "$MODULE_NAME"