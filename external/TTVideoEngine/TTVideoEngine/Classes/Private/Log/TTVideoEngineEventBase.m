//
//  TTVideoEngineEventBase.m
//  FLEX
//
//  Created by chibaowang on 2019/10/20.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventBase.h"
#import "TTVideoNetUtils.h"
#import "TTVideoEngineEventLoggerProtocol.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSDictionary+TTVideoEngine.h"

@implementation TTVideoEngineEventBase

- (instancetype)init {
    if(self = [super init]) {
        _videoInfo = [NSMutableDictionary dictionary];
        _device_id = nil;
        _source_type = nil;
        _sv = nil, _pv = nil, _pc = nil, _sdk_version = nil, _vid = nil;
        _tag = @"default", _subtag = @"default";
        _currentResolution = nil;
        _lastResolution = nil;
        _initial_resolution = nil;
        _initial_ip = nil;
        _initialURL = nil, _curURL = nil, _internal_ip = nil;
        
        _drm_type = LOGGER_INTEGER_EMPTY_VALUE;
        _drm_token_url = @"";
        _play_type = 0;
        _audio_codec_nameId = LOGGER_INTEGER_EMPTY_VALUE;
        _video_codec_nameId = LOGGER_INTEGER_EMPTY_VALUE;
        _hw = NO;
        _hw_user = NO;
        _format_type = LOGGER_INTEGER_EMPTY_VALUE;
        _playSpeed = 1.0;
        _reuse_socket = LOGGER_INTEGER_EMPTY_VALUE;
        _abr_info = [NSMutableDictionary dictionary];
        
        //generate temporary sessionID to avoid reporting null
        _session_id = [self generateTraceID:nil];
        _delegate = nil;
        
        _mdl_cur_req_pos = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_cur_end_pos = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_cur_cache_pos = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_cache_type = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_cur_ip = nil;
        _mdl_cur_host = nil;
        _mdl_cur_url = nil;
        _mdl_reply_size = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_down_pos = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_player_wait_num = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_player_wait_time = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_stage = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_error_code = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_cur_task_num = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_conc_count = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_speed = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_file_key = nil;
        _mdl_is_socrf = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_req_num = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_url_index = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_re_url = nil;
        _mdl_cur_soure = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_extra_info = nil;
        _mdl_http_code = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_req_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_end_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_dns_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_tcp_start_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_tcp_end_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_ttfp = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_httpfb = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_http_open_end_t = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_fs = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_pcdn_full_speed = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_tbs = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_lbs = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_res_err = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_read_src = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_seek_num = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_last_msg = nil;
        _mdl_server_timing = nil;
        _mdl_v_lt = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_v_p2p_ier = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_ip_list = nil;
        _mdl_blocked_ips = nil;
        _mdl_response_cache = nil;
        _mdl_response_cinfo = nil;
        _mdl_dns_type = nil;
        _initialQualityDesc = nil;
        _currentQualityDesc = nil;
        _lastForebackSwitchTime = -1LL;
        _lastAVSwitchTime = -1LL;
        _lastResSwitchTime = -1LL;
        _lastHeadsetSwithTime = -1LL;
        _isInBackground = 0;
        _radioMode = 0;
        _curHeadset = LOGGER_INTEGER_EMPTY_VALUE;
        _blueTooth = LOGGER_INTEGER_EMPTY_VALUE;
        _video_stream_duration = LOGGER_INTEGER_EMPTY_VALUE;
        _audio_stream_duration = LOGGER_INTEGER_EMPTY_VALUE;
        _mdl_p2p_loader = LOGGER_INTEGER_EMPTY_VALUE;
        _mdlAudioInfo = [[TTVideoEngineMDLTrackInfo alloc] init];
        _mdlVideoInfo = [[TTVideoEngineMDLTrackInfo alloc] init];
    }
    return self;
}

