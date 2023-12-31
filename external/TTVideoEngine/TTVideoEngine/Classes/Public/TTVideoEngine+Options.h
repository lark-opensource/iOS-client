//
//  TTVideoEngine+Options.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/4.
//

#import "TTVideoEngine.h"

typedef NSNumber *VEKKeyType;
#ifndef VEKKEY
#define VEKKEY(key) @(key)
#endif

/// VEKKey
/// Use these keys, set value correspond the key, also get value correspod the key.
/// Please use marco VEKKEY(key), example: VEKKEY(VEKKeyPlayerHardwareDecode_BOOL)
typedef NS_ENUM(NSInteger, VEKKey)
{
    /// Player
    VEKKeyPlayer                                           = 1,
    /* HardwareDecode switch. */
    VEKKeyPlayerHardwareDecode_BOOL                        = 2,
    /* KsyByteVC1Decode switch. */
    VEKKeyPlayerKsyByteVC1Decode_BOOL                      = 3,
    /* ByteVC1 switch. */
    VEKKeyPlayerByteVC1Enabled_BOOL                        = 4,
    /* Whether to support dash. */
    VEKKeyPlayerDashEnabled_BOOL                           = 5,
    VEKKeyPlayerSmoothlySwitching_BOOL                     = 6,
    /* Loop sswitch. */
    VEKKeyPlayerLooping_BOOL                               = 7,
    /* Async init player switch. */
    VEKKeyPlayerAsyncInit_BOOL                             = 8,
    /* Async prepare player switch. */
    VEKKeyPlayerAsyncPrepare_BOOL                          = 9,
    /* Muted switch. */
    VEKKeyPlayerMuted_BOOL                                 = 10,
    /* Volume. */
    VEKKeyPlayerVolume_CGFloat                             = 11,
    /* Begin play time.*/
    VEKKeyPlayerStartTime_CGFloat                          = 12,
    /* Loop start time. */
    VEKKeyPlayerLoopStartTime_CGFloat                      = 13,
    /* Loop end time. */
    VEKKeyPlayerLoopEndTime_CGFloat                        = 14,
    /* Play speed. */
    VEKKeyPlayerPlaybackSpeed_CGFloat                      = 15,
    /* Embellish volume milliseconds.
     The max value is 1000, default 0 */
    VEKKeyPlayerEmbellishVolumeMilliseconds_NSInteger      = 16,
    /* Player network timeout. */
    VEKKeyPlayerOpenTimeOut_NSInteger                      = 17,
    /** Smoothly switch delayed seconds. */
    VEKKeyPlayerSmoothDelayedSeconds_NSInteger             = 18,
    /** Test speed model. only vod
     Value type is TTVideoEngineTestSpeedMode. */
    VEKKeyPlayerTestSpeedMode_ENUM                         = 19,
    /** Whether to reuse socket */
    VEKKeyPlayerReuseSocket_BOOL                           = 20,
    /** Disable accurate start time, used in dash video */
    VEKKeyPlayerDisableAccurateStart_BOOL                  = 21,
    /* Audio Device
     Value type is TTVideoEngineAudioDeviceType. */
    VEKKeyPlayerAudioDevice_ENUM                           = 22,
    /* Maximum number of seconds to cache local resources */
    VEKKeyPlayerCacheMaxSeconds_NSInteger                  = 23,
    /* Buffering  timeout*/
    VEKKeyPlayerBufferingTimeOut_NSInteger                 = 24,
    /* Buffering  endtime*/
    VEKKeyPlayerMaxBufferEndTime_NSInteger                 = 25,
    /* Loop way: 0,Engine;1,Kernel*/
    VEKKeyPlayerLoopWay_NSInteger                          = 26,
    /** Whether to use boe*/
    VEKKeyPlayerBoeEnabled_BOOL                            = 27,
    /* Whether to support bash. */
    VEKKeyPlayerBashEnabled_BOOL                           = 28,
    /* Whether to support https. */
    VEKKeyPlayerHttpsEnabled_BOOL                          = 29,
    /* Whether to check hijack. */
    VEKKeyPlayerCheckHijack_BOOL                           = 30,
    /* Whether enable hijack retry. */
    VEKKeyPlayerHijackRetryEnable_BOOL                     = 31,
    /* Whether to seek end. */
    VEKKeyPlayerSeekEndEnabled_BOOL                        = 32,
    /* Whether to report request headers. */
    VEKKeyPlayerReportRequestHeaders_BOOL                  = 33,
    /* Whether to report response headers. */
    VEKKeyPlayerReportResponseHeaders_BOOL                 = 34,
    /* Whether to use cache duration calc buffer percentage*/
    VEKKeyPlayerTimeBarPercentage_BOOL                     = 35,
    /* Whether to enable dash abr */
    VEKKeyPlayerEnableDashAbr_BOOL                         = 36,
    /* Whether to enable index cache */
    VEKKeyPlayerEnableIndexCache_BOOL                      = 37,
    /* Whether to enable frag range */
    VEKKeyPlayerEnableFragRange_BOOL                       = 38,
    /* Whether to enable async */
    VEKKeyPlayerEnableAsync_BOOL                           = 39,
    /* Range mode */
    VEKKeyPlayerRangeMode_ENUM                             = 40,
    /* Video range size */
    VEKKeyPlayerVideoRangeSize_NSInteger                   = 41,
    /* Audio range size */
    VEKKeyPlayerAudioRangeSize_NSInteger                   = 42,
    /* Video range time */
    VEKKeyPlayerVideoRangeTime_NSInteger                   = 43,
    /* Audio range time */
    VEKKeyPlayerAudioRangeTime_NSInteger                   = 44,
    /* skip find stream info */
    VEKKeyPlayerSkipFindStreamInfo_BOOL                    = 45,
    /* Whether to enable tt hls drm */
    VEKKeyPlayerTTHLSDrm_BOOL                              = 46,
    /* tt hls drm token */
    VEKKeyPlayerTTHLSDrmToken_NSString                     = 47,
    /* idle timer controller by engine */
    VEKKeyPlayerIdleTimerAuto_NSInteger                    = 48,
    /* Whether to enter buffering directly to ease playstall */
    VEKKeyEnterBufferingDirectly_BOOL                      = 49,
    /* OutputFrames  wait*/
    VEKKeyPlayerOutputFramesWaitNum_NSInteger              = 50,
    /* Audio Buffer Threshold to start play */
    VEKKeyPlayerStartPlayAudioBufferThreshold_NSInteger    = 51,
    /* Audio Effect */
    VEKKeyPlayerAudioEffectEnable_BOOL                     = 52,
    /* Auidio Effect Parameter for pre gain*/
    VEKKeyPlayerAudioEffectPregain_CGFloat                 = 53,
    /* Auidio Effect Parameter for threshold*/
    VEKKeyPlayerAudioEffectThreshold_CGFloat               = 54,
    /* Auidio Effect Parameter for ratio*/
    VEKKeyPlayerAudioEffectRatio_CGFloat                   = 55,
    /* Auidio Effect Parameter for pre delay*/
    VEKKeyPlayerAudioEffectPredelay_CGFloat                = 56,
    /* Memory Optimize */
    VEKKeyPlayerMemoryOptimize_BOOL                        = 57,
    /* Use Audio Unit Pool*/
    VEKKeyPlayerAudioUnitPoolEnable_BOOL                   = 58,
    /* Audio Video start render in sync mode.
     First frame audio rendering waiting for video decode and video render open */
    VEKKeyPlayerAVSyncStartEnable_BOOL                     = 59,
    /* Thread wait time ms */
    VEKKeyThreadWaitTimeMS_NSInteger                       = 60,
    /* Drop skipped frame to accelerate video decode during seek*/
    VEKKeyCodecDropSkippedFrame_BOOL                       = 61,
    /* Auidio Effect Parameter for post gain*/
    VEKKeyPlayerAudioEffectPostgain_CGFloat                = 62,
    /* ABR timer interval */
    VEKKeyPlayerABRTimerIntervalMilliseconds_NSInteger     = 63,
    /* add option for disable dummy audio sleep  */
    VEKKeyPlayerDummyAudioSleep_BOOL                       = 64,
    /* An Engine uses a serial queue */
    VEKKeyPlayerUseEngineQueue_BOOL                        = 65,
    /* Read mode */
    VEKKeyPlayerReadMode_ENUM                              = 66,
    /* Default Buffering  endtime*/
    VEKKeyPlayerDefaultBufferEndTime_NSInteger             = 67,
    /* enable sr */
    VEKKeyPlayerEnableNNSR_BOOL                            = 68,
    /* Read mode */
    VEKKeyPlayerNNSRFPSThreshold_NSInteger                 = 69,
    /* Update timestamp mode */
    VEKKeyPlayerUpdateTimestampMode_ENUM                   = 70,
    /* Open timeout */
    VEKKeyPlayerEnableOpenTimeout_BOOL                     = 71,
    /* Decoder Output Buffer Type*/
    VEKKeyPlayerDecoderOutputBufferType_ENUM               = 72,
    /* Prepare Max Cache Ms*/
    VEKKeyPlayerPrepareMaxCacheMs_NSInteger                = 73,
    /* MDL Cache Mode*/
    VEKKeyPlayerMDLCacheMode_NSInteger                     = 74,
    /* Http AutoRange Offset*/
    VEKKeyPlayerHttpAutoRangeOffset_NSInteger              = 75,
    /* move seek in demuxer read */
    VEKKeyPlayerLazySeek_BOOL                              = 76,
    /*abr 4G maxResolution*/
    VEKKeyPlayerABR4GMaxResolution                         = 77,
    /**abr switch mode*/
    VEKKeyPlayerDashABRSwitchMode                          = 78,
    /* enable range */
    VEKKeyPlayerEnableRange_BOOL                           = 79,
    /* Whether to support barrage mask. */
    VEKKeyPlayerBarrageMaskEnabled_BOOL                    = 80,
    /**mp4 segment format flag eg: dash format*/
    VEKeyPlayerSegmentFormatFlag                           = 81,
    /**enable barrage mask thread*/
    VEKeyPlayerEnableBarrageMaskThread_BOOL                = 82,
    /* Auidio Effect Parameter for ratio*/
    VEKKeyPlayerAudioEffectTargetLoudness_CGFloat          = 83,
    /* Auidio Effect Parameter for pre delay*/
    VEKKeyPlayerAudioEffectType_NSInteger                  = 84,
    VEKKeyPlayerAudioEffectSrcLoudness_CGFloat             = 85,
    VEKKeyPlayerAudioEffectSrcPeak_CGFloat                 = 86,
    VEKKeyPlayerNormalClockType_NSInteger                  = 87,
    /* All resolution sr */
    VEKKeyPlayerEnableAllResolutionSR_BOOL                 = 88,
    /** Skip buffer limit. */
    VEKKeyPlayerSkipBufferLimit_NSInteger                  = 89,
    /** Report All  Buffer Update*/
    VEKKeyPlayerReportAllBufferUpdate_BOOL                 = 90,
    /** Ignore buffer start before first frame */
    VEKKeyPlayerNotifyBufferBeforeFirstFrame_BOOL          = 91,
    /** set use server decoding mode hw or sw*/
    VEKKeyPlayerServerDecodingModePriority_BOOL            = 92,
    /** Enable av stack */
    VEKKeyPlayerEnableAVStack_BOOL                         = 93,
    /** Terminal AudioUnit Pool */
    VEKKeyPlayerTerminalAudioUnitPool_BOOL                 = 94,
    /** Set Audio Output queue by Audio Duration Time*/
    VEKKeyAudioLatencyQueueByTime_BOOL                     = 95,
    VEKKeyVideoEndIsAllEof_BOOL                            = 96,
    /** Enable ms buffering*/
    VEKKeyPlayerEnableBufferingMilliSeconds_BOOL           = 97,
    /** Default ms buffering time */
    VEKKeyPlayersDefaultBufferingEndMilliSeconds_NSInteger = 98,
    /** Max ms buffering time */
    VEKKeyPlayersMaxBufferEndMilliSeconds_NSInteger        = 99,
    /** Whether to support subtitle. */
    VEKKeyPlayerSubEnabled_BOOL                            = 100,
    /** enable sub thread*/
    VEKeyPlayerEnableSubThread_BOOL                        = 101,
    VEKKeyDecreaseVtbStaskSize_NSInteger                   = 102,
    /**post prepare message*/
    VEKKeyPlayerPostPrepareMsg                             = 103,
    /** Disable short seek */
    VEKKeyDisableShortSeek_BOOL                            = 104,
    /*demuxer prefer nearst sample*/
    VEKKeyPlayerPreferNearestSampleEnable                  = 105,
    /*demuxer prefer nearst sample maxpos offset*/
    VEKKeyPlayerPreferNearestMaxPosOffset                  = 106,
    VEKKeyPlayerEnable720pSP_BOOL                          = 107,
    /* Keep player formater thread alive */
    VEKKEYPlayerKeepFormatAlive_BOOL                       = 108,
    /** Find stream info probe size */
    VEKKeyPlayerFindStreamInfoProbeSize_NSInteger          = 109,
    /** Find stream info probe duration */
    VEKKeyPlayerFindStreamInfoProbeDuration_NSInteger      = 110,
    /* Codec Type */
    VEKKeyPlayerCodecType_ENUM                             = 111,
    VEKKeyPlayerMaxAccumulatedErrCount_NSInteger           = 112,
    VEKKeyPlayerFFCodecerHeaacV2Compat_BOOL                = 113,
    /** enable hdr10*/
    VEKKeyPlayerHDR10VideoModelLowBound_NSInteger          = 114,
    VEKKeyPlayerHDR10VideoModelHighBound_NSInteger         = 115,
    VEKKeyPlayerPreferSpdlForHDR_BOOL                      = 116,
    VEKKeyPlayerStopSourceAsync_BOOL                       = 117,
    VEKKeyPlayerSeekInterrupt_BOOL                         = 118,
    VEKKeyPlayerBackGroundPlay_BOOL                        = 119,
    VEKKeyPlayerEnableRefreshByTime_BOOL                   = 120,
    VEKKeyPlayerEnableFallbackSWDecode_BOOL                = 121,
    VEKKeyPlayerAudioEffectForbidCompressor_BOOL           = 122,
    VEKKeyPlayerUpdateClockWithOffset_BOOL                 = 123,
    VEKKeyPlayerChangeVtbSizePicSizeBound_NSInteger        = 124,
    VEKKeyPlayerHandleBackgroundInAVView_BOOL              = 125,
    VEKKeyPlayerLazyAudioUnitOp_BOOL                       = 126,
    VEKKeyPlayerEnableRangeCacheDuration_BOOL              = 127,
    VEKKeyPlayerEnableVoiceSplitHeaacV2_BOOL               = 128,
    VEKKeyPlayerEnableAudioHardwareDecode_BOOL             = 129,
    VEKKeyPlayerDelayBufferingUpdate_BOOL                  = 130,
    VEKKeyPlayerNoBufferingUpdate_BOOL                     = 131,
    VEKKeyPlayerKeepVoiceDuration_BOOL                     = 132,
    VEKKeyPlayerVoiceBlockDuration_NSInteger               = 133,
    VEKeyPlayerCheckInfo_NSString                          = 134,
    VEKKeyPlayerSetSpdlForHDRUrl_BOOL                      = 135,
    VEKKeyPlayerEnableSRBound_BOOL                         = 136,
    VEKKeyPlayerSRLongDimensionLowerBound_NSInteger        = 137,
    VEKKeyPlayerSRLongDimensionUpperBound_NSInteger        = 138,
    VEKKeyPlayerSRShortDimensionLowerBound_NSInteger       = 139,
    VEKKeyPlayerSRShortDimensionUpperBound_NSInteger       = 140,
    VEKKeyPlayerLiveStartIndex_NSInteger                   = 141,
    VEKKeyPlayerFilePlayNoBuffering_BOOL                   = 142,
    VEKKeyPlayerEnableAVStack_NSInteger                    = 143,
    VEKKeyPlayerMaskStopTimeout_NSInteger                  = 144,
    VEKKeyPlayerSkipSetSameWindow_BOOL                     = 145,
    VEKKeyPlayerCacheVoiceId_BOOL                          = 146,
    VEKKeyVtbFlushKeepSesssion_BOOL                        = 147,
    VEKKeyPlayerSubtitleStopTimeout_NSInteger              = 148,
    VEKKeyCurrentVideoQualityType_NSInteger                = 149,
    VEKKeyPlayerEnableVtbDropRASL_BOOL                     = 150,
    VEKKeyPlayerCheckVoiceInBufferingStart_BOOL            = 151,
    VEKKeyPlayerOpenVoiceInPrepare                         = 152,
    VEKKeyPlayerAllAVViewHoldBackground                    = 153,
    VEKKeyPlayerEnableNewOutlet_BOOL                       = 154,
    VEKKeyPlayerSubtitleOptEnable_BOOL                     = 155,
    VEKKeyPlayerEnableDisplayP3_BOOL                       = 156,
    VEKKeyPlayerEnableVideoTimestampMonotonic_BOOL         = 157,
    VEKKeyPlayerEnableFlushSeek_BOOL                       = 158,
    VEKKeyPlayerEnableGetTimeOptimize                      = 159,
    VEKKeyPlayerGetVideoCodecTypeId_NSInteger              = 160,
    VEKKeyPlayerGetAudioCodecTypeId_NSInteger              = 161,
    VEKKeyPlayerGetVideoCodecName_NSString                 = 162,
    VEKKeyPlayerGetAudioCodecName_NSString                 = 163,
    VEKKeyPlayerSubtitleOpenRetryTimes_NSInteger           = 164,
    VEKKeyPlayerHLSSeamlessSwitchEnable_BOOL               = 165,
    VEKKeyPlayerEnableRecreateSubIfDetached_BOOL           = 166,
    VEKKeyPlayerSubtitleFormatQuery_NSString               = 167,
    /** Position update intervsal */
    VEKKeyPlayerPositionUpdateInterval_NSInteger           = 168,
    VEKKeyAVOutsyncCallback_BOOL                           = 169,
    /** optimize blue tooth connection */
    VEKKeyPlayerOptBlueToothRenderSync_BOOL                = 170,
    /** voice writing time out multiple */
    VEKKeyPlayerVoiceWriteTimeoutMultiple_NSInteger        = 171,
    /** limited times skipping for failed judging */
    VEKKeyPlayerAudioSkipLimitedTimes_NSInteger            = 172,
    /// Precise control of the player's cache.
    VEKKeyPlayerPreciseCache_NSInteger                     = 173,
    /// Force use asyn pause even if going or in background
    VEKKeyPlayerForceAsyncPause_BOOL                       = 174,
    /// Enable auto resolution selection while playing
    VEKKeyPlayerEnableAutoResolution_BOOL                  = 175,
    VEKKeyPlayerEnableOutletDropLimit_BOOL                 = 176,
    /* Enable Video 1.5 SR */
    VEKKeyPlayerEnableVideo15SR_BOOL                       = 177,
    /** switch audio info for TTS */
    VEKKeyPlayerSwitchAudioInfoId_NSInteger                = 178,
    /** ttplayer thread-safe ref turn-on value, use TTVideoEngineThreadSafeRefFlag */
    VEKKeyPlayerEnableThreadSafeRef_NSInteger              = 179,
    /** opt sub rendering search */
    VEKKeyPlayerEnableOptSubSearch_BOOL                    = 180,
    /** support custom av_voice buffer size setting */
    VEKKeyPlayerKeepDurationBufferSize_NSInteger           = 181,
    /** set max fps decoding to software decoder */
    VEKKeyPlayerSetMaxFps_NSInteger                        = 182,
    VEKKeyPlayerClockResumeResetEof_BOOL                   = 183,
    /// Log UIResponder stack on play
    VEKKeyPlayerEnableUIResponderLogOnPlay_BOOL            = 184,
    /* Revert Aoutlet cpu optimize*/
    VEKKeyPlayerAOutletCPUTest_BOOL                        = 185,
    /** enable directly buffering render start report */
    VEKKeyPlayerEnableBufferingDirectlyRenderStartReport_BOOL = 186,
    /** enable directly buffering ms */
    VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds_BOOL = 187,
    /** directly buffering ms time*/
    VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds_NSInteger = 188,
    /** enable directly buffering send video packet*/
    VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket_BOOL = 189,
    /** cache metal device, create device once */
    VEKKeyPlayerCacheMetalDevice_BOOL       = 190,
    /** fix voice latency, better av sync in seek case */
    VEKKeyPlayerFixVoiceLatency_BOOL        = 191,
    /** opera event report control*/
    VEKKeyPLayerOperaEventReportLevel_NSInteger = 192,
    /** enable demuxer non-block read */
    VEKKeyPlayerEnableDemuxNonBlockRead_BOOL = 193,
    /** enable deinterlace */
    VEKKeyPlayerEnableDeinterlace_BOOL = 194,
    /**  enable startup select with gear strategy */
    VEKKeyPlayerEnableGearStrategy_BOOL = 195,
    /** set precise pause pts */
    VEKKeyPlayerSetPrecisePausePts_int64_t = 196,
    /** control how many frames to drop before render 1 frame when av outsync */
    VEKKeyPlayerSetFramesDrop_NSInteger = 197,
    /** recheck vpls for directly buffering */
    VEKKeyPlayerRecheckVPLSforDirectBuffering_BOOL = 198,
    VEKKeyEnginePoolIsFromEnginePool_NSString = 199,
    VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger = 200,
    VEKKeyEnginePoolCorePoolSizeBeforeGetEngine = 201,
    VEKKeyEnginePoolCountEngineInUse = 202,
    VEKKeyStrategyRangeControlOverride_BOOL = 203,
    VEKKeyStrategyAutoAddMedia_BOOL = 204,
    VEKeyPlayerMaskEnableDataloader_BOOL = 205,
    
    /// tob begin
    ///
    ///
    /** Image rotation type.Value type is TTVideoEngineImageRotaionType */
    VEKKeyImageRotateType_ENUM            = 206,
    //Value type is TTVideoEngineAudioChannelType
    VEKKeyAudioChannelEffect_ENUM         = 207,
    
    VEKKeyIsCustomizedVideoRenderingFrameRate = 235,
    VEKKeyIsEnableVsyncHelper = 236,
    ///
    ///
    ///
    /// tob end
    ///
    VEKKeyHookVoiceType_BOOL = 208,
    VEKKeyEnableReportPreloadTraceId_BOOL = 209,
    //remove engine.taskQueue for ABTest
    VEKKeyEnableRemoveEngineTaskQueue_BOOL = 210,
    //enable player post start
    VEKKeyEnablePlayerPostStart_BOOL = 211,
    //enable preloadGear
    VEKKeyEnablePlayerPreloadGear_BOOL = 212,
    //enable get player req offset
    VEKKeyEnableGetPlayerReqOffset_NSInteger = 213,
    
    /// View
    VEKKeyView                            = 1 << 8,
    /** Image scale type.
     Value type isTTVideoEngineImageScaleType */
    VEKKeyViewImageScaleType_ENUM         = 257,
    /* Picture enhancement type. only vod
     Value type is TTVideoEngineEnhancementType */
    VEKKeyViewEnhancementType_ENUM        = 258,
    /* Image layout type.
     Value type is TTVideoEngineImageLayoutType */
    VEKKeyViewImageLayoutType_ENUM        = 259,
    /* Content scale mode.
     Value type is TTVideoEngineScalingMode */
    VEKKeyViewScaleMode_ENUM              = 260,
    /* Render type.
     Value type is TTVideoEngineRenderType */
    VEKKeyViewRenderType_ENUM             = 261,
    /* Render engine.
     Value type is TTVideoEngineRenderEngine */
    VEKKeyViewRenderEngine_ENUM           = 262,
    /* Rotate type.
     Value type is TTVideoEngineRotateType */
    VEKKeyViewRotateType_ENUM             = 263,
    /* Mirror type.
     Value type is TTVideoEngineMirrorType */
    VEKKeyViewMirrorType_ENUM             = 264,
    /* switch subtitle language */
    VEKeyPlayerSwitchSubtitleId_NSInteger = 265,
    /* language query of subtitle request */
    VEKeyPlayerSubtitleIdQuery_NSString   = 266,
    /* optimize audio and video interweaving problem*/
    VEKKeyPlayerEnableMp4Check_NSInteger = 267,
    /** enable open AI Barrage function thread */
    VEKeyPlayerEnableAIBarrageThread_BOOL = 268,
    /** enable AI Barrage call back */
    VEKKeyPlayerAIBarrageEnabled_BOOL = 269,

    /// Model
    VEKKeyModel                                    = 1 << 9,
    VEKKeyModelResolutionServerControlEnabled_BOOL = 513,
    /** Cache video info, Defut NO */
    VEKKeyModelCacheVideoInfoEnable_BOOL           = 514,
    /** Support for setting expired VideoModel. */
    VEKKeyModelSupportExpired_BOOL                 = 515,
    /** Use fallbackapi to retry after the url expires. */
    VEKKeyModelUseFallbackApi_BOOL                 = 516,
    /** NSURLSession use ephemeral config.*/
    VEKKeyModelURLSessionUseEphemeral_BOOL         = 517,
    /** Use fallbackapi to retry after the url expires by MDL */
    VEKKeyModelFallbackApiMDLRetry_BOOL            = 518,
    /// DNS
    VEKKeyDNS                                      = 1 << 10,
    /* Use player DNS resolver switch. */
    VEKKeyDNSIsUsingAVResolver_BOOL                = 1025,
    /** Whether to use dns cache*/
    VEKKeyPlayerDnsCacheEnabled_BOOL               = 1026,
    /* dns expired time*/
    VEKKeyPlayerDnsCacheSecond_NSInteger           = 1027,
    /* hijack retry main dns type */
    VEKKeyPlayerHijackRetryMainDnsType_ENUM        = 1028,
    /* hijack retry backup dns type */
    VEKKeyPlayerHijackRetryBackupDnsType_ENUM      = 1029,
    /**post prepare way 0 engine, 1 kernal*/
    VEKKeyPlayerPostPrepareWay  = 1030,
    /**  enable play callback cache hit size 0 close, 1 enable */
    VEKKeyPlayerEnablePlayCallbackCacheHitSize  = 1031,

    /// Cache
    VEKKeyCache                                    = 1 << 11,
    /* Cache playing data switch.
     Can save network traffic if loop */
    VEKKeyCacheCacheEnable_BOOL                    = (1 << 11) + 1,
    /* User extern directory switch. */
    VEKKeyCacheUseExternDirEnable_BOOL             = (1 << 11) + 2,
    /* The directory of cache data.
     Play video use vid, and need cache video data when play finished
     Set cache data directory. */
    VEKKeyCacheExternCacheDir_NSString             = (1 << 11) + 3,
    /* Limit a media resource cache size when using dataloader.*/
    VEKKeyCacheLimitSingleMediaCacheSize_NSInteger = (1 << 11) + 4,
    VEKKeyPreloadUpperBufferMS_NSInteger           = (1 << 11) + 5,
    VEKKeyPreloadLowerBufferMS_NSInteger           = (1 << 11) + 6,
    VEKKeyPreloadEnablePlayDurationCheck           = (1 << 11) + 7,
    VEKKeyPreloadEnableCheckInTimer_BOOL           = (1 << 11) + 8,
    VEKKeyEnableClearMdlCache_BOOL                 = (1 << 11) + 9,

    /// Log
    VEKKeyLog                                    = 1 << 12,
    /* Log tag. */
    VEKKeyLogTag_NSString                        = (1 << 12) + 1,
    /* Log SubTag. */
    VEKKeyLogSubTag_NSString                     = (1 << 12) + 2,
    /* Performance log switch. */
    VEKKeyLogPerformanceSwitch_BOOL              = (1 << 12) + 3,
    /* custom str log. */
    VEKKeyLogCustomStr_NSString                  = (1 << 12) + 4,
    /// Decrypt
    VEKKeyDecrypt                                = 1 << 13,
    /* The key of decryption. */
    VEKKeyDecryptDecryptionKey_NSString          = (1 << 13) + 1,
    /* The encrypted key of decryption. */
    VEKKeyDecryptEncryptedDecryptionKey_NSString = (1 << 13) + 2,
    /// Key of medialoader
    VEKKeyMedialoader                            = 1 << 14,
    /// enable medialoader switch.
    VEKKeyMedialoaderEnable_BOOL                 = (1 << 14) + 1,
    /// native mode of medialoader switch
    VEKKeyMedialoaderNativeEnable_BOOL           = (1 << 14) + 2,
    /// Proxy server
    VEKKeyProxyServer                            = VEKKeyMedialoader,
    /// proxy server switch.
    VEKKeyProxyServerEnable_BOOL                 = VEKKeyMedialoaderEnable_BOOL,
    // enable native mdl seek reopen
    VEKKeyNativeMdlEnableSeekReopen_BOOL         = (1 << 14) + 3,
    //cdn type
    VEKKeyMediaLoaderCdnType_NSInteger           = (1 << 14) + 4,
    // pcdn timer
    VEKKeyMediaLoaderPcdnTimer_NSInteger         = (1 << 14) + 5,
    // forbidp2p
    VEKKeyMediaLoaderForbidP2p_BOOL              = (1 << 14) + 6,
    // native mdl only for transcoded
    VEKKeyNativeMdlEnableCheckTranscode_BOOL     = (1 << 14) + 7,
    
    ///tob begin   (1 << 14) + (1 << 13)
    ///
    ///
    ///
    /* choose video seek mode, the value type is TTVideoEngineSeekModeType,
     default TTVideoEngineSeekModeAccurateAny */
    VEKKeyPlayerSeekMode_ENUM                        = (1 << 14) + (1 << 13),
    /// enable HLSProxy for m3u8 cache 
    VEKKeyHLSProxyProtocolEnable_BOOL                = (1 << 14) + (1 << 13) + 7,
    /// enable play speed extend
    VEKKeyPlaySpeedExtendEnable_BOOL                 = (1 << 14) + (1 << 13) + 8,
    ///
    ///
    ///
    ///
    ///
    ///tob end
    
    /// Drm
    /* Drm type */
    VEKKeyDrmType_ENUM                 = 1 << 15,
    /* Drm downgrade */
    VEKKeyDrmDowngrade_NSInteger       = (1 << 15) + 1,
    /* Drm retry */
    VEKKeyDrmRetry_BOOL                = (1 << 15) + 2,
    /* Drm token url template */
    VEKKeyDrmTokenUrlTemplate_NSString = (1 << 15) + 3,
    
    
    
    /// Direct Int Option set Before prepare
    ///
    /// Just Add new key between min and max,
    /// Make sure the key value is same as the one in TTPlayerDef.h
    /// don't need any other code
    VEKKeyDirIntMinGuard_NSInteger  = 40001,
    /// enable heaacv2 pts 1ms correction
    /// VEKKeyEnableHEAACV2PtsMSCorrection_BOOL = 40001,
    /// enable metal asyn commit and set timeout
    VEKKeyMetalCommitTimeout_NSInteger = 40002,
    /**enable ioSurface render*/
    VEKKeyPlayerEnableiOSurfaceRender_BOOL = 40003,
    /** clip heaacv2 first pts packet*/
    VEKKeyPlayerClipHEAACV2FirstPkt_BOOL   = 40004,
    /** enable bvc1 opt*/
    VEKKeyPlayerEnableCPPBYTEVC1CodecOpt_BOOL   = 40005,
    /** buffering check required duration of voice queue number */
    VEKKeyPlayerVoiceRequiredDuration_NSInteger = 40006,
    /** switcher for video dynamic frame dropping */
    VEKKeyPlayerEnableDynamicFrameDropping_BOOL   = 40007,
    /** multiple of frame dropping condition */
    VEKKeyPlayerDroppingFrameMultiple_NSInteger = 40008,
    /** dynamic frame dropping check period */
    VEKKeyPlayerDroppingCheckPeriod_NSInteger   = 40009,
    /** enable outleter sense buffering start/end */
    VEKKeyPlayerOutleterSenseBuffering_BOOL     = 40010,
    /** bluetooth optimization only works on pause->resume scene */
    VEKKeyPlayerBTOptOnlyWorksOnPause_BOOL      = 40011,
    /** bluetooth optimization effective time when last switcher is on */
    VEKKeyPlayerBTOptEffectiveTime_NSInteger    = 40012,
    /** bluetooth opt enable drop voice queue header node */
    VEKKeyPlayerVoiceDropHeaderNode_BOOL        = 40013,
    VEKKeyPlayerEnableFastStop_BOOL             = 40014,
    VEKKeyPlayerHEAACV2PtsMSCorrection_BOOL     = 40016,
    /**postprepare start moment 0 after prepared, 1 after opend*/
    VEKKeyPlayerIsPostPrepareCallStartMoment_NSInteger  = 40017,
    /**enable metal iosurface*/
    VEKKeyPlayerMetalVideoiOSurface             = 40018,
    VEKKeyPlayerEnableStartTimeSkipAVSkipSerial = 40019,
    VEKKeyDynamicDroppingCheckCount             = 40020,
    VEKKeyBTOptAddConsumingTime_BOOL            = 40021,
    VEKKeyEnablexHEAACSupport_BOOL              = 40022,
    VEKKeyPlayerPreDemuxAutoPause_BOOL          = 40023,
    VEKKeyPlayerEnableDemuxerRecycle_BOOL       = 40024,
    VEKKeyPlayerEnableCodecRecycle_BOOL         = 40025,
    VEKKeyPlayerEnableFilterRecycle_BOOL        = 40026,
    VEKKeyPlayerEnablePlayerRecycle_BOOL        = 40027,
    VEKKeyPlayerAOutletFastStop_BOOL            = 40028,
    VEKKeyPlayerVOutletFastStop_BOOL            = 40029,
    VEKKeyPlayerAGraphFastStop_BOOL             = 40030,
    VEKKeyPlayerADecoderFastStop_BOOL           = 40031,
    VEKKeyPlayerVDecoderFastStop_BOOL           = 40032,
    VEKKeyPlayerReaderFastStop_BOOL             = 40033,
    VEKKeyPlayerPostPauseAfterClose_BOOL        = 40034,
    VEKKeyUnlimitHeaderSize_BOOL                = 40035,
    VEKKeyPostResume_BOOL                       = 40036,
    VEKKeyDecodeAACThroughFDKAAC_BOOL           = 40037,
    VEKKeyStopCloseIO_BOOL                      = 40038,
    VEKKeyOnlyPlayAudioForBothStream_BOOL       = 40039,
    VEKKeyIsAudioEOSDelayDiscontinuousSleep_BOOL= 40040,
    VEKKeyIsEnableDrawableSizeInMinVideoView    = 40042,
    VEKKeyIsEnableProcessorCrop                 = 40043,
    VEKKeyEnableBufferingLowerCapacity_BOOL     = 40044,
    VEKKeySupportFastStopCancelWait_BOOL        = 40045,
    VEKKeyEnableHWDropFrameWhenVOIsInDropState_NSInteger = 40046,
    VEKKeyEnableHWDropFrameWhenAVOutSyncing_NSInteger    = 40047,
    VEKKeyCodecFramesDrop_NSInteger                      = 40048,
    VEKKeyEnableMaskDelayLoading_BOOL                    = 40049,
    VEKKeyIsEnableVideoBmf_BOOL                 = 40050,
    VEKKeyIsKeyCheckVtbMaxRefFrame              = 40051,
    VEKKeyIsEnableVideoSoftBmfSr                = 40052,
    VEKKeyIsMetalPauseNoLock                    = 40053,
    /// Enable mask range option
    VEKKeyEnableMaskEnableRange_BOOL            = 40055,
    VEKKeyIsEnableMetalViewDoubleBuffering      = 40057,
    VEKKeyIsThreadNamePad2Char_NSInteger        = 40058,
    VEKKeyIsEnableDemuxerRWLock                 = 40059,
    VEKKeyIsEnableAVVoiceReuse_NSInteger        = 40060,
    VEKKeyIsTestDeviceAfterPause_BOOL           = 40063,
    VEKKeyIsEnableSBDLayerDirectly_BOOL         = 40066,
    VEKKeyIsBMFSRALGORITH                   = 40067,
    VEKKeyIsEnableBMFSrSync                 = 40068,
    VEKKeyIsSubtitleSenseBuffering          = 40069,
    VEKKeyIsDisableVoiceReuseOnPause_BOOL    = 40071,
    VEKKeyIsEnableSubtitleLazyLoading_BOOL   = 40072,
    VEKKeyIsEnableCorrectRealClock_BOOL         = 42004,
    VEKKeyOutletThreadOptimize_NSInteger        = 42027,
    VEKKeyDirIntMaxGuard_NSInteger              = 49999,
}; /// The max value is (1<<20 - 1)

