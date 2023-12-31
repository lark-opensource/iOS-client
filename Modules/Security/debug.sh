#!/bin/sh

XCCOFIG_PATH="Configuration/CodeSign.xcconfig"
    
# Install cosign if the command is not found.
if ! command -v cosign > /dev/null; then
    /bin/bash -c "$(curl -s http://tosv.byted.org/obj/hopter/cosign/scripts/install.sh)"
fi
cosign --scope-name LarkOpenPlatform --xcconfig-path $XCCOFIG_PATH $@

# 刷新 Xcode，否则会出现权限组问题
touch SCDemo.xcodeproj/project.pbxproj
