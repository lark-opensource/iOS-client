//
//  TTVideoEngineEventOneOutSync.m
//  ABRInterface
//
//  Created by chibaowang on 2021/5/25.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventOneOutSync.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineEventOneEventProtocol.h"
#import "TTVideoEngineEventLoggerProtocol.h"

static const NSString* MonitorName = @"videoplayer_oneevent";

//const for event type
static const NSString* EVENT_TYPE_AVOUTSYNC = @"av_outsync";

@interface TTVideoEngineEventOneOutSync ()

@property (nonatomic, copy) NSString* eventType;
@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;
@property (nonatomic, assign) UInt64 startTime;
@property (nonatomic, assign) UInt64 lastEventTime;
@property (nonatomic, assign) NSInteger costTime;
@property (nonatomic, copy) NSString* endType;
@property (nonatomic, assign) UInt64 firstFrameTime;
@property (nonatomic, assign) long long videoFormaterLenMS;
@property (nonatomic, assign) long long audioFormaterLenMS;
@property (nonatomic, assign) long long videoLenDecMs;
@property (nonatomic, assign) long long audioLenDecMs;
@property (nonatomic, assign) long long videoLenBaseMs;
@property (nonatomic, assign) long long audioLenBaseMs;
@property (nonatomic, assign) UInt64 endTime;
@property (nonatomic, copy) NSString* resolutionBefore;
@property (nonatomic, copy) NSString* resolutionAfter;
@property (nonatomic, assign) NSInteger configBitrateBefore;  //不同步发生时，videoModel中当前清晰度对应的码率
@property (nonatomic, assign) NSInteger configBitrateAfter;   //不同步结束时，videoModel中当前清晰度对应的码率
@property (nonatomic, assign) NSInteger mIndex;
@property (nonatomic, assign) int is_abr;
@property (nonatomic, copy) NSString* mPtsList;
@property (nonatomic, assign) NSInteger mDropCount;
@property (nonatomic, copy) NSString* mVideoDecFpsList;
@property (nonatomic, assign) UInt64 mLastRebufT;
@property (nonatomic, assign) UInt64 mLastSeekT;
@property (nonatomic, assign) UInt64 lastForebackSwitchTime;
@property (nonatomic, assign) UInt64 lastAVSwitchTime;
@property (nonatomic, assign) UInt64 lastResSwitchTime;
@property (nonatomic, assign) UInt64 lastHeadsetSwithTime;
@property (nonatomic, assign) NSInteger mBeginPos;
@property (nonatomic, assign) NSInteger mEndPos;
@property (nonatomic, assign) NSInteger mEnableMDL;
@property (nonatomic, copy) NSString* mQualityDescBefore;  //西瓜的档位码
@property (nonatomic, copy) NSString* mQualityDescAfter;  //西瓜的档位码
@property (nonatomic, assign) int64_t maxAVDiff;
@property (nonatomic, assign) NSInteger isInBackground;
@property (nonatomic, assign) NSInteger radioMode;
@property (nonatomic, assign) NSInteger curHeadset;
@property (nonatomic, assign) NSInteger blueTooth;
@property (nonatomic, strong) NSMutableArray *pauseTimeList;  //音画不同步过程中暂停的时间
@property (nonatomic, assign) NSInteger isAVBadInterlaced;
@property (nonatomic, assign) NSInteger crosstalkCount;

@end

@implementation TTVideoEngineEventOneOutSync

@synthesize delegate = _delegate;
@synthesize avOutsyncCount = _avOutsyncCount;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base {
    if (self = [super init]) {
        _eventBase = base;
        _eventType = nil;
        _costTime = LOGGER_INTEGER_EMPTY_VALUE;
        _endType = nil;
        _startTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastEventTime = LOGGER_INTEGER_EMPTY_VALUE;
        _endTime = LOGGER_INTEGER_EMPTY_VALUE;
        _firstFrameTime = LOGGER_INTEGER_EMPTY_VALUE;
        _videoFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
        _audioFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
        _mIndex = 0;
        _resolutionBefore = nil;
        _resolutionAfter = nil;
        _configBitrateBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _configBitrateAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _is_abr = LOGGER_INTEGER_EMPTY_VALUE;
        _mPtsList = nil;
        _mDropCount = LOGGER_INTEGER_EMPTY_VALUE;
        _mVideoDecFpsList = nil;
        _mLastSeekT = LOGGER_INTEGER_EMPTY_VALUE;
        _mLastRebufT = LOGGER_INTEGER_EMPTY_VALUE;
        _mBeginPos = LOGGER_INTEGER_EMPTY_VALUE;
        _mEndPos = LOGGER_INTEGER_EMPTY_VALUE;
        _mEnableMDL = LOGGER_INTEGER_EMPTY_VALUE;
        _mQualityDescBefore = nil;
        _mQualityDescAfter = nil;
        _avOutsyncCount = 0;
        _maxAVDiff = LOGGER_INTEGER_EMPTY_VALUE;
        _lastForebackSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastAVSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastResSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastHeadsetSwithTime = LOGGER_INTEGER_EMPTY_VALUE;
        _isInBackground = 0;
        _radioMode = 0;
        _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
        _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
        _pauseTimeList = [NSMutableArray array];
        _isAVBadInterlaced = 0;
        _crosstalkCount = 0;
    }
    return self;
}

- (void)clear {
    _eventType = nil;
    _costTime = LOGGER_INTEGER_EMPTY_VALUE;
    _endType = nil;
    _startTime = LOGGER_INTEGER_EMPTY_VALUE;
    _endTime = LOGGER_INTEGER_EMPTY_VALUE;
    _firstFrameTime = LOGGER_INTEGER_EMPTY_VALUE;
    _videoFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
    _audioFormaterLenMS = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenDecMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenBaseMs = LOGGER_INTEGER_EMPTY_VALUE;
    _resolutionBefore = nil;
    _resolutionAfter = nil;
    _configBitrateBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _configBitrateAfter = LOGGER_INTEGER_EMPTY_VALUE;
    _is_abr = LOGGER_INTEGER_EMPTY_VALUE;
    _mPtsList = nil;
    _mDropCount = LOGGER_INTEGER_EMPTY_VALUE;
    _mVideoDecFpsList = nil;
    _mLastSeekT = LOGGER_INTEGER_EMPTY_VALUE;
    _mLastRebufT = LOGGER_INTEGER_EMPTY_VALUE;
    _mBeginPos = LOGGER_INTEGER_EMPTY_VALUE;
    _mEndPos = LOGGER_INTEGER_EMPTY_VALUE;
    _mEnableMDL = LOGGER_INTEGER_EMPTY_VALUE;
    _mQualityDescBefore = nil;
    _mQualityDescAfter = nil;
    _maxAVDiff = LOGGER_INTEGER_EMPTY_VALUE;
    _lastForebackSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastAVSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastResSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
    _lastHeadsetSwithTime = LOGGER_INTEGER_EMPTY_VALUE;
    _isInBackground = 0;
    _radioMode = 0;
    _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
    _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
    [_pauseTimeList removeAllObjects];
    _crosstalkCount = 0;
}

- (NSDictionary*)jsonDict {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    //required for event v3
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"params_for_special", @"videoplayer_monitor");
    if (_eventBase != nil) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_sessionid", _eventBase.session_id);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"sdk_version", _eventBase.sdk_version);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"pc", _eventBase.pc);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"pv", _eventBase.pv);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"sv", _eventBase.sv);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"tag", _eventBase.tag);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"subtag", _eventBase.subtag);
        if (_eventBase.curURL && _eventBase.curURL.length > 0) {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_url", _eventBase.curURL);
        } else {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_url", _eventBase.initialURL);
        }
        if (_eventBase.internal_ip && _eventBase.internal_ip.length > 0) {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_ip", _eventBase.internal_ip);
        } else {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cdn_ip", _eventBase.initial_ip);
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
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_type", [_eventBase getNetworkType]);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_duration", @(_eventBase.video_stream_duration));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_duration", @(_eventBase.audio_stream_duration));
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_mdl", @(_mEnableMDL));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"event_type", _eventType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cost_time", @(_costTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_type", _endType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_before", _resolutionBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_after", _resolutionAfter);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bitrate_before", @(_configBitrateBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bitrate_after", @(_configBitrateAfter));
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
    
    if (_lastEventTime > 0LL && _startTime >= _lastEventTime) {
        UInt64 interval = _startTime - _lastEventTime;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_event_interval", @(interval));
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_len_before", @(_videoFormaterLenMS));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_len_before", @(_audioFormaterLenMS));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_dec_before", @(_videoLenDecMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_base_before", @(_videoLenBaseMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_dec_before", @(_audioLenDecMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_base_before", @(_audioLenBaseMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"index", @(_mIndex));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"st", @(_startTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"et", @(_endTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"begin_pos", @(_mBeginPos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_pos", @(_mEndPos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"drop_cnt", @(_mDropCount));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pts_list", _mPtsList);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_dec_fps_list", _mVideoDecFpsList);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"quality_desc_before", _mQualityDescBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"quality_desc_after", _mQualityDescAfter);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"max_av_diff", @(_maxAVDiff));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pause_time_list", _pauseTimeList);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bad_interlaced", @(_isAVBadInterlaced));
    if (_crosstalkCount >= 2) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"crosstalk_count", @(_crosstalkCount));
    }
    
    return jsonDict;
}

- (void)sendOneOutsync {
    NSDictionary* eventDict = [self jsonDict];
    if (!eventDict) {
        TTVideoEngineLog(@"OneOutsync send failed");
        return;
    }

    [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:@"videoplayer_oneevent"];
}

- (void)avOutsyncStart:(NSInteger) pts vt:(long long)vt lastSeekT:(UInt64)lastSeekT lastRebufT:(UInt64)lastRebufT {
    _mBeginPos = pts;
    _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _eventType = [EVENT_TYPE_AVOUTSYNC copy];
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
        _configBitrateBefore = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
        // to do: common logic should placed in the parent class
        //parse buffers
        NSString* bufs = [self.delegate getLogValueStr:LOGGER_VALUE_BUFS_WHEN_BUFFER_START];
//        NSString* bufs = @"fvl:0;fal:0;dvl:29280;dal:9959;bvl:0;bal:0;";
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
    [self avOutsyncStartCallback];
}

- (NSDictionary *)avOutsyncEnd:(NSInteger) pts endType:(NSString *)endType {
    if (_startTime <= 0) {
        return nil;
    }
    _mEndPos = pts;
    _endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _costTime = _endTime - _startTime;
    _endType = endType;
    
    if (self.delegate) {
        _mDropCount = [self.delegate getLogValueInt:LOGGER_VALUE_GET_OUTLET_DROP_COUNT_ONCE];
    }
    //less than 200ms not report
    if (_costTime <= 200) {
        [self avOutsyncEndCallback];
        [self clear];
        return nil;
    }
    _mIndex++;
    _avOutsyncCount++;
    if (_eventBase != nil) {
        _mQualityDescAfter = _eventBase.currentQualityDesc;
        _resolutionAfter = _eventBase.currentResolution;
    }
    if (self.delegate) {
        _mPtsList = [self.delegate getLogValueStr:LOGGER_VALUE_AV_PTS_DIFF_LIST];
        _mVideoDecFpsList = [self.delegate getLogValueStr:LOGGER_VALUE_VIDEO_DEC_OUTPUT_FPS_LIST];
        _maxAVDiff = [self.delegate getLogValueInt64:LOGGER_VALUE_AVOUTSYNC_MAX_AVDIFF];
    }
    
    NSMutableDictionary *outSyncEventModel = [NSMutableDictionary dictionary];
    [outSyncEventModel setObject:@(_mBeginPos) forKey:@"ps"];
    [outSyncEventModel setObject:@(_mEndPos) forKey:@"pe"];
    [outSyncEventModel setObject:@(_startTime) forKey:@"st"];
    [outSyncEventModel setObject:@(_costTime) forKey:@"c"];
    
    _lastEventTime = _endTime;
    [self sendOneOutsync];
    
    [self avOutsyncEndCallback];
    
    [self clear];
    
    return outSyncEventModel;
}

- (void)avOutsyncStartCallback {
    if (self.delegate) {
        NSMutableDictionary* extraInfo = [NSMutableDictionary dictionary];
        [extraInfo setObject:@(_mBeginPos) forKey:@"pts"];
        [self.delegate onInfo:LoggerOptionKeyAVOutsyncStateChanged value:TTVideoEngineAVOutsyncTypeStart extraInfo:extraInfo];
    }
}

- (void)avOutsyncEndCallback {
    if (self.delegate) {
        int64_t clockDiff = [self.delegate getLogValueInt64:LOGGER_VALUE_CLOCK_DIFF];
        NSInteger containerFPS = [self.delegate getLogValueInt:LOGGER_VALUE_CONTAINER_FPS];
        CGFloat videooutFPS = [self.delegate getLogValueFloat:LOGGER_VALUE_VIDEO_OUT_FPS];
        NSInteger videoDecoderOutputFPS = [self.delegate getLogValueInt:LOGGER_VALUE_VIDEODECODER_OUTPUT_FPS];
        CGFloat decoderTime = 0.0f;
        if (videoDecoderOutputFPS > 0) {
            decoderTime = 1000.0/videoDecoderOutputFPS;
        }
        
        NSMutableDictionary* extraInfo = [NSMutableDictionary dictionary];
        [extraInfo setObject:@(TTVideoEngineValidNumber(_mEndPos)) forKey:@"pts"];
        [extraInfo ttvideoengine_setObject:@(TTVideoEngineValidNumber(containerFPS)) forKey:@"container_fps"];
        [extraInfo ttvideoengine_setObject:@(TTVideoEngineValidNumber(videooutFPS)) forKey:@"video_out_fps"];
        [extraInfo ttvideoengine_setObject:@(TTVideoEngineValidNumber(_mDropCount)) forKey:@"render_drop_count"];
        [extraInfo ttvideoengine_setObject:@(TTVideoEngineValidNumber(decoderTime)) forKey:@"decode_time"];
        [extraInfo setObject:@(clockDiff) forKey:@"clock_diff"];
        [self.delegate onInfo:LoggerOptionKeyAVOutsyncStateChanged value:TTVideoEngineAVOutsyncTypeEnd extraInfo:extraInfo];
    }
}

- (void)setEnableMDL:(NSInteger)enable {
    _mEnableMDL = enable;
}

- (void)setValue:(id)value WithKey:(NSInteger)key {
    switch (key) {
        case VIDEO_OUTSYNC_KEY_PAUSE_TIME:
            [self.pauseTimeList addObject:@([value unsignedLongLongValue])];
            break;
        case VIDEO_OUTSYNC_KEY_CROSSTALK_COUNT:
            _crosstalkCount = [value integerValue];
            break;
        default:
            break;
    }
}

- (void)onAVBadInterlaced {
    _isAVBadInterlaced = 1;
}

@end