/// VEKGetKey
/// Use these keys, only get info
/// Please use marco VEKKEY(key), example: VEKKEY(VEKGetKeyPlayerVideoWidth_NSInteger)
typedef NS_ENUM(NSInteger, VEKGetKey)
{
    /// PLayer
    VEKGetKeyPlayer                            = 1 << 20,
    /* Video picture width, from video metadata. */
    VEKGetKeyPlayerVideoWidth_NSInteger        = (1 << 20) + 1,
    /* Video picture height, from video metadata. */
    VEKGetKeyPlayerVideoHeight_NSInteger       = (1 << 20) + 2,
    /* Size of Media data, from video metadata. only vod
     Use owner player*/
    VEKGetKeyPlayerMediaSize_LongLong          = (1 << 20) + 3,
    /* metadata of player. valid for own player */
    VEKGetKeyPlayerMetadata_NSDictionary       = (1 << 20) + 4,
    /* bitrate from player */
    VEKGetKeyPlayerBitrate_LongLong            = (1 << 20) + 5,
    /* Rendering frame rate */
    VEKGetKeyPlayerVideoOutputFPS_CGFloat      = (1 << 20) + 6,
    /* Video coded frame rate */
    VEKGetKeyPlayerContainerFPS_CGFloat        = (1 << 20) + 7,
    /* Bytes read by the player */
    VEKGetKeyPlayerPlayBytes_int64_t           = (1 << 20) + 8,
    /* Timstamp of the first frame. */
    VEKGetKeyFirstFrameTimestamp_NSDictionary  = (1 << 20) + 9,
    /* Video current pts in milliseconds */
    VEKGetKeyPlayerVideoCurrentTime_NSInteger  = (1 << 20) + 10,
    /* Video sr width */
    VEKGetKeyPlayerVideoSRWidth_NSInteger      = (1 << 20) + 11,
    /* Video sr height */
    VEKGetKeyPlayerVideoSRHeight_NSInteger     = (1 << 20) + 12,
    /* Get file format */
    VEKGetKeyFileFormat_NSString               = (1 << 20) + 13,
    /* Get Audio Codec Id */
    VEKGetKeyPlayerAudioCodecId_NSInteger      = (1 << 20) + 14,
    /* Get Video Codec Id */
    VEKGetKeyPlayerVideoCodecId_NSInteger      = (1 << 20) + 15,
    /* Get Audio Codec Profile */
    VEKGetKeyPlayerAudioCodecProfile_NSInteger = (1 << 20) + 16,
    /* Get Video Codec Profile */
    VEKGetKeyPlayerVideoCodecProfile_NSInteger = (1 << 20) + 17,
    /* Get whether audio effect is enabled  */
    VEKGetKeyPlayerAudioEffectOpened_BOOL      = (1 << 20) + 18,
    VEKGetKeyPlayerSessionId_NSString          = (1 << 20) + 19,
    /* audio bitrate from player */
    VEKGetKeyPlayerAudioBitrate_LongLong       = (1 << 20) + 20,
    /* Get if Stream is enabled. Get the value when or after `videoEnginePrepared`
     * Notice: stream enabled is different to stream existing.
     * If stream enabled, it must be existing.
     * If stream is not existing, it must be not enabled.
     * If strean is existing, it can be not enabled
     */
    VEKGetKeyVideoEnabled_BOOL                 = (1 << 20) + 21,
    VEKGetKeyAudioEnabled_BOOL                 = (1 << 20) + 22,
    /* stream track info */
    VEKGetKeyStreamTrackInfo_NSString             = (1 << 20) + 23,
    /* video area frame pattern*/
    VEKGetKeyVideoAreaFrame_LongLong             = (1 << 20) + 24,

    /// Model
    VEKGetKeyModel                          = 1 << 21,
    /* Size of video data, from model info. */
    VEKGetKeyModelVideoSize_NSInteger       = (1 << 21) + 1,
    /// Metrics
    VEKGetKeyMetrics                        = 1 << 22,
    /// First frame metrics.
    VEKGetKeyMetricsFirstFrame_NSDictionary = (1 << 22) + 1,
    /** Get precise cache log */
    VEKGetKeyMetricsPreciseCache_NSDictionary = (1 << 22) + 2,
    /// Error
    VEKGetKeyError                          = 1 << 23,
    /// Player error info.
    VEKGetKeyErrorPlayerInfo_NSString       = (1 << 23) + 1,
}; /// The min value is (1<<20),and max value is (1 << 31);

