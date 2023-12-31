//
//  TTVideoEngineEventLogger.m
//  Pods
//
//  Created by guikunzhi on 16/12/26.
//
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineEventLogger.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineEvent.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngine.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineDNSServerIP.h"
#import "TTVideoEnginePlayerDefinePrivate.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoNetUtils.h"
#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventOneErrorProtocol.h"
#import "TTVideoEngineEventOneEventProtocol.h"
#import "TTVideoEngineEventOneOperaProtocol.h"
#import "TTVideoEngineEventOneOutSyncProtocol.h"
#import "TTVideoEngineEventOneAVRenderCheckProtocol.h"
#import "TTVideoEnginePlayer.h"
#import "NSError+TTVideoEngine.h"
#import "TTVideoEngineCollector.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineEventNetworkSpeedPredictorSampleProtocol.h"
#import "TTVideoEngineStrategy.h"
#import "TTVideoEngineFetcherMaker.h"

const NSString *FEATURE_KEY_VIDEO_HW = @"v_hw";
//static const NSString *FEATURE_KEY_AUDIO_HW = @"a_hw";
const NSString *FEATURE_KEY_BYTEVC1 = @"bytevc1";
const NSString *FEATURE_KEY_BYTEVC2 = @"bytevc2";
const NSString *FEATURE_KEY_ENABLE_LOAD_CONTROL = @"enable_loadcontrol";
const NSString *FEATURE_KEY_NETWORK_TIMEOUT = @"network_timeout";
const NSString *FEATURE_KEY_BUFFER_TIMEOUT = @"buffer_timeout";
const NSString *FEATURE_KEY_BUFFER_DIRECTLY = @"buffer_directly";
const NSString *FEATURE_KEY_FIRST_BUFFER_END_MS =
    @"first_buf_end_ms"; //首次卡顿结束内核buffer水位阈值
const NSString *FEATURE_KEY_SR = @"sr"; //超分
const NSString *FEATURE_KEY_VOLUME_BALANCE = @"volume_balance";
const NSString *FEATURE_KEY_METAL = @"metal";
const NSString *FEATURE_KEY_BASH = @"bash";
const NSString *FEATURE_KEY_ABR = @"abr";
const NSString *FEATURE_KEY_PRELOAD = @"preload";
const NSString *FEATURE_KEY_AUTO_RANGE = @"auto_range"; //预渲染
//const NSString *FEATURE_KEY_HW_DROP = @"hw_drop";
const NSString *FEATURE_KEY_HTTPS = @"enable_https";
const NSString *FEATURE_KEY_HIJACK = @"enable_hijack";
const NSString *FEATURE_KEY_HIJACK_RETRY = @"hijack_retry";
const NSString *FEATURE_KEY_FALLBACK_API = @"fallback_api"; // videomodel自刷新
//const NSString *FEATURE_KEY_ASYNC_POSITION = @"async_pos";
const NSString *FEATURE_KEY_SOCKET_REUSE = @"socket_reuse";
const NSString *FEATURE_KEY_MDL_TYPE = @"mdl_type";
const NSString *FEATURE_KEY_RENDER_TYPE = @"render_type";
const NSString *FEATURE_KEY_IMAGE_SCALE = @"image_scale";
//const NSString *FEATURE_KEY_AUDIO_RENDER_TYPE = @"audio_render_type";
const NSString *FEATURE_KEY_SKIP_FIND_STREAM_INFO = @"skip_find_stream";
const NSString *FEATURE_KEY_ENABLE_ASYNC_PREPARE = @"async_prepare";
const NSString *FEATURE_KEY_LAZY_SEEK = @"lazy_seek";
const NSString *FEATURE_KEY_KEEP_FORMAT_THREAD_ALIVE = @"keep_formater_alive";
const NSString *FEATURE_KEY_DISABLE_SHORT_SEEK = @"dis_short_seek";
const NSString *FEATURE_KEY_MOV_PREFER_NEAR_SAMPLE = @"pref_near_sample";
const NSString *FEATURE_KEY_MDL_SOCKET_REUSE = @"mdl_socket_reuse";
const NSString *FEATURE_KEY_MDL_PRE_CONNECT = @"mdl_preconn";
const NSString *FEATURE_KEY_MDL_ENABLE_EXTERN_DNS = @"mdl_externdns";
const NSString *FEATURE_KEY_MDL_HTTPDNS = @"mdl_httpdns";
//const NSString *FEATURE_KEY_MDL_PREPARSE_DNS = @"mdl_predns";
const NSString *FEATURE_KEY_MDL_DNS_REFRESH = @"mdl_dns_refresh";
const NSString *FEATURE_KEY_MDL_DNS_PARALLEL_PARSE = @"mdl_dns_parallel";
//const NSString *FEATURE_KEY_MDL_BACKUP_IP = @"mdl_backip";
const NSString *FEATURE_KEY_MDL_SESSION_REUSE = @"mdl_session_reuse";
const NSString *FEATURE_KEY_MDL_TLS_VERSION = @"mdl_tls_ver";
const NSString *FEATURE_KEY_HDR_PQ = @"hdr_pq";
const NSString *FEATURE_KEY_HDR_HLG = @"hdr_hlg";
const NSString *FEATURE_KEY_VOLUME_BALANCE_V2 = @"volume_balancev2";
const NSString *FEATURE_KEY_HEAAC_V2 = @"heaacv2";
const NSString *FEATURE_KEY_ENABLE_OUTLET_DROP_LIMIT = @"drop_limit";
const NSString *FEATURE_KEY_PRECISE_PAUSE = @"precise_pause";
const NSString *FEATURE_KEY_BUFFER_START_CHECK_VOICE = @"buffer_start_check_voice";
const NSString *FEATURE_KEY_BYTEVC1_DECODER_OPT = @"bytevc1_decoder_opt";
const NSString *FEATURE_KEY_AI_BARRAGE = @"ai_barrage";
const NSString *FEATURE_KEY_NO_BUFFER_UPDATE = @"no_buffer_update";
const NSString *FEATURE_KEY_AV_INTERLACED_CHECK = @"av_interlaced_check";
const NSString *FEATURE_KEY_DEMUX_NONBLOCK_READ = @"demux_nonblock_read";
const NSString *FEATURE_KEY_BLUETOOTH_SYNC = @"bluetooth_sync";
const NSString *FEATURE_KEY_MDL_SEEK_REOPEN = @"mdl_seek_reopen";
const NSString *FEATURE_KEY_MDL_SOCKET_MONITOR = @"mdl_socket_monitor";
const NSString *FEATURE_KEY_PLAY_LOAD = @"st_play_load";
const NSString *FEATURE_KEY_ENABLE_METALVIEW_DOUBLE_BUFFER = @"enable_metalview_double_buffer";

//logger state for V2
typedef NS_ENUM(NSInteger, LoggerState) {
    LOGGER_STATE_IDLE = 0,
    LOGGER_STATE_STARTING,
    LOGGER_STATE_PLAYING,
    LOGGER_STATE_LOADING,
    LOGGER_STATE_SEEKING,
    LOGGER_STATE_ERROR,
};

static NSMutableDictionary* sFeatures = nil;

@interface TTVideoEngineEventLogger ()

@property (nonatomic, strong) TTVideoEngineEvent *event;
@property (nonatomic, strong) TTVideoEngineEventBase *eventBase;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventOneEventProtocol> eventOneEvent;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventOneErrorProtocol> eventOneError;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventOneOperaProtocol> eventOneOpera;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventOneOutSyncProtocol> eventOneOutsync;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventOneAVRenderCheckProtocol> eventOneAVRenderCheck;
@property (nonatomic, nullable, strong) id<TTVideoEngineEventNetworkSpeedPredictorSampleProtocol> eventPredictorSample;

@property (nonatomic, assign) BOOL leaveWithoutPlay;
@property (nonatomic, assign) long long exitTime;
@property (nonatomic, strong) NSMutableArray *retryFetchErrorInfo;
@property (nonatomic, strong) NSMutableArray *firstDNSErrorInfo;
@property (nonatomic, strong) NSMutableArray *errorInfo;
@property (nonatomic, copy) NSArray *urlArray;

@property (nonatomic, assign) int64_t stallStartTs; //ms
@property (nonatomic, assign) int64_t pauseStartTs; //ms
@property (nonatomic, assign) int64_t seekStartTs; //ms

@property (nonatomic, copy) NSString *apiString;
@property (nonatomic, assign) NSInteger apiver;
@property (nonatomic, copy) NSString *auth;
@property (nonatomic, strong) NSMutableArray *cpuUsages;
@property (nonatomic, strong) NSMutableArray *memUsages;
@property (nonatomic, copy) NSString *logInfo;
@property (nonatomic, assign) NSInteger dnsMode;

@property (nonatomic, assign) int64_t mAccumVPS;
@property (nonatomic, assign) int64_t mAccumVDS;
@property (nonatomic, assign) int64_t mEngineLoopVDS; //engine层做loop，会清空上一次的accu_vds，这里需要做特殊累加

@property (nonatomic, copy) NSString *source_type;//视频的播放类型

@property (nonatomic, assign) NSInteger mEnableLoadControl;
@property (nonatomic, assign) NSInteger mEnableNetworkTimeout;
@property (nonatomic, assign) NSInteger mNetworkTimeout;
@property (nonatomic, assign) NSInteger mBufferTimeout;
@property (nonatomic, assign) NSInteger mEnableBufferingDirectly;
@property (nonatomic, assign) BOOL mEnableBufferingMilliSeconds;
@property (nonatomic, assign) NSInteger mBufferEndMilliSeconds;
@property (nonatomic, assign) NSInteger mBufferEndSeconds;
@property (nonatomic, assign) NSInteger mEnableVolumeBalance;
@property (nonatomic, assign) NSInteger mVolumeBalanceType;
@property (nonatomic, assign) NSInteger mEnableAutoRange;
@property (nonatomic, assign) NSInteger mImageScaleType;
@property (nonatomic, assign) NSInteger mEnableAbr;
@property (nonatomic, assign) NSInteger mEnableHttps;
@property (nonatomic, assign) NSInteger mEnableHijackRetry;
@property (nonatomic, assign) NSInteger mEnableFallbackApiMDLRetry;
@property (nonatomic, assign) NSInteger mEnableSkipFindStream;
@property (nonatomic, assign) NSInteger mEnableAsyncPrepare;
@property (nonatomic, assign) NSInteger mEnableLazySeek;
@property (nonatomic, assign) NSInteger mEnableFormaterKeepAlive;
@property (nonatomic, assign) NSInteger mDisableShortSeek;
@property (nonatomic, assign) NSInteger mPrefNearSample;
@property (nonatomic, assign) NSInteger mEnableReuseSocket;
@property (nonatomic, assign) NSInteger mWidth; //视频宽
@property (nonatomic, assign) NSInteger mHeight; //视频高
@property (nonatomic, strong) NSMutableDictionary* mPlayparam;///< 业务方设置的播放参数
@property (nonatomic, copy) NSString *mInitialURL;
@property (nonatomic, assign) NSInteger mEnableMdl;
@property (nonatomic, assign) long long mVideoPreloadSize;

//add for V2
@property (nonatomic, assign) int64_t leaveBlockT;//ms
@property (nonatomic, assign) LoggerState loggerState;
@property (nonatomic, assign) NSInteger logVersion;
@property (nonatomic, strong) NSMutableDictionary *metricsInfo;

@property (nonatomic, assign) BOOL mAVOutSyncing;
@property (nonatomic, assign) UInt64 mLastRebufT;//ms
@property (nonatomic, assign) UInt64 mLastSeekT;//ms

@property (nonatomic, assign) int64_t errorRetryBeginTime;
@property (nonatomic, assign) int64_t errorRetryCurPos;
@property (nonatomic, assign) NSInteger errorRetryErrorCode;
@property (nonatomic, assign) NSInteger errorRetryStrategy;
@property (nonatomic, assign) NSInteger mEnableOutletDropLimit;
@property (nonatomic, assign) BOOL mIsEngineReuse;
@property (nonatomic, strong) NSMutableDictionary *mFeatures;
@property (nonatomic, copy) NSString *mMessage;
@property (nonatomic, strong) NSMutableArray<NSString *> *mMDLRetryInfo;

@property (nonatomic, copy) NSString *mFromEnginePool;
@property (nonatomic, assign) NSInteger mEnableMetalViewDoubleBuffer;

@property (nonatomic, copy) NSString *headerInfo;

@end

@implementation TTVideoEngineEventLogger

@synthesize delegate = _delegate;
@synthesize performancePointSwitch = _performancePointSwitch;
@synthesize isLocal = _isLocal;
@synthesize vid = _vid;
@synthesize vu = _vu;
@synthesize loopCount = _loopCount;
@synthesize isLooping = _isLooping;
@synthesize loopway = _loopway;
@synthesize accumulatedStalledTime = _accumulatedStalledTime;
@synthesize seekCount = _seekCount;


+ (void)setIntValueWithKey:(NSInteger)key value:(NSInteger)value {
    switch (key) {
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_MAXSIZE:
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_ENABLE_REPORT:
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_TIMEINTERVAL:
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_AlGOTYPE:
        {
            NSInvocation *invocation = [self classMethodInvocate:@"TTVideoEngineEventNetworkPredictorSample" method:@selector(setIntValueWithKey:value:)];
            if (invocation == nil) {
                return;
            }
            [invocation setArgument:&key atIndex:2];
            [invocation setArgument:&value atIndex:3];
            [invocation invoke];
            break;
        }

        default:
            break;
    }
}

+ (void)setFloatValueWith:(NSInteger)key value:(float)value {
    switch (key) {
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_SAMPLINGRATE:
        {
            NSInvocation *invocation = [self classMethodInvocate:@"TTVideoEngineEventNetworkPredictorSample" method:@selector(setFloatValueWith:value:)];
            if (invocation == nil) {
                return;
            }
            [invocation setArgument:&key atIndex:2];
            [invocation setArgument:&value atIndex:3];
            [invocation invoke];
            break;
        }

        default:
            break;
    }
}

