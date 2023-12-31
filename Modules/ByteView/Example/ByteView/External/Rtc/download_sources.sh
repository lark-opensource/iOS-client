#!/bin/sh

rm -fr ByteRTC

rtc_branch=release_3.38_rc
# rtc_branch=release_3.32_for_meeting_5.8_and_5.9_rc
#develop
git clone -b $rtc_branch git@code.byted.org:bytertc/ByteRTC.git
cd ByteRTC
git submodule update --init --recursive