/// @interface  option check end
/// TTVideoEngine Key about global static settings
typedef NS_ENUM(NSInteger, VEKGSKey)
{
    VEGSKeyUseBaseThread_BOOL = 0,
    VEGSKeyUseThreadPool_BOOL = 1,
    VEGSKeyThreadPoolSize_INT = 2,
    VEGSKeyThreadSafeRefSwitcher_INT = 3,
    VEGSKeyEnableGlobalMuteFeature   = 4,
    VEGSKeyGlobalMute                = 5, // is start global mute
    VEGSKeyLooperOpenWait_BOOL       = 6,
    VEGSKeyQosLooper_BOOL            = 7,
    VEGSKeyLooperDetach_BOOL         = 8,
    VEGSKeyVoiceReusePoolSize        = 10,
    VEGSKeyVoicePoolStopAllMembers   = 11,
    VEGSKeyDemuxerBox_BOOL                      = 12,
    VEGSKeyVoiceReuseEnableChangeSampleNB_BOOL  = 13,
    VEGSKeySBDLHoldBackground_BOOL              = 14,
    VEGSKeyThreadV2_BOOL                        = 15,
    
    /// engine key begin ....
    /// Default is NO.
    VEGSKeyIgnoreMTLDeviceCheck_BOOL = 5001,
    
    //abr
    VEGSKeyABRPreloadJsonParams_NSString      = 5002,
    VEGSKeyABRStartupJsonParams_NSString      = 5003,
    VEGSKeyABRFlowJsonParams_NSString         = 5004,
    
    VEGSKeyAlgoGlobalOptionStart = 50000,  /// TTVideoEngineStrategyAlgoGlobalOptionStart
    VEGSKeyAlgoOptionStopBackground = 50001,
    VEGSKeyAlgoOptionStopTaskEndPlay = 50002,
    VEGSKeyAlgoOptionCacheTimestamp = 50003,
    VEGSKeyAlgoOptionCheckExitedLC = 50004,
    VEGSKeyAlgoOptionCheckOriginLC = 50005,
    VEGSKeyAlgoOptionSelectBitrateMode = 50006,
    VEGSKeyAlgoOptionAllPreloadFinishMessage = 50007,
    VEGSKeyAlgoOptionEnableIoDecision = 50008,
    VEGSKeyAlgoOptionAutoResumeTaskWhenPlay = 50009,
    VEGSKeyAlgoOptionPauseIOWhenRequestEnd = 50010,
    VEGSKeyAlgoOptionEnableUseCacheFlag = 50011,
    VEGSKeyAlgoOptionEnableContextForPlayer = 50012,
    VEGSKeyAlgoGlobalOptionEnd = 60000,      /// TTVideoEngineStrategyAlgoGlobalOptionEnd
};

