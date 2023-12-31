#!/usr/bin/env bash

# READ.ME
# https://bytedance.feishu.cn/docx/Yw6Td1Lssos58exYYDucOi1xnWb

set -Eeox pipefail

function realpath() (
  OURPWD=$PWD
  cd "$(dirname "$1")"
  REALPATH="$(PWD -P)/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
)

function export2env() {
  local key=$1
  local value=$2
  command -v bit &>/dev/null && bit env set "${key}" "${value}" || echo 0
  export "${key}=${value}"
  echo "export2env ${key}=${value}"
}

# 根据环境变量主动注册新版本 xcode
function registerxcode() {
  # 检查环境变量 XCODE_VERSION 是否存在
  if [ -n "$XCODE_VERSION" ]; then
    echo "Environment variable XCODE_VERSION :${XCODE_VERSION}"
    # 构建Xcode安装路径
    REGISTER_XCODE_PATH="/Applications/Xcode-${XCODE_VERSION}.app"
    # 检查Xcode路径是否存在
    if [ -d "$REGISTER_XCODE_PATH" ]; then
        # 执行register指令（替换为实际需要执行的命令）
        echo "Registering Xcode version $XCODE_VERSION"
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f "${REGISTER_XCODE_PATH}"
    else
        echo "Xcode version $XCODE_VERSION not found at $REGISTER_XCODE_PATH"
    fi
  fi
}

path=$(realpath "${BASH_SOURCE:-$0}")
project_root_dir=$(dirname "$path")
if which orbit > /dev/null; then
    bundle_exec="orbit bundle exec"
else
    bundle_exec="bundle exec"
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --verbose)
    VERBOSE=1
    shift
    ;;
  --install)
    INSTALL=1
    shift
    ;;
  --update_external_only)
    UPDATE_EXTERNAL_ONLY=1
    shift
    ;;
  --integrate)
    INTEGRATE="--integrate_monorepo"
    shift
    ;;
  --g)
    GENERATE=1
    shift
    ;;
  --c)
    COMPILATION_DB=1
    shift
    ;;
  --c_incremental_files)
    C_INCREMENTAL_FILES="$2"
    shift
    ;;
  --c_output_file)
    C_OUT_FILE="$2"
    shift
    ;;
  --build)
    BUILD=1
    shift
    ;;
  --mbox)
    MBOX=1
    shift
    ;;
  --clean)
    CLEAN=1
    shift
    ;;
  --skip_install) #跳过 bundle install 和 pod  install
    SKIP_INSTALL=1
    shift
    ;;
  --configuration)
    configuration="$2" #Debug、Release
    shift
    shift
    ;;
  --scheme)
    scheme="$2" #要编译的组件，e.g.  LarkHTTP，不传则编译整个Lark
    shift
    shift
    ;;
  --archs)
    archs="$2" #arm64、x86_64、sim_arm64
    shift
    shift
    ;;
  --sdk) # simulator/os
    sdk="$2"
    shift
    shift
    ;;
  --build_type) #可以不传，可用选项： inhouse/international/internal/inhouse-oversea/dev-oversea
    build_type="$2"
    shift
    shift
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done

if [[ -z "$configuration" ]]; then
  configuration="Debug"
fi

if [[ ${configuration}x == 'Debug'x ]]; then
  configuration="Debug"
else
  configuration="Release"
fi

# check sdk/archs related arguments
if [[ -z "$sdk" ]]; then
  sdk="simulator"
fi

if [[ -z "$archs" ]]; then
  if [[ "$sdk" == "simulator" ]]; then
    cpu_type=$(/bin/bash -c "uname -m")
    if [[ "$cpu_type" == "arm64" ]]; then #apple silicon 默认sim arm64
      archs="sim_arm64"
    else
      archs="x86_64"
    fi
  else
    archs="arm64" #真机默认arm64
  fi
fi

