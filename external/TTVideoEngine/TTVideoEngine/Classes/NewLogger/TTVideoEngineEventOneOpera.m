//
//  TTVideoEngineEventOneOpera.m
//  FLEX
//
//  Created by chibaowang on 2019/10/20.
//

#import "TTVideoEngineEventOneOpera.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineEventLoggerProtocol.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventManager.h"
#import "NSDictionary+TTVideoEngine.h"

@interface TTVideoEngineEventOneOpera ()

@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;
@property (nonatomic, copy) NSString* operaType;
@property (nonatomic, copy) NSString* endType;
@property (nonatomic, assign) UInt64 startTime;
@property (nonatomic, assign) UInt64 endTime;
@property (nonatomic, assign) UInt64 costTime;
@property (nonatomic, nullable, strong) NSMutableDictionary* lastOperaTime;
@property (nonatomic, assign) NSInteger fromVideoPos;
@property (nonatomic, assign) NSInteger toVideoPos;
@property (nonatomic, copy) NSString* stateBefore;
@property (nonatomic, copy) NSString* stateAfter;
@property (nonatomic, assign) long long audioLenAfter;
@property (nonatomic, assign) long long videoLenAfter;
@property (nonatomic, assign) long long downloadSpeed;
@property (nonatomic, assign) NSInteger isSeekInCache;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) NSInteger mIndex;
@property (nonatomic, copy) NSString* resolutionBefore;
@property (nonatomic, copy) NSString* resolutionAfter;
@property (nonatomic, assign) NSInteger configBitrateBefore;
@property (nonatomic, assign) NSInteger configBitrateAfter;

@end

@implementation TTVideoEngineEventOneOpera

@synthesize delegate = _delegate;
@synthesize reportLevel = _reportLevel;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase *)base {
    if (self = [super init]) {
        _eventBase = base;
        _operaType = nil;
        _endType = nil;
        _startTime = LOGGER_INTEGER_EMPTY_VALUE;
        _endTime = LOGGER_INTEGER_EMPTY_VALUE;
        _costTime = LOGGER_INTEGER_EMPTY_VALUE;
        _lastOperaTime = [[NSMutableDictionary alloc] init];
        _fromVideoPos = LOGGER_INTEGER_EMPTY_VALUE;
        _toVideoPos = LOGGER_INTEGER_EMPTY_VALUE;
        _stateAfter = nil;
        _stateBefore = nil;
        _audioLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _videoLenAfter = LOGGER_INTEGER_EMPTY_VALUE;
        _isSeekInCache = 0;
        _retryCount = 0;
        _mIndex = 0;
    }
    return self;
}

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver {
    _retryCount++;
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
        
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_speed", @(_eventBase.mdl_speed));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_req_t", @(_eventBase.mdl_req_t));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_end_t", @(_eventBase.mdl_end_t));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_dns_t", @(_eventBase.mdl_dns_t));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_tcp_start_t", @(_eventBase.mdl_tcp_start_t));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_tcp_end_t", @(_eventBase.mdl_tcp_end_t));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_ttfp", @(_eventBase.mdl_ttfp));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_httpfb", @(_eventBase.mdl_httpfb));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_req_pos", @(_eventBase.mdl_cur_req_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_end_pos", @(_eventBase.mdl_cur_end_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_cache_pos", @(_eventBase.mdl_cur_cache_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cache_type", @(_eventBase.mdl_cache_type));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_ip", _eventBase.mdl_cur_ip);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_reply_size", @(_eventBase.mdl_reply_size));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_down_pos", @(_eventBase.mdl_down_pos));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_error_code", @(_eventBase.mdl_error_code));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_http_code", @(_eventBase.mdl_http_code));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_ip_list", _eventBase.mdl_ip_list);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_blocked_ips", _eventBase.mdl_blocked_ips);
    }

    TTVideoEngineLoggerPutToDictionary(jsonDict, @"opera_type", _operaType);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cost_time", @(_costTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_type", _endType);
    
    _stateBefore = [NSString stringWithFormat:@"%d", _fromVideoPos];
    _stateAfter = [NSString stringWithFormat:@"%d", _toVideoPos];
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"state_before", _stateBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"state_after", _stateAfter);

    UInt64 nowT = [[NSDate date] timeIntervalSince1970] * 1000;
    id tmp_value = [_lastOperaTime objectForKey:OPERA_TYPE_SEEK];
    if (tmp_value != nil) {
        UInt64 last_event_time = [tmp_value longLongValue];
        if (last_event_time > 0LL) {
            long interval = nowT - last_event_time;
            [jsonDict setObject:@(interval) forKey:@"last_interval"];
        }
        [_lastOperaTime removeObjectForKey:OPERA_TYPE_SEEK];
    }
    [_lastOperaTime setObject:@(nowT) forKey:OPERA_TYPE_SEEK];

    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_len_after", @(_videoLenAfter));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_len_after", @(_audioLenAfter));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_speed", @(_downloadSpeed));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"is_seek_in_buffer", @(_isSeekInCache));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"retry_count", @(_retryCount));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"index", @(_mIndex));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_before", _resolutionBefore);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_after", _resolutionAfter);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bitrate_before", @(_configBitrateBefore));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bitrate_after", @(_configBitrateAfter));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"st", @(_startTime));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"et", @(_endTime));
    
    return jsonDict;
}

- (void)sendOneOpera:(int)reportType {
    if ((_reportLevel & reportType) == 0) {
        return;
    }
    NSDictionary* eventDict = [self jsonDict];
    if (!eventDict) {
        TTVideoEngineLog(@"OneError send failed");
        return;
    }
    
    [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:@"videoplayer_oneopera"];
}

- (void)seekToTime:(NSTimeInterval)fromPos toPos:(NSTimeInterval)toPos {
    //s to ms
    _fromVideoPos = fromPos * 1000;
    _toVideoPos = toPos * 1000;
    _operaType = [OPERA_TYPE_SEEK copy];
    _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _mIndex++;
    if (_eventBase) {
        _resolutionBefore = _eventBase.currentResolution;
    }
    if (self.delegate) {
        _configBitrateBefore = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
    }
}

- (NSDictionary *)endSeek:(NSString*)reason isSeekInCache:(NSInteger)isSeekInCache {
    
    _endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (_startTime > 0LL) {
        _costTime = _endTime - _startTime;
    }
    
    _endType = reason;
    if (_eventBase) {
        _resolutionAfter = _eventBase.currentResolution;
    }
    
    _isSeekInCache = isSeekInCache;
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
            NSDictionary* dict = [self.delegate bytesInfoForEventLogger:nil];
            if (dict) {
                _videoLenAfter = [[dict objectForKey:@"vlen"] longLongValue];
                _audioLenAfter= [[dict objectForKey:@"alen"] longLongValue];
                _downloadSpeed = [[dict objectForKey:@"download_speed"] longLongValue];
            }
        }
        _configBitrateAfter = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
    }
    if (self.eventBase) {
        [self.eventBase updateMDLInfo];
    }
    
    NSMutableDictionary *seekEventModel = [NSMutableDictionary dictionary];
    [seekEventModel ttvideoengine_setObject:@(_fromVideoPos) forKey:@"fr"];
    [seekEventModel ttvideoengine_setObject:@(_toVideoPos) forKey:@"to"];
    [seekEventModel ttvideoengine_setObject:@(_endTime) forKey:@"t"];
    [seekEventModel ttvideoengine_setObject:@(_costTime) forKey:@"c"];
    
    [self sendOneOpera:OPERA_REPORT_SEEK];
    
    return seekEventModel;
}

@end