//videoprocessor key value
typedef NS_ENUM(NSInteger,VEKFilterType) {
    VEKFilterTypeEmpty,
    VEKFilterTypeDefault,
    VEKFilterTypeLookupTable,
    VEKFilterTypeYUVtoRGB,
    VEKFilterTypeLens,
    VEKFilterTypeCrop,
    VEKFilterTypeRGBtoYUV,
    VEKFilterTypeVR,
    VEKFilterTypeBMFVideoSRLut,
    VEKFilterTypeGaussianBlur,
};
typedef NS_ENUM(NSInteger, VEKProcessorOptions) {
    VEKProcessorInitEffect,
    VEKProcessorIsFilterUsing,
    VEKProcessorUseEffect,
    VEKProcessorUseLens,
    VEKProcessorUpdateImage,
    VEKProcessorFilterStrength,
    VEKProcessorWidth,
    VEKProcessorHeight,
    VEKprocessorYUVtoRGBMatrix,
    VEKProcessorFilterCrop,
    VEKProcessorVROutputTextureSize,
    VEKProcessorVRConfiguration,
    VEKProcessorVRRecenter,
    VEKProcessorFilterAlpha,
};
static NSString *const VEKProcessorEffectTypeStr = @"kProcessorEffectType";
static NSString *const VEKProcessorActionStr = @"kProcessorAction";
static NSString *const VEKProcessorLutBitmapStr = @"kProcessorLutBitmap";
static NSString *const VEKProcessorIntValueStr = @"kProcessorIntValue";
static NSString *const VEKProcessorUseEffectStr = @"kProcessorUseEffect";
static NSString *const VEKProcessorFloatValueStr = @"kProcessorFloatValue";
static NSString *const VEKProcessorIndexStr = @"kProcessorIndex";
static NSString *const VEKProcessorGeneralValueStr = @"kProcessorGeneralValue";//非基本类型数值
static NSString *const VEKProcessorStreamTypeStr = @"kProcessorStreamType";
static NSString *const VEKProcessorMultiModeStr = @"kProcessorMultiMode";
static NSString *const VEKProcessorCurrentModeStr = @"kProcessorCurrentMode";
static NSString *const VEKProcessorEnable15SRStr = @"kProcessorEnable15SR";

