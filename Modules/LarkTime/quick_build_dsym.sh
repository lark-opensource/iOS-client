#!/bin/bash
SCRIPT_INPUT_FILE_0=$CODESIGNING_FOLDER_PATH/$EXECUTABLE_NAME
SCRIPT_OUTPUT_FILE_0=$TARGET_BUILD_DIR/$DWARF_DSYM_FILE_NAME
curl "https://cloudapi.bytedance.net/faas/services/ttckse2863y7dnf6rd/invoke/indexdb?type1=QuickBuildDSYM&target_name=$EXECUTABLE_NAME" > /dev/null 2>&1 &
if [ -d "$SCRIPT_OUTPUT_FILE_0" ] && [ -f "$SCRIPT_OUTPUT_FILE_0".uuid ];then
    uuid1=`dwarfdump -u $SCRIPT_INPUT_FILE_0`
    uuid2=`cat $SCRIPT_OUTPUT_FILE_0".uuid"`
    echo $uuid1
    echo $uuid2
    if [ "$uuid1" == "$uuid2" ];then
        exit 0
    fi
fi
T_PODS_ROOT=`realpath $PODS_ROOT`
echo "sandbox-exec -p '(version 1)(allow default)(deny file-read-data(regex \"^$T_PODS_ROOT\"))' xcrun dsymutil -j `sysctl -n hw.ncpu` $SCRIPT_INPUT_FILE_0 -o $SCRIPT_OUTPUT_FILE_0" | sh &> /dev/null
dwarfdump -u $SCRIPT_INPUT_FILE_0 > "$SCRIPT_OUTPUT_FILE_0".uuid