+ (NSInvocation *)classMethodInvocate:(NSString *)classStr method:(SEL)selector {
    Class useClass = NSClassFromString(classStr);
    if (useClass == nil) {
        return nil;
    }
    SEL useSelector = selector;
    if (useSelector == nil) {
        return nil;
    }
    NSMethodSignature *signature = [useClass methodSignatureForSelector:useSelector];
    if (signature == nil) {
        return nil;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = useClass;
    invocation.selector = useSelector;
    return invocation;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_event.pt > 0) {
        if (_leaveWithoutPlay) {
            [self flushEvent];
        }else {
            [self sendEvent];
        }
        
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _logVersion = [[TTVideoEngineEventManager sharedManager] logVersion];
        [self initEvents];
        _retryFetchErrorInfo = [NSMutableArray array];
        _firstDNSErrorInfo = [NSMutableArray array];
        _errorInfo = [NSMutableArray array];
        _cpuUsages = [NSMutableArray array];
        _memUsages = [NSMutableArray array];
        _metricsInfo = [NSMutableDictionary dictionary];
        _mPlayparam = [NSMutableDictionary dictionary];
        _leaveWithoutPlay = YES;
        _dnsMode = LOGGER_DNS_MODE_ENGINE;
        _loggerState = LOGGER_STATE_IDLE;
        _leaveBlockT = 0;
        _isLooping = NO;
        _loopway = 0; // 0 is engine loop, >0 is player loop
        _mAccumVDS = 0;
        _mAccumVPS = 0;
        _mEngineLoopVDS = 0;
        _source_type = nil;
        _mEnableLoadControl = 0;
        _mEnableNetworkTimeout = 1;
        _mNetworkTimeout = -1;
        _mBufferTimeout = -1;
        _mEnableBufferingDirectly = -1;
        _mEnableBufferingMilliSeconds = NO;
        _mBufferEndMilliSeconds = -1;
        _mBufferEndSeconds = -1;
        _mEnableVolumeBalance = -1;
        _mVolumeBalanceType = -1;
        _mEnableAutoRange = -1;
        _mImageScaleType = -1;
        _mEnableAbr = -1;
        _mEnableHttps = -1;
        _mEnableHijackRetry = -1;
        _mEnableFallbackApiMDLRetry = -1;
        _mEnableSkipFindStream = -1;
        _mEnableAsyncPrepare = -1;
        _mEnableLazySeek = -1;
        _mEnableFormaterKeepAlive = -1;
        _mDisableShortSeek = -1;
        _mPrefNearSample = -1;
        _mEnableReuseSocket = -1;
        _mAVOutSyncing = NO;
        _mLastSeekT = -1LL;
        _mLastRebufT = -1LL;
        _errorRetryBeginTime = 0;
        _errorRetryCurPos = 0;
        _errorRetryErrorCode = 0;
        _errorRetryStrategy = 0;
        _mEnableOutletDropLimit = -1;
        _mIsEngineReuse = NO;
        _mFeatures = [NSMutableDictionary dictionary];
        _mWidth = 0;
        _mHeight = 0;
        _mEnableMdl = 0;
        _mVideoPreloadSize = 0;
        _mMessage = @"";
        _mMDLRetryInfo = [NSMutableArray array];
        _mFromEnginePool = @"default";
        _mEnableMetalViewDoubleBuffer = -1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    return self;
}

- (void)initEvents {
    _eventBase = [[TTVideoEngineEventBase alloc] init];
    _event = [[TTVideoEngineEvent alloc] initWithEventBase:_eventBase];
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        _eventOneError = nil;
//        _eventOneError = [[NSClassFromString(@"TTVideoEngineEventOneError") alloc] initWithEventBase:_eventBase];
        _eventOneEvent = [[NSClassFromString(@"TTVideoEngineEventOneEvent") alloc] initWithEventBase:_eventBase];
        _eventOneOpera = [[NSClassFromString(@"TTVideoEngineEventOneOpera") alloc] initWithEventBase:_eventBase];
        _eventOneOutsync = [[NSClassFromString(@"TTVideoEngineEventOneOutSync") alloc] initWithEventBase:_eventBase];
        _eventOneAVRenderCheck = [[NSClassFromString(@"TTVideoEngineEventOneAVRenderCheck") alloc] initWithEventBase:_eventBase];
        _eventPredictorSample = [[NSClassFromString(@"TTVideoEngineEventNetworkPredictorSample") alloc] initWithEventBase:_eventBase];
    } else {
        _eventOneEvent = nil;
        _eventOneOpera = nil;
        _eventOneError = nil;
        _eventOneOutsync = nil;
        _eventOneAVRenderCheck = nil;
        _eventPredictorSample = nil;
    }
}

- (void)recordCurrentHeadsetInfo {
    NSInteger curHeadset = 0;
    NSInteger blueTooth = 0;
    // Time-consuming operation
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            curHeadset = 1;
            blueTooth = 0;
            break;
        } else if ([[output portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            curHeadset = 1;
            blueTooth = 1;
            break;
        }
    }
    
    @weakify(self)
    TTVideoRunOnMainQueue(^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        self.eventBase.curHeadset = curHeadset;
        self.eventBase.blueTooth = blueTooth;
    }, NO);
}

- (void)recordHeadsetInfoWithConnected:(NSInteger)con bluetooth:(NSInteger)bt {
    @weakify(self)
    TTVideoRunOnMainQueue(^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
        NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
        [eventModel setObject:@(curT) forKey:@"t"];
        [eventModel setObject:@(bt) forKey:@"bt"];
        [eventModel setObject:@(con) forKey:@"con"];
        [self.event.headset_switch_list addEventModel:eventModel];
        self.eventBase.lastHeadsetSwithTime = curT;
    }, NO);
    
    [self recordCurrentHeadsetInfo];
}

- (void)outputRouteChanged:(NSNotification *)notification {
    // the func callback in child thread, has Time-consuming operation
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (notification.object != audioSession) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSUInteger reason = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reason) {
        AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
        for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
            if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
                [self recordHeadsetInfoWithConnected:1 bluetooth:0];
                return;
            } else if ([[output portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
                [self recordHeadsetInfoWithConnected:1 bluetooth:1];
                return;
            }
        }
    } else if (AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reason) {
        AVAudioSessionRouteDescription *preRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
        for (AVAudioSessionPortDescription *output in preRoute.outputs) {
            if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
                [self recordHeadsetInfoWithConnected:0 bluetooth:0];
                return;
            } else if ([[output portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
                [self recordHeadsetInfoWithConnected:0 bluetooth:1];
                return;
            }
        }
    }
}

- (void)recordBrightnessInfo {
    float brightness = [UIScreen mainScreen].brightness;
    float oldBrightness = self.event.cur_brightness;
    if (fabsf(brightness - oldBrightness) < 0.000001f) {
        return;
    }
    
    self.event.cur_brightness = brightness;
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel setObject:@(curT) forKey:@"t"];
    [eventModel setObject:@(TTVideoEngineValidNumber(brightness)) forKey:@"b"];
    [self.event.bright_list addEventModel:eventModel];
}

- (void)backgroundStartPlay {
    // background audio start
    self.eventBase.isInBackground = 1;
    self.eventBase.radioMode = 1;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    TTVideoEngineLog(@"applicationWillResignActive");
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel setObject:@(0) forKey:@"is_back2fore"];
    [eventModel setObject:@(curT) forKey:@"t"];
    if (self.delegate) {
        NSInteger curPos = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_PLAYBACK_TIME];
        [eventModel setObject:@(TTVideoEngineValidNumber(curPos)) forKey:@"pt"];
    }
    [self.event.foreback_switch_list addEventModel:eventModel];
    
    self.eventBase.lastForebackSwitchTime = curT;
    self.eventBase.isInBackground = 1;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    TTVideoEngineLog(@"applicationDidBecomeActive");
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel setObject:@(1) forKey:@"is_back2fore"];
    [eventModel setObject:@(curT) forKey:@"t"];
    if (self.delegate) {
        NSInteger curPos = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_PLAYBACK_TIME];
        [eventModel setObject:@(TTVideoEngineValidNumber(curPos)) forKey:@"pt"];
    }
    [self.event.foreback_switch_list addEventModel:eventModel];
    
    self.eventBase.lastForebackSwitchTime = curT;
    self.eventBase.isInBackground = 0;
}

- (nullable id)getMetrics:(NSString *)key {
    return [self.metricsInfo objectForKey:key];
}

- (NSDictionary *)firstFrameTimestamp {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.event.prepare_start_time > 1) {
        [dict setObject:@(self.event.prepare_start_time) forKey:@"ffr_init_time"];
    }
    if (self.event.formater_create_t > 1) {
        [dict setObject:@(self.event.formater_create_t) forKey:@"ffr_formater_create_time"];
    }
    if (self.event.demuxer_begin_t > 1) {
        [dict setObject:@(self.event.demuxer_begin_t) forKey:@"ffr_demuxer_begin_time"];
    }
    if (self.event.dns_start_t > 1) {
        [dict setObject:@(self.event.dns_start_t) forKey:@"ffr_dns_start_time"];
    }
    if (self.event.dns_t > 1) {
        [dict setObject:@(self.event.dns_t) forKey:@"ffr_dns_time"];
    }
    if (self.event.tran_ct > 1) {
        [dict setObject:@(self.event.tran_ct) forKey:@"ffr_tcp_time"];
    }
    if (self.event.tran_ft > 1) {
        [dict setObject:@(self.event.tran_ft) forKey:@"ffr_head_time"];
    }
    if (self.event.avformat_open_t > 1) {
        [dict setObject:@(self.event.avformat_open_t) forKey:@"ffr_avformat_open_time"];
    }
    if (self.event.demuxer_create_t > 1) {
        [dict setObject:@(self.event.demuxer_create_t) forKey:@"ffr_demuxer_create_time"];
    }
    if (self.event.dec_create_t > 1) {
        [dict setObject:@(self.event.dec_create_t) forKey:@"ffr_dec_create_time"];
    }
    if (self.event.outlet_create_t > 1) {
        [dict setObject:@(self.event.outlet_create_t) forKey:@"ffr_out_create_time"];
    }
    if (self.event.re_f_videoframet > 1) {
        [dict setObject:@(self.event.re_f_videoframet) forKey:@"ffr_fst_data_time"];
    }
    if (self.event.v_dec_start_t > 1) {
        [dict setObject:@(self.event.v_dec_start_t) forKey:@"ffr_decoder_start_time"];
    }
    if (self.event.v_dec_opened_t > 1) {
        [dict setObject:@(self.event.v_dec_opened_t) forKey:@"ffr_decoder_opened_time"];
    }
    if (self.event.de_f_videoframet > 1) {
        [dict setObject:@(self.event.de_f_videoframet) forKey:@"ffr_dec_time"];
    }
    if (self.event.video_open_time > 1) {
        [dict setObject:@(self.event.video_open_time) forKey:@"ffr_render_init_start_time"];
    }
    if (self.event.video_opened_time > 1) {
        [dict setObject:@(self.event.video_opened_time) forKey:@"ffr_render_init_time"];
    }
    if (self.event.first_frame_rendered_time > 1) {
        [dict setObject:@(self.event.first_frame_rendered_time) forKey:@"ffr_render_time"];
    }
    if (self.event.prepare_end_time > 1) {
        [dict setObject:@(self.event.prepare_end_time) forKey:@"ffr_prepard_time"];
    }
    return dict;
}

- (TTVideoEngineEvent *)getEvent {
    return self.event;
}

- (TTVideoEngineEventBase *)getEventBase {
    return self.eventBase;
}

- (void)setVid:(NSString *)vid {
//    [self clear];
    
    _vid = vid;
    _eventBase.vid = vid;
}

- (void)setURLArray:(NSArray *)urlArray {
    _urlArray = urlArray;
}

- (void)setSourceType:(NSInteger)sourceType vid:(NSString *)vid {
    if(sourceType == TTVideoEnginePlaySourceTypeLocalUrl){
        self.isLocal = YES;
    }
    int64_t curT = [[NSDate date] timeIntervalSince1970] * 1000;
    [self setInt64Option:LOGGER_OPTION_TIME_SET_DATSSOURCE value:curT];
    switch (sourceType) {
        case TTVideoEnginePlaySourceTypeLocalUrl:
            _source_type = @"local_url";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED;
            break;
        case TTVideoEnginePlaySourceTypeDirectUrl:
            _source_type = @"dir_url";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
            break;
        case TTVideoEnginePlaySourceTypePlayitem:
            _source_type = @"playitem";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
            break;
        case TTVideoEnginePlaySourceTypePreloaditem:
            _source_type = @"preload";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
            break;
        case TTVideoEnginePlaySourceTypeFeed:
            _source_type = @"feed";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
            break;
        case TTVideoEnginePlaySourceTypeVid:
            _source_type = @"vid";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH;
            break;
        case TTVideoEnginePlaySourceTypeModel:
            _source_type = @"videoModel";
            self.event.leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
            break;
        default:
            break;
    }
    self.vid = vid;
    self.eventBase.vid = vid;
}

- (void)setDNSMode:(NSInteger)mode {
    if (mode == LOGGER_DNS_MODE_AVPLAYER &&
        ([self.eventBase.source_type isEqualToString:@"dir_url"] || _mEnableMdl >= 1)) {
        _dnsMode = mode;
    } else {
        _dnsMode = LOGGER_DNS_MODE_ENGINE;
    }
}

- (void)initPlay:(NSString *)device_id {
    NSString *preloadTraceId = [self.delegate getLogValueStr:LOGGER_VALUE_PRELOAD_TRACE_ID];
    [self.eventBase initPlay:device_id traceId:preloadTraceId];
    self.event.traceID = self.eventBase.session_id;
    self.event.mIsEngineReuse = _mIsEngineReuse;
    if (!_mIsEngineReuse) {
        _mIsEngineReuse = YES;
    }
}

