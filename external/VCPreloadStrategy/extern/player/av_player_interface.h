//
// Created by teddy on 11/30/20.
//

#pragma once
#include "av_player_event.h"
#include "av_player_event_base.h"
PEV_NAMESPACE_BEGIN

// copied from av_player_value.h
#define IGNORE_MDL_CACHE 0xFFFF

typedef enum : int {
    PlayerPlaybackStateUnknown = 0,
    PlayerPlaybackStateInitializing = 1,
    PlayerPlaybackStateLoading = 2,
    PlayerPlaybackStateBuffer = 3,
    PlayerPlaybackStatePlaying = 4,
    PlayerPlaybackStateSeeking = 5,
    PlayerPlaybackStatePausing = 6,
    PlayerPlaybackStateEnded = 7,
    PlayerPlaybackStateError = 8,
    PlayerPlaybackStateSwitching = 9,
} PlayerPlaybackState;

typedef enum : int {
    // ---- int -------
    PlayerKeyValueInt = 1,
    PlayerKeyPlaybackPosition = 2,
    PlayerKeyVideoFrameRate = 3,
    PlayerKeyPlaybackState = 4,
    PlayerKeyVideoBitrate = 5,
    PlayerKeyAudioBitrate = 6,
    PlayerKeyVideoMaxCacheSize = 7,
    PlayerKeyAudioMaxCacheSize = 8,
    PlayerKeyIsFileProtocol = 9,
    PlayerKeyMediaDuration = 10,
    PlayerKeyPreciseCache = 11,
    PlayerKeyOpenTimeout = 12,
    PlayerKeyCacheMaxSeconds = 13,
    PlayerKeyHardwareDecode = 14,
    PlayerKeyPlayRange = 15,
    PlayerKeyEnableCacheTimeStamp = 16,
    PlayerKeyRangeMode = 17,
    PlayerKeyPreDecoderAutoPause = 18,
    PlayerKeyAsyncInitCodec = 19,
    PlayerKeyNetworkTimeout = 20,
    PlayerKeyBufferingTimeOut = 21,
    PlayerKeyEnterBufferingDirectly = 22,
    PlayerKeyDefaultBufferingEndMilliSeconds = 23,
    PlayerKeyMaxBufferEnd = 24,
    PlayerKeySettingRenderType = 25,
    PlayerKeyPostPrepare = 26,
    PlayerKeySeekLazyInRead = 27,
    PlayerKeyKeepFormatThreadAlive = 28,
    PlayerKeyDisableShortSeek = 29,
    PlayerKeyPreferNearestSample = 30,
    PlayerKeyEnableMp4Check = 31,
    PlayerKeyOptBlueToothRenderSync = 32,
    PlayerKeyEnableHWDropFrameWhenVOIsInDropState = 33,
    PlayerKeyEnableHWDropFrameWhenAVOutSyncing = 34,
    PlayerKeyPreDemuxAutoPause = 35,
    PlayerKeyUseCodecPool = 36,
    PlayerKeyEnableNativeYV12Render = 37,
    PlayerKeyDemuxerRecycle = 38,
    PlayerKeyCodecRecycle = 39,
    PlayerKeyFilterRecycle = 40, // deprecated
    PlayerKeyPlayerRecycle = 41, // deprecated
    PlayerKeyFastStop = 42,
    PlayerKeyAOutletFastStop = 43,
    PlayerKeyVOutletFastStop = 44,
    PlayerKeyAGraphFastStop = 45,
    PlayerKeyADecoderFastStop = 46,
    PlayerKeyVDecoderFastStop = 47,
    PlayerKeyReaderFastStop = 48,
    PlayerKeyUseDtsAsBufferLen = 49,
    PlayerKeyNetworkConnectCount = 50,
    PlayerKeyPostPauseAfterClose = 51,
    PlayerKeyUnlimitHeaderSize = 52,
    PlayerKeyPostResume = 53,
    PlayerKeyStopCloseIO = 54,
    PlayerKeyMediaCodecAudio = 55,
    PlayerKeyCheckVoiceInBufferingStart = 56,
    PlayerKeyEnableVideoSR = 57,
    PlayerKeyEnableAudioEffect = 58,
    PlayerKeyRenderType = 59,
    PlayerKeyImageScaleType = 60,
    PlayerKeyMediaCodecRender = 61,
    PlayerKeyQueryWinSizeEnable = 62,
    PlayerKeyEnableDashABR = 63,
    PlayerKeyEnableHDR10 = 64,
    PlayerKeyHttpAutoRangeOffset = 65,
    PlayerKeyHWDecDropNonRef = 66,
    PlayerKeyPositionUpdateInterval = 67,
    PlayerKeySkipFindStreamInfo = 68,
    PlayerKeyCodecFRCLevel = 69,
    PlayerKeySubEnable = 70,
    PlayerKeyBarrageMaskEnable = 71,
    PlayerKeyEnableOutletDropLimit = 72,
    PlayerKeyEnablethreadPrioroty = 73,
    PlayerKeyEnableAudioTrackSmoothClock = 74,
    PlayerKeyDisableSpiltVoiceWrite = 75,
    PlayerKeyEnableCPPBYTEVC1CodecOpt = 76,
    PlayerKeyEnableCPPBYTEVC2CodecOpt = 77,
    PlayerKeyMaxFps = 78,
    PlayerKeyEnableDynamicFrameDropping = 79,
    PlayerKeySkipAudioGraph = 80,
    PlayerKeyAIBarrageEnable = 81,
    PlayerKeyPrecisePausePts = 82,
    PlayerKeyNoBufferingUpdate = 83,
    PlayerKeyEnableDemuxNonBlockRead = 84,
    PlayerKeyMediaCodecAsyncEnable = 85,
    PlayerKeyEnableAudioMemIntergration = 86,
    PlayerKeyEnableBufferingLowerCapacity = 87,
    PlayerKeyEnableDowngradeAsyncCodec = 88,
    PlayerKeyEnableMediaCodecSyncClose = 89,
    PlayerKeyEnableSeekBuffering = 90,
    PlayerKeyCodecAndSurfaceReuse = 91,
    PlayerKeyReuseSocket = 92,
    PlayerKeyMetalPauseNoLock = 93,
    PlayerKeyMaskDelayLoading = 94,
    PlayerKeyMaskRangeOpt = 95,
    PlayerKeyEnableDemuxerRWLock = 96,
    KeyIsEnableAVVoiceReuse = 97,
    PlayerKeyVoiceRequiredDuration = 98,
    PlayerKeyDynamicDroppingCheckPeriod = 99,
    PlayerKeyDynamicDroppingFrameMultiple = 100,
    PlayerKeyDynamicDroppingCheckCount = 101,
    PlayerKeyAutoAudioDeviceChangeDetectionSI = 102,
    PlayerKeyVoiceStartFailedSenseSI = 103,

    // ---- float -------
    PlayerKeyValueFloat = 1000,
    PlayerKeyPlaybackSpeed = 1001,

    // ---- int64 -------
    PlayerKeyValueInt64 = 2000,
    PlayerKeyCurVideoCacheMS = 2001,
    PlayerKeyCurAudioCacheMS = 2002,
    PlayerKeyCurVideoCacheSize = 2003,
    PlayerKeyCurAudioCacheSize = 2004,
    PlayerKeyCurCacheVideoOffset = 2005,
    PlayerKeyCurCacheAudioOffset = 2006,

    // ---- string -------
    PlayerKeyValueString = 3000,
    PlayerKeyVideoFormat = 3001,
    PlayerKeyVideoMediaId = 3002,

    // ---- ptr -------
    PlayerKeyValuePtr = 4000,
    PlayerKeyLoadControl = 4001,
    PlayerKeySCContextInfo = 4002,

    //
    PlayerKeyValueForSCInt = 50000,
    //
    PlayerKeyValueForSCInt64 = 52000,

} PlayerValueKey;

