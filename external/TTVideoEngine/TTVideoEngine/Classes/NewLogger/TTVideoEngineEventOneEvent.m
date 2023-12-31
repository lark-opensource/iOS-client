//
//  TTVideoEngineEventOneEvent.m
//  FLEX
//
//  Created by chibaowang on 2019/10/20.
//

#import "TTVideoEngineEventOneEvent.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineEventLoggerProtocol.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventManager.h"
#import "NSDictionary+TTVideoEngine.h"

static const NSString* MonitorName = @"videoplayer_oneevent";

//const for event type
static const NSString* EVENT_TYPE_NET = @"block_net";
static const NSString* EVENT_TYPE_DECODE = @"block_decode";

@interface TTVideoEngineEventOneEvent ()

@property (nonatomic, copy) NSString* eventType;
@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) BOOL isFirstFrameShown;
@property (nonatomic, assign) UInt64 startTime;
@property (nonatomic, assign) NSInteger costTime;
@property (nonatomic, assign) long long mAccuCostTime;
@property (nonatomic, copy) NSString* endType;
@property (nonatomic, assign) int64_t lastSeekTime;
@property (nonatomic, assign) UInt64 firstFrameTime;
@property (nonatomic, nullable, strong) NSMutableDictionary* lastEventTime;
@property (nonatomic, assign) NSInteger videoPos;
@property (nonatomic, assign) long long videoLenBefore;
@property (nonatomic, assign) long long audioLenBefore;
@property (nonatomic, assign) long long videoLenAfter;
@property (nonatomic, assign) long long audioLenAfter;
@property (nonatomic, assign) long long videoLenDecBeforeMs;
@property (nonatomic, assign) long long videoLenDecAfterMs;
@property (nonatomic, assign) long long audioLenDecBeforeMs;
@property (nonatomic, assign) long long audioLenDecAfterMs;
@property (nonatomic, assign) long long videoLenBaseBeforeMs;
@property (nonatomic, assign) long long videoLenBaseAfterMs;
@property (nonatomic, assign) long long audioLenBaseBeforeMs;
@property (nonatomic, assign) long long audioLenBaseAfterMs;
@property (nonatomic, assign) long long videoLenOnlyBefore; // videoLenBefore not contain mdl buffer len
@property (nonatomic, assign) long long audioLenOnlyBefore; // audioLenBefore not contain mdl buffer len
@property (nonatomic, assign) int64_t playerReqOffset;
@property (nonatomic, assign) long long bytesFromMDL;
@property (nonatomic, assign) NSInteger mIndex;
@property (nonatomic, assign) UInt64 endTime;
@property (nonatomic, copy) NSString* resolutionBefore;
@property (nonatomic, copy) NSString* resolutionAfter;
@property (nonatomic, assign) NSInteger configBitrateBefore;  //卡顿发生时，videoModel中当前清晰度对应的码率
@property (nonatomic, assign) NSInteger configBitrateAfter;   //卡顿结束时，videoModel中当前清晰度对应的码率
@property (nonatomic, assign) int is_abr;
@property (nonatomic, assign) UInt64 preBufferTimeMs;
@property (nonatomic, assign) NSInteger bufferReason;  // 1 video, 2 audio, 3 both
@property (nonatomic, copy) NSString* mQualityDescBefore;  //西瓜的档位码
@property (nonatomic, copy) NSString* mQualityDescAfter;  //西瓜的档位码
@property (nonatomic, assign) NSInteger isInBackground;
@property (nonatomic, assign) NSInteger radioMode;
@property (nonatomic, assign) NSInteger curHeadset;
@property (nonatomic, assign) NSInteger blueTooth;
@property (nonatomic, assign) UInt64 lastForebackSwitchTime;
@property (nonatomic, assign) UInt64 lastAVSwitchTime;
@property (nonatomic, assign) UInt64 lastResSwitchTime;
@property (nonatomic, assign) UInt64 lastHeadsetSwithTime;
@property (nonatomic, assign) NSInteger isAVBadInterlaced;
@property (nonatomic, assign) NSInteger crosstalkCount;

@end


@implementation TTVideoEngineEventOneEvent

@synthesize delegate = _delegate;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base {
    if (self = [super init]) {
        _eventBase = base;
        _eventType = nil;
        _retryCount = 0;
        _isFirstFrameShown = NO;
        _costTime = LOGGER_INTEGER_EMPTY_VALUE;
        _endType = nil;
        _lastEventTime = [[NSMutableDictionary alloc] init];
        _startTime = LOGGER_INTEGER_EMPTY_VALUE;
        _endTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastSeekTime = LOGGER_INTEGER_EMPTY_VALUE;
        _firstFrameTime = LOGGER_INTEGER_EMPTY_VALUE;
        _videoPos = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenDecBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenDecAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenDecAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenDecBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenBaseBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenBaseAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenBaseAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenBaseBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenOnlyBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _audioLenOnlyBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _playerReqOffset = LOGGER_INTEGER_EMPTY_VALUE;
        _bytesFromMDL = LOGGER_INTEGER_EMPTY_VALUE;
        _mAccuCostTime = 0LL;
        _mIndex = 0;
        _resolutionBefore = nil;
        _resolutionAfter = nil;
        _configBitrateBefore = LOGGER_INTEGER_EMPTY_VALUE;
        _configBitrateAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _is_abr = LOGGER_INTEGER_EMPTY_VALUE;
        _preBufferTimeMs = LOGGER_INTEGER_EMPTY_VALUE;
        _bufferReason = LOGGER_INTEGER_EMPTY_VALUE;
        _mQualityDescBefore = nil;
        _mQualityDescAfter = nil;
        _lastForebackSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastAVSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastResSwitchTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastHeadsetSwithTime = LOGGER_INTEGER_EMPTY_VALUE;
        _isInBackground = 0;
        _radioMode = 0;
        _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
        _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
        _isAVBadInterlaced = 0;
        _crosstalkCount = 0;
    }
    return self;
}

- (void)clear {
    _costTime = LOGGER_INTEGER_EMPTY_VALUE;
    _endType = nil;
    _startTime = LOGGER_INTEGER_EMPTY_VALUE;
    _endTime = LOGGER_INTEGER_EMPTY_VALUE;
    _videoPos = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenDecBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenDecAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenDecAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenDecBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenBaseBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenBaseAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenBaseAfterMs = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenBaseBeforeMs = LOGGER_INTEGER_EMPTY_VALUE;
    _videoLenOnlyBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _audioLenOnlyBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _playerReqOffset = LOGGER_INTEGER_EMPTY_VALUE;
    _resolutionBefore = nil;
    _resolutionAfter = nil;
    _configBitrateBefore = LOGGER_INTEGER_EMPTY_VALUE;
    _configBitrateAfter = LOGGER_INTEGER_EMPTY_VALUE;
    _bytesFromMDL = LOGGER_INTEGER_EMPTY_VALUE;
    _preBufferTimeMs = LOGGER_INTEGER_EMPTY_VALUE;
    _bufferReason = LOGGER_INTEGER_EMPTY_VALUE;
    _mQualityDescBefore = nil;
    _mQualityDescAfter = nil;
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

- (void)showedFirstFrame {
    _isFirstFrameShown = YES;
    _firstFrameTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void)movieShouldRetry {
    _retryCount++;
}

- (void)seekHappend {
    _lastSeekTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (NSDictionary *)jsonDict {
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
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"reuse_socket", @(_eventBase.reuse_socket));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_type", [_eventBase getNetworkType]);
        
        //mdl related
        if (_eventBase.mdl_conc_count != -1) {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_conc_count", @(_eventBase.mdl_conc_count));
        }
        int mdl_mem_buffer_len = _eventBase.mdlVideoInfo.mdl_mem_buffer_len;
        int64_t mdl_disk_buffer_len = _eventBase.mdlVideoInfo.mdl_disk_buffer_len;
        int64_t mdl_send_offset = _eventBase.mdlVideoInfo.mdl_send_offset;
        int64_t mdl_last_req_offset = _eventBase.mdlVideoInfo.mdl_last_req_offset;
        NSString *mdl_last_ip_list = _eventBase.mdlVideoInfo.mdl_last_ip_list;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_mem_buffer_len", @(mdl_mem_buffer_len));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_disk_buffer_len", @(mdl_disk_buffer_len));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_send_offset", @(mdl_send_offset));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_last_req_offset", @(mdl_last_req_offset));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_last_ip_list", mdl_last_ip_list);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_req_pos", @(_eventBase.mdl_cur_req_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_end_pos", @(_eventBase.mdl_cur_end_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_cache_pos", @(_eventBase.mdl_cur_cache_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cache_type", @(_eventBase.mdl_cache_type));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_ip", _eventBase.mdl_cur_ip);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_host", _eventBase.mdl_cur_host);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"reply_size", @(_eventBase.mdl_reply_size));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"down_pos", @(_eventBase.mdl_down_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_wait_time", @(_eventBase.mdl_player_wait_time));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_wait_num", @(_eventBase.mdl_player_wait_num));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_stage", @(_eventBase.mdl_stage));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_ec", @(_eventBase.mdl_error_code));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_task_num", @(_eventBase.mdl_cur_task_num));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_speed", @(_eventBase.mdl_speed));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_file_key", _eventBase.mdl_file_key);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_is_socrf", @(_eventBase.mdl_is_socrf));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_req_num", @(_eventBase.mdl_req_num));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_url_index", @(_eventBase.mdl_url_index));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_re_url", _eventBase.mdl_re_url);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_source", @(_eventBase.mdl_cur_soure));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_extra_info", _eventBase.mdl_extra_info);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_fs", @(_eventBase.mdl_fs));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_p2p_sp", @(_eventBase.mdl_pcdn_full_speed));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_tbs", @(_eventBase.mdl_tbs));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_lbs", @(_eventBase.mdl_lbs));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_response_cinfo", _eventBase.mdl_response_cinfo);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_response_cache", _eventBase.mdl_response_cache);
    }

    TTVideoEngineLoggerPutToDictionary(jsonDict, @"event_type", _eventType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cost_time", @(_costTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_type", _endType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"retry_count", @(_retryCount));
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
    
    UInt64 nowT = [[NSDate date] timeIntervalSince1970] * 1000;
    id tmp_value = [_lastEventTime objectForKey:EVENT_TYPE_NET];
    if (tmp_value != nil) {
        UInt64 last_event_time = [tmp_value longLongValue];
        if (last_event_time > 0LL) {
            long interval = nowT - last_event_time;
            [jsonDict setObject:@(interval) forKey:@"last_event_interval"];
        }
        [_lastEventTime removeObjectForKey:EVENT_TYPE_NET];
    }
    [_lastEventTime setObject:@(nowT) forKey:EVENT_TYPE_NET];
    
    if (_lastSeekTime > 0) {
        int seekInterval = _startTime - _lastSeekTime;
        [jsonDict setObject:@(seekInterval) forKey:@"last_seek_interval"];
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_pos", @(_videoPos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"read_count_mdl", @(_bytesFromMDL));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_len_before", @(_videoLenBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_len_after", @(_videoLenAfter));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_len_before", @(_audioLenBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_len_after", @(_audioLenAfter));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_dec_after", @(_videoLenDecAfterMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_dec_before", @(_videoLenDecBeforeMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_base_after", @(_videoLenBaseAfterMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_base_before", @(_videoLenBaseBeforeMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_dec_after", @(_audioLenDecAfterMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_dec_before", @(_audioLenDecBeforeMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_base_after", @(_audioLenBaseAfterMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_base_before", @(_audioLenBaseBeforeMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vlen_only_before", @(_videoLenOnlyBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"alen_only_before", @(_audioLenOnlyBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_req_offset", @(_playerReqOffset));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"index", @(_mIndex));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"st", @(_startTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"et", @(_endTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pst", @(_preBufferTimeMs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"buffer_reason", @(_bufferReason));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"quality_desc_before", _mQualityDescBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"quality_desc_after", _mQualityDescAfter);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bad_interlaced", @(_isAVBadInterlaced));
    if (_crosstalkCount >= 2) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"crosstalk_count", @(_crosstalkCount));
    }
    
    return jsonDict;
}

- (void)sendOneEvent {
    NSDictionary* eventDict = [self jsonDict];
    if (!eventDict) {
        TTVideoEngineLog(@"OneError send failed");
        return;
    }
    
    [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:@"videoplayer_oneevent"];
}

- (void)moviePreStall:(NSInteger)reason {
    _preBufferTimeMs = [[NSDate date] timeIntervalSince1970] * 1000;
    _bufferReason = reason;
    if (self.eventBase) {
        [self.eventBase updateMDLInfo];
    }
    
    if (self.delegate) {
        _playerReqOffset = [self.delegate getLogValueInt64:LOGGER_VALUE_PLAYER_REQ_OFFSET];
    }
}

- (NSInteger) getMovieStalledReason {
    return _bufferReason;
}

- (void)movieStalled:(NSInteger)curPos {
    _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _videoPos = curPos;
    _eventType = [EVENT_TYPE_NET copy];
    _mIndex++;
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
        if ([self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
            NSDictionary* dict = [self.delegate bytesInfoForEventLogger:nil];
            if (dict) {
                _bytesFromMDL = [[dict objectForKey:@"vds"] longLongValue];
            }
        }
        _configBitrateBefore = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
        
        //parse first frame items
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
                _videoLenBefore = [[fvl substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString* fal = array[i];
                NSRange range = [fal rangeOfString:@":"];
                _audioLenBefore = [[fal substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString* dvl = array[i];
                NSRange range = [dvl rangeOfString:@":"];
                _videoLenDecBeforeMs = [[dvl substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString* dal = array[i];
                NSRange range = [dal rangeOfString:@":"];
                _audioLenDecBeforeMs = [[dal substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString* bvl = array[i];
                NSRange range = [bvl rangeOfString:@":"];
                _videoLenBaseBeforeMs = [[bvl substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString* bal = array[i];
                NSRange range = [bal rangeOfString:@":"];
                _audioLenBaseBeforeMs = [[bal substringFromIndex:range.location+1] intValue];
            }
            
            i++;
            if (i < array.count) {
                NSString *fvl_only = array[i];
                NSRange range = [fvl_only rangeOfString:@":"];
                if (range.location != NSNotFound && range.location+1 < fvl_only.length) {
                    _videoLenOnlyBefore = [[fvl_only substringFromIndex:range.location+1] longLongValue];
                }
            }
            
            i++;
            if (i < array.count) {
                NSString *fal_only = array[i];
                NSRange range = [fal_only rangeOfString:@":"];
                if (range.location != NSNotFound && range.location+1 < fal_only.length) {
                    _audioLenOnlyBefore = [[fal_only substringFromIndex:range.location+1] longLongValue];
                }
            }
        }
    }
}

- (NSDictionary *)movieStallEnd:(NSString*)reason {
    if (_startTime <= 0LL || _eventType == nil) {
        return nil;
    }
    
    _endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _costTime = _endTime - _startTime;
    if (_costTime > 0) {
        _mAccuCostTime += _costTime;
    }
    _endType = reason;
    if (_eventBase != nil) {
        _resolutionAfter = _eventBase.currentResolution;
        _mQualityDescAfter = _eventBase.currentQualityDesc;
    }
    if (self.delegate) {
        _configBitrateAfter = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
        if ([self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
            NSDictionary* dict = [self.delegate bytesInfoForEventLogger:nil];
            if (dict) {
                _videoLenAfter = [[dict objectForKey:@"vlen"] longLongValue];
                _audioLenAfter= [[dict objectForKey:@"alen"] longLongValue];
                _videoLenDecAfterMs = [[dict objectForKey:@"vDecLen"] longLongValue];
                _audioLenDecAfterMs = [[dict objectForKey:@"aDecLen"] longLongValue];
                _videoLenBaseAfterMs = [[dict objectForKey:@"vBaseLen"] longLongValue];
                _audioLenBaseAfterMs = [[dict objectForKey:@"aBaseLen"] longLongValue];
            }
        }
    }
    
    NSMutableDictionary *stallEventModel = [NSMutableDictionary dictionary];
    [stallEventModel ttvideoengine_setObject:@(_videoPos) forKey:@"p"];
    [stallEventModel ttvideoengine_setObject:@(_endTime) forKey:@"t"];
    [stallEventModel ttvideoengine_setObject:@(_costTime) forKey:@"c"];

    [self sendOneEvent];
    
    [self clear];
    
    return stallEventModel;
}

- (long long)getAccuCostTime {
    return _mAccuCostTime;
}

- (void)onAVBadInterlaced {
    _isAVBadInterlaced = 1;
}

- (void)setValue:(id)value WithKey:(NSInteger)key {
    switch (key) {
        case VIDEO_ONEEVENT_KEY_CROSSTALK_COUNT:
            _crosstalkCount = [value integerValue];
            break;
        default:
            break;
    }
}

@end
