#!/bin/sh
#
################################################################################
# 注意: 请配置下面的信息
################################################################################
HMD_APP_ID="0"
HMD_APP_KEY="APM"
DSYM_UPLOAD_URL_CN_BASE64="aHR0cDovL3N5bWJvbGljYXRlLmJ5dGVkLm9yZy9zbGFyZGFyX2lvc191cGxvYWQ="
DSYM_UPLOAD_URL_US_BASE64="aHR0cDovL3N5bWJvbGljYXRldXMuYnl0ZWQub3JnL3NsYXJkYXJfaW9zX3VwbG9hZA=="
DSYM_UPLOAD_URL=$(echo $DSYM_UPLOAD_URL_CN_BASE64 | base64 --decode)


echo "Region: $1"
echo "APPID: $2"

#$1 Region
if [ "$1" = "US" ] ;then
    DSYM_UPLOAD_URL=$(echo $DSYM_UPLOAD_URL_US_BASE64 | base64 --decode)
fi

echo "Uploading URL: $DSYM_UPLOAD_URL"

HMD_APP_ID=$2

################################################################################
# 自定义配置
###############################################################################
# Debug模式编译是否上传，1＝上传 0＝不上传，默认不上传
UPLOAD_DEBUG_SYMBOLS=0

# 模拟器编译是否上传，1＝上传，0＝不上传，默认不上传
UPLOAD_SIMULATOR_SYMBOLS=0

#
# # 脚本默认配置的版本格式为CFBundleShortVersionString(CFBundleVersion),  如果你修改默认的版本格式, 请设置此变量, 如果不想修改, 请忽略此设置
# CUSTOMIZED_APP_VERSION=""

################################################################################
# 注意: 如果你不知道此脚本的执行流程和用法，请不要随便修改！
################################################################################
function main() {
    # 退出执行并打印提示信息
    warningWithMessage() {
        echo "--------------------------------"
        echo -e "${1}"
        echo "--------------------------------"
        echo "No upload and over."
        echo "----------------------------------------------------------------"
        UPLOADFLAG=0
        exit ${2}
    }
    
    UPLOADFLAG=1
    
    echo "Uploading dSYM to Slardar."
    echo ""
    
    # 读取Info.plist文件中的版本信息
    echo "Info.Plist : ${INFOPLIST_FILE}"
    
    BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "${INFOPLIST_FILE}")
    BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "${INFOPLIST_FILE}")
    
    # 组装识别的版本信息(格式为CFBundleShortVersionString(CFBundleVersion), 例如: 1.0(1))
    if [ ! "${CUSTOMIZED_APP_VERSION}" ]; then
    HMD_APP_VERSION="${BUNDLE_SHORT_VERSION}(${BUNDLE_VERSION})"
    else
    HMD_APP_VERSION="${CUSTOMIZED_APP_VERSION}"
    fi
    
    echo "--------------------------------"
    echo "Step 1: Prepare application information."
    echo "--------------------------------"
    
    echo "Product Name: ${PRODUCT_NAME}"
    echo "Bundle Identifier: ${PRODUCT_BUNDLE_IDENTIFIER}"
    echo "Version: ${BUNDLE_SHORT_VERSION}"
    echo "Build: ${BUNDLE_VERSION}"
    
    echo "HMD App ID: ${HMD_APP_ID}"
    echo "HMD App key: ${HMD_APP_KEY}"
    echo "HMD App Version: ${HMD_APP_VERSION}"
    
    echo "--------------------------------"
    echo "Step 2: Check the arguments ..."
    echo "--------------------------------"
    
    ##检查模拟器是否允许上传符号
    if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]; then
    if [[ $UPLOAD_SIMULATOR_SYMBOLS -eq 0 ]]; then
    warningWithMessage "Warning: Build for simulator and skipping to upload. \nYou can modify 'UPLOAD_SIMULATOR_SYMBOLS' to 1 in the script." 0
    fi
    fi
    
    # 检查DEBUG模式是否允许上传符号
    if [[ ${CONFIGURATION=} == Debug* ]]; then
    if [[ $UPLOAD_DEBUG_SYMBOLS -eq 0 ]]; then
    warningWithMessage "Warning: Build for debug mode and skipping to upload. \nYou can modify 'UPLOAD_DEBUG_SYMBOLS' to 1 in the script." 0
    fi
    fi
    
    # 检查必须参数是否设置
    if [ ! "${HMD_APP_ID}" ]; then
    warningWithMessage "Error: HMD App ID not defined." 1
    fi
    
    if [ ! "${HMD_APP_KEY}" ]; then
    warningWithMessage "Error: HMD App Key not defined." 1
    fi
    
    CFBundleIdentifier=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "${INFOPLIST_FILE}")
    
    if [ ! "${PRODUCT_BUNDLE_IDENTIFIER}" ]; then
    PRODUCT_BUNDLE_IDENTIFIER=${CFBundleIdentifier}
    echo "WARNING!: Bundle Identifier not defined. Use CFBundleIdentifier"
    if [ ! "${CFBundleIdentifier}" ]; then
    warningWithMessage "Error!:  Bundle Identifier not defined. CFBundleIdentifier not defined" 1
    fi
    fi
    
    function uploadDSYM() {
        DSYM_SRC="$1"
        if [ ! -d "$DSYM_SRC" ]; then
        warningWithMessage "dSYM source not found: ${DSYM_SRC}" 1
        fi
        
        APPID="${HMD_APP_ID}"
        VERSION="${HMD_APP_VERSION}"
        BID="${PRODUCT_BUNDLE_IDENTIFIER}"
        
        ZIP_DIR_PATH=$(dirname ${DSYM_SRC})
        # 清理
        $(find ${ZIP_DIR_PATH} -name "*.zip" -mindepth 1 -delete)
        FILENAME=$(basename ${DSYM_SRC})
        DSYM_SYMBOL_OUT_ZIP_NAME="${VERSION}.zip"
        DSYM_ZIP_FPATH="${ZIP_DIR_PATH}/${DSYM_SYMBOL_OUT_ZIP_NAME}"
        cd "${ZIP_DIR_PATH}"
        PAD=$(zip -r ${DSYM_SYMBOL_OUT_ZIP_NAME} ${FILENAME})
        
        if [ ! -e "${DSYM_ZIP_FPATH}" ]; then
        warningWithMessage "no dSYM zip archive generated: ${DSYM_ZIP_FPATH}" 1
        fi
        
        FILESIZE=$(/usr/bin/stat -f%z ${DSYM_ZIP_FPATH})
        echo "dsym size: ${FILESIZE}"
        # if [ $FILESIZE -ge 52428800 ] ; then
        #     echo "dSYM zipped file is too big, please upload mannually."
        #     echo "dSYM zipped file path: ${DSYM_ZIP_FPATH}"
        #     echo "-----------------------------------------------------------------"
        #     return
        # fi
        
        echo "--------------------------------"
        echo "Step 3: Upload the zipped dSYM file."
        echo "--------------------------------"
        MD5ZIP=$(md5 -q ${DSYM_ZIP_FPATH})
        if [ ! ${#MD5ZIP} -eq 32 ]; then
            warningWithMessage "Error: Failed to caculate md5 of zipped file." 1
            fi
            echo "zip md5 : ${MD5ZIP}"
            echo "signature : ${MD5ZIP}"
            
            echo "dSYM upload domain: ${DSYM_UPLOAD_DOMAIN}"
            
            echo "dSYM upload url: ${DSYM_UPLOAD_URL}"
            
            # Upload dSYM to HMD
            echo "curl ${DSYM_UPLOAD_URL} -F \"file=@${DSYM_ZIP_FPATH}\"  -F \"aid=${HMD_APP_ID}\" -H \"Content-Type: multipart/form-data\" -w %{http_code} -v "
            
            echo "--------------------------------"
            
            # 上传请求
            STATUS=$(curl ${DSYM_UPLOAD_URL} -F "file=@${DSYM_ZIP_FPATH}" -F "aid=${HMD_APP_ID}" -H "Content-Type: multipart/form-data" -w %{http_code} -v)
            
            UPLOAD_RESULT="FAILTURE"
            echo "HMD server response: ${STATUS}"
            
        }
        
        # .dSYM文件信息
        echo "DSYM FOLDER ${DWARF_DSYM_FOLDER_PATH}"
        
        DSYM_FOLDER="${DWARF_DSYM_FOLDER_PATH}"
        
        IFS=$'\n'
        #解决New Build System模式下的兼容性问题 https://www.jianshu.com/p/cd6ff0a86f1c
        for i in {1..100}; do
        # sleep number, if append suffix "s" will meet error "usage: sleep seconds" on macOS 12+
        sleep 1
        # 遍历目录查找当前工程名的文件
            for dsymFile in $(find "$DSYM_FOLDER" -name "${PRODUCT_NAME}.*.dSYM"); do
                # 判断压缩文件的源文件是否存在
                SDYM_SINGLE_FILE_NAME="${dsymFile}/Contents/Resources/DWARF/${PRODUCT_NAME}"
                if [ ${UPLOADFLAG} -eq 1 -a -s "${SDYM_SINGLE_FILE_NAME}" ]; then
                echo "Found dSYM file: $dsymFile"
                uploadDSYM $dsymFile
                break 2
                fi
            done
        done
    }
    
    if [[ -z $uploaddsym ]]; then
    main
    fi