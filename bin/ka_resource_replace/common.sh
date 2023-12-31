#/bin/bash

#定义颜色变量
RED='\033[31m'   # 红
GREEN='\033[32m' # 绿
YELOW='\033[33m' # 黄
BLUE='\033[34m'  # 蓝
PINK='\033[35m'  # 粉红
RES='\033[0m'    # 清除颜色

log() {
  echo "${PINK}$(date)${RES} $2$1${RES}"
}

if [[ $BUILD_PRODUCT_TYPE == KA* ]]; then
  log "当前是KA环境" ${GREEN}
else
  log "仅构建KA包才可以调用该脚本" ${RES}
  exit 10001
fi