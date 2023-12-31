#!/bin/sh

set -x

current_dir=$(pwd)
src_dir=$current_dir/ByteRTCSDK
cd $src_dir

# build_config=Debug
build_config=Release
rtc_version=5.9.0.1

all_arches="x86_64 arm64 armv7"
for arch in $all_arches; do
	rm -fr build_ios/$arch
	cmake -GXcode -B build_ios/$arch -DRTC_PLATFORM=ios \
		-DRTC_ENABLE_MEETING=ON \
		-DRTC_CPP_EXCEPTION=ON \
		-DRTC_PROFILE_VC=ON \
		-DRX_PROFILE_VC=ON \
		-DRTC_STATIC_LIB=1 \
		-DRTC_STATIC_BYTEAUDIO=TRUE \
		-DRTC_IOS_ENABLE_LTO=1 \
		-DRTC_SDK_VERSION=$rtc_version \
		-DRTC_IOS_ARCHS=$arch .
	if [[ "$arch" == "x86_64" ]]; then
		sdk=iphonesimulator
	else
		sdk=iphoneos
	fi
	cd build_ios/$arch
	xcodebuild -project VolcEngine.xcodeproj -scheme VolcEngineRTC -configuration $build_config -sdk $sdk -jobs $(sysctl -n hw.ncpu)
	lipo -thin $arch -output $build_config/librealx_video_main-thin.a $build_config/librealx_video_main.a
	lipo -info $build_config/librealx_video_main-thin.a
	cd -
done

cd $current_dir
rm -fr third_party
mkdir -p third_party
cd third_party
cp -r $src_dir/realx/third_party/prebuilt/ios/* .
cp -r $src_dir/realx/third_party/boringssl-src/include boringssl/
all_libs="boya jsoncpp srtp2 protobuf-lite z realx_base realx_audio_main realx_network_main realx realx_engine byteaudio_engine byteaudio_static webrtc_p2p"
for lib in $all_libs; do
	mkdir -p $lib/lib
	lipo -create -output "${lib}/lib/lib${lib}.a"  $src_dir/build_ios/x86_64/$build_config/lib${lib}.a \
		$src_dir/build_ios/armv7/$build_config/lib${lib}.a \
		$src_dir/build_ios/arm64/$build_config/lib${lib}.a
done

mkdir -p realx_video_main/lib
lipo -create -output "realx_video_main/lib/librealx_video_main.a"  $src_dir/build_ios/x86_64/$build_config/librealx_video_main-thin.a \
	$src_dir/build_ios/armv7/$build_config/librealx_video_main-thin.a \
	$src_dir/build_ios/arm64/$build_config/librealx_video_main-thin.a

set +x