typedef enum : int {
    VideoCodecIdUndefine = 0,
    VideoCodecIdByteVC0 = 1,
    VideoCodecIdByteVC1 = 2,
    VideoCodecIdByteVC2 = 3,
    VideoCodecIdByteVC3 = 4
} VideoCodecId;

class IPlayer {
public:
    IPlayer() = default;

    virtual ~IPlayer() {}

    virtual int getIntValue(PlayerValueKey key, int dValue) = 0;
    virtual float getFloatValue(PlayerValueKey key, float dValue) = 0;
    virtual int64_t getInt64Value(PlayerValueKey key, int64_t dValue) = 0;
    virtual char *getCStringValue(PlayerValueKey key, char *dValue) = 0;
    virtual int getValue(PlayerValueKey key, void *value, size_t size) = 0;
    virtual int
    setValue(PlayerValueKey key, const void *value, size_t size) = 0;
    virtual intptr_t getPtrValue(PlayerValueKey key) = 0;
    virtual int setIntValue(PlayerValueKey key, int value) = 0;
    virtual int setInt64Value(PlayerValueKey key, int64_t value) = 0;
    /// event callback
    virtual void setPlayerEventListener(IPlayerEvent *eventListener) = 0;
};

typedef enum : int {
    ContextInfoKeyInt = 0,

    ContextInfoKeyDouble = 2000,

    ContextInfoKeyInt64 = 4000,
    ContextInfoKeyCacheEndOffset = 4001,

    ContextInfoKeyString = 6000,

    ContextInfoKeyPtr = 8000,
} ContextInfoKey;

class IContextInfo {
public:
    IContextInfo() = default;
    virtual ~IContextInfo(){};
    //
    virtual int64_t getCacheInfo(void *fileKey, int key, int64_t dVal) = 0;
    //
    virtual int64_t getInt64Value(int key, int64_t dVal) = 0;
    virtual int getIntValue(int key, int dVal) = 0;
    virtual double getDoubleValue(int key, double dVal) = 0;
    virtual char *getCStringValue(int key, char *dVal) = 0;
    // associated player
    virtual int64_t getInt64Value(IPlayer *player, int key, int64_t dVal) = 0;
    virtual int getIntValue(IPlayer *player, int key, int dVal) = 0;
    virtual double getDoubleValue(IPlayer *player, int key, double dVal) = 0;
    virtual char *getCStringValue(IPlayer *player, int key, char *dVal) = 0;
};

extern IContextInfo *getSCContext();

PEV_NAMESPACE_END
