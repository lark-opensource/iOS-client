function download_framework() {
  name=$1
  url=$2
  path=$3

  # get script's dir path
  base_path=$(
  cd $(dirname $0)
  pwd
)

  # download file and unzip
  curl $url --output "${base_path}/${name}.zip"
  unzip -oq "${base_path}/${name}.zip" -d "${name}_files"

  # clean and create target dir
  [[ -d "${base_path}/frameworks/${name}" ]] && rm -rf "${base_path}/frameworks/${name}"
  mkdir -p "${base_path}/frameworks/${name}"

  mv "${base_path}/${name}_files/$path" "${base_path}/frameworks/"
  rm "${base_path}/${name}.zip"
  rm -rf "${base_path}/${name}_files"
}

download_framework WST http://tosv.byted.org/obj/ee-infra-ios/ka_sdk/fkms/WST.zip WST
download_framework TW http://tosv.byted.org/obj/ee-infra-ios/ka_sdk/fkms/TW.zip TW
