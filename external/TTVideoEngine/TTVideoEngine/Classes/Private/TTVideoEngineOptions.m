#import "TTVideoEngineOptions.h"
#import "TTVideoEngine+Options.h"
#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineUtilPrivate.h"

@implementation TTVideoEngineOptions {
    TTVideoEnginePlayer *_player;
    NSMutableDictionary<NSNumber*, NSNumber*> *_intOptions;
}

- (instancetype) initWithPlayer:(TTVideoEnginePlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
        _intOptions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) setDefaultValues {
    _vtbFlushKeepSesssion = NO;
    _enableDropRASL = NO;
    _isEnableNewOutlet = NO;
    _enableDisplayP3 = NO;
    _enableVideoTimestampMonotonic = NO;
    _enableFlushSeek = NO;
    _subtitleOpenRetryTimes = -1;
    _enableRecreateSubIfNeeded = NO;
    _positionUpdateInterval = 0;
    _enableAVOutsyncCallback = YES;
    _isOptBluetoothRenderSync = NO;
    _voiceWroteTimeoutMultiple = 3;
    _audioSkipLimitedTimes = 30;
    _enableStartUpAutoResolution = NO;
    _enableOutletDropLimit = YES;
    _enableVideo15SR = NO;
    _threadSafeRefSwitcher = TTVideoEngineThreadSafeRefFlagNone;
    _enableOptSubSearch = NO;
    _keepDurationBufferSize = 0;
    _maxFps = 0;
    _enableClockResumeResetEof = NO;
    _currentAudioInfoId = -1;
    _enableBufferingDirectlyRenderStartReport = NO;
    _enableDirectlyBufferingEndTimeMilliSeconds = NO;
    _directlyBufferingEndTimeMilliSeconds = 200;
    _enableDirectlyBufferingSendVideoPacket = NO;
    _enableNativeMdlSeekReopen = NO;
    _enableMp4Check = 0;
    _enableDemuxNonblockRead = NO;
    _forbidP2p = NO;
    _enableDeinterlace = NO;
    _enableGearStrategy = NO;
    _precisePausePts = 0;
    _enableNativeMdlCheckTranscode = NO;
    _framesDrop = -1;
    _imageRotateType = TTVideoEngineImageRotaionTypeNone;
    _isCheckVoiceInBufferingStart = NO;
    _enableGetTimeOptimize = NO;
    _subFormatQuery = nil;
    _allAVViewHoldBackground = NO;
    _openVoiceInPrepare = NO;
    _preciseCache = 0;
    _forceAsyncPause = NO;
    _enableUIResponderLogOnPlay = NO;
    _enableAudioOutletCpuTest = NO;
    _enableCacheMetalDevice = NO;
    _enableFixVoiceLatency = NO;
    _enableSubtitleLoadOpt = NO;
    _seekMode = TTVideoEngineSeekModeAccurateAny;
    _enableStrategyRangeControl = NO;
    _enableStrategyAutoAddMedia = YES;
    _enableHookVoice = NO;
    _intOptions = [NSMutableDictionary dictionary];
    _intOptions[@(VEKKeyPlayerPostPauseAfterClose_BOOL)] = @(YES);
    _enablePlaySpeedExtend = NO;
}

- (void) applyToPlayer:(TTVideoEnginePlayer *) player{
    [player setIntValue:_vtbFlushKeepSesssion forKey:KeyIsVtbFlushKeepSesssion];
    [player setIntValue:_enableDropRASL forKey:KeyIsEnableVtbDropRASL];
    [_player setIntValue:_openVoiceInPrepare forKey:KeyIsOpenVoiceDuringPrepare];
    [_player setIntValue:_allAVViewHoldBackground forKey:KeyIsAllAVViewHoldBackground];
    [player setIntValue:_isEnableNewOutlet forKey:KeyIsIosNewOutlet];
    [player setIntValue:_enableDisplayP3 forKey:KeyIsEnableDisplayP3];
    [player setIntValue:_enableVideoTimestampMonotonic forKey:KeyIsEnableVideoTimestampMonotonic];
    [player setIntValue:_enableFlushSeek forKey:KeyIsEnableFlushSeek];
    [player setIntValue:_enableGetTimeOptimize ? 1 : 0 forKey:KeyIsEnableGetTimeOptimize];
    [player setIntValue:(int)_subtitleOpenRetryTimes forKey:KeyIsOpenSubRetryTimes];
    [player setIntValue:_enableRecreateSubIfNeeded ? 1 : 0 forKey:KeyIsRecreateSubIfDetached];
    [player setIntValue:(int)_positionUpdateInterval forKey:KeyIsPositionUpdateInterval];
    [player setIntValue:(int)_preciseCache forKey:KeyIsPreciseCache];
    [player setIntValue:_isOptBluetoothRenderSync ? 1 : 0 forKey:KeyISOptBlueToothRenderSync];
    [player setIntValue:(int)_voiceWroteTimeoutMultiple forKey:KeyISVoiceWriteTimeoutMultiple];
    [player setIntValue:(int)_audioSkipLimitedTimes forKey:KeyISAudioSkipLimitedTimes];
    [player setIntValue:_enableOutletDropLimit ? 1 : 0 forKey:KeyIsEnableOutletDropLimit];
    [player setIntValue:(int)_enableVideo15SR forKey:KeyIsEnableVideo15SR];
    [player setIntValue:(int)_threadSafeRefSwitcher forKey:KeyISEnableThreadSafeRef];
    [player setIntValue:_enableOptSubSearch ? 1 : 0 forKey:KeyIsEnableOptSubSearch];
    [player setIntValue:(int)_keepDurationBufferSize forKey:KeyIsKeepDurationBufferSize];
    [player setIntValue:(int)_maxFps forKey:KeyIsMaxFps];
    [player setIntValue:_enableClockResumeResetEof ? 1 : 0 forKey:KeyIsClockResumeResetEof];
    [player setIntValue:_enableAudioOutletCpuTest ? 1 : 0 forKey:KeyIsAOutletCPUTest];
    [player setIntValue:(int)_enableBufferingDirectlyRenderStartReport forKey:KeyIsEnableBufferingDirectlyRenderStartReport];
    [player setIntValue:(int)_enableDirectlyBufferingEndTimeMilliSeconds forKey:KeyIsEnableDirectlyBufferingEndTimeMilliSeconds];
    [player setIntValue:(int)_directlyBufferingEndTimeMilliSeconds forKey:KeyIsDirectlyBufferingEndTimeMilliSeconds];
    [player setIntValue:(int)_enableDirectlyBufferingSendVideoPacket forKey:KeyIsEnableDirectlyBufferingSendVideoPacket];
    [player setIntValue:(int)_enableCacheMetalDevice forKey:KeyIsCacheMetalDevice];
    [player setIntValue:(int)_enableFixVoiceLatency forKey:KeyIsFixVoiceLatency];
    [player setIntValue:(int)_enableNativeMdlSeekReopen forKey:KeyIsEnableMdlSeekReopen];
    [player setIntValue:(int)_enableMp4Check forKey:KeyIsEnableMp4Check];
    [player setIntValue:_enableDemuxNonblockRead ? 1 : 0 forKey:KeyIsEnableDemuxNonBlockRead];
    [player setIntValue:_enableDeinterlace ? 1 : 0 forKey:KeyIsEnableDeinterlace];
    [player setIntValue:(int)_enableHookVoice forKey:KeyIsHijackVoiceType];
    [player setValueVoidPTR:(void *)(&_precisePausePts) forKey:KeyIsSetPrecisePausePts];
    [player setIntValue:_imageRotateType forKey:KeyIsImageRotationType];
    [player setIntValue:_enablePlaySpeedExtend forKey:KeyIsPlaySpeedExtendEnable];
    if (_framesDrop > 0) {
        [player setIntValue:(int)_framesDrop forKey:KeyIsSetFramesDrop];
    }
    
    [_intOptions enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [_player setIntValue:[obj intValue] forKey:[key intValue]];
    }];
}

- (void)setPreIntOptForKey:(NSInteger)key value:(int)value {
    _intOptions[@(key)] = @(value);
}

- (NSNumber *) getPreIntOptForKey:(NSNumber*)key {
    return _intOptions[key];
}

- (void) setVtbFlushKeepSesssion:(BOOL)vtbFlushKeepSesssion {
    _vtbFlushKeepSesssion = vtbFlushKeepSesssion;
    [_player setIntValue:_vtbFlushKeepSesssion forKey:KeyIsVtbFlushKeepSesssion];
}

- (void) setEnableDropRASL:(BOOL)enableDropRASL {
    _enableDropRASL = enableDropRASL;
    [_player setIntValue:_enableDropRASL forKey:KeyIsEnableVtbDropRASL];
}

- (void)setIsCheckVoiceInBufferingStart:(BOOL)isCheckVoiceInBufferingStart {
    _isCheckVoiceInBufferingStart = isCheckVoiceInBufferingStart;
    [_player setIntValue:isCheckVoiceInBufferingStart ? 1 : 0 forKey:KeyIsCheckVoiceInBufferingStart];
}

- (void)setEnableSubtitleLoadOpt:(BOOL)enableSubtitleLoadOpt {
    _enableSubtitleLoadOpt = enableSubtitleLoadOpt;
    [_player setIntValue:enableSubtitleLoadOpt ? 1 : 0 forKey:KeyIsOptSubFirstLoadTime];
}

- (void)setEnableOutletDropLimit:(BOOL)enableOutletDropLimit {
    _enableOutletDropLimit = enableOutletDropLimit;
    [_player setIntValue:enableOutletDropLimit ? 1 : 0 forKey:KeyIsEnableOutletDropLimit];
}

- (void)setCurrentAudioInfoId:(NSInteger)currentAudioInfoId {
    TTVideoEngineLog(@"TTS feature: switch current voice Id: %ld, original one: %ld", currentAudioInfoId, _currentAudioInfoId);
    if (_currentAudioInfoId != currentAudioInfoId) {
        _currentAudioInfoId = currentAudioInfoId;
        [_player setIntValue:(int)currentAudioInfoId forKey:KeyIsSetAudioInfoId];
    }
}

- (void)setPrecisePausePts:(int64_t)precisePausePts {
    _precisePausePts = precisePausePts;
    [_player setValueVoidPTR:(void *)(&precisePausePts) forKey:KeyIsSetPrecisePausePts];
}

- (NSInteger) videoCodecTypeId {
    return [_player getIntValueForKey:KeyIsVideoCodecId];
}

- (NSInteger) audioCodecTypeId {
    return [_player getIntValueForKey:KeyIsAudioCodecId];
}

- (NSString *) videoCodecName {
    return [_player getStringValueForKey:KeyIsVideoCodecName];
}

- (NSString *) audioCodecName {
    return [_player getStringValueForKey:KeyIsAudioCodecName];
}

- (void)setPreciseCache:(NSInteger)preciseCache {
    _preciseCache = preciseCache;
    [_player setIntValue:(int)_preciseCache forKey:KeyIsPreciseCache];
}

- (void)setAudioChannelType:(TTVideoEngineAudioChannelType) channelType {

    _audioChannelType = channelType;
    [_player setIntValue:(int)channelType forKey:KeyIsAudioChannelCtl];
}

- (void)setImageRotateType:(TTVideoEngineImageRotaionType)imageRotateType {
    _imageRotateType = imageRotateType;
    AVPlayerViewRotation temRotateType = AVPlayerViewRotationNone;
    switch (imageRotateType) {
        case TTVideoEngineImageRotaionTypeNone:
            temRotateType = AVPlayerViewRotationNone;
            break;
        case TTVideoEngineImageRotaionType90:
            temRotateType = AVPlayerViewRotation90;
            break;
        case TTVideoEngineImageRotaionType180:
            temRotateType = AVPlayerViewRotation180;
            break;
        case TTVideoEngineImageRotaionType270:
            temRotateType = AVPlayerViewRotation270;
            break;
        default:
            break;
    }
    [_player setIntValue:(int)temRotateType forKey:KeyIsImageRotationType];
}

@end