# Install bitsky bin
export PATH=${HOME}/Library/Caches/BitSky/tools/skyup/stable:$PATH
cd ${project_root_dir}
bash <(curl -fsSL --retry 3 http://tosv.byted.org/obj/bit-io/bitsky/scripts/skyup_install.sh)
bitsky prebuild

if [[ ${UPDATE_EXTERNAL_ONLY}x == "1"x ]]; then
  cd ${project_root_dir}
  rm -rf dev_target
  git checkout -- deps.yml
  $bundle_exec pod parse-diff
  cat Host_Patch
  bitsky update --skip_update_dependencies --dynamic --verbose --integrate_monorepo
fi

if [[ ${INSTALL}x == "1"x ]]; then
  cd ${project_root_dir}

  if [[ ${SKIP_INSTALL}x != "1"x ]]; then
    if [[ -e /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk ]]; then
      SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk bundle install
    else
      DEVELOPER_DIR= bundle install
    fi
  fi

  rm -rf dev_target
  git checkout -- deps.yml

  # dynamically update bazel materials
  cd ${project_root_dir}
  export USE_SWIFT_BINARY="false"
  export REMOTE_CACHE_ENABLE="false"

  export External_SOURCE_BOOT="true"
  if [[ ${SKIP_INSTALL}x != "1"x ]]; then
    $bundle_exec pod install --verbose
  fi

  $bundle_exec pod parse-diff
  cat Host_Patch
  bitsky update --skip_update_dependencies --dynamic --verbose ${INTEGRATE}

  $bundle_exec pod bitsky-install --file_setup --enable_rules_ios
  $bundle_exec pod bitsky-install --install --skip_circle_dependencies --enable_rules_ios --enable_lark
  # sed LarkConfig/Lark-Shared.xcconfig
  ./bin/BuildSettingExtractorCli -x Lark.xcodeproj -o LarkConfig
  find LarkConfig -type f -name "*.xcconfig" | xargs -I {} sed -i '' -e 's/^#include \"/#include \"LarkConfig\//' {}
  find LarkConfig -type f -name "*.xcconfig" | xargs -I {} sed -i '' -e 's/PROVISIONING_PROFILE_SPECIFIER/PROVISIONING_PROFILE/' {}
  find LarkConfig -type f -name "*-Shared.xcconfig" | xargs -I {} sh -c 'echo "\nPRODUCT_MODULE_NAME = \$(PRODUCT_NAME)" >> {}'
  if [[ -f ${project_root_dir}/LarkConfig/Lark-Shared.xcconfig ]]; then
    content=$(
      cat LarkConfig/Lark-Shared.xcconfig | grep AppIdentifierPrefix
      true
    )
    if [[ -z $content ]]; then
      echo "" >>LarkConfig/Lark-Shared.xcconfig
      echo "AppIdentifierPrefix = 2" >>LarkConfig/Lark-Shared.xcconfig
    fi

  fi
fi

bitsky_common_args="--configuration ${configuration} --sdk ${sdk} --archs ${archs}"

if [[ ${GENERATE}x == "1"x ]]; then
  cd ${project_root_dir}
  bitsky generate ${bitsky_common_args} --project_name=LarkBitSky \
    --bazelrc ${project_root_dir}/.bitsky/plugins/Lark/bazelrc/common.bazelrc
  exit 0
fi

if [[ -n "$build_type" ]]; then
  ./BuildScript/XcodeEdit ./ BuildScript/config.json $build_type
  echo "extract xcodeproj build setting to xcconfig with build type $build_type"
  ./bin/BuildSettingExtractorCli -x Lark.xcodeproj -o LarkConfig
  #替换 #include "xxx" 为 #include "LarkConfig/xxx"
  find LarkConfig -type f -name "*.xcconfig" | xargs -I {} sed -i '' -e 's/^#include \"/#include \"LarkConfig\//' {}
  find LarkConfig -type f -name "*.xcconfig" | xargs -I {} sed -i '' -e 's/PROVISIONING_PROFILE_SPECIFIER/PROVISIONING_PROFILE/' {}
  find LarkConfig -type f -name "*-Shared.xcconfig" | xargs -I {} sh -c 'echo "\nPRODUCT_MODULE_NAME = \$(PRODUCT_NAME)" >> {}'
  #从LarkConfig/Lark-Shared.xcconfig读取mobile provision
  mobile_provision=$(grep PROVISIONING_PROFILE LarkConfig/Lark-Shared.xcconfig | awk '{print $NF}')
  mobile_provision="Provisions/$mobile_provision.mobileprovision"
  # #从mobile provision中解析AppIdentifierPrefix
  appIdentifierPrefix=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<<$(security cms -D -i $mobile_provision))
  appIdentifierPrefix=$(echo $appIdentifierPrefix | awk -F "." '{print $1"."}')
  # #LarkConfig/Lark-Shared.xcconfig添加AppIdentifierPrefix = xxx
  echo "change AppIdentifierPrefix to $appIdentifierPrefix"
  content=$(
    cat LarkConfig/Lark-Shared.xcconfig | grep AppIdentifierPrefix
    true
  )
  export AppIdentifierPrefix=$appIdentifierPrefix
  if [[ -z $content ]]; then
    echo "" >>LarkConfig/Lark-Shared.xcconfig
    echo "AppIdentifierPrefix = $appIdentifierPrefix" >>LarkConfig/Lark-Shared.xcconfig
  else
    sed -i '' -e "s/^AppIdentifierPrefix =.*/AppIdentifierPrefix = $appIdentifierPrefix/" LarkConfig/Lark-Shared.xcconfig
  fi
