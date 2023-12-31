usage()
{
  echo "Usage: $0 [ -n productName ] [ -t compileTime ] [ -r uploadUrl ]"
  exit 2
}

while getopts 'n:t:v:b:r:' c
do
    case $c in
        n)
            productName=$OPTARG
            ;;
        t)
            compileTime=$OPTARG
            ;;
        v)
            appVersion=$OPTARG
            ;;
        b)
            buildVerison=$OPTARG
            ;;
        r)
            uploadUrl=$OPTARG
            ;;
        h|?)
            usage
            ;;
    esac
done

if [ -z "$productName" ]; then
    usage
fi

if [ -z "$compileTime" ]; then
    usage
fi

if [ -z "$appVersion" ]; then
    usage
fi

if [ -z "$buildVerison" ]; then
    usage
fi

if [ -z "$uploadUrl" ]; then
    usage
fi

echo $compileTime

timestamp=$(date +%s)
headOs="iOS"

metric="
  {
    \"name\": \"Lark\",
    \"content\": \"${compileTime}\"
  }"

echo $metric

compileData="
  {
    \"service\": \"compile_time\",
    \"metric\": [${metric}]
  }
"

echo $compileData


data="
  {
    \"build_version\": \"${buildVerison}\",
    \"timestamp\": \"${timestamp}\",
    \"head_app_version\": \"${appVersion}\",
    \"product_name\": \"${productName}\",
    \"head_os\": \"${headOs}\",
    \"data\": ${compileData}
  }"

echo $data

curl -X POST \
  $uploadUrl \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$data"