+ (NSString*) generateSessionID : (NSString*)did {
    NSMutableString* tempString = [NSMutableString string];
    
    if(did != nil)
        [tempString appendString:[NSString stringWithFormat:@"%@", did]];
    
    uint32_t rand = arc4random();
    
    [tempString appendFormat:@"%u", rand];
    
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    
    [tempString appendFormat:@"%lld", time];
    
    NSData *data = [tempString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* retString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return retString;
}

- (NSString*) generateTraceID : (NSString *) deviceId {
    NSMutableString *temString = [NSMutableString string];
    if (deviceId) {
        [temString appendString:[NSString stringWithFormat:@"%@", deviceId]];
        [temString appendString:@"T"];
    }
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    [temString appendFormat:@"%lld",time];
    [temString appendFormat:@"T"];
    
    uint32_t random = arc4random_uniform(0xFFFF);
    [temString appendFormat:@"%u",random];
    return temString.copy;
}

- (void)initPlay:(nullable NSString *)device_id traceId:(nullable NSString *)traceId{
    if (traceId && traceId.length > 0) {
        _session_id = traceId;
    } else {
        _session_id = [self generateTraceID:device_id];
    }
    //如果业务在启动app的时候没有调用过configAppInfo，在这里进行兜底，生成app_session_id
    TTVideoEngineEventUtil *sharedEventUtil = [TTVideoEngineEventUtil sharedInstance];
    if (!sharedEventUtil.appSessionId || sharedEventUtil.appSessionId.length == 0) {
        sharedEventUtil.appSessionId = [TTVideoEngineEventBase generateSessionID:device_id];
    }
}

- (void)beginToPlay:(NSString *)vid {
    _vid = vid;
}

- (NSString*)getNetworkType {
    int status = [[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus];
    switch (status) {
        case TTVideoEngineNetWorkStatusUnknown:
            return @"unknown";
        case TTVideoEngineNetWorkStatusNotReachable:
            return @"unavailable";
        case TTVideoEngineNetWorkStatusWiFi:
            return @"WIFI";
        case TTVideoEngineNetWorkStatusWWAN:
            return TTVideoEngineGetMobileNetType();
            
        default:
            return @"unknown";
    }
}

- (void)updateMDLInfo {
    if (self.delegate) {
        NSString* info = [self.delegate getLogValueStr:LOGGER_VALUE_GET_MDL_PLAY_LOG];
        if (info) {
            NSData* jsonData = [info dataUsingEncoding:NSUTF8StringEncoding];
            if (!jsonData) {
                return;
            }
            NSError* err;
            NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&err];
            if (err) {
                NSLog(@"json parse failed: %@", info);
                return;
            }
            
            if (dic && [dic isKindOfClass:[NSDictionary class]]) {
                _hasAudioTrackInfo = NO;
                BOOL trackInfo = NO;
                if (dic[@"audio"]) {
                    _hasAudioTrackInfo = YES;
                    trackInfo = YES;
                    [_mdlAudioInfo update:[dic ttVideoEngineDictionaryValueForKey:@"audio" defaultValue:nil]];
                }
                if (dic[@"video"]) {
                    trackInfo = YES;
                    [_mdlVideoInfo update:[dic ttVideoEngineDictionaryValueForKey:@"video" defaultValue:nil]];
                }
                if (!trackInfo) {
                    [_mdlVideoInfo update:dic];
                }
                if (dic[@"conc_count"]) {
                    _mdl_conc_count = [dic[@"conc_count"] intValue];
                }
                
                if ([dic objectForKey:@"cur_req_pos"]) {
                    _mdl_cur_req_pos = [[dic objectForKey:@"cur_req_pos"] longLongValue];
                }
                if ([dic objectForKey:@"cur_end_pos"]) {
                    _mdl_cur_end_pos = [[dic objectForKey:@"cur_end_pos"] longLongValue];
                }
                if ([dic objectForKey:@"cur_cache_pos"]) {
                    _mdl_cur_cache_pos = [[dic objectForKey:@"cur_cache_pos"] longLongValue];
                }
                if ([dic objectForKey:@"cache_type"]) {
                    _mdl_cache_type = [[dic objectForKey:@"cache_type"] intValue];
                }
                if ([dic objectForKey:@"cur_ip"]) {
                    _mdl_cur_ip = [dic objectForKey:@"cur_ip"];
                }
                if ([dic objectForKey:@"cur_host"]) {
                    _mdl_cur_host = [dic objectForKey:@"cur_host"];
                }
                if ([dic objectForKey:@"url"]) {
                    _mdl_cur_url = [dic objectForKey:@"url"];
                }
                if ([dic objectForKey:@"reply_size"]) {
                    _mdl_reply_size = [[dic objectForKey:@"reply_size"] longLongValue];
                }
                if ([dic objectForKey:@"down_pos"]) {
                    _mdl_down_pos = [[dic objectForKey:@"down_pos"] longLongValue];
                }
                if ([dic objectForKey:@"player_wait_time"]) {
                    _mdl_player_wait_time = [[dic objectForKey:@"player_wait_time"] longLongValue];
                }
                if ([dic objectForKey:@"player_wait_num"]) {
                    _mdl_player_wait_num = [[dic objectForKey:@"player_wait_num"] intValue];
                }
                if ([dic objectForKey:@"stage"]) {
                    _mdl_stage = [[dic objectForKey:@"stage"] intValue];
                }
                if ([dic objectForKey:@"err_code"]) {
                    _mdl_error_code = [[dic objectForKey:@"err_code"] intValue];
                }
                if ([dic objectForKey:@"cur_task_num"]) {
                    _mdl_cur_task_num = [[dic objectForKey:@"cur_task_num"] intValue];
                }
                if ([dic objectForKey:@"speed"]) {
                    _mdl_speed = [[dic objectForKey:@"speed"] intValue];
                }
                if ([dic objectForKey:@"file_key"]) {
                    _mdl_file_key = [dic objectForKey:@"file_key"];
                }
                if ([dic objectForKey:@"is_socrf"]) {
                    _mdl_is_socrf = [[dic objectForKey:@"is_socrf"] intValue];
                }
                if ([dic objectForKey:@"req_num"]) {
                    _mdl_req_num = [[dic objectForKey:@"req_num"] intValue];
                }
                if ([dic objectForKey:@"url_index"]) {
                    _mdl_url_index = [[dic objectForKey:@"url_index"] intValue];
                }
                if ([dic objectForKey:@"re_url"]) {
                    _mdl_re_url = [dic objectForKey:@"re_url"];
                }
                if ([dic objectForKey:@"cur_source"]) {
                    _mdl_cur_soure = [[dic objectForKey:@"cur_source"] intValue];
                }
                if ([dic objectForKey:@"extra_info"]) {
                    _mdl_extra_info = [dic objectForKey:@"extra_info"];
                }
                if ([dic objectForKey:@"status_code"]) {
                    _mdl_http_code = [[dic objectForKey:@"status_code"] intValue];
                }
                if ([dic objectForKey:@"req_t"]) {
                    _mdl_req_t = [[dic objectForKey:@"req_t"] longLongValue];
                }
                if ([dic objectForKey:@"end_t"]) {
                    _mdl_end_t = [[dic objectForKey:@"end_t"] longLongValue];
                }
                if ([dic objectForKey:@"dns_t"]) {
                    _mdl_dns_t = [[dic objectForKey:@"dns_t"] longLongValue];
                }
                if ([dic objectForKey:@"tcp_con_start_t"]) {
                    _mdl_tcp_start_t = [[dic objectForKey:@"tcp_con_start_t"] longLongValue];
                }
                if ([dic objectForKey:@"tcp_con_t"]) {
                    _mdl_tcp_end_t = [[dic objectForKey:@"tcp_con_t"] longLongValue];
                }
                if ([dic objectForKey:@"tcp_first_pack_t"]) {
                    _mdl_ttfp = [[dic objectForKey:@"tcp_first_pack_t"] longLongValue];
                }
                if ([dic objectForKey:@"http_first_body_t"]) {
                    _mdl_httpfb = [[dic objectForKey:@"http_first_body_t"] longLongValue];
                }
                if ([dic objectForKey:@"http_open_end_t"]) {
                    _mdl_http_open_end_t = [[dic objectForKey:@"http_open_end_t"] longLongValue];
                }
                if ([dic objectForKey:@"fs"]) {
                    _mdl_fs = [[dic objectForKey:@"fs"] longLongValue];
                }
                if ([dic objectForKey:@"full_speed"]) {
                    _mdl_pcdn_full_speed = [[dic objectForKey:@"full_speed"] intValue];
                }
                if ([dic objectForKey:@"tbs"]) {
                    _mdl_tbs = [[dic objectForKey:@"tbs"] longLongValue];
                }
                if ([dic objectForKey:@"lbs"]) {
                    _mdl_lbs = [[dic objectForKey:@"lbs"] longLongValue];
                }
                if ([dic objectForKey:@"req_err"]) {
                    _mdl_res_err = [[dic objectForKey:@"req_err"] intValue];
                }
                if ([dic objectForKey:@"read_src"]) {
                    _mdl_read_src = [[dic objectForKey:@"read_src"] intValue];
                }
                if ([dic objectForKey:@"seek_times"]) {
                    _mdl_seek_num = [[dic objectForKey:@"seek_times"] intValue];
                }
                if ([dic objectForKey:@"last_msg"]) {
                    _mdl_last_msg = [dic objectForKey:@"last_msg"];
                }
                if ([dic objectForKey:@"server_timing"]) {
                    _mdl_server_timing = [dic objectForKey:@"server_timing"];
                }
                if ([dic objectForKey:@"v_lt"]) {
                    _mdl_v_lt = [[dic objectForKey:@"v_lt"] intValue];
                }
                if ([dic objectForKey:@"v_p2p_ier"]) {
                    _mdl_v_p2p_ier = [[dic objectForKey:@"v_p2p_ier"] intValue];
                }
                if ([dic objectForKey:@"ip_list"]) {
                    _mdl_ip_list = [dic objectForKey:@"ip_list"];
                }
                if ([dic objectForKey:@"blocked_ip"]) {
                    _mdl_blocked_ips = [dic objectForKey:@"blocked_ip"];
                }
                if ([dic objectForKey:@"cdn_cache"]) {
                    _mdl_response_cache = [dic objectForKey:@"cdn_cache"];
                }
                if ([dic objectForKey:@"client_info"]) {
                    _mdl_response_cinfo = [dic objectForKey:@"client_info"];
                }
                if ([dic objectForKey:@"dns_type"]) {
                    int dns_type = [[dic objectForKey:@"dns_type"] intValue];
                    switch (dns_type) {
                        case TTVideoEngineMDLDnsTypeLocal:
                            _mdl_dns_type = kTTVideoEngineDnsTypeLocal;
                            break;
                        case TTVideoEngineMDLDnsTypeTT:
                            _mdl_dns_type = kTTVideoEngineDnsTypeOwn;
                            break;
                        case TTVideoEngineMDLDnsTypeGoogle:
                            _mdl_dns_type = kTTVideoEngineDnsTypeGoogle;
                            break;
                        case TTVideoEngineMDLDnsTypeCustom:
                            _mdl_dns_type = kTTVideoEngineDnsTypeCustom;
                            break;
                            
                        default:
                            break;
                    }
                }
                if ([dic objectForKey:@"mdl_features"]) {
                    [self updateMdlFeatures:[dic objectForKey:@"mdl_features"]];
                }
            }
        }
    }
}

- (void)updateMdlFeatures:(NSDictionary *)dic {
    _mdl_features = dic;
    if (_mdl_p2p_loader == -1 && [dic objectForKey:@"mdl_p2p_loader"]) {
        _mdl_p2p_loader = [[dic objectForKey:@"mdl_p2p_loader"] intValue];
    }
}

@end


@interface TTVideoEngineEventUtil ()
@property (nonatomic, assign) float currentVolume;
@property (nonatomic, assign) NSInteger screenWidth;
@property (nonatomic, assign) NSInteger screenHeight;
@property (nonatomic, assign) float screenScale;
@end

@implementation TTVideoEngineEventUtil

static TTVideoEngineEventUtil *eventUtil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventUtil = [[TTVideoEngineEventUtil alloc] init];
    });
    return eventUtil;
}

