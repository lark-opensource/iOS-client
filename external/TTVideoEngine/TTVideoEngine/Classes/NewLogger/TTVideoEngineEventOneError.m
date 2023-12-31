//
//  TTVideoEngineEventOneError.m
//  FLEX
//
//  Created by chibaowang on 2019/10/20.
//

#import "TTVideoEngineEventLoggerProtocol.h"
#import "TTVideoEngineEventOneError.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventManager.h"
#import "NSDictionary+TTVideoEngine.h"

@interface TTVideoEngineEventOneError ()

@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;
@property (nonatomic, assign) NSInteger errorType;//播放器返回的错误类型
@property (nonatomic, assign) NSInteger errorCode;//播放器返回的错误码
@property (nonatomic, copy) NSString* errorStage; //播放器发生错误时的播放阶段

@property (nonatomic, assign) BOOL isFirstFrameShown;
@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, assign) NSInteger vsc;

@end

@implementation TTVideoEngineEventOneError

- (instancetype)initWithEventBase:(TTVideoEngineEventBase *)base {
    if (self = [super init]) {
        _eventBase = base;
        _errorType = LOGGER_INTEGER_EMPTY_VALUE;
        _errorCode = LOGGER_INTEGER_EMPTY_VALUE;
        _errorStage = nil;
        _isFirstFrameShown = NO;
        _retryCount = 0;
        _vsc = LOGGER_INTEGER_EMPTY_VALUE;
    }
    return self;
}

- (void)showedFirstFrame {
    _isFirstFrameShown = YES;
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
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution", _eventBase.currentResolution);
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
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"drm_token_url", _eventBase.drm_token_url);
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
    }
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"errc", @(_errorCode));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"errt", @(_errorType));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"es", _errorStage);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"retry_count", @(_retryCount));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vsc", @(_vsc));
    
    return jsonDict;
}

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver {
    _retryCount++;
}

- (void)sendErrorEvent {
    if (_isFirstFrameShown) {
        _errorStage = @"playing";
    } else {
        _errorStage = @"beforePlay";
    }
    
    NSDictionary* eventDict = [self jsonDict];
    if (!eventDict) {
        TTVideoEngineLog(@"OneError send failed");
        return;
    }
    
    [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:@"videoplayer_oneerror"];
}

- (void)errorHappened:(NSError *)error {
    _errorType = TTVideoEngineGetErrorType(error);
    _errorCode = error.code;
    
    [self sendErrorEvent];
}

- (void)errorStatusHappened:(NSInteger)status {
    _vsc = status;
    
    [self sendErrorEvent];
}


@end