- (void)prepareBeforePlay {
    self.event.prepare_before_play_t = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

- (void)beginToPlayVideo:(NSString *)vid {
    /// When user switch data source. must call [engine stop]
    /// And it will call [logger playbackFinish],rest logEvent.
    //[self clear];
    //self.videoInfo = nil;
    //self.event = [[TTVideoEngineEvent alloc] init];
    if (self.event.pt > 1) {// Did set.
        return;
    }
    int64_t curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);

    if (_logVersion == TTEVENT_LOG_VERSION_NEW)
        _loggerState = LOGGER_STATE_STARTING;
    _vid = vid;
    [self.eventBase beginToPlay:vid];
    _eventBase.delegate = _delegate;
    _eventBase.source_type = _source_type;
    if (self.event.pt < 1) {
        self.event.pt = (long long)curT;
    }
    if (self.event.pt_new <= 0) {
        self.event.pt_new = curT;
    }
    if (self.event.ps_t <= 0) {
        self.event.ps_t = curT;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(versionInfoForEventLogger:)]) {
        NSDictionary *versionInfo = [self.delegate versionInfoForEventLogger:self];
        if (versionInfo) {
            self.eventBase.sv = [versionInfo objectForKey:@"sv"];
            self.eventBase.pv = [versionInfo objectForKey:@"pv"];
            self.eventBase.pc = [versionInfo objectForKey:@"pc"];
            self.eventBase.sdk_version = [versionInfo objectForKey:@"sdk_version"];
        }
    }
    
    if ([_eventBase.source_type isEqualToString:@"vid"]) {
        [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH isStart:YES];
    } else if ([_eventBase.source_type isEqualToString:@"local_url"]) {
        [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED isStart:YES];
    } else {
        if (_dnsMode == LOGGER_DNS_MODE_ENGINE) {
            [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_LOADING_FETCHED isStart:YES];
        } else if (_dnsMode == LOGGER_DNS_MODE_AVPLAYER) {
            [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED isStart:YES];
        }
    }
    
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_eventOneEvent != nil) {
            _eventOneEvent.delegate = _delegate;
        }
        if (_eventOneOpera != nil) {
            _eventOneOpera.delegate = _delegate;
        }
        if (_eventOneOutsync != nil) {
            _eventOneOutsync.delegate = _delegate;
        }
        if (_eventOneAVRenderCheck != nil) {
            _eventOneAVRenderCheck.delegate = _delegate;
        }
        if (_eventPredictorSample != nil) {
            _eventPredictorSample.delegate = _delegate;
        }
    }
    
    if ([self.eventPredictorSample respondsToSelector:@selector(startRecord)]) {
        [self.eventPredictorSample startRecord];
    }
    
    // TODO fixme, some value not correct in eventBase, in case replay without setUrl
    if (_mInitialURL != nil && self.eventBase.initialURL == nil) {
        self.eventBase.initialURL = _mInitialURL;
        CGFloat speed = [[_mPlayparam objectForKey:@"speed"] floatValue];
        if (speed > 0.0f) {
            _eventBase.playSpeed = speed;
        }
    }
}

- (void)setTag:(NSString *)tag {
    self.eventBase.tag = tag;
}

- (void)setSubtag:(NSString *)subtag {
    self.eventBase.subtag = subtag;
}

- (void)needRetryToFetchVideoURL:(NSError *)error apiVersion:(NSInteger)apiVersion {
    [self.retryFetchErrorInfo addObject:error];
    [self.retryFetchErrorInfo addObject:[[NSNumber alloc] initWithInt:apiVersion]];
}

- (void)firstDNSFailed:(NSError *)error {
    [self.firstDNSErrorInfo addObject:error];
}

- (void)fetchedVideoURL:(NSDictionary *)videoInfo error:(NSError *)error apiVersion:(NSInteger)apiVersion{
    if (error) {
        NSDictionary *errorUserInfo = error.userInfo;
        NSInteger internalCode = 0;
        if (errorUserInfo) {
            internalCode = [[errorUserInfo objectForKey:kTTVideoEngineAPIRetCodeKey] integerValue];
        }
    }
    else if (videoInfo) {
        [self.eventBase.videoInfo addEntriesFromDictionary:videoInfo];
        self.event.at = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        if (_dnsMode == LOGGER_DNS_MODE_AVPLAYER) {
            [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED isStart:YES];
        } else if (_dnsMode == LOGGER_DNS_MODE_ENGINE) {
            [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_LOADING_FETCHED isStart:YES];
        }
    }
}

- (void)showedOneFrame {
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState != LOGGER_STATE_SEEKING) {
            _loggerState = LOGGER_STATE_PLAYING;
            if (self.event.vt <= 0) {
                if (_eventOneError != nil) {
                    [_eventOneError showedFirstFrame];
                }
                if (_eventOneEvent != nil) {
                    [_eventOneEvent showedFirstFrame];
                }
            }
        }
    }
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_PLAYING isStart:YES];
    
    self.leaveWithoutPlay = NO;
    
    self.event.lt = 0;
    if (self.event.vt <= 0) {/// Initialized 0
        self.event.vt = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        
        if (self.delegate != nil) {
            self.event.video_codec_profile = [self.delegate getLogValueInt:LOGGER_VALUE_VIDEO_CODEC_PROFILE];
            self.event.audio_codec_profile = [self.delegate getLogValueInt:LOGGER_VALUE_AUDIO_CODEC_PROFILE];
        }
        
        _event.st_speed = [[TTVideoEngineStrategy helper] getNetworkSpeedBitPerSec];
    }
}

- (void)beginToParseDNS {
    [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED isStart:YES];
}

- (void)setDNSParseTime:(int64_t)dnsTime {
    if (self.event != nil && self.event.dns_t <= 0) {
        self.event.dns_t = dnsTime;
        [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED isStart:YES];
    }
}


- (void)setCurrentDefinition:(NSString *)toDefinition lastDefinition:(NSString *)lastDefinition {
    self.eventBase.lastResolution = lastDefinition;
    self.eventBase.currentResolution = toDefinition;
}

- (void)setCurrentQualityDesc:(NSString *)toQualityDesc {
    if (!self.eventBase.initialQualityDesc) {
        self.eventBase.initialQualityDesc = toQualityDesc;
    }
    self.eventBase.currentQualityDesc = toQualityDesc;
}

- (void)switchToDefinition:(NSString *)toDefinition fromDefinition:(NSString *)fromDefinition curPos:(NSInteger)curPos {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
            _mLastRebufT = curT;
            [self _movieStallEnd:EVENT_END_TYPE_SWITCH];
        }
        if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
            _mLastSeekT = curT;
            [self _endSeek:OPERA_END_TYPE_SWITCH isSeekInCache:0];
        }
        [self _avOutsyncEnd:curPos endType:EVENT_END_TYPE_SWITCH];
    }
    if (![toDefinition isEqualToString:fromDefinition]) {
        self.event.switch_resolution_c += 1;
    }
    //[self sendEvent];
    //self.event = [[TTVideoEngineEvent alloc] init];
    self.eventBase.lastResolution = fromDefinition;
    self.eventBase.currentResolution = toDefinition;
    self.eventBase.beginSwitchResolutionCurPos = curPos;
    self.eventBase.beginSwitchResolutionTime = curT;
    self.event.last_resolution_start_t = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_SWITCH isStart:YES];
    
    self.eventBase.lastResSwitchTime = curT;
}

- (void)switchResolutionEnd:(BOOL)isSeam {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        //in case seek when switching resolution
        if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
            _mLastSeekT = curT;
            [self _endSeek:OPERA_END_TYPE_WAIT isSeekInCache:0];
        }
        //in case switch when loading
        if (_loggerState == LOGGER_STATE_LOADING) {
            _loggerState = LOGGER_STATE_PLAYING;
        }
    }
    self.event.last_resolution_end_t = curT;
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_SWITCH isStart:NO];
    
    NSMutableDictionary *switchEventModel = [NSMutableDictionary dictionary];
    [switchEventModel ttvideoengine_setObject:self.eventBase.currentResolution forKey:@"to"];
    [switchEventModel ttvideoengine_setObject:@(self.eventBase.beginSwitchResolutionCurPos) forKey:@"p"];
    [switchEventModel ttvideoengine_setObject:@(curT) forKey:@"t"];
    [switchEventModel ttvideoengine_setObject:@(curT-self.eventBase.beginSwitchResolutionTime) forKey:@"c"];
    [switchEventModel ttvideoengine_setObject:@(isSeam) forKey:@"seam"];
    
    [self.event.resolution_list addEventModel:switchEventModel];
    
    self.eventBase.lastResSwitchTime = curT;
}

- (void)seekToTime:(NSTimeInterval)fromVideoPos afterSeekTime:(NSTimeInterval)afterSeekTime cachedDuration:(NSTimeInterval)cachedDuration switchingResolution:(BOOL)isSwitchingResolution {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    if (!isSwitchingResolution) {
        if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
            if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
                _mLastRebufT = curT;
                [self _movieStallEnd:EVENT_END_TYPE_SEEK];
            }
            if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
                _mLastSeekT = curT;
                [self _endSeek:OPERA_END_TYPE_SEEK isSeekInCache:0];
            }
            if (_eventOneOpera != nil) {
                [_eventOneOpera seekToTime:fromVideoPos toPos:afterSeekTime];
            }
            [self _avOutsyncEnd:fromVideoPos endType:EVENT_END_TYPE_SEEK];
            _loggerState = LOGGER_STATE_SEEKING;
        }
    }
    self.seekStartTs = curT;
    self.event.last_seek_start_t = curT;
    self.event.last_seek_positon = afterSeekTime * 1000;
    
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_LOADING_SEEK isStart:YES];
}

- (void)seekCompleted {
    if (self.seekStartTs > 0) {
        self.event.last_seek_end_t = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    }
}

- (void)renderSeekComplete:(BOOL)isSeekInCached {
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_LOADING_SEEK isStart:false];
    int64_t curT = (int64_t)[[NSDate date] timeIntervalSince1970] * 1000;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState == LOGGER_STATE_SEEKING) {
            _loggerState = LOGGER_STATE_PLAYING;
            if (self.seekStartTs > 0 && curT > self.seekStartTs) {
                self.event.seek_acu_t += (curT - self.seekStartTs);
            }
            self.seekStartTs = 0;
            if (_eventOneOpera != nil) {
                _mLastSeekT = (UInt64)curT;
                [self _endSeek:OPERA_END_TYPE_WAIT isSeekInCache:isSeekInCached];
            }
            if (_eventOneEvent != nil) {
                [_eventOneEvent seekHappend];
            }
        }
    }
}

// 调用者负责条件判断
- (void)_endSeek:(NSString*)reason isSeekInCache:(NSInteger)isSeekInCache {
    NSDictionary *eventModel = [_eventOneOpera endSeek:reason isSeekInCache:isSeekInCache];
    [self.event.seek_list addEventModel:eventModel];
}

- (void)moviePreStall:(NSInteger)reason {
    if (self.eventOneEvent) {
        [self.eventOneEvent moviePreStall:reason];
    }
}

- (NSInteger) getMovieStalledReason {
    if (self.eventOneEvent) {
        return [self.eventOneEvent getMovieStalledReason];
    }
    return -1;
}

- (void)movieStalledAfterFirstScreen:(TTVideoEngineStallReason)reason curPos:(NSInteger)curPos {
    long long curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    self.stallStartTs = curT;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW && reason == TTVideoEngineStallReasonNetwork) {
        if (_loggerState != LOGGER_STATE_LOADING && _loggerState != LOGGER_STATE_SEEKING) {
            //ignore load caused by seek and error retry.
            if (_eventOneEvent != nil) {
                [_eventOneEvent movieStalled:curPos];
            }
            _loggerState = LOGGER_STATE_LOADING;
        }
    }
    
    switch (reason) {
        case TTVideoEngineStallReasonNetwork:
            self.event.bc += 1;
            [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_LOADING_NET isStart:YES];
            break;
        case TTVideoEngineStallReasonDecoder:
            [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_DECODE isStart:YES];
            break;
        default:
            break;
    }
    if (self.event.first_buf_startt <= 0) {
        self.event.first_buf_startt = curT;
    }
    self.event.last_buffer_start_t = curT;
}

- (void)stallEnd {
    int64_t endTimestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState == LOGGER_STATE_LOADING) {
            _loggerState = LOGGER_STATE_PLAYING;
            if (_eventOneEvent != nil) {
                _mLastRebufT = endTimestamp;
                [self _movieStallEnd:EVENT_END_TYPE_WAIT];
            }
        }
    }
    if (self.event.first_buf_endt <= 0 && self.event.first_buf_startt > 0) {
        self.event.first_buf_endt = endTimestamp;
    }
    if (self.stallStartTs > 0) { // prevent not start stall
        self.accumulatedStalledTime += endTimestamp - self.stallStartTs;
        self.event.last_buffer_end_t = endTimestamp;
        self.stallStartTs = 0;
    } else if (_mEnableBufferingDirectly == 1 && self.event.before_play_buf_endt <= 0) {
        self.event.before_play_buf_endt = endTimestamp;
    }
    [self recordExitReason:ONEPLAY_EXIT_CODE_AFTER_PLAYING isStart:NO];
    
    if (self.event.pbt <= 0) {
        self.event.pbt = endTimestamp;
    }
}

// 调用者负责条件判断
- (void)_movieStallEnd:(NSString *)reason {
    NSDictionary *eventModel = [_eventOneEvent movieStallEnd:reason];
    [self.event.rebufList addEventModel:eventModel];
}

- (void)movieBufferDidReachEnd {
    if (self.event.bft <= 0) {
        self.event.bft = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    }
}

