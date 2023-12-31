#!/bin/sh

set -x

./patch_for_xcode_13.3.sh

current_dir=$(pwd)
src_dir=$current_dir/ByteRTC
framework_dir=$current_dir/framework
cd $src_dir

# build_config=Debug
build_config=Release
rtc_version=5.11.0.1

output_dir=build_ios/podspec
rm -fr $output_dir
mkdir -p $output_dir/.cmake/api/v1/query
cd $output_dir/.cmake/api/v1/query
touch codemodel-v2
cd -
cmake -GXcode -B $output_dir -DRTC_PLATFORM=ios \
-DRTC_ENABLE_MEETING=ON \
-DRTC_CPP_EXCEPTION=ON \
-DRTC_PROFILE_VC=ON \
-DRX_PROFILE_VC=ON \
-DRTC_STATIC_LIB=1 \
-DRTC_STATIC_BYTEAUDIO=TRUE \
-DRTC_IOS_ENABLE_LTO=1 \
-DRTC_SDK_VERSION=$rtc_version \
-DRTC_IOS_ARCHS=arm64 .

# from rtc/cmake/ios.cmake
rm -fr $framework_dir
mkdir -p $framework_dir/Headers
cp $output_dir/helpers/VolcEngineRTC.module.modulemap $framework_dir/module.modulemap
cp $output_dir/helpers/VolcEngineRTC.h $framework_dir/Headers/
cp $src_dir/sdk/ios/ByteRtcEngineKit/Info.plist $framework_dir/Info.plist

rtc_native_dir=$framework_dir/Headers/native/rtc
mkdir -p $rtc_native_dir
cp src/sdk/native/rtc/*.h $rtc_native_dir
cp src/sdk/native/meeting/*.h $rtc_native_dir
cp sdk/ios/ByteRtcEngineKit/Headers/*.h $rtc_native_dir

rtc_objc_dir=$framework_dir/Headers/objc/rtc
mkdir -p $rtc_objc_dir
cp src/sdk/objc/rtc/*.h $rtc_objc_dir
cp sdk/ios/ByteRtcEngineKit/ByteRtcMeetingEngineKit.h $rtc_objc_dir
cp sdk/ios/ByteRtcEngineKit/ByteRtcMeetingEngineKitDefines.h $rtc_objc_dir
cp sdk/ios/ByteRtcEngineKit/ByteRtcMeetingEngineEventHandler.h $rtc_objc_dir
cp sdk/ios/ByteRtcEngineKit/ByteRtcEngineKitDefines.h $rtc_objc_dir

# from cmake/modules/rts.cmake
rts_native_dir=$framework_dir/Headers/native/rts
mkdir -p $rts_native_dir
cp src/sdk/native/rts/*.h $rts_native_dir

# from cmake/modules/transcode.cmake
live_objc_dir=$framework_dir/Headers/objc/live
mkdir -p $live_objc_dir
cp src/sdk/objc/live/*.h $live_objc_dir

set +x
