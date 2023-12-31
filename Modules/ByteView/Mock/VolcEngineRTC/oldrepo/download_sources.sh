#!/bin/sh

rm -fr ByteRTCSDK

rtc_branch=release_3.32_for_meeting_5.8_and_5.9_rc
# rtc_branch=release_3.32_for_meeting_5.8_and_5.9_rc
#develop
git clone -b $rtc_branch git@code.byted.org:bytertc/ByteRTCSDK.git
cd ByteRTCSDK
git submodule update --init --recursive
git clone -b $rtc_branch git@code.byted.org:bytertc/RealX.git realx

cd realx
#git submodule update --init --recursive
git submodule update --init $(< .mandatory_submodules 2>/dev/null)
