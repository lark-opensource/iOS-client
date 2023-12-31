#!/bin/bash
#get TTNetworkManager's version value from json file(pod_info.json) in ${PODS_ROOT}
#this value is set by packager in Bits, which may be different from ttnet_version
#by dongyangfan, 2021/04/30

#set -e  #set -e will terminate program immediately when one statement return a non-zero code, which will cause some important statement unable to execute, ie: grep TTNetworkManager in Podfile.lock, here we must anotate it.
IFS=$'\n'

cd ${PODS_ROOT}
cd ..

PATTERN="\- TTNetworkManager ([^=].*):"
VALUE=`grep "$PATTERN" Podfile.lock`
if [ -z "$VALUE" ];then
  PATTERN="\- TTNetworkManager/Core ([^=].*):"
  VALUE=`grep "$PATTERN" Podfile.lock`
fi

VALUE=${VALUE#*\(}
VALUE=${VALUE%\)*}

case $VALUE in
  *.1.binary-debug)
    VALUE=${VALUE%.1.binary-debug*};;
  
  *.1-binary)
    VALUE=${VALUE%.1-binary*};;
esac

#if exist pod_info.json, use next lines
<<'COMMENT'
#get value from JSON, NOT support nested value
function getJsonValue() {
  awk -v json="$1" -v key="$2" -v defaultValue="$3" 'BEGIN{
    foundKeyCount = 0
    while (length(json) > 0) {
      pos = match(json, "\""key"\"[ \\t]*?:[ \\t]*");
      if (pos == 0) {
        if (foundKeyCount == 0) {
          print defaultValue;
        } 
        exit 0;
      }

      ++foundKeyCount;
      start = 0; stop = 0; layer = 0;
      for (i = pos + length(key) + 1; i <= length(json); ++i) {
        lastChar = substr(json, i - 1, 1)
        currChar = substr(json, i, 1)

        if (start <= 0) {
          if (lastChar == ":") {
            start = currChar == " " ? i + 1: i;
            if (currChar == "{" || currChar == "[") {
              layer = 1;
            }
          }
        } else {
          if (currChar == "{" || currChar == "[") {
            ++layer;
          }
          if (currChar == "}" || currChar == "]") {
            --layer;
          }
          if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
            stop = currChar == "," ? i : i + 1 + layer;
            break;
          }
        }
      }

      if (start <= 0 || stop <= 0 || start > length(json) || stop > length(json) || start >= stop) {
        if (foundKeyCount == 0) {
          print defaultValue;
        } 
        exit 0;
      } else {
        print substr(json, start, stop - start);
      }

      json = substr(json, stop + 1, length(json) - stop)
    }
  }'
}

JSON=$(cat ${PODS_ROOT}/pod_info.json)
#JSON=$(cat ../Example/Pods/pod_info.json)
POD_NAME="TTNetworkManager"
KEY_NAME="version"

OUTER=$(getJsonValue $JSON $POD_NAME)
INNER_ORIGIN=$(getJsonValue $OUTER $KEY_NAME)
INNER_DEPREFIX=${INNER_ORIGIN#*\"}
INNER_DESUFFIX=${INNER_DEPREFIX%\"*}
COMMENT

cd ${PODS_ROOT}/TTNetworkManager/Pod/Assets
echo "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>ttnetversion</key>
	<string>$VALUE</string>
</dict>
</plist>

    " > TTNetVersion.plist

