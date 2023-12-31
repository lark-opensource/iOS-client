//
// Created by 黄清 on 12/21/20.
//

#ifndef VIDEOENGINE_VC_DEFINE_H
#define VIDEOENGINE_VC_DEFINE_H
#pragma once

#include "vc_base.h"

VC_NAMESPACE_BEGIN

/// select bitrate
typedef enum : int {
    SelectBitratePlay = 1,
    SelectBitratePreload = 2,
    SelectBitrateVCPreload = 3,
} SelectBitrateType;

typedef enum : int {
    SelectBitrateModeNative = 1,
    SelectBitrateModeCallback = 2,
} SelectBitrateMode;

typedef enum : int {
    NetStateUnknown = -1,
    NetStateUnReachable = 0,
    NetStateWWAN = 10,
    NetStateWifi = 20,
} NetState;

typedef enum : int {
    AppStateForeground = 1,
    AppStateBackground = 2,
} AppState;

typedef enum : int {
    MediaCategoryNormal = 0,
    MediaCategoryAd = 1,
} MediaCategory;

// keep same with ttvideoengine dataloaderhelper.java
typedef enum : int {
    DEFAULT = 0,
    IDLE = 10,
    HIGH = 100,
    HIGHEST = 10000,
} PreloadTaskPriority;

namespace VCConstString {
extern const char *Format_MP4;
extern const char *Format_M4A;
extern const char *Format_MP3;
extern const char *Format_DASH;

extern const char *Stream_AUDIO;
extern const char *Stream_VIDEO;
extern const char *Stream_MASK;
extern const char *Stream_SUBTITLE;
extern const char *Stream_DUBBED_INFO;

extern const char *Quality_240P;
extern const char *Quality_360P;
extern const char *Quality_540P_LOW;
extern const char *Quality_540P;
extern const char *Quality_540P_HIGHT;
extern const char *Quality_720P_LOW;
extern const char *Quality_720P;
extern const char *Quality_720P_HIGHT;
extern const char *Quality_1080P;
extern const char *Quality_2K;
extern const char *Quality_4K;
} // namespace VCConstString

typedef enum : int {
    VCModuleTypeUnknown = 0,
    //
    VCModuleTypePreload = 1 << 0, /// 1
    VCModuleTypeABR = 1 << 1,     /// 2
    VCModuleTypeSelectBitrate = 1 << 2,
    VCModuleTypeBandwidth = 1 << 3,
    VCModuleTypePlayLoad = 1 << 4,
    VCModuleTypePlayRange = 1 << 5, /// 32
    VCModuleTypePlayBufferControl = 1 << 6,
    //
    VCModuleTypeTrace = 1 << 30,
    //
    VCModuleTypeAll = 0x7FFFFFFF,
} VCModuleType;

static inline VCModuleType operator|(VCModuleType lhs, VCModuleType rhs) {
    return static_cast<VCModuleType>(static_cast<int>(lhs) |
                                     static_cast<int>(rhs));
}

static inline VCModuleType operator&(VCModuleType lhs, VCModuleType rhs) {
    return static_cast<VCModuleType>(static_cast<int>(lhs) &
                                     static_cast<int>(rhs));
}

VC_NAMESPACE_END

#endif // VIDEOENGINE_VC_DEFINE_H