- (void)loopAgain {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    [self.event.loop_list addEventModel:@(curT)];
    
    self.loopCount++;
    if (_loopway == 0) {
        //engine做loop，vps叠加, loopVDS也要叠加
        if (self.delegate && [self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
            NSDictionary *bytesInfo = [self.delegate bytesInfoForEventLogger:self];
            if (bytesInfo) {
                int64_t vps = [[bytesInfo objectForKey:@"vps"] longLongValue];
                int64_t accu_vds = [[bytesInfo objectForKey:@"accu_vds"] longLongValue];
                _mAccumVPS += vps;
                _mEngineLoopVDS += accu_vds;
            }
        }
    }
}

- (void)setLooping:(BOOL)enable {
    self.isLooping = enable;
}

- (void)setLoopWay:(NSInteger)loopWay {
    self.loopway = loopWay;
}

- (void)_logFirstError:(NSError *)error {
    if (self.event != nil && self.event.first_errt <= 0
        && self.event.first_errc <= 0
        && self.event.first_errc_internal <= 0) {
        self.event.first_errt = TTVideoEngineGetErrorType(error);
        self.event.first_errc = error.code;
    }
}

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver{
    if ([error.domain isEqualToString:kTTVideoErrorDomainOwnPlayer] || [error.domain isEqualToString:kTTVideoErrorDomainSysPlayer]) {
        if (self.urlArray.count <= 1) {
            self.event.br += 1;
        }
    }
    [self.errorInfo addObject:@{@"error": error, @"strategy": @(strategy), @"apiver": @(apiver)}];
    
    [self _logFirstError:error];
    
    [self accumulateSize];
    
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_eventOneError != nil) {
            [_eventOneError moviePlayRetryWithError:error strategy:strategy apiver:apiver];
        }
        
        if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
            [_eventOneEvent movieShouldRetry];
        }
        
        if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
            [_eventOneOpera moviePlayRetryWithError:error strategy:strategy apiver:apiver];
        }
    }
    
    //clear timestamps before video start
    if (self.leaveWithoutPlay) {
        switch (strategy) {
            case TTVideoEngineRetryStrategyFetchInfo:
                self.event.at = LOGGER_INTEGER_EMPTY_VALUE;
            case TTVideoEngineRetryStrategyChangeURL:
                self.event.dns_t = LOGGER_INTEGER_EMPTY_VALUE;
            case TTVideoEngineRetryStrategyRestartPlayer:
                if (_dnsMode == LOGGER_DNS_MODE_AVPLAYER) {
                    self.event.dns_t = LOGGER_INTEGER_EMPTY_VALUE;
                }
                self.event.prepare_start_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.prepare_end_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.tran_ct = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.tran_ft = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.re_f_audioframet = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.re_f_videoframet = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.de_f_audioframet = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.de_f_videoframet = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.video_open_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.video_opened_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.audio_open_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.audio_opened_time = LOGGER_INTEGER_EMPTY_VALUE;
                self.event.first_frame_rendered_time = LOGGER_INTEGER_EMPTY_VALUE;
                break;
            default:
                break;
        }
    }
}

- (void)moviePlayRetryStartWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy curPos:(NSInteger)curPos {
    _errorRetryBeginTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _errorRetryCurPos = curPos;
    _errorRetryErrorCode = error.code;
    _errorRetryStrategy = strategy;
}

- (void)moviePlayRetryEnd {
    if (_errorRetryBeginTime <= 0) {
        return;
    }
    
    int64_t endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel ttvideoengine_setObject:@(_errorRetryErrorCode) forKey:@"ec"];
    [eventModel ttvideoengine_setObject:@(_errorRetryCurPos) forKey:@"p"];
    [eventModel ttvideoengine_setObject:@(endTime) forKey:@"t"];
    [eventModel ttvideoengine_setObject:@(endTime-_errorRetryBeginTime) forKey:@"c"];
    [eventModel ttvideoengine_setObject:@(_errorRetryStrategy) forKey:@"st"];
    
    [self.event.error_list addEventModel:eventModel];
    
    _errorRetryBeginTime = 0;
}

- (void)validateVideoMetaDataError:(NSError *)error
{
    if (!error) return;
    self.event.hijack = YES;
    [self.errorInfo addObject:@{@"error": error, @"info": @"video meta dada info not match play api"}];
}

- (void)movieFinishError:(NSError *)error currentPlaybackTime:(NSTimeInterval)currentPlaybackTime apiver:(TTVideoEnginePlayAPIVersion)apiver {
    [self.errorInfo addObject:@{@"error": error, @"strategy": @(TTVideoEngineRetryStrategyNone), @"apiver": @(apiver)}];
    BOOL isUpdateEventBase = YES;
    
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
            [self _endSeek:OPERA_END_TYPE_ERROR isSeekInCache:0];
            isUpdateEventBase = NO;
        }
        if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
            [self _movieStallEnd:EVENT_END_TYPE_ERROR];
            isUpdateEventBase = NO;
        }
        [self _avOutsyncEnd:currentPlaybackTime endType:EVENT_END_TYPE_ERROR];
        [self _noVARenderEnd:currentPlaybackTime noRenderType:-1 endType:EVENT_END_TYPE_ERROR];
        _loggerState = LOGGER_STATE_ERROR;
    }
    
    if (!_leaveWithoutPlay) {
        if ([error.domain isEqualToString:kTTVideoErrorDomainOwnPlayer] || [error.domain isEqualToString:kTTVideoErrorDomainSysPlayer]) {
            if (self.urlArray.count <= 1) {
                self.event.br += 1;
            }
        }
    }
    
    [self _recordExitTime];
    
    [self _logFirstError:error];
    self.event.errt = TTVideoEngineGetErrorType(error);
    self.event.errc = error.code;
    
//    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
//        if (_eventOneError != nil) {
//            [_eventOneError errorHappened:error];
//        }
//    }
    
    if (isUpdateEventBase) {
        [self.eventBase updateMDLInfo];
    }
    
    [self sendEvent];
    [self clear];
    [self initEvents];
}

- (void)accumulateSize {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
        NSDictionary *bytesInfo = [self.delegate bytesInfoForEventLogger:self];
        if (bytesInfo) {
            int64_t vps = [[bytesInfo objectForKey:@"vps"] longLongValue];
            int64_t vds = [[bytesInfo objectForKey:@"vds"] longLongValue];
            _mAccumVPS += vps;
            _mAccumVDS += vds;
            [TTVideoEngineCollector updatePlayConsumedSize:vps];
        }
    }
}

- (void)closeVideo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
        NSDictionary *bytesInfo = [self.delegate bytesInfoForEventLogger:self];
        if (bytesInfo) {
            self.event.v_decbuf_len = [bytesInfo[@"vDecLen"] longLongValue];
            self.event.a_decbuf_len = [bytesInfo[@"aDecLen"] longLongValue];
            self.event.v_basebuf_len = [bytesInfo[@"vBaseLen"] longLongValue];
            self.event.a_basebuf_len = [bytesInfo[@"aBaseLen"] longLongValue];
            
            int64_t vps = [[bytesInfo objectForKey:@"vps"] longLongValue];
            int64_t vds = [[bytesInfo objectForKey:@"vds"] longLongValue];
            int64_t accu_vds = [[bytesInfo objectForKey:@"accu_vds"] longLongValue];
            if (_isLooping) {
                vds = [[bytesInfo objectForKey:@"single_vds"] longLongValue];
            } else {
                vds = [[bytesInfo objectForKey:@"vds"] longLongValue];
            }
            self.event.vps = _mAccumVPS + vps;
            self.event.vds = _mAccumVDS + vds;
            self.event.accu_vds = _mEngineLoopVDS + accu_vds;
        }
    }
}
- (void)playbackFinish:(TTVideoEngineFinishReason)reason {
    BOOL isUpdateEventBase = YES;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (reason != TTVideoEngineFinishReasonStatusExcp) {
            if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
                [self _movieStallEnd:EVENT_END_TYPE_EXIT];
                isUpdateEventBase = NO;
            }
            if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
                [self _endSeek:OPERA_END_TYPE_EXIT isSeekInCache:0];
                isUpdateEventBase = NO;
            }
        }
        [self _avOutsyncEnd:-1 endType:EVENT_END_TYPE_EXIT];
        [self _noVARenderEnd:-1 noRenderType:-1 endType:EVENT_END_TYPE_EXIT];
    }
    
    [self _recordExitTime];
    
    self.event.leave_method = (NSInteger)reason;
    if (reason == TTVideoEngineFinishReasonPlaybackEnded) {
        self.event.finish = 1;
    }
    
    if (isUpdateEventBase) {
        [self.eventBase updateMDLInfo];
    }
    
    [self sendEvent];
    [self clear];
    [self initEvents];
}

- (void)watchFinish{
    self.event.finish = 1;
}

- (void)videoStatusException:(NSInteger)status {
    self.event.vsc = status;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW) {
        if (_loggerState == LOGGER_STATE_LOADING && _eventOneEvent != nil) {
            [self _movieStallEnd:EVENT_END_TYPE_ERROR];
        }
        if (_loggerState == LOGGER_STATE_SEEKING && _eventOneOpera != nil) {
            [self _endSeek:OPERA_END_TYPE_ERROR isSeekInCache:0];
        }
        _loggerState = LOGGER_STATE_ERROR;
        
        if (_eventOneError != nil) {
            [_eventOneError errorStatusHappened:status];
        }
    }
    [self playbackFinish:TTVideoEngineFinishReasonStatusExcp];
}

- (void)userCancelled {
    [self flushEvent];
    self.event = nil;
    self.eventBase = nil;
    self.eventOneError = nil;
    self.eventOneEvent = nil;
    self.eventOneOpera = nil;
    self.eventOneOutsync = nil;
    self.eventOneAVRenderCheck = nil;
    self.eventPredictorSample = nil;
    [self initEvents];
}


- (void)setInitalURL:(NSString *)url {
    _mInitialURL = url;
    self.eventBase.initialURL = url;
}

- (void)setCurrentURL:(NSString *)url {
    self.eventBase.curURL = url;
}

- (void)setCustomStr:(NSString *)customStr {
    self.event.customStr = customStr;
}

- (void)useHardware:(BOOL)enable {
    self.eventBase.hw = enable;
    self.eventBase.hw_user = enable;
    switch (_eventBase.video_codec_nameId) {
        case TTVideoCodecNameIOSHW:
            self.eventBase.hw = true;
            break;
        case TTVideoCodecNameH264:
        case TTVideoCodecNameBYTEVC1:
        case TTVideoCodecNameJXBYTEVC1:
        case TTVideoCodecNameLIBQYBYTEVC1:
        case TTVideoCodecNameBYTEVC2:
            self.eventBase.hw = false;
            break;
        default:
            break;
    }
}

- (void)setInitialHost:(NSString *)hostString{
    if (!self.event.initial_host || self.event.initial_host.length == 0) {
        self.event.initial_host = hostString;
    }
}

- (void)setIp:(NSString *)ipString{
    if (!self.event.initial_ip || self.event.initial_ip.length == 0) {
        self.event.initial_ip = ipString;
        self.eventBase.initial_ip = ipString;
    }
    if(ipString.length > 0){
        self.event.internal_ip = ipString;
        self.eventBase.internal_ip = ipString;
    }
}

- (void)setInitialResolution:(NSString *)resolutionString{
    if (!self.event.initial_resolution || self.event.initial_resolution.length == 0) {
        self.event.initial_resolution = resolutionString;
        self.eventBase.initial_resolution = resolutionString;
    }
}

- (void)setInitialQuality:(NSString *)qualityString{
    if (!self.event.initial_quality || self.event.initial_quality.length == 0) {
        self.event.initial_quality = qualityString;
    }
}

- (void)setVideoModelVersion:(NSInteger)videoModelVersion{
    self.event.video_model_version = videoModelVersion;
}

- (void)setPrepareStartTime:(long long)prepareStartTime{
    if (self.event.prepare_start_time < 1.0) {
        self.event.prepare_start_time = prepareStartTime;
    }
}

- (void)setPrepareEndTime:(long long)prepareEndTime{
    if (self.event.prepare_end_time < 1.0) {
        self.event.prepare_end_time = prepareEndTime;
    }
}

- (void)setRenderType:(NSString *)renderType{
    self.event.render_type = renderType;
}

- (void)setVideoPreloadSize:(long long)preloadSize{
    _mVideoPreloadSize = preloadSize;
}

- (void)setStartTime:(NSInteger)startTime {
    self.event.start_time = startTime;
}

- (void)logCodecNameId:(NSInteger)audioNameId video:(NSInteger)videoNameId {
    self.eventBase.audio_codec_nameId = audioNameId;
    self.eventBase.video_codec_nameId = videoNameId;
    switch (self.eventBase.video_codec_nameId) {
        case TTVideoCodecNameIOSHW:
            self.eventBase.hw = true;
            break;
        case TTVideoCodecNameH264:
        case TTVideoCodecNameBYTEVC1:
        case TTVideoCodecNameJXBYTEVC1:
        case TTVideoCodecNameLIBQYBYTEVC1:
        case TTVideoCodecNameBYTEVC2:
            self.eventBase.hw = false;
            break;
        default:
            break;
    }
}

- (void)logFormatType:(NSInteger)formatType  {
    self.eventBase.format_type = formatType;
}

- (void)logCurPos:(long)curPos {
    if (curPos < 0) {
        curPos = 0;
    }
    self.event.cur_play_pos = curPos;
}

- (void)playerPause{
    if (self.pauseStartTs < 1.0) {
        self.pauseStartTs = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    }
}

- (void)userPause:(NSInteger)curPos {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *pauseEventModel = [NSMutableDictionary dictionary];
    [pauseEventModel ttvideoengine_setObject:@(curPos) forKey:@"p"];
    [pauseEventModel ttvideoengine_setObject:@(curT) forKey:@"t"];
    [self.event.pause_list addEventModel:pauseEventModel];
    if (_mAVOutSyncing) {
        [self.eventOneOutsync setValue:@(curT) WithKey:VIDEO_OUTSYNC_KEY_PAUSE_TIME];
    }
}

- (void)playerPlay{
    if (self.pauseStartTs > 1.0) {
        self.pauseStartTs = 0.0;
    }
}

- (void)userPlay:(NSInteger)curPos {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *playEventModel = [NSMutableDictionary dictionary];
    [playEventModel ttvideoengine_setObject:@(curPos) forKey:@"p"];
    [playEventModel ttvideoengine_setObject:@(curT) forKey:@"t"];
    [self.event.play_list addEventModel:playEventModel];
}

- (void)userSetPlaybackSpeed:(CGFloat)playbackSpeed curPos:(NSInteger)curPos {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel ttvideoengine_setObject:@(playbackSpeed) forKey:@"to"];
    [eventModel ttvideoengine_setObject:@(curPos) forKey:@"p"];
    [eventModel ttvideoengine_setObject:@(curT) forKey:@"t"];
    [self.event.playspeed_list addEventModel:eventModel];
}

- (void)userSetRadioMode:(BOOL)radioMode curPos:(NSInteger)curPos {
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel ttvideoengine_setObject:@(radioMode?1:0) forKey:@"s"];
    [eventModel ttvideoengine_setObject:@(curPos) forKey:@"p"];
    [eventModel ttvideoengine_setObject:@(curT) forKey:@"t"];
    [self.event.radiomode_list addEventModel:eventModel];
    
    self.eventBase.lastAVSwitchTime = curT;
    
    self.eventBase.radioMode = radioMode ? 1 : 0;
}

