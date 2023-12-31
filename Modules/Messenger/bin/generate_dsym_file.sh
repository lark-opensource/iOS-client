#!/bin/bash

dsymutil_dir="${TMPDIR}dsymutil"
app_name=$1

if [[ -z "${app_name}" ]]; then
  echo "缺少入参应用明"
  exit 1
fi

if [[ -z "${TMPDIR}" ]]; then
  dsymutil_dir="$PROJECT_DIR/fastlane"
fi

dsymutil_path="${dsymutil_dir}/dsymutil"

if [[ "${CONFIGURATION}" == "Release" && -e "${dsymutil_path}" ]]; then
  time "${dsymutil_path}" \
    "${BUILT_PRODUCTS_DIR}/${app_name}.app/${app_name}" \
    -o "${BUILT_PRODUCTS_DIR}/${app_name}.app.dSYM"
fi