- (instancetype)init {
    if (self = [super init]) {
        _currentVolume = [[AVAudioSession sharedInstance]outputVolume];
        CGRect bounds = [UIScreen mainScreen].bounds;
        _screenWidth = bounds.size.width;
        _screenHeight = bounds.size.height;
        _screenScale = [UIScreen mainScreen].scale;
        _lastPlaySessionId = @"";
        _appSessionId = @"";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)volumeChanged:(NSNotification *)notification {
    _currentVolume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
}

- (float)currentVolume {
    return _currentVolume;
}

@end

@implementation TTVideoEngineMDLTrackInfo

- (instancetype)init {
    if (self = [super init]) {
        _mdl_mem_buffer_len = -1;
        _mdl_disk_buffer_len = -1;
        _mdl_send_offset = -1;
        _mdl_last_req_offset = -1;
    }
    return self;
}

- (void)update:(NSDictionary *_Nullable)dic {
    if (!(dic && [dic isKindOfClass:[NSDictionary class]])) {
        return;
    }
    
    if (dic[@"mem_buffer_len"]) {
        _mdl_mem_buffer_len = [dic[@"mem_buffer_len"] intValue];
    }
    if (dic[@"disk_buffer_len"]) {
        _mdl_disk_buffer_len = [dic[@"disk_buffer_len"] longLongValue];
    }
    if (dic[@"send_offset"]) {
        _mdl_send_offset = [dic[@"send_offset"] longLongValue];
    }
    if (dic[@"last_req_offset"]) {
        _mdl_last_req_offset = [dic[@"last_req_offset"] longLongValue];
    }
    NSString *last_ip_list = [dic ttVideoEngineStringValueForKey:@"last_ip_list" defaultValue:nil];
    if (last_ip_list && [last_ip_list isKindOfClass:[NSString class]]) {
        _mdl_last_ip_list = last_ip_list;
    }
}

@end