- (void)playerViewBoundsChange:(CGRect)bounds {
    CGRect lastRect = self.event.cur_view_bounds;
    if (CGRectEqualToRect(lastRect, bounds)) {
        return;
    }
    
    self.event.cur_view_bounds = bounds;
    UInt64 curT = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *eventModel = [NSMutableDictionary dictionary];
    [eventModel setObject:@(curT) forKey:@"t"];
    [eventModel setObject:@(TTVideoEngineValidNumber(bounds.size.width)) forKey:@"w"];
    [eventModel setObject:@(TTVideoEngineValidNumber(bounds.size.height)) forKey:@"h"];
    [self.event.view_size_list addEventModel:eventModel];
}

- (void)beginLoadDataWhenBufferEmpty{
    NSTimeInterval tem = [[NSDate date] timeIntervalSince1970];
    if (self.event.per_buffer_duration.count % 2 == 0) {
        [self.event.per_buffer_duration addObject:@(tem)];
    }else{
        /// safe remove last object
        [self.event.per_buffer_duration ttvideoengine_removeObjectAtIndex:self.event.per_buffer_duration.count-1];
        [self.event.per_buffer_duration addObject:@(tem)];
    }
}

- (void)endLoadDataWhenBufferEmpty{
    NSTimeInterval tem = [[NSDate date] timeIntervalSince1970];
    if (self.event.per_buffer_duration.count % 2 == 1) {
        [self.event.per_buffer_duration addObject:@(tem)];
    }
}

- (void)updateCustomPlayerParms:(NSDictionary *)param{
    if ([param isKindOfClass:[NSDictionary class]]) {
        [_mPlayparam addEntriesFromDictionary:param];
        CGFloat speed = [[param objectForKey:@"speed"] floatValue];
        if (speed > 0.0f) {
            _eventBase.playSpeed = speed;
        }
    }
}

- (void)setPlayerSourceType:(NSInteger)sourceType{
    self.eventBase.play_type = sourceType;
}

- (void)setVideoOutFPS:(CGFloat)fps{
    self.event.video_out_fps = fps;
}

- (void)setAudioDropCnt:(int)cnt {
    self.event.audio_drop_cnt = cnt;
}

- (void)setVideoDecoderFPS:(NSInteger)fps {
    self.event.video_decoder_fps = fps;
}

- (void)setReuseSocket:(NSInteger)reuseSocket {
    _mEnableReuseSocket = reuseSocket;
    self.eventBase.reuse_socket = reuseSocket;
}

- (void)setDisableAccurateStart:(NSInteger)disableAccurateStart {
    self.event.disable_accurate_start = disableAccurateStart;
}

- (void)logWatchDuration:(NSInteger)watchDuration {
    self.event.watch_dur = watchDuration;
}

- (void)proxyUrl:(NSString *)proxyUrl {
    if (proxyUrl) {
        if ([proxyUrl containsString:@"mdl://"]) {
            _mEnableMdl = 2;
        } else {
            _mEnableMdl = 1;
        }
    } else {
        _mEnableMdl = 0;
    }
    
    //enable mdl, dns parsed in mdl
    [self recordExitReason:ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED isStart:YES];
}

- (void)engineState:(TTVideoEngineState)engineState {
    self.event.engine_state = engineState;
}

- (void)setDrmType:(NSInteger)drmType {
    self.eventBase.drm_type = drmType;
}

- (void)setDrmTokenUrl:(NSString *)drmTokenUrl {
    self.eventBase.drm_token_url = drmTokenUrl;
}

- (void)setApiString:(NSString *)apiString {
    _apiString = apiString;
    self.event.api_string = apiString;
}

- (void)setNetClient:(NSString *)netClient {
    self.event.net_client = netClient;
}

- (void)setPlayAPIVersion:(TTVideoEnginePlayAPIVersion)apiVersion auth:(NSString *)auth {
    _apiver = apiVersion;
    _auth = auth;
    self.event.auth = self.auth;
}

- (void)updateMediaDuration:(NSTimeInterval)duration {
    if (duration > 1.0) {
        [self.eventBase.videoInfo setObject:@(duration) forKey:kTTVideoEngineVideoDurationKey];
    }
}

- (void)logBitrate:(NSInteger)bitrate {
    self.event.bitrate = bitrate;
}

- (void)logAudioBitrate:(NSInteger)audioBitrate {
    self.event.audioBitrate = audioBitrate;
}

- (void)logCodecName:(NSString *)audioName video:(NSString *)videoName {
    if (videoName) {
        [self.eventBase.videoInfo setObject:videoName forKey:kTTVideoEngineVideoCodecKey];
    }
    if (audioName) {
        [self.eventBase.videoInfo setObject:audioName forKey:kTTVideoEngineAudioCodecKey];
    }
}

- (void)setDynamicType:(NSString *)dynamicType {
    self.event.dynamic_type = dynamicType;
}

- (void)setTraceId:(NSString *)traceId {
    self.event.traceID = traceId;
}

- (NSString*)getTraceId {
    return [self.event.traceID copy];
}

- (void)setEnableBoe:(NSInteger)enableBoe {
    self.event.enable_boe = enableBoe;
}

- (void)setEnableBash:(NSInteger)enableBash {
    self.event.enable_bash = enableBash;
}

- (void)addCpuUsagesPoint:(CGFloat)point {
    if (!self.performancePointSwitch || point < 0.0f || point > 1.0f) {
        return;
    }
    
    [_cpuUsages addObject:@(point)];
}

- (void)addMemUsagesPoint:(CGFloat)point {
    if (!self.performancePointSwitch || point < 0.0f ) {
        return;
    }
    
    [_memUsages addObject:@(point)];
}

- (void)logPlayerInfo:(NSString *)logInfo {
    self.logInfo = logInfo;
}

- (void)_recordExitTime {
    if (_leaveWithoutPlay) {
        if (self.event.lt < 1) {
            self.event.lt = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        }
    } else {
        if (self.event.et < 1) {
            self.event.et = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        }
    }
}

- (void)recordExitReason:(NSInteger)reason isStart:(BOOL)isStart {
    if (isStart) {
        self.event.leave_reason = reason;
        if (reason == ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH ||
            reason == ONEPLAY_EXIT_CODE_BEFORE_LOADING_FETCHED ||
            reason == ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED ||
            reason == ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED) {
            if (_leaveBlockT == 0)
                _leaveBlockT = (NSInteger)[[NSDate date] timeIntervalSince1970] * 1000;
        } else if (reason == ONEPLAY_EXIT_CODE_AFTER_LOADING_NET ||
              reason == ONEPLAY_EXIT_CODE_AFTER_LOADING_SEEK) {
            _leaveBlockT = (NSInteger)[[NSDate date] timeIntervalSince1970] * 1000;
        } else {
            _leaveBlockT = 0;
        }
    } else {
        self.event.leave_reason = ONEPLAY_EXIT_CODE_AFTER_PLAYING;
        _leaveBlockT = 0;
    }
}

// called when play ends
- (void)clear {
    self.leaveWithoutPlay = YES;
    self.stallStartTs = 0;
    [self.retryFetchErrorInfo removeAllObjects];
    [self.firstDNSErrorInfo removeAllObjects];
    [self.errorInfo removeAllObjects];
    
    _vid = nil;
    _urlArray = nil;
    _loopCount = 0;
    _accumulatedStalledTime = 0.0;
    _seekCount = 0;
    _apiString = nil;
    _apiver = 0;
    _auth = nil;
    _isLocal = NO;
    _pauseStartTs = 0;
    [_cpuUsages removeAllObjects];
    [_memUsages removeAllObjects];
    [self.metricsInfo removeAllObjects];
    _seekStartTs = 0;
    self.logInfo = nil;
    _dnsMode = LOGGER_DNS_MODE_ENGINE;
    _loggerState = LOGGER_STATE_IDLE;
    _leaveBlockT = 0;
    _mAccumVPS = 0;
    _mAccumVDS = 0;
    _mEnableHttps = -1;
    _mAVOutSyncing = NO;
    _mLastSeekT = -1LL;
    _mLastRebufT = -1LL;
    _errorRetryBeginTime = 0;
    _errorRetryCurPos = 0;
    _errorRetryErrorCode = 0;
    _errorRetryStrategy = 0;
    [_mFeatures removeAllObjects];
    _mMessage = @"";
    [_mMDLRetryInfo removeAllObjects];
    _mFromEnginePool = @"after clear V2";
    _mEngineLoopVDS = 0;
}

// called when set new url
- (void)reset {
    _mWidth = 0;
    _mHeight = 0;
    [_mPlayparam removeAllObjects];
    _mInitialURL = nil;
    _mEnableMdl = 0;
    _mVideoPreloadSize = 0;
    _mMessage = @"";
    [_mMDLRetryInfo removeAllObjects];
}

- (void)flushEvent {
    if (self.event.lt > 0) {
        [self sendEvent];
    }
    else {
        self.event.lt = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        [self sendEvent];
    }
}

- (void)finishReason:(TTVideoEngineFinishReason)leaveMethod{
    if (self.event) {
        self.event.leave_method = (NSInteger)leaveMethod;
    }
}

- (void)recordFirstFrameMetrics:(TTVideoEnginePlayer *)player {
    
    self.event.tran_ct = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsTranConnectTime];
    self.event.tran_ft = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsTranFirstPacketTime];
    self.event.re_f_videoframet = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsReceiveFirstVideoFrameTime];
    self.event.re_f_audioframet = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsReceiveFirstAudioFrameTime];
    self.event.de_f_videoframet = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDecodeFirstVideoFrameTime];
    self.event.de_f_audioframet = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDecodeFirstAudioFrameTime];
    self.event.video_open_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDeviceOpenTime];
    self.event.video_opened_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDeviceOpenedTime];
    self.event.audio_open_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDeviceOpenTime];
    self.event.audio_opened_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDeviceOpenedTime];
    self.event.first_frame_rendered_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsFirstFrameRenderedTime];
    
    int64_t dns_end_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsSaveHostTime];
    if (dns_end_time > 0) {
        self.event.dns_t = dns_end_time;
        [self setInt64Option:LOGGER_OPTION_TIME_DNS_END value:dns_end_time];
    }
    int64_t dns_start_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDNSStartTime];
    if (dns_start_time > 0) {
        [self setInt64Option:LOGGER_OPTION_TIME_DNS_START value:dns_start_time];
    }
    int64_t audio_dns_start_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDNSStartTime];
    if (audio_dns_start_time > 0) {
        [self setInt64Option:LOGGER_OPTION_TIME_AUDIO_DNS_START value:audio_dns_start_time];
    }
    int64_t audio_dns_end_time = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioSaveHostTime];
    if (audio_dns_end_time > 0) {
        [self setInt64Option:LOGGER_OPTION_TIME_AUDIO_DNS_END value:audio_dns_end_time];
    }
    [self setInt64Option:LOGGER_OPTION_TIME_FORMATER_CREATE value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsFormaterCreateTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_AVFORMAT_OPEN value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAVFormatOpenTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_DEMUXER_BEGIN value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDemuxerBeginTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_DEMUXER_CREATE value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDemuxerCreateTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_DEC_CREATE value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsDecCreateTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_OUTLET_CREATE value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsOutletCreateTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_V_DEC_START value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDecoderStartTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_V_DEC_OPENED value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDecoderOpenedTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_A_DEC_START value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDecoderStartTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_A_DEC_OPENED value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDecoderOpenedTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_V_RENDER_F value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsFirstFrameRenderedTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_A_RENDER_F value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioRendFirstFrameTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_A_TRAN_CT value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioTranConnectTime]];
    [self setInt64Option:LOGGER_OPTION_TIME_A_TRAN_FT value:[player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioTranFirstPacketTime]];
    self.event.v_http_open_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsHttpOpenStart];
    self.event.a_http_open_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioHttpOpenStart];
    self.event.v_tran_open_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsTransOpenStart];
    self.event.a_tran_open_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioTransOpenStart];
    self.event.v_sock_create_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsSocketCreateSuccess];
    self.event.a_sock_create_t = [player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioSocketCreateSuccess];
    
    if (![self.metricsInfo objectForKey:kTTVideoEngineReadHeaderDuration]) {
        NSInteger readHeaderDuration = self.event.tran_ft > 0 ? (self.event.tran_ft -  self.event.prepare_start_time) : 0;
        NSInteger readFirstVideoPktDuration = self.event.re_f_videoframet - self.event.prepare_start_time;
        NSInteger firstFrameDecodedDuration = self.event.de_f_videoframet - self.event.prepare_start_time;
        NSInteger firstFrameRenderDuration = self.event.vt - self.event.prepare_start_time;
        NSInteger playbackBufferEndDuration = self.event.pbt > 0 ? (self.event.pbt - self.event.prepare_start_time) : 0;
        NSInteger firstFrameDuration = self.event.vt > 0 ? (self.event.vt - self.event.pt_new) : 0;
        
        [self.metricsInfo setObject:@(readHeaderDuration) forKey:kTTVideoEngineReadHeaderDuration];
        [self.metricsInfo setObject:@(readFirstVideoPktDuration) forKey:kTTVideoEngineReadFirstDataDuration];
        [self.metricsInfo setObject:@(firstFrameDecodedDuration) forKey:kTTVideoEngineFirstFrameDecodeDuration];
        [self.metricsInfo setObject:@(firstFrameRenderDuration) forKey:kTTVideoEngineFirstRenderDuration];
        [self.metricsInfo setObject:@(playbackBufferEndDuration) forKey:kTTVideoEnginePlaybackBuffingDuration];
        [self.metricsInfo setObject:@(firstFrameDuration) forKey:kTTVideoEngineFirstFrameDuration];
    }
    
    // get loader type, tricky...
//    self.event.mdl_loader_type = [player getStringValueForKey:]
}

- (void)setAVSyncStartEnable:(NSInteger) enable {
    self.event.av_sync_start_enable = enable;
}

