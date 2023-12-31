#!/bin/bash

echo -e "\033[32m ------- encode js start ----------\033[0m"

SOURCE_PATH='__dev__'
OFFLINE_PATH='offline'
DESTINATE_PATH='../Timor/Resources/dat.bundle'
OTHERS_PATH='../Timor/Resources/Others'
ZIP_PASSWORD='gadget' # 密码不需要特殊保护，这里仅仅是为了对代码进行混淆，防止苹果检测出JS代码，设置一个简单的密码即可，这个密码与 Timor 中 coder.h 中 ZIP_PASSWORD 保持一致

# 自动进入脚本目录
SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $SCRIPT_PATH

### 旧版基础库打包逻辑
#./encoder $SOURCE_PATH/tma-core.js $DESTINATE_PATH/kotl.dat
#./encoder $SOURCE_PATH/tmg-core.js $DESTINATE_PATH/meeop.dat
#./encoder $SOURCE_PATH/webview.js $DESTINATE_PATH/enigma.dat
#./encoder $SOURCE_PATH/vconsole.min.js $DESTINATE_PATH/doom.dat
#./encoder $SOURCE_PATH/webview.css $DESTINATE_PATH/luna.dat
rm -rf $DESTINATE_PATH/siren.dat
base64 -i $SOURCE_PATH/basebundlecheck | tr -d \\n > $DESTINATE_PATH/siren.dat    #留下版本号，方便检测逻辑， | tr -d \\n 用于移除尾随\n

### 新版基础库打包逻辑，为了方便未来文件目录扩展，改为zip打包方式
#清除旧版遗留的数据，防止多打一份进去影响包大小
rm -rf $DESTINATE_PATH/kotl.dat
rm -rf $DESTINATE_PATH/meeop.dat
rm -rf $DESTINATE_PATH/enigma.dat
rm -rf $DESTINATE_PATH/doom.dat
rm -rf $DESTINATE_PATH/luna.dat
rm -rf $DESTINATE_PATH/zio.dat
#rm -rf $DESTINATE_PATH/siren.dat    #留下版本号，方便检测逻辑
#先压缩再加密
rm -rf $DESTINATE_PATH/delta.dat
rm -rf $DESTINATE_PATH/delta.txz.dat

tar cfJ delta.txz $SOURCE_PATH # 使用 xz 对 JSSDK 进行压缩，获得最佳压缩率 https://bytedance.feishu.cn/docx/doxcnndEH6A7gxOseUpR6EIIzFf
zip --password $ZIP_PASSWORD -r -0 $DESTINATE_PATH/delta.txz.dat delta.txz # txz压缩后，没有加密，使用 zip + 0 压缩率设置密码
rm -rf delta.txz
# ./encoder ./__dev__.zip $DESTINATE_PATH/delta.dat
# rm -rf ./__dev__.zip

rm -rf $DESTINATE_PATH/zio.dat
zip --password $ZIP_PASSWORD -r -9 $DESTINATE_PATH/zio.dat $OFFLINE_PATH
# ./encoder ./offline.zip $DESTINATE_PATH/zio.dat
# rm -rf ./offline.zip

#其他配置
rm -rf $OTHERS_PATH/ez.dat
base64 -i ./TMAAPIAuth.plist | tr -d \\n > $OTHERS_PATH/ez.dat # | tr -d \\n 用于移除尾随\n

if [ $? -eq 0 ]; then
    echo -e "\033[32m ------- encode js success ----------\033[0m"
else 
    echo -e "\033[31m ------- encode js failed ----------\033[0m"
fi
