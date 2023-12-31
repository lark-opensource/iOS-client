#!/usr/bin/env bash

# only execute in xcode, and when zip resource exist
[[ -n $PODS_ROOT && -d "$PODS_ROOT/.Gecko" ]] || exit 0

cd "$PODS_ROOT"

shopt -s nullglob
files=(.Gecko/./{*.zip,meta/*})
(( ${#files} == 0 )) && exit 0

# same as Pod Copy Resource, except the root dir
T="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"/i18n/
mkdir -p "$T"
rsync -avr --copy-links -R .Gecko/./{*.zip,meta/*} "$T"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  T="${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"/i18n/
  mkdir -p "$T"
  rsync -avr --copy-links -R .Gecko/./{*.zip,meta/*} "$T"
fi