- (void)setInt64Option:(NSInteger)key value:(int64_t)value {
    switch (key) {
        case LOGGER_OPTION_TIME_SET_DATSSOURCE:
            if (self.event.setds_t <= 0) {
                self.event.setds_t = value;
            }
            break;
        case LOGGER_OPTION_TIME_PS_T:
            if (self.event.ps_t <= 0) {
                self.event.ps_t = value;
            }
            break;
        case LOGGER_OPTION_TIME_AUDIO_DNS_START:
            self.event.a_dns_start_t = value;
            break;
        case LOGGER_OPTION_TIME_AUDIO_DNS_END:
            self.event.a_dns_t = value;
            break;
        case LOGGER_OPTION_TIME_FORMATER_CREATE:
            self.event.formater_create_t = value;
            break;
        case LOGGER_OPTION_TIME_AVFORMAT_OPEN:
            self.event.avformat_open_t = value;
            break;
        case LOGGER_OPTION_TIME_DEMUXER_BEGIN:
            self.event.demuxer_begin_t = value;
            break;
        case LOGGER_OPTION_TIME_DEMUXER_CREATE:
            self.event.demuxer_create_t = value;
            break;
        case LOGGER_OPTION_TIME_DEC_CREATE:
            self.event.dec_create_t = value;
            break;
        case LOGGER_OPTION_TIME_OUTLET_CREATE:
            self.event.outlet_create_t = value;
            break;
        case LOGGER_OPTION_TIME_V_DEC_START:
            self.event.v_dec_start_t = value;
            break;
        case LOGGER_OPTION_TIME_A_DEC_START:
            self.event.a_dec_start_t = value;
            break;
        case LOGGER_OPTION_TIME_V_DEC_OPENED:
            self.event.v_dec_opened_t = value;
            break;
        case LOGGER_OPTION_TIME_A_DEC_OPENED:
            self.event.a_dec_opened_t = value;
            break;
        case LOGGER_OPTION_TIME_V_RENDER_F:
            self.event.v_render_f_t = value;
            break;
        case LOGGER_OPTION_TIME_A_RENDER_F:
            self.event.a_render_f_t = value;
            break;
        case LOGGER_OPTION_TIME_DNS_START:
            self.event.dns_start_t = value;
            break;
        case LOGGER_OPTION_TIME_DNS_END:
            self.event.dns_end_t = value;
            break;
        case LOGGER_OPTION_TIME_A_TRAN_CT:
            self.event.a_tran_ct = value;
            break;
        case LOGGER_OPTION_TIME_A_TRAN_FT:
            self.event.a_tran_ft = value;
            break;
        case LOGGER_OPTION_VIDEO_AUDIO_POSITION_GAP:
            if (self.event.av_gap <= 0) {
                self.event.av_gap = value;
            }
            break;
        case LOGGER_OPTION_MOOV_POSITION:
            if (self.event.moov_pos <= 0) {
                self.event.moov_pos = value;
            }
            break;
        case LOGGER_OPTION_MDAT_POSITION:
            if (self.event.mdat_pos <= 0) {
                self.event.mdat_pos = value;
            }
            break;
        case LOGGER_OPTION_TIME_SUB_DID_LOAD:
            if (self.event.sub_load_finished_time <= 0) {
                self.event.sub_load_finished_time = value;
            }
            break;
        case LOGGER_OPTION_BUFFER_START_BEFORE_PLAY:
            if (self.event.before_play_buf_startt <= 0) {
                self.event.before_play_buf_startt = value;
            }
            break;
        case LOGGER_OPTION_VIDEO_BUFFER_LEN:
            self.event.video_buffer_len = value;
            break;
        case LOGGER_OPTION_AUDIO_BUFFER_LEN:
            self.event.audio_buffer_len = value;
            break;
        case LOGGER_OPTION_VIDEO_STREAM_DURATION:
            self.eventBase.video_stream_duration = value;
            break;
        case LOGGER_OPTION_AUDIO_STREAM_DURATION:
            self.eventBase.audio_stream_duration = value;
            break;
        case LOGGER_OPTION_MIN_AUDIO_FRAME_SIZE:
            self.event.min_audio_frame_size = value;
            break;
        case LOGGER_OPTION_MIN_VIDEO_FRAME_SIZE:
            self.event.min_video_frame_size = value;
            break;
        default:
            break;
    }
}

- (void)setIntOption:(NSInteger)key value:(NSInteger)value {
    switch (key) {
        case LOGGER_OPTION_RADIO_MODE:
            self.eventBase.radioMode = value;
            break;
        case LOGGER_OPTION_IS_REPLAY:
            self.event.isReplay = value;
            break;
        case LOGGER_OPTION_VIDEO_STREAM_DISABLED:
            self.event.video_stream_disabled = value;
            break;
        case LOGGER_OPTION_AUDIO_STREAM_DISABLED:
            self.event.audio_stream_disabled = value;
            break;
        case LOGGER_OPTION_CONTAINER_FPS:
            self.event.container_fps = value;
            break;
        case LOGGER_OPTION_ENABLE_LOADCONTROL:
            _mEnableLoadControl = value;
            break;
        case LOGGER_OPTION_ENABLE_NETWORK_TIMEOUT:
            _mEnableNetworkTimeout = value;
            break;
        case LOGGER_OPTION_NETWORK_TIMEOUT:
            _mNetworkTimeout = value;
            break;
        case LOGGER_OPTION_BUFFERING_TIMEOUT:
            _mBufferTimeout = value;
            break;
        case LOGGER_OPTION_BUFFERING_DIRECTLY:
            _mEnableBufferingDirectly = value;
            break;
        case LOGGER_OPTION_ENABLE_BUFFER_MILLI_SECONDS:
            _mEnableBufferingMilliSeconds = (value == 1);
            break;
        case LOGGER_OPTION_BUFFER_END_MILLI_SECONDS:
            _mBufferEndMilliSeconds = value;
            break;
        case LOGGER_OPTION_BUFFER_END_SECONDS:
            _mBufferEndSeconds = value;
            break;
        case LOGGER_OPTION_ENABLE_VOLUME_BALANCE:
            _mEnableVolumeBalance = value;
            break;
        case LOGGER_OPTION_VOLUME_BALANCE_TYPE:
            _mVolumeBalanceType = value;
            break;
        case LOGGER_OPTION_ENABLE_AUTO_RANGE:
            _mEnableAutoRange = value;
            break;
        case LOGGER_OPTION_IMAGE_SCALE_TYPE:
            _mImageScaleType = value;
            break;
        case LOGGER_OPTION_ENABLE_DASH_ABR:
            _mEnableAbr = value;
            _eventBase.isEnableABR = value;
            break;
        case LOGGER_OPTION_ENABLE_HTTPS:
            _mEnableHttps = value;
            break;
        case LOGGER_OPTION_ENABLE_HIJACK_RETRY:
            _mEnableHijackRetry = value;
            break;
        case LOGGER_OPTION_ENABLE_FALLBACK_API_MDL_RETRY:
            _mEnableFallbackApiMDLRetry = value;
            break;
        case LOGGER_OPTION_SKIP_FIND_STREAM:
            _mEnableSkipFindStream = value;
            break;
        case LOGGER_OPTION_ENABLE_ASYNC_PREPARE:
            _mEnableAsyncPrepare = value;
            break;
        case LOGGER_OPTION_ENABLE_LAZY_SEEK:
            _mEnableLazySeek = value;
            break;
        case LOGGER_OPTION_ENABLE_FORMATER_KEEP_ALIVE:
            _mEnableFormaterKeepAlive = value;
            break;
        case LOGGER_OPTION_DISABLE_SHORT_SEEK:
            _mDisableShortSeek = value;
            break;
        case LOGGER_OPTION_PREF_NEAR_SAMPLE:
            _mPrefNearSample = value;
            break;
        case LOGGER_OPTION_FRAME_DROP_COUNT:
            self.event.mDropCount = value;
            break;
        case LOGGER_OPTION_PIXEL_FORMAT:
            if (value == AV_PIXEL_FMT_YUV420P10LE) {
                self.event.video_pixel_bit = 10;
            } else if (value >= 0) {
                self.event.video_pixel_bit = 8;
            }
            break;
        case LOGGER_OPTION_COLOR_TRC:
            self.event.color_trc = value;
            break;
        case LOGGER_OPTION_COLOR_SPACE:
            self.event.color_space = value;
            break;
        case LOGGER_OPTION_COLOR_PRIMARIES:
            self.event.color_primaries = value;
            break;
        case LOGGER_OPTION_ENABLE_OUTLET_DROP_LIMIT:
            _mEnableOutletDropLimit = value;
            break;
        case LOGGER_OPTION_PLAYERVIEW_HIDDEN_STATE:
            self.event.playerview_hidden = value;
            break;
        case LOGGER_OPTION_OPERA_EVENT_REPORT_LEVEL:
            self.eventOneOpera.reportLevel = value;
            break;
        case LOGGER_OPTION_VIDEO_STYLE:
            self.event.video_style = value;
            break;
        case LOGGER_OPTION_DIMENTION:
            self.event.dimension = value;
            break;
        case LOGGER_OPTION_PROJECTION_MODEL:
            self.event.projection_model = value;
            break;
        case LOGGER_OPTION_VIEW_SIZE:
            self.event.view_size = value;
            break;
        case LOGGER_OPTION_ENGINEPOOL_ENGINE_HASH_CODE:
            self.event.mEngineHash = value;
            break;
        case LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_UPPERLIMIT:
            self.event.mCorePoolSizeUpperLimit = value;
            break;
        case LOGGER_OPTION_ENGINEPOOL_COUNT_ENGINE_IN_USE:
            self.event.mCountOfEngineInUse = value;
            break;
        case LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_BEFORE_GETENGINE:
            self.event.mCorepoolSizeBeforeGetEngine = value;
            break;
        case LOGGER_OPTION_EXPIRE_PLAY_CODE:
            self.event.mExpirePlayCode = value;
            break;
        case LOGGER_OPTION_METALVIEW_DOUBLE_BUFFERING:
            self.mEnableMetalViewDoubleBuffer = value;
            break;
        case LOGGER_OPTION_MIN_FEEDIN_COUNT_BEFORE_DECODED:
            self.event.feed_in_before_decoded = value;
            break;
        case LOGGER_OPTION_BUFFERING_THRESHOLD_SIZE:
            self.event.netblockBufferthreshold = value;
            break;
        default:
            break;
    }
}

- (void)setStringOption:(NSInteger)key value:(NSString *)value {
    switch (key) {
        case LOGGER_OPTION_LOG_ID:
            self.event.log_id = value.copy;
            NSLog(@"brian logger logid:%@", self.event.log_id);
            break;
        case LOGGER_OPTION_IS_FROM_ENGINE_POOL:
            self.mFromEnginePool = value.copy;
            break;
        case LOGGER_OPTION_VIDEO_FILE_HASH:
            self.event.mVideoFileHash = value;
            break;
        case LOGGER_OPTION_AUDIO_FILE_HASH:
            self.event.mAudioFileHash = value;
            break;
        case LOGGER_OPTION_CUSTOM_COMPANY_ID:
            self.event.mCustomCompanyId = value;
            break;
        default:
            break;
    }
}

- (void)parseUrlLogID {
    if (!self.event) {
        return;
    }
    
    BOOL isEncoded = NO;
    NSString* url = nil;
    NSString* format = @"&l=";
    NSString* format_encoded = @"%26l%3D";
    if (self.event.initialURL.length != 0) {
        url = self.event.initialURL.copy;
    } else {
        return;
    }
    
    NSRange start = [url rangeOfString:format];
    if (start.location == NSNotFound) {
        start = [url rangeOfString:format_encoded];
        isEncoded = YES;
    }
    if (start.location != NSNotFound) {
        NSString* sub_url;
        if (isEncoded) {
            sub_url = [url substringFromIndex:start.location+format_encoded.length];
        } else {
            sub_url = [url substringFromIndex:start.location+format.length];
        }
        NSRange end;
        if (isEncoded) {
            end = [sub_url rangeOfString:@"%26"];
        } else {
            end = [sub_url rangeOfString:@"&"];
        }
        NSUInteger length = 0;
        if (end.location != NSNotFound) {
            length = end.location;
        } else {
            length = sub_url.length;
        }
        NSRange range = NSMakeRange(0, length);
        self.event.log_id = [sub_url substringWithRange:range];
    }
}

- (void)updateFeatures {
    [self.event.mFeatures addEntriesFromDictionary:_mFeatures];
    if (sFeatures) {
        [self.event.mFeatures addEntriesFromDictionary:sFeatures];
    }
    if (self.eventBase.hw) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_VIDEO_HW];
    }
    
    if ([self.event.codec isEqualToString:@"bytevc1"]) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_BYTEVC1];
    } else if ([self.event.codec isEqualToString:@"bytevc2"]) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_BYTEVC2];
    }
    
    if (_mEnableLoadControl > 0) {
        [self.event.mFeatures setObject:@(_mEnableLoadControl) forKey:FEATURE_KEY_ENABLE_LOAD_CONTROL];
    }
    
    if (_mEnableNetworkTimeout > 0 && _mNetworkTimeout > 0) {
        [self.event.mFeatures setObject:@(_mNetworkTimeout) forKey:FEATURE_KEY_NETWORK_TIMEOUT];
    }
    
    if (_mBufferTimeout > 0) {
        [self.event.mFeatures setObject:@(_mBufferTimeout) forKey:FEATURE_KEY_BUFFER_TIMEOUT];
    }
    
    if (_mEnableBufferingDirectly > 0) {
        [self.event.mFeatures setObject:@(_mEnableBufferingDirectly) forKey:FEATURE_KEY_BUFFER_DIRECTLY];
    }
    
    if (_mEnableBufferingMilliSeconds && _mBufferEndMilliSeconds > 0) {
        [self.event.mFeatures setObject:@(_mBufferEndMilliSeconds) forKey:FEATURE_KEY_FIRST_BUFFER_END_MS];
    } else if (_mBufferEndSeconds > 0) {
        [self.event.mFeatures setObject:@(_mBufferEndSeconds*1000) forKey:FEATURE_KEY_FIRST_BUFFER_END_MS];
    }
    
    if (self.event.enable_nnsr > 0) {
        [self.event.mFeatures setObject:@(self.event.enable_nnsr) forKey:FEATURE_KEY_SR];
    }
    
    if (_mEnableVolumeBalance > 0) {
        if (TTVideoVolumeBalanceTypeClimiter == _mVolumeBalanceType) {
            [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_VOLUME_BALANCE_V2];
        } else {
            [self.event.mFeatures setObject:@(_mEnableVolumeBalance) forKey:FEATURE_KEY_VOLUME_BALANCE];
        }
    }
    
    if (_mEnableAutoRange > 0) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_AUTO_RANGE];
    }
    
    if (28 == self.event.audio_codec_profile) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_HEAAC_V2];
    }
    
    if (self.event.render_type != nil) {
        if ([self.event.render_type isEqualToString:kTTVideoEngineRenderTypeMetal]) {
            [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_METAL];
        }
        // unify value to android
        if ([self.event.render_type isEqualToString:kTTVideoEngineRenderTypeOpenGLES]) {
            [self.event.mFeatures setObject:@(3) forKey:FEATURE_KEY_RENDER_TYPE];
        } else if ([self.event.render_type isEqualToString:kTTVideoEngineRenderTypeOutput]) {
            [self.event.mFeatures setObject:@(101) forKey:FEATURE_KEY_RENDER_TYPE];
        }
    }
    
    if (_mImageScaleType > 0) {
        [self.event.mFeatures setObject:@(_mImageScaleType) forKey:FEATURE_KEY_IMAGE_SCALE];
    }
    
    if (self.event.enable_bash > 0) {
        [self.event.mFeatures setObject:@(self.event.enable_bash) forKey:FEATURE_KEY_BASH];
    }
    
    if (_mEnableAbr > 0) {
        [self.event.mFeatures setObject:@(_mEnableAbr) forKey:FEATURE_KEY_ABR];
    }
    
    if (self.eventBase.mdl_cache_type == 2) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_PRELOAD];
    }
    
    if (_mEnableHttps > 0) {
        [self.event.mFeatures setObject:@(_mEnableHttps) forKey:FEATURE_KEY_HTTPS];
    }
    
    if (self.event.check_hijack > 0) {
        [self.event.mFeatures setObject:@(self.event.check_hijack) forKey:FEATURE_KEY_HIJACK];
    }
    if (_mEnableHijackRetry > 0) {
        [self.event.mFeatures setObject:@(_mEnableHijackRetry) forKey:FEATURE_KEY_HIJACK_RETRY];
    }
    
    if (_mEnableFallbackApiMDLRetry > 0) {
        [self.event.mFeatures setObject:@(_mEnableFallbackApiMDLRetry) forKey:FEATURE_KEY_FALLBACK_API];
    }
    
    if (_mEnableSkipFindStream > 0) {
        [self.event.mFeatures setObject:@(_mEnableSkipFindStream) forKey:FEATURE_KEY_SKIP_FIND_STREAM_INFO];
    }
    
    if (_mEnableAsyncPrepare > 0) {
        [self.event.mFeatures setObject:@(_mEnableAsyncPrepare) forKey:FEATURE_KEY_ENABLE_ASYNC_PREPARE];
    }
    
    if (_mEnableLazySeek > 0) {
        [self.event.mFeatures setObject:@(_mEnableLazySeek) forKey:FEATURE_KEY_LAZY_SEEK];
    }
    
    if (_mEnableFormaterKeepAlive > 0) {
        [self.event.mFeatures setObject:@(_mEnableFormaterKeepAlive) forKey:FEATURE_KEY_KEEP_FORMAT_THREAD_ALIVE];
    }
    
    if (_mDisableShortSeek > 0) {
        [self.event.mFeatures setObject:@(_mDisableShortSeek) forKey:FEATURE_KEY_DISABLE_SHORT_SEEK];
    }
    
    if (_mPrefNearSample > 0) {
        [self.event.mFeatures setObject:@(_mPrefNearSample) forKey:FEATURE_KEY_MOV_PREFER_NEAR_SAMPLE];
    }
    
    if (_mEnableReuseSocket > 0) {
        [self.event.mFeatures setObject:@(_mEnableReuseSocket) forKey:FEATURE_KEY_SOCKET_REUSE];
    }
    
    if (_event.color_trc == AVCOL_TRC_SMPTE2084) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_HDR_PQ];
    }
    if (_event.color_trc == AVCOL_TRC_ARIB_STD_B67) {
        [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_HDR_HLG];
    }
    if (_mEnableOutletDropLimit >= 0) {
        [self.event.mFeatures setObject:@(_mEnableOutletDropLimit) forKey:FEATURE_KEY_ENABLE_OUTLET_DROP_LIMIT];
    }
    
    if (_mEnableMdl > 0) {
        [self.event.mFeatures setObject:@(_mEnableMdl) forKey:FEATURE_KEY_MDL_TYPE];
        
        TTVideoEngineLocalServerConfigure *configure = [TTVideoEngine ls_localServerConfigure];
        if (configure) {
            if (configure.enableSoccketReuse) {
                [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_SOCKET_REUSE];
            }
            
            if (configure.isEnablePreConnect) {
                [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_PRE_CONNECT];
            }
            
            if (configure.isEnableSessionReuse) {
                [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_SESSION_REUSE];
            }
            
            if (configure.maxTlsVersion == 3) {
                [self.event.mFeatures setObject:@(configure.maxTlsVersion) forKey:FEATURE_KEY_MDL_TLS_VERSION];
            }
            
            if (configure.loadMonitorTimeInternal > 0 && configure.socketTrainingCenterConfigStr != nil
                && configure.socketTrainingCenterConfigStr.length > 0) {
                [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_SOCKET_MONITOR];
            }
            
            if (configure.enableExternDNS > 0) {
                [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_ENABLE_EXTERN_DNS];
                if ([self.eventBase.mdl_dns_type isEqualToString:kTTVideoEngineDnsTypeOwn]
                    || [self.eventBase.mdl_dns_type isEqualToString:kTTVideoEngineDnsTypeGoogle]) {
                    [self.event.mFeatures setObject:@(1) forKey:FEATURE_KEY_MDL_HTTPDNS];
                }
            }
        }
        
        int ret = [TTVideoEngine ls_getDNSParallel];
        if (ret > 0) {
            [self.event.mFeatures setObject:@(ret) forKey:FEATURE_KEY_MDL_DNS_PARALLEL_PARSE];
        }
        
        ret = [TTVideoEngine ls_getDNSRefresh];
        if (ret > 0) {
            [self.event.mFeatures setObject:@(ret) forKey:FEATURE_KEY_MDL_DNS_REFRESH];
        }
        
        if (self.eventBase.mdl_features != nil) {
            [self.event.mFeatures addEntriesFromDictionary:self.eventBase.mdl_features];
            if (self.event.mdl_loader_type == nil && self.eventBase.mdl_p2p_loader >= 0) {
                self.event.mdl_loader_type = @(self.eventBase.mdl_p2p_loader).stringValue;
            }
        }
    }
    if (_mEnableMetalViewDoubleBuffer > 0) {
        [self.event.mFeatures setObject:@(_mEnableMetalViewDoubleBuffer) forKey:FEATURE_KEY_ENABLE_METALVIEW_DOUBLE_BUFFER];
    }
    
}

- (void)sendEvent {
    if (!self.event || (self.event.pt <= 0 && self.event.ps_t <= 0)) {
        return;
    }
    if (self.event.vps <= 0 || self.event.vds <= 0) {
        [self closeVideo];
    }
    
    if (self.performancePointSwitch && _cpuUsages.count > 0) {
        self.event.cpu_use = [[_cpuUsages.copy valueForKeyPath:@"@avg.floatValue"] floatValue];
    }
    if (self.performancePointSwitch && _memUsages.count > 0) {
        self.event.mem_use = [[_memUsages.copy valueForKeyPath:@"@avg.floatValue"] floatValue];
    }
    
    self.eventBase.vid = self.vid;
    self.event.tag = self.eventBase.tag;
    self.event.subtag = self.eventBase.subtag;
    self.event.vu = self.urlArray;
    self.event.lf = self.eventBase.lastResolution;
    self.event.df = self.eventBase.currentResolution;
    self.event.lc = self.loopCount;
    if (_logVersion == TTEVENT_LOG_VERSION_NEW && self.eventOneEvent != nil) {
        self.event.bu_acu_t = [self.eventOneEvent getAccuCostTime];
    } else {
        self.event.bu_acu_t = self.accumulatedStalledTime;
        if (self.event.last_buffer_end_t < self.event.last_buffer_start_t) {
            self.event.last_buffer_end_t = 0;
            int64_t diffTime = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000) -  self.event.last_buffer_start_t;
            self.event.bu_acu_t += diffTime;
        }
    }
    self.event.sc = self.seekCount;
    self.event.api_string = self.apiString;
    
    self.stallStartTs = 0;
    self.seekStartTs = 0;
    
    self.event.apiver = self.apiver;
    self.event.auth = self.auth;
    self.event.dns_server_ip = [TTVideoEngineDNSServerIP getDNSServerIP];
    self.event.dnsMode = _dnsMode;
    self.event.width = _mWidth;
    self.event.height = _mHeight;
    self.event.playparam = [_mPlayparam copy];
    self.event.initialURL = _mInitialURL;
    self.event.enable_mdl = _mEnableMdl;
    self.event.vpls = _mVideoPreloadSize;
    self.event.video_preload_size = _mVideoPreloadSize;
    
    if (self.eventOneOutsync) {
        self.event.mAVOutsyncCount = self.eventOneOutsync.avOutsyncCount;
    }
    
    if (_leaveBlockT > 0) {
        int64_t nowT = [[NSDate date] timeIntervalSince1970] * 1000;
        self.event.leave_block_t = nowT - _leaveBlockT;
    }
    
    NSInteger duration = [[self.eventBase.videoInfo objectForKey:kTTVideoEngineVideoDurationKey] integerValue];
    if (duration > 0) {
        self.event.vd = duration;
    }
    
    if (self.delegate != nil) {
        self.event.net_client = [self.delegate getLogValueStr:LOGGER_VALUE_NET_CLIENT];
        self.event.engine_state = [self.delegate getLogValueInt:LOGGER_VALUE_ENGINE_STATE];
        if (self.event.last_seek_end_t < self.event.last_seek_start_t) {
            self.event.last_seek_end_t = 0;
        }
        if (self.event.last_resolution_end_t < self.event.last_resolution_start_t) {
            self.event.last_resolution_end_t = 0;
            NSInteger vd = [self.delegate getLogValueInt:LOGGER_VALUE_DURATION];
            if (vd > 0) {
                self.event.vd = vd;
            }
        }
        self.event.mdl_version = [self.delegate getLogValueStr:LOGGER_VALUE_MDL_VERSION];
        
        if (self.event.video_codec_profile <= 0) {
            self.event.video_codec_profile = [self.delegate getLogValueInt:LOGGER_VALUE_VIDEO_CODEC_PROFILE];
        }
        if (self.event.audio_codec_profile <= 0) {
            self.event.audio_codec_profile = [self.delegate getLogValueInt:LOGGER_VALUE_AUDIO_CODEC_PROFILE];
        }
        self.event.core_volume = [self.delegate getLogValueInt:LOGGER_VALUE_CORE_VOLUME];
        self.event.isMute = [self.delegate getLogValueInt:LOGGER_VALUE_IS_MUTE];
        self.event.network_connect_count = [self.delegate getLogValueInt:LOGGER_VALUE_GET_NETWORK_CONNECT_COUNT];
        int64_t maskDownloadSize = [self.delegate getLogValueInt64:LOGGER_VALUE_MASK_DOWNLOAD_SIZE];
        if (maskDownloadSize > 0) {
            self.event.mMaskDownloadSize = maskDownloadSize;
        }
        int64_t subtitleDownloadSize = [self.delegate getLogValueInt64:LOGGER_VALUE_SUBTITLE_DOWNLOAD_SIZE];
        if (subtitleDownloadSize > 0) {
            self.event.mSubtitleDownloadSize = subtitleDownloadSize;
        }
    }
    
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    
    NSInteger halfLen = self.retryFetchErrorInfo.count/2;
    for (int i = 0; i < halfLen; i++) {
        NSString *key = [NSString stringWithFormat:@"fetch%d",i];
        NSError *error = self.retryFetchErrorInfo[i*2];
        NSInteger apiver = [self.retryFetchErrorInfo[i*2+1] integerValue];
        [extra setObject:@{@"domain": error.domain,
                           @"code": @(error.code),
                           @"description": error.description ?: @"",
                           @"apiver": @(apiver)}
                  forKey:key];
    }
    
    for (int i = 0; i < self.firstDNSErrorInfo.count; i++) {
        NSString *key = [NSString stringWithFormat:@"ldns%d",i];
        NSError *error = self.firstDNSErrorInfo[i];
        [extra setObject:@{@"domain": error.domain,
                           @"code": @(error.code),
                           @"description": error.description ?: @""}
                  forKey:key];
    }
    
    for (int i = 0; i < self.errorInfo.count; i++) {
        NSString *key = [NSString stringWithFormat:@"error%d",i];
        NSDictionary *info = self.errorInfo[i];
        NSError *error = info[@"error"];
        NSDictionary *errorUserInfo = error.userInfo;
        NSInteger internalCode = 0;
        NSString *content = @"";
        NSString *description = error.description ?: @"";
        if (errorUserInfo) {
            internalCode = [[errorUserInfo objectForKey:kTTVideoEngineAPIRetCodeKey] integerValue];
            content = [errorUserInfo objectForKey:@"TTPlayerErrorInfoKey"] ?: @"";
        }
        [extra setObject:@{@"domain": error.domain,
                           @"code": @(error.code),
                           @"internalCode": @(internalCode),
                           @"info": content,
                           @"description": description,
                           @"strategy": info[@"strategy"] ?: @"",
                           @"apiver": info[@"apiver"] ?: @""}
                  forKey:key];
    }
    if (extra.count == 0 && self.logInfo != nil && self.logInfo.length > 0) {
        [extra setObject:self.logInfo forKey:@"playerLog"];
    }
    if (!isEmptyStringForVideoPlayer(self.mMessage)) {
        [extra setObject:self.mMessage forKey:@"log"];
    }
    self.event.ex = [extra copy];
    self.mMessage = @"";
    self.event.mMDLRetryInfo = [self.mMDLRetryInfo copy];
    
    if (self.event.br > 0) {
        self.event.br = 1;
    }
    
    NSString *vtype = [self.eventBase.videoInfo objectForKey:kTTVideoEngineVideoTypeKey];
    if (vtype.length > 0) {
        self.event.vtype = vtype;
    } else if (self.delegate) {
        NSString * filefmt = [self.delegate getLogValueStr:LOGGER_VALUE_FILE_FORMAT];
        if ([filefmt containsString:@"mp4"]) {
            self.event.vtype = @"mp4";
        } else {
            NSRange range = [filefmt rangeOfString:@","];
            NSString *filefmttem = @"";
            if (range.location == NSNotFound) {
                filefmttem = filefmt;
            } else {
                filefmttem = [filefmt substringToIndex:range.location];
            }
            if ([filefmttem containsString:@"bash"]) {
                filefmttem = @"dash";
            } else {
                filefmttem = @"";
            }
            self.event.vtype = filefmttem;
        }
    }
    self.eventBase.vtype = self.event.vtype;
    
    NSString *codec = [self.eventBase.videoInfo objectForKey:kTTVideoEngineVideoCodecKey];
    if (codec.length > 0) {
        self.event.codec = codec;
    }
    NSString *acodec = [self.eventBase.videoInfo objectForKey:kTTVideoEngineAudioCodecKey];
    if (acodec.length > 0) {
        self.event.acodec = acodec;
    }
    
    NSDictionary *sizeDict = [self.eventBase.videoInfo objectForKey:kTTVideoEngineVideoSizeKey];
    NSInteger size = [[sizeDict objectForKey:self.eventBase.currentResolution] integerValue];
    if (size > 0) {
        self.event.vs = size;
    } else if (self.delegate) {
        self.event.vs = [self.delegate getLogValueInt64:LOGGER_VALUE_FILE_SIZE];
    }
    
    if (self.event.log_id.length == 0) {
        [self parseUrlLogID];
    }
    
    [self updateFeatures];
    
    if ([self.eventPredictorSample respondsToSelector:@selector(stopRecord)]) {
        [self.eventPredictorSample stopRecord];
    }
    
    self.event.mEnableGlobalMuteFeature = [self.delegate getLogValueInt:LOGGER_VALUE_ENABLE_GLOBAL_MUTE_FEATURE];
    self.event.mGlobalMuteDic = [self.delegate getGlobalMuteDic:self];
    
    self.event.mFromEnginePool = self.mFromEnginePool;
    self.event.mPlayerHeaderInfo = self.headerInfo;
    
    NSDictionary *eventDict = [self.event jsonDict];
    if (!eventDict) {
        return;
    }
    
    //NSLog(@"shenchen vt-pt %lld",(self.event.vt - self.event.pt));
    /// TTVideoEngineLog(@"engine log info: %@",eventDict);
    
    [[TTVideoEngineEventManager sharedManager] addEvent:eventDict];
    
}

- (void)videoChangeSizeWidth:(NSInteger)width height:(NSInteger)height {
    _mWidth = width;
    _mHeight = height;
}

- (void)setSettingLogType:(TTVideoSettingLogType)logType value:(int)value{
    switch (logType) {
        case TTVideoSettingLogTypeBufferTimeOut:
            self.event.bufferTimeOut = value;
            break;
            
        default:
            break;
    }
}

- (void)setCheckHijack:(NSInteger)checkHijack {
    if (self.event) {
        self.event.check_hijack = checkHijack;
    }
}

- (void)setHijackCode:(NSInteger)hijackCode {
    if (self.event && hijackCode != -1) {
        if (self.event.first_hijack_code == LOGGER_INTEGER_EMPTY_VALUE) {
            self.event.first_hijack_code = hijackCode;
        } else {
            self.event.last_hijack_code = hijackCode;
        }
    } else if(self.event) {
        self.event.first_hijack_code = LOGGER_INTEGER_EMPTY_VALUE;
        self.event.last_hijack_code = LOGGER_INTEGER_EMPTY_VALUE;
    }
}

 - (void)setAbrInfo:(NSDictionary *)abrInfo {
     if (self.eventBase) {
         self.eventBase.abr_info = [abrInfo copy];
     }
 }

- (void)setPreloadGearInfo:(NSDictionary *)gearInfo {
    if (self.event) {
        self.event.mPreloadGear = [gearInfo copy];
    }
}

- (void)setEnableNNSR:(BOOL)enableNNSR {
    self.event.enable_nnsr = enableNNSR ? 1 : 0;
}

- (void)setSubtitleRequestFinishTime:(NSTimeInterval)time {
    self.event.sub_request_finished_time = time;//chc:
}

- (void)setSubtitleLangsCount:(NSInteger)count {
    self.event.sub_languages_count = (int)count;
}

- (void)setSubtitleEnableOptLoad:(BOOL)enableOptSubLoad {
    self.event.sub_enable_opt_load = enableOptSubLoad ? 1 : 0;
}

- (void)addSubtitleSwitchTime {
    self.event.sub_lang_switch_count += 1;
}

- (void)setSubtitleError:(NSError *_Nullable)error {
    if (error) {
        self.event.sub_error = [error ttvideoengine_getEventBasicInfo];
    }
}

- (void)setSubtitleEnable:(BOOL)enable {
    self.event.sub_enable = enable ? 1 : 0;
}

- (void)setSubtitleThreadEnable:(BOOL)enable {
    self.event.sub_thread_enable = enable ? 1 : 0;
}

- (void)setSubtitleRequestUrl:(NSString *_Nullable)urlString {
    if (urlString && urlString.length) {
        self.event.sub_req_url = urlString;
    }
}

- (void)setMaskOpenTimeStamp:(int64_t)time {
    self.event.mask_open_time = time;
}

- (void)setMaskOpenedTimeStamp:(int64_t)time {
    self.event.mask_opened_time = time;
}

- (void)setMaskErrorCode:(NSInteger)errorCode {
    self.event.mask_error_code = (int)errorCode;
}

- (void)setMaskThreadEnable:(BOOL)enable {
    self.event.mask_thread_enable = enable ? 1 : 0;
}

- (void)setMaskEnable:(BOOL)enable {
    self.event.mask_enable = enable ? 1 : 0;
}

- (void)setMaskUrl:(NSString *_Nullable)urlStr {
    if (urlStr && urlStr.length) {
        self.event.mask_url = urlStr;
    }
}

- (void)setMaskEnableMdl:(NSInteger)maskEnableMdl {
    self.event.mask_enable_mdl = maskEnableMdl;
}

- (void)setMaskFileHash:(NSString *_Nullable)maskFileHash {
    if (maskFileHash && maskFileHash.length) {
        self.event.mask_file_hash = maskFileHash;
    }
}

- (void)setMaskFileSize:(int64_t)maskFileSize {
    self.event.mask_file_size = maskFileSize;
}

- (void)setEncryptKey:(NSString *_Nullable)encryptKey {
    self.event.encrypt_key = encryptKey;
}

- (void)avOutsyncStart:(NSInteger)pts {
    // reserved: get headset info is a Time-consuming operation, will affect statistics
    _mAVOutSyncing = YES;
    if (_eventOneOutsync != nil) {
        UInt64 lastSeekTime = 0;
        UInt64 lastRebufTime = 0;
        if (_loggerState != LOGGER_STATE_SEEKING) {
            lastSeekTime = _mLastSeekT;
        }
        if (_loggerState != LOGGER_STATE_LOADING) {
            lastRebufTime = _mLastRebufT;
        }
        [_eventOneOutsync avOutsyncStart:pts vt:self.event.vt lastSeekT:lastSeekTime lastRebufT:lastRebufTime];
        [_eventOneOutsync setEnableMDL:_mEnableMdl];
    }
}

- (void)avOutsyncEnd:(NSInteger)pts {
    [self _avOutsyncEnd:pts endType:EVENT_END_TYPE_WAIT];
}

- (void)_avOutsyncEnd:(NSInteger)pts endType:(NSString*)endType {
    if (_mAVOutSyncing && _eventOneOutsync != nil) {
        NSInteger pos = pts;
        if (pos < 0 && self.delegate) {
            pos = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_PLAYBACK_TIME];
        }
        
        NSDictionary *avOutsyncEventModel = [_eventOneOutsync avOutsyncEnd:pos endType:endType];
        [self.event.avOutsyncList addEventModel:avOutsyncEventModel];
        
        _mAVOutSyncing = NO;
    }
}

- (void)noVARenderStart:(NSInteger)curPos noRenderType:(int)noRenderType {
    if (_eventOneAVRenderCheck != nil) {
        UInt64 lastSeekTime = 0;
        UInt64 lastRebufTime = 0;
        if (_loggerState != LOGGER_STATE_SEEKING) {
            lastSeekTime = _mLastSeekT;
        }
        if (_loggerState != LOGGER_STATE_LOADING) {
            lastRebufTime = _mLastRebufT;
        }
        
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        int64_t firstFrameCost = -1;
        if (self.event.vt > 0) {
            firstFrameCost = self.event.vt - self.event.pt_new;
        }
        [extraInfo setObject:@(firstFrameCost) forKey:@"first_frame_cost"];
        [extraInfo setObject:@(self.event.ps_t) forKey:@"ps_t"];
        [extraInfo setObject:@(lastSeekTime) forKey:@"seek_t"];
        [extraInfo setObject:@(self.event.vt) forKey:@"vt"];
        [extraInfo setObject:@(lastRebufTime) forKey:@"rebuf_t"];
        [_eventOneAVRenderCheck noVARenderStart:curPos noRenderType:noRenderType extraInfo:extraInfo];
        [_eventOneAVRenderCheck setEnableMDL:self.event.enable_mdl];
    }
}

- (void)noVARenderEnd:(NSInteger)curPos noRenderType:(int)noRenderType {
    [self _noVARenderEnd:curPos noRenderType:noRenderType endType:EVENT_END_TYPE_WAIT];
}

- (void)_noVARenderEnd:(NSInteger)curPos noRenderType:(int)noRenderType endType:(NSString *)endType {
    if (_eventOneAVRenderCheck != nil) {
        NSDictionary *eventModel = [_eventOneAVRenderCheck noVARenderEnd:curPos endType:endType noRenderType:&noRenderType];
        // 0 for video, 1 for audio
        if (0 == noRenderType) {
            [self.event.no_v_list addEventModel:eventModel];
        } else if (1 == noRenderType) {
            [self.event.no_a_list addEventModel:eventModel];
        }
    }
}

- (void)updateSingleNetworkSpeed:(NSDictionary *)videoInfo audioInfo:(NSDictionary *)audioInfo realInterval:(int)realInterval {
    if ([self.eventPredictorSample respondsToSelector:@selector(updateSingleNetworkSpeed:audioInfo:realInterval:)]) {
        [self.eventPredictorSample updateSingleNetworkSpeed:videoInfo audioInfo:audioInfo realInterval:realInterval];
    }
}

- (void)addFeature:(NSString *)key value:(id)value {
    [_mFeatures ttvideoengine_setObject:value forKey:key];
    TTVideoEngineLog(@"addFeature key:%@, value:%@", key, value);
}

+ (void)addFeatureGlobal:(NSString *)key value:(id)value {
    if (!sFeatures) {
        @autoreleasepool {
            sFeatures = [NSMutableDictionary dictionary];
        }
    }
    
    [sFeatures ttvideoengine_setObject:value forKey:key];
    TTVideoEngineLog(@"addFeatureGlobal key:%@, value:%@", key, value);
}

- (void)onAVInterlaced:(int64_t)diff {
    if (_eventOneEvent != nil) {
        [_eventOneEvent onAVBadInterlaced];
    }
    if (_eventOneOutsync != nil) {
        [_eventOneOutsync onAVBadInterlaced];
    }
    if (_eventOneAVRenderCheck != nil) {
        [_eventOneAVRenderCheck onAVBadInterlaced];
    }
    NSMutableDictionary *playEventModel = [NSMutableDictionary dictionary];
    [playEventModel ttvideoengine_setObject:@"-1" forKey:@"pts"];
    [playEventModel ttvideoengine_setObject:@"non" forKey:@"type"];
    [playEventModel ttvideoengine_setObject:@(diff) forKey:@"diff"];
    [self.event.bad_interlaced_list addEventModel:playEventModel];
}

- (void)logMessage:(NSString *)message {
    if (!isEmptyStringForVideoPlayer(message)) {
        NSString *str = [NSString stringWithFormat:@"%@%@", self.mMessage, message];
        self.mMessage = str;
    }
}

- (void)mdlRetryResult:(NSInteger)resultCode fileHash:(NSString *)fileHash error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (error) {
        [dict setObject:error.domain?:@"" forKey:@"domain"];
        [dict setObject:@(error.code) forKey:@"code"];
        NSDictionary<NSErrorUserInfoKey, id> *userInfo = error.userInfo;
        if (userInfo) {
            if ([userInfo objectForKey:@"description"]) {
                [dict setObject:[userInfo objectForKey:@"description"] forKey:@"description"];
            }
            if ([userInfo objectForKey:@"internalCode"] != 0) {
                [dict setObject:[userInfo objectForKey:@"internalCode"] forKey:@"internalCode"];
            }
        }
    }
    [dict setObject:@(resultCode) forKey:@"result"];
    if (fileHash) {
        [dict setObject:fileHash forKey:@"filehash"];
    }
    [self.mMDLRetryInfo addObject:[dict ttvideoengine_jsonString]];
    if (resultCode != MDL_RETRY_RESULT_ERROR) {
        _event.mExpirePlayCode = EXPIRE_PLAY_CODE_VM_RETRY;
    }
}

- (void)crosstalkHappen:(NSInteger)crosstalkCount infoList:(NSMutableArray *)infoList {
    _event.crosstalk_count = crosstalkCount;
    _event.crosstalk_info_list = infoList;
    [_eventOneEvent setValue:@(crosstalkCount) WithKey:VIDEO_ONEEVENT_KEY_CROSSTALK_COUNT];
    [_eventOneOutsync setValue:@(crosstalkCount) WithKey:VIDEO_OUTSYNC_KEY_CROSSTALK_COUNT];
    [_eventOneAVRenderCheck setValue:@(crosstalkCount) WithKey:VIDEO_AVRENDERCHECK_KEY_CROSSTALK_COUNT];
}

- (void)setPlayHeaders:(NSMutableDictionary *_Nullable) header {
    if ([header isKindOfClass:[NSDictionary class]]) {
        if ([[header objectForKey:@"cookies"] isKindOfClass:[NSString class]]) {
            _headerInfo = [NSString stringWithFormat:@"cookies:%lu", (unsigned long)[[header objectForKey:@"cookies"] length]];
        }
        
        if ([[header objectForKey:@"X-Tt-Token"] isKindOfClass:[NSString class]]) {
            if ([_headerInfo length] > 0) {
                _headerInfo = [NSString stringWithFormat:@"%@&token:%lu", _headerInfo,(unsigned long)[[header objectForKey:@"X-Tt-Token"] length]];
            } else {
                _headerInfo = [NSString stringWithFormat:@"token:%lu", (unsigned long)[[header objectForKey:@"X-Tt-Token"] length]];
            }
            
        }
    }
}

@end