fi

if [ ! -n "$AppIdentifierPrefix" ]; then
  export AppIdentifierPrefix="2" # 模拟器环境下 lark 必须要这个变量。
fi

if [[ ${BUILD}x == "1"x ]]; then
  cd ${project_root_dir}
  # 缓存进程常驻适配
  if [[ "$BITSCLOUD_EBS" != "1" && "$DOLPHIN_DAEMON_LAUNCHED" == "1" ]]; then
    if [ $(ps aux | grep root | grep coral | awk '{print $11}' | grep -v coral-manager | wc -l) -eq 0 ]; then
      export2env "BITSKY_TAG_DOLPHIN_DAEMON_FAILED" "1"
      echo "Dolphin 常驻进程失效"
    else
      export2env "BITSKY_TAG_DOLPHIN_DAEMON" "1"
      export2env "OCEAN_HOME" "/Users/Shared/dolphin_cache/.ocean"
      export2env "DISABLE_STOP_OCEAN" "1"
      echo "Dolphin 常驻进程生效"
    fi
  fi
  if [[ ${ENABLE_RBE}x == "1"x ]]; then
    export2env "SAILFISH_SWIFT_MODULE_CACHE_DIR" "../.ocean/dep_server_goma/swift_module_cache"
    export2env "SAILFISH_MAX_SUBPROCS_LOW" "20"
    export2env "SAILFISH_MAX_SUBPROCS" "20"
    export2env "SAILFISH_MAX_SUBPROCS_HEAVY" "20"
    export2env "BITSKY_TAGS_ENABLE_RBE" "1"
    bitsky_common_args="${bitsky_common_args} --use_sailfish"
  fi
  if [[ ! -z ${WORKFLOW_PIPELINE_ID} ]]; then
    #CI构建，尝试加hummer tag
    if [[ ! -z ${WORKFLOW_REPO_TARGET_BRANCH} ]]; then
      export BITSKY_TAG_BAZEL_Compile_Verify="1"
    else
      export BITSKY_TAG_Compile_Verify="0"
      export BITSKY_TAG_BAZEL_DEV="1"
    fi
  fi
  if [ -z "$WORKFLOW_JOB_ID" ] && ([ -z "$JOB_NAME" ] || [[ "$JOB_NAME" == "bazel_cache_publish" ]]); then # local compile
    ocean_yml_path=".bitsky/plugins/Lark/.ocean/dev_build.yaml"
  else
    ocean_yml_path=".bitsky/plugins/Lark/.ocean/build.yaml"
  fi
  export2env "BITSKY_TAGS_ENABLE_RBE" "1"  
  if [[ ${configuration}x == 'Debug'x ]]; then
    build_command="dev-build" 
  else
    build_command="build" 
  fi
  COMMAND_STRING="bitsky ${build_command} ${bitsky_common_args} \
    --bazelrc ${project_root_dir}/.bitsky/plugins/Lark/bazelrc/common.bazelrc \
    --ocean_yml_path=${ocean_yml_path}"

  # 如果开启了覆盖率包增加 bazel feature
  if [ -n "$CODECOVERAGE" ]; then
    COMMAND_STRING="${COMMAND_STRING} --bazelrc ${project_root_dir}/.bitsky/plugins/Lark/bazelrc/coverage.bazelrc"
    plist_path=dev_target/BDTestCoverage/BDTestCoverage/Assets/GITInfo.plist
    /usr/libexec/PlistBuddy -c "Set :GITProjectId ${WORKFLOW_REPO_ID}" $plist_path
    /usr/libexec/PlistBuddy -c "Set :GITBranch ${WORKFLOW_REPO_BRANCH}" $plist_path
    /usr/libexec/PlistBuddy -c "Set :GITHash ${WORKFLOW_REPO_COMMIT}" $plist_path
    /usr/libexec/PlistBuddy -c "Set :TaskId ${TASK_ID}" $plist_path

    /usr/libexec/PlistBuddy -c "Print" $plist_path
  fi

  if [[ ! -z ${scheme} ]] && [[ scheme != "Lark" ]]; then
    COMMAND_STRING="${COMMAND_STRING} --custom_build_labels @${scheme}//:Lark_${scheme}"
  fi

  if [[ $BIT_WORKSPACE_DIR ]]; then
    registerxcode
    if [ -d "$BIT_WORKSPACE_DIR/products" ]; then rm -r "$BIT_WORKSPACE_DIR/products"; fi
    mkdir $BIT_WORKSPACE_DIR/products
    COMMAND_STRING="${COMMAND_STRING} --beauty_output --output=$BIT_WORKSPACE_DIR/products --raw_log_path=$BIT_WORKSPACE_DIR/products/bazel_build.raw.log"
    if [[ ${configuration}x == 'Release'x ]]; then
      COMMAND_STRING="${COMMAND_STRING} --linkmap --dsym"
    fi
  fi
  echo "bitsky 指令：$COMMAND_STRING"
  $COMMAND_STRING
fi

if [[ ${COMPILATION_DB}x == "1"x ]];then
    cd ${project_root_dir}
    echo 'build --swiftcopt=-wmo' > ${project_root_dir}/compilation_db.bazelrc
    bitsky_common_args="--skip_hmap --configuration ${configuration} --sdk ${sdk} --archs ${archs} --c_db_type aspect --swift_frontend"
    if [[ ! -z ${C_INCREMENTAL_FILES} ]]; then
      bitsky_common_args="${bitsky_common_args} --incremental_file $C_INCREMENTAL_FILES"
    fi
    if [[ ! -z ${C_OUT_FILE} ]]; then
      bitsky_common_args="${bitsky_common_args} --outfile $C_OUT_FILE"
    fi
    bitsky compilation_db ${bitsky_common_args} --target Lark --mnemonic '(Objc|Cpp|Swift)Compile' --invoker Terminal \
    --bazelrc ${project_root_dir}/.bitsky/plugins/Lark/bazelrc/common.bazelrc \
    --bazelrc ${project_root_dir}/compilation_db.bazelrc
fi