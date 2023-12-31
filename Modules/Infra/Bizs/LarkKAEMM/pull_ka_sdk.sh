function download_framework() {
  name=$1
  url=$2
  path=$3

  # download file and unzip
  curl $url --output "./${name}.zip"
  unzip -oq "./${name}.zip" -d "${name}_files"

  # clean and create target dir
  [[ -d "./frameworks/${name}" ]] && rm -rf "./frameworks/${name}"
  mkdir -p "./frameworks/${name}"

  mv "./${name}_files/$path" "./frameworks/${name}"
  rm "./${name}.zip"
  rm -rf "./${name}_files"
}

download_framework kazdtq http://tosv.byted.org/obj/ee-infra-ios/MBSSDK_ios_3.6.2_20210811092417.zip output/frameworks