NS_ASSUME_NONNULL_BEGIN
@interface TTVideoEngine (Options)
/**
 Get option that you care about.
 Example: get video width.
 NSInteger videoWidth = [[self getOptionBykey:VEKKEY(VEKGetKeyPlayerVideoWidth_NSInteger)] integerValue];
              |                                  |                    |           |
            value                             Gen key               Field      valueType
 @param key Please use VEKKEY(key) to prodect a valid key.
 @return Value correspod the key. The key include value type.
 */
- (id)getOptionBykey:(VEKKeyType)key;

/**
 Set options by VEKKey
 Example:
 [self setOptions:@{VEKKEY(VEKKeyPlayerTestSpeedMode_ENUM):@(TTVideoEngineTestSpeedModeContinue)}];
                      |                   |          |                          |
                Generate key            Field     valueType                   value
 @param options key is one of VEKKeys, value defined id type.
 */
- (void)setOptions:(NSDictionary<VEKKeyType, id> *)options;

/// key is a type of VEKKey or VEKGetKey.
- (void)setOptionForKey:(NSInteger)key value:(id)value;

+ (void)setGlobalForKey:(VEKGSKey)key value:(id)value;

/// when engine was giveback to enginePool, it should reset all options to make itself a pure engine.
- (void)resetOptions;

