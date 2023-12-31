usage()
{
  echo "Usage: $0 [ -n productName ] [ -t buildType ]"
  exit 2
}

while getopts 'n:t:' c
do
    case $c in
        n)
            productName=$OPTARG
            ;;
        t)
            buildType=$OPTARG
            ;;
        h|?)
            usage
            ;;
    esac
done

if [ -z "$productName" ]; then
    usage
fi

if [ -z "$buildType" ]; then
    usage
fi

cd archives
ipa_name=$(ls *.ipa)
dsym_name=$(ls *.dSYM.zip)
cp ../bin/toscli-darwin toscli-darwin
chmod a+x toscli-darwin

# 上传ipa
upload_result=$(curl -X POST \
 http://eetest.bytedance.net/automation/v1/file \
 -H 'Content-Type: multipart/form-data' \
 -F file=@${ipa_name})

# 上传符号表
upload_dsym_result=$(curl -X POST \
 http://eetest.bytedance.net/automation/v1/file \
 -H 'Content-Type: multipart/form-data' \
 -F file=@${dsym_name})

cd ..

echo $upload_result

upload_status=$(ruby bin/parse_json.rb $upload_result "status")
if [[ $upload_status == "200" ]]; then
  echo "上传到tos成功!!!!"
else
  echo "上传到tos失败!!!!"
  curl -X POST \
    https://oapi.zjurl.cn/open-apis/bot/hook/133d50ec6f2f4967888f5a78f4bffef2 \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"iOS包上传到tos失败\",
      \"text\": \"ipa包的名字: ${ipa_name}\n失败原因: ${upload_status}\"
    }"
  exit 2
fi

version=$(echo ${ipa_name} | awk -F _ '{print $2}')
ipa_url=$(ruby bin/parse_json.rb $upload_result "urls")
dsym_url=$(ruby bin/parse_json.rb $upload_dsym_result "urls")

echo $ipa_url
echo $dsym_url
echo $productName
echo $version
echo $buildType

data="
  {
    \"PackageURL\": \"${ipa_url}\",
    \"ProductName\": \"${productName}\",
    \"Department\": \"EE\",
    \"Version\": \"${version}\",
    \"BuildType\": \"${buildType}\",
    \"Platform\": \"iOS\",
    \"Other\": {
    	\"DSYMURL\": \"${dsym_url}\"
    }
  }"

echo $data

curl -X POST \
  http://eetest.bytedance.net/automation/v1/app-packages \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$data"