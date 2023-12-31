//
//  TTVideoEngine+Options.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/4.
//

#import "TTVideoEngine+Options.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngineKeys.h"
#import "TTVideoEngineEventLoggerProtocol.h"
#import "TTVideoEngineUtilPrivate.h"
#import <TTPlayerSDK/TTAVPlayer.h>
#import "TTVideoEngineStrategy.h"
#import "TTVideoEnginePlayerDefine.h"


#ifndef __TTVIDEOENGINE_OPTION_ERROR__
#define __TTVIDEOENGINE_OPTION_ERROR__
#define ERROR_KEY  TTVideoEngineLogE(@"setOptions: or getOptionBykey:  key value error ~ ~ ");
#endif

@interface TTVideoEngine ()
@property (nonatomic,   copy) NSString *logInfoTag;
@property (nonatomic, assign) TTVideoEngineAudioDeviceType audioDeviceType;

- (NSDictionary *)getMetaData;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation TTVideoEngine (Options)

+ (void)setGlobalForKey:(VEKGSKey)key value:(id)value {
    switch (key) {
        case VEGSKeyIgnoreMTLDeviceCheck_BOOL:
            g_IgnoreMTLDeviceCheck = [value boolValue];
            break;
        case VEGSKeyEnableGlobalMuteFeature: {
            sEnableGlobalMuteFeature = [value boolValue];
            TTVideoEngineLogE(@"set enable global mute feature");
            [TTAVPlayer setGlobalValue:value forKey:(int)key];
            break;
        }
        case VEGSKeyGlobalMute: {
            TTVideoEngineLogE(@"set global mute %d",[value intValue]);
            if (!sGlobalMuteDic) {
                sGlobalMuteDic = [NSMutableDictionary dictionary];
                sGlobalKeyArray = [NSMutableArray array];
            }
            if (sGlobalMuteDic.count >= 1 && sGlobalKeyArray.count > 0) {
                id key = [sGlobalKeyArray firstObject];
                [sGlobalMuteDic removeObjectForKey:key];
                [sGlobalKeyArray removeObjectAtIndex:0];
            }
            int64_t curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
            sGlobalMuteDic[@(curT)] = value;
            [sGlobalKeyArray addObject:@(curT)];
            [TTAVPlayer setGlobalValue:value forKey:(int)key];
            break;
        }
        case VEGSKeyABRPreloadJsonParams_NSString: {
            gABRPreloadJsonParams = value;
            TTVideoEngineLogE(@"set gABRPreloadJsonParams: %@", gABRPreloadJsonParams);
            break;
        }
        case VEGSKeyABRStartupJsonParams_NSString: {
            gABRStartupJsonParams = value;
            TTVideoEngineLogE(@"set gABRStartupJsonParams: %@", gABRStartupJsonParams);
            break;
        }
        case VEGSKeyABRFlowJsonParams_NSString: {
            gABRFlowJsonParams = value;
            TTVideoEngineLogE(@"set gABRFlowJsonParams: %@", gABRFlowJsonParams);
            break;
        }
        default:
            if (key > VEGSKeyAlgoGlobalOptionStart && key < VEGSKeyAlgoGlobalOptionEnd) {
                TTVideoEngineLogE(@"set strategy center global option key = %d, value =  %d", (int)key, [value intValue]);
                [TTVideoEngineStrategy.helper setIntValue:key intVal:[value intValue]];
            } else {
                [TTAVPlayer setGlobalValue:value forKey:(int)key];
            }
            break;
    }
}

- (void)setOptions:(NSDictionary<VEKKeyType,id> *)options {
    [options.copy enumerateKeysAndObjectsUsingBlock:^(VEKKeyType  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]]) {
            NSInteger kint = key.integerValue;
            if (kint > VEKKeyDirIntMinGuard_NSInteger && kint < VEKKeyDirIntMaxGuard_NSInteger) {
                [self.options setPreIntOptForKey:key.intValue value:[obj intValue]];
            } else {
                [self _setOption:key value:obj];
            }
        } else {
            TTVideoEngineLogE(@"setOptions:  value type error ~ ~ ");
        }
    }];
}

- (void)setOptionForKey:(NSInteger)key value:(id)value {
    if (key > VEKKeyDirIntMinGuard_NSInteger && key < VEKKeyDirIntMaxGuard_NSInteger) {
        [self.options setPreIntOptForKey:key value:[value intValue]];
        if (key == VEKKeyIsEnableMetalViewDoubleBuffering) {
            [[self getEventLogger] setIntOption:LOGGER_OPTION_METALVIEW_DOUBLE_BUFFERING value:[value interval]];
        }
    } else if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        [self _setOption:VEKKEY(key) value:value];
    } else {
        TTVideoEngineLogE(@"setOptions:  value type error ~ ~ ");
    }
}

- (void)_setOption:(VEKKeyType)key value:(id)value {
    TTVideoEngineLog(@"setOption: %@ value: %@",key,value);
    
    switch (key.integerValue) {
        //
        case VEKKeyPlayer:
            // ReadWrite, Player
            ERROR_KEY
            break;
        case VEKKeyPlayerMuted_BOOL:
            self.muted = [value boolValue];
            break;
        case VEKKeyPlayerLooping_BOOL:
            self.looping = [value boolValue];
            break;
        case VEKKeyPlayerAsyncInit_BOOL:
            self.asyncInit = [value boolValue];
            break;
        case VEKKeyPlayerAsyncPrepare_BOOL:
            self.asyncPrepare = [value boolValue];
            break;
        case VEKKeyPlayerVolume_CGFloat:
            self.volume = [value floatValue];
            break;
        case VEKKeyPlayerDashEnabled_BOOL:
            self.dashEnabled = [value boolValue];
            break;
        case VEKKeyPlayerHttpsEnabled_BOOL:
            self.enableHttps = [value boolValue];
            break;
        case VEKKeyPlayerABR4GMaxResolution:
            self.mABR4GMaxResolutionIndex = [value integerValue];
            break;
        case VEKKeyPlayerCheckHijack_BOOL:
            self.checkHijack = [value boolValue];
            break;
        case VEKKeyPlayerHijackRetryEnable_BOOL:
            self.hijackRetryEnable = [value boolValue];
            break;
        case VEKKeyPlayerStartTime_CGFloat:
            self.startTime = [value doubleValue];
            break;
        case VEKKeyPlayerKsyByteVC1Decode_BOOL:
            self.ksyByteVC1Decode = [value boolValue];
            break;
        case VEKKeyPlayerTestSpeedMode_ENUM:
            self.testSpeedMode = [value unsignedIntegerValue];
            break;
        case VEKKeyPlayerHardwareDecode_BOOL:
            self.hardwareDecode = [value boolValue];
            break;
        case VEKKeyPlayerServerDecodingModePriority_BOOL:
            self.serverDecodingMode = [value boolValue];
            break;
        case VEKKeyPlayerByteVC1Enabled_BOOL:
            self.byteVC1Enabled = [value boolValue];
            break;
        case VEKKeyPlayerCodecType_ENUM:
            self.codecType = [value unsignedIntValue];
            break;
        case VEKKeyPlayerLoopEndTime_CGFloat:
            self.loopEndTime = [value doubleValue];
            break;
        case VEKKeyPlayerLoopStartTime_CGFloat:
            self.loopStartTime = [value doubleValue];
            break;
        case VEKKeyPlayerPlaybackSpeed_CGFloat:
            self.playbackSpeed = [value floatValue];
            break;
        case VEKKeyPlayerSmoothlySwitching_BOOL:
            self.smoothlySwitching = [value boolValue];
            break;
        case VEKKeyPlayerSmoothDelayedSeconds_NSInteger:
            self.smoothDelayedSeconds = [value integerValue];
            break;
        case VEKKeyPlayerEmbellishVolumeMilliseconds_NSInteger:
            self.embellishVolumeMilliseconds = [value integerValue];
            break;
        case VEKKeyPlayerReuseSocket_BOOL:
            self.reuseSocket = [value boolValue];
            break;
        case VEKKeyPlayerDisableAccurateStart_BOOL:
            self.disableAccurateStart = [value boolValue];
            break;
        case VEKKeyPlayerOpenTimeOut_NSInteger:
            self.openTimeOut = [value integerValue];
            break;
        case VEKKeyPlayerAudioDevice_ENUM:
            self.audioDeviceType = [value unsignedIntegerValue];
            break;
        case VEKKeyPlayerCacheMaxSeconds_NSInteger:
            self.cacheMaxSeconds = [value integerValue];
            break;
        case VEKKeyPlayerBufferingTimeOut_NSInteger:
            self.bufferingTimeOut = [value integerValue];
            break;
        case VEKKeyPlayerMaxBufferEndTime_NSInteger:
            self.maxBufferEndTime = [value integerValue];
            break;
        case VEKKeyPlayerLoopWay_NSInteger:
            self.loopWay = [value integerValue];
            break;
        case VEKKeyPlayerBoeEnabled_BOOL:
            self.boeEnable = [value boolValue];
            break;
        case VEKKeyPlayerDnsCacheEnabled_BOOL:
            self.dnsCacheEnable = [value boolValue];
            break;
        case VEKKeyPlayerDnsCacheSecond_NSInteger:
            self.dnsExpiredTime = [value integerValue];
            break;
        case VEKKeyPlayerHijackRetryMainDnsType_ENUM:
            self.hijackRetryMainDnsType = [value integerValue];
            break;
        case VEKKeyPlayerHijackRetryBackupDnsType_ENUM:
            self.hijackRetryBackupDnsType = [value integerValue];
            break;
        case VEKKeyPlayerBashEnabled_BOOL:
           self.bashEnable = [value boolValue];
            break;
        case VEKKeyPlayerHLSSeamlessSwitchEnable_BOOL:
            self.hlsSeamlessSwitch = [value boolValue];
            break;
        case VEKeyPlayerSegmentFormatFlag:
            self.segmentFormatFlag = [value integerValue];
            break;
        case VEKeyPlayerEnableBarrageMaskThread_BOOL:
            self.barrageMaskThreadEnable = [value boolValue];
            break;
        case VEKeyPlayerEnableAIBarrageThread_BOOL:
            self.aiBarrageThreadEnable = [value boolValue];
            break;
        case VEKeyPlayerEnableSubThread_BOOL:
            self.subThreadEnable = [value boolValue];
            break;
        case VEKeyPlayerMaskEnableDataloader_BOOL:
            self.maskEnableDataLoader = [value boolValue];
            break;
        case VEKKeyPlayerSeekEndEnabled_BOOL:
            self.seekEndEnabled = [value boolValue];
            break;
        case VEKKeyPlayerReportRequestHeaders_BOOL:
            self.reportRequestHeaders = [value boolValue];
            break;
        case VEKKeyPlayerReportResponseHeaders_BOOL:
            self.reportResponseHeaders = [value boolValue];
            break;
        case VEKKeyPlayerTimeBarPercentage_BOOL:
            self.enableTimerBarPercentage = [value boolValue];
            break;
        case VEKKeyPlayerEnableDashAbr_BOOL:
            self.enableDashAbr = [value boolValue];
            break;
        case VEKKeyPlayerDashABRSwitchMode:
            self.abrSwitchMode = [value integerValue];
            break;
        case VEKKeyPlayerEnableIndexCache_BOOL:
            self.enableIndexCache = [value boolValue];
            break;
        case VEKKeyPlayerEnableFragRange_BOOL:
            self.enableFragRange = [value boolValue];
            break;
        case VEKKeyPlayerEnableAsync_BOOL:
            self.enableAsync = [value boolValue];
            break;
        case VEKKeyPlayerRangeMode_ENUM:
            self.rangeMode = [value integerValue];
            break;
        case VEKKeyPlayerReadMode_ENUM:
            self.readMode = [value integerValue];
            break;
        case VEKKeyPlayerVideoRangeSize_NSInteger:
            self.videoRangeSize = [value integerValue];
            break;
        case VEKKeyPlayerAudioRangeSize_NSInteger:
            self.audioRangeSize = [value integerValue];
            break;
        case VEKKeyPlayerVideoRangeTime_NSInteger:
            self.videoRangeTime = [value integerValue];
            break;
        case VEKKeyPlayerAudioRangeTime_NSInteger:
            self.audioRangeTime = [value integerValue];
            break;
        case VEKKeyPlayerSkipFindStreamInfo_BOOL:
            self.skipFindStreamInfo = [value boolValue];
            break;
        case VEKKeyPlayerUpdateTimestampMode_ENUM:
            self.updateTimestampMode = [value integerValue];
            break;
        case VEKKeyPlayerEnableOpenTimeout_BOOL:
            self.enableOpenTimeout = [value boolValue];
            break;
        case VEKKeyPlayerTTHLSDrm_BOOL:
            self.enableTTHlsDrm = [value boolValue];
            break;
        case VEKKeyPlayerTTHLSDrmToken_NSString:
            self.ttHlsDrmToken = value;
            break;
        case VEKKeyPlayerIdleTimerAuto_NSInteger:
            self.idleTimerAutoMode = [value integerValue];
            break;
        case VEKKeyEnterBufferingDirectly_BOOL:
            self.enableEnterBufferingDirectly = [value boolValue];
            break;
        case VEKKeyPlayerOutputFramesWaitNum_NSInteger:
            self.outputFramesWaitNum = [value integerValue];
            break;
        case VEKKeyPlayerStartPlayAudioBufferThreshold_NSInteger:
            self.startPlayAudioBufferThreshold = [value integerValue];
            break;
        case VEKKeyPlayerAudioEffectPregain_CGFloat:
            self.audioEffectPregain = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectThreshold_CGFloat:
            self.audioEffectThreshold = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectRatio_CGFloat:
            self.audioEffectRatio = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectPredelay_CGFloat:
            self.audioEffectPredelay = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectPostgain_CGFloat:
            self.audioEffectPostgain = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectEnable_BOOL:
            self.audioEffectEnabled = [value boolValue];
            break;
        case VEKKeyPlayerAudioEffectForbidCompressor_BOOL:
            self.aeForbidCompressor = [value boolValue];
            break;
        case VEKKeyPlayerMemoryOptimize_BOOL:
            self.optimizeMemoryUsage = [value boolValue];
            break;
        case VEKKeyPlayerAudioUnitPoolEnable_BOOL:
            self.audioUnitPoolEnabled = [value boolValue];
            break;
        case VEKKeyPlayerAVSyncStartEnable_BOOL:
            self.avSyncStartEnable = [value boolValue];
            break;
        case VEKKeyThreadWaitTimeMS_NSInteger:
            self.threadWaitTimeMS = [value integerValue];
            break;
        case VEKKeyCodecDropSkippedFrame_BOOL:
            self.codecDropSkippedFrame = [value boolValue];
            break;
        case VEKKeyPlayerABRTimerIntervalMilliseconds_NSInteger:
            self.abrTimerInterval = [value integerValue];
            break;
        case VEKKeyPlayerDummyAudioSleep_BOOL:
            self.dummyAudioSleep = [value boolValue];
            break;
        case VEKKeyPlayerUseEngineQueue_BOOL:
            self.usingEngineQueue = [value boolValue];
            break;
        case VEKKeyPlayerDefaultBufferEndTime_NSInteger:
            self.defaultBufferEndTime = [value integerValue];
            break;
        case VEKKeyPlayerBarrageMaskEnabled_BOOL:
            self.barrageMaskEnable = [value boolValue];
            break;
        case VEKKeyPlayerAIBarrageEnabled_BOOL:
            self.aiBarrageEnable = [value boolValue];
            break;
        case VEKKeyPlayerSubEnabled_BOOL:
            self.subEnable = [value boolValue];
            break;
        case VEKKeyPlayerDecoderOutputBufferType_ENUM:
            self.decoderOutputType = [value integerValue];
            break;
        case VEKKeyPlayerPrepareMaxCacheMs_NSInteger:
            self.prepareMaxCacheMs = [value integerValue];
            break;
        case VEKKeyPlayerMDLCacheMode_NSInteger:
            self.mdlCacheMode = [value integerValue];
            break;
        case VEKKeyPlayerHttpAutoRangeOffset_NSInteger:
            self.httpAutoRangeOffset = [value integerValue];
            break;
        case VEKKeyPlayerLazySeek_BOOL:
            self.playerLazySeek = [value boolValue];
            break;
        case VEKKeyPlayerEnableNNSR_BOOL:
            self.enableNNSR = [value boolValue];
            break;
        case VEKKeyPlayerNNSRFPSThreshold_NSInteger:
            self.nnsrFpsThreshold = [value integerValue];
            break;
        case VEKKeyPlayerEnableRange_BOOL:
            self.enableRange = [value boolValue];
            break;
        case VEKKeyPlayerAudioEffectTargetLoudness_CGFloat:
            self.audioEffectTarLoudness = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectType_NSInteger:
            self.audioEffectType = [value integerValue];
            break;
        case VEKKeyAudioChannelEffect_ENUM:
            self.options.audioChannelType = [value integerValue];
            break;
        case VEKKeyPlayerAudioEffectSrcPeak_CGFloat:
            self.audioEffectSrcPeak = [value floatValue];
            break;
        case VEKKeyPlayerAudioEffectSrcLoudness_CGFloat:
            self.audioEffectSrcLoudness = [value floatValue];
            break;
        case VEKKeyPlayerNormalClockType_NSInteger:
            self.normalClockType = [value integerValue];
            break;
        case VEKKeyPlayerEnableAllResolutionSR_BOOL:
            self.enableAllResolutionVideoSR = [value integerValue];
            break;
        case VEKKeyPlayerSkipBufferLimit_NSInteger:
            self.skipBufferLimit = [value integerValue];
            break;
        case VEKKeyPlayerReportAllBufferUpdate_BOOL:
            self.enableReportAllBufferUpdate = [value integerValue];
            break;
        case VEKKeyPlayerNotifyBufferBeforeFirstFrame_BOOL:
            self.notifyBufferBeforeFirstFrame = [value boolValue];
            break;
        case VEKKeyPlayerEnableAVStack_BOOL:
        case VEKKeyPlayerEnableAVStack_NSInteger:
            self.enableAVStack = [value integerValue];
            break;
        case VEKKeyPlayerMaskStopTimeout_NSInteger:
            self.maskStopTimeout = [value integerValue];
            break;
        case VEKKeyPlayerSubtitleStopTimeout_NSInteger:
            self.subtitleStopTimeout = [value integerValue];
            break;
        case VEKKeyPlayerSubtitleOptEnable_BOOL:
            self.options.enableSubtitleLoadOpt = [value boolValue];
            break;
        case VEKKeyPlayerTerminalAudioUnitPool_BOOL:
            self.terminalAudioUnitPool = [value boolValue];
            break;
        case VEKKeyPlayerPostPrepareMsg:
            self.isEnablePostPrepareMsg = [value boolValue];
            break;
        case VEKKeyPlayerPostPrepareWay:
            TTVideoEngineLog(@"set postprepare way:%d",[value integerValue]);
            self.postprepareWay = [value integerValue];
            break;
        case VEKKeyPlayerEnablePlayCallbackCacheHitSize:
            self.isEnablePlayCallbackHitCacheSize = [value boolValue];
            break;
        case VEKKeyAudioLatencyQueueByTime_BOOL:
            self.audioLatencyQueueByTime = [value boolValue];
            break;
        case VEKKeyVideoEndIsAllEof_BOOL:
            self.videoEndIsAllEof = [value boolValue];
            break;
        case VEKKeyPlayerEnableBufferingMilliSeconds_BOOL:
            self.enableBufferingMilliSeconds = [value boolValue];
            break;
        case VEKKeyPlayersDefaultBufferingEndMilliSeconds_NSInteger:
            self.defaultBufferingEndMilliSeconds = [value integerValue];
            break;
        case VEKKeyPlayersMaxBufferEndMilliSeconds_NSInteger:
            self.maxBufferEndMilliSeconds = [value integerValue];
            break;
        case VEKKeyDecreaseVtbStaskSize_NSInteger:
            self.decreaseVtbStackSize = [value integerValue];
        case VEKKeyPlayerPreferNearestSampleEnable:
            self.preferNearstSampleEnable = [value boolValue];
            break;
        case VEKKeyPlayerPreferNearestMaxPosOffset:
            self.preferNearstSampleMaxPosOffset = [value integerValue];
            break;
        case VEKKeyDisableShortSeek_BOOL:
            self.disableShortSeek = [value boolValue];
            break;
        case VEKKeyPlayerEnable720pSP_BOOL:
            self.enable720pSR = [value boolValue];
            break;
        case VEKKEYPlayerKeepFormatAlive_BOOL:
            self.enableKeepFormatThreadAlive = [value boolValue];
            break;
        case VEKKeyPlayerMaxAccumulatedErrCount_NSInteger:
            self.maxAccumulatedErrCount = [value integerValue];
            break;
        case VEKKeyPlayerFFCodecerHeaacV2Compat_BOOL:
            self.enableFFCodecerHeaacV2Compat = [value boolValue];
            break;
        case VEKKeyPlayerPreferSpdlForHDR_BOOL:
            self.preferSpdl4HDR = [value boolValue];
            break;
        case VEKKeyPlayerHandleBackgroundInAVView_BOOL:
            break;
        case VEKKeyPlayerLazyAudioUnitOp_BOOL:
            self.enableLazyAudioUnitOp = [value boolValue];
            break;
        case VEKKeyPlayerHDR10VideoModelLowBound_NSInteger:
            self.hdr10VideoModelLowBound = [value intValue];
            break;
        case VEKKeyPlayerHDR10VideoModelHighBound_NSInteger:
            self.hdr10VideoModelHighBound = [value intValue];
            break;
        case VEKKeyPlayerStopSourceAsync_BOOL:
            self.stopSourceAsync = [value boolValue];
            break;
        case VEKKeyPlayerSeekInterrupt_BOOL:
            self.enableSeekInterrupt = [value boolValue];
            break;
        case VEKKeyPlayerUpdateClockWithOffset_BOOL:
            break;
        case VEKKeyPlayerChangeVtbSizePicSizeBound_NSInteger:
            self.changeVtbSizePicSizeBound = [value intValue];
            break;
        case VEKKeyPlayerEnableRangeCacheDuration_BOOL:
            self.enableRangeCacheDuration = [value boolValue];
            break;
        case VEKKeyPlayerEnableVoiceSplitHeaacV2_BOOL:
            self.enableVoiceSplitHeaacV2 = [value boolValue];
            break;
        case VEKKeyPlayerEnableAudioHardwareDecode_BOOL:
            self.enableAudioHardwareDecode = [value boolValue];
            break;
        case VEKKeyPlayerDelayBufferingUpdate_BOOL:
            self.delayBufferingUpdate = [value boolValue];
            break;
        case VEKKeyPlayerNoBufferingUpdate_BOOL:
            self.noBufferingUpdate = [value boolValue];
            break;
        case VEKKeyPlayerKeepVoiceDuration_BOOL:
            self.keepVoiceDuration = [value boolValue];
            break;
        case VEKKeyPlayerVoiceBlockDuration_NSInteger:
            self.voiceBlockDuration = [value intValue];
            break;
        case VEKKeyPlayerSkipSetSameWindow_BOOL:
            self.skipSetSameWindow = [value boolValue];
            break;
        case VEKKeyPlayerCacheVoiceId_BOOL:
            self.cacheVoiceId = [value boolValue];
            break;
        case VEKeyPlayerCheckInfo_NSString:
            self.checkInfoString = value;
            break;
        case VEKKeyPlayerSetSpdlForHDRUrl_BOOL:
            self.preferSpdl4HDRUrl = [value boolValue];
            break;
        case VEKKeyPlayerEnableSRBound_BOOL:
            self.enableSRBound = [value boolValue];
            break;
        case VEKKeyPlayerSRLongDimensionLowerBound_NSInteger:
            self.srLongDimensionLowerBound = [value intValue];
            break;
        case VEKKeyPlayerSRLongDimensionUpperBound_NSInteger:
            self.srLongDimensionUpperBound = [value intValue];
            break;
        case VEKKeyPlayerSRShortDimensionLowerBound_NSInteger:
            self.srShortDimensionLowerBound = [value intValue];
            break;
        case VEKKeyPlayerSRShortDimensionUpperBound_NSInteger:
            self.srShortDimensionUpperBound = [value intValue];
            break;
        case VEKKeyPlayerFilePlayNoBuffering_BOOL:
            self.filePlayNoBuffering = [value intValue];
            break;
        case VEKKeyPlayerAllAVViewHoldBackground:
            self.options.allAVViewHoldBackground = [value boolValue];
            break;
        case VEKKeyPlayerOpenVoiceInPrepare:
            self.options.openVoiceInPrepare = [value boolValue];
            break;
        case VEKKeyVtbFlushKeepSesssion_BOOL:
            self.options.vtbFlushKeepSesssion = [value boolValue];
            break;
        case VEKKeyPlayerEnableVtbDropRASL_BOOL:
            self.options.enableDropRASL = [value boolValue];
            break;
        case VEKKeyPlayerEnableDisplayP3_BOOL:
            self.options.enableDisplayP3 = [value boolValue];
            break;
        case VEKKeyPlayerEnableVideoTimestampMonotonic_BOOL:
            self.options.enableVideoTimestampMonotonic = [value boolValue];
            break;
        case VEKKeyPlayerPositionUpdateInterval_NSInteger:
            self.options.positionUpdateInterval = [value integerValue];
            break;
        case VEKKeyAVOutsyncCallback_BOOL:
            self.options.enableAVOutsyncCallback = [value boolValue];
            break;
        case VEKKeyPlayerPreciseCache_NSInteger:
            self.options.preciseCache = [value integerValue];
            break;
        case VEKKeyPlayerForceAsyncPause_BOOL:
            self.options.forceAsyncPause = [value boolValue];
            break;
        case VEKKeyPlayerEnableVideo15SR_BOOL:
            self.options.enableVideo15SR = [value boolValue];
            break;
        case VEKKeyPlayerClockResumeResetEof_BOOL:
            self.options.enableClockResumeResetEof = [value boolValue];
            break;
        case VEKKeyPlayerEnableUIResponderLogOnPlay_BOOL:
            self.options.enableUIResponderLogOnPlay = [value boolValue];
            break;
        case VEKKeyPlayerAOutletCPUTest_BOOL:
            self.options.enableAudioOutletCpuTest = [value boolValue];
            break;
        case VEKKeyPlayerEnableBufferingDirectlyRenderStartReport_BOOL:
            self.options.enableBufferingDirectlyRenderStartReport = [value boolValue];
            break;
        case VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds_BOOL:
            self.options.enableDirectlyBufferingEndTimeMilliSeconds = [value boolValue];
            break;
        case VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds_NSInteger:
            self.options.directlyBufferingEndTimeMilliSeconds = [value intValue];
            break;
        case VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket_BOOL:
            self.options.enableDirectlyBufferingSendVideoPacket = [value boolValue];
            break;
        case VEKKeyPlayerCacheMetalDevice_BOOL:
            self.options.enableCacheMetalDevice = [value boolValue];
            break;
        case VEKKeyPlayerFixVoiceLatency_BOOL:
            self.options.enableFixVoiceLatency = [value boolValue];
            break;
        case VEKKeyPlayerRecheckVPLSforDirectBuffering_BOOL:
            self.recheckVPLSforDirectBuffering = [value boolValue];
            break;
        //
        case VEKKeyView:
            // ReadWrite, View
            ERROR_KEY
            break;
        case VEKKeyViewScaleMode_ENUM:
            self.scaleMode = [value integerValue];
            break;
        case VEKKeyViewRenderType_ENUM:
            self.renderType = [value integerValue];
            break;
        case VEKKeyViewRenderEngine_ENUM:
            self.renderEngine = [value integerValue];
            break;
        case VEKKeyViewImageScaleType_ENUM:
            self.imageScaleType = [value integerValue];
            break;
        case VEKKeyViewEnhancementType_ENUM:
            self.enhancementType = [value integerValue];
            break;
        case VEKKeyViewImageLayoutType_ENUM:
            self.imageLayoutType = [value integerValue];
            break;
        case VEKKeyViewRotateType_ENUM:
            self.rotateType = [value integerValue];
            break;
        case VEKKeyImageRotateType_ENUM:
            self.options.imageRotateType = [value integerValue];
            break;
        case VEKKeyViewMirrorType_ENUM:
            self.mirrorType = [value integerValue];
            break;
        case VEKeyPlayerSwitchSubtitleId_NSInteger:
            self.currentSubLangId = [value integerValue];
            break;
        case VEKeyPlayerSubtitleIdQuery_NSString:
            self.subLangQuery = value;
            break;
        //
        case VEKKeyModel:
            // ReadWrite, Model
            ERROR_KEY
            break;
            
        case VEKKeyModelResolutionServerControlEnabled_BOOL:
            self.resolutionServerControlEnabled = [value boolValue];
            break;
        case VEKKeyModelCacheVideoInfoEnable_BOOL:
            self.cacheVideoInfoEnable = [value boolValue];
            break;
        case VEKKeyModelSupportExpired_BOOL:
            self.supportExpiredModel = [value boolValue];
            break;
        case VEKKeyModelUseFallbackApi_BOOL:
            self.useFallbackApi = [value boolValue];
            break;
        case VEKKeyModelFallbackApiMDLRetry_BOOL:
            self.fallbackApiMDLRetry = [value boolValue];
            break;
        case VEKKeyModelURLSessionUseEphemeral_BOOL:
            self.useEphemeralSession = [value boolValue];
            break;
        //
        case VEKKeyDNS:
            // ReadWrite, DNS
            ERROR_KEY
            break;
        case VEKKeyDNSIsUsingAVResolver_BOOL:
            self.isUsingAVResolver = [value boolValue];
            break;
        //
        case VEKKeyCache:
            // ReadWrite, Cache
            ERROR_KEY
            break;
        case VEKKeyCacheCacheEnable_BOOL:
            self.cacheEnable = [value boolValue];
            break;
        case VEKKeyCacheUseExternDirEnable_BOOL:
            self.useExternDirEnable = [value boolValue];
            break;
        case VEKKeyCacheExternCacheDir_NSString:
            self.externCacheDir = value;
            break;
        case VEKKeyCacheLimitSingleMediaCacheSize_NSInteger:
            self.limitMediaCacheSize = [value integerValue];
            break;
        case VEKKeyPreloadUpperBufferMS_NSInteger:
            self.preloadUpperBufferMs = [value integerValue];
            break;
        case VEKKeyPreloadLowerBufferMS_NSInteger:
            self.preloadLowerBufferMs = [value integerValue];
            break;
        case VEKKeyPreloadEnablePlayDurationCheck:
            self.preloadDurationCheck = [value boolValue];
            break;
        case VEKKeyPreloadEnableCheckInTimer_BOOL:
            self.isEnablePreloadCheckTimer = [value boolValue];
            break;
        //
        case VEKKeyLog:
            // ReadWrite, Log
            ERROR_KEY
            break;
        case VEKKeyLogTag_NSString:
            self.logInfoTag = value;
            break;
        case VEKKeyLogSubTag_NSString:
            self.subtag = value;
            break;
        case VEKKeyLogCustomStr_NSString:
            self.customStr = value;
            break;
        case VEKKeyLogPerformanceSwitch_BOOL:
            self.performanceLogEnable = [value boolValue];
            break;
        //
        case VEKKeyDecrypt:
            // ReadWrite, Decrypt
            ERROR_KEY
            break;
        case VEKKeyDecryptDecryptionKey_NSString:
            self.decryptionKey = value;
            break;
        case VEKKeyDecryptEncryptedDecryptionKey_NSString:
            self.encryptedDecryptionKey = value;
            break;
        //
        case VEKKeyMedialoader:
            // ReadWrite, proxy server
            ERROR_KEY
            break;
        case VEKKeyMedialoaderEnable_BOOL:
            self.medialoaderEnable = [value boolValue];
            break;
        case VEKKeyMedialoaderNativeEnable_BOOL:
            self.medialoaderNativeEnable = [value boolValue];
            break;
        case VEKKeyMediaLoaderCdnType_NSInteger:
            self.medialoaderCdnType = [value integerValue];
            break;
        case VEKKeyMediaLoaderForbidP2p_BOOL:
            // need test then open
            // self.options.forbidP2p = [value boolValue];
            break;
        case VEKKeyMediaLoaderPcdnTimer_NSInteger:
            self.mediaLoaderPcdnTimerInterval = [value integerValue];
            break;
        case VEKKeyNativeMdlEnableSeekReopen_BOOL:
            self.options.enableNativeMdlSeekReopen = [value boolValue];
            break;
        case VEKKeyNativeMdlEnableCheckTranscode_BOOL:
            self.options.enableNativeMdlCheckTranscode = [value boolValue];
            break;
        case VEKKeyDrmType_ENUM:
            self.drmType = [value integerValue];
            break;
        case VEKKeyDrmDowngrade_NSInteger:
            self.drmDowngrade = [value integerValue];
            break;
        case VEKKeyDrmRetry_BOOL:
            self.drmRetry = [value boolValue];
            break;
        case VEKKeyDrmTokenUrlTemplate_NSString:
            self.tokenUrlTemplate = value;
            break;
        case VEKKeyPlayerFindStreamInfoProbeSize_NSInteger:
            self.findStreamInfoProbeSize = [value integerValue];
            break;
        case VEKKeyPlayerFindStreamInfoProbeDuration_NSInteger:
            self.findStreamInfoProbeDuration = [value integerValue];
            break;
        case VEKKeyPlayerBackGroundPlay_BOOL:
            self.isEnableBackGroundPlay = [value boolValue];
            break;
        case VEKKeyPlayerEnableRefreshByTime_BOOL:
            self.enableRefreshByTime = [value boolValue];
            break;
        case VEKKeyPlayerLiveStartIndex_NSInteger:
            self.liveStartIndex = [value integerValue];
            break;
        case VEKKeyPlayerEnableFallbackSWDecode_BOOL:
            self.enableFallbackSWDecode = [value boolValue];
            break;
        case VEKKeyPlayerCheckVoiceInBufferingStart_BOOL:
            self.options.isCheckVoiceInBufferingStart = [value boolValue];
            break;
        case VEKKeyPlayerEnableNewOutlet_BOOL:
            self.options.isEnableNewOutlet = [value boolValue];
            break;
        case VEKKeyPlayerEnableFlushSeek_BOOL:
            self.options.enableFlushSeek = [value boolValue];
            break;
        case VEKKeyPlayerEnableGetTimeOptimize:
            self.options.enableGetTimeOptimize = [value boolValue];
            break;
        case VEKKeyPlayerSubtitleOpenRetryTimes_NSInteger:
            self.options.subtitleOpenRetryTimes = [value integerValue];
            break;
        case VEKKeyPlayerEnableRecreateSubIfDetached_BOOL:
            self.options.enableRecreateSubIfNeeded = [value boolValue];
            break;
        case VEKKeyPlayerSubtitleFormatQuery_NSString:
            self.options.subFormatQuery = value;
            break;
        case VEKKeyPlayerEnableAutoResolution_BOOL:
            self.options.enableStartUpAutoResolution = [value boolValue];
            break;
        case VEKKeyPlayerOptBlueToothRenderSync_BOOL:
            self.options.isOptBluetoothRenderSync = [value boolValue];
            break;
        case VEKKeyPlayerVoiceWriteTimeoutMultiple_NSInteger:
            self.options.voiceWroteTimeoutMultiple = [value integerValue];
            break;
        case VEKKeyPlayerAudioSkipLimitedTimes_NSInteger:
            self.options.audioSkipLimitedTimes = [value integerValue];
            break;
        case VEKKeyPlayerEnableOutletDropLimit_BOOL:
            self.options.enableOutletDropLimit = [value boolValue];
            break;
        case VEKKeyPlayerEnableThreadSafeRef_NSInteger:
            self.options.threadSafeRefSwitcher = [value integerValue];
            break;
        case VEKKeyPlayerEnableOptSubSearch_BOOL:
            self.options.enableOptSubSearch = [value boolValue];
            break;
        case VEKKeyPlayerKeepDurationBufferSize_NSInteger:
            self.options.keepDurationBufferSize = [value integerValue];
            break;
        case VEKKeyPlayerSetMaxFps_NSInteger:
            self.options.maxFps = [value integerValue];
            break;
        case VEKKeyPlayerSwitchAudioInfoId_NSInteger:
            self.options.currentAudioInfoId = [value integerValue];
            break;
        case VEKKeyPLayerOperaEventReportLevel_NSInteger:
            [[self getEventLogger] setIntOption:LOGGER_OPTION_OPERA_EVENT_REPORT_LEVEL value:[value integerValue]];
            break;
        case VEKKeyPlayerEnableMp4Check_NSInteger:
            self.options.enableMp4Check = [value integerValue];
            break;
        case VEKKeyPlayerEnableDemuxNonBlockRead_BOOL:
            self.options.enableDemuxNonblockRead = [value boolValue];
            break;
        case VEKKeyPlayerEnableDeinterlace_BOOL:
            self.options.enableDeinterlace = [value boolValue];
            break;
        case VEKKeyPlayerEnableGearStrategy_BOOL:
            self.options.enableGearStrategy = [value boolValue];
            break;
        case VEKKeyPlayerSetPrecisePausePts_int64_t:
            self.options.precisePausePts = [value longLongValue];
            break;
        case VEKKeyPlayerSetFramesDrop_NSInteger:
            self.options.framesDrop = [value integerValue];
            break;
        case VEKKeyEnginePoolIsFromEnginePool_NSString:
            [[self getEventLogger] setStringOption:LOGGER_OPTION_IS_FROM_ENGINE_POOL value:value];
            break;
        case VEKKeyEnginePoolCorePoolSizeUpperLimit_NSInteger:
            [[self getEventLogger] setIntOption:LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_UPPERLIMIT value:[value intValue]];
            break;
        case VEKKeyEnginePoolCorePoolSizeBeforeGetEngine:
            [[self getEventLogger] setIntOption:LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_BEFORE_GETENGINE value:[value intValue]];
            break;
        case VEKKeyEnginePoolCountEngineInUse:
            [[self getEventLogger] setIntOption:LOGGER_OPTION_ENGINEPOOL_COUNT_ENGINE_IN_USE value:[value intValue]];
            break;
        case VEKKeyStrategyRangeControlOverride_BOOL:
            self.options.enableStrategyRangeControl = [value boolValue];
            break;
        case VEKKeyPlayerSeekMode_ENUM:
            self.options.seekMode = [value integerValue];
            break;
        case VEKKeyStrategyAutoAddMedia_BOOL:
            self.options.enableStrategyAutoAddMedia = [value boolValue];
            break;
        case VEKKeyHookVoiceType_BOOL:
            [self setEnableHookVoice:[value boolValue]];
            break;
        case VEKKeyEnableReportPreloadTraceId_BOOL:
            self.enableReportPreloadTraceId = [value boolValue];
            break;
        case VEKKeyEnableRemoveEngineTaskQueue_BOOL:
            self.enableRemoveTaskQueue = [value boolValue];
            if (self.enableRemoveTaskQueue) {
                [self.options setPreIntOptForKey:VEKKeyPostResume_BOOL value:1];
            }
            break;
        case VEKKeyEnablePlayerPostStart_BOOL:
            self.enablePostStart = [value boolValue];
            break;
        case VEKKeyEnablePlayerPreloadGear_BOOL:
            self.enablePlayerPreloadGear = [value boolValue];
            break;
        case VEKKeyEnableGetPlayerReqOffset_NSInteger:
            self.enableGetPlayerReqOffset = [value integerValue];
            break;
        case VEKKeyIsEnableVsyncHelper:
            self.isEnableVsyncHelper = [value integerValue];
            break;
        case VEKKeyIsCustomizedVideoRenderingFrameRate:
            self.customizedVideoRenderingFrameRate = [value integerValue];
            break;
        case VEKKeyPlaySpeedExtendEnable_BOOL:
            self.options.enablePlaySpeedExtend = [value boolValue];
            break;
        case VEKKeyEnableClearMdlCache_BOOL:
            self.enableClearMdlCache = [value boolValue];
            break;
        default:
            ERROR_KEY
            break;
    }
    //
}
- (id)getOptionBykey:(VEKKeyType)key {
    if (key.integerValue > VEKKeyDirIntMinGuard_NSInteger &&
        key.integerValue < VEKKeyDirIntMaxGuard_NSInteger)
        return [self.options getPreIntOptForKey:key];
    id temValue = [NSNull null];
    switch (key.integerValue) {
        //
        case VEKKeyPlayer:
            // ReadWrite, Player
            ERROR_KEY
            break;
        case VEKKeyPlayerMuted_BOOL:
            temValue = @(self.muted);
            break;
        case VEKKeyPlayerLooping_BOOL:
            temValue = @(self.looping);
            break;
        case VEKKeyPlayerAsyncInit_BOOL:
            temValue = @(self.asyncInit);
            break;
        case VEKKeyPlayerAsyncPrepare_BOOL:
            temValue = @(self.asyncPrepare);
            break;
        case VEKKeyPlayerVolume_CGFloat:
            temValue = @(self.volume);
            break;
        case VEKKeyPlayerDashEnabled_BOOL:
            temValue = @(self.dashEnabled);
            break;
        case VEKKeyPlayerHttpsEnabled_BOOL:
            temValue = @(self.enableHttps);
            break;
        case VEKKeyPlayerCheckHijack_BOOL:
            temValue = @(self.checkHijack);
            break;
        case VEKKeyPlayerStartTime_CGFloat:
            temValue = @(self.startTime);
            break;
        case VEKKeyPlayerKsyByteVC1Decode_BOOL:
            temValue = @(self.ksyByteVC1Decode);
            break;
        case VEKKeyPlayerTestSpeedMode_ENUM:
            temValue = @(self.testSpeedMode);
            break;
        case VEKKeyPlayerHardwareDecode_BOOL:
            temValue = @(self.hardwareDecode);
            break;
        case VEKKeyPlayerServerDecodingModePriority_BOOL:
            temValue = @(self.serverDecodingMode);
            break;
        case VEKKeyPlayerByteVC1Enabled_BOOL:
            temValue = @(self.byteVC1Enabled);
            break;
        case VEKKeyPlayerCodecType_ENUM:
            temValue = @(self.codecType);
            break;
        case VEKKeyPlayerLoopEndTime_CGFloat:
            temValue = @(self.loopEndTime);
            break;
        case VEKKeyPlayerLoopStartTime_CGFloat:
            temValue = @(self.loopStartTime);
            break;
        case VEKKeyPlayerPlaybackSpeed_CGFloat:
            temValue = @(self.playbackSpeed);
            break;
        case VEKKeyPlayerSmoothlySwitching_BOOL:
            temValue = @(self.smoothlySwitching);
            break;
        case VEKKeyPlayerSmoothDelayedSeconds_NSInteger:
            temValue = @(self.smoothDelayedSeconds);
            break;
        case VEKKeyPlayerEmbellishVolumeMilliseconds_NSInteger:
            temValue = @(self.embellishVolumeMilliseconds);
            break;
        case VEKKeyPlayerReuseSocket_BOOL:
            temValue = @(self.reuseSocket);
            break;
        case VEKKeyPlayerDisableAccurateStart_BOOL:
            temValue = @(self.disableAccurateStart);
            break;
        case VEKKeyPlayerOpenTimeOut_NSInteger:
            temValue = @(self.openTimeOut);
            break;
        case VEKKeyPlayerAudioDevice_ENUM:
            temValue = @(self.audioDeviceType);
            break;
        case VEKKeyPlayerCacheMaxSeconds_NSInteger:
            temValue = @(self.cacheMaxSeconds);
            break;
        case VEKKeyPlayerBufferingTimeOut_NSInteger:
            temValue = @(self.bufferingTimeOut);
            break;
        case VEKKeyPlayerMaxBufferEndTime_NSInteger:
            temValue = @(self.maxBufferEndTime);
            break;
        case VEKKeyPlayerLoopWay_NSInteger:
            temValue = @(self.loopWay);
            break;
        case VEKKeyPlayerBoeEnabled_BOOL:
            temValue = @(self.boeEnable);
            break;
        case VEKKeyPlayerDnsCacheEnabled_BOOL:
            temValue = @(self.dnsCacheEnable);
            break;
        case VEKKeyPlayerDnsCacheSecond_NSInteger:
            temValue = @(self.dnsExpiredTime);
            break;
        case VEKKeyPlayerHijackRetryEnable_BOOL:
            temValue = @(self.hijackRetryEnable);
            break;
        case VEKKeyPlayerHijackRetryMainDnsType_ENUM:
            temValue = @(self.hijackRetryMainDnsType);
            break;
        case VEKKeyPlayerHijackRetryBackupDnsType_ENUM:
            temValue = @(self.hijackRetryBackupDnsType);
            break;
        case VEKGetKeyPlayerBitrate_LongLong:
            temValue = @(self.bitrate);
            break;
        case VEKKeyPlayerBashEnabled_BOOL:
            temValue = @(self.bashEnable);
            break;
        case VEKKeyPlayerSeekEndEnabled_BOOL:
            temValue = @(self.seekEndEnabled);
            break;
        case VEKKeyPlayerReportRequestHeaders_BOOL:
            temValue = @(self.reportRequestHeaders);
            break;
        case VEKKeyPlayerReportResponseHeaders_BOOL:
            temValue = @(self.reportResponseHeaders);
            break;
        case VEKKeyPlayerEnableDashAbr_BOOL:
            temValue = @(self.enableDashAbr);
            break;
        case VEKKeyPlayerDashABRSwitchMode:
            temValue = @(self.abrSwitchMode);
            break;
        case VEKKeyPlayerEnableIndexCache_BOOL:
            temValue = @(self.enableIndexCache);
            break;
        case VEKKeyPlayerEnableFragRange_BOOL:
            temValue = @(self.enableFragRange);
            break;
        case VEKKeyPlayerEnableAsync_BOOL:
            temValue = @(self.enableAsync);
            break;
        case VEKKeyPlayerRangeMode_ENUM:
            temValue = @(self.rangeMode);
            break;
        case VEKKeyPlayerReadMode_ENUM:
            temValue = @(self.readMode);
            break;
        case VEKKeyPlayerVideoRangeSize_NSInteger:
            temValue = @(self.videoRangeSize);
            break;
        case VEKKeyPlayerAudioRangeSize_NSInteger:
            temValue = @(self.audioRangeSize);
            break;
        case VEKKeyPlayerVideoRangeTime_NSInteger:
            temValue = @(self.videoRangeTime);
            break;
        case VEKKeyPlayerAudioRangeTime_NSInteger:
            temValue = @(self.audioRangeTime);
            break;
        case VEKKeyPlayerSkipFindStreamInfo_BOOL:
            temValue = @(self.skipFindStreamInfo);
            break;
        case VEKKeyPlayerUpdateTimestampMode_ENUM:
            temValue = @(self.updateTimestampMode);
            break;
        case VEKKeyPlayerEnableOpenTimeout_BOOL:
            temValue = @(self.enableOpenTimeout);
            break;
        case VEKKeyPlayerIdleTimerAuto_NSInteger:
            temValue = @(self.idleTimerAutoMode);
            break;
        case VEKKeyEnterBufferingDirectly_BOOL:
            temValue = @(self.enableEnterBufferingDirectly);
            break;
        case VEKKeyPlayerOutputFramesWaitNum_NSInteger:
            temValue = @(self.outputFramesWaitNum);
            break;
        case VEKKeyPlayerStartPlayAudioBufferThreshold_NSInteger:
            temValue = @(self.startPlayAudioBufferThreshold);
            break;
        case VEKKeyPlayerAudioEffectPregain_CGFloat:
            temValue = @(self.audioEffectPregain);
            break;
        case VEKKeyPlayerAudioEffectThreshold_CGFloat:
            temValue = @(self.audioEffectThreshold);
            break;
        case VEKKeyPlayerAudioEffectRatio_CGFloat:
            temValue = @(self.audioEffectRatio);
            break;
        case VEKKeyPlayerAudioEffectPredelay_CGFloat:
            temValue = @(self.audioEffectPredelay);
            break;
        case VEKKeyPlayerAudioEffectPostgain_CGFloat:
            temValue = @(self.audioEffectPostgain);
            break;
        case VEKKeyPlayerAudioEffectEnable_BOOL:
            temValue = @(self.audioEffectEnabled);
            break;
        case VEKKeyPlayerAudioEffectForbidCompressor_BOOL:
            temValue = @(self.aeForbidCompressor);
            break;
        case VEKKeyPlayerMemoryOptimize_BOOL:
            temValue = @(self.optimizeMemoryUsage);
            break;
        case VEKKeyThreadWaitTimeMS_NSInteger:
            temValue = @(self.threadWaitTimeMS);
            break;
        case VEKKeyCodecDropSkippedFrame_BOOL:
            temValue = @(self.codecDropSkippedFrame);
            break;
        case VEKKeyPlayerAudioUnitPoolEnable_BOOL:
            temValue = @(self.audioUnitPoolEnabled);
            break;
        case VEKKeyPlayerAVSyncStartEnable_BOOL:
            temValue = @(self.avSyncStartEnable);
            break;
        case VEKKeyPlayerABRTimerIntervalMilliseconds_NSInteger:
            temValue = @(self.abrTimerInterval);
            break;
        case VEKKeyPlayerDummyAudioSleep_BOOL:
            temValue = @(self.dummyAudioSleep);
            break;
        case VEKKeyPlayerUseEngineQueue_BOOL:
            temValue = @(self.usingEngineQueue);
            break;
        case VEKKeyPlayerDefaultBufferEndTime_NSInteger:
            temValue = @(self.defaultBufferEndTime);
            break;
        case VEKKeyPlayerDecoderOutputBufferType_ENUM:
            temValue = @(self.decoderOutputType);
            break;
        case VEKKeyPlayerBarrageMaskEnabled_BOOL:
            temValue = @(self.barrageMaskEnable);
            break;
        case VEKKeyPlayerAIBarrageEnabled_BOOL:
            temValue = @(self.aiBarrageEnable);
            break;
        case VEKKeyPlayerSubEnabled_BOOL:
            temValue = @(self.subEnable);
            break;
        case VEKKeyPlayerLazySeek_BOOL:
            temValue = @(self.playerLazySeek);
            break;
        case VEKKeyPlayerEnableNNSR_BOOL:
            temValue = @(self.enableNNSR);
            break;
        case VEKeyPlayerEnableBarrageMaskThread_BOOL:
            temValue = @(self.barrageMaskThreadEnable);
            break;
        case VEKeyPlayerEnableAIBarrageThread_BOOL:
            temValue = @(self.aiBarrageThreadEnable);
            break;
        case VEKeyPlayerEnableSubThread_BOOL:
            temValue = @(self.subThreadEnable);
            break;
        case VEKKeyPlayerAudioEffectType_NSInteger:
            temValue = @(self.audioEffectType);
            break;
        case VEKKeyAudioChannelEffect_ENUM:
            temValue = @(self.options.audioChannelType);
            break;
        case VEKKeyPlayerAudioEffectTargetLoudness_CGFloat:
            temValue = @(self.audioEffectTarLoudness);
            break;
        case VEKKeyPlayerAudioEffectSrcLoudness_CGFloat:
            temValue = @(self.audioEffectSrcLoudness);
            break;
        case VEKKeyPlayerAudioEffectSrcPeak_CGFloat:
            temValue = @(self.audioEffectSrcPeak);
            break;
        case VEKKeyPlayerNormalClockType_NSInteger:
            temValue = @(self.normalClockType);
            break;
        case VEKKeyPlayerSkipBufferLimit_NSInteger:
            temValue = @(self.skipBufferLimit);
            break;
        case VEKKeyPlayerNotifyBufferBeforeFirstFrame_BOOL:
            temValue = @(self.notifyBufferBeforeFirstFrame);
            break;
        case VEKKeyPlayerPostPrepareMsg:
            temValue = @(self.isEnablePostPrepareMsg);
            break;
        case VEKKeyPlayerStopSourceAsync_BOOL:
            temValue = @(self.stopSourceAsync);
            break;
        case VEKKeyPlayerSeekInterrupt_BOOL:
            temValue = @(self.enableSeekInterrupt);
            break;
        case VEKKeyPlayerEnableRangeCacheDuration_BOOL:
            temValue = @(self.enableRangeCacheDuration);
            break;
        case VEKKeyPlayerEnableVoiceSplitHeaacV2_BOOL:
            temValue = @(self.enableVoiceSplitHeaacV2);
            break;
        case VEKKeyPlayerDelayBufferingUpdate_BOOL:
            temValue = @(self.delayBufferingUpdate);
            break;
        case VEKKeyPlayerNoBufferingUpdate_BOOL:
            temValue = @(self.noBufferingUpdate);
            break;
        case VEKKeyPlayerEnableSRBound_BOOL:
            temValue = @(self.enableSRBound);
            break;
        case VEKKeyPlayerSRLongDimensionLowerBound_NSInteger:
            temValue = @(self.srLongDimensionLowerBound);
            break;
        case VEKKeyPlayerSRLongDimensionUpperBound_NSInteger:
            temValue = @(self.srLongDimensionUpperBound);
            break;
        case VEKKeyPlayerSRShortDimensionLowerBound_NSInteger:
            temValue = @(self.srShortDimensionLowerBound);
            break;
        case VEKKeyPlayerSRShortDimensionUpperBound_NSInteger:
            temValue = @(self.srShortDimensionUpperBound);
            break;
        case VEKKeyPlayerFilePlayNoBuffering_BOOL:
            temValue = @(self.filePlayNoBuffering);
            break;
        case VEKKeyPlayerPositionUpdateInterval_NSInteger:
            temValue = @(self.options.positionUpdateInterval);
            break;
        case VEKKeyAVOutsyncCallback_BOOL:
            temValue = @(self.options.enableAVOutsyncCallback);
            break;
        case VEKKeyPlayerPreciseCache_NSInteger:
            temValue = @(self.options.preciseCache);
            break;
        case VEKKeyPlayerForceAsyncPause_BOOL:
            temValue = @(self.options.forceAsyncPause);
            break;
        case VEKKeyPlayerEnableVideo15SR_BOOL:
            temValue = @(self.options.enableVideo15SR);
            break;
        case VEKKeyPlayerEnableUIResponderLogOnPlay_BOOL:
            temValue = @(self.options.enableUIResponderLogOnPlay);
            break;
        case VEKKeyPlayerEnableBufferingDirectlyRenderStartReport_BOOL:
            temValue = @(self.options.enableBufferingDirectlyRenderStartReport);
            break;
        case VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds_BOOL:
            temValue = @(self.options.enableDirectlyBufferingEndTimeMilliSeconds);
            break;
        case VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds_NSInteger:
            temValue = @(self.options.directlyBufferingEndTimeMilliSeconds);
            break;
        case VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket_BOOL:
            temValue = @(self.options.enableDirectlyBufferingSendVideoPacket);
            break;
        case VEKKeyPlayerCacheMetalDevice_BOOL:
            temValue = @(self.options.enableCacheMetalDevice);
            break;
        case VEKKeyPlayerFixVoiceLatency_BOOL:
            temValue = @(self.options.enableFixVoiceLatency);
            break;
        //
        case VEKKeyView:
            // ReadWrite, View
            ERROR_KEY
            break;
        case VEKKeyViewScaleMode_ENUM:
            temValue = @(self.scaleMode);
            break;
        case VEKKeyViewRenderType_ENUM:
            temValue = @(self.renderType);
            break;
        case VEKKeyViewRenderEngine_ENUM:
            temValue = @(self.renderEngine);
            break;
        case VEKKeyViewImageScaleType_ENUM:
            temValue = @(self.imageScaleType);
            break;
        case VEKKeyViewEnhancementType_ENUM:
            temValue = @(self.enhancementType);
            break;
        case VEKKeyViewImageLayoutType_ENUM:
            temValue = @(self.imageLayoutType);
            break;
        case VEKKeyViewRotateType_ENUM:
            temValue = @(self.rotateType);
            break;
        case VEKKeyImageRotateType_ENUM:
            temValue = @(self.options.imageRotateType);
            break;
        case VEKKeyViewMirrorType_ENUM:
            temValue = @(self.mirrorType);
            break;
        case VEKeyPlayerSwitchSubtitleId_NSInteger:
            temValue = @(self.currentSubLangId);
            break;
        case VEKeyPlayerSubtitleIdQuery_NSString:
            temValue = self.subLangQuery;
            break;
        //
        case VEKKeyModel:
            // ReadWrite, Model
            ERROR_KEY
            break;
        case VEKKeyModelResolutionServerControlEnabled_BOOL:
            temValue = @(self.resolutionServerControlEnabled);
            break;
        case VEKKeyModelCacheVideoInfoEnable_BOOL:
            temValue = @(self.cacheVideoInfoEnable);
            break;
        case VEKKeyModelSupportExpired_BOOL:
            temValue = @(self.supportExpiredModel);
            break;
        case VEKKeyModelUseFallbackApi_BOOL:
            temValue = @(self.useFallbackApi);
            break;
        case VEKKeyModelFallbackApiMDLRetry_BOOL:
            temValue = @(self.fallbackApiMDLRetry);
            break;
        //
        case VEKKeyDNS:
            // ReadWrite, DNS
            ERROR_KEY
            break;
        case VEKKeyDNSIsUsingAVResolver_BOOL:
            temValue = @(self.isUsingAVResolver);
            break;
        //
        case VEKKeyCache:
            // ReadWrite, Cache
            ERROR_KEY
            break;
        case VEKKeyCacheCacheEnable_BOOL:
            temValue = @(self.cacheEnable);
            break;
        case VEKKeyCacheUseExternDirEnable_BOOL:
            temValue = @(self.useExternDirEnable);
            break;
        case VEKKeyCacheExternCacheDir_NSString:
            temValue = self.externCacheDir ?: @"";
            break;
        case VEKKeyCacheLimitSingleMediaCacheSize_NSInteger:
            temValue = @(self.limitMediaCacheSize);
            break;
        case VEKKeyPreloadLowerBufferMS_NSInteger:
            temValue = @(self.preloadLowerBufferMs);
            break;
        case VEKKeyPreloadUpperBufferMS_NSInteger:
            temValue = @(self.preloadUpperBufferMs);
            break;
        case VEKKeyPreloadEnablePlayDurationCheck:
            temValue = @(self.preloadDurationCheck);
            break;
        case VEKKeyPreloadEnableCheckInTimer_BOOL:
            temValue = @(self.isEnablePreloadCheckTimer);
            break;
        case VEKKeyPlayerPreferNearestSampleEnable:
            temValue = @(self.preferNearstSampleEnable);
            break;
        case VEKKeyPlayerPreferNearestMaxPosOffset:
            temValue = @(self.preferNearstSampleMaxPosOffset);
            break;
        //
        case VEKKeyLog:
            // ReadWrite, Log
            ERROR_KEY
            break;
        case VEKKeyLogTag_NSString:
            temValue = self.logInfoTag ?: @"default";
            break;
        case VEKKeyLogSubTag_NSString:
            temValue = self.subtag ?: @"default";
            break;
        case VEKKeyLogCustomStr_NSString:
            temValue = self.customStr ?: @"default";
            break;
        case VEKKeyLogPerformanceSwitch_BOOL:
            temValue = @(self.performanceLogEnable);
            break;
        //
        case VEKKeyDecrypt:
            // ReadWrite, Decrypt
            ERROR_KEY
            break;
        case VEKKeyDecryptDecryptionKey_NSString:
            temValue = self.decryptionKey ?: @"";
            break;
        case VEKKeyDecryptEncryptedDecryptionKey_NSString:
            temValue = self.encryptedDecryptionKey ?: @"";
            break;
            
        //
        case VEKKeyMedialoader:
            // ReadWrite, proxy server
            ERROR_KEY
            break;
        case VEKKeyMedialoaderEnable_BOOL:
            temValue = @(self.medialoaderEnable);
            break;
            /// Readonly
        case VEKKeyMedialoaderNativeEnable_BOOL:
            temValue = @(self.medialoaderNativeEnable);
            break;
        case VEKKeyNativeMdlEnableSeekReopen_BOOL:
            temValue = @(self.options.enableNativeMdlSeekReopen);
            break;
        case VEKKeyNativeMdlEnableCheckTranscode_BOOL:
            temValue = @(self.options.enableNativeMdlCheckTranscode);
            break;
        //
        case VEKGetKeyPlayer:
            // Readonly, Player
            ERROR_KEY
            break;
        case VEKGetKeyPlayerMediaSize_LongLong:
            temValue = @([self mediaSize]);
            break;
        case VEKGetKeyPlayerVideoWidth_NSInteger:
            temValue = @([self getVideoWidth]);
            break;
        case VEKGetKeyPlayerVideoHeight_NSInteger:
            temValue = @([self getVideoHeight]);
            break;
        case VEKGetKeyPlayerMetadata_NSDictionary:
            temValue = [self getMetaData];
            break;
        case VEKGetKeyPlayerVideoOutputFPS_CGFloat:
            temValue = @(self.videoOutputFPS);
            break;
        case VEKGetKeyPlayerContainerFPS_CGFloat:
            temValue = @(self.containerFPS);
            break;
        case VEKGetKeyPlayerPlayBytes_int64_t:
            temValue = @(self.playBytes);
            break;
        case VEKGetKeyFirstFrameTimestamp_NSDictionary:
            temValue = [self.getEventLogger firstFrameTimestamp];
            break;
        case VEKGetKeyPlayerVideoCurrentTime_NSInteger:
            temValue = @(self.currentVideoTime);
            break;
        case VEKGetKeyPlayerVideoSRWidth_NSInteger:
            temValue = @([self getVideoSRWidth]);
            break;
        case VEKGetKeyPlayerVideoSRHeight_NSInteger:
            temValue = @([self getVideoSRHeight]);
            break;
        case VEKGetKeyPlayerAudioCodecId_NSInteger:
            temValue = @(self.audioCodecId);
            break;
        case VEKGetKeyPlayerVideoCodecId_NSInteger:
            temValue = @(self.videoCodecId);
            break;
        case VEKGetKeyPlayerAudioCodecProfile_NSInteger:
            temValue = @(self.audioCodecProfile);
            break;
        case VEKGetKeyPlayerVideoCodecProfile_NSInteger:
            temValue = @(self.videoCodecProfile);
            break;
        case VEKGetKeyPlayerAudioEffectOpened_BOOL:
            temValue = @(self.audioEffectOpened);
            break;
        case VEKGetKeyPlayerSessionId_NSString:
            temValue = [self.getEventLogger getTraceId];
            break;
        //
        case VEKGetKeyModel:
            // Readonly, Model
            ERROR_KEY
            break;
        case VEKGetKeyModelVideoSize_NSInteger:
            temValue = @([self videoSize]);
            break;
        case VEKKeyDrmType_ENUM:
            temValue = @(self.drmType);
            break;
        case VEKKeyDrmDowngrade_NSInteger:
            temValue = @(self.drmDowngrade);
            break;
        case VEKKeyDrmRetry_BOOL:
            temValue = @(self.drmRetry);
            break;
        case VEKKeyDrmTokenUrlTemplate_NSString:
            temValue = self.tokenUrlTemplate ?: @"";
            break;
        case VEKKeyModelURLSessionUseEphemeral_BOOL:
            temValue = @(self.useEphemeralSession);
            break;
            
        //
        case VEKGetKeyMetrics:
            // Readonly, Metrics
            ERROR_KEY
            break;
        case VEKGetKeyMetricsFirstFrame_NSDictionary:
            temValue = self.firstFrameMetrics ?: @{};
            break;
            
        //
        case VEKGetKeyError:
            // Readonly, Error
            ERROR_KEY
            break;
        case VEKGetKeyErrorPlayerInfo_NSString:
            temValue = self.playerLog ?: @"";
            break;
        case VEKGetKeyFileFormat_NSString:
            temValue = [self getFileFormat] ?: @"";
            break;
        case VEKGetKeyStreamTrackInfo_NSString:
            temValue = [self getStreamTrackInfo] ?: @"";
            break;
        case VEKKeyPlayerFindStreamInfoProbeSize_NSInteger:
            temValue = @(self.findStreamInfoProbeSize);
            break;
        case VEKKeyPlayerFindStreamInfoProbeDuration_NSInteger:
            temValue = @(self.findStreamInfoProbeDuration);
            break;
        case VEKKeyPlayerLiveStartIndex_NSInteger:
            temValue = @(self.liveStartIndex);
            break;
        case VEKKeyPlayerEnableFallbackSWDecode_BOOL:
            temValue = @(self.enableFallbackSWDecode);
            break;
        case VEKKeyCurrentVideoQualityType_NSInteger:
            temValue = @(self.qualityType);
            break;
        case VEKKeyPlayerCheckVoiceInBufferingStart_BOOL:
            temValue = @(self.options.isCheckVoiceInBufferingStart);
            break;
        case VEKKeyPlayerGetVideoCodecTypeId_NSInteger:
            temValue = @(self.options.videoCodecTypeId);
            break;
        case VEKKeyPlayerGetAudioCodecTypeId_NSInteger:
            temValue = @(self.options.audioCodecTypeId);
            break;
        case VEKKeyPlayerGetVideoCodecName_NSString:
            temValue = self.options.videoCodecName ?: @"";
            break;
        case VEKKeyPlayerGetAudioCodecName_NSString:
            temValue = self.options.audioCodecName ?: @"";
            break;
        case VEKKeyPlayerOptBlueToothRenderSync_BOOL:
            temValue = @(self.options.isOptBluetoothRenderSync);
            break;
        case VEKKeyPlayerVoiceWriteTimeoutMultiple_NSInteger:
            temValue = @(self.options.voiceWroteTimeoutMultiple);
            break;
        case VEKKeyPlayerAudioSkipLimitedTimes_NSInteger:
            temValue = @(self.options.audioSkipLimitedTimes);
            break;
        case VEKKeyPlayerEnableThreadSafeRef_NSInteger:
            temValue = @(self.options.threadSafeRefSwitcher);
            break;
        case VEKKeyPlayerEnableOptSubSearch_BOOL:
            temValue = @(self.options.enableOptSubSearch);
            break;
        case VEKKeyPlayerKeepDurationBufferSize_NSInteger:
            temValue = @(self.options.keepDurationBufferSize);
            break;
        case VEKKeyPlayerSetMaxFps_NSInteger:
            temValue = @(self.options.maxFps);
            break;
        case VEKKeyPlayerClockResumeResetEof_BOOL:
            temValue = @(self.options.enableClockResumeResetEof);
            break;
        case VEKKeyPlayerSwitchAudioInfoId_NSInteger:
            temValue = @(self.options.currentAudioInfoId);
            break;
        case VEKKeyPlayerAOutletCPUTest_BOOL:
            temValue = @(self.options.enableAudioOutletCpuTest);
            break;
        case VEKGetKeyMetricsPreciseCache_NSDictionary:
            temValue = [TTVideoEngineStrategy.helper getLogData:self.playSource.videoId
                                                         forKey:kTTVideoEngineStrategyLogKey_PlayTaskControl] ?: @{};
            break;
        case VEKGetKeyPlayerAudioBitrate_LongLong:
            temValue = @(self.audioBitrate);
            break;
        case VEKGetKeyVideoAreaFrame_LongLong:
            temValue = @(self.videoAreaFrame);
            break;
        case VEKKeyPlayerEnableDemuxNonBlockRead_BOOL:
            temValue = @(self.options.enableDemuxNonblockRead);
            break;
        case VEKKeyPlayerEnableDeinterlace_BOOL:
            temValue = @(self.options.enableDeinterlace);
            break;
        case VEKKeyPlayerEnableGearStrategy_BOOL:
            temValue = @(self.options.enableGearStrategy);
            break;
        case VEKKeyPlayerSetFramesDrop_NSInteger:
            temValue = @(self.options.framesDrop);
            break;
        case VEKGetKeyVideoEnabled_BOOL:
            temValue = @([self getStreamEnabled:TTVideoEngineVideoStream]);
            break;
        case VEKGetKeyAudioEnabled_BOOL:
            temValue = @([self getStreamEnabled:TTVideoEngineAudioStream]);
            break;
        case VEKKeyPlayerSeekMode_ENUM:
            temValue = @(self.options.seekMode);
            break;
        case VEKKeyPlaySpeedExtendEnable_BOOL:
            temValue = @(self.options.enablePlaySpeedExtend);
            break;
        default:
            ERROR_KEY
            break;
    }
    
    return temValue;
}

- (void)resetOptions {
    self.radioMode = FALSE;
    self.muted = FALSE;
    self.looping = FALSE;
    self.asyncInit = FALSE;
    self.asyncPrepare = FALSE;
    self.volume = 1.0;
    self.dashEnabled = FALSE;
    self.enableHttps = FALSE;
    self.mABR4GMaxResolutionIndex = TTVideoEngineResolutionTypeUnknown;
    self.checkHijack = FALSE;
    self.hijackRetryEnable = YES;
    self.startTime = 0;
    self.ksyByteVC1Decode = FALSE;
    self.testSpeedMode = -1;
    self.hardwareDecode = YES;
    self.serverDecodingMode = NO;
    self.byteVC1Enabled = FALSE;
    self.codecType = TTVideoEngineH264;
    self.loopEndTime = 0;
    self.loopStartTime = 0;
    self.playbackSpeed = 1.0;
    self.smoothlySwitching = NO;
    self.smoothDelayedSeconds = -1;
    self.embellishVolumeMilliseconds = 0;
    self.reuseSocket = FALSE;
    self.disableAccurateStart = FALSE;
    self.openTimeOut = 5;
    self.audioDeviceType = TTVideoEngineDeviceDefault;
    self.cacheMaxSeconds = 30;
    self.bufferingTimeOut = 30;
    self.maxBufferEndTime = 4;
    self.loopWay = 0;
    self.boeEnable = FALSE;
    self.dnsCacheEnable = NO;
    self.dnsExpiredTime = 0;
    self.hijackRetryMainDnsType = TTVideoEngineDnsTypeHttpTT;
    self.hijackRetryBackupDnsType = TTVideoEngineDnsTypeLocal;
    self.bashEnable = FALSE;
    self.hlsSeamlessSwitch = FALSE;
    self.segmentFormatFlag = TTVideoEngineDashSegmentFlagFormatFMP4;
    self.barrageMaskThreadEnable = FALSE;
    self.maskEnableDataLoader = FALSE;
    self.aiBarrageThreadEnable = FALSE;
    self.subThreadEnable = FALSE;
    self.seekEndEnabled = FALSE;
    self.reportRequestHeaders = FALSE;
    self.reportResponseHeaders = FALSE;
    self.enableTimerBarPercentage = FALSE;
    self.enableDashAbr = FALSE;
    self.abrSwitchMode = 0;
    self.enableIndexCache = FALSE;
    self.enableFragRange = FALSE;
    self.enableAsync = FALSE;
    self.rangeMode = 0;
    self.readMode = 0;
    self.videoRangeSize = 0;
    self.audioRangeSize = 0;
    self.videoRangeTime = 0;
    self.audioRangeTime = 0;
    self.skipFindStreamInfo = NO;
    self.updateTimestampMode = TTVideoEngineUpdateTimestampModeDts;
    self.enableOpenTimeout = YES;
    self.enableTTHlsDrm = FALSE;
    self.ttHlsDrmToken = nil;
    self.idleTimerAutoMode = 0;
    self.enableEnterBufferingDirectly = FALSE;
    self.outputFramesWaitNum = 1;
    self.startPlayAudioBufferThreshold = 0;
    self.audioEffectPregain = 0.25;
    self.audioEffectThreshold = -18;
    self.audioEffectRatio = 8;
    self.audioEffectPredelay = 0.007;
    self.audioEffectPostgain = 0.0;
    self.audioEffectEnabled = NO;
    self.aeForbidCompressor = NO;
    self.optimizeMemoryUsage = YES;
    self.audioUnitPoolEnabled = FALSE;
    self.avSyncStartEnable = FALSE;
    self.threadWaitTimeMS = 0;
    self.codecDropSkippedFrame = FALSE;
    self.abrTimerInterval = 500;
    self.dummyAudioSleep = YES;
    self.usingEngineQueue = YES;
    self.defaultBufferEndTime = 2;
    self.barrageMaskEnable = NO;
    self.aiBarrageEnable = NO;
    self.subEnable = NO;
//    self.decoderOutputType
    self.prepareMaxCacheMs = 1000;
    self.mdlCacheMode = 0;
    self.httpAutoRangeOffset = 0;
    self.playerLazySeek = YES;
    self.enableNNSR = NO;
    self.nnsrFpsThreshold = 32;
    self.enableRange = NO;
    self.audioEffectTarLoudness = 0.0;
    self.audioEffectType = 0;
    self.options.audioChannelType = 0;
    self.audioEffectSrcPeak = 0.0;
    self.audioEffectSrcLoudness = 0.0;
    self.normalClockType = TTVideoEngineClockTypeDefault;
    self.enableAllResolutionVideoSR = NO;
    self.skipBufferLimit = 0;
    self.enableReportAllBufferUpdate = NO;
    self.notifyBufferBeforeFirstFrame = NO;
    self.enableAVStack = 0;
    self.maskStopTimeout = 0;
    self.subtitleStopTimeout = 0;
    self.terminalAudioUnitPool = NO;
    self.isEnablePostPrepareMsg = NO;
    self.postprepareWay = NO;
    self.isEnablePlayCallbackHitCacheSize = NO;
    self.audioLatencyQueueByTime = NO;
    self.videoEndIsAllEof = NO;
    self.enableBufferingMilliSeconds = NO;
    self.defaultBufferingEndMilliSeconds = 1000;
    self.maxBufferEndMilliSeconds = 5000;
    self.decreaseVtbStackSize = 0;
    self.preferNearstSampleEnable = NO;
    self.preferNearstSampleMaxPosOffset = 0;
    self.disableShortSeek = NO;
    self.enable720pSR = NO;
    self.enableKeepFormatThreadAlive = NO;
    self.enableFFCodecerHeaacV2Compat = NO;
    self.preferSpdl4HDR = NO;
    self.enableLazyAudioUnitOp = YES;
    self.hdr10VideoModelLowBound = -1;
    self.hdr10VideoModelHighBound = -1;
    self.stopSourceAsync = NO;
    self.enableSeekInterrupt = NO;
    self.changeVtbSizePicSizeBound = 0;
    self.enableRangeCacheDuration = NO;
    self.enableVoiceSplitHeaacV2 = NO;
    self.enableAudioHardwareDecode = NO;
    self.delayBufferingUpdate = NO;
    self.noBufferingUpdate = NO;
    self.keepVoiceDuration = NO;
    self.voiceBlockDuration = 0;
    self.skipSetSameWindow = NO;
    self.cacheVoiceId = NO;
    self.checkInfoString = nil;
    self.preferSpdl4HDRUrl = NO;
    self.enableSRBound = NO;
    self.srLongDimensionLowerBound = 0;
    self.srLongDimensionUpperBound = 0;
    self.srShortDimensionLowerBound = 0;
    self.srShortDimensionUpperBound = 0;
    self.filePlayNoBuffering = NO;
    self.renderType = TTVideoEngineRenderTypeDefault;
    self.renderEngine = TTVideoEngineRenderEngineOpenGLES;
    self.imageScaleType = TTVideoEngineImageScaleTypeLinear;
    self.enhancementType = TTVideoEngineEnhancementTypeNone;
    self.rotateType = TTVideoEngineRotateTypeNone;
    self.mirrorType = TTVideoEngineMirrorTypeNone;
    self.currentSubLangId = 0;
    self.subLangQuery = nil;
    self.resolutionServerControlEnabled = NO;
    self.cacheVideoInfoEnable = NO;
    self.supportExpiredModel = NO;
    self.useFallbackApi = YES;
    self.fallbackApiMDLRetry = NO;
    self.useEphemeralSession = NO;
    self.isUsingAVResolver = YES;
    self.cacheEnable = NO;
    self.useExternDirEnable = FALSE;
    self.externCacheDir = nil;
    self.limitMediaCacheSize = 0;
    self.preloadUpperBufferMs = 0;
    self.preloadLowerBufferMs = 0;
    self.preloadDurationCheck = NO;
    self.isEnablePreloadCheckTimer = NO;
    self.logInfoTag = nil;
    self.subtag = nil;
    self.customStr = nil;
    self.performanceLogEnable = FALSE;
    self.decryptionKey = nil;
    self.encryptedDecryptionKey = nil;
    self.medialoaderEnable = NO;
    self.medialoaderNativeEnable = NO;
    self.medialoaderCdnType = 0;
    self.mediaLoaderPcdnTimerInterval = 500;
    self.drmType = TTVideoEngineDrmNone;
    self.drmDowngrade = 0;
    self.drmRetry = YES;
    self.tokenUrlTemplate = nil;
    self.findStreamInfoProbeSize = 5000000;
    self.findStreamInfoProbeDuration = 0;
    self.isEnableBackGroundPlay = NO;
    self.enableRefreshByTime = 0;
    self.liveStartIndex = -3;
    self.enableFallbackSWDecode = 1;
    [[self getEventLogger] setIntOption:LOGGER_OPTION_OPERA_EVENT_REPORT_LEVEL value:0];
    self.enableReportPreloadTraceId = NO;
    self.enableRemoveTaskQueue = NO;
    self.enablePostStart = NO;
    self.enablePlayerPreloadGear = NO;
    self.enableGetPlayerReqOffset = 1;
    self.enableClearMdlCache = NO;
}

@end
#pragma clang diagnostic pop
