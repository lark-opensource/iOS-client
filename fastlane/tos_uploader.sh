#!/bin/bash

latest_version=$(curl -s http://tosv.byted.org/obj/toutiao.ios.arch/tos_uploader/version | awk '{print $2}')

if [[ -f ./tos-upload ]]; then
    rm ./tos-upload
fi
curl -s https://ios.bytedance.net/wlapi/tosDownload/toutiao.ios.arch/tos_uploader/"$latest_version" -o ./tos-upload
chmod +x ./tos-upload
./tos-upload -b lark-ios -k $1 $2