@end

/// Will move to private file.
@interface TTVideoEngine ()

/**
 default 0, max value: 1000
 */
@property (nonatomic, assign) NSInteger embellishVolumeMilliseconds;

/**
 enable ksyByteVC1Decode
 */
@property (nonatomic, assign) BOOL ksyByteVC1Decode;

/**
 enable bytevc1
 */
@property (nonatomic, assign) BOOL byteVC1Enabled;

/**
 smoothly switching resolution
 */
@property (nonatomic, assign) BOOL smoothlySwitching;

/**
 set init ttplayer in async mode,default is false
 */
@property (nonatomic, assign) BOOL asyncInit;

/**
 set prepare ttplayer in async mode,default is false
 */
@property (nonatomic, assign) BOOL asyncPrepare;

/**
 set start play time
 */
@property (nonatomic, assign) NSTimeInterval startTime;

/**
 set loop start time
 */
@property (nonatomic, assign) NSTimeInterval loopStartTime;

/**
 set loop end time
 */
@property (nonatomic, assign) NSTimeInterval loopEndTime;

/**
 smoothly switch delayed seconds, default is -1
 */
@property (nonatomic, assign) NSInteger smoothDelayedSeconds;

/**
 set using avresolver or not
 */
@property (nonatomic, assign, readwrite) BOOL isUsingAVResolver;

/**
 decryptionKey
 */
@property (nonatomic, nullable, copy) NSString *decryptionKey;

/**
 encoded decryption key
 */
@property (nonatomic, nullable, copy) NSString *encryptedDecryptionKey;

/**
 resolution server control enabled
 */
@property (nonatomic, assign) BOOL resolutionServerControlEnabled;

@property (nonatomic, assign) TTVideoEngineTestSpeedMode testSpeedMode;

/**
 image scale model, default linear
 */
@property (nonatomic, assign) TTVideoEngineImageScaleType imageScaleType;

/**
 image enhancement, default none
 */
@property (nonatomic, assign) TTVideoEngineEnhancementType enhancementType;

/**
 image layout. set into openGLES
 */
@property (nonatomic, assign) TTVideoEngineImageLayoutType imageLayoutType;

/**
 view contentMode. not set into openGLES
 */
@property (nonatomic, assign) TTVideoEngineScalingMode scaleMode;

/**
  view alignMode, default TTVideoEngineAlignModeCenter
 */
@property (nonatomic, assign) TTVideoEngineAlignMode alignMode;

/**
  view align ratio,  work only when alignMode is TTVideoEngineAlignModeSelfDefineRatio, default 0.5, range 0 to 1
 */
@property (nonatomic, assign) CGFloat alignRatio;

/**
 render type, plane, pano ...
 */
@property (nonatomic, assign) TTVideoEngineRenderType renderType;

/**
 render engine type: openGL, Metal. Metal only support iPhone 5s above && A7 chip above.
 Simulator not support Metal engine type.
 */
@property (nonatomic, assign) TTVideoEngineRenderEngine renderEngine;

/**
 get from response of play API server. setVid && preloadItem can get a value.
 */
@property (nonatomic, assign, readonly) NSInteger videoSize;

/**
 get from video metadata, all video source can get the size if use own player
 */
@property (nonatomic, assign, readonly) long long mediaSize;

/**
 get hijack code
 */
@property (nonatomic, assign, readonly) NSInteger hijackCode;

/**
 Cache video info, Defut NO
 */
@property (nonatomic, assign) BOOL cacheVideoInfoEnable;

/**
 enable extern dir
 */
@property (nonatomic, assign) BOOL useExternDirEnable;

/**
 enable extern dir
 */
@property (nonatomic, nullable, copy) NSString *externCacheDir;

/**
 reuse socket
 */
@property (nonatomic, assign) BOOL reuseSocket;

/**
 enable dash
 */
@property (nonatomic, assign) BOOL dashEnabled;

/**
 disable accurate start time, used in dash video
 */
@property (nonatomic, assign) BOOL disableAccurateStart;

/**
 open network timeout
 */
@property (nonatomic, assign) NSInteger openTimeOut;

/**post prepare*/
@property (nonatomic, assign) BOOL isEnablePostPrepareMsg;

/**postprepare way 0 engine 1 kernal*/
@property (nonatomic, assign) BOOL postprepareWay;

/**
 demuxer mov find_next_sample use prefer nearst sample enable
 */
@property (nonatomic, assign) BOOL preferNearstSampleEnable;

/**
 the max pos offset between audio and video for demuxer mov find_next_sample use prefer nearst
 sample for
 */
@property (nonatomic, assign) NSInteger preferNearstSampleMaxPosOffset;

/**
 enable background play, change states in audioRenderStart
 */
@property (nonatomic, assign) BOOL isEnableBackGroundPlay;

@property (nonatomic, assign) BOOL isEnablePlayCallbackHitCacheSize;

@property (nonatomic, assign) CGRect normalizeCropArea;

@property (nonatomic, assign) NSInteger isEnableVsyncHelper;

@property (nonatomic, assign) NSInteger customizedVideoRenderingFrameRate;


- (void)setTag:(NSString *)tag;

/**
 get video width
 @return video display width
 */
- (NSInteger)getVideoWidth;

/**
 get video height
 @return video display height
 */
- (NSInteger)getVideoHeight;


- (BOOL) getStreamEnabled:(TTVideoEngineStreamType) type;

@end

NS_ASSUME_NONNULL_END
