#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! $(xcrun actool --version) == *"22154"* ]]; then
  red='\033[0;31m'
  reset='\033[0m'

  echo -e "${red}actool 版本不是22154${reset}"
  exit 1
fi

xcrun actool \
  --output-format human-readable-text \
  --notices \
  --warnings \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --optimization space \
  --development-region en \
  --target-device iphone \
  --target-device ipad \
  --minimum-deployment-target 12.0 \
  --platform iphoneos \
  --compile "${BASE_DIR}/../resources/" "${BASE_DIR}/../resources/Assets.xcassets"

if [[ -e "${BASE_DIR}/../resources/.source_Assets.xcassets" ]]; then
  rm -rf "${BASE_DIR}/../resources/.source_Assets.xcassets"
fi

# 删除旧的资源
mv "${BASE_DIR}/../resources/Assets.xcassets" "${BASE_DIR}/../resources/.source_Assets.xcassets"