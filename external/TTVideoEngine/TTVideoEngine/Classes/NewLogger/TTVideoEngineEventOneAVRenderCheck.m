//
//  TTVideoEngineEventOneAVRenderCheck.m
//  TTVideoEngine
//
//  Created by bytedance on 2021/7/5.
//

#import "TTVideoEngineEventOneAVRenderCheck.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventManager.h"


@interface TTVideoEngineEventOneAVRenderCheck () {
    
}

@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;
@property (nonatomic, assign) int noRenderType; // 0 for video, 1 for audio
@property (nonatomic, assign) int64_t startTime;
@property (nonatomic, assign) int64_t costTime;
@property (nonatomic, copy) NSDictionary *r_stage_errcs;

@property (nonatomic, assign) long long videoFormaterLenMS;
@property (nonatomic, assign) long long audioFormaterLenMS;
@property (nonatomic, assign) long long videoLenDecMs;
@property (nonatomic, assign) long long audioLenDecMs;
@property (nonatomic, assign) long long videoLenBaseMs;
@property (nonatomic, assign) long long audioLenBaseMs;
@property (nonatomic, assign) NSInteger mIndex;
@property (nonatomic, assign) NSInteger isAVBadInterlaced;

@property (nonatomic, copy) NSString* endType;
@property (nonatomic, assign) int64_t firstFrameTime;
@property (nonatomic, assign) int64_t endTime;
@property (nonatomic, copy) NSString* resolutionBefore;
@property (nonatomic, assign) int is_abr;
@property (nonatomic, assign) UInt64 mLastRebufT;
@property (nonatomic, assign) UInt64 mLastSeekT;
@property (nonatomic, assign) UInt64 lastForebackSwitchTime;
@property (nonatomic, assign) UInt64 lastAVSwitchTime;
@property (nonatomic, assign) UInt64 lastResSwitchTime;
@property (nonatomic, assign) UInt64 lastHeadsetSwithTime;
@property (nonatomic, assign) NSInteger mBeginPos;
@property (nonatomic, assign) NSInteger mEndPos;
@property (nonatomic, assign) NSInteger mEnableMDL;
@property (nonatomic, copy) NSString* mQualityDescBefore;
@property (nonatomic, assign) NSInteger isInBackground;
@property (nonatomic, assign) NSInteger radioMode;
@property (nonatomic, assign) NSInteger curHeadset;
@property (nonatomic, assign) NSInteger blueTooth;
@property (nonatomic, assign) NSInteger crosstalkCount;

@end


@implementation TTVideoEngineEventOneAVRenderCheck
@synthesize delegate = _delegate;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base {
    if (self = [super init]) {
        _eventBase = base;
        _noRenderType = 0;
        _startTime = LOGGER_INTEGER_EMPTY_VALUE;
        _costTime = LOGGER_INTEGER_EMPTY_VALUE;
        _r_stage_errcs = nil;
        _videoFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
        _audioFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
        _mIndex = 0;
        _isAVBadInterlaced = 0;
        _endType = nil;
        _endTime = LOGGER_INTEGER_EMPTY_VALUE;
        _firstFrameTime = LOGGER_INTEGER_EMPTY_VALUE;
        _resolutionBefore = nil;
        _is_abr = LOGGER_INTEGER_EMPTY_VALUE;
        _mLastSeekT = LOGGER_INTEGER_EMPTY_VALUE;
        _mLastRebufT = LOGGER_INTEGER_EMPTY_VALUE;
        _mBeginPos = LOGGER_INTEGER_EMPTY_VALUE;
        _mEndPos = LOGGER_INTEGER_EMPTY_VALUE;
        _mEnableMDL = LOGGER_INTEGER_EMPTY_VALUE;
        _mQualityDescBefore = nil;
        _lastForebackSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastAVSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastResSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastHeadsetSwithTime = LOGGER_INTEGER_EMPTY_VALUE;
        _isInBackground = 0;
        _radioMode = 0;
        _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
        _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
        _crosstalkCount = 0;
    }
    return self;
}

- (void)clear {
    _noRenderType = 0;
    _startTime = LOGGER_INTEGER_EMPTY_VALUE;
    _costTime = LOGGER_INTEGER_EMPTY_VALUE;
    _r_stage_errcs = nil;
    _videoFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
    _audioFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
    _endType = nil;
    _endTime = LOGGER_INTEGER_EMPTY_VALUE;
    _firstFrameTime = LOGGER_INTEGER_EMPTY_VALUE;
    _resolutionBefore = nil;
    _is_abr = LOGGER_INTEGER_EMPTY_VALUE;
    _mLastSeekT = LOGGER_INTEGER_EMPTY_VALUE;
    _mLastRebufT = LOGGER_INTEGER_EMPTY_VALUE;
    _mBeginPos = LOGGER_INTEGER_EMPTY_VALUE;
    _mEndPos = LOGGER_INTEGER_EMPTY_VALUE;
    _mEnableMDL = LOGGER_INTEGER_EMPTY_VALUE;
    _mQualityDescBefore = nil;
    _lastForebackSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastAVSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastResSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastHeadsetSwithTime = LOGGER_INTEGER_EMPTY_VALUE;
    _isInBackground = 0;
    _radioMode = 0;
    _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
    _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
    _crosstalkCount = 0;
}

- (NSDictionary*)jsonDict {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    //required for event v3
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"params_for_special", @"videoplayer_monitor");
    if (_eventBase) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_sessionid", _eventBase.session_id);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"sdk_version", _eventBase.sdk_version);
    }
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"event_type", @"av_norender");
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"r_stage_errcs", _r_stage_errcs);
    
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_len_before", @(_videoFormaterLenMS));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_len_before", @(_audioFormaterLenMS));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_dec_before", @(_videoLenDecMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_base_before", @(_videoLenBaseMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_dec_before", @(_audioLenDecMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_base_before", @(_audioLenBaseMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cost_time", @(_costTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"index", @(_mIndex));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"norender_type", @(_noRenderType));
    
    if (_eventBase) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"tag", _eventBase.tag);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"subtag", _eventBase.subtag);
        if (_eventBase.curURL && _eventBase.curURL.length > 0) {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_url", _eventBase.curURL);
        } else {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_url", _eventBase.initialURL);
        }
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"source_type", _eventBase.source_type);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"v", _eventBase.vid);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"drm_type", @(_eventBase.drm_type));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"play_type", @(_eventBase.play_type));
        NSString *codec = [_eventBase.videoInfo objectForKey:kTTVideoEngineVideoCodecKey];
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"codec", codec);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_codec_nameid", @(_eventBase.video_codec_nameId));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_codec_nameid", @(_eventBase.audio_codec_nameId));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"format_type", @(_eventBase.format_type));
        NSInteger hw = _eventBase.hw ? 1 : 0;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_hw", @(hw));
        NSInteger user_hw = _eventBase.hw_user ? 1 : 0;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"user_hw", @(user_hw));
        NSString *vtype = [_eventBase.videoInfo objectForKey:kTTVideoEngineVideoTypeKey];
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"vtype", vtype);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"play_speed", @(_eventBase.playSpeed));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_duration", @(_eventBase.video_stream_duration));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_duration", @(_eventBase.audio_stream_duration));
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_mdl", @(_mEnableMDL));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_type", _endType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_before", _resolutionBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"is_abr", @(_is_abr));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"is_background", @(_isInBackground));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"radio_mode", @(_radioMode));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"headset", @(TTVideoEngineValidNumber(_curHeadset)));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bt", @(TTVideoEngineValidNumber(_blueTooth)));
    
    UInt64 lastHeadsetSwithTime = _lastHeadsetSwithTime;
    if (lastHeadsetSwithTime > 0 && _startTime >= lastHeadsetSwithTime) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_headset_switch_interval", @(_startTime - lastHeadsetSwithTime));
    }
    
    UInt64 lastForebackSwitchTime = _lastForebackSwitchTime;
    if (lastForebackSwitchTime > 0 && _startTime >= lastForebackSwitchTime) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_foreback_switch_interval", @(_startTime - lastForebackSwitchTime));
    }
    
    UInt64 lastAVSwitchTime = _lastAVSwitchTime;
    if (lastAVSwitchTime > 0 && _startTime >= lastAVSwitchTime) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_av_switch_interval", @(_startTime - lastAVSwitchTime));
    }
    
    UInt64 lastResSwitchTime = _lastResSwitchTime;
    if (lastResSwitchTime > 0 && _startTime >= lastResSwitchTime) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_res_switch_interval", @(_startTime - lastResSwitchTime));
    }

    long first_frame_interval = -1;
    if (_firstFrameTime > 0LL && _startTime > 0LL) {
        first_frame_interval = _startTime - _firstFrameTime;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"first_frame_interval", @(first_frame_interval));
    }

    if (_mLastRebufT > 0LL && _startTime >= _mLastRebufT) {
        UInt64 interval = _startTime - _mLastRebufT;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_rebuf_interval", @(interval));
    }

    if (_mLastSeekT > 0LL && _startTime >= _mLastSeekT) {
        UInt64 seekInterval = _startTime - _mLastSeekT;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_seek_interval", @(seekInterval));
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"st", @(_startTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"et", @(_endTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"begin_pos", @(_mBeginPos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_pos", @(_mEndPos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"quality_desc_before", _mQualityDescBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bad_interlaced", @(_isAVBadInterlaced));
    
    if (_crosstalkCount >= 2) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"crosstalk_count", @(_crosstalkCount));
    }
    
    return jsonDict;
}

- (void)sendOneAVRenderCheck {
    NSDictionary* eventDict = [self jsonDict];
    if (!eventDict) {
        TTVideoEngineLog(@"OneAVRenderCheck send failed");
        return;
    }

    [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:@"videoplayer_oneevent"];
}

- (void)parseBufferLens {
    if (!self.delegate) {
        return;
    }
    
    NSString* bufs = [self.delegate getLogValueStr:LOGGER_VALUE_BUFS_WHEN_BUFFER_START];
    // eg: @"fvl:0;fal:0;dvl:29280;dal:9959;bvl:0;bal:0;"
    if (!bufs || !bufs.length) {
        return;
    }
    NSArray* array = [bufs componentsSeparatedByString:@";"];
    if (array != nil && array.count > 0) {
        int i = 0;
        if (i < array.count) {
            NSString* fvl = array[i];
            NSRange range = [fvl rangeOfString:@":"];
            _videoFormaterLenMS = [[fvl substringFromIndex:range.location+1] intValue];
        }

        i++;
        if (i < array.count) {
            NSString* fal = array[i];
            NSRange range = [fal rangeOfString:@":"];
            _audioFormaterLenMS = [[fal substringFromIndex:range.location+1] intValue];
        }

        i++;
        if (i < array.count) {
            NSString* dvl = array[i];
            NSRange range = [dvl rangeOfString:@":"];
            _videoLenDecMs = [[dvl substringFromIndex:range.location+1] intValue];
        }

        i++;
        if (i < array.count) {
            NSString* dal = array[i];
            NSRange range = [dal rangeOfString:@":"];
            _audioLenDecMs = [[dal substringFromIndex:range.location+1] intValue];
        }

        i++;
        if (i < array.count) {
            NSString* bvl = array[i];
            NSRange range = [bvl rangeOfString:@":"];
            _videoLenBaseMs = [[bvl substringFromIndex:range.location+1] intValue];
        }

        i++;
        if (i < array.count) {
            NSString* bal = array[i];
            NSRange range = [bal rangeOfString:@":"];
            _audioLenBaseMs = [[bal substringFromIndex:range.location+1] intValue];
        }
    }
}

- (void)noVARenderStart:(NSInteger)pts noRenderType:(int)noRenderType {
    [self noVARenderStart:pts noRenderType:noRenderType extraInfo:nil];
}

- (void)noVARenderStart:(NSInteger)pts noRenderType:(int)noRenderType extraInfo:(NSDictionary *)extraInfo {
    if (_startTime > 0) {
        return;
    }
    
    _mBeginPos = pts;
    _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _noRenderType = noRenderType;
    long long vt = [extraInfo[@"vt"] longLongValue];
    UInt64 lastSeekT = [extraInfo[@"seek_t"] unsignedLongLongValue];
    UInt64 lastRebufT = [extraInfo[@"rebuf_t"] unsignedLongLongValue];
    _firstFrameTime = vt;
    if (lastSeekT == 0LL) {
        _mLastSeekT = _startTime;
    } else {
        _mLastSeekT = lastSeekT;
    }
    if (lastRebufT == 0LL) {
        _mLastRebufT = _startTime;
    } else {
        _mLastRebufT = lastRebufT;
    }
    
    if (_eventBase != nil) {
        _resolutionBefore = _eventBase.currentResolution;
        BOOL abr_used = [[_eventBase.abr_info objectForKey:@"abr_used"] boolValue];
        if (abr_used) {
            _is_abr = 1;
        } else {
            _is_abr = 0;
        }
        _mQualityDescBefore = _eventBase.currentQualityDesc;
        _lastForebackSwitchTime = _eventBase.lastForebackSwitchTime;
        _lastAVSwitchTime = _eventBase.lastAVSwitchTime;
        _lastResSwitchTime = _eventBase.lastResSwitchTime;
        _lastHeadsetSwithTime = _eventBase.lastHeadsetSwithTime;
        _isInBackground = _eventBase.isInBackground;
        _radioMode = _eventBase.radioMode;
        _curHeadset = _eventBase.curHeadset;
        _blueTooth = _eventBase.blueTooth;
    }
    
    if (self.delegate) {
        NSString *renderErrcStr = nil;
        // 0 for video, 1 for audio
        if (0 == noRenderType) {
            renderErrcStr = [self.delegate getLogValueStr:LOGGER_VALUE_ERRC_WHEN_NOV_RENDERSTART];
        }
        
        if (renderErrcStr) {
            NSDictionary *renderErrcDic = TTVideoEngineStringToDicForIntvalue(renderErrcStr, @"=", @";");
            if (renderErrcDic.count > 0) {
                _r_stage_errcs = renderErrcDic;
                if (_eventBase) {
                    _eventBase.r_stage_errcs = renderErrcDic;
                }
            }
        }
        
        [self parseBufferLens];
        
        NSMutableDictionary *callbackInfo = [NSMutableDictionary dictionary];
        [callbackInfo setObject:@(_startTime) forKey:@"t"];
        [callbackInfo setObject:@(noRenderType) forKey:@"type"];
        NSInteger enableNNSR = [self.delegate getLogValueInt:LOGGER_VALUE_ENABLE_NNSR];
        [callbackInfo setObject:@(enableNNSR) forKey:@"enable_nnsr"];
        if (_eventBase) {
            [callbackInfo setObject:_eventBase.currentResolution ?: @"" forKey:@"resolution"];
            [callbackInfo setObject:_eventBase.currentQualityDesc ?: @"" forKey:@"quality_desc"];
            NSString *codec = [_eventBase.videoInfo objectForKey:kTTVideoEngineVideoCodecKey];
            [callbackInfo setObject:codec ?: @"" forKey:@"codec"];
            [callbackInfo setObject:@(_eventBase.hw ? 1 : 0) forKey:@"hw"];
            [callbackInfo setObject:@(_eventBase.lastResSwitchTime) forKey:@"switch_resolution_t"];
        }
        
        if (extraInfo[@"first_frame_cost"]) {
            [callbackInfo setObject:extraInfo[@"first_frame_cost"] forKey:@"first_frame_cost"];
        }
        if (extraInfo[@"ps_t"]) {
            [callbackInfo setObject:extraInfo[@"ps_t"] forKey:@"ps_t"];
        }
        if (extraInfo[@"seek_t"]) {
            [callbackInfo setObject:extraInfo[@"seek_t"] forKey:@"seek_t"];
        }
        
        [self.delegate onInfo:LoggerOptionKeyNOVARenderStateChanged value:TTVideoEngineNOVARenderStateTypeStart extraInfo:callbackInfo];
    }
}

- (NSDictionary *)noVARenderEnd:(NSInteger)pts endType:(NSString *)endType noRenderType:(int *)pNORenderType {
    if (_startTime <= 0) {
        return nil;
    }
    
    int nNORenderType = *pNORenderType;
    if (-1 == *pNORenderType) {
        *pNORenderType = _noRenderType;
    }
    
    _mEndPos = pts;
    _endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _costTime = _endTime - _startTime;
    _endType = endType;
    
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel setObject:@(_startTime) forKey:@"st"];
    [eventModel setObject:@(_costTime) forKey:@"c"];
    
    // consistent with the server stastic
    if (_costTime > 1000) {
        _mIndex++;
        [self sendOneAVRenderCheck];
        
        if (nNORenderType != -1 && self.delegate) {
            NSMutableDictionary *callbackInfo = [NSMutableDictionary dictionary];
            [callbackInfo setObject:@(_endTime) forKey:@"t"];
            [self.delegate onInfo:LoggerOptionKeyNOVARenderStateChanged value:TTVideoEngineNOVARenderStateTypeEnd extraInfo:callbackInfo];
        }
    }
    
    [self clear];
    
    return eventModel;
}

- (void)setEnableMDL:(NSInteger)enable {
    _mEnableMDL = enable;
}

- (void)onAVBadInterlaced {
    _isAVBadInterlaced = 1;
}

- (void)setValue:(id)value WithKey:(NSInteger)key {
    switch (key) {
        case VIDEO_AVRENDERCHECK_KEY_CROSSTALK_COUNT:
            _crosstalkCount = [value integerValue];
            break;
        default:
            break;
    }
}

@end
