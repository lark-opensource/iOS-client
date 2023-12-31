#!/bin/sh

function patch_realx_flags {
sed -i "" "s/-Wno-error=overloaded-virtual #remove this asap/-Wno-error=overloaded-virtual #remove this asap\
\n            -Wno-error=unused-but-set-variable # error in Xcode 13.3\
\n            -Wno-error=unused-but-set-parameter # error in Xcode 13.3\
\n            -Wno-error=deprecated-copy # error in Xcode 13.3\
/" $1
}

cd ByteRTC

swift_version="$(swift --version)"
if [[ "$swift_version" == *"Apple Swift version 5.6"* ]]; then
    file_for_patch="cmake/realx_flags.cmake"
    if grep -q "\-Wno-error=unused-but-set-variable # error in Xcode 13.3" $file_for_patch
    then
        echo "already patched"
    else
        echo "patching cmake/realx_flags.cmake"
        patch_realx_flags $file_for_patch
    fi
else
    echo "skip patching for version: $swift_version"
fi

cd -