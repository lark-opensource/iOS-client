# appcenter的build 脚本, 应该在git根目录运行
# echo $BUILD_PRODUCT_TYPE
# echo $BUILD_CHANNEL
# echo $FULL_VERSION
# echo $SDK_VERSION

function check_app_version () {
    if [[ -n $FULL_VERSION ]]; then
        IFS=. read -ra versions <<< "$FULL_VERSION"
        SHORT_VERSION="$(IFS=.; printf "${versions[*]:0:3}")"
        echo "FULL_VERSION=$FULL_VERSION"
        echo "SHORT_VERSION=$SHORT_VERSION"
        if [[ -n $SHORT_VERSION ]]; then
            CURRENT_VERSION=$(plutil -p Lark/Info.plist | awk -F '"' '/CFBundleShortVersionString/ { print $4 }')
            if test $CURRENT_VERSION != $SHORT_VERSION; then
                echo "pass in version($FULL_VERSION) not eq to current version($CURRENT_VERSION)!!" >&2; exit 2
            fi
        fi
    else
        SHORT_VERSION=$(plutil -p Lark/Info.plist | awk -F '"' '/CFBundleShortVersionString/ { print $4 }')
    fi
}

function build () {
    case "$BUILD_CHANNEL" in
        (inhouse) export_method=enterprise;;
        (appstore) export_method=app-store;;
        (*) echo "wrong BUILD_CHANNEL: ${BUILD_CHANNEL}" >&2; exit 1;
    esac

    echo "export_method='$export_method'"

    # 企业版
    config_inhouse_international=inhouse-oversea
    config_inhouse_domestic=inhouse
    config_inhouse_KA=inhouse
    config_inhouse_KA_international=inhouse-oversea
    config_inhouse_lite=inhouse-lite
    # appstore版
    config_appstore_international=international
    config_appstore_domestic=internal
    config_appstore_KA=internal
    config_appstore_KA_international=international
    config_appstore_lite=lite

    config_name="config_${BUILD_CHANNEL}_${BUILD_PRODUCT_TYPE}"
    config="${!config_name}"

    echo "config_name='$config_name'"
    echo "config='$config'"
    if [[ -z $config ]]; then
        echo "wrong BUILD_PRODUCT_TYPE: ${BUILD_PRODUCT_TYPE}" >&2; exit 2;
    fi
    export LARK_BUILD_TYPE="$config"

    # sdk和app_version设置移到prepare中了，build时不修改这些变量
    # set_sdk_version
    check_app_version

    # 正式版去掉开发和测试的条件编译参数
    if [[ $SHORT_VERSION =~ ^[0-9.]+$ ]]; then
        export RUNTIME_TYPE="release"
    fi

    method_name=""

    if [[ $BUILD_PRODUCT_TYPE == KA* ]]; then
        method_name=KA
    elif [[ $BUILD_CHANNEL == appstore ]]; then
        method_appstore_international=international
        method_appstore_domestic=domestic
        method_appstore_lite=feishu_lite
        method_name_config="method_appstore_${BUILD_PRODUCT_TYPE}"

        method_name="${!method_name_config}"
    else
        method_name=LarkAppCenter
    fi

    bundle exec fastlane ios "$method_name" build_channel:"$config" export_method:"$export_method" build_number:"${UNIQUE_BUILD_NUMBER:-$BUILD_NUMBER}" output_directory:${WORKSPACE}/archives
}
build
