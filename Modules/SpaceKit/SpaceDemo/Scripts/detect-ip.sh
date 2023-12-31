# /bin/sh
set -ex

DEST="$METAL_LIBRARY_OUTPUT_DIR"

if ipconfig getifaddr en0 >/dev/null; then
    IP=`ipconfig getifaddr en0`
    DOMIAN=$IP.xip.io
else
    IP="127.0.0.1"
    DOMIAN="localhost"
fi

PLISTBUDDY='/usr/libexec/PlistBuddy'
PLIST=$TARGET_BUILD_DIR/$INFOPLIST_PATH

check_localhost() {
    if $PLISTBUDDY -c "Print NSAppTransportSecurity:NSExceptionDomains:localhost:NSTemporaryExceptionAllowsInsecureHTTPLoads" $PLIST >/dev/null; then
        echo "exist localhost"
    else
        echo "add localhost"
        $PLISTBUDDY -c "Add NSAppTransportSecurity:NSExceptionDomains:localhost:NSTemporaryExceptionAllowsInsecureHTTPLoads bool true" $PLIST
    fi
}

check_ip() {
    if $PLISTBUDDY -c "Print NSAppTransportSecurity:NSExceptionDomains:$DOMIAN:NSTemporaryExceptionAllowsInsecureHTTPLoads" $PLIST ; then
        echo "exist $DOMIAN"
    else
        echo "add $DOMIAN"
        $PLISTBUDDY -c "Add NSAppTransportSecurity:NSExceptionDomains:$DOMIAN:NSTemporaryExceptionAllowsInsecureHTTPLoads bool true" $PLIST
    fi
}

# 模拟器
if [[ "$PLATFORM_NAME" == "iphonesimulator" ]]; then
    check_localhost
fi

# Debug的真机调试
if [[ "$CONFIGURATION" = "Debug" && "$PLATFORM_NAME" != "iphonesimulator" ]]; then
    check_localhost
    check_ip
    echo "$DOMIAN" > "$DEST/ip.txt"
fi
