#!/usr/bin/env bash

# appcenter的prepare脚本，自己修改一些准备参数，比如RustVersion，app version等
function set_sdk_version () {
    if [[ -n $SDK_VERSION ]]; then
        sed -i '' -Ee "/pod[[:space:]]+[\"']RustPB[\"']/s/,.*/, '$SDK_VERSION'/" Podfile
        # 有变化时更新LarkSQLCipher
        git diff --quiet -- Podfile || {
            # 有LarkSQLCipher时
            fgrep -q 'LarkSQLCipher' Podfile.lock && {
                # pod update或者异常退出
                bundle install && bundle exec pod update RustPB LarkSQLCipher || exit 3
            }
        }
        echo "SDK_VERSION=$SDK_VERSION"
        git add Podfile Podfile.lock
    fi
}

function set_app_version () {
    if [[ -n $FULL_VERSION ]]; then
        IFS=. read -ra versions <<< "$FULL_VERSION"
        SHORT_VERSION="$(IFS=.; printf "${versions[*]:0:3}")"
        echo "FULL_VERSION=$FULL_VERSION"
        echo "SHORT_VERSION=$SHORT_VERSION"
        if [[ -n $SHORT_VERSION ]]; then
            for infoplist_path in "Lark/Info.plist" "ShareExtension/Info.plist" "NotificationServiceExtension/Info.plist" "BroadcastUploadExtension/Info.plist" "SmartWidget/Info.plist"; do
                plutil -replace CFBundleShortVersionString -string "$SHORT_VERSION" "$infoplist_path"
                git add $infoplist_path
            done
        fi
    else
        echo "FULL_VERSION must be set!" >&2; exit 1
    fi
}

function push_if_needed () {
    if [[ -n "$(git diff-index --cached --name-only HEAD)" ]]; then
        git commit -m "chore: prepare version: $FULL_VERSION" --no-verify &&
            # push到upstream, 需要push权限
            git -c push.default=upstream push || exit 2
    fi
}

function prepare () {
    set_app_version
    set_sdk_version

    push_if_needed
}
prepare
