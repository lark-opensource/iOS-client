#!/bin/bash
echo -e "\033[32m ------- handle js start ----------\033[0m"

SOURCE_PATH='block_jssdk'
DESTINATE_PATH='../Timor/Resources/Others'
BLOCKIT_PATH='../../OPBlockInterface/src/Utils/OPBlockSDK.swift'

# 自动进入脚本目录
SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $SCRIPT_PATH

rm -rf $DESTINATE_PATH/block_jssdk_version
cat $SOURCE_PATH/basebundlecheck | tr -d \\n > $DESTINATE_PATH/block_jssdk_version    #留下版本号，方便检测逻辑， | tr -d \\n 用于移除尾随\n


rm -rf $DESTINATE_PATH/block_jssdk.zip
rm -rf $DESTINATE_PATH/block_jssdk.txz

tar cfJ $DESTINATE_PATH/block_jssdk.txz $SOURCE_PATH

OLD_CONTENT=`grep "let runtimeSDKVersion" ${BLOCKIT_PATH}`

NEW_CONTENT='    public static let runtimeSDKVersion = "'$1'"'
REGX="$OLD_CONTENT"

sed -i "" "s/$REGX/$NEW_CONTENT/g" $BLOCKIT_PATH

if [ $? -eq 0 ]; then
    echo -e "\033[32m ------- handle js success ----------\033[0m"
else 
    echo -e "\033[31m ------- handle js failed ----------\033[0m"
fi
