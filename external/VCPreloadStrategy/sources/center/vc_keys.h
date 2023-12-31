//
//  vc_keys.h

#ifndef vc_keys_h
#define vc_keys_h
#pragma once

#include "vc_base.h"
#include <string>

VC_NAMESPACE_BEGIN

typedef enum : int {
    VCKeyIntValue = 1,
    VCKeyDeviceMachineCap = 2,
    VCKeyDeviceHDRInfo = 3,
    VCKeyDeviceScreenWidth = 4,
    VCKeyDeviceScreenHeight = 5,
    VCKeyDeviceId = 6,
    VCKeyInfoReuseType = 10,
    VCKeyAppState = 11,

    /// player --int
    VCKeyPlayerPlaybackPosition = 101,
    VCKeyPlayerVideoFrameRate = 102,
    VCKeyPlayerPlaybackState = 103,
    VCKeyPlayerVideoBitrate = 104,
    VCKeyPlayerAudioBitrate = 105,
    VCKeyPlayerSourceIsLocalFile = 106,
    VCKeyPlayerPreciseCache = 107,
    VCKeyPlayerPlayRange = 108,
    VCKeyPlayerRangeMode = 109,
    VCKeyPlayerFirstFrameDuration = 110, // first frame duration
    VCKeyPlayerMaxCacheSeconds = 112,
    VCKeyPlayerMaskDelayLoading = 113,
    VCKeyPlayerMaskEnableRange = 114,

    /// media --int
    VCKeyMediaVideoSelectBitrate = 201,
    VCKeyMediaAudioSelectBitrate = 202,
    VCKeyMediaLikeNum = 203,
    VCKeyMediaCommentNum = 204,
    VCKeyMediaShareNum = 205,
    VCKeyMediaIsPlaceholder = 206,
    VCKeyMediaIsPlaying = 207,
    VCKeyMediaCategory = 208,
    VCKeyMediaSubIndex = 209,
    VCKeyMediaIsPrepare = 210,

    /// representation --int
    VCKeyRepresentationWidth = 401,
    VCKeyRepresentationHeight = 402,
    VCKeyRepresentationBitrate = 403,
    VCKeyRepresentationMdatOffset = 404,

    /// loader info --int
    VCKeyLoaderInfoTaskStatus = 601,
    VCKeyLoaderInfoDownloadType = 602,
    VCKeyLoaderInfoTotalDownloadTime = 604,
    VCKeyLoaderInfoBitrate = 609,
    VCKeyLoaderInfoSegmentIndex = 610,
    VCKeyLoaderInfoMDLAccess = 612,

    /// setting --int
    VCKeyInteractionBlockDurationPreloaded = 801,
    VCKeyInteractionBlockDurationNonPreloaded = 802,
    VCKeyModuleBandwidthSwitch = 803,
    VCKeyModuleSelectBitrateSwitch = 804,
    VCKeyModulePreloadSwitch = 805,
    VCKeyModulePlayLoadSwitch = 806,
    VCKeyModuleAbrSwitch = 807,
    VCKeyAllPreloadFinishedMessage = 808,
    VCKeyEnableIoDecision = 809,

    /// Business status --int
    VCKeyBusinessAppState = 1001,
    VCKeyBusinessBandwidthQueueSize = 1002,
    VCKeyBusinessPortraitChanged = 1003,

    /// run info
    VCKeySceneTotalRecordCount = 1201,
    VCKeyNetStateChanged = 1202,

    /** ----- int64 ----- */
    VCKeyInt64Value = 10000,
    VCKeyAppStateTS = 10001,

    /// representation --int64
    VCKeyRepresentationFileSize = 10201,

    /// iomanager --int64
    VCKeyIOManagerGetFileSize = 10401,
    VCKeyIOManagerGetFileCache = 10402,
    VCKeyIOManagerGetFileCacheSize = 10403,

    /// player --int64
    VCKeyPlayerVideoMaxCacheSize = 10601,
    VCKeyPlayerAudioMaxCacheSize = 10602,
    VCKeyPlayerGetCurVideoCacheMS = 10603,
    VCKeyPlayerGetCurAudioCacheMS = 10604,
    VCKeyPlayerGetCurVideoCacheSize = 10605,
    VCKeyPlayerGetCurAudioCacheSize = 10606,
    VCKeyPlayerGetCurCacheVideoOffset = 10607,
    VCKeyPlayerGetCurCacheAudioOffset = 10608,

    /// loader info --int64
    VCKeyLoaderInfoSegmentTS = 10802,
    VCKeyLoaderInfoByteStart = 10803,
    VCKeyLoaderInfoByteEnd = 10804,
    VCKeyLoaderStartTimeMS = 10805,
    VCKeyLoaderInfoDownloadSize = 10806,
    VCKeyLoaderInfoFileSize = 10807,
    VCKeyLoaderInfoMaxDownloadSize = 10808,

    /** ----- float ----- */
    VCKeyFloatValue = 20000,
    VCKeyPlayerPlaybackSpeed = 20001,

    /// loader info --float
    VCKeyLoaderInfoSegmentDurationMS = 20201,

    /// media --float
    VCKeyMediaDuration = 20201,

    /// run info --float
    VCKeyNetworkSpeedBitPerSec = 20401,

    /** ----- string ----- */
    VCKeyStringValue = 30000,

    /// media --string
    VCKeyMediaId = 30201,
    VCKeyMediaFormat = 30202,
    VCKeyMediaPlayingVideoFileHash = 30203,
    VCKeyMediaPlayingAudioFileHash = 30204,
    VCKeyMediaFirstSubMediaId = 30205,

    /// representation --string
    VCKeyRepresentationCodec = 30401,
    VCKeyRepresentationQuality = 30402,
    VCKeyRepresentationMediaType = 30403,
    VCKeyRepresentationFileId = 30404,
    VCKeyRepresentationFileHash = 30405,
    VCKeyRepresentationDefinition = 30406,
    VCKeyRepresentationPCDNVerifyUrl = 30407,

    /// App --string
    VCKeyAppId = 30601,
    VCKeyAppName = 30602,

    /// loader info --string
    VCKeyLoaderInfoMediaId = 30801,
    VCKeyLoaderInfoFormat = 30802,
    VCKeyLoaderInfoMediaType = 30803,
    VCKeyLoaderInfoQuality = 30804,
    VCKeyLoaderInfoStreamId = 30805,
    VCKeyLoaderInfoCacheKey = 30806,

    /// configure --string
    VCKeyConfigAlgoStart = 31000,
    VCKeyConfigAlgoCommon = 31001,
    VCKeyConfigAlgoSmartPreload = 31002,
    VCKeyConfigAlgoPreloadTimeliness = 31003,
    VCKeyConfigAlgoPlayLoad = 31004,
    VCKeyConfigAlgoPlayRange = 31005,
    VCKeyConfigAlgoSelectBitrate = 31006,
    VCKeyConfigAlgoBandwidth = 31007,
    VCKeyConfigAlgoModuleConfig = 31008,
    VCKeyConfigAlgoSmartRange = 31009,
    VCKeyConfigAlgoPreload = 31010,
    VCKeyConfigAlgoDynamic = 31011,
    VCKeyConfigAlgoOption = 31012,
    VCKeyConfigDynamicTimeInfo = 31013,
    VCKeyConfigDynamicPreload = 31014,
    VCKeyConfigDynamicPlayLoad = 31015,
    VCKeyConfigDynamicPlayRange = 31016,
    VCKeyConfigDynamicSelectBitrate = 31017,

    /// Business status --string
    VCKeyPreloadSmartRetUpdate = 31201,
    VCKeyPreloadTimelinessRetUpdate = 31202,
    VCKeyPreloadSmartConfigJsonUpdate = 31203,
    VCKeySmartRangeRequestUpdate = 31204,
    VCKeyAppPreloadCancelAll = 31205,
    VCKeyConfigPeakSetting = 31206,
    VCKeyAppTraceHostUpdate = 31207,
    VCKeySettingInfoUpdate = 31208,
    VCKeyConfigSetCacheDir = 31209,
    VCKeySerializedDataUpdate = 31210,
    VCKeyConfigAppSessionID = 31211,
    VCKeySerializedKeyValue = 31212, // key-value data.
    VCKeyEngineNetScore = 31213,

    /// Preload log inf --string
    VCKeyGetPreloadStrategyLogInfo = 31301,

    /** ----- ptr ----- */
    VCKeyPointerValue = 40000,

    /** ----- option ----- */
    VCKeyGlobalOptionStart = 50000,
    VCKeyOptionStopBackground = 50001,
    VCKeyOptionStopTaskEndPlay = 50002,
    VCKeyOptionCacheTimestamp = 50003,
    VCKeyOptionCheckExitedLC = 50004,
    VCKeyOptionCheckOriginLC = 50005,
    VCKeyOptionSelectBitrateMode = 50006,
    VCKeyOptionAllPreloadFinishMessage = 50007,
    VCKeyOptionEnableIoDecision = 50008,
    VCKeyOptionAutoResumeTaskWhenPlay = 50009,
    VCKeyOptionPauseIOWhenRequestEnd = 50010,
    VCKeyOptionEnableUseCacheFlag = 50011,
    VCKeyOptionEnableContextForPlayer = 50012,
    VCKeyOptionEnableRangeStartMsg = 50013,
    /// value:1, strategy suspend;2 manager suspend.
    VCKeyOptionBackgroundCode = 50014,
    /// default is 60s.
    VCKeyOptionBackgroundTTL = 50015,
    VCKeyOptionPlayRecordPersistentNum = 50016,
    VCKeyOptionPlayRecordScene = 50017,
    VCKeyOptionBandwidthSampleRate = 50018,
    VCKeyOptionEnableMP3Support = 50019,
    VCKeyGlobalOptionEnd = 60000,

} VCKey;

typedef enum : int {
    VCPlaybackStateUnknown = 0,
    VCPlaybackStateInitializing = 1,
    VCPlaybackStateLoading = 2,
    VCPlaybackStateBuffer = 3,
    VCPlaybackStatePlaying = 4,
    VCPlaybackStateSeeking = 5,
    VCPlaybackStatePausing = 6,
    VCPlaybackStateEnded = 7,
    VCPlaybackStateError = 8,
    VCPlaybackStateSwitching = 9,
} VCPlaybackState;

namespace KeyUtil {
int ToPlayerKey(VCKey key);
int ToIOManagerKey(VCKey key);

std::string PlayerEvent(int playerEvent);
std::string IOCenterKey(int key);
std::string IOTaskKey(int key);
std::string PlaybackState(int state);
std::string ToAlgoConfig(int key);
} // namespace KeyUtil

VC_NAMESPACE_END

#endif /* vc_keys_h */
