#  s.script_phase = {
#  :name => 'CreateAppLogModulemap',
#  :script => '',
#  :execution_position => :before_compile
#  }

# 这段脚本是为了处理以后 RangersAppLog 切换为静态库之后 用来自动创建 modulemap
# 同时 如果需要开启这段脚本的话需要经过更多的测试
# 其中路径相关的内容要根据 RangersAppLogCore 的版本进行调整

COMMON_APPLOG_DIR="${PROJECT_DIR}/RangersAppLog"
  if [ -f "${COMMON_APPLOG_DIR}/module.modulemap" ]
   then
   echo "RangersAppLog already exists, skipping"
   else
   FRAMEWORK_DIR="${BUILT_PRODUCTS_DIR}/RangersAppLog.framework"
   if [ -d "${FRAMEWORK_DIR}" ]; then
     echo "${FRAMEWORK_DIR} already exists, so skipping the rest of the script."
     exit 0
   fi
   mkdir -p "${FRAMEWORK_DIR}/Modules"
   echo "framework module RangersAppLog {
     umbrella header \"${COMMON_APPLOG_DIR}/RangersAppLog/Core/RangersAppLogCore.h\"
     export *
     module * { export * }
   }" >> "${FRAMEWORK_DIR}/Modules/module.modulemap"
   ln -sf "${COMMON_APPLOG_DIR}" "${FRAMEWORK_DIR}/Headers"
 fi
