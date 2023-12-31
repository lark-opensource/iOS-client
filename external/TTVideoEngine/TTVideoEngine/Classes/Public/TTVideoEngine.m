//
//  TTVideoEngine.m
//  Pods
//
//  Created by guikunzhi on 16/12/2.
//
//
#import "TTVideoEngine.h"
static const NSString *kServerLogVersion = @"5.5";
static const NSString *kSysPlayerVersion = @"1.0";
static const NSString *kOwnPlayerVersion = @"3.0";

#define VERSION_PREFIX_LEN 5
#ifdef TTVideoEngine_POD_VERSION
static const NSString *kTTVideoEngineVersion = TTVideoEngine_POD_VERSION;
#else
static const NSString *kTTVideoEngineVersion = @"9999_1.0.0";
#endif

static const NSString *kSysPlayerCore = @"0";
static const NSUInteger kTTVideoEngineAutoModeTolerance = 3;
static void *Context_playerView_playViewBounds = &Context_playerView_playViewBounds;

NSString *kTTVideoEngineUserClickedUI = @"kTTVideoEngineUserClickedUI";

#import "TTVideoEngine+Options.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngineInfoFetcher.h"
#import "TTVideoEngineDNSParser.h"
#import "TTVideoEngineEventLogger.h"
#import "NSTimer+TTVideoEngine.h"
#import "TTVideoCacheManager.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineExtraInfo.h"
#import "NSString+TTVideoEngine.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineLogView.h"
#import "TTVideoEngineKeys.h"
#import "TTVideoEnginePerformanceCollector.h"
#import "TTVideoEngineDNS.h"
#import "TTVideoEngineModelCache.h"
#import "TTVideoEnginePlayerDefinePrivate.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEnginePreloader+Private.h"
#import "TTVideoEngine+SubTitle.h"
#import "TTVideoEngine+Mask.h"
#import "TTVideoEngine+AIBarrage.h"
#import "TTVideoEngineAVAIBarrager.h"
#import "TTVideoEngineNetwork.h"
#import "TTVideoEngine+Tracker.h"
#import "NSError+TTVideoEngine.h"
#import "TTVideoEngineSettings.h"
#import "TTVideoEngineFetcherMaker.h"
#import "TTVideoEngineStrategy.h"
#import "TTVideoEngineFragmentLoader.h"
#import "TTVideoEngineNetworkPredictorAction.h"
#import "TTVideoEngineNetworkPredictorReaction.h"
#import "TTVideoEngineActionManager.h"
#import "TTVideoEngineNetworkSpeedPredictorConfigModel.h"
#import "TTVideoEngineStartUpSelector.h"
#import "TTVideoEngine+AsyncInit.h"
#import "TTVideoEnginePlayerViewWrapper.h"
#import "TTVideoEnginePlayDuration.h"
#import "TTVideoEnginePool.h"

/// Other Pod dependency.
#import <TTPlayerSDK/ttvideodec.h>
#import <TTPlayerSDK/TTAVPlayer.h>
#import <TTPlayerSDK/TTPlayerView.h>
#import <TTPlayerSDK/TTAVPlayerOpenGLActivity.h>
#import <ABRInterface/IVCABRModule.h>
#import <ABRInterface/VCABRVideoStream.h>
#import <ABRInterface/VCABRAudioStream.h>
#import <MDLMediaDataLoader/AVMDLDataLoader.h>
#import <VCPreloadStrategy/VCVodStrategyManager.h>
#if USE_HLSPROXY
#import <PlaylistCacheModule/HLSProxyModule.h>
#endif
#if defined(__arm__) | defined(__arm64__)
#include <Metal/Metal.h>
#endif

#define ENGINE_LOG(fmt,...)\
TTVideoEngineLog(@"%@, %@", [NSString stringWithFormat:fmt, ##__VA_ARGS__], [self _engineDebugInfo])

/* max error sequeue
 1:Player Network Error;(45s timeout)
 2:force HTTP DNS error;(5s timeout)
 3:DNSCache 1st; (45s, wait player timeout)
 4:DNSCache 2nd; (45s, wait player timeout)
 5:fetchInfo (local 10s + http 5s)
 6:exit */
static const NSUInteger kTTVideoEngineMaxErrorCount = 6;
static const NSUInteger kTTVideoEngineMaxAccumulatedErrorCount = 15;
static const NSTimeInterval kPlayURLExpireTime = 40*60; // 40 min
static const NSTimeInterval kInvalidatePlayTime = -1.0f;

static ABRPredictAlgoType sPredictAlgo = ABRPredictAlgoTypeBABB;
static ABROnceAlgoType sOnceSelectAlgo = ABROnceAlgoTypeB2BModel;
static ABRFlowAlgoType sABRFlowType = ABRFlowAlgoTypeBABBFlow;

static BOOL sTestSpeedEnabled = NO;

@interface TTVideoEngine () <TTVideoEngineDNSProtocol, TTVideoPlayerStateProtocol, TTVideoEngineEventLoggerDelegate, IVCABRInfoListener, IVCABRPlayStateSupplier, TTAVPlayerSubInfoInterface, TTAVPlayerMaskInfoInterface, TTVideoEngineNetworkPredictorReaction, TTVideoEngineMDLFetcherDelegate>

@property (nonatomic, nullable, strong) id<TTVideoEngineEventLoggerProtocol> eventLogger;

@property (nonatomic,   copy) NSString *currentHostnameURL;
@property (nonatomic,   copy) NSString *currentIPURL;
@property (nonatomic, strong) NSMutableDictionary *urlIPDict;
@property (nonatomic, assign) TTVideoEngineState state;
@property (nonatomic, assign) TTVideoEngineResolutionType currentResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType lastResolution;
@property (nonatomic, strong) TTVideoEngineDNSParser *dnsParser;
@property (nonatomic, assign) BOOL isFirstURL;
@property (nonatomic, strong) NSMutableDictionary *header;
@property (nonatomic, strong) TTVideoEngineFragmentLoader *fragmentLoader;
@property (nonatomic, strong) id<TTVideoEngineNetworkPredictorAction> networkPredictorAction;

@property (nonatomic, strong) AVPlayerItem *osplayerItem;
@property (nonatomic,   copy) NSString *logInfoTag;
@property (nonatomic, assign) BOOL isOwnPlayer;
@property (nonatomic, assign) BOOL autoModeEnabled;
@property (nonatomic, copy) void(^configResolutionComplete)(BOOL success, TTVideoEngineResolutionType completeResolution);
@property (nonatomic, assign) TTVideoEngineAudioDeviceType audioDeviceType;

@property (nonatomic, assign) TTVideoEnginePlaybackState playbackState;
@property (nonatomic, assign) TTVideoEngineLoadState loadState;
@property (nonatomic, assign) TTVideoEngineStallReason stallReason;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval playableDuration;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *speedTimer;

@property (nonatomic, assign) NSUInteger errorCount;
@property (nonatomic, assign) NSUInteger accumulatedErrorCount;
@property (nonatomic, assign) NSInteger playerUrlDNSRetryCount;
@property (nonatomic, assign) NSUInteger bufferCount;
@property (nonatomic, assign) NSTimeInterval lastPlaybackTime;
@property (nonatomic, assign) BOOL isSwitchingDefinition;
@property (nonatomic, assign) BOOL isSeamlessSwitching;
@property (nonatomic, assign) BOOL isSuggestingReduceResolution;
@property (nonatomic, assign) BOOL isRetrying;
@property (nonatomic, assign) BOOL hasShownFirstFrame;
@property (nonatomic, assign) BOOL hasAudioRenderStarted;
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) BOOL isUserStopped;
@property (nonatomic, assign) BOOL isComplete;
@property (nonatomic, assign) BOOL isViewWrapperSet;
@property (nonatomic, assign) TTVideoEngineUserAction lastUserAction;
@property (nonatomic, assign) TTVideoEnginePlayAPIVersion apiVersion;
@property (nonatomic, copy) NSString *auth;
@property (nonatomic, copy) NSString *cacheFilePathWhenUsingDirectURL;
@property (nonatomic, assign) NSTimeInterval beforeSeekTimeInterval;
@property (nonatomic, copy) void(^temSeekFinishBlock)(BOOL succeed);
@property (nonatomic, copy) void(^temSeekRenderCompleteBlock)(void);
@property (nonatomic, strong) TTVideoEngineLogView *debugView;
@property (nonatomic, assign) BOOL playerIsPreparing;
@property (nonatomic, assign) BOOL didCallPrepareToPlay;
@property (nonatomic, assign) BOOL firstGetWidthHeight;
@property (nonatomic, strong) id<IVCABRModule> abrModule;
@property (nonatomic, assign) int currentDownloadAudioBitrate;
@property (nonatomic, strong) NSMutableArray *bashDefaultMDLKeys;
@property (nonatomic, assign) int64_t mdlCacheSize;
@property (nonatomic, assign) NSInteger easyPreloadThreshold;
@property (nonatomic, assign) NSTimeInterval easyPreloadNotifyTime;
@property (nonatomic, assign) BOOL didSetHardware;
@property (nonatomic, assign) BOOL didSetAESrcLoudness;
@property (nonatomic, assign) BOOL didSetAESrcPeak;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, strong) NSMutableArray *fileHashArray;
@property (nonatomic, copy) NSString *traceId;
//postprepare情况下是否在prepare完成前调用了play
@property(nonatomic, assign) BOOL needPlayBack;
//prepare完成
@property(nonatomic, assign) BOOL hasPrepared;
@property (nonatomic, assign) BOOL shouldUseAudioRenderStart;
/** initial type */
@property (nonatomic, assign) TTVideoEnginePlayerType playerType;
/** AI barrager */
@property (nonatomic, strong) TTVideoEngineAVAIBarrager *aiBarrager;

// pcdn
@property (nonatomic, strong) NSTimer *pcdnTimer;

// check preload timer
@property (nonatomic, strong) NSTimer *checkPreloadTimer;

//GearStrategy related
@property (nonatomic, nullable, strong) TTVideoEngineGearContext *gearStrategyContext;
@property (nonatomic, nullable, strong) TTVideoEnginePlayDuration *playDuration;
@end

@implementation TTVideoEngine
@synthesize enableNNSR = _enableNNSR;
@synthesize enableAllResolutionVideoSR = _enableAllResolutionVideoSR;
@synthesize enableRange = _enableRange;
@synthesize enableAVStack = _enableAVStack;
@synthesize terminalAudioUnitPool = _terminalAudioUnitPool;
@synthesize audioLatencyQueueByTime= _audioLatencyQueueByTime;
@synthesize videoEndIsAllEof = _videoEndIsAllEof;
@synthesize enableBufferingMilliSeconds = _enableBufferingMilliSeconds;
@synthesize defaultBufferingEndMilliSeconds = _defaultBufferingEndMilliSeconds;
@synthesize maxBufferEndMilliSeconds = _maxBufferEndMilliSeconds;
@synthesize decreaseVtbStackSize = _decreaseVtbStackSize;
@synthesize enable720pSR = _enable720pSR;
@synthesize enableKeepFormatThreadAlive = _enableKeepFormatThreadAlive;
@synthesize enableFFCodecerHeaacV2Compat = _enableFFCodecerHeaacV2Compat;
@synthesize hardwareDecode = _hardwareDecode;

+ (void)startOpenGLESActivity {
    [TTAVPlayerOpenGLActivity start];
}

+ (void)stopOpenGLESActivity {
    [TTAVPlayerOpenGLActivity stop];
}

+ (void)startSpeedPredictor:(NetworkPredictAlgoType)type congifModel:(TTVideoEngineNetworkSpeedPredictorConfigModel *)configModel {
    Class speedPredictorCls = NSClassFromString(@"TTVideoEngineNetworkPredictorFragment");
    if (speedPredictorCls == nil) {
        return;
    }
    SEL startSpeedPredictorSelector = @selector(startSpeedPredictor:configModel:);
    if (startSpeedPredictorSelector == nil) {
        return;
    }
    NSMethodSignature *signature = [speedPredictorCls methodSignatureForSelector:startSpeedPredictorSelector];
    if (signature == nil) {
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = speedPredictorCls;
    invocation.selector = startSpeedPredictorSelector;
    [invocation setArgument:&type atIndex:2];
    [invocation setArgument:&configModel atIndex:3];
    [invocation invoke];
    sTestSpeedEnabled = YES;
    [TTVideoEngineEventLogger setIntValueWithKey:LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_TIMEINTERVAL value:configModel.mutilSpeedInterval ? :configModel.singleSpeedInterval];
    [TTVideoEngineEventLogger setIntValueWithKey:LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_MAXSIZE value:configModel.maxWindowSize];
    [TTVideoEngineEventLogger setIntValueWithKey:LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_ENABLE_REPORT value:configModel.enableReport];
    [TTVideoEngineEventLogger setFloatValueWith:LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_SAMPLINGRATE value:configModel.samplingRate];
    [TTVideoEngineEventLogger setIntValueWithKey:LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_AlGOTYPE value:type];
}

+ (void)setLogEnabled:(BOOL)enabled {
    isTTVideoEngineLogEnabled = enabled;
}

+ (void)setLogFlag:(TTVideoEngineLogFlag)flag {
    g_TTVideoEngineLogFlag = (NSInteger)flag;
    if (flag == TTVideoEngineLogFlagNone) {
        TTVideoEngineSettings.settings.setDebug(NO);
        TTVideoEngineStrategy.helper.logLevel = VCVodStrategyLogLevelNone; ///none
    } else {
        TTVideoEngineSettings.settings.setDebug(YES);
        TTVideoEngineStrategy.helper.logLevel = VCVodStrategyLogLevelWarn; ///warn
    }
}

+ (void)setLogDelegate:(id<TTVideoEngineLogDelegate>)logDelegate {
    g_TTVideoEngineLogDelegate = logDelegate;
}

+ (void)setIgnoreAudioInterruption:(BOOL)ignore {
    isIgnoreAudioInterruption = ignore;
}

+ (void)setDNSType:(TTVideoEngineDnsType)mainDns backupDns:(TTVideoEngineDnsType)backupDns {
    if (mainDns == TTVideoEngineDnsTypeHttpAli) {
        mainDns = TTVideoEngineDnsTypeHttpTT;
    }
    if (backupDns == TTVideoEngineDnsTypeHttpAli) {
        backupDns = TTVideoEngineDnsTypeHttpTT;
    }
    TTVideoEngineLog(@"setDNSType: %@   backupDns: %@",@(mainDns),@(backupDns));
    sVideoEngineDnsTypes = @[@(mainDns),@(backupDns)];
    /// [TTVideoEngine ls_mainDNSParseType:mainDns backup:backupDns];/// MDL DNS parse
}

+ (NSArray *)getDNSType{
    if (!sVideoEngineDnsTypes) {
        sVideoEngineDnsTypes = @[@(TTVideoEngineDnsTypeLocal),@(TTVideoEngineDnsTypeLocal)];
    }
    return  sVideoEngineDnsTypes;
}

+ (void)setHTTPDNSFirst:(BOOL)isFirst {
    isVideoEngineHTTPDNSFirst = isFirst;
    TTVideoEngineLog(@"setHTTPDNSFirst : %d",isFirst);
}

+ (BOOL)getHTTPDNSFirst {
    return isVideoEngineHTTPDNSFirst;
}

+ (void)setHTTPDNSServerIP:(NSString *)serverIP {
    [TTVideoEngineDNSParser setHTTPDNSServerIP:serverIP];
}

+ (void)setQualityInfos:(NSArray *)qualityInfos {
    sVideoEngineQualityInfos = qualityInfos;
    return;
}

+ (NSArray *)getQualityInfos{
    return  sVideoEngineQualityInfos;
}

+ (BOOL)isSupportMetal {
#if defined(__arm__) | defined(__arm64__)
    if (@available(iOS 10, *)) {
        if (g_IgnoreMTLDeviceCheck){
            return YES;
        }
        static id <MTLDevice> device = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            device = MTLCreateSystemDefaultDevice();
        });
        if (device) {
            return YES;
        }
    }
    return NO;
#else
    return NO;
#endif
}

+ (void)sendCustomMessage:(NSDictionary *)message {
    if ([message objectForKey:kTTVideoEngineUserClickedUI]) {
        [TTAVPlayerOpenGLActivity checkBroken];
    }
}

+ (void)setStackSizeOptimized:(BOOL)optimized {
    [TTAVPlayer setStackSizeOptimized:optimized];
}

+ (void)configThreadWaitMilliSeconds:(int)timeout {
    [TTAVPlayer configThreadWaitMilliSeconds:timeout];
}

+ (void)configureAppInfo:(NSDictionary<NSString *,id> *)config {
    TTVideoEngineAppInfo_Dict = config.copy;
    TTVideoEngineEventUtil *sharedEventUtil = [TTVideoEngineEventUtil sharedInstance];
    if (!sharedEventUtil.appSessionId || sharedEventUtil.appSessionId.length == 0) {
        sharedEventUtil.appSessionId = [TTVideoEngineEventBase generateSessionID:TTVideoEngineAppInfo_Dict[TTVideoEngineDeviceId]];
    }
}

+ (void)configExtraInfoProtocol:(id<TTVideoEngineExtraInfoProtocol>)protocol {
    [TTVideoEngineExtraInfo configExtraInfoProtocol:protocol];
}

+ (void)setDefaultABRAlgorithm:(ABRPredictAlgoType)algoType {
    sPredictAlgo = algoType;
}

+ (void)setDefaultOnceSelectAlgoType:(ABROnceAlgoType)algoType {
    sOnceSelectAlgo = algoType;
}

+ (void)setDefaultABRFlowAlgoType:(ABRFlowAlgoType)algoType {
    sABRFlowType = algoType;
}

+ (void)setUseHttpsForApiFetch:(BOOL)useHttpsForApiFetch {
    g_FocusUseHttpsForApiFetch = useHttpsForApiFetch;
}

+ (BOOL)useHttpsForApiFetch {
    return g_FocusUseHttpsForApiFetch;
}

+ (nullable NSString *)getAppSessionID {
    TTVideoEngineEventUtil *sharedEventUtil = [TTVideoEngineEventUtil sharedInstance];
    if (!sharedEventUtil.appSessionId || sharedEventUtil.appSessionId.length == 0) {
        return nil;
    }
    return sharedEventUtil.appSessionId;
}

- (NSString *)getDubbedMemUrl:(NSArray<TTVideoEngineURLInfo *> *)infos {
    NSMutableArray <NSDictionary *> *videoList = [NSMutableArray new];
    NSMutableArray <NSDictionary *> *audioList = [NSMutableArray new];
    for (TTVideoEngineURLInfo *info in infos) {
        if (self.medialoaderEnable && [TTVideoEngine ls_isStarted] && info.fileHash.length) {
            NSMutableArray<NSString *>* urls = [[NSMutableArray alloc] init];
            if (info.mainURLStr.length)
                [urls addObject:info.mainURLStr];
            if (info.backupURL1.length)
                [urls addObject:info.backupURL1];
            else if (info.backupURL2.length)
                [urls addObject:info.backupURL2];
            else if (info.backupURL3.length)
                [urls addObject:info.backupURL3];
            NSString *proxyUrl = [self _ls_proxyUrl:info.fileHash
                                             rawKey:info.fileHash
                                               urls:[[NSArray alloc]initWithArray:urls]
                                          extraInfo:nil
                                           filePath:nil];
            if (proxyUrl.length) {
                info.mainURLStr = proxyUrl;
                info.backupURL1 = proxyUrl;
            }
        }
        NSDictionary *dict = [info videoEngineUrlInfoToDict];
        if ([info.mediaType isEqualToString:@"video"]) {
            [videoList addObject:dict];
        } else if ([info.mediaType isEqualToString:@"audio"]) {
            [audioList addObject:dict];
        }
    }
    NSDictionary *infoDic = @{
        @"dynamic_video_list" : videoList,
        @"dynamic_audio_list" : audioList
    };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDic options:0 error:&error];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"mem://bash/url_index:0/segment_format:%d/%@", TTVideoEngineDashSegmentFlagFormatFMP4, jsonStr];
}

- (instancetype)init {
    return [self initWithOwnPlayer:YES];
}

- (instancetype)initWithType:(TTVideoEnginePlayerType)type async:(BOOL)async {
    if (self = [super init]) {
        _isOwnPlayer = (type == TTVideoEnginePlayerTypeVanGuard || type == TTVideoEnginePlayerTypeRearGuard);
        _playerType = type;
        _optimizeMemoryUsage = YES;
        _renderType = TTVideoEngineRenderTypeDefault;
        _audioDeviceType = TTVideoEngineDeviceDefault;
        _lastUserAction = TTVideoEngineUserActionInit;
        _isUserStopped = NO;
        _isFirstURL = YES;
        _smoothlySwitching = NO;
        _smoothDelayedSeconds = -1;
        _playbackSpeed = 1.0;
        _autoModeEnabled = NO;
        _state = TTVideoEngineStateUnknown;
        _currentResolution = TTVideoEngineResolutionTypeSD;
        _currentQualityDesc = @"";

        _player = [[TTVideoEnginePlayer alloc] initWithType:type async:async];
        _options = [[TTVideoEngineOptions alloc] initWithPlayer:_player];
        [_options setDefaultValues];

        _player.delegate = self;
        _player.engine = (id<TTVideoPlayerEngineInfoProtocol>)self;
        if (!async) {
            _playerView = _player.view;
            _isViewWrapperSet = YES;
#ifdef DEBUG
            _debugView = [[TTVideoEngineLogView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
#endif
        }
        
        _deviceID = nil;
        _traceId = nil;
        _eventLogger = [[TTVideoEngineEventLogger alloc] init];
        _eventLogger.delegate = self;
        _maxAccumulatedErrCount = kTTVideoEngineMaxAccumulatedErrorCount;
        _errorCount = 0;
        _accumulatedErrorCount = 0;
        _playerUrlDNSRetryCount = 0;
        _bufferCount = 0;
        _isSwitchingDefinition = NO;
        _isRetrying = NO;
        _isUsingAVResolver = YES;
        _beforeSeekTimeInterval = kInvalidatePlayTime;
        _drmType = TTVideoEngineDrmNone;
        _drmDowngrade = 0;
        _drmRetry = YES;
        _cacheMaxSeconds = 30;
        _bufferingTimeOut = 30;
        _maxBufferEndTime = 4;
        _dnsCacheEnable = NO;
        _dnsExpiredTime = 0;
        _lastPlaybackTime = kInvalidatePlayTime;
        _hijackRetryEnable = YES;
        _isHijackRetried = NO;
        _hijackRetryMainDnsType = TTVideoEngineDnsTypeHttpTT;
        _hijackRetryBackupDnsType = TTVideoEngineDnsTypeLocal;
        _urlIPDict = [NSMutableDictionary dictionary];
        _header = [NSMutableDictionary dictionary];
        _audioEffectEnabled = NO;
        _aeForbidCompressor = NO;
        _audioEffectPregain = 0.25;
        _audioEffectThreshold = -18;
        _audioEffectRatio = 8;
        _audioEffectPredelay = 0.007;
        _audioEffectPostgain = 0.0;
        _audioEffectType = 0;
        _audioEffectSrcLoudness = 0.0;
        _audioEffectSrcPeak = 0.0;
        _audioEffectTarLoudness = 0.0;
        _abrTimerInterval = 500;
        _useFallbackApi = YES;
        _fallbackApiMDLRetry = NO;
        _localServerTaskKeys = [NSMutableArray array];
        _bashDefaultMDLKeys = [NSMutableArray array];
        _easyPreloadThreshold = 3;
        _dummyAudioSleep = YES;
        _isComplete = NO;
        _defaultBufferEndTime = 2;
        _usingEngineQueue = YES;
        _segmentFormatFlag = TTVideoEngineDashSegmentFlagFormatFMP4;
        _supportBarrageMask = NO;
        _disableShortSeek = NO;
        _updateTimestampMode = TTVideoEngineUpdateTimestampModeDts;
        _enableOpenTimeout = YES;
        _enableNNSR = NO;
        _nnsrFpsThreshold = 32;
        _enableAllResolutionVideoSR = NO;
        _enableRange = NO;
        _mABR4GMaxResolutionIndex = TTVideoEngineResolutionTypeUnknown;
        _enableReportAllBufferUpdate = NO;
        _enableAVStack = 0;
        _maskStopTimeout = 0;
        _terminalAudioUnitPool = NO;
        _audioLatencyQueueByTime = NO;
        _videoEndIsAllEof = NO;
        _enableBufferingMilliSeconds = NO;
        _enable720pSR = NO;
        _enableFFCodecerHeaacV2Compat = NO;
        _enableKeepFormatThreadAlive = NO;
        _playerLazySeek = YES;
        _defaultBufferingEndMilliSeconds = 1000;
        _maxBufferEndMilliSeconds = 5000;
        _decreaseVtbStackSize = 0;
        _hdr10VideoModelLowBound = -1;
        _hdr10VideoModelHighBound = -1;
        _audioCodecProfile = -1;
        _videoCodecProfile = -1;
        _audioCodecId = -1;
        _videoCodecId = -1;
        _voiceBlockDuration = 0;
        _keepVoiceDuration = NO;
        _preferSpdl4HDRUrl = NO;
        _didSetAESrcPeak = NO;
        _didSetAESrcLoudness = NO;
        _skipSetSameWindow = NO;
        _cacheVoiceId = NO;
        _maskEnableDataLoader = NO;
        _currentVideoInfo = nil;
        _dynamicAudioInfo = nil;
        _dynamicVideoInfo = nil;
        _recheckVPLSforDirectBuffering = NO;
        _enableClearMdlCache = NO;
        NSString *taskQueue = [NSString stringWithFormat:@"vcloud.engine.task.%p",self];
        _taskQueue = dispatch_queue_create(taskQueue.UTF8String,DISPATCH_QUEUE_SERIAL);

        /// Call setResolutionMap:
        self.resolutionMap = TTVideoEngineDefaultVideoResolutionMap();

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kTTVideoEngineNetWorkReachabilityChangedNotification
                                                   object:nil];
        [[TTVideoEngineNetWorkReachability shareInstance] startNotifier];
        self.fileHashArray = [NSMutableArray arrayWithCapacity:0];
        _isEnableBackGroundPlay = NO;
        _isEnablePlayCallbackHitCacheSize = NO;
        
        _fragmentLoader = [[TTVideoEngineFragmentLoader alloc] init];
        [_fragmentLoader loadFragmentWithList:@[@"NetworkPredictor", @"VR"]];
        [_fragmentLoader videoEngineDidInit:self];
        
        _shouldUseAudioRenderStart = NO;
        _medialoaderCdnType = 0;
        _mediaLoaderPcdnTimerInterval = 500;
        _pcdnTimer = nil;
        _firstGetWidthHeight = YES;
        _gearStrategyContext = nil;
        _playDuration = [[TTVideoEnginePlayDuration alloc] init];
        _engineHash = [NSString stringWithFormat:@"%lu", self.hash];
        [TTVideoEnginePool.instance startObserve:self.hash engine:self];
        [_eventLogger setIntOption:LOGGER_OPTION_ENGINEPOOL_ENGINE_HASH_CODE value:self.hash];
        _isGetFromEnginePool = NO;
        _enableGetPlayerReqOffset = 1;
        [self _registerHLSProxyProtocolHandle];
    }
    return self;
}

- (instancetype)initWithOwnPlayer:(BOOL)isOwnPlayer {
    if (isOwnPlayer) {
        return [self initWithType:TTVideoEnginePlayerTypeVanGuard];
    } else {
        return [self initWithType:TTVideoEnginePlayerTypeSystem];
    }
}

- (instancetype)initWithType:(TTVideoEnginePlayerType)type {
    return [self initWithType:type async:NO];
}

- (void)refreshEnginePara {
    _lastUserAction = TTVideoEngineUserActionInit;
    _isUserStopped = NO;
    _isFirstURL = YES;
    _autoModeEnabled = NO;
    _state = TTVideoEngineStateUnknown;
    _loadState = TTVideoEngineLoadStateUnknown;
    _playbackState = TTVideoEnginePlaybackStateStopped;
    _stallReason = TTVideoEngineStallReasonNone;
    _currentResolution = TTVideoEngineResolutionTypeSD;
    _currentQualityDesc = @"";
    _deviceID = nil;
    _traceId = nil;
    _eventLogger = [[TTVideoEngineEventLogger alloc] init];
    _eventLogger.delegate = self;
    _maxAccumulatedErrCount = kTTVideoEngineMaxAccumulatedErrorCount;
    _errorCount = 0;
    _accumulatedErrorCount = 0;
    _playerUrlDNSRetryCount = 0;
    _bufferCount = 0;
    _isSwitchingDefinition = NO;
    _isRetrying = NO;
    _beforeSeekTimeInterval = kInvalidatePlayTime;
    _lastPlaybackTime = kInvalidatePlayTime;
    _isHijackRetried = NO;
    [_urlIPDict removeAllObjects];
    [_header removeAllObjects];
    [_localServerTaskKeys removeAllObjects];
    [_bashDefaultMDLKeys removeAllObjects];
    if (_dnsParser) {
        [_dnsParser cancel];
        _dnsParser = nil;
    }
    _easyPreloadThreshold = 3;
    _isComplete = NO;
    _supportBarrageMask = NO;
    _audioCodecProfile = -1;
    _videoCodecProfile = -1;
    _audioCodecId = -1;
    _videoCodecId = -1;
    _didSetAESrcPeak = NO;
    _didSetAESrcLoudness = NO;
    _currentVideoInfo = nil;
    _dynamicAudioInfo = nil;
    _dynamicVideoInfo = nil;
    /// Call setResolutionMap:
    self.resolutionMap = TTVideoEngineDefaultVideoResolutionMap();
    [[TTVideoEngineNetWorkReachability shareInstance] startNotifier];
    [_fragmentLoader unLoadFragment];
    [_fragmentLoader loadFragmentWithList:@[@"NetworkPredictor"]];
    _shouldUseAudioRenderStart = NO;
    _pcdnTimer = nil;
    _firstGetWidthHeight = YES;
    _gearStrategyContext = nil;
    self.scaleMode = TTVideoEngineScalingModeNone;
    [self.playDuration reset];
    _currentIPURL = nil;
    _currentHostnameURL = nil;
    _playUrl = nil;
    _cacheFilePathWhenUsingDirectURL = nil;
    _lastResolution = 0;
    _osplayerItem = nil;
    _playSource = nil;
    _playerIsPreparing = NO;
    _playableDuration = 0.0;
    _didCallPrepareToPlay = NO;
    _hasPrepared = NO;
    _needPlayBack = NO;
    _httpsEnabled = NO;
    _retryEnableHttps = NO;
    _isUsedAbr = NO;
    _didSetHardware = NO;
    _serverDecodingMode = NO;
    _maskInfoDelegate = nil;
    _subtitleInfo = nil;
    _subDecInfoModel = nil;
    _checkInfoString = nil;
    _barrageMaskUrl = nil;
    _startUpParams = nil;
    _preloadDurationCheck = NO;
    [TTVideoEnginePool.instance startObserve:self.hash engine:self];
    [_player refreshPara];
    [_eventLogger setIntOption:LOGGER_OPTION_ENGINEPOOL_ENGINE_HASH_CODE value:self.hash];
    _engineCloseIsDone = NO;
    _isGetFromEnginePool = YES;
    _hasShownFirstFrame = NO;
    _hasAudioRenderStarted = NO;
    _mCompanyId = nil;
}

- (void)resetAllOptions {
    [self resetOptions];
    [_options setDefaultValues];
}

- (void)setFallbackApiMDLRetry:(BOOL)fallbackApiMDLRetry {
    _fallbackApiMDLRetry = fallbackApiMDLRetry;
    if (self.fallbackApiMDLRetry) {
        [AVMDLiOSURLFetcherBridge setFetcherMaker:TTVideoEngineFetcherMaker.instance];
    } else {
        [AVMDLiOSURLFetcherBridge setFetcherMaker:nil];
    }
}

- (void)dealloc {
    TTVIDEOENGINE_PUT_METHOD
    ENGINE_LOG(@"");
    [self.eventLogger logCurPos:[self currentPlaybackTime] * 1000];
    [self.eventLogger logWatchDuration:[self durationWatched] * 1000];
    [self.eventLogger engineState:self.state];
    if (self.netClient == nil) {
        [self.eventLogger setNetClient:@"own"];
    } else {
        [self.eventLogger setNetClient:@"user"];
    }
    [self logUrlConnectToFirstFrameTime];
    if (self.isRegistedObservePlayViewBound) {
        [self removeObserversForAbr];
        self.isRegistedObservePlayViewBound = NO;
    }
    [TTVideoEngineCopy reset];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.fragmentLoader unLoadFragment];
    _ffmpegProtocol = nil;
}

- (void)reachabilityChanged:(NSNotification *)notification {
    TTVideoEngineNetWorkStatus netStatus = [notification.userInfo[TTVideoEngineNetWorkReachabilityNotificationState] integerValue];
    self.currentNetworkStatus = netStatus;
}

#pragma mark -
#pragma mark Public

- (void)setPlayAPIVersion:(TTVideoEnginePlayAPIVersion)apiVersion auth:(NSString *)auth {
    self.apiVersion = apiVersion;
    self.auth = auth;
    [self.eventLogger setPlayAPIVersion:apiVersion auth:auth];
}

- (void)setCustomHeaderValue:(NSString *)value forKey:(NSString *)key {
    if (!key.length || !value.length) {
        return;
    }
    [self.header setValue:value forKey:key];
}

- (id<TTVideoEngineEventLoggerProtocol>)getEventLogger {
     return self.eventLogger;
}

- (NSInteger)getVideoWidth {
    return [self.player getIntValueForKey:KeyIsVideoWidth];
}

- (NSInteger)getVideoHeight {
    return [self.player getIntValueForKey:KeyIsVideoHeight];
}

- (BOOL) getStreamEnabled:(TTVideoEngineStreamType) type {
    if (type == TTVideoEngineVideoStream) {
        return [_player getIntValueForKey:KeyIsVideoTrackEnable];
    } else if (type == TTVideoEngineAudioStream) {
        return [_player getIntValueForKey:KeyIsAudioTrackEnable];
    } else {
        return NO;
    }
}

- (NSDictionary *)getMetaData {
    return [self.player metadata];
}

- (NSInteger)getVideoSRWidth {
    if(_enableNNSR) {
        return [self.player getIntValueForKey:KeyIsVideoSRWidth];
    } else {
        return -1;
    }
}

- (NSInteger)getVideoSRHeight {
    if(_enableNNSR) {
        return [self.player getIntValueForKey:KeyIsVideoSRHeight];
    } else {
        return -1;
    }
}

- (BOOL)enableNNSR {
    return [self.player getIntValueForKey:KeyIsEnableVideoSR];
}

- (void)clearScreen {
    TTVIDEOENGINE_PUT_METHOD
}

- (CVPixelBufferRef)copyPixelBuffer {
    return [self.player copyPixelBuffer];
}

- (void)setTag:(NSString *)tag {
    _logInfoTag = tag;
}

- (void)setSubtag:(NSString *)subtag {
    _subtag = subtag;
}

- (void)setCustomStr:(NSString *)customStr {
    _customStr = customStr;
    if(customStr.length > 512){
        customStr = [customStr substringToIndex:512];
        TTVideoEngineLog(@"customStr too long to be truncated!");
    }
    [self.eventLogger setCustomStr:customStr];
}

- (BOOL)isBashSource {
    return [self.playSource supportBash];
}

- (TTVideoEngineResolutionType)getStartUpAutoResolutionResult:(TTVideoEngineAutoResolutionParams *)params
                                            defaultResolution:(TTVideoEngineResolutionType)defaultResolution {
    TTVideoEngineLog(@"auto res: get manual trigger auto resolution ----------")
    
    TTVideoEngineURLInfo *info = [TTVideoEngine _getAutoResolutionInfo:params
                                                            playSource:self.playSource];
    
    if (!info) {
        TTVideoEngineLog(@"auto res: empty selected result")
        return defaultResolution;
    }
    
    return [info videoDefinitionType];
}

#pragma mark - Data Source
- (void)_needStopBeforePlayerWithPlaySource:(id<TTVideoEnginePlaySource>)other {
    BOOL temResult = (self.playSource && ![self.playSource isEqual:other]) || other == nil;
    if (temResult) {
        if (_lastUserAction != TTVideoEngineUserActionStop) {
            [self stop];
        }
        [self resetOnRefreshSource];
    }
    [self.fragmentLoader videoEngineDidReset:self];
    _isComplete = NO;
}

- (void)setVideoID:(NSString *)videoID {
    TTVideoRunOnMainQueue(^{
        if (self.playSource.videoId && [self.playSource.videoId isEqualToString:videoID]) {
            if (_state == TTVideoEngineStateUnknown ||
                _state == TTVideoEngineStateFetchingInfo ||
                _state == TTVideoEngineStateParsingDNS) {
                TTVideoEngineLog(@"did set the same vid, and just fetch url");
                [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeVid vid:videoID];
                return;
            }
        }

        TTVideoEnginePlayVidSource *temSource = [[TTVideoEnginePlayVidSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        temSource.videoId = videoID;
        [temSource setParamMap:nil];
        TTVideoEngineLog(@"set video id:%@",videoID);
        // Stop before if need
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeVid vid:videoID];
    }, YES);
}

- (void)setLiveID:(NSString *)liveID {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePlayLiveVidSource *temSource = [[TTVideoEnginePlayLiveVidSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.videoId = liveID;
        TTVideoEngineLog(@"set live id:%@",liveID);
        // Stop before if need
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        self.eventLogger.isLocal = NO;
        self.eventLogger.vid = liveID;
    }, YES);
}

- (void)setPlayItem:(TTVideoEnginePlayItem *)playItem {
    TTVideoRunOnMainQueue(^{
        BOOL isExpired = [playItem isExpired];
        if (!playItem.playURL || [playItem.playURL isEqualToString:@""] || isExpired) {
            [self setVideoID:playItem.vid];
            return;
        }
        TTVideoEnginePlayPlayItemSource *temSource = [[TTVideoEnginePlayPlayItemSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.playItem = playItem;
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        self.currentResolution = playItem.resolution;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypePlayitem vid:playItem.vid];
    }, YES);
}

- (void)setVideoInfo:(TTVideoEngineVideoInfo *)videoInfo {
    TTVideoRunOnMainQueue(^{
        BOOL isExpired = [videoInfo isExpired];
        if (self.supportExpiredModel) { /// allow expired data to trigger playback.
            isExpired = NO;
        }

        if (!videoInfo.playInfo || ![videoInfo hasPlayURL] || isExpired) {
            [self setVideoID:videoInfo.vid];
            [(TTVideoEnginePlayVidSource *)self.playSource setFallbackApi:videoInfo.playInfo.videoInfo.fallbackAPI];
            [(TTVideoEnginePlayVidSource *)self.playSource setKeyseed:videoInfo.playInfo.videoInfo.keyseed];
            return;
        }
        TTVideoEnginePlayInfoSource *temSource = [[TTVideoEnginePlayInfoSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.videoInfo = videoInfo;
        TTVideoEngineLog(@"set video info. isExpired:%@,vid:%@",isExpired ?@"YES":@"NO",videoInfo.vid);
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        self.currentResolution = videoInfo.resolution;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeFeed vid:videoInfo.vid];
        [self.eventLogger logCodecName:nil video:[videoInfo codecType]];
        [self logFetchedVideoInfo:videoInfo.playInfo.videoInfo];
        if (self.fallbackApiMDLRetry) {
            [TTVideoEngineFetcherMaker.instance storeDelegate:self];
        }
    }, YES);
}

- (void)setVideoModel:(TTVideoEngineModel *)videoModel {
    TTVideoRunOnMainQueue(^{
        BOOL isExpired = NO;
        if ([videoModel respondsToSelector:@selector(hasExpired)]) {
            isExpired = [videoModel hasExpired];
        }

        if (self.supportExpiredModel) { /// allow expired data to trigger playback.
            isExpired = NO;
        }

        if (isExpired) {
            [self setVideoID:[videoModel.videoInfo getValueStr:VALUE_VIDEO_ID]];
            [(TTVideoEnginePlayVidSource *)self.playSource setFallbackApi:videoModel.videoInfo.fallbackAPI];
            [(TTVideoEnginePlayVidSource *)self.playSource setKeyseed:videoModel.videoInfo.keyseed];
            return;
        }
        TTVideoEnginePlayModelSource *temSource = [[TTVideoEnginePlayModelSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.videoModel = videoModel;
        TTVideoEngineLog(@"set video model. isExpired:%@,vid:%@",isExpired ?@"YES":@"NO",[videoModel.videoInfo getValueStr:VALUE_VIDEO_ID]);
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        
        if (self.fallbackApiMDLRetry) {
            [TTVideoEngineFetcherMaker.instance storeDelegate:self];
        }
       
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeModel vid:[videoModel.videoInfo getValueStr:VALUE_VIDEO_ID]];
        [self.eventLogger logCodecName:nil video:[videoModel codecType]];
        [self logFetchedVideoInfo:videoModel.videoInfo];
        self.videoInfoDict = videoModel.dictInfo;
    }, YES);
}

- (void)setPreloaderItem:(TTAVPreloaderItem *)preloaderItem {
    TTVideoRunOnMainQueue(^{
        if (!preloaderItem) return;

        TTVideoEnginePlayPreloadSource *temSource = [[TTVideoEnginePlayPreloadSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.preloadItem = preloaderItem;
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        self.currentResolution = preloaderItem.resolution;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypePreloaditem vid:preloaderItem.vid];
    }, YES);
}

- (void)setLocalURL:(NSString *)url {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePlayLocalSource *temSource = [[TTVideoEnginePlayLocalSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.url = url;
        TTVideoEngineLog(@"set local url: %@",url);
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeLocalUrl vid:nil];
    }, YES);
}

- (void)setDirectPlayURL:(NSString *)url{
    [self setDirectPlayURL:url cacheFile:nil];
}

- (void)setDirectPlayURL:(NSString *)url cacheFile:(nullable NSString *)cacheFilePath {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePlayUrlSource *temSource = [[TTVideoEnginePlayUrlSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.url = url;
        TTVideoEngineLog(@"set direct url:%@",url);
        [self _needStopBeforePlayerWithPlaySource:temSource];
        self.playSource = temSource;
        self.cacheFilePathWhenUsingDirectURL = cacheFilePath;
        self.currentResolution = TTVideoEngineResolutionTypeSD;
        [self.eventLogger setSourceType:TTVideoEnginePlaySourceTypeDirectUrl vid:_playSource.videoId];
    }, YES);
}

- (void)setAVPlayerItem:(AVPlayerItem *)playerItem {
    TTVideoRunOnMainQueue(^{
        if (self.playSource ||
            (self.osplayerItem && ![self.osplayerItem isEqual:playerItem])) {
            [self _needStopBeforePlayerWithPlaySource:nil];
        }
        //
        self.osplayerItem =  playerItem;
        self.eventLogger.isLocal = YES;
    }, YES);
}

- (void)setDirectPlayURLs:(NSArray<NSString *> *)urls {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePlayUrlsSource *temSource = [[TTVideoEnginePlayUrlsSource alloc] init];
        temSource.resolutionMap = _resolutionMap;
        [temSource setParamMap:nil];
        temSource.urls = urls;
        [self _needStopBeforePlayerWithPlaySource:temSource];
        //
        self.playSource = temSource;
        self.currentResolution = TTVideoEngineResolutionTypeSD;
        self.eventLogger.isLocal = NO;
    }, YES);
}

#pragma mark Resolution
- (NSArray<NSNumber *> *)supportedResolutionTypes {
    return self.playSource.supportResolutions;
}

- (NSArray<NSString *> *)supportedQualityInfos {
    return self.playSource.supportQualityDesc;
}

- (BOOL)configResolution:(TTVideoEngineResolutionType)resolution params:(NSDictionary *)map {
    TTVideoEngineLog(@"config reolution:%@  videoId = %@, params:%@",@(resolution),self.playSource.videoId,map);
    if (self.abrSwitchMode == TTVideoEngineDashABRSwitchAuto && resolution == TTVideoEngineResolutionTypeABRAuto) {
        self.enableDashAbr = YES;
        [self.abrModule start:sABRFlowType intervalMs:0];
        return YES;
    }
    if (self.abrSwitchMode == TTVideoEngineDashABRSwitchUser && resolution == TTVideoEngineResolutionTypeABRAuto) {
        self.enableDashAbr = YES;
        return YES;
    }
    if (self.abrSwitchMode == TTVideoEngineDashABRSwitchAuto && resolution != TTVideoEngineResolutionTypeABRAuto ) {
        [self.abrModule stop];
        self.enableDashAbr = NO;
    }
    
    if (resolution == TTVideoEngineResolutionTypeAuto) {
        resolution = [self _getAutoResolution];
        [self setAutoModeEnabled:YES];
        if (self.currentResolution == resolution) {
            return YES;
        }
    }
    switch (_state) {
        case TTVideoEngineStateUnknown:
        case TTVideoEngineStateFetchingInfo: {
            TTVideoRunOnMainQueue(^{
                self.lastResolution = resolution;
                self.currentResolution = resolution;
                self.currentParams = map;
                [self.playSource setParamMap:map];
                [self.eventLogger setCurrentDefinition:[self _resolutionStringForType:self.currentResolution]
                                    lastDefinition:[self _resolutionStringForType:self.lastResolution]];
            }, YES);
            return YES;
        }
            break;
        case TTVideoEngineStatePlayerRunning:
            [self switchToDefinition:resolution params:map];
            return YES;

        default:
            break;
    }
    return NO;
}
- (void)configResolution:(TTVideoEngineResolutionType)resolution params:(NSDictionary *)map completion:(void(^)(BOOL success, TTVideoEngineResolutionType completeResolution))completion {
    ENGINE_LOG(@"");
    BOOL suitValue = ((resolution == TTVideoEngineResolutionTypeABRAuto) || resolution == TTVideoEngineResolutionTypeAuto || [self.supportedResolutionTypes containsObject:@(resolution)]);
    if (!suitValue) {
        TTVideoEngineLog(@"resolution is wrong, value = %@",@(resolution));
    }
    //
    self.configResolutionComplete = completion;
    BOOL setConfigSuccess = [self configResolution:resolution params:map];
    if (resolution == TTVideoEngineResolutionTypeAuto && setConfigSuccess) {
        [self notifyDelegateSwitchComplete:YES];
    }
    if (!setConfigSuccess) {
        [self notifyDelegateSwitchComplete:NO];
    }
}

- (BOOL)configResolution:(TTVideoEngineResolutionType)resolution {
    return [self configResolution:resolution params:nil];
}

- (void)configResolution:(TTVideoEngineResolutionType)resolution completion:(void(^)(BOOL success, TTVideoEngineResolutionType completeResolution))completion {
    ENGINE_LOG(@"");
    BOOL suitValue = ((resolution == TTVideoEngineResolutionTypeABRAuto) || resolution == TTVideoEngineResolutionTypeAuto || [self.supportedResolutionTypes containsObject:@(resolution)]);
    if (!suitValue) {
        TTVideoEngineLog(@"resolution is wrong, value = %@",@(resolution));
    }
    //
    self.configResolutionComplete = completion;
    BOOL setConfigSuccess = [self configResolution:resolution];
    if (resolution == TTVideoEngineResolutionTypeAuto && setConfigSuccess) {
        [self notifyDelegateSwitchComplete:YES];
    }
    if (!setConfigSuccess) {
        [self notifyDelegateSwitchComplete:NO];
    }
}

- (void)setGearStrategyDelegate:(id<TTVideoEngineGearStrategyDelegate>)delegate userData:(nullable id)userData {
    TTVideoEngineLog(@"[GearStrategy]setGearStrategyDelegate delegate=%p userData=%p", delegate, userData);
    if (!_gearStrategyContext) {
        _gearStrategyContext = [TTVideoEngineGearContext new];
    }
    _gearStrategyContext.gearDelegate = delegate;
    _gearStrategyContext.userData = userData;
}

- (void)setAutoModeEnabled:(BOOL)autoModeEnabled {
    _autoModeEnabled = autoModeEnabled;
    if (_autoModeEnabled) {
        //_smoothlySwitching = YES;
    }
}

- (void)setCurrentResolution:(TTVideoEngineResolutionType)currentResolution {
   CODE_ERROR(currentResolution == TTVideoEngineResolutionTypeABRAuto)
    _currentResolution = currentResolution;
}

- (void)setLastResolution:(TTVideoEngineResolutionType)lastResolution {
    CODE_ERROR(lastResolution == TTVideoEngineResolutionTypeABRAuto)
    _lastResolution = lastResolution;
}

#pragma mark Settings
- (CGFloat)volume {
    return self.player.volume;
}

- (void)setVolume:(CGFloat)volume {
    self.player.volume = volume;

    [self.eventLogger updateCustomPlayerParms:@{@"volume":@(volume)}];
}

- (void)setByteVC1Enabled:(BOOL)byteVC1Enabled {
    if (_isOwnPlayer) {
        _byteVC1Enabled = byteVC1Enabled;
        [self.eventLogger updateCustomPlayerParms:@{@"bytevc1_enabled":@(byteVC1Enabled)}];
    }
}

- (void)setCodecType:(TTVideoEngineEncodeType)codecType {
    if (_isOwnPlayer) {
        _codecType = codecType;
        [self.eventLogger updateCustomPlayerParms:@{@"codec_type":@(codecType)}];
    }
}

- (void)setHardwareDecode:(BOOL)hardwareDecode {
    _didSetHardware = YES;
    _hardwareDecode = hardwareDecode;
    self.player.hardwareDecode = hardwareDecode;
    self.settingMask |= kTTVideoEngineHardwareDecodMask;
    [self.eventLogger updateCustomPlayerParms:@{@"hardware_decode":@(hardwareDecode)}];
}

- (BOOL)hardwareDecode {
    return self.player.hardwareDecode;
}

- (void)setKsyByteVC1Decode:(BOOL)ksyByteVC1Decde {
    self.player.ksyByteVC1Decode = ksyByteVC1Decde;

    [self.eventLogger updateCustomPlayerParms:@{@"ksy_bytevc1_decde":@(ksyByteVC1Decde)}];
}

- (BOOL)ksyByteVC1Decode {
    return self.player.ksyByteVC1Decode;
}

- (BOOL)proxyServerEnable {
    return _medialoaderEnable;
}

- (void)setProxyServerEnable:(BOOL)medialoaderEnable {
    _medialoaderEnable = medialoaderEnable;

    [self.eventLogger updateCustomPlayerParms:@{@"proxy_server_enable":@(medialoaderEnable)}];
}

- (void)setMedialoaderEnable:(BOOL)medialoaderEnable {
    _medialoaderEnable = medialoaderEnable;

    [self.eventLogger updateCustomPlayerParms:@{@"proxy_server_enable":@(medialoaderEnable)}];
}

- (void)setMedialoaderNativeEnable:(BOOL)medialoaderNativeEnable {
    #if TOB_EDITION
        //feature control: native mdl
        CHECK_ADVANCE_LICENSE(YES)
    #endif
    _medialoaderNativeEnable = medialoaderNativeEnable;
    
    [self.eventLogger updateCustomPlayerParms:@{@"mdl_native_enable":@(medialoaderNativeEnable)}];
}

-(void)setMedialoaderCdnType:(NSInteger)medialoaderCdnType {
    _medialoaderCdnType = medialoaderCdnType;
    
    [self.eventLogger updateCustomPlayerParms:@{@"custom_p2p_cdn_type":@(medialoaderCdnType)}];
}

- (void)setSmoothlySwitching:(BOOL)smoothlySwitching {
    //    _smoothlySwitching = smoothlySwitching;
}

- (void)setLoopStartTime:(NSTimeInterval)loopStartTime {
    _loopStartTime = loopStartTime;
    [self.player setIntValue:self.loopStartTime forKey:KeyIsLoopStartTime];
}

- (void)setLoopEndTime:(NSTimeInterval)loopEndTime {
    _loopEndTime = loopEndTime;
    [self.player setIntValue:self.loopEndTime forKey:KeyIsLoopEndTime];
}

- (void)setOpenTimeOut:(NSInteger)openTimeOut {
    _openTimeOut = openTimeOut;
    self.settingMask |= kTTVideoEngineNetworkTimeOutMask;
    [self.eventLogger updateCustomPlayerParms:@{@"http_time_out":@(openTimeOut)}];
    self.player.openTimeOut = openTimeOut;
    [self.eventLogger setIntOption:LOGGER_OPTION_NETWORK_TIMEOUT value:openTimeOut];
}

- (void)setBoeEnable:(BOOL)boeEnable {
    _boeEnable = boeEnable;
    [self.eventLogger setEnableBoe:boeEnable?1:0];
}

- (void)setServerDecodingMode:(BOOL)serverDecodingMode {
    _serverDecodingMode = serverDecodingMode;
}

- (void)setBashEnable:(BOOL)bashEnable {
    _bashEnable = bashEnable;
}

- (void)setHlsSeamlessSwitch:(BOOL)hlsSeamlessSwitch {
    _hlsSeamlessSwitch = hlsSeamlessSwitch;
}

- (void)setBarrageMaskEnable:(BOOL)barrageMaskEnable {
    if (_barrageMaskEnable != barrageMaskEnable) {
        _barrageMaskEnable = barrageMaskEnable;
        self.player.barrageMaskEnable = barrageMaskEnable;
        [self.eventLogger setMaskEnable:barrageMaskEnable];
    }
}

- (void)setAiBarrageEnable:(BOOL)aiBarrageEnable {
    TTVideoEngineLog(@"AIBarrage: set AI Barrage switcher: %d", aiBarrageEnable);
    if (_aiBarrageEnable != aiBarrageEnable) {
        _aiBarrageEnable = aiBarrageEnable;
        self.player.aiBarrageEnable = aiBarrageEnable;
    }
}

- (void)setAiBarrageThreadEnable:(BOOL)aiBarrageThreadEnable {
    TTVideoEngineLog(@"AIBarrage: set AI Barrage thread: %d", aiBarrageThreadEnable);
    if (_aiBarrageThreadEnable != aiBarrageThreadEnable) {
        _aiBarrageThreadEnable = aiBarrageThreadEnable;
    }
}

- (void)setDnsCacheEnable:(BOOL)dnsCacheEnable {
    _dnsCacheEnable = dnsCacheEnable;
}

- (void)setLooping:(BOOL)looping {
    _looping = looping;
    self.player.looping = looping;
    [self.eventLogger setLooping:looping];
    TTVideoEngineLog(@"setLooping value:%@",looping ?@"YES":@"NO");
}

- (void)setLoopWay:(NSInteger)loopWay {
    _loopWay = loopWay;
    self.player.loopWay = loopWay;
    [self.eventLogger setLoopWay:loopWay];
}

- (void)setAsyncInit:(BOOL)isAsyncInit {
    _asyncInit = isAsyncInit;
    self.player.asyncInit = isAsyncInit;
}

- (void)setAsyncPrepare:(BOOL)isAsyncPrepare {
    _asyncPrepare = isAsyncPrepare;
    self.player.asyncPrepare = isAsyncPrepare;
}

- (void)setDecryptionKey:(NSString *)decryptionKey {
    _decryptionKey = decryptionKey;
    [self.player setValueString:decryptionKey forKey:KeyIsDecryptionKey];
}

- (void)setEncryptedDecryptionKey:(NSString *)encryptedDecryptionKey {
    _encryptedDecryptionKey = encryptedDecryptionKey;

    if (encryptedDecryptionKey && encryptedDecryptionKey.length > 0) {
        _decryptionKey = TTVideoEngineGetDescrptKey(encryptedDecryptionKey);
        [self.player setValueString:_decryptionKey forKey:KeyIsDecryptionKey];
    }else {
        _decryptionKey = nil;
        [self.player setValueString:nil forKey:KeyIsDecryptionKey];
    }
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.muted = muted;

    [self.eventLogger updateCustomPlayerParms:@{@"muted":@(muted)}];
}

- (void)setRadioMode:(BOOL)radioMode {
    NSInteger curPos = [self currentPlaybackTime] * 1000;
    [self.eventLogger userSetRadioMode:radioMode curPos:curPos];
    
    _radioMode = radioMode;
    [self.player setIntValue:radioMode forKey:KeyIsRadioMode];
    [self.eventLogger setIntOption:LOGGER_OPTION_RADIO_MODE value:(radioMode?1:0)];
}

- (void)setAudioDeviceType:(TTVideoEngineAudioDeviceType)audioDeviceType {
    _audioDeviceType = audioDeviceType;
    [self.player setIntValue:audioDeviceType forKey:KeyIsAudioDevice];
}

- (void)setEnableHookVoice:(BOOL)hook {            
    self.options.enableHookVoice = hook;
    [self.player setIntValue:hook forKey:KeyIsHijackVoiceType];
}

- (void)setSeekEndEnabled:(BOOL)seekEndEnabled {
    _seekEndEnabled = seekEndEnabled;
    [self.player setIntValue:seekEndEnabled forKey:KeyIsSeekEndEnable];
}

- (void)setPlaybackSpeed:(CGFloat)playbackSpeed {
    NSInteger curPos = [self currentPlaybackTime] * 1000;
    [self.eventLogger userSetPlaybackSpeed:playbackSpeed curPos:curPos];
    if (fabs(playbackSpeed) < 0.1) {
        return;
    }
    _playbackSpeed = playbackSpeed;
    self.player.playbackSpeed = playbackSpeed;

    [self.eventLogger updateCustomPlayerParms:@{@"speed":@(playbackSpeed)}];
}

- (void)setImageScaleType:(TTVideoEngineImageScaleType)imageScaleType {
    _imageScaleType = imageScaleType;
    self.player.imageScaleType = imageScaleType;

    [self.eventLogger updateCustomPlayerParms:@{@"image_scale_type":@(imageScaleType)}];
    [self.eventLogger setIntOption:LOGGER_OPTION_IMAGE_SCALE_TYPE value:imageScaleType];
}

- (void)setScaleMode:(TTVideoEngineScalingMode)scaleMode {
    _scaleMode = scaleMode;
    self.player.scalingMode = scaleMode;

    [self.eventLogger updateCustomPlayerParms:@{@"scale_mode":@(scaleMode)}];
}

- (void)setAlignMode:(TTVideoEngineAlignMode)alignMode {
    _alignMode = alignMode;
    self.player.alignMode = alignMode;
}

- (void)setAlignRatio:(CGFloat)alignRatio {
    _alignRatio = alignRatio;
    self.player.alignRatio = alignRatio;
}

- (void)setEnhancementType:(TTVideoEngineEnhancementType)enhancementType {
    _enhancementType = enhancementType;
    self.player.enhancementType = enhancementType;

    [self.eventLogger updateCustomPlayerParms:@{@"enhancement_type":@(enhancementType)}];
}

- (void)setImageLayoutType:(TTVideoEngineImageLayoutType)imageLayoutType {
    _imageLayoutType = imageLayoutType;
    self.player.imageLayoutType = imageLayoutType;

    [self.eventLogger updateCustomPlayerParms:@{@"imageLayout_type":@(imageLayoutType)}];
}

- (void)setTestSpeedMode:(TTVideoEngineTestSpeedMode)testSpeedMode {
    _testSpeedMode = testSpeedMode;
    [self.player setIntValue:testSpeedMode-1 forKey:KeyIsTestSpeed];
}

- (void)setRenderType:(TTVideoEngineRenderType)renderType {
    _renderType = renderType;
    self.player.renderType = renderType;

    [self.eventLogger updateCustomPlayerParms:@{@"render_type":@(renderType)}];
}

- (void)setRenderEngine:(TTVideoEngineRenderEngine)renderEngine {
    if (renderEngine == TTVideoEngineRenderEngineMetal && ![TTVideoEngine isSupportMetal]) {
        renderEngine = TTVideoEngineRenderEngineOpenGLES;
    }
    _renderEngine = renderEngine;
    self.settingMask |= kTTVideoEngineRenderEngineMask;

    self.player.renderEngine = renderEngine;

    if (renderEngine == TTVideoEngineRenderEngineOpenGLES) {
        [self.eventLogger setRenderType:kTTVideoEngineRenderTypeOpenGLES];
    } else if (renderEngine == TTVideoEngineRenderEngineMetal) {
        [self.eventLogger setRenderType:kTTVideoEngineRenderTypeMetal];
    } else if (renderEngine == TTVideoEngineRenderEngineOutput) {
        [self.eventLogger setRenderType:kTTVideoEngineRenderTypeOutput];
    }
}

- (void)setReuseSocket:(BOOL)reuseSocket {
    _reuseSocket = reuseSocket;
    self.settingMask |= kTTVideoEngineReuseSocketMask;

    [self.eventLogger setReuseSocket:reuseSocket?1:0];
}

- (void)setDisableAccurateStart:(BOOL)disableAccurateStart {
    _disableAccurateStart = disableAccurateStart;
    [self.eventLogger setDisableAccurateStart:disableAccurateStart];
}

- (void)setErrorCount:(NSUInteger)errorCount{
    _errorCount = errorCount;
}

- (void)setAccumulatedErrorCount:(NSUInteger)accumulatedErrorCount{
    _accumulatedErrorCount = accumulatedErrorCount;

}

- (void)setDrmCreater:(DrmCreater)drmCreater {
    _drmCreater = drmCreater;
    [self.player setDrmCreater:self.drmCreater];
}

- (void)setRotateType:(TTVideoEngineRotateType)rotateType {
    _rotateType = rotateType;

    [self.player setRotateType:rotateType];
}

- (UIView *)debugInfoView {
    return self.debugView;
}

- (void)setCacheMaxSeconds:(NSInteger)cacheMaxSeconds {
    _cacheMaxSeconds = cacheMaxSeconds;
    self.settingMask |= kTTVideoEngineCacheMaxSecondsMask;

    [self.eventLogger updateCustomPlayerParms:@{@"cache_max_seconds":@(cacheMaxSeconds)}];
    [self.player setIntValue:cacheMaxSeconds forKey:KeyIsSettingCacheMaxSeconds];
}

- (void)setCacheVideoInfoEnable:(BOOL)cacheVideoInfoEnable {
    _cacheVideoInfoEnable = cacheVideoInfoEnable;
    self.settingMask |= kTTVideoEngineCacheVideoModelMask;
}

- (void)setBufferingTimeOut:(NSInteger)bufferingTimeOut {
    _bufferingTimeOut = bufferingTimeOut;
    self.settingMask |= kTTVideoEngineBufferingTimeOutMask;

    [self.eventLogger updateCustomPlayerParms:@{@"buffering_time_out":@(bufferingTimeOut)}];
    [self.player setIntValue:bufferingTimeOut forKey:KeyIsBufferingTimeOut];
    [self.eventLogger setIntOption:LOGGER_OPTION_BUFFERING_TIMEOUT value:bufferingTimeOut];
}

- (void)setMaxBufferEndTime:(NSInteger)maxBufferEndTime {
    _maxBufferEndTime = maxBufferEndTime;
    [self.eventLogger updateCustomPlayerParms:@{@"max_buffer_end_time":@(maxBufferEndTime)}];
    [self.player setIntValue:maxBufferEndTime forKey:KeyIsMaxBufferEndTime];
}

- (void)setEnableTimerBarPercentage:(BOOL)enableTimerBarPercentage {
    _enableTimerBarPercentage = enableTimerBarPercentage;
    [self.player setIntValue:enableTimerBarPercentage forKey:KeyIsTimeBarPercentage];
}

- (void)setEnableDashAbr:(BOOL)enableDashAbr {
    _enableDashAbr = enableDashAbr;
    if (enableDashAbr) {
        if (!self.abrModule) {
            if (self.isRegistedObservePlayViewBound) {
                [self removeObserversForAbr];
                self.isRegistedObservePlayViewBound = NO;
            }
            if (self.mABR4GMaxResolutionIndex != TTVideoEngineResolutionTypeUnknown) {
                NSInteger bitrate = [self.playSource bitrateForDashSourceOfType:self.mABR4GMaxResolutionIndex];
                if (bitrate > 0) {
                    [VCABRConfig set4GMaxBitrate:bitrate];
                    TTVideoEngineLog(@"[ABR] set 4gmaxBitrate:%d", bitrate);
                }
            }
            Class abrCls = NSClassFromString(@"DefaultVCABRModule");
            if (abrCls == nil) {
                return;
            }
            SEL initSelector = @selector(initWithAlgoType:);
            if (initSelector == nil) {
                return;
            }
            NSMethodSignature *signature = [abrCls instanceMethodSignatureForSelector:initSelector];
            if (signature == nil) {
                return;
            }
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            self.abrModule = [abrCls alloc];
            invocation.target = self.abrModule;
            invocation.selector = initSelector;
            [invocation setArgument:&sPredictAlgo atIndex:2];
            [invocation invoke];
            [invocation getReturnValue:&_abrModule];
            
            TTVideoEngineLog(@"[ABR] set dash abr, predict algo:%d",sPredictAlgo);
            [self.abrModule setInfoListener:self];
            [self.abrModule configWithParams:self];
            [self _initSetMediaInfo];
            NSInteger viewWidth = CGRectGetWidth(self.playerView.frame) * [UIScreen mainScreen].scale;
            NSInteger viewHeight = CGRectGetHeight(self.playerView.frame) * [UIScreen mainScreen].scale;
            [self.abrModule setIntValue:viewWidth forKey:ABRKeyIsPlayerDisplayWidth];
            [self.abrModule setIntValue:viewHeight forKey:ABRKeyIsPlayerDisplayHeight];
            [self.playerView addObserver:self forKeyPath:NSStringFromSelector(@selector(bounds)) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:Context_playerView_playViewBounds];
            self.isRegistedObservePlayViewBound = YES;
            if (self.state == TTVideoEngineStatePlayerRunning) {
                [self.abrModule start:sABRFlowType intervalMs:0];
            }
        }
    }
    [self.player setIntValue:enableDashAbr forKey:KeyIsEnableDashABR];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_DASH_ABR value:enableDashAbr?1:0];
}

- (void)setResolutionMap:(NSDictionary<NSString *,NSNumber *> *)resolutionMap {
    if (!resolutionMap || resolutionMap.count == 0) {
        return;
    }

    _resolutionMap= resolutionMap;
    self.playSource.resolutionMap = resolutionMap;
}

- (void)setPerformanceLogEnable:(BOOL)performanceLogEnable {
    _performanceLogEnable = performanceLogEnable;
    _eventLogger.performancePointSwitch = performanceLogEnable;
}

- (void)setSkipFindStreamInfo:(BOOL)skipFindStreamInfo {
    _skipFindStreamInfo = skipFindStreamInfo;
    [self.player setIntValue:skipFindStreamInfo forKey:KeyIsSkipFindStreamInfo];
    [self.eventLogger setIntOption:LOGGER_OPTION_SKIP_FIND_STREAM value:skipFindStreamInfo?1:0];
}

- (void)setEnableTTHlsDrm:(BOOL)enableTTHlsDrm {
    _enableTTHlsDrm = enableTTHlsDrm;
    [self.player setIntValue:enableTTHlsDrm forKey:KeyIsTTHlsDrm];
}

- (void)setTtHlsDrmToken:(NSString *)ttHlsDrmToken {
    _ttHlsDrmToken = ttHlsDrmToken;
    [_player setValueString:ttHlsDrmToken forKey:KeyIsTTHlsDrmToken];
}

- (void)setEnableEnterBufferingDirectly:(BOOL)enableEnterBufferingDirectly {
    _enableEnterBufferingDirectly = enableEnterBufferingDirectly;
    [_player setIntValue:enableEnterBufferingDirectly forKey:KeyIsEnterBufferingDirectly];
    [self.eventLogger setIntOption:LOGGER_OPTION_BUFFERING_DIRECTLY value:enableEnterBufferingDirectly?1:0];
}

- (void)setMirrorType:(TTVideoEngineMirrorType)mirrorType {
    
    if (mirrorType == TTVideoEngineMirrorTypeNone) {
        _mirrorType = TTVideoEngineMirrorTypeNone;
    }else {
        _mirrorType = _mirrorType^mirrorType;
    }
    [self.player setIntValue:(int)mirrorType forKey:KeyIsMirrorType];

}

- (void)setOutputFramesWaitNum:(NSInteger)outputFramesWaitNum {
    _outputFramesWaitNum = outputFramesWaitNum;
    [self.player setIntValue:outputFramesWaitNum forKey:KeyIsOutputFramesWaitNum];
}

- (void)setStartPlayAudioBufferThreshold:(NSInteger)startPlayAudioBufferThreshold {
    _startPlayAudioBufferThreshold = startPlayAudioBufferThreshold;
    [self.player setIntValue:startPlayAudioBufferThreshold forKey:KeyIsStartPlayAudioBufferThreshold];
}

- (void)setAudioEffectPregain:(CGFloat)audioEffectPregain {
    _audioEffectPregain = audioEffectPregain;
    [self.player setFloatValue:audioEffectPregain forKey:KeyIsAudioEffectPregain];
}

- (void)setAudioEffectEnabled:(BOOL)audioEffectEnabled {
    _audioEffectEnabled = audioEffectEnabled;
    [self.player setIntValue:audioEffectEnabled forKey:KeyIsEnableAudioEffect];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_VOLUME_BALANCE value:audioEffectEnabled?1:0];
}

- (void)setAudioEffectThreshold:(CGFloat)audioEffectThreshold {
    _audioEffectThreshold = audioEffectThreshold;
    [self.player setFloatValue:audioEffectThreshold forKey:KeyIsAudioEffectThreshold];
}

- (void)setAudioEffectRatio:(CGFloat)audioEffectRatio {
    _audioEffectRatio = audioEffectRatio;
    [self.player setFloatValue:audioEffectRatio forKey:KeyIsAudioEffectRatio];
}

- (void)setAudioEffectType:(NSInteger)audioEffectType{
    _audioEffectType = audioEffectType;
    [self.player setIntValue:audioEffectType forKey:KeyIsAudioEffectType];
    [self.eventLogger setIntOption:LOGGER_OPTION_VOLUME_BALANCE_TYPE value:audioEffectType];
}

- (void)setAudioEffectTarLoudness:(CGFloat)audioEffectTarLoudness {
    _audioEffectTarLoudness = audioEffectTarLoudness;
    [self.player setFloatValue:audioEffectTarLoudness forKey:KeyIsAETarLufs];
}

- (void)setAudioEffectSrcLoudness:(CGFloat)audioEffectSrcLoudness {
    _didSetAESrcLoudness = YES;
    _audioEffectSrcLoudness = audioEffectSrcLoudness;
    [self.player setFloatValue:audioEffectSrcLoudness forKey:KeyIsAESrcLufs];
}

- (void)setAudioEffectSrcPeak:(CGFloat)audioEffectSrcPeak {
    _didSetAESrcPeak = YES;
    _audioEffectSrcPeak = audioEffectSrcPeak;
    [self.player setFloatValue:audioEffectSrcPeak forKey:KeyIsAESrcPeak];
}

- (void)setAudioEffectPredelay:(CGFloat)audioEffectPredelay {
    _audioEffectPredelay = audioEffectPredelay;
    [self.player setFloatValue:audioEffectPredelay forKey:KeyIsAudioEffectPredelay];
}

- (void)setAudioEffectPostgain:(CGFloat)audioEffectPostgain {
    _audioEffectPostgain = audioEffectPostgain;
    [self.player setFloatValue:audioEffectPostgain forKey:KeyIsAudioEffectPostgain];
}

- (void)setOptimizeMemoryUsage:(BOOL)optimizeMemoryUsage {
    _optimizeMemoryUsage = optimizeMemoryUsage;
    self.player.optimizeMemoryUsage = optimizeMemoryUsage;
}

- (void)setAudioUnitPoolEnabled:(BOOL)audioUnitPoolEnabled {
    _audioUnitPoolEnabled = audioUnitPoolEnabled;
    [self.player setIntValue:audioUnitPoolEnabled forKey:KeyIsUseAudioPool];
}

- (void)setAvSyncStartEnable:(BOOL)avSyncStartEnable {
    _avSyncStartEnable = avSyncStartEnable;
    [self.player setIntValue:avSyncStartEnable forKey:KeyIsAVStartSync];
}

- (void)setPlayerLazySeek:(BOOL)playerLazySeek {
    _playerLazySeek = playerLazySeek;
    [self.player setIntValue:playerLazySeek forKey:KeyIsSeekLazyInRead];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_LAZY_SEEK value:playerLazySeek?1:0];
}

- (void)setStopSourceAsync:(BOOL)stopSourceAsync {
    _stopSourceAsync = stopSourceAsync;
    [self.player setIntValue:stopSourceAsync forKey:KeyIsStopSourceAsync];
}

- (void)setEnableSeekInterrupt:(BOOL)enableSeekInterrupt {
    _enableSeekInterrupt = enableSeekInterrupt;
    [self.player setIntValue:enableSeekInterrupt forKey:KeyIsEnableSeekInterrupt];
}

- (void)setChangeVtbSizePicSizeBound:(NSInteger)changeVtbSizePicSizeBound {
    _changeVtbSizePicSizeBound = changeVtbSizePicSizeBound;
    [self.player setIntValue:changeVtbSizePicSizeBound forKey:KeyIsChangeVtbSizePicSizeBound];
}

- (void)setNormalClockType:(NSInteger)normalClockType {
    _normalClockType = normalClockType;
    [self.player setIntValue:normalClockType  forKey:KeyIsNormalClockType];
}

- (void)setCodecDropSkippedFrame:(BOOL)codecDropSkippedFrame {
    _codecDropSkippedFrame = codecDropSkippedFrame;
    [self.player setIntValue:codecDropSkippedFrame forKey:KeyIsCodecDropSikppedFrame];
}

- (void)setThreadWaitTimeMS:(NSInteger)threadWaitTimeMS {
    _threadWaitTimeMS = threadWaitTimeMS;
    [_player setIntValue:threadWaitTimeMS forKey:KeyIsThreadWaitTimeMS];
}

- (void)setDummyAudioSleep:(BOOL)dummyAudioSleep {
    _dummyAudioSleep = dummyAudioSleep;
    [_player setIntValue:dummyAudioSleep forKey:KeyIsDummyAudioSleep];
}

- (void)setDefaultBufferEndTime:(NSInteger)defaultBufferEndTime {
    _defaultBufferEndTime = defaultBufferEndTime;
    [self.player setIntValue:defaultBufferEndTime forKey:KeyIsDefaultBufferEndTime];
    [self.eventLogger setIntOption:LOGGER_OPTION_BUFFER_END_SECONDS value:defaultBufferEndTime];
}

- (void)setDecoderOutputType:(TTVideoEngineDecoderOutputType)decoderOutputType {
    _decoderOutputType = decoderOutputType;
    [self.player setIntValue:decoderOutputType forKey:KeyIsVTBOutputRGB];
}

- (void)setPrepareMaxCacheMs:(NSInteger)prepareMaxCacheMs {
    _prepareMaxCacheMs = prepareMaxCacheMs;
    [self.player setIntValue:prepareMaxCacheMs forKey:KeyIsPrepareMaxCacheMs];
}

- (void)setMdlCacheMode:(NSInteger)mdlCacheMode {
    _mdlCacheMode = mdlCacheMode;
    [self.player setIntValue:mdlCacheMode forKey:KeyIsMDLCacheMode];
}

- (void)setHttpAutoRangeOffset:(NSInteger)httpAutoRangeOffset {
    _httpAutoRangeOffset = httpAutoRangeOffset;
    [self.player setIntValue:httpAutoRangeOffset forKey:KeyIsHttpAutoRangeOffset];
}

- (void)setEnableNNSR:(BOOL)enableNNSR {
    _enableNNSR = enableNNSR;
    [_player setIntValue:enableNNSR forKey:KeyIsEnableVideoSR];
}

- (void)setNormalizeCropArea:(CGRect)normalizeCropArea {
    _normalizeCropArea = normalizeCropArea;
    [_player setNormalizeCropArea:normalizeCropArea];
}

- (void)setEffect:(NSDictionary *)effectParam {
    [_player setEffect:effectParam];
}

- (void)setNnsrFpsThreshold:(NSInteger)nnsrFpsThreshold {
    _nnsrFpsThreshold = nnsrFpsThreshold;
    [_player setIntValue:nnsrFpsThreshold forKey:KeyIsEnableVideoSRFPSThreshold];
}

- (void)setEnableAllResolutionVideoSR:(BOOL)enableAllResolutionVideoSR {
    _enableAllResolutionVideoSR = enableAllResolutionVideoSR;
    [_player setIntValue:enableAllResolutionVideoSR forKey:KeyIsEnableAllResolutionVideoSR];
}

- (void)setSkipBufferLimit:(NSInteger)skipBufferLimit {
    if (_skipBufferLimit != skipBufferLimit) {
        _skipBufferLimit = skipBufferLimit;
        [_player setIntValue:(int)skipBufferLimit forKey:KeyIsSkipBufferLimit];
    }
}

- (void)setEnableRange:(BOOL)enableRange {
    _enableRange = enableRange;
    [_player setIntValue:enableRange forKey:KeyIsEnableRange];
}

- (void)setEnableReportAllBufferUpdate:(BOOL)enableReportAllBufferUpdate {
    _enableReportAllBufferUpdate = enableReportAllBufferUpdate;
    self.player.enableReportAllBufferUpdate = enableReportAllBufferUpdate;
}

- (TTVideoEngineSeekModeType)playerSeekMode {
    return self.options.seekMode;
}

- (void)setSubtitleDelegate:(id<TTVideoEngineSubtitleDelegate>)subtitleDelegate {
    _subtitleDelegate = subtitleDelegate;
    if (subtitleDelegate) {
        [_player setSubInfo:self];
    } else {
        [_player setSubInfo:nil];
    }
}

- (void)setSubtitleHostName:(NSString *)subtitleHostName {
    _subtitleHostName = subtitleHostName;
}

- (NSArray * _Nullable)subtitleInfos {
    return self.playSource.subtitleInfos;
}

- (BOOL)hasEmbeddedSubtitle {
    return self.playSource.hasEmbeddedSubtitle;
}

- (TTVideoEngineSubInfo *)getSubtitleInfo:(NSInteger)queryTime {
    if (self.player == nil) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *content = [self.player getSubtitleContent:queryTime Params:dict];
    
    TTVideoEngineSubInfo *subInfo = [[TTVideoEngineSubInfo alloc] init];
    subInfo.content = content;
    subInfo.pts = [[dict valueForKey:@"pts"] integerValue];
    subInfo.duration = [[dict valueForKey:@"duration"] integerValue];
    
    return subInfo;
}

- (void)setSubEnable:(BOOL)subEnable {
    if (_subEnable != subEnable) {
        _subEnable = subEnable;
        self.player.subEnable = subEnable;
        [self.eventLogger setSubtitleEnable:subEnable];
        TTVideoEngineLog(@"subtitle: enable switch to: %@", subEnable ? @"on": @"off");
    }
}

- (void)setSubThreadEnable:(BOOL)subThreadEnable {
    if (_subThreadEnable != subThreadEnable) {
        _subThreadEnable = subThreadEnable;
        TTVideoEngineLog(@"subtitle: sub thread switch to: %@", subThreadEnable ? @"on": @"off");
    }
}

- (void)setSubDecInfoModel:(id<TTVideoEngineSubDecInfoProtocol>)subDecInfoModel {
    _subDecInfoModel = subDecInfoModel;
    TTVideoEngineLog(@"subtitle: subDecInfoModel set, sub count: %ld, json info: %@",
                     subDecInfoModel.subtitleCount,
                     subDecInfoModel.jsonString);
}

- (void)setCurrentSubLangId:(NSInteger)currentSubLangId {
    _currentSubLangId = currentSubLangId;
    [_player setSubLanguageId:currentSubLangId];
    [self.eventLogger addSubtitleSwitchTime];
}

- (void)switchNewSubtitleModel:(id<TTVideoEngineSubProtocol>)subModel {
    NSString *subModelStr = [subModel jsonString];
    [_player setValueString:subModelStr forKey:KeyIsAdditionSubInfo];
}

- (void)setPreferNearstSampleEnable:(BOOL)preferNearstSampleEnable {
    _preferNearstSampleEnable = preferNearstSampleEnable;
    [_player setIntValue:preferNearstSampleEnable forKey:KeyIsPreferNearestSample];
    [self.eventLogger setIntOption:LOGGER_OPTION_PREF_NEAR_SAMPLE value:preferNearstSampleEnable?1:0];
}

- (void)setPreferNearstSampleMaxPosOffset:(NSInteger)preferNearstSampleMaxPosOffset {
    _preferNearstSampleMaxPosOffset = preferNearstSampleMaxPosOffset;
    [_player setIntValue:(int)preferNearstSampleMaxPosOffset forKey:KeyIsPreferNearestMaxPosOffset];
}

- (void)setFindStreamInfoProbeSize:(NSInteger)findStreamInfoProbeSize {
    _findStreamInfoProbeSize = findStreamInfoProbeSize;
    [_player setIntValue:(int)findStreamInfoProbeSize forKey:KeyIsFindStreamInfoProbeSize];
}

- (void)setFindStreamInfoProbeDuration:(NSInteger)findStreamInfoProbeDuration {
    _findStreamInfoProbeDuration = findStreamInfoProbeDuration;
    [_player setIntValue:(int)findStreamInfoProbeDuration forKey:KeyIsFindStreamInfoProbeDuration];
}

- (void)setEnableRefreshByTime:(BOOL)enableRefreshByTime {
    _enableRefreshByTime = enableRefreshByTime;
    [_player setIntValue:(int)enableRefreshByTime forKey:KeyIsEnableRefreshByTime];
}

- (void)setLiveStartIndex:(NSInteger)liveStartIndex {
    _liveStartIndex = liveStartIndex;
    [_player setIntValue:(int)liveStartIndex forKey:KeyIsLiveStartIndex];
}

- (void)setEnableFallbackSWDecode:(BOOL)enableFallbackSWDecode {
    _enableFallbackSWDecode = enableFallbackSWDecode;
    [_player setIntValue:(int)enableFallbackSWDecode forKey:KeyIsEnableFallbackSwDec];
}

- (void)setEnableRangeCacheDuration:(BOOL)enableRangeCacheDuration {
    _enableRangeCacheDuration = enableRangeCacheDuration;
    [_player setIntValue:(int)enableRangeCacheDuration forKey:KeyIsEnableRangeCacheDuration];
}

- (void)setEnableVoiceSplitHeaacV2:(BOOL)enableVoiceSplitHeaacV2 {
    _enableVoiceSplitHeaacV2 = enableVoiceSplitHeaacV2;
    [_player setIntValue:(int)enableVoiceSplitHeaacV2 forKey:KeyIsVoiceSplitHeaacV2];
}

- (void)setEnableAudioHardwareDecode:(BOOL)enableAudioHardwareDecode {
    _enableAudioHardwareDecode = enableAudioHardwareDecode;
    [_player setIntValue:enableAudioHardwareDecode forKey:KeyIsAudioHardwareDecode];
}

- (void)setDelayBufferingUpdate:(BOOL)delayBufferingUpdate {
    _delayBufferingUpdate = delayBufferingUpdate;
    [_player setIntValue:delayBufferingUpdate forKey:KeyIsDelayBufferingUpdate];
}

- (void)setNoBufferingUpdate:(BOOL)noBufferingUpdate {
    _noBufferingUpdate = noBufferingUpdate;
    [_player setIntValue:noBufferingUpdate forKey:KeyIsNoBufferingUpdate];
}

- (void)setKeepVoiceDuration:(BOOL)keepVoiceDuration {
    _keepVoiceDuration = keepVoiceDuration;
    [_player setIntValue:keepVoiceDuration forKey:KeyIsKeepVoiceDuration];
}

- (void)setVoiceBlockDuration:(NSInteger)voiceBlockDuration {
    _voiceBlockDuration = voiceBlockDuration;
    [_player setIntValue:voiceBlockDuration forKey:KeyIsVoiceBlockDuration];
}

- (void)setSkipSetSameWindow:(BOOL)skipSetSameWindow {
    _skipSetSameWindow = skipSetSameWindow;
    [_player setIntValue:skipSetSameWindow forKey:KeyIsSkipSetSameWindow];
}

- (void)setCacheVoiceId:(BOOL)cacheVoiceId {
    _cacheVoiceId = cacheVoiceId;
    [_player setIntValue:cacheVoiceId forKey:KeyIsCacheVoiceId];
}

- (void)setEnableSRBound:(BOOL)enableSRBound {
    _enableSRBound = enableSRBound;
    [_player setIntValue:enableSRBound forKey:KeyIsEnableSRBound];
}

- (void)setSrLongDimensionLowerBound:(NSInteger)srLongDimensionLowerBound {
    _srLongDimensionLowerBound = srLongDimensionLowerBound;
    [_player setIntValue:srLongDimensionLowerBound forKey:KeyIsSRLongDimensionLowerBound];
}

- (void)setSrLongDimensionUpperBound:(NSInteger)srLongDimensionUpperBound {
    _srLongDimensionUpperBound = srLongDimensionUpperBound;
    [_player setIntValue:srLongDimensionUpperBound forKey:KeyIsSRLongDimensionUpperBound];
}

- (void)setSrShortDimensionLowerBound:(NSInteger)srShortDimensionLowerBound {
    _srShortDimensionLowerBound = srShortDimensionLowerBound;
    [_player setIntValue:srShortDimensionLowerBound forKey:KeyIsSRShortDimensionLowerBound];
}

- (void)setSrShortDimensionUpperBound:(NSInteger)srShortDimensionUpperBound {
    _srShortDimensionUpperBound = srShortDimensionUpperBound;
    [_player setIntValue:srShortDimensionUpperBound forKey:KeyIsSRShortDimensionUpperBound];
}

- (void)setFilePlayNoBuffering:(BOOL)filePlayNoBuffering {
    _filePlayNoBuffering = filePlayNoBuffering;
    [_player setIntValue:filePlayNoBuffering forKey:KeyIsFilePlayNoBuffering];
}

- (void)setEnableRemoveTaskQueue:(BOOL)enableRemoveTaskQueue {
    _enableRemoveTaskQueue = enableRemoveTaskQueue;
    self.player.enableRemoveTaskQueue = enableRemoveTaskQueue;
}

- (void)setEnablePostStart:(BOOL)enablePostStart {
    _enablePostStart = enablePostStart;
    [_player setIntValue:enablePostStart forKey:KeyIsPostStart];
}

- (void)setEnablePlayerPreloadGear:(BOOL)enablePlayerPreloadGear {
    _enablePlayerPreloadGear = enablePlayerPreloadGear;
    [_player setIntValue:enablePlayerPreloadGear forKey:KeyIsEnablePreloadGear];
}

- (NSString *)playerLog {
    if (!_playerLog) {
        _playerLog = [self.player getStringValueForKey:KeyIsPlayerLogInfo];
    }
    return _playerLog;
}

- (BOOL)shouldPlay {
    return _lastUserAction == TTVideoEngineUserActionPlay;
}

- (NSInteger)currentVideoTime {
    return [_player getInt64ValueForKey:KeyIsVideoCurrentTime];
}

- (NSInteger) videoCodecId {
    if (_videoCodecId == -1)
        _videoCodecId = [_player getIntValueForKey:KeyIsVideoCodecModName];
    return _videoCodecId;
}

- (NSInteger) audioCodecId {
    if (_audioCodecId == -1)
        _audioCodecId = [_player getIntValueForKey:KeyIsAudioCodecModName];
    return _audioCodecId;
}

- (NSInteger) audioCodecProfile {
    if (_audioCodecProfile == -1)
        _audioCodecProfile = [_player getIntValueForKey:KeyIsAudioCodecProfile];
    return _audioCodecProfile;
}

- (NSInteger) videoCodecProfile {
    if (_videoCodecProfile == -1)
        _videoCodecProfile = [_player getIntValueForKey:KeyIsVideoCodecProfile];
    return _videoCodecProfile;
}

- (BOOL) audioEffectOpened {
    return [_player getIntValueForKey:KeyIsAudioEffectEnabled];
}

- (void)setSupportPictureInPictureMode:(BOOL)supportPictureInPictureMode {
    if ([self.playerView respondsToSelector:@selector(setSupportPictureInPictureMode:)]) {
        _supportPictureInPictureMode = supportPictureInPictureMode;
        [self.playerView setValue:@(supportPictureInPictureMode) forKey:@"supportPictureInPictureMode"];
    }
}

#pragma mark - Play Control
- (void)play {
    TTVIDEOENGINE_PUT_METHOD
    ENGINE_LOG(@"");
    NSInteger curPos = [self currentPlaybackTime] * 1000;
    [self.eventLogger userPlay:curPos];
    [self.fragmentLoader videoEngineDidCallPlay:self];
    
    if (!self.playSource) {
        CODE_ERROR(NO);
        TTVideoEngineLogE(@"invalid play source. need set url or vid ...");
        return;
    }

    if (self.options.enableUIResponderLogOnPlay) {
        TTVideoEngineLog(@"Resopnder chain:\n%@", self.responderChain);
    }

    [self setIdleTimerDisabledOnMainQueue:YES];
    if (self.performanceLogEnable) {
        [TTVideoEnginePerformanceCollector addObserver:self.eventLogger];
    }
    _lastUserAction = TTVideoEngineUserActionPlay;
    _isUserStopped = NO;
    self.errorCount = 0;
    self.accumulatedErrorCount = 0;
    self.playerIsPreparing = NO;
    [self.eventLogger setStartTime:self.startTime];
    [self _logDNSMode:_isUsingAVResolver];
    
    if (TTVideoEnginePreloader.hasRegistClass) {
        [self _ls_cancelPreload:TTVideoEnginePreloadNewPlayCancel info:nil];
    }
    
    if (_isComplete) {
        [self.eventLogger setIntOption:LOGGER_OPTION_IS_REPLAY value:1];
        [self.eventLogger initPlay:_deviceID];
    }

    switch (_state) {
        case TTVideoEngineStateUnknown:
        case TTVideoEngineStateError: {
            [self _prepareToPlay:YES];
        }
            break;
        case TTVideoEngineStatePlayerRunning: {
            if (self.isEnablePostPrepareMsg && !self.hasPrepared) {
                if (self.postprepareWay == TTVideoEnginePostPrepareInEngine) {
                    self.needPlayBack = YES;
                } else if (self.postprepareWay == TTVideoEnginePostPrepareInKernal) {
                    [self.eventLogger beginToPlayVideo:self.playSource.videoId];
                    [self playVideo];
                }
            } else {
                [self.eventLogger beginToPlayVideo:self.playSource.videoId];
                if (self.playDuration && (self.isComplete ||
                     (self.playbackState == TTVideoEnginePlaybackStateStopped && self.startPlayTimestamp == 0))) {
                    [self.playDuration clear];
                }
                [self playVideo];
            }
        }
            break;
        case TTVideoEngineStateFetchingInfo: {
            [_playSource cancelFetch];
            _state = TTVideoEngineStateUnknown;
            [self _prepareToPlay:YES];
        }
            break;
        default:
            break;
    }
    _isComplete = NO;
}

- (void)stop {
    TTVIDEOENGINE_PUT_METHOD
    ENGINE_LOG(@"");
    _lastUserAction = TTVideoEngineUserActionStop;
//    NSLog(@"stop nnsr width. %@",[self getOptionBykey:VEKKEY(VEKGetKeyPlayerVideoSRWidth_NSInteger)]);
//    NSLog(@"stop nnsr height. %@",[self getOptionBykey:VEKKEY(VEKGetKeyPlayerVideoSRHeight_NSInteger)]);
//    NSLog(@"stop nnsr set. %@",[self getOptionBykey:VEKKEY(VEKKeyPlayerEnableNNSR_BOOL)]);
//
    CGFloat averageDownLoadSpeed = 0.0;
    CGFloat averagePredictSpeed = 0.0;
    Class networkPredictClassAction = [self networkPredictorActionClass];
    if ([networkPredictClassAction respondsToSelector:@selector(getAverageDownLoadSpeed)]) {
        averageDownLoadSpeed = [networkPredictClassAction getAverageDownLoadSpeed];
    }
    if ([networkPredictClassAction respondsToSelector:@selector(getAveragePredictSpeed)]) {
        averagePredictSpeed = [networkPredictClassAction getAveragePredictSpeed];
    }
    [self.eventLogger setTag:self.logInfoTag];
    [self.eventLogger setSubtag:self.subtag];
    [self.eventLogger setHijackCode:self.hijackCode];
    [self.eventLogger setAbrInfo:@{@"abr_probe_count": @(self.abrProbeCount),
                                   @"abr_switch_count": @(self.abrSwitchCount),
                                   @"abr_average_bitrate": @(self.abrAverageBitrate),
                                   @"abr_average_play_speed": @(self.abrAveragePlaySpeed),
                                   @"abr_used": @(self.isUsedAbr),
                                   @"abr_avg_download" : @(averageDownLoadSpeed),
                                   @"abr_avg_predict" : @(averagePredictSpeed),
                                   @"abr_avg_diff_abs" : @(self.abrDiddAbs)
    }];

    switch (_state) {
        case TTVideoEngineStateUnknown:
            _isUserStopped = YES;
            break;
        case TTVideoEngineStateFetchingInfo:
            _isUserStopped = YES;
            [self.playSource cancelFetch];
            self.state = TTVideoEngineStateUnknown;
            break;
        case TTVideoEngineStateParsingDNS:
            _isUserStopped = YES;
            [self.dnsParser cancel];
            self.state = TTVideoEngineStateUnknown;
            break;
        case TTVideoEngineStatePlayerRunning:
            _isUserStopped = YES;
            self.state = TTVideoEngineStateUnknown;
            break;
        case TTVideoEngineStateError:
            return;

        default:
            break;
    }
    [self stopVideo];
    [self _userWillLeave];
    [self.fileHashArray removeAllObjects];
}

-(void)closeAysnc {
    TTVIDEOENGINE_PUT_METHOD
    if(!self.isOwnPlayer){
        [self _close:NO];
        return;
    }

    [self _close:YES];
}

- (void)close {
    TTVIDEOENGINE_PUT_METHOD
    [self _close:NO];
}

- (void)_close:(BOOL)async {
    ENGINE_LOG(@"async = %@",async ? @"YES" : @"NO");
    if (self.playSource && self.fallbackApiMDLRetry) {
        [TTVideoEngineFetcherMaker.instance removeDelegate:self];
    }
    
    if (self.lastUserAction == TTVideoEngineUserActionClose) {
        return;
    }
    ENGINE_LOG(@"close called, async = %@",async ? @"YES" : @"NO");
    TTVideoEngineFinishReason finishReason = async ? TTVideoEngineFinishReasondReleaseAsync : TTVideoEngineFinishReasonRelease;
    self.lastUserAction = TTVideoEngineUserActionClose;
    if (self.playDuration) {
        [self.playDuration stop];
    }
    [self _buryDataWhenUserWillLeave];
    [self _buryDataWhenSendOneplayEvent];
    [self.eventLogger closeVideo];
    [self.eventLogger playbackFinish:finishReason];
    [self.playSource cancelFetch];
    if (async) {
        if (self.enableRemoveTaskQueue) {
            //for remove taskQueue AB Test
            [self.abrModule stop];
            [self.player closeAsync];
            if (self.optimizeMemoryUsage) {
                [(TTPlayerView *)self.playerView releaseContents];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineCloseAysncFinish:)]) {
                [self.delegate videoEngineCloseAysncFinish:self];
            }
            self.engineCloseIsDone = YES;
        } else {
            __strong id engineDelegate = self.delegate;
            dispatch_async([self usingSerialTaskQueue], ^{
                [self.abrModule stop];
                [self.player close];
                TTVideoRunOnMainQueue(^{
                    if (self.optimizeMemoryUsage) {
                        [(TTPlayerView *)self.playerView releaseContents];
                    }

                    if (engineDelegate && [engineDelegate respondsToSelector:@selector(videoEngineCloseAysncFinish:)]) {
                        [engineDelegate videoEngineCloseAysncFinish:self];
                    }
                    
                    if (self.isGetFromEnginePool) {
                        [TTVideoEnginePool.instance engineAsyncCloseDone:self];
                    }
                }, NO);
            });
        }
    } else {
        [self.player close];
        self.engineCloseIsDone = YES;
    }
    [self _userWillLeave];
}

- (void)pause:(BOOL)async {
    TTVIDEOENGINE_PUT_METHOD
    ENGINE_LOG(@"async = %@",async ? @"YES" : @"NO");
    NSInteger curPos = [self currentPlaybackTime] * 1000;
    [self.eventLogger userPause:curPos];
    
    if (_lastUserAction == TTVideoEngineUserActionPause) {
        return;
    }
    [self setIdleTimerDisabledOnMainQueue:NO];
    ENGINE_LOG(@"pause called, async = %@",async ? @"YES" : @"NO");
    _lastUserAction = TTVideoEngineUserActionPause;
    if (self.playDuration) {
        [self.playDuration stop];
    }
    if (![TTAVPlayerOpenGLActivity isActive]) {
        [self syncPauseVideo];
    } else {
        [self pauseVideo:async];
    }
}

- (void)pause {
    TTVIDEOENGINE_PUT_METHOD
    [self pause:NO];
}

- (void)pauseAsync {
    TTVIDEOENGINE_PUT_METHOD
    ENGINE_LOG(@"");
    NSInteger curPos = [self currentPlaybackTime] * 1000;
    [self.eventLogger userPause:curPos];
    
    if (_lastUserAction == TTVideoEngineUserActionPause) {
        return;
    }
    [self setIdleTimerDisabledOnMainQueue:NO];
   ENGINE_LOG(@"pause called");
    _lastUserAction = TTVideoEngineUserActionPause;
    if (self.playDuration) {
        [self.playDuration stop];
    }
    if (self.enableRemoveTaskQueue) {
        //for remove taskQueue AB Test
        if (![TTAVPlayerOpenGLActivity isActive]) {
            [self syncPauseVideo];
        } else {
            [self pauseVideo:YES];
        }
    } else {
        dispatch_async([self usingSerialTaskQueue], ^{
            [self.player pause];
        });
    }
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime complete:(void(^)(BOOL success))finised {
    [self seekToTime:currentPlaybackTime switchingResolution:NO complete:finised renderComplete:nil];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
                      complete:(void(^)(BOOL success))finised
                renderComplete:(void(^)(void)) renderComplete {
    [self seekToTime:currentPlaybackTime switchingResolution:NO complete:finised renderComplete:renderComplete];
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)())block {
    TTVideoRunOnMainQueue(^{
        if (self.timer && [self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = [NSTimer ttvideoengine_scheduledTimerWithTimeInterval:interval queue:queue block:block repeats:YES];
    }, NO);
}

- (void)removeTimeObserver {
    TTVideoRunOnMainQueue(^{
        if (self.timer && [self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = nil;
    }, NO);
}

- (void)addSpeedTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(long long speed))block {
    TTVideoRunOnMainQueue(^{
        if (self.speedTimer && [self.speedTimer isValid]) {
            [self.speedTimer invalidate];
        }
        @weakify(self)
        void (^speedBlock)(void) = ^(){
            @strongify(self);
            if (!self) {
                return;
            }

            long long downLoadSpeed = [self.player downloadSpeed];
            if(block != nil) {
                block(downLoadSpeed);
            }
        };
        self.speedTimer = [NSTimer ttvideoengine_scheduledTimerWithTimeInterval:interval queue:queue block:speedBlock repeats:YES];
    }, NO);
}

- (void)removeSpeedTimeObserver {
    TTVideoRunOnMainQueue(^{
        if (self.speedTimer && [self.speedTimer isValid]) {
            [self.speedTimer invalidate];
        }
        self.speedTimer = nil;
    }, NO);
}

#pragma mark - Inspector
- (NSTimeInterval)currentPlaybackTime {
    if (_isSwitchingDefinition && fabs(self.lastPlaybackTime - kInvalidatePlayTime) > 0.0001) {/// switch definition
        if (self.beforeSeekTimeInterval > kInvalidatePlayTime) {/// did seek
            return self.beforeSeekTimeInterval;
        }
        //TODO: need return player.currentPlaybackTime
        return self.lastPlaybackTime;
    }
    return self.player.currentPlaybackTime;
}

- (NSTimeInterval)duration {
    return self.player.duration;
}

- (long long)bitrate {
    return [self.player getInt64ValueForKey:KeyIsMediaBitrate];
}

- (long long)audioBitrate {
    return [self.player getInt64ValueForKey:KeyIsAudioBitrate];
}

- (long long)videoAreaFrame {
    return [self.player getInt64ValueForKey:KeyIsVideoAreaFramePattern];
}

- (CGFloat)videoOutputFPS {
    return [self.player getFloatValueForKey:KeyIsVideoOutFPS];
}

- (CGFloat)containerFPS {
    return [self.player getIntValueForKey:KeyIsContainerFPS];
}

- (int64_t)playBytes {
    return (int64_t)[self.player numberOfBytesPlayed];
}

- (NSTimeInterval)durationWatched {
    NSTimeInterval watched = 0.0;
    if (self.playDuration) {
        watched = [self.playDuration getPlayedDuration];
    }
    return watched;
}

- (NSTimeInterval)playableDuration {
    if (_playableDuration > 0.0) {
        return _playableDuration;
    }
    //
    return self.player.playableDuration;
}

- (NSInteger)videoSize {
    return [self.playSource videoSizeOfType:self.currentResolution];
}

- (NSInteger)qualityType {
    if (!self.playSource)
        return 0;
    TTVideoEngineURLInfo *infoVideo = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
    if (!infoVideo)
        return 0;
    return [infoVideo getValueInt:VALUE_QUALITY_TYPE];
}

- (long long)mediaSize {
    if (self.isOwnPlayer) {
        return self.player.mediaSize;
    }
    return -1;
}

- (NSInteger)hijackCode {
    if (self.state == TTVideoEngineStatePlayerRunning) {
        return [self.player getIntValueForKey:KeyIsHijackCode];
    }
    return -1;
}

- (NSInteger)abrProbeCount {
    return [self.player getIntValueForKey:KeyIsABRProbeCount];
}

- (NSInteger)abrSwitchCount {
    return [self.player getIntValueForKey:KeyIsABRSwitchCount];
}

- (NSInteger)abrAverageBitrate {
    return [self.player getIntValueForKey:KeyIsABRAverageBitrate];
}

- (CGFloat)abrAveragePlaySpeed {
    return [self.player getFloatValueForKey:KeyIsABRAveragePlaySpeed];
}

- (NSInteger)abrDiddAbs {
    return [self.player getIntValueForKey:KeyIsABRAverageBitrateDiff];
}

- (TTVideoEngineAVPlayerItemAccessLog *)accessLog {
    return self.player.accessLog;
}

#pragma mark - Private
- (void)setIdleTimerDisabledOnMainQueue:(BOOL)disabled {
    if (_idleTimerAutoMode > 0) {
        if (TTVideoIsMainQueue()) {
            TTVideoEngineGetApplication().idleTimerDisabled = disabled;
        }
    }
}

- (void)resetOnRefreshSource {
    _state = TTVideoEngineStateUnknown;
    _loadState = TTVideoEngineLoadStateUnknown;
    _playbackState = TTVideoEnginePlaybackStateStopped;
    _stallReason = TTVideoEngineStallReasonNone;
    _lastPlaybackTime = kInvalidatePlayTime;
    _isUserStopped = NO;
    _isFirstURL = YES;
    [self.playDuration reset];
    [self.header removeAllObjects];
    [self.urlIPDict removeAllObjects];
    [_dnsParser cancel];
    _dnsParser = nil;
    self.eventLogger.loopCount = 0;
    [self.eventLogger setURLArray:nil];
    _currentIPURL = nil;
    _currentHostnameURL = nil;
    _currentQualityDesc = nil;
    _playUrl = nil;
    self.beforeSeekTimeInterval = kInvalidatePlayTime;
    _cacheFilePathWhenUsingDirectURL = nil;
    _lastResolution = 0;
    _osplayerItem = nil;
    _playSource = nil;
    _playerIsPreparing = NO;
    _playableDuration = 0.0;
    _didCallPrepareToPlay = NO;
    _hasPrepared = NO;
    _needPlayBack = NO;
    _errorCount = 0;
    _playerUrlDNSRetryCount = 0;
    _accumulatedErrorCount = 0;
    _isRetrying = NO;
    _httpsEnabled = NO;
    _retryEnableHttps = NO;
    _isHijackRetried = NO;
    _isUsedAbr = NO;
    _didSetHardware = NO;
    _serverDecodingMode = NO;
    _maskInfoDelegate = nil;
    _subtitleInfo = nil;
    _audioCodecId = -1;
    _videoCodecId = -1;
    _videoCodecProfile = -1;
    _audioCodecProfile = -1;
    _didSetAESrcPeak = NO;
    _didSetAESrcLoudness = NO;
    _currentVideoInfo = nil;
    _dynamicAudioInfo = nil;
    _dynamicVideoInfo = nil;
    _subDecInfoModel = nil;
    _checkInfoString = nil;
    _barrageMaskUrl = nil;
    _startUpParams = nil;
    _preloadDurationCheck = NO;
    _firstGetWidthHeight = YES;
    [self.eventLogger finishReason:TTVideoEngineFinishReasonReset];
    if (self.fallbackApiMDLRetry) {
        [TTVideoEngineFetcherMaker.instance removeDelegate:self];
    }
}

- (void)setState:(TTVideoEngineState)state {
    TTVideoRunOnMainQueue(^{
        _state = state;
    }, YES);
}

- (void)_prepareToPlay:(BOOL)byPlay {
    {
        if (self.playDuration) {
            [self.playDuration clear];
        }
        //event logger things
        if (byPlay) {
            [self.eventLogger beginToPlayVideo:self.playSource.videoId];
        }
        if (_deviceID == nil) {
            NSString *deviceId = nil;
            if (_dataSource && [_dataSource respondsToSelector:@selector(appInfo)]) {
                NSDictionary *appInfo = [_dataSource appInfo].copy;
                if (appInfo && appInfo.count > 0) {
                    deviceId = appInfo[TTVideoEngineDeviceId];
                    TTVideoEngineLog(@"generate get appInfo. deviceId = %@",deviceId);
                }
            }
            if (deviceId == nil && TTVideoEngineAppInfo_Dict.count > 0) {
                deviceId = TTVideoEngineAppInfo_Dict[TTVideoEngineDeviceId];
            }
            _deviceID = [deviceId copy];
        }
        [self.eventLogger initPlay:_deviceID];
        
        int64_t curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        [self.eventLogger setInt64Option:LOGGER_OPTION_TIME_PS_T value:curT];

        self.startPlayTimestamp = curT;
        [self.eventLogger setTag:self.logInfoTag];
        [self.eventLogger setSubtag:self.subtag];
        [self.eventLogger setCustomStr:self.customStr];
        if (self.mCompanyId && self.mCompanyId.length > 0) {
            [self.eventLogger setStringOption:LOGGER_OPTION_CUSTOM_COMPANY_ID value:self.mCompanyId];
        }
    }
    
    if (!_medialoaderEnable) {
        [self _createCacheFileDirAndDeleteInvalidDataIfNeed];
    }

    if (self.osplayerItem) {// os play item
        [self playVideo];
    }else if (self.playSource.preloadDataIsExpire) { // preload data is expire
        [self fetchVideoInfo];
    } else if([self.playSource urlForResolution:self.currentResolution]){ // Has url.
        [self _startToPlay];
    } else {
        [self fetchVideoInfo]; // video-id
    }
    //
}

- (void)prepareToPlay {
    TTVIDEOENGINE_PUT_METHOD
    TTVideoEngineLog(@"did call prepareToPlay, state = %zd",self.state);
    _lastUserAction = TTVideoEngineUserActionPrepare;
    _isUserStopped = NO;
    self.errorCount = 0;
    _isComplete = NO;

    BOOL playerShouldPrepare = (self.state == TTVideoEngineStateUnknown || self.state == TTVideoEngineStateError);
    if (playerShouldPrepare || !self.playerIsPreparing) {
        self.playerIsPreparing = YES;
        [self.eventLogger prepareBeforePlay];
        if (_enableRange && _mdlCacheMode > TTVideoMDLReadModeNormal) {
            [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_AUTO_RANGE value:1];
        }
        [self _prepareToPlay:NO];
    }
}

- (void)_fetchVideoInfo {
    //
    CODE_ERROR(self.playSource.canFetch == NO)
    if (!self.playSource.canFetch) {
        TTVideoEngineLog(@"invalid playSource");
    }
    // fetch data
    self.playSource.netClient = self.netClient;
    self.playSource.cacheVideoModelEnable = self.cacheVideoInfoEnable;
    self.playSource.useFallbackApi = self.useFallbackApi;
    self.playSource.useEphemeralSession = self.useEphemeralSession;
    // Setting configure
    //
    // ⚠️ Pay attention to memory leaks.
    // ⚠️ Do not use underlined variables.like _playSource;
    @weakify(self)
    [self.playSource fetchUrlWithApiString:^NSString *(NSString * _Nonnull vid) {
        @strongify(self)
        NSString *apiString = nil;
        // ⚠️ Use self.dataSource rather than _dataSource.
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(apiForFetcher:)]) {
            apiString = [self.dataSource apiForFetcher:self.apiVersion];
        } else if (self.dataSource && [self.dataSource respondsToSelector:@selector(apiForFetcher)]) {
            apiString = [self.dataSource apiForFetcher];
        }
        if(self.boeEnable){
             apiString = TTVideoEngineBuildBoeUrl(apiString);
        }
        apiString = TTVideoEngineBuildHttpsApi(apiString);
        return apiString;
    } auth:^NSString *(NSString * _Nonnull vid) {
        @strongify(self)
        // ⚠️ Use self.auth rather than _auth.
        return self.apiVersion == TTVideoEnginePlayAPIVersion2 ? nil : self.auth;
    } params:^NSDictionary *(NSString * _Nonnull vid) {
        @strongify(self)
        if (self.enableHttps || self.retryEnableHttps) {
            self.httpsEnabled = YES;
        }
        // ⚠️ Use self.byteVC1Enabled rather than _byteVC1Enabled.
        TTVideoEngineEncodeType codecType = self.codecType < TTVideoEngineByteVC1 && self.byteVC1Enabled ? TTVideoEngineByteVC1 : self.codecType;
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"codec_type": [NSString stringWithFormat:@"%ld", codecType],
                                                                                      @"player_version": [self.player getVersion],
                                                                                      @"format_type": self.dashEnabled ? @"dash":@"mp4",
                                                                                      @"ssl": self.httpsEnabled ? @"1":@"0",
                                                                                      @"projectTag":self.logInfoTag ?:@"tag" ,
                                                                                      }];
        if (self.playSource.isLivePlayback) {
            [params setObject:@"3" forKey:@"play_type"];
        }
        return params.copy;
    } apiVersion:^NSInteger(NSString * _Nonnull vid) {
        @strongify(self)
        // ⚠️ Use self.apiVersion rather than _apiVersion.
        return self.apiVersion;
    } result:^(BOOL canFetch, TTVideoEngineModel *videoModel, NSError * _Nullable error) {
        @strongify(self)
        // ⚠️ Use self.delegate rather than _delegate.
        if (error) {
            NSDictionary *userInfo = error.userInfo;
            if (userInfo[@"log_id"]) {
                [self.eventLogger setStringOption:LOGGER_OPTION_LOG_ID value:userInfo[@"log_id"]];
            }
            if (userInfo[TTVideoEnginePlaySourceErrorRetryKey]) { // Retry
                [self.eventLogger needRetryToFetchVideoURL:error apiVersion:self.apiVersion];
            }else if (userInfo[TTVideoEnginePlaySourceErrorUserCancelKey]) {// User cancel
                [self logUserCancelled];
            }else if (userInfo[TTVideoEnginePlaySourceErrorStatusKey]) { // Error status
                NSInteger status = [userInfo[TTVideoEnginePlaySourceErrorStatusKey] integerValue];
                [self.eventLogger videoStatusException:status];
                self.playerIsPreparing = NO;
                self.didCallPrepareToPlay = NO;
                self.hasPrepared = NO;
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineDidFinish:videoStatusException:)]) {
                    [self.delegate videoEngineDidFinish:self videoStatusException:status];
                }
            } else if (userInfo[TTVideoEnginePlaySourceErrorDNSKey]) { // DNS error
                [self.eventLogger needRetryToFetchVideoURL:error apiVersion:self.apiVersion];
                [self didReceiveError:error];
            } else { // Fetch Error
                [self logFetchInfoError:error];
                [self didReceiveError:error];
            }
        } else {
            if (self.isUserStopped) {
                self.state = TTVideoEngineStateUnknown;
                return;
            }
            //
            [self logFetchedVideoInfo:videoModel.videoInfo];
            self.videoInfoDict = videoModel.dictInfo;
            if (self.autoModeEnabled && self.resolutionServerControlEnabled) {
                self.currentResolution = [self _getAutoResolution];
            }
            [self.playSource setParamMap:self.currentParams];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:fetchedVideoModel:)]) {
                [self.delegate videoEngine:self fetchedVideoModel:videoModel];
            }
            //

            [self _startToPlay];
        }
    }];
    if ([self.playSource isKindOfClass:[TTVideoEnginePlayVidSource class]]) {
        [self.eventLogger setApiString:[(TTVideoEnginePlayVidSource *)self.playSource apiString]];
    }
}

- (void)fetchVideoInfo {
    TTVideoRunOnMainQueue(^{
        self.state = TTVideoEngineStateFetchingInfo;

        [self _fetchVideoInfo];
    }, NO);
}

- (void)tryNextURL {
    TTVideoRunOnMainQueue(^{
        BOOL temResult = [self.playSource skipToNext];
        if (temResult == NO) { // no more url.
            NSString *s_model = @"";
            NSString *s_api_string = @"";
            if ([self.playSource isKindOfClass:[TTVideoEnginePlayVidSource class]]) {
                TTVideoEnginePlayVidSource *pvs = (TTVideoEnginePlayVidSource *)self.playSource;
                s_model = [pvs.fetchData description];
                s_api_string = pvs.apiString;
            }
            NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                                 code:TTVideoEngineErrorResultNotApplicable
                                             userInfo:@{@"location":@"tryNextURL",
                                                        @"video_id":self.playSource.videoId ?: @"null",
                                                        @"video_model": s_model,
                                                        @"api_string":s_api_string}];
            [self didReceiveError:error];
            return;
        }
        //
        [self _startToPlay];
    }, NO);
}

- (void)_logDNSMode:(NSInteger) isUsingAVPlayer {
    if (isUsingAVPlayer) {
        [_eventLogger setDNSMode:LOGGER_DNS_MODE_AVPLAYER];
    } else {
        [_eventLogger setDNSMode:LOGGER_DNS_MODE_ENGINE];
    }
}

//MARK: - async initialization
- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)wrapper {
    TTVideoEngineLog(@"async init: set wrapper type: %ld, player type: %ld",
                     (NSInteger)wrapper.type, (NSInteger)self.playerType);
    if (self.playerType == wrapper.type && !self.isViewWrapperSet) {
        self.playerView = wrapper.playerView;
        [self.player setUpPlayerViewWrapper:wrapper];
#ifdef DEBUG
        if (_debugView != wrapper.debugView)
            _debugView = wrapper.debugView;
#endif
        self.isViewWrapperSet = YES;
    }
}

#pragma mark - Parse IP and DNS handling

- (void)parseDNS:(NSString *)urlString {
    TTVideoRunOnMainQueue(^{
        NSString *temString = urlString;
        if ([temString rangeOfString:@"?"].length > 0) {
            temString = [temString substringToIndex:[temString rangeOfString:@"?"].location];
        }
        NSURL *url = [NSURL URLWithString:temString];
        if (!url || !url.host) {
            NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                                 code:TTVideoEngineErrorUrlEmpty
                                             userInfo:@{@"url":urlString?:@"null",
                                                        @"info":@"NSURL is invalid"
                                             }];
            [self didReceiveError:error];
            return;
        }

        int64_t curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        [self.eventLogger setInt64Option:LOGGER_OPTION_TIME_DNS_START value:curT];
        [self _logDNSMode:0];
        self.state = TTVideoEngineStateParsingDNS;
        self.dnsParser = [[TTVideoEngineDNSParser alloc] initWithHostname:url.host];
        if(self.errorCount > 0){
            [self.dnsParser setForceReparse];
        }
        self.dnsParser.isUseDnsCache = self.dnsCacheEnable;
        if (self.currentNetworkStatus == TTVideoEngineNetWorkStatusNotReachable) { // need update.
            self.currentNetworkStatus = [[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus];
        }
        self.dnsParser.networkType = self.currentNetworkStatus;
        if(self.dnsExpiredTime > 0){
            self.dnsParser.expiredTimeSeconds = self.dnsExpiredTime;
        }
        if(sVideoEngineDnsTypes != nil){
            self.dnsParser.parserIndex = sVideoEngineDnsTypes;
        }else{
            [self.dnsParser setIsHTTPDNSFirst:isVideoEngineHTTPDNSFirst];
        }
        self.dnsParser.delegate = self;
        [self.dnsParser start];

        [self.eventLogger setInitialHost:url.host.copy];
        //
    }, NO);
}

- (void)updateURLWithIP:(NSString *)ipAddress {
    self.currentIPURL = [self.currentHostnameURL stringByReplacingOccurrencesOfString:self.dnsParser.hostname withString:ipAddress];
    [self.urlIPDict ttvideoengine_setObject:ipAddress forKey:self.currentHostnameURL];
    [self updateURLArray];

    [self.eventLogger setIp:ipAddress.copy];
    [self.eventLogger setDNSParseTime:([[NSDate date] timeIntervalSince1970]*1000)];
}

#pragma mark -

/** Need setup self.player */
- (void)_setUpPlayer {
    self.shouldUseAudioRenderStart = NO;
    self.didCallPrepareToPlay = YES;
    self.state = TTVideoEngineStatePlayerRunning;
    NSTimeInterval preparePlayerTime = [[NSDate date] timeIntervalSince1970] * 1000;
    /// Set trace-id
    _traceId = [self.eventLogger getTraceId];
    if (_traceId == nil) {
        _traceId = [self _traceIdBaseTime:preparePlayerTime];
    }
    [self.header setObject:_traceId?:@"" forKey:@"X-Tt-Traceid"];
    if ([self.networkPredictorAction respondsToSelector:@selector(setSinglePredictSpeedTimeIntervalWithHeader:)]) {
        [self.networkPredictorAction setSinglePredictSpeedTimeIntervalWithHeader:self.header];
    }
    [self.header setObject:[NSString stringWithFormat:@"%d",self.fallbackApiMDLRetry] forKey:@"X-Tt-Fapi"];
    if (self.fallbackApiMDLRetry) {
        [self.header setObject:[NSString stringWithFormat:@"%@",self.engineHash] forKey:@"Engine-ID"];
    }
    [self.header setObject:[NSString stringWithFormat:@"%@", _logInfoTag?_logInfoTag:@""] forKey:@"X-Tt-Tag"];
    if (_subtag != nil) {
        [self.header setObject:[NSString stringWithFormat:@"%@", _subtag] forKey:@"X-Tt-SubTag"];
    }
    
    [self.eventLogger setPrepareStartTime:(long long)(preparePlayerTime)];
    [self.eventLogger setPlayHeaders:self.header];
    
    [self _configHardwareDecode];
    
    [_options applyToPlayer:_player];
    [self _updateOptionsToLogger];
    
    [self.player setSmoothDelayedSeconds:self.smoothDelayedSeconds];
    [self.player setStartTime:self.startTime];
    
    NSInteger audioInfoId = self.options.currentAudioInfoId >= 0 ? self.options.currentAudioInfoId : self.playSource.getDefaultAudioInfo;
    [self.player setIntValue:(int)audioInfoId forKey:KeyIsSetDefaultAudioInfoId];
    [self.player setIntValue:self.disableShortSeek forKey:KeyIsDisableShortSeek];
    [self.player setIntValue:self.seekEndEnabled forKey:KeyIsSeekEndEnable];
    [self.player setIntValue:self.loopStartTime forKey:KeyIsLoopStartTime];
    [self.player setIntValue:self.loopEndTime forKey:KeyIsLoopEndTime];
    [self.player setIntValue:self.embellishVolumeMilliseconds forKey:KeyIsEmbellishVolumeTime];
    [self.player setIntValue:self.reuseSocket forKey:KeyIsReuseSocket];
    [self.player setIntValue:self.disableAccurateStart forKey:KeyIsDisableAccurateStartTime];
    [self.player setIntValue:self.cacheMaxSeconds forKey:KeyIsSettingCacheMaxSeconds];
    [self.player setIntValue:self.bufferingTimeOut forKey:KeyIsBufferingTimeOut];
    [self.player setIntValue:self.maxBufferEndTime forKey:KeyIsMaxBufferEndTime];
    [self.player setIntValue:self.defaultBufferEndTime forKey:KeyIsDefaultBufferEndTime];
    [self.eventLogger setEncryptKey:nil];
    if (self.decryptionKey) {
        [self.player setValueString:self.decryptionKey forKey:KeyIsDecryptionKey];
        [self.eventLogger setEncryptKey:self.decryptionKey];
    }
    [self.player setIntValue:self.audioEffectEnabled forKey:KeyIsEnableAudioEffect];
    if (!self.isEnablePlayCallbackHitCacheSize) {
        [self _updateMDLHitCacheSize];
    }
    

    if (self.isOwnPlayer && self.playSource.preloadItem && ![self.playSource usingUrlInfo]) {// Need preloadItem valid
        [self.header setValue:[NSURL URLWithString:self.playSource.preloadItem.URL].host forKey:@"Host"];
        ///Here is the calculation cache file size, slightly larger than the actual cached video data.
        [self.eventLogger setVideoPreloadSize:TTVideoEngineGetLocalFileSize(self.playSource.preloadItem.filePath)];
    } else if (self.isUsingAVResolver  && self.playSource.isSingleUrl) {
        [self.header removeObjectForKey:@"Host"];
    } else {
        [self.header setValue:self.dnsParser.hostname forKey:@"Host"];
    }

    [self.player setCustomHeader:[self.header copy]];

    if ((self.isSwitchingDefinition && !self.smoothlySwitching) || self.isRetrying) {
        if (self.lastPlaybackTime > kInvalidatePlayTime) { // valid lastPlaybackTime
            [self.player setStartTime:self.lastPlaybackTime];
        }
    }

    if (self.drmCreater) {
        [self.player setDrmCreater:self.drmCreater];
    }

    if (self.loadControl) {
        [self.player setLoadControl:self.loadControl];
        [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_LOADCONTROL value:1];
    }
    if (self.maskInfoDelegate && self.barrageMaskThreadEnable) {
        [self.player setMaskInfo:self];
    }
    if (self.aiBarrageThreadEnable) {
        [self.player setAIBarrageInfo:self.aiBarrager];
    }
    [self.player setIntValue:self.drmType forKey:KeyIsDrmType];
    [self.player setIntValue:self.drmDowngrade forKey:KeyIsDrmDowngrade];
    [self.eventLogger setDrmType:self.drmType];
    if (self.playSource.videoId) {
        [self.player setValueString:self.playSource.videoId forKey:KeyIsVideoId];
    }
    if (self.tokenUrlTemplate) {
        [self.player setValueString:self.tokenUrlTemplate forKey:KeyIsTokenUrlTemplate];
        [self.eventLogger setDrmTokenUrl:self.tokenUrlTemplate];
    }
    self.barrageMaskUrl = [self.playSource barrageMaskUrl];
    if (self.barrageMaskUrl.length && self.barrageMaskThreadEnable) {
        self.supportBarrageMask = YES;
        self.player.barrageMaskEnable = self.barrageMaskEnable;
        NSString *maskFileHash = [self.playSource getValueStr:VALUE_MASK_FILE_HASH];
        if(_maskEnableDataLoader > 0 && _medialoaderEnable > 0 && maskFileHash.length){
            NSString *maskUrl = [self _ls_proxyUrl:maskFileHash rawKey:self.playSource.videoId urls:@[self.barrageMaskUrl] extraInfo:nil filePath:nil];
            if(maskUrl.length){
                self.barrageMaskUrl = maskUrl;
            }
        }
        [self.player setValueString:self.barrageMaskUrl forKey:KeyIsBarrageMaskUrl];
        [self.player setIntValue:(int)[self.playSource getValueInt:VALUE_MASK_HEAD_LEN] forKey:KeyIsMaskHeaderLen];
        [self.eventLogger setMaskFileHash:maskFileHash];
    }
    if ([self.playSource aiBarrageUrl] && self.aiBarrageThreadEnable) {
        self.player.aiBarrageEnable = self.aiBarrageEnable;
        [self.player setValueString:[self.playSource aiBarrageUrl] forKey:KeyIsAIBarrageUrl];
    }
    [self.eventLogger setMaskThreadEnable:self.barrageMaskThreadEnable];
    [self.eventLogger setMaskUrl:[self.playSource barrageMaskUrl]];
    [self.eventLogger setMaskEnableMdl:self.maskEnableDataLoader];
    [self.eventLogger setMaskFileSize:[self.playSource getValueInt:VALUE_MASK_FILE_SIZE]];
    if(!self.didSetAESrcPeak && !self.didSetAESrcLoudness){
        if([self.playSource supportDash] && self.dynamicAudioInfo){
            self.audioEffectSrcPeak = [self.dynamicAudioInfo getValueFloat:VALUE_VOLUME_PEAK];
            self.audioEffectSrcLoudness = [self.dynamicAudioInfo getValueFloat:VALUE_VOLUME_LOUDNESS];
        }else{
            self.audioEffectSrcPeak = [self.currentVideoInfo getValueFloat:VALUE_VOLUME_PEAK];
            self.audioEffectSrcLoudness = [self.currentVideoInfo getValueFloat:VALUE_VOLUME_LOUDNESS];
        }
        if(self.audioEffectSrcPeak == 0.0f && self.audioEffectSrcLoudness == 0.0f){
            self.audioEffectSrcPeak = [self.playSource getValueFloat:VALUE_VOLUME_PEAK];
            self.audioEffectSrcLoudness = [self.playSource getValueFloat:VALUE_VOLUME_LOUDNESS];
        }
        [self.player setFloatValue:self.audioEffectSrcPeak forKey:KeyIsAESrcPeak];
        [self.player setFloatValue:self.audioEffectSrcLoudness forKey:KeyIsAESrcLufs];
    }
    if(_aeForbidCompressor && _audioEffectSrcLoudness == 0.0f && _audioEffectSrcPeak == 0.0f){
        self.audioEffectEnabled = NO;
    }
    [self.player setIntValue:self.audioEffectEnabled forKey:KeyIsEnableAudioEffect];
    [self.player setIntValue:self.reportRequestHeaders forKey:KeyIsReportRequestHeaders];
    [self.player setIntValue:self.reportResponseHeaders forKey:KeyIsReportResponseHeaders];

    [self.player setIntValue:self.enableIndexCache forKey:KeyIsEnableIndexCache];
    [self.player setIntValue:self.enableFragRange forKey:KeyIsEnableFragRange];
    [self.player setIntValue:self.enableAsync forKey:KeyIsEnableAsync];
    [self.player setIntValue:self.rangeMode forKey:KeyIsRangeMode];
    [self.player setIntValue:self.readMode forKey:KeyIsReadMode];
    [self.player setIntValue:self.videoRangeSize forKey:KeyIsVideoRangeSize];
    [self.player setIntValue:self.audioRangeSize forKey:KeyIsAudioRangeSize];
    [self.player setIntValue:self.videoRangeTime forKey:KeyIsVideoRangeTime];
    [self.player setIntValue:self.audioRangeTime forKey:KeyIsAudioRangeTime];
    [self.player setIntValue:self.skipFindStreamInfo forKey:KeyIsSkipFindStreamInfo];
    [self.player setIntValue:self.updateTimestampMode forKey:KeyIsUpdateTimestampMode];
    [self.player setIntValue:self.enableOpenTimeout forKey:KeyIsEnableOpenTimeout];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_NETWORK_TIMEOUT value:_enableOpenTimeout?1:0];
    [self.player setIntValue:self.codecDropSkippedFrame forKey:KeyIsCodecDropSikppedFrame];
    [self.player setIntValue:self.avSyncStartEnable forKey:KeyIsAVStartSync];
    [self.player setIntValue:self.audioUnitPoolEnabled forKey:KeyIsUseAudioPool];
    [self.player setIntValue:self.playerLazySeek forKey:KeyIsSeekLazyInRead];
    [self.player setIntValue:self.normalClockType forKey:KeyIsNormalClockType];
    [self.player setIntValue:self.stopSourceAsync forKey:KeyIsStopSourceAsync];
    [self.player setIntValue:self.enableSeekInterrupt forKey:KeyIsEnableSeekInterrupt];
    [self.player setIntValue:self.changeVtbSizePicSizeBound forKey:KeyIsChangeVtbSizePicSizeBound];
    [self.player setIntValue:self.enableRangeCacheDuration forKey:KeyIsEnableRangeCacheDuration];
    [self.player setIntValue:self.enableVoiceSplitHeaacV2 forKey:KeyIsVoiceSplitHeaacV2];
    [self.player setIntValue:self.enableAudioHardwareDecode forKey:KeyIsAudioHardwareDecode];
    [self.player setIntValue:self.delayBufferingUpdate forKey:KeyIsDelayBufferingUpdate];
    [self.player setIntValue:self.noBufferingUpdate forKey:KeyIsNoBufferingUpdate];
    [self.player setIntValue:self.keepVoiceDuration forKey:KeyIsKeepVoiceDuration];
    [self.player setIntValue:self.voiceBlockDuration forKey:KeyIsVoiceBlockDuration];
    [self.player setIntValue:self.enableSRBound forKey:KeyIsEnableSRBound];
    [self.player setIntValue:self.cacheVoiceId forKey:KeyIsCacheVoiceId];
    [self.player setIntValue:self.skipSetSameWindow forKey:KeyIsSkipSetSameWindow];
    [self.player setIntValue:self.srLongDimensionLowerBound forKey:KeyIsSRLongDimensionLowerBound];
    [self.player setIntValue:self.srLongDimensionUpperBound forKey:KeyIsSRLongDimensionUpperBound];
    [self.player setIntValue:self.srShortDimensionLowerBound forKey:KeyIsSRShortDimensionLowerBound];
    [self.player setIntValue:self.srShortDimensionUpperBound forKey:KeyIsSRShortDimensionUpperBound];
    [self.player setIntValue:self.filePlayNoBuffering forKey:KeyIsFilePlayNoBuffering];
    NSString *hijackCheckInfo = [self.playSource checkInfo:self.currentResolution];
    if ([self.playSource isMemberOfClass:[TTVideoEnginePlayUrlSource class]] ||
        [self.playSource isMemberOfClass:[TTVideoEnginePlayUrlsSource class]]) {
        hijackCheckInfo = _checkInfoString;
        TTVideoEngineLog("use extern checkinfo string: %@", _checkInfoString);
    }
    BOOL checkHijack = self.checkHijack && hijackCheckInfo.length > 0;
    [self.eventLogger setCheckHijack:checkHijack ? 1 : 0];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_HIJACK_RETRY value:self.hijackRetryEnable?1:0];
    [self.eventLogger setHijackCode:-1];
    [self.player setIntValue:!self.isHijackRetried forKey:KeyIsHijackExit];
    if ([self isSupportSeamlessSwitch]) {
        int predictStartBitrate = 0;
        if (self.enableDashAbr) {
            VCABRResult *result = [self.abrModule onceSelect:ABROnceAlgoTypeBwOnce scene:ABRSelectSceneStartUp];
            VCABRResultElement *element = [result elementAtIndex:0];
            predictStartBitrate = element.bitrate;
            TTVideoEngineLog(@"[ABR] predict start bitrate:%dbps",predictStartBitrate);
        }
        if(![self.playSource hasVideo]){
            [self.player setIntValue:[self.playSource bitrateForDashSourceOfType:self.currentResolution] forKey:KeyIsDefaultAudioBitrate];
            if (checkHijack) {
                [self.player setValueString:hijackCheckInfo forKey:KeyIsAudioCheckInfo];
            }
        }else{
            if (predictStartBitrate > 0 && self.abrSwitchMode == TTVideoEngineDashABRSwitchAuto) {
                self.isUsedAbr = self.enableDashAbr || self.isUsedAbr;
                [self.player setIntValue:predictStartBitrate forKey:KeyIsDefaultVideoBitrate];
            } else {
                [self.player setIntValue:[self.playSource bitrateForDashSourceOfType:self.currentResolution] forKey:KeyIsDefaultVideoBitrate];
            }
            if (checkHijack) {
                [self.player setValueString:hijackCheckInfo forKey:KeyIsVideoCheckInfo];
            }
        }
        [self.player setIntValue:self.enableDashAbr forKey:KeyIsEnableDashABR];
    } else {
        self.dashEnabled = NO;
        [self.player setIntValue:NO forKey:KeyIsDisableAccurateStartTime];
        if (checkHijack) {
            [self.player setValueString:hijackCheckInfo forKey:KeyIsVideoCheckInfo];
        }
    }
    
    if (!checkHijack) {
        [self.player setValueString:nil forKey:KeyIsVideoCheckInfo];
        [self.player setValueString:nil forKey:KeyIsAudioCheckInfo];
    }
    if (self.playSource.decryptionKey) {
        [self.player setValueString:self.playSource.decryptionKey forKey:KeyIsDecryptionKey];
        [self.eventLogger setEncryptKey:self.playSource.decryptionKey];
    }

    // Is swithing resolution
    BOOL isSwithingResolution = self.isSwitchingDefinition && self.smoothlySwitching && self.isOwnPlayer;
    if (isSwithingResolution) {
        self.isSwitchingDefinition = NO;
        @weakify(self)
        [self.player playNextWithURL:[NSURL URLWithString:self.currentIPURL]
                            complete:^(BOOL success) {
                                @strongify(self)
                                if (!self) {
                                    return;
                                }
                                [self switchDefinitionCompleted:success];
                            }];
        return;
    }
    //
    if (self.isSwitchingDefinition && self.isOwnPlayer) {
        [self.player setPrepareFlag:NO];
    }
    [self.player setIgnoreAudioInterruption:isIgnoreAudioInterruption];

    // check url
    if ([self.currentHostnameURL rangeOfString:@"/"].location != 0) {
        //非本地
        NSURL *url = [NSURL URLWithString:self.currentHostnameURL];
        if (!url) {
            // case when url contains chinese characters, need to encode
            NSString* encodedUrl = [self.currentHostnameURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            url = [NSURL URLWithString:encodedUrl];
        }
        if (!url.scheme) {
            TTVideoEngineLogE(@"invalid play url:%@", self.currentHostnameURL);
            NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainOwnPlayer
                                                 code:TTVideoEngineErrorUrlInvalid
                                             userInfo:nil];
            [self didReceiveError:error];
            return;
        }
    }

    if (self.osplayerItem) {
        [self.player setAVPlayerItem:self.osplayerItem];
    } else {
        if (self.isUsingAVResolver && self.playSource.isSingleUrl) {
            [self.player setContentURLString:self.currentHostnameURL];
        } else {
            if (self.currentIPURL != nil) {
                [self.player setContentURLString:self.currentIPURL];
            } else {
                [self.player setContentURLString:self.currentHostnameURL];
            }
        }
    }
    if(self.playUrl.length){
        NSString *ip = [self.urlIPDict ttvideoengine_objectForKey:self.currentHostnameURL];
        if(ip.length > 0){
            _playUrl = [_playUrl stringByReplacingOccurrencesOfString:self.dnsParser.hostname withString:ip];
        }
    }
    [self.player setValueString:self.playUrl forKey:KeyIsFileUrl];
    [self.player setValueString:nil forKey:KeyIsMediaFileKey];

    NSInteger medialoaderEnable = NO;
    medialoaderEnable = self.medialoaderEnable;
   
    //
    if (self.isSwitchingDefinition) {
        [self.eventLogger accumulateSize];
    }

    //recheck vpls for direct buffering, if no vpls, close direct buffering
    if(_recheckVPLSforDirectBuffering && _enableEnterBufferingDirectly && self.medialoaderEnable) {
        NSArray *keys = self.localServerTaskKeys.copy;
        for (NSString *key in keys) {
            if (key) {
                int64_t temCacheSize = [TTVideoEngine ls_tryQuickGetCacheSizeByKey:key];
                if(temCacheSize <= 0) {
                    self.enableEnterBufferingDirectly = NO;
                    TTVideoEngineLog(@"no vpls, close direct buffering. key = %@",key);
                }
            }
        }
    }
    //
    NSString *uaStr = [self produceUserAgentString];
    [self.player setValueString:uaStr forKey:KeyIsHttpUserAgent];

    [self.player prepareToPlay];
}

-(void)_updateMDLHitCacheSize {
    self.mdlCacheSize = 0;
    NSArray *keys = self.localServerTaskKeys.copy;
    for (NSString *key in keys) {
        if (self.medialoaderEnable && key) {
            @weakify(self)
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                @strongify(self)
                if (!self) {
                    return;
                }

                NSString *temKey = key;
                int64_t temCacheSize = [TTVideoEngine ls_getCacheSizeByKey:temKey];
                TTVideoRunOnMainQueue(^{
                    if ([temKey isEqualToString:key]) {
                        self.mdlCacheSize += temCacheSize;
                        [self.eventLogger setVideoPreloadSize:self.mdlCacheSize];
                        if (keys.count < 2 || (keys.count >= 2 && [self.bashDefaultMDLKeys containsObject:key])) {
                            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:mdlKey:hitCacheSze:)]) {
                                [self.delegate videoEngine:self mdlKey:temKey hitCacheSze:temCacheSize];
                            }
                            TTVideoEngineLog(@"using mdl cache. key = %@. size = %@",temKey,@(temCacheSize));
                        }
                    }
                }, NO);
            });
        }
    }
}

- (void)_updateOptionsToLogger {
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_FALLBACK_API_MDL_RETRY value:self.fallbackApiMDLRetry?1:0];
    if (self.httpsEnabled) {
        [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_HTTPS value:1];
    }
    [self.eventLogger useHardware:self.hardwareDecode];
    [_eventLogger setIntOption:LOGGER_OPTION_ENABLE_OUTLET_DROP_LIMIT value:_options.enableOutletDropLimit?1:0];
    
    if (self.options.precisePausePts > 0) {
        [_eventLogger addFeature:FEATURE_KEY_PRECISE_PAUSE value:@(1)];
    }
    if (self.options.isCheckVoiceInBufferingStart) {
        [_eventLogger addFeature:FEATURE_KEY_BUFFER_START_CHECK_VOICE value:@(1)];
    }
    if (_aiBarrageThreadEnable) {
        [_eventLogger addFeature:FEATURE_KEY_AI_BARRAGE value:@(1)];
    }
    if (_noBufferingUpdate) {
        [_eventLogger addFeature:FEATURE_KEY_NO_BUFFER_UPDATE value:@(1)];
    }
    if (self.options.enableMp4Check > 0) {
        [_eventLogger addFeature:FEATURE_KEY_AV_INTERLACED_CHECK value:@(1)];
    }
    if (self.options.enableDemuxNonblockRead) {
        [_eventLogger addFeature:FEATURE_KEY_DEMUX_NONBLOCK_READ value:@(1)];
    }
    if (self.options.isOptBluetoothRenderSync) {
        [_eventLogger addFeature:FEATURE_KEY_BLUETOOTH_SYNC value:@(1)];
    }
    if (self.options.enableNativeMdlSeekReopen) {
        [_eventLogger addFeature:FEATURE_KEY_MDL_SEEK_REOPEN value:@(1)];
    }
    
    NSNumber* value = [self.options getPreIntOptForKey:@(VEKKeyPlayerEnableCPPBYTEVC1CodecOpt_BOOL)];
    if (value) {
        int isEnableBytevc1Opt = [value intValue];
        if (isEnableBytevc1Opt > 0) {
            [_eventLogger addFeature:FEATURE_KEY_BYTEVC1_DECODER_OPT value:@(1)];
        }
    }
    
    int enableHWDropWhenVOIsInDropState = [[self.options getPreIntOptForKey:@(VEKKeyEnableHWDropFrameWhenVOIsInDropState_NSInteger)] intValue];
    int enableHWDropWhenAVOutSyncing = [[self.options getPreIntOptForKey:@(VEKKeyEnableHWDropFrameWhenAVOutSyncing_NSInteger)] intValue];
    if (enableHWDropWhenVOIsInDropState == 1) {
        [_eventLogger addFeature:@"hw_decoder_drop" value:@(1)];
    } else if (enableHWDropWhenAVOutSyncing == 1) {
        [_eventLogger addFeature:@"hw_decoder_drop" value:@(2)];
    }
    int enableVoiceReuse = [[self.options getPreIntOptForKey:@(VEKKeyIsEnableAVVoiceReuse_NSInteger)] intValue];
    if (enableVoiceReuse) {
        [_eventLogger addFeature:@"av_voice_reuse" value:@(1)];
    }
}

/** Just call [self.player play]; */
- (void)_play {
    if (self.playSource.supportResolutions) {// Support multifarious resolution
        [self.eventLogger setInitialResolution:[self _resolutionStringForType:_currentResolution]];
        [self.eventLogger setCurrentDefinition:[self _resolutionStringForType:_currentResolution]
                                lastDefinition:[self _resolutionStringForType:_lastResolution]];
    }
    //
    [self.player play];
    if (self.lastUserAction != TTVideoEngineUserActionPlay && !(self.isSwitchingDefinition && (self.lastUserAction == TTVideoEngineUserActionPause || self.lastUserAction == TTVideoEngineUserActionStop))) {
        [self.player pause];
    }
}

- (void)_playVideo {
    //
    if (self.isUserStopped) {
        self.state = TTVideoEngineStateUnknown;
        return;
    }
    //
    CODE_ERROR((self.currentHostnameURL == nil) && !_osplayerItem)
    if (self.currentHostnameURL != nil && self.isFirstURL == YES) {
        [self.eventLogger setInitalURL:self.currentHostnameURL];
        self.isFirstURL = NO;
    }
    // Is it the first call?
    BOOL isFirstCall = (!self.didCallPrepareToPlay) && (self.state != TTVideoEngineStatePlayerRunning || self.playbackState == TTVideoEnginePlaybackStateStopped || self.playbackState == TTVideoEnginePlaybackStateError);
    if (isFirstCall || self.playerIsPreparing || (self.isSwitchingDefinition && fabs(self.lastPlaybackTime - kInvalidatePlayTime) > 0.0001)) {
        [self _setUpPlayer];
    }
    
    if (self.state == TTVideoEngineStateError) {
        return;
    }
    //
    if (!self.playerIsPreparing) {
        [self _play];
        
        if (self.isEnablePlayCallbackHitCacheSize) {
            [self _updateMDLHitCacheSize];
        }
    }

    /// play again need.
    self.state = TTVideoEngineStatePlayerRunning;
    if (self.enableDashAbr) {
        [self.abrModule start:sABRFlowType intervalMs:0];
    }
}

- (void)playVideo {
    TTVideoRunOnMainQueue(^{
        [self _playVideo];
    }, NO);
}

- (nullable NSString *)getMemUrl {
     NSInteger videoModelVersion = [self.playSource videoModelVersion];
    if(videoModelVersion == TTVideoEngineVideoModelVersion3){
        self.bashEnable = YES;
    }
    if(self.bashEnable && [self.playSource supportDash] && [[self.playSource getDynamicType] isEqualToString:@"segment_base"]) {
        int urlIndex = [self.playSource currentUrlIndex];
        NSString *memString = [self.playSource videoMemString];
        if (self.retryEnableHttps) {
            memString = TTVideoEngineBuildHttpsUrl(memString);
        }
        if (memString) {
            return [NSString stringWithFormat:@"mem://bash/url_index:%d/check_hijack:%d/segment_format:%d/%@",
                    urlIndex, self.checkHijack ? 1 : 0,TTVideoEngineDashSegmentFlagFormatFMP4,memString];
        }
    } else if (self.bashEnable && [self.playSource supportMP4] && [self.playSource enableAdaptive]) {
        NSString *memString = [self.playSource videoMemString];
        if (self.retryEnableHttps) {
            memString = TTVideoEngineBuildHttpsUrl(memString);
        }
        int urlIndex = [self.playSource currentUrlIndex];
        if (memString) {
            return [NSString stringWithFormat:@"mem://bash/url_index:%d/check_hijack:%d/segment_format:%d/%@",urlIndex,self.checkHijack ? 1 : 0,TTVideoEngineDashSegmentFlagFormatMp4,memString];
        }
    } else if (self.hlsSeamlessSwitch && [self isSupportHLSSeamlessSwitch]) {
        NSString *memString = [self.playSource videoMemString];
        if (self.retryEnableHttps) {
            memString = TTVideoEngineBuildHttpsUrl(memString);
        }
        int urlIndex = [self.playSource currentUrlIndex];
        if (memString) {
            return [NSString stringWithFormat:@"mem://hls/url_index:%d/%@",urlIndex, memString];
        }
    }
    return nil;
}

- (void)configAutoStartUpResolutionIfNeeded {
    TTVideoEngineLog(@"auto res: configAutoStartUpResolutionIfNeeded ----------")
    TTVideoEngineURLInfo *info = [TTVideoEngine _getAutoResolutionInfo:self.startUpParams
                                                            playSource:self.playSource];
    if (!info) {
        TTVideoEngineLog(@"auto res: empty selected result")
        return;
    }
    
    self.currentResolution = [info videoDefinitionType];
    TTVideoEngineLog(@"auto res: start up selected result: %ld", self.currentResolution);
}

- (void)startUpGearByGearStrategy {
    TTVideoEngineLog(@"[GearStrategy]startUpGearByGearStrategy gear strategy enabled");
    
    if(!self.playSource) {
        TTVideoEngineLog(@"[GearStrategy]startUpGearByGearStrategy playSource is null");
        return;
    }
    
    TTVideoEngineModel *videoModel = nil;
    if ([self.playSource isKindOfClass:[TTVideoEnginePlayModelSource class]]) {
        videoModel = ((TTVideoEnginePlayModelSource *)self.playSource).videoModel;
    } else if ([self.playSource isKindOfClass:[TTVideoEnginePlayBaseSource class]]) {
        videoModel = [TTVideoEngineModel new];
        videoModel.videoInfo = ((TTVideoEnginePlayBaseSource *)self.playSource).fetchData;
    }
    if(!videoModel) {
        TTVideoEngineLog(@"[GearStrategy]startUpGearByGearStrategy videoModel is null");
        return;
    }
    
    TTVideoEngineGearMutilParam params = [NSMutableDictionary new];
    TTVideoEngineStrategy *vodStrategy = TTVideoEngineStrategy.helper;
    if (!_gearStrategyContext) {
        _gearStrategyContext = [TTVideoEngineGearContext new];
    }
    id userData = _gearStrategyContext.userData;
    if(!vodStrategy.manager.isRunning) {
        TTVideoEngineLog(@"[GearStrategy] strategy center not running");
        id<TTVideoEngineGearStrategyDelegate> gearDelegate = _gearStrategyContext.gearDelegate;
        if(!gearDelegate) {
            gearDelegate = TTVideoEngineStrategy.helper.gearDelegate;
        }
        if(gearDelegate) {
            if([gearDelegate respondsToSelector:@selector(vodStrategy:onBeforeSelect:type:param:userData:)]) {
                [gearDelegate vodStrategy:vodStrategy onBeforeSelect:videoModel type:TTVideoEngineGearPlayType param:params userData:userData];
            }
            params[TTVideoEngineGearKeyErrorCode] = [NSString stringWithFormat: @"%ld", (long)TTVideoEngineGearErrorStrategyCenterNotRunning];
            params[TTVideoEngineGearKeyErrorDesc] = @"strategy center not running";
            if([gearDelegate respondsToSelector:@selector(vodStrategy:onAfterSelect:type:param:userData:)]) {
                [gearDelegate vodStrategy:vodStrategy onAfterSelect:videoModel type:TTVideoEngineGearPlayType param:params userData:userData];
            }            
        }
        return;
    }
    
    _gearStrategyContext.videoModel = videoModel;
    TTVideoEngineGearParam result = [vodStrategy gearVideoModel:videoModel type:TTVideoEngineGearPlayType extraInfo:params context:_gearStrategyContext];
    if(result) {
        int videoBitrate = 0;
        int audioBitrate = 0;
        NSString *videoBitrateStr = [result objectForKey:TTVideoEngineGearKeyMediaTypeVideo];
        NSString *audioBitrateStr = [result objectForKey:TTVideoEngineGearKeyMediaTypeAudio];
        if(videoBitrateStr){
            videoBitrate = [videoBitrateStr intValue];
        }
        if(audioBitrateStr){
            audioBitrate = [audioBitrateStr intValue];
        }
        TTVideoEngineLog(@"[GearStrategy] gear strategy startup videoBitrate=%d audioBitrate=%d", videoBitrate, audioBitrate);
        TTVideoEngineURLInfo *selectedInfo = [TTVideoEngineStrategy.helper urlInfoFromModel:videoModel bitrate:videoBitrate mediaType:TTVideoEngineGearKeyMediaTypeVideo];
        if(selectedInfo) {
            self.currentResolution = [selectedInfo videoDefinitionType];
            TTVideoEngineLog(@"[GearStrategy] start up selected result: %ld", self.currentResolution);
        } else {
            TTVideoEngineLog(@"[GearStrategy]empty selected result")
        }
    } else {
        TTVideoEngineLog(@"[GearStrategy] gearVideoModel result nil")
    }
}

- (void)_setMdlForbidP2pFlag : (NSArray*)urls {
    if (urls == nil || urls.count == 0) {
        return;
    }
    if (!self.options.forbidP2p) {
        return;
    }
    NSString *param = @"p2p=0";
    NSMutableArray *urlsReplaced = [[NSMutableArray alloc] initWithCapacity:urls.count];

    for (int i = 0; i < urls.count; i++) {
        NSString *url = urls[i];
        if (url.length == 0) {
            continue;
        }
        if ([url containsString:param]) {
            [urlsReplaced addObject:url];
            continue;
        }
        if ([url containsString:@"?"]) {
            url = [url stringByAppendingFormat:@"&%@", param];
        } else {
            url = [url stringByAppendingFormat:@"?%@", param];
        }
        [urlsReplaced addObject:url];
    }
    urls = urlsReplaced;
}

- (void)_startToPlay {
    ENGINE_LOG(@"");
    
    if (self.options.enableStartUpAutoResolution) {
        [self configAutoStartUpResolutionIfNeeded];
    } else if(self.options.enableGearStrategy) {
        [self startUpGearByGearStrategy];
    }
    
    // Must first. configure resolution for playSource.
    TTVideoEngineResolutionType targetResolution = self.currentResolution;
    NSInteger videoModelVersion = [self.playSource videoModelVersion];
    [self.eventLogger setVideoModelVersion:videoModelVersion];
    NSMutableArray<TTVideoEngineURLInfo *> *urlinfos = [NSMutableArray array];
    [self.playSource setParamMap:self.currentParams];
    TTVideoEngineURLInfo *info = nil;
    NSString *temUrl = [self.playSource urlForResolution:self.currentResolution];
    if(![self.playSource hasVideo]){
        info =  [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"audio"];
    }else{
        info =  [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
    }
    self.currentResolution = self.playSource.currentResolution;

    self.currentQualityDesc = [info getValueStr:VALUE_VIDEO_QUALITY_DESC];
    [self.eventLogger setCurrentQualityDesc:self.currentQualityDesc];
    if (_preferSpdl4HDR && info != nil) {
        BOOL isHDR10 = [self isHDR10Video:info];
        TTVideoEngineLog(@"_startToPlay isHDR10: %@", self.currentQualityDesc);
        [_player setIntValue:isHDR10 forKey:KeyIsEnableHDR10];
    }
    
    if (_preferSpdl4HDR && _preferSpdl4HDRUrl && info == nil) {
        [_player setIntValue:YES forKey:KeyIsEnableHDR10];
    }

    NSString *quality = [info getValueStr:VALUE_QUALITY];
    [self.eventLogger setInitialQuality:quality];
    NSString *dynamicType =[self.playSource getDynamicType];
    [self.eventLogger setDynamicType:dynamicType];
    if ([self isSupportUseBash]) {
        // Note！！！
        // urlInfoForResolution allows resolution to be downgraded and may change currentResolution
        // audio dash: only audio info, currentResolution is audio resolution
        // video dash: audio + video info，currentResolution is video resolution
        TTVideoEngineURLInfo *infoAudio = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"audio"];
        TTVideoEngineURLInfo *infoVideo = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
        if(infoVideo != nil){
            [urlinfos addObject:infoVideo];
            NSString *temFilehash = [infoVideo getValueStr:VALUE_FILE_HASH];
            [self.eventLogger setStringOption:LOGGER_OPTION_VIDEO_FILE_HASH value:temFilehash];
            if (temFilehash && ![self.bashDefaultMDLKeys containsObject:temFilehash]) {
                [self.bashDefaultMDLKeys addObject:temFilehash];
            }
            TTVideoEngineLog(@"play info, dash video videoId = %@, targetResolution = %@, useResolution = %@",self.playSource.videoId,@(targetResolution),@([infoVideo getVideoDefinitionType]));
            if([[infoVideo getValueStr:VALUE_MEDIA_TYPE] isEqualToString:@"video"]){
                self.dynamicVideoInfo = infoVideo;
            }
        }
        if(infoAudio != nil){
            [urlinfos addObject:infoAudio];
            NSString *temFilehash = [infoAudio getValueStr:VALUE_FILE_HASH];
            [self.eventLogger setStringOption:LOGGER_OPTION_AUDIO_FILE_HASH value:temFilehash];
            if (temFilehash && ![self.bashDefaultMDLKeys containsObject:temFilehash]) {
                [self.bashDefaultMDLKeys addObject:temFilehash];
            }
            TTVideoEngineLog(@"play info, dash audio videoId = %@, targetResolution = %@, useResolution = %@",self.playSource.videoId,@(targetResolution),@([infoAudio getVideoDefinitionType]));
            if([[infoAudio getValueStr:VALUE_MEDIA_TYPE] isEqualToString:@"audio"]){
                self.dynamicAudioInfo = infoAudio;
            }
        }
        if (self.enableDashAbr && self.abrModule) {
            [self _initSetMediaInfo];
        }
    } else {
        if(info != nil){
            TTVideoEngineLog(@"play info, not dash videoId = %@, targetResolution = %@, useResolution = %@",self.playSource.videoId,@(targetResolution),@([info getVideoDefinitionType]));
             [urlinfos addObject:info];
        }
        self.enableDashAbr = NO;
    }
    self.currentVideoInfo = info;
    if (urlinfos.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:usingUrlInfos:)]) {
        [self.delegate videoEngine:self usingUrlInfos:urlinfos];
    }

    //1. local server
    BOOL enableMedialoader = self.medialoaderEnable && [TTVideoEngine ls_isStarted] && !self.playSource.isSingleUrl && self.playSource.videoId && self.supportedResolutionTypes;
    if (enableMedialoader) { // generate medialoader url for vid source.
        NSString *playUrl = nil;
        NSString* proxyUrl = nil;
        [self.localServerTaskKeys removeAllObjects];
        NSMutableArray<TTVideoEngineURLInfo *> *infolist = [[NSMutableArray array] init];
        if ([self isSupportUseBash] || [self isSupportHLSSeamlessSwitch]) {
            playUrl = [self getMemUrl];
            if (playUrl != nil) {
                infolist = [self.playSource getVideoList];
            }
        } else if([self.playSource usingUrlInfo] != nil) {
            [infolist addObject:[self.playSource usingUrlInfo]];
        }
        for(TTVideoEngineURLInfo *info in infolist) {
            TTVideoEngineResolutionType temType = [info getVideoDefinitionType];
            NSArray* urls = [info allURLForVideoID:nil transformedURL:NO];
            [self _setMdlForbidP2pFlag:urls];
            if (self.retryEnableHttps) {
                NSMutableArray *urlsReplaced = [[NSMutableArray alloc] initWithCapacity:urls.count];
                for (int i = 0; i < urls.count; i++) {
                    NSString *url = urls[i];
                    url = TTVideoEngineBuildHttpsUrl(url);
                    [urlsReplaced addObject:url];
                }
                urls = urlsReplaced;
            }
            NSString *temFileHash = [info getValueStr:VALUE_FILE_HASH];
            NSString *filePath = nil;
            if (temFileHash &&
                temFileHash.length > 0 &&
                _dataSource &&
                [_dataSource respondsToSelector:@selector(cacheFilePathUsingMediaDataLoader:infoModel:)]) {

                filePath = [_dataSource cacheFilePathUsingMediaDataLoader:self.playSource.videoId infoModel:info];
                if (filePath && ![filePath containsString:temFileHash]) {
                    CODE_ERROR(![filePath containsString:temFileHash]);
                    filePath = nil;
                }
                if (filePath) {
                    temFileHash = [TTVideoEngine _ls_keyFromFilePath:filePath];
                }
            }

            NSMutableString *extraInfo = [NSMutableString string];
            [extraInfo appendFormat:@"fileId=%@",info.fieldId?:@""];
            [extraInfo appendFormat:@"&bitrate=%zd",[info getValueInt:VALUE_BITRATE]];
            [extraInfo appendFormat:@"&pcrc=%@",info.p2pVerifyUrl?:@""];

            if(temFileHash.length){
                proxyUrl = [self _ls_proxyUrl:temFileHash rawKey:self.playSource.videoId urls:urls extraInfo:extraInfo filePath:filePath];
                
                if (temFileHash && ![self.fileHashArray containsObject:temFileHash]) {
                    [self.fileHashArray addObject:temFileHash];
                }
                
                TTVideoEngineLog(@"mediloader url:%@ \n", proxyUrl);
                if (proxyUrl) {
                    if([playUrl hasPrefix:@"mem://bash"] || [playUrl hasPrefix:@"mem://hls"]){
                        for (NSString *url in urls) {
                            NSString *tmpUrl = [url stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
                            playUrl = [playUrl stringByReplacingOccurrencesOfString:tmpUrl withString:proxyUrl];
                        }
                    }
                    [self _ls_addTask:self.playSource.videoId
                                  key:temFileHash
                           resolution:temType
                             proxyUrl:proxyUrl
                        decryptionKey:self.playSource.spade_a
                                 info:info
                                 urls:urls];
                } else { // Error
                    TTVideoEngineLog(@"local server, key is null \n");
                }
            }
        }
        if(enableMedialoader && proxyUrl){
            _playUrl =  playUrl;
            [self.eventLogger setEnableBash:[_playUrl hasPrefix:@"mem://bash"]?1:0];
            self.currentHostnameURL = proxyUrl;
            self.currentIPURL = proxyUrl;
            [self.eventLogger proxyUrl:proxyUrl];
            [self _logDNSMode:_isUsingAVResolver];
            // Add to all tasks.
            [self playVideo];
            return;
        }
    }
    
    //2. not local server.
    if (temUrl == nil) {
        NSString *s_model = @"";
        NSString *s_api_string = @"";
        if ([self.playSource isKindOfClass:[TTVideoEnginePlayVidSource class]]) {
            TTVideoEnginePlayVidSource *pvs = (TTVideoEnginePlayVidSource *)self.playSource;
            s_model = [pvs.fetchData description];
            s_api_string = pvs.apiString;
        }
        NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                             code:TTVideoEngineErrorResultNotApplicable
                                         userInfo:@{@"location":@"_startToPlay",
                                                    @"video_id":self.playSource.videoId ?: @"null",
                                                    @"video_model": s_model,
                                                    @"api_string":s_api_string}];
        [self didReceiveError:error];
        return;
    }
    //如果开启了mdl，且开启了测速，但没有enablBash或者isSupportUseBash(开启bash)将url地址转为mdl地址。OR在上述代码中如果开启了mdl但不开启dash直接转成mdlurl`
    if (enableMedialoader && sTestSpeedEnabled) {
        TTVideoEngineURLInfo *temUrlInfo = nil;
        if(![self.playSource hasVideo]){
            temUrlInfo =  [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"audio"];
        }else{
            temUrlInfo =  [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
        }
        NSString *temProxyUrl = [self generateMdlUrlForSpeedTest:temUrlInfo temUrl:temUrl];
        TTVideoEngineLog(@"speedtest mdl tempUrl:%@ temproxyUrl:%@",temUrl, temProxyUrl);
        if (temProxyUrl) {
            self.currentHostnameURL = temProxyUrl;
            self.currentIPURL = temProxyUrl;
            [self.eventLogger proxyUrl:temProxyUrl];
            [self _logDNSMode:_isUsingAVResolver];
            // Add to all tasks.
            [self playVideo];
            return;
        }
    }
    _playUrl = nil;
    if ([self isSupportUseBash] || [self isSupportHLSSeamlessSwitch]) {
        _playUrl = [self getMemUrl];
    }
    if (_playUrl == nil && [temUrl hasPrefix:@"mem://bash"]) // directUrl 播放方式中，直接设置了 mem url
        _playUrl = temUrl;
    [self.eventLogger setEnableBash:[_playUrl hasPrefix:@"mem://bash"] ? 1 : 0];
    self.currentHostnameURL = temUrl;

    BOOL isHttps = [self.currentHostnameURL hasPrefix:@"https"];
    if((self.isUsingAVResolver && self.playSource.isSingleUrl)
       || (!self.isOwnPlayer && isHttps)) { //if https with sys player, donot use httpdns
        [self playVideo];
        return;
    }

    [self.urlIPDict ttvideoengine_setObject:@"" forKey:self.currentHostnameURL];
    [self updateURLArray];
    NSRange httpRange = [self.currentHostnameURL rangeOfString:@"http"];
    if (httpRange.location == 0) {
        BOOL isIpAddress = TTVideoEngineCheckHostNameIsIP(self.currentHostnameURL);
        if (isIpAddress) {
            self.currentIPURL = self.currentHostnameURL;
            [self playVideo];
        } else {
            [self parseDNS:self.currentHostnameURL];
        }
    } else {
        [self playVideo];
    }
}

- (NSString *)generateMdlUrlForSpeedTest:(TTVideoEngineURLInfo *)info temUrl:(NSString *)temUrl {
    NSString *proxyUrl = nil;
    TTVideoEngineResolutionType temType = [info getVideoDefinitionType];
    NSArray* urls = [info allURLForVideoID:nil transformedURL:NO];
    if (self.retryEnableHttps) {
        NSMutableArray *urlsReplaced = [[NSMutableArray alloc] initWithCapacity:urls.count];
        for (int i = 0; i < urls.count; i++) {
            NSString *url = urls[i];
            url = TTVideoEngineBuildHttpsUrl(url);
            [urlsReplaced addObject:url];
        }
        urls = urlsReplaced;
    }
    NSString *temFileHash = [info getValueStr:VALUE_FILE_HASH];
    NSString *filePath = nil;
    if (temFileHash &&
        temFileHash.length > 0 &&
        _dataSource &&
        [_dataSource respondsToSelector:@selector(cacheFilePathUsingMediaDataLoader:infoModel:)]) {

        filePath = [_dataSource cacheFilePathUsingMediaDataLoader:self.playSource.videoId infoModel:info];
        if (filePath && ![filePath containsString:temFileHash]) {
            CODE_ERROR(![filePath containsString:temFileHash]);
            filePath = nil;
        }
        if (filePath) {
            temFileHash = [TTVideoEngine _ls_keyFromFilePath:filePath];
        }
    }

    NSMutableString *extraInfo = [NSMutableString string];
    [extraInfo appendFormat:@"fileId=%@",info.fieldId?:@""];
    [extraInfo appendFormat:@"&bitrate=%zd",[info getValueInt:VALUE_BITRATE]];
    [extraInfo appendFormat:@"&pcrc=%@",info.p2pVerifyUrl?:@""];

    if(temFileHash.length){
        proxyUrl = [self _ls_proxyUrl:temFileHash rawKey:self.playSource.videoId urls:urls extraInfo:extraInfo filePath:filePath];

        TTVideoEngineLog(@"mediloader url:%@ \n", proxyUrl);
        if (proxyUrl) {
            [self _ls_addTask:self.playSource.videoId
                          key:temFileHash
                   resolution:temType
                     proxyUrl:proxyUrl
                decryptionKey:self.playSource.spade_a
                         info:info
                         urls:urls];
        } else { // Error
            TTVideoEngineLog(@"local server, key is null \n");
        }
    }
    return proxyUrl;
}

- (BOOL)isSupportSeamlessSwitch {
    if ([self.playSource supportDash]) {
        return YES;
    } else if ([self.playSource supportMP4]) {
        return self.bashEnable && [self isSupportUseBash];
    } else if ([self.playSource supportHLS]) {
        return self.hlsSeamlessSwitch && [self isSupportHLSSeamlessSwitch];
    }
    return NO;
}

- (BOOL)isSupportUseBash {
    if ([self.playSource videoMemString].length <= 0) {
        return NO;
    }
    if (([self.playSource supportDash] && (self.segmentFormatFlag & TTVideoEngineDashSegmentFlagFormatFMP4)) ||
        ([self.playSource supportMP4] && (self.segmentFormatFlag & TTVideoEngineDashSegmentFlagFormatMp4))) {
        return [self.playSource supportBash];
    }
    return NO;
}

- (BOOL)isSupportHLSSeamlessSwitch {
    if ([self.playSource videoMemString].length <= 0) {
        return NO;
    }
    return [self.playSource supportHLSSeamlessSwitch];
}

- (BOOL) isHDR10Video:(TTVideoEngineURLInfo *)info {
    if (info == nil)
        return NO;
    if (_hdr10VideoModelLowBound < 0|| _hdr10VideoModelHighBound < 0)
        return NO;
    NSString *qualityDescStr = [info getValueStr:VALUE_VIDEO_QUALITY_DESC];
    int qualityDesc = [qualityDescStr intValue];
    TTVideoEngineLog(@">HDR isHDR10Video: str:%@, quality:%d", qualityDescStr, qualityDesc);
    if (qualityDesc >= _hdr10VideoModelLowBound && qualityDesc <= _hdr10VideoModelHighBound)
        return YES;
    return NO;
}

- (void)_initSetMediaInfo {
    NSMutableArray<id<IVCABRVideoStream>> *videoStreamArr = [[NSMutableArray alloc] init];
    NSMutableArray<id<IVCABRAudioStream>> *audioStreamArr = [[NSMutableArray alloc] init];
    NSArray<TTVideoEngineURLInfo *> *mediaList = [self.playSource getVideoList];
    self.currentDownloadAudioBitrate = INT_MAX;
    for (TTVideoEngineURLInfo *info in mediaList) {
        if ([[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:@"video"]) {
            VCABRVideoStream *videoStream = [[VCABRVideoStream alloc] init];
            videoStream.streamId = [info getValueStr:VALUE_FILE_HASH];
            videoStream.bandwidth = (int)[info getValueInt:VALUE_BITRATE];
            videoStream.codec = [info getValueStr:VALUE_CODEC_TYPE];
            videoStream.width = (int)[info getValueInt:VALUE_VWIDTH];
            videoStream.height = (int)[info getValueInt:VALUE_VHEIGHT];
            videoStream.segmentDuration = 5000;
            if (videoStream.streamId) {
                [videoStreamArr addObject:videoStream];
            }
        }
        else {
            VCABRAudioStream *audioStream = [[VCABRAudioStream alloc] init];
            audioStream.streamId = [info getValueStr:VALUE_FILE_HASH];
            audioStream.bandwidth = (int)[info getValueInt:VALUE_BITRATE];
            audioStream.codec = [info getValueStr:VALUE_CODEC_TYPE];
            audioStream.segmentDuration = 5000;
            audioStream.sampleRate = -1;
            if (audioStream.streamId) {
                [audioStreamArr addObject:audioStream];
            }
            if (audioStream.bandwidth < self.currentDownloadAudioBitrate) {
                self.currentDownloadAudioBitrate = audioStream.bandwidth;
            }
        }
    }
    [self.abrModule setMediaInfo:videoStreamArr withAudio:audioStreamArr];
}

- (TTAVPreloaderItem*)getCurPreloaderItem {
    return self.playSource.preloadItem;
}

- (NSInteger)videoSizeForType:(TTVideoEngineResolutionType)type {
    return [self.playSource videoSizeOfType:type];
}

- (TTVideoEngineResolutionType)_getAutoResolution {
    //
    if (!self.playSource.supportResolutions) {
        return self.playSource.autoResolution;
    }
    //
    TTVideoEngineNetworkType networkType = TTVideoEngineNetworkTypeWifi;
    if ([self.dataSource respondsToSelector:@selector(networkType)]) {
        networkType = [self.dataSource networkType];
    }
    BOOL isWifiNetwork = (networkType == TTVideoEngineNetworkTypeWifi);
    TTVideoEngineResolutionType temType = self.playSource.autoResolution;
    return isWifiNetwork ? temType : TTVideoEngineResolutionTypeSD;
}

- (void)syncPauseVideo {
    BOOL async = NO;
    if (self.options.forceAsyncPause) {
        async = YES;
    }
    TTVideoRunOnMainQueue(^{
        [self.player pause:async];
    }, YES);
}

- (void)pauseVideo:(BOOL)async {
    TTVideoRunOnMainQueue(^{
        [self.player pause:async];
    }, YES);
}

- (void)stopVideo {
    TTVideoRunOnMainQueue(^{
        if (self.playDuration) {
            [self.playDuration stop];
        }
        [self.eventLogger logCurPos:self.currentPlaybackTime * 1000];
        [self.eventLogger logWatchDuration:[self durationWatched] * 1000];
        [self.eventLogger closeVideo];
        [self.player stop];
        [self.abrModule stop];
    }, YES);
}

- (void)seekToTime:(NSTimeInterval)currentPlaybackTime
switchingResolution:(BOOL)isSwitchingResolution
          complete:(void(^)(BOOL success))finised
    renderComplete:(void(^)(void)) renderComplete {
    TTVideoRunOnMainQueue(^{
        ENGINE_LOG(@"");
        @weakify(self)
        void(^seekFinish)(BOOL success) = ^(BOOL success){
            @strongify(self)
            !finised ?: finised(success);
            [self.eventLogger seekCompleted];
        };
        
        void(^renderSeekComplete)(BOOL isSeekInCached) = ^(BOOL isSeekInCached){
            @strongify(self)
            [self.eventLogger renderSeekComplete:isSeekInCached];
            !renderComplete ?: renderComplete();
        };
        
        if (self.isSwitchingDefinition) {
            self.beforeSeekTimeInterval = currentPlaybackTime;
            self.temSeekFinishBlock = seekFinish;
            self.temSeekRenderCompleteBlock = renderComplete;
        }
        
        else if (((self.state == TTVideoEngineStateUnknown) && self.playbackState ==
                    AVPlayerPlaybackStateStopped)
                   || (self.playbackState == TTVideoEnginePlaybackStateError)
                   || (self.isComplete && self.playbackState == AVPlayerPlaybackStateStopped)) {
            seekFinish(NO);
        }
        
        else {
            self.isSeeking = YES;
            NSTimeInterval curVideoPos = [self currentPlaybackTime];
            [self.player setCurrentPlaybackTime:currentPlaybackTime complete:seekFinish renderComplete:renderSeekComplete];
            [self.eventLogger logWatchDuration:[self durationWatched] * 1000];
            [self.eventLogger seekToTime:curVideoPos afterSeekTime:currentPlaybackTime
                          cachedDuration:self.playableDuration
                     switchingResolution:isSwitchingResolution];
            if (!isSwitchingResolution) {
                self.eventLogger.seekCount += 1;
            }
        }
    }, NO);
}

- (BOOL)isNSDictionary:(NSDictionary *)dict1 EqualToNSDictionary:(NSDictionary *)dict2 {
    if (dict1 == nil && dict2 == nil ) {
        return YES;
    }
    return [dict1 isEqual:dict2];
}

- (void)switchToDefinition:(TTVideoEngineResolutionType)definition params:(NSDictionary *)params{
    @weakify(self);
    TTVideoRunOnMainQueue(^{
        @strongify(self);
        if (!s_dict_is_empty(params) && !s_dict_is_empty(_currentParams) && !s_array_is_empty(sVideoEngineQualityInfos)) {
            NSString *value = [params objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
            NSString *lastValue = [_currentParams objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
            if(value != nil && lastValue != nil && [sVideoEngineQualityInfos containsObject:value] && [value isEqualToString:lastValue]){
                self.lastResolution = self.currentResolution;
                self.currentResolution = definition;
                self.currentParams = params;
                TTVideoEngineLog(@"switch to the same qualityDesc:%@, drop",value);
                return;
            }
        }
        if (_currentResolution == definition && [self isNSDictionary:params EqualToNSDictionary:_currentParams]) {
            TTVideoEngineLog(@"switch to the same definition:%lu, drop",(unsigned long)definition);
            return;
        }
        /// Need to save the scene, easy to recover after failure
        [TTVideoEngineCopy copyEngine:self];

        
        TTVideoEngineURLInfo *lastInfoVideo = nil;
        if (_preferSpdl4HDR) {
            [self.playSource setParamMap:self.currentParams];
            lastInfoVideo = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
        }
        
        self.lastResolution = self.currentResolution;
        self.currentResolution = definition;
        TTVideoEngineLog(@"will switch to to definition:%lu,from definition:%lu\n",(unsigned long)_currentResolution,(unsigned long)_lastResolution);
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
            TTVideoEngineLog(@"will switch to to params: key = %@ and value = %@\n", key, obj);
        }];
        NSInteger curPos = [self currentPlaybackTime] * 1000;
        [self.eventLogger switchToDefinition:[self _resolutionStringForType:_currentResolution]
                              fromDefinition:[self _resolutionStringForType:_lastResolution]
                                      curPos:curPos];
        [self.playSource setParamMap:params];
        if(![self.playSource hasVideo]){
            [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"audio"];
        }else{
            [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
        }
        self.currentResolution = self.playSource.currentResolution;

        if (self.lastResolution == self.currentResolution && [self isNSDictionary:params EqualToNSDictionary:self.currentParams]) {
            [self notifyDelegateSwitchComplete:YES];
            return;
        }
        self.currentParams = params;

        bool breakSemlessSwitch = NO;
        if (_preferSpdl4HDR && [self isSupportSeamlessSwitch]) {
            TTVideoEngineURLInfo *infoVideo = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
            if ([self isHDR10Video:lastInfoVideo] != [self isHDR10Video:infoVideo]) {
                breakSemlessSwitch = YES;
            }
            TTVideoEngineLog(@"breakSemlessSwitch: %d", breakSemlessSwitch);
        }

        if ([self isSupportSeamlessSwitch] && !breakSemlessSwitch) {
            NSMutableArray<TTVideoEngineURLInfo *> *urlinfos = [NSMutableArray array];
            TTVideoEngineURLInfo *infoAudio = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"audio"];
            if(infoAudio != nil){
                self.currentQualityDesc = [infoAudio getValueStr:VALUE_VIDEO_QUALITY_DESC];
                TTVideoEngineLog(@"audio switch to quality desc:%@",self.currentQualityDesc);
                [urlinfos addObject:infoAudio];
            }
            TTVideoEngineURLInfo *infoVideo = [self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"];
            if(infoVideo != nil){
                self.currentQualityDesc = [infoVideo getValueStr:VALUE_VIDEO_QUALITY_DESC];
                TTVideoEngineLog(@"video switch to quality desc:%@",self.currentQualityDesc);
                [urlinfos addObject:infoVideo];
            }
            [self.eventLogger setCurrentQualityDesc:self.currentQualityDesc];
            if (urlinfos.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:usingUrlInfos:)]) {
                [self.delegate videoEngine:self usingUrlInfos:urlinfos];
            }
            if (self.playbackState != TTVideoEnginePlaybackStatePaused) {
                TTMediaStreamType streamType = TTMediaStreamTypeVideo;
                if(![self.playSource hasVideo]){
                    streamType = TTMediaStreamTypeAudio;
                }
                self.lastPlaybackTime = kInvalidatePlayTime;
                [self switchBitrate:[self.playSource bitrateForDashSourceOfType:self.currentResolution] type:streamType];
                return;
            }

        } else {
            self.dashEnabled = NO;
        }

        // Not dash.
        _isSwitchingDefinition = YES;
        _lastPlaybackTime = [self.player currentPlaybackTime];
        if (self.playDuration) {
            [self.playDuration stop];
        }
        self.state = TTVideoEngineStateFetchingInfo;
        [self _startToPlay];
    }, NO);
}

- (void)movieStalled {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineStalledExcludeSeek:)]) {
        [self.delegate videoEngineStalledExcludeSeek:self];
    }
    if (!self.autoModeEnabled) {
        return;
    }
    self.bufferCount++;
    NSArray<NSNumber *> *supportedResolutionTypes = [self supportedResolutionTypes];
    TTVideoEngineResolutionType minResolution = TTVideoEngineResolutionTypeFullHD;
    for (NSNumber *resolutionNumber in supportedResolutionTypes) {
        TTVideoEngineResolutionType resolution = [resolutionNumber integerValue];
        if (resolution < minResolution) {
            minResolution = resolution;
        }
    }
    BOOL shouldReduceResolution = self.bufferCount >= kTTVideoEngineAutoModeTolerance
    && self.currentResolution != minResolution
    && !self.isSwitchingDefinition
    && !self.isSuggestingReduceResolution
    && supportedResolutionTypes.count != 1;
    if (shouldReduceResolution) {
        self.bufferCount = 0;
        self.isSuggestingReduceResolution = YES;
        if (self.resolutionDelegate && [self.resolutionDelegate respondsToSelector:@selector(suggestReduceResolution:)]) {
            [self.resolutionDelegate suggestReduceResolution:self];
        }
        self.isSuggestingReduceResolution = NO;
    }
}

- (void)switchBitrate:(NSInteger)bitrate type:(TTMediaStreamType)type {
    @weakify(self)
    self.isSeamlessSwitching = YES;
    [self.player switchStreamBitrate:bitrate
                              ofType:type
                          completion:^(BOOL success) {
        @strongify(self)
        if (!self) {
            return;
        }
        [self switchDefinitionCompleted:success];
    }];
}

- (void)_removeCacheFile {
    NSArray<TTVideoEngineURLInfo *> *infolist = [self.playSource getVideoList];
    for (TTVideoEngineURLInfo *info in infolist) {
        [TTVideoEngine _ls_forceRemoveFileCacheByKey:[info getValueStr:VALUE_FILE_HASH]];
    }
}

- (void)_removeMdlCacheFile {
    for(NSInteger i = self.fileHashArray.count - 1; i >= 0; i--){
        [TTVideoEngine _ls_forceRemoveFileCacheByKey:self.fileHashArray[i]];
    }
}

- (void)didReceiveError:(NSError *)error {
    //
    BOOL nIsRetrying = self.isRetrying;
    [self logUrlConnectToFirstFrameTime];
    if (self.isUserStopped) {
        self.state = TTVideoEngineStateUnknown;
        return;
    }
    NSInteger apiVersionWithError = self.apiVersion;
    if (!self.isRetrying) {
        if (self.startTime != 0) {
            self.lastPlaybackTime = self.startTime;
        } else if (self.state == TTVideoEngineStatePlayerRunning || self.state == TTVideoEngineStateError) {// player did readyToPlay
            if (_hasShownFirstFrame) {
                self.lastPlaybackTime = [self.player currentPlaybackTime];
            }
        }
    }
    self.errorCount++;
    self.accumulatedErrorCount++;

    TTVideoEngineLogE(@"videoEngine Failed:%@,%ld,errorCount:%lu",error.domain,(long)error.code,(unsigned long)self.errorCount);

    [self.playSource setParamMap:nil];
    if (self.playSource.isSingleUrl) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        [userInfo addEntriesFromDictionary:@{@"isDirectURL": @YES}];
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
    }

    void (^defaultBlock)() = ^{
        self.state = TTVideoEngineStateError;
        [self _buryDataWhenSendOneplayEvent];
        [self.eventLogger movieFinishError:error currentPlaybackTime:self.currentPlaybackTime apiver:self.apiVersion];
        self.playerIsPreparing = NO;
        self.didCallPrepareToPlay = NO;
        self.hasPrepared = NO;
        if (self.isSwitchingDefinition) {
            [self switchDefinitionCompleted:NO];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineDidFinish:error:)]) {
                [self.delegate videoEngineDidFinish:self error:error];
            }
        }
        self.errorCount = 0;
        self.playerUrlDNSRetryCount = 0;
        self.accumulatedErrorCount = 0;
    };
    
    if (error.code == TTVideoEngineErrorUrlInvalid) {
        defaultBlock();
        return;
    }

    // /** Do not try more */
    if (self.errorCount >= kTTVideoEngineMaxErrorCount) {
        TTVideoEngineLogE(@"videoEngine retry failed");
        defaultBlock();
        return;
    }
    if (self.accumulatedErrorCount >= self.maxAccumulatedErrCount) {
        defaultBlock();
        return;
    }
    // /** retry strategy */
    TTVideoEngineRetryStrategy retryStrategy = TTVideoEngineGetStrategyFrom(error, self.playerUrlDNSRetryCount);
    if (error.code == TTVideoEngineErrorInvalidRequest || error.code == TTVideoEngineErrorAuthFail) {
        if (self.apiVersion == TTVideoEnginePlayAPIVersion2 && (self.auth != nil && self.auth.length > 0)) {
            self.apiVersion = TTVideoEnginePlayAPIVersion1;
        }else if(self.apiVersion == TTVideoEnginePlayAPIVersion3){
            retryStrategy = TTVideoEngineRetryStrategyFetchInfo;
        }else {
            defaultBlock();
            return;
        }
    }
    
    if (error.code == TTVideoEngineErrorHttpForbidden) {
        if (self.playSource.isSingleUrl) {
            [self.eventLogger setIntOption:LOGGER_OPTION_EXPIRE_PLAY_CODE value:EXPIRE_PLAY_CODE_URL];
        } else {
            [self.eventLogger setIntOption:LOGGER_OPTION_EXPIRE_PLAY_CODE value:EXPIRE_PLAY_CODE_VM];
        }
    }
    
    if (!self.playSource.canFetch && self.playSource.isSingleUrl && self.errorCount > 1) {
        defaultBlock();
        return;
    }

    // Trying
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:retryForError:)]) {
        [self.delegate videoEngine:self retryForError:error];
    }
    self.isRetrying = YES;

    BOOL errorAtPlaySource = (TTVideoEngineRetryStrategyRestartPlayer != retryStrategy);
    if (errorAtPlaySource) {
        retryStrategy = [self.playSource retryStrategyForRetryCount:self.errorCount];
    }
    if (self.errorCount == kTTVideoEngineMaxErrorCount - 1 && self.playSource.canFetch) {
        if (self.apiVersion == TTVideoEnginePlayAPIVersion2 && (self.auth != nil && self.auth.length > 0)) {
            self.apiVersion = TTVideoEnginePlayAPIVersion1;
        }
        retryStrategy = TTVideoEngineRetryStrategyFetchInfo;
    }

    if (TTVideoEngineIsHijackError(error.code)) {
        TTVideoEngineLog(@"is hijack, error code is %@",@(error.code));
        
        [self.eventLogger setHijackCode:error.code];

        // hijack error retry is not enabled, just notify error message
        if (!self.hijackRetryEnable) {
            defaultBlock();
            return;
        }

        // engine hijack retry
        // 2. enable http dns
        sVideoEngineDnsTypes = @[@(self.hijackRetryMainDnsType),@(self.hijackRetryBackupDnsType)];

        // medialoader hijack retry
        // 1. clear hijack cache
        [self _removeCacheFile];
        // 2. clear mdl dns cache
        [TTVideoEngine ls_clearAllDNSCache];
        // 3. enable http dns
        [TTVideoEngine ls_mainDNSParseType:self.hijackRetryMainDnsType backup:self.hijackRetryBackupDnsType];

        if (!self.isHijackRetried && [self.playSource supportSSL]) {
            self.isHijackRetried = YES;
            // enable https
            self.retryEnableHttps = YES;
            retryStrategy = TTVideoEngineRetryStrategyChangeURL;
        } else {
            self.isHijackRetried = NO;
            defaultBlock();
            return;
        }
    }
    
    if (self.drmRetry && TTVideoEngineIsDrmError(error.code)) {
        self.drmType = TTVideoEngineDrmNone;
        retryStrategy = TTVideoEngineRetryStrategyRestartPlayer;
    }
    
    // check error code to clear mdl cache
    if(self.enableClearMdlCache && TTVideoEngineIsDataError(error.code)) {
        [self _removeCacheFile];
    }
    
    // /** log */
    TTVideoEngineLog(@"retry strategy:%@", TTVideoEngineGetStrategyName(retryStrategy));
    if (apiVersionWithError != self.apiVersion) {
        TTVideoEngineLog(@"APIVersion rollback from TTVideoEnginePlayAPIVersion%d to TTVideoEnginePlayAPIVersion%d errorCount:%d",apiVersionWithError,self.apiVersion,self.errorCount);
    }
    if (retryStrategy != TTVideoEngineRetryStrategyNone) {
        [self.eventLogger moviePlayRetryWithError:error strategy:retryStrategy apiver:apiVersionWithError];
        
        if (nIsRetrying) {
            [self.eventLogger moviePlayRetryEnd];
        }
        NSInteger curPos = [self currentPlaybackTime] * 1000;
        [self.eventLogger moviePlayRetryStartWithError:error strategy:retryStrategy curPos:curPos];
    }

    // /** Action */
    switch (retryStrategy) {
        case TTVideoEngineRetryStrategyNone:
            defaultBlock();
            break;
        case TTVideoEngineRetryStrategyFetchInfo:{
            /// remove disk cache.
            [TTVideoEngineModelCache.shareCache removeItemFromDiskForKey:self.playSource.videoId];
            [self fetchVideoInfo];
        }
            break;
        case TTVideoEngineRetryStrategyChangeURL:
            [self tryNextURL];
            break;
        case TTVideoEngineRetryStrategyRestartPlayer:
            [self _startToPlay];
            break;
        default:
            break;
    }
}

- (void)updateURLArray {
    NSMutableArray *urlArray = [NSMutableArray array];
    NSDictionary *temDict = self.urlIPDict.copy;
    for (NSString* urlstr in temDict.allKeys) {
        [urlArray addObject:@{@"url": urlstr ?:@"",
                              @"ip": [temDict objectForKey:urlstr] ?:@"",
                              @"dns": [self.dnsParser getTypeStr] ?:@"",
                              @"dns_cache_open": self.dnsParser.isUseDnsCache?@(1):@(0)}];
    }
    [self.eventLogger setURLArray:urlArray];
}

- (void)notifyDelegateSwitchComplete:(BOOL)success {
    if (self.configResolutionComplete) {
        self.configResolutionComplete(success, self.currentResolution);
        self.configResolutionComplete = nil;
    }
}

- (void)switchDefinitionCompleted:(BOOL)success {
    BOOL isSeam = !self.isSeamlessSwitching;
    self.isSwitchingDefinition = NO;
    self.isSeamlessSwitching = NO;
    TTVideoEngineLog(@"switch definition complete:%d, to resolution:%lu",success,(unsigned long)self.currentResolution);
    [self.eventLogger showedOneFrame];
    if (!success) {
        TTVideoEngineResolutionType resolution = self.currentResolution;
        self.currentResolution = self.lastResolution;
        /// Recovery scene
        [TTVideoEngineCopy assignEngine:self];

        [self.eventLogger setCurrentDefinition:[self _resolutionStringForType:self.currentResolution]
                                lastDefinition:[self _resolutionStringForType:resolution]];
    }else{
          [self.eventLogger switchResolutionEnd:isSeam];
    }

    [self notifyDelegateSwitchComplete:success];
}

- (void)seekToLastPlaytimeAfterSwitchResolution {
    if (self.state != TTVideoEngineStatePlayerRunning) {
        return;
    }
    if ((self.isSwitchingDefinition && !self.smoothlySwitching) || self.isRetrying) {
        if (self.isSwitchingDefinition) {
            TTVideoEngineLog(@"did switch to resolution:%lu",(unsigned long)self.currentResolution);
            [self notifyDelegateSwitchComplete:YES];
        }

        if (fabs(self.lastPlaybackTime) > 0.1 && !self.isOwnPlayer) {
            @weakify(self)
            [self seekToTime:self.lastPlaybackTime
         switchingResolution:self.isSwitchingDefinition
                    complete:^(BOOL success) {
                @strongify(self)
                if (!self) {
                    return;
                }
                [self.eventLogger showedOneFrame];
            } renderComplete:nil];
        }

        self.isSwitchingDefinition = NO;
        self.isRetrying = NO;
        [self.eventLogger moviePlayRetryEnd];

        /// seek when switch definition
        if (self.beforeSeekTimeInterval > kInvalidatePlayTime) {/// did seek
            [self seekToTime:self.beforeSeekTimeInterval switchingResolution:NO complete:self.temSeekFinishBlock renderComplete:self.temSeekRenderCompleteBlock];
            self.beforeSeekTimeInterval = kInvalidatePlayTime;
            self.temSeekFinishBlock = nil;
            self.temSeekRenderCompleteBlock = nil;
        }
    }
}

- (void)logFetchInfoError:(NSError *)error {
    [self.eventLogger fetchedVideoURL:nil
                                error:error
                           apiVersion:self.apiVersion];
}

- (void)logFetchedVideoInfo:(TTVideoEngineInfoModel *)infoModel {
    if (self.playSource.isLivePlayback) {
        return;
    }
    NSInteger sizeFor360p = 0;
    NSInteger sizeFor480p = 0;
    NSInteger sizeFor720p = 0;
    NSInteger sizeFor1080p = 0;
    TTVideoEngineURLInfo *video360 = nil;
    TTVideoEngineURLInfo *video480 = nil;
    TTVideoEngineURLInfo *video720 = nil;
    TTVideoEngineURLInfo *video1080 = nil;

    if (infoModel != nil) {
        video360 = [infoModel videoInfoForType:TTVideoEngineResolutionTypeSD];
        video480 = [infoModel videoInfoForType:TTVideoEngineResolutionTypeHD];
        video720 = [infoModel videoInfoForType:TTVideoEngineResolutionTypeFullHD];
        video1080 = [infoModel videoInfoForType:TTVideoEngineResolutionType1080P];
    }
    if (video360) {
        sizeFor360p = [video360 getValueNumber:VALUE_SIZE].integerValue;
    }
    if (video480) {
        sizeFor480p = [video480 getValueNumber:VALUE_SIZE].integerValue;
    }
    if (video720) {
        sizeFor720p = [video720 getValueNumber:VALUE_SIZE].integerValue;
    }
    if (video1080) {
        sizeFor1080p = [video1080 getValueNumber:VALUE_SIZE].integerValue;
    }
    NSTimeInterval mediaDuration = [[infoModel getValueNumber:VALUE_VIDEO_DURATION] doubleValue] * 1000;
    NSArray *codecs = [infoModel codecTypes];
    NSString *codecType = [codecs containsObject:kTTVideoEngineCodecByteVC2] ? kTTVideoEngineCodecByteVC2 : ([codecs containsObject:kTTVideoEngineCodecByteVC1] ? kTTVideoEngineCodecByteVC1 : kTTVideoEngineCodecH264);
    
    NSArray<TTVideoEngineURLInfo *> *urlInfoList = [infoModel getValueArray:VALUE_VIDEO_LIST];
    NSMutableDictionary *bitrateMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *fileHashBitrateMap = [NSMutableDictionary dictionary];
    NSMutableArray *videoBitrateArray = [NSMutableArray array];
    NSMutableArray *audioBitrateArray = [NSMutableArray array];
    for (NSInteger i = 0; i < urlInfoList.count; i++) {
        TTVideoEngineURLInfo *urlInfo = [urlInfoList objectAtIndex:i];
        NSInteger bitrate = [urlInfo getValueInt:VALUE_BITRATE];
        bitrateMap[[NSString stringWithFormat:@"%d",bitrate]] = @(i);
        NSString *fileHash = [urlInfo getValueStr:VALUE_FILE_HASH];
        if (!isEmptyStringForVideoPlayer(fileHash)) {
            fileHashBitrateMap[fileHash] = @(bitrate);
        }
        NSString *mediaType = [urlInfo getValueStr:VALUE_MEDIA_TYPE];
        if ([mediaType isEqualToString:@"video"]) {
            [videoBitrateArray addObject:@(bitrate)];
        } else if ([mediaType isEqualToString:@"audio"]) {
            [audioBitrateArray addObject:@(bitrate)];
        }
    }

    [self.eventLogger fetchedVideoURL:@{kTTVideoEngineVideoDurationKey:@(mediaDuration),
                                        kTTVideoEngineVideoSizeKey: @{
                                                @"360p": @(sizeFor360p),
                                                @"480p": @(sizeFor480p),
                                                @"720p": @(sizeFor720p),
                                                @"1080p": @(sizeFor1080p),
                                                },
                                        kTTVideoEngineVideoCodecKey: codecType ?: @"",
                                        kTTVideoEngineVideoTypeKey: [infoModel videoType] ?: @"",
                                        kTTVideoEngineVideoBitrateComppressMap: bitrateMap,
                                        kTTVideoEngineVideoBitrates : videoBitrateArray,
                                        kTTVideoEngineAudioBitrates : audioBitrateArray,
                                        kTTVideoEngineFileHashAndBitrate : fileHashBitrateMap
                                        }
                                error:nil
                           apiVersion:self.apiVersion];
    //
    NSInteger bitrate = [self.playSource bitrateForDashSourceOfType:self.currentResolution];
    [self.eventLogger logBitrate:bitrate];
    
    if (infoModel != nil && infoModel.videoStyle != nil) {
        if (infoModel.videoStyle.videoStyle == 1) {
            [self.eventLogger setIntOption:LOGGER_OPTION_VIDEO_STYLE value:infoModel.videoStyle.videoStyle];
            [self.eventLogger setIntOption:LOGGER_OPTION_DIMENTION value:infoModel.videoStyle.dimension];
            [self.eventLogger setIntOption:LOGGER_OPTION_PROJECTION_MODEL value:infoModel.videoStyle.projectionModel];
            [self.eventLogger setIntOption:LOGGER_OPTION_VIEW_SIZE value:infoModel.videoStyle.viewSize];
        }
    }
}

- (void)logUserCancelled {
    [self.eventLogger userCancelled];
}

- (void)logUrlConnectToFirstFrameTime {
    if (self.player && (!_hasShownFirstFrame || !_hasAudioRenderStarted) && (!self.looping || self.eventLogger.loopCount == 0)) {
        //record the last time before first frame
        [self.eventLogger recordFirstFrameMetrics:self.player];
    }
}

- (void)_buryDataWhenPrepareToDisplay {
    [self.eventLogger setPrepareEndTime:(long long)([[NSDate date] timeIntervalSince1970]*1000)];
    NSInteger audio_name_id = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioCodecModName];
    NSInteger video_name_id = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoCodecModName];
    [self.eventLogger logCodecNameId:audio_name_id video:video_name_id];
    
    NSString *videoName = [self.player getStringValueForKey:KeyIsVideoCodec];
    NSString *audioName = [self.player getStringValueForKey:KeyIsAudioCodec];
    NSInteger videoCodecId = [self.player getIntValueForKey:KeyIsVideoCodecId];
    //视频编码格式为bytevc1和bytevc2，要修改名字
    if (videoCodecId == BYTEVC1CodecId) {
        videoName = @"bytevc1";
    } else if (videoCodecId == BYTEVC2CodecId) {
        videoName = @"bytevc2";
    }
    //空字符串兜底
    if (!videoName || videoName.length == 0) {
        videoName = @"unknown_codec";
    }
    if (!audioName || audioName.length == 0) {
        audioName = @"unknown_codec";
    }
    [self.eventLogger logCodecName:audioName video:videoName];
}

- (void)_buryDataWhenPlayerPrepared {
    NSInteger decoderType = (self.byteVC1Enabled || self.codecType == TTVideoEngineByteVC1) && self.ksyByteVC1Decode;
    [self.eventLogger setPlayerSourceType:self.playSource.isLivePlayback];
    [self.eventLogger setIp:[_player getIpAddress]];
    [self.eventLogger setAVSyncStartEnable:_avSyncStartEnable ? 1:0];
    NSInteger audio_name_id = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioCodecModName];
    NSInteger video_name_id = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoCodecModName];
    [self.eventLogger logCodecNameId:audio_name_id video:video_name_id];
    NSInteger format_type = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMediaFormatType];
    [self.eventLogger logFormatType:format_type];
    //
    NSTimeInterval mediaDuration = self.duration * 1000;
    if (mediaDuration > 1.0) {
        [self.eventLogger updateMediaDuration:mediaDuration];
    }
    [self.eventLogger logBitrate:self.bitrate];
    [self.eventLogger logAudioBitrate:self.audioBitrate];
    
    /// first frame metrics
    [self logUrlConnectToFirstFrameTime];
    
    NSInteger video_track_enabled = [_player getIntValueForKey:KeyIsVideoTrackEnable];
    NSInteger audio_track_enabled = [_player getIntValueForKey:KeyIsAudioTrackEnable];
    if (video_track_enabled == 0) {
        [self.eventLogger setIntOption:LOGGER_OPTION_VIDEO_STREAM_DISABLED value:1];
    } else {
        [self.eventLogger setIntOption:LOGGER_OPTION_VIDEO_STREAM_DISABLED value:0];
    }
    if (audio_track_enabled == 0) {
        [self.eventLogger setIntOption:LOGGER_OPTION_AUDIO_STREAM_DISABLED value:1];
    } else {
        [self.eventLogger setIntOption:LOGGER_OPTION_AUDIO_STREAM_DISABLED value:0];
    }
    
    if (_renderEngine == TTVideoEngineRenderEngineSBDLayer) {
        switch (self.player.finalRenderEngine) {
            case TTVideoEngineRenderEngineOpenGLES:
                [self.eventLogger setRenderType:kTTVideoEngineRenderTypeOpenGLES];
                break;
            case TTVideoEngineRenderEngineMetal:
                [self.eventLogger setRenderType:kTTVideoEngineRenderTypeMetal];
                break;
            case TTVideoEngineRenderEngineOutput:
                [self.eventLogger setRenderType:kTTVideoEngineRenderTypeOutput];
                break;
            case TTVideoEngineRenderEngineSBDLayer:
                [self.eventLogger setRenderType:kTTVideoEngineRenderTypeSBDL];
                break;
            default:
                [self.eventLogger setRenderType:kTTVideoEngineRenderTypeSBDL];
                break;
        }
    }
    
    int64_t moov_pos = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMoovPosition];
    [self.eventLogger setInt64Option:LOGGER_OPTION_MOOV_POSITION value:moov_pos];
    int64_t mdat_pos = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMdatPosition];
    [self.eventLogger setInt64Option:LOGGER_OPTION_MDAT_POSITION value:mdat_pos];
    
    int64_t video_stream_duration = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoStreamDuration];
    int64_t audio_stream_duration = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioStreamDuration];
    [self.eventLogger setInt64Option:LOGGER_OPTION_VIDEO_STREAM_DURATION value:video_stream_duration];
    [self.eventLogger setInt64Option:LOGGER_OPTION_AUDIO_STREAM_DURATION value:audio_stream_duration];
    
    id readHeaderDuration = [self.eventLogger getMetrics:kTTVideoEngineReadHeaderDuration];
    id readFirstVideoPktDuration = [self.eventLogger getMetrics:kTTVideoEngineReadFirstDataDuration];
    id firstFrameDecodedDuration = [self.eventLogger getMetrics:kTTVideoEngineFirstFrameDecodeDuration];
    id firstFrameRenderDuration = [self.eventLogger getMetrics:kTTVideoEngineFirstRenderDuration];
    id playbackBufferEndDuration = [self.eventLogger getMetrics:kTTVideoEnginePlaybackBuffingDuration];
    id firstFrameDuration = [self.eventLogger getMetrics:kTTVideoEngineFirstFrameDuration];
    self.firstFrameMetrics = @{kTTVideoEngineReadHeaderDuration:readHeaderDuration?:@(0),
                               kTTVideoEngineReadFirstDataDuration:readFirstVideoPktDuration?:@(0),
                               kTTVideoEngineFirstFrameDecodeDuration:firstFrameDecodedDuration?:@(0),
                               kTTVideoEngineFirstRenderDuration:firstFrameRenderDuration?:@(0),
                               kTTVideoEnginePlaybackBuffingDuration:playbackBufferEndDuration?:@(0),
                               kTTVideoEngineFirstFrameDuration:firstFrameDuration?:@(0)};
}

- (void)_buryDataWhenUserWillLeave {
    int64_t av_gap = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMaxAVPosGap];
    [self.eventLogger setInt64Option:LOGGER_OPTION_VIDEO_AUDIO_POSITION_GAP value:av_gap];
    CGFloat videoutFPS = [self.player getFloatValueForKey:KeyIsVideoOutFPS];
    NSInteger videoDecoderFPS = [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDecoderOutputFps];
    BOOL enableNNSR = [self.player getIntValueForKey:KeyIsEnableVideoSR];
    int containerFPS = [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsContainerFPS];
    int64_t videoBufferLen = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoBufferLength];
    int64_t audioBufferLen = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioBufferLength];
    [self.eventLogger setInt64Option:LOGGER_OPTION_VIDEO_BUFFER_LEN value:videoBufferLen];
    [self.eventLogger setInt64Option:LOGGER_OPTION_AUDIO_BUFFER_LEN value:audioBufferLen];
    //subtitle event
    int64_t sub_did_load_t = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsSubFirstLoadTime];
    [self.eventLogger setInt64Option:LOGGER_OPTION_TIME_SUB_DID_LOAD value:sub_did_load_t];
    
    //mask event
    int64_t mask_open_t = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMaskStreamOpenTime];
    int64_t mask_opened_t = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMaskStreamOpenedTime];
    [self.eventLogger setMaskOpenTimeStamp:mask_open_t];
    [self.eventLogger setMaskOpenedTimeStamp:mask_opened_t];
    
    //audio frame dropping count
    int audioDropCnt = [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioFrameDropCnt];
    [self.eventLogger setAudioDropCnt:audioDropCnt];
    
    [self.eventLogger setIntOption:LOGGER_OPTION_CONTAINER_FPS value:containerFPS];
    [self.eventLogger setVideoOutFPS:videoutFPS];
    [self.eventLogger setVideoDecoderFPS:videoDecoderFPS];
    [self.eventLogger setEnableNNSR:enableNNSR];
    [self.eventLogger setTag:self.logInfoTag];
    [self.eventLogger setSubtag:self.subtag];
    [self.eventLogger logWatchDuration:[self durationWatched] * 1000];
    [self.eventLogger logCurPos:self.currentPlaybackTime * 1000];
    CGFloat averageDownLoadSpeed = 0.0;
    CGFloat averagePredictSpeed = 0.0;
    Class networkPredictClassAction = [self networkPredictorActionClass];
    if ([networkPredictClassAction respondsToSelector:@selector(getAverageDownLoadSpeed)]) {
        averageDownLoadSpeed = [networkPredictClassAction getAverageDownLoadSpeed];
    }
    if ([networkPredictClassAction respondsToSelector:@selector(getAveragePredictSpeed)]) {
        averagePredictSpeed = [networkPredictClassAction getAveragePredictSpeed];
    }
    [self.eventLogger setAbrInfo:@{@"abr_probe_count": @(self.abrProbeCount),
                                    @"abr_switch_count": @(self.abrSwitchCount),
                                    @"abr_average_bitrate": @(self.abrAverageBitrate),
                                    @"abr_average_play_speed": @(self.abrAveragePlaySpeed),
                                    @"abr_used": @(self.isUsedAbr),
                                    @"abr_avg_download" : @(averageDownLoadSpeed),
                                   @"abr_avg_predict" : @(averagePredictSpeed),
                                   @"abr_avg_diff_abs" : @(self.abrDiddAbs)}];
    NSInteger video_track_enabled = [_player getIntValueForKey:KeyIsVideoTrackEnable];
    NSInteger audio_track_enabled = [_player getIntValueForKey:KeyIsAudioTrackEnable];
    if (video_track_enabled == 0) {
        [self.eventLogger setIntOption:LOGGER_OPTION_VIDEO_STREAM_DISABLED value:1];
    } else {
        [self.eventLogger setIntOption:LOGGER_OPTION_VIDEO_STREAM_DISABLED value:0];
    }
    if (audio_track_enabled == 0) {
        [self.eventLogger setIntOption:LOGGER_OPTION_AUDIO_STREAM_DISABLED value:1];
    } else {
        [self.eventLogger setIntOption:LOGGER_OPTION_AUDIO_STREAM_DISABLED value:0];
    }
    [self logUrlConnectToFirstFrameTime];
    NSString *playerLog = [self.player getStringValueForKey:KeyIsPlayerLogInfo];
    if (playerLog) {
        self.playerLog = playerLog;
        [self.eventLogger logPlayerInfo:playerLog];
    }
    NSInteger frameDropCount = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsFrameDropCount];
    [self.eventLogger setIntOption:LOGGER_OPTION_FRAME_DROP_COUNT value:frameDropCount];
    NSInteger colorTrc = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsColorTrc];
    NSInteger pixelFormat = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsPixelFormat];
    [self.eventLogger setIntOption:LOGGER_OPTION_COLOR_TRC value:colorTrc];
    [self.eventLogger setIntOption:LOGGER_OPTION_PIXEL_FORMAT value:pixelFormat];
}

- (void)_buryDataWhenSendOneplayEvent {
    if ([NSThread isMainThread]) {
        if (self.playerView) {
            NSInteger hidden = 0;
            if (self.playerView.hidden) {
                hidden = 1;
            }
            if (!self.playerView.superview) {
                hidden = 2;
            }
            [self.eventLogger setIntOption:LOGGER_OPTION_PLAYERVIEW_HIDDEN_STATE value:hidden];
            [self.eventLogger playerViewBoundsChange:self.playerView.bounds];
        }
        [self.eventLogger recordBrightnessInfo];
    }
    
    NSInteger colorSpace = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsColorSpace];
    NSInteger colorPri = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsColorPrimaries];
    [self.eventLogger setIntOption:LOGGER_OPTION_COLOR_SPACE value:colorSpace];
    [self.eventLogger setIntOption:LOGGER_OPTION_COLOR_PRIMARIES value:colorPri];
    [self _reportPreloadGearData];
    int videoFrameRate = [self.player getIntValueForKey:KeyIsContainerFPS];
    int bufferingThresholdSize = [self.player getIntValueForKey:KeyIsBufferingThresholdSize];
    if (videoFrameRate > 0 && bufferingThresholdSize > 0) {
        int netblockBufferthreshold = (int)(((float)bufferingThresholdSize / videoFrameRate) * 1000.0);
        [self.eventLogger setIntOption:LOGGER_OPTION_BUFFERING_THRESHOLD_SIZE value:netblockBufferthreshold];
    }
}

#pragma mark -
#pragma mark TTDNSProtocol

- (void)parser:(id)dns didFinishWithAddress:(NSString *)ipAddress error:(NSError *)error {
    if (ipAddress && !error) {
        TTVideoEngineLog(@"parsing DNS success, hostame:%@,ipAddress:%@",self.currentHostnameURL,ipAddress);
        int64_t curT = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        [self.eventLogger setInt64Option:LOGGER_OPTION_TIME_DNS_END value:curT];
        [self updateURLWithIP:ipAddress];
        [self playVideo];
        //
    } else {

        [self didReceiveError:error];
    }
}

- (void)parser:(id)dns didFailedWithError:(NSError *)error {
    if (!error) {
        return;
    }

    [self.eventLogger firstDNSFailed:error];
}

- (void)parserDidCancelled {
    [self logUserCancelled];
}

#pragma mark -
#pragma mark TTPlayerStateChangeDelegate

- (void)playbackStateDidChange:(TTVideoEnginePlaybackState)state {
    TTVideoEngineLog(@"playback state:%@",playbackStateString(state));
    if (state == TTVideoEnginePlaybackStatePlaying) {
        self.duration = [self.player duration];
        if (!_hasShownFirstFrame) {
            [self.eventLogger showedOneFrame];
            [self logUrlConnectToFirstFrameTime];
            [self.eventLogger useHardware:self.hardwareDecode];
            [self _syncPlayInfoToMdlForKey:VEKPlayInfoRenderStart Value:1];
            _hasShownFirstFrame = YES; //need behind logUrlConnectToFirstFrameTime
        }
        if (self.playDuration && _lastUserAction == TTVideoEngineUserActionPlay) {
            [self.playDuration start];
        }
    }

    self.playbackState = state;
    TTVideoRunOnMainQueue(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:playbackStateDidChanged:)]) {
            [self.delegate videoEngine:self playbackStateDidChanged:state];
        }
    }, NO);

    if (state == TTVideoEnginePlaybackStatePaused) {
        [self.eventLogger playerPause];
    }else if (state == TTVideoEnginePlaybackStatePlaying){
        [self.eventLogger playerPlay];
    }
    [TTVideoEnginePool.instance engine:self.hash stateChange:state];
}

- (void)loadStateDidChange:(TTVideoEngineLoadState)state stallReason:(TTVideoEngineStallReason)reason {
    TTVideoEngineLog(@"load state:%s stall reason:%s",loadStateGetName(state),stallReasonGetName(reason));

    self.loadState = state;
    self.stallReason = reason;
    NSMutableDictionary *extraInfo = nil;

    if (state == TTVideoEngineLoadStateStalled) {
        if (self.playDuration) {
            [self.playDuration stop];
        }
        extraInfo = [NSMutableDictionary dictionary];
        TTVideoEngineStallAction action = TTVideoEngineStallActionNone;
        if (_isSeeking) {
            action = TTVideoEngineStallActionSeek;
        }
        if (_isSwitchingDefinition || _isSeamlessSwitching) {
            action = TTVideoEngineStallActionSwitch;
        }
        [extraInfo setObject:@(action) forKey:TTVideoEngineBufferStartAction];
        [extraInfo setObject:@(reason) forKey:TTVideoEngineBufferStartReason];
        if (TTVideoEnginePreloader.hasRegistClass) {
            [self _ls_cancelPreload:TTVideoEnginePreloadStalledCancel info:nil];
        }
        
        if (!_isSeeking) {
            if (_hasShownFirstFrame) {
                NSInteger curPos = [self currentPlaybackTime] * 1000;
                [self.eventLogger movieStalledAfterFirstScreen:reason curPos:curPos];
                [self movieStalled];
                if(reason == TTVideoEngineStallReasonNetwork) {
                    NSInteger reason = [_eventLogger getMovieStalledReason];
                    [self _syncPlayInfoToMdlForKey:VEKPlayInfoBufferingStart Value:reason];
                }
            } else if (_enableEnterBufferingDirectly) {
                int64_t curT = [[NSDate date] timeIntervalSince1970] * 1000;
                [self.eventLogger setInt64Option:LOGGER_OPTION_BUFFER_START_BEFORE_PLAY value:curT];
            }
        }
        
        if (self.player != nil) {
            int64_t maxSamplePosBack = [self.player getInt64ValueForKey:KeyIsMaxSamplePosBackDiff];
            if (maxSamplePosBack > 0) {
                [_eventLogger onAVInterlaced:maxSamplePosBack];
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:onAVBadInterlaced:)]) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setObject:@(maxSamplePosBack) forKey:@"diff"];
                    [self.delegate videoEngine:self onAVBadInterlaced:dict];
                }
            }
        }

        [self.eventLogger beginLoadDataWhenBufferEmpty];
        if (!_hasShownFirstFrame && !_notifyBufferBeforeFirstFrame) {
            return;
        }
    }

    if (state == TTVideoEngineLoadStatePlayable) {
        if (_isSeeking) {
            _isSeeking = NO;
            [self.eventLogger showedOneFrame];
        } else {
            [self.eventLogger stallEnd];
            [self _syncPlayInfoToMdlForKey:VEKPlayInfoBufferingEnd Value:1];
        }
        if (self.playDuration && self.playbackState == TTVideoEnginePlaybackStatePlaying && _lastUserAction != TTVideoEngineUserActionPause) {
            [self.playDuration start];
        }
        [self.eventLogger endLoadDataWhenBufferEmpty];
    }
    TTVideoRunOnMainQueue(^{
        TTVideoEngineLog(@"load state change, state = %zd, extra info: %@",state,extraInfo);
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:loadStateDidChanged:)]) {
            [self.delegate videoEngine:self loadStateDidChanged:state];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:loadStateDidChanged:extra:)]) {
            [self.delegate videoEngine:self loadStateDidChanged:state extra:extraInfo.copy];
        }
    }, NO);
}
- (void)playerVideoSizeChange:(NSInteger)width height:(NSInteger)height {
    TTVideoEngineLog(@"notify video size changed, width:%ld, height:%ld, isFirstGet:%d, isSwitchingDefinition:%d", width, height, _firstGetWidthHeight, _isSwitchingDefinition);
    if (_firstGetWidthHeight && !_isSwitchingDefinition) {
        _firstGetWidthHeight = NO;
        [self.eventLogger videoChangeSizeWidth:width height:height];
    }
    if (self.resolutionDelegate && [self.resolutionDelegate respondsToSelector:@selector(videoSizeDidChange:videoWidth:videoHeight:)]) {
        [self.resolutionDelegate videoSizeDidChange:self videoWidth:width videoHeight:height];
    }
}
- (void)playerVideoBitrateChanged:(NSInteger)bitrate {
    NSArray<NSNumber *> *resolutions = [self supportedResolutionTypes];
    TTVideoEngineResolutionType resolution;
    TTVideoEngineURLInfo *info = nil;
    TTVideoEngineLog(@"videoBitrateHaveChanged:%zd",bitrate);
    for (NSInteger i = 0; i < resolutions.count; i++) {
        resolution = (TTVideoEngineResolutionType)[resolutions[i] integerValue];
        if ([self.playSource bitrateForDashSourceOfType:resolution] == bitrate) {
            self.lastResolution = self.currentResolution;
            self.currentResolution = resolution;
            if(![self.playSource hasVideo]){
                info =  [self.playSource urlInfoForResolution:resolution mediaType:@"audio"];
            }else{
                info =  [self.playSource urlInfoForResolution:resolution mediaType:@"video"];
            }
            if(info != nil){
                self.currentQualityDesc = [info getValueStr:VALUE_VIDEO_QUALITY_DESC];
            }
            [self.eventLogger setCurrentDefinition:[self _resolutionStringForType:_currentResolution] lastDefinition:[self _resolutionStringForType:_lastResolution]];
            [self.eventLogger setCurrentQualityDesc:self.currentQualityDesc];
            if (self.resolutionDelegate && [self.resolutionDelegate respondsToSelector:@selector(videoBitrateDidChange:resolution:bitrate:)]) {
                [self.resolutionDelegate videoBitrateDidChange:self resolution:resolution bitrate:bitrate];
            }
            return;
        }
    }
}
- (void)playerDeviceOpened:(TTVideoEngineStreamType)streamType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineDeviceOpened:streamType:)]) {
        [self.delegate videoEngineDeviceOpened:self streamType:streamType];
    }
}

- (void)playerViewWillRemove {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineBeforeViewRemove:)]) {
        [self.delegate videoEngineBeforeViewRemove:self];
    }
}

- (void)playableDurationUpdate:(NSTimeInterval)playableDuration {
    self.playableDuration = playableDuration;
    if (TTVideoIsFloatEqual(self.playableDuration, self.duration)) {
        [self.eventLogger movieBufferDidReachEnd];
    }
    
    if (TTVideoEnginePreloader.hasRegistClass) {
        [self _ls_tryToNotifyPrelaod];
    }
}

- (void)playerReadyToDisplay {
    TTVideoEngineLog(@"player is playerReadyToDisplay");
    [self seekToLastPlaytimeAfterSwitchResolution];
    [self _buryDataWhenPrepareToDisplay];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineReadyToDisPlay:)]) {
        [self.delegate videoEngineReadyToDisPlay:self];
    }
    
    [self _setupSubtitleInfo];
}

- (void)_manualSendRenderStart {
    [self loadStateDidChange:TTVideoEngineLoadStatePlayable stallReason:TTVideoEngineStallReasonNone];
    
    [self playerReadyToDisplay];
    
    [self playerIsReadyToPlay];
    
    [self playbackStateDidChange:TTVideoEnginePlaybackStatePlaying];
}

- (void)playerAudioRenderStart {
    TTVideoEngineLog(@"audio render start");
    if (_isEnableBackGroundPlay && !_hasShownFirstFrame) {
        UIApplication* uiApplication = TTVideoEngineGetApplication();
        if (uiApplication) {
            UIApplicationState state = uiApplication.applicationState;
            if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
                TTVideoEngineLog(@"isBackGround start, need report render start");
                [self.eventLogger setIntOption:LOGGER_OPTION_RADIO_MODE value:1];
                [self.eventLogger backgroundStartPlay];
                
                [self _manualSendRenderStart];
            }
        }
    }
    
    if (_shouldUseAudioRenderStart && !_hasShownFirstFrame) {
        [self _manualSendRenderStart];
    }

    if (!_hasAudioRenderStarted && self.player != nil) {
        //need to get first frame times here, in case times not ready when video render start
        [self logUrlConnectToFirstFrameTime];
        _hasAudioRenderStarted = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineAudioRendered:)]) {
            [self.delegate videoEngineAudioRendered:self];
        }
    }
}

- (void)playerPreBuffering:(NSInteger)type {
    TTVideoEngineLog(@"playerPrebuffering, type:%d", type);
    if (self.eventLogger) {
        [self.eventLogger moviePreStall:type];
    }
}

- (void)playerAVOutsyncStateChange:(NSInteger)type pts:(NSInteger)pts {
    TTVideoEngineLog(@"playerAVOutsyncStateChange, type:%d, pts:%d", type, pts);
    if (type == TTVideoEngineAVOutsyncTypeStart) {
        [self.eventLogger avOutsyncStart:pts];
    } else if (type == TTVideoEngineAVOutsyncTypeEnd) {
        [self.eventLogger avOutsyncEnd:pts];
    }
}

- (void)playerNOVARenderStateChange:(TTVideoEngineNOVARenderStateType)stateType noRenderType:(int)noRenderType {
    TTVideoEngineLog(@"playerNOVARenderStateChange, stateType:%lu, noRenderType:%d", (unsigned long)stateType, noRenderType);
    if (TTVideoEngineNOVARenderStateTypeStart == stateType) {
        NSInteger curPos = 0;
        [self.eventLogger noVARenderStart:curPos noRenderType:noRenderType];
    } else if (TTVideoEngineNOVARenderStateTypeEnd == stateType) {
        NSInteger curPos = 0;
        [self.eventLogger noVARenderEnd:curPos noRenderType:noRenderType];
    }
}

- (void)playerStartTimeNoVideoFrame:(int)streamDuration {
    TTVideoEngineLog(@"starttime is bigger than video duration:%d", streamDuration);
    _shouldUseAudioRenderStart = YES;
}

- (void)playerOutleterPaused:(TTVideoEngineStreamType)streamType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineOutleterPaused:streamType:)]) {
        [self.delegate videoEngineOutleterPaused:self streamType:streamType];
    }
    TTVideoEngineLog(@"outleter paused stream:%d",(int)streamType);
}

- (void)playerBarrageMaskInfoCompleted:(NSInteger)code {
    [self.eventLogger setMaskErrorCode:code];
    TTVideoEngineLog(@"BarrageMaskInfoCompleted, error code:%ld",code);
}

- (void)playerDidCreateKernelPlayer {
    /// Need after create kernel.
    [self _tryConfigVodStrategyInfo];
}

- (void)playerIsPrepared {
    TTVideoEngineLog(@"player is prepared");

    self.hasPrepared = YES;
    if (self.isEnablePostPrepareMsg) {
        if (self.postprepareWay == TTVideoEnginePostPrepareInEngine) {
            if (self.lastUserAction == TTVideoEngineUserActionPlay && self.needPlayBack) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.eventLogger beginToPlayVideo:self.playSource.videoId];
                    [self playVideo];
                    self.needPlayBack = NO;
                });
            }
        }
    }
    if (self.lastUserAction == TTVideoEngineUserActionPause ||
        self.lastUserAction == TTVideoEngineUserActionStop
        ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.lastUserAction == TTVideoEngineUserActionPause ||
                self.lastUserAction == TTVideoEngineUserActionStop
                ) {
                [self pauseVideo:NO];
            }
        });
    }
    

    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEnginePrepared:)]) {
        [self.delegate videoEnginePrepared:self];
    }
    
    [self _startTimerToSyncPlayInfo];
    [self _startCheckPreloadTimer];
}

- (void)playerMediaInfoDidChanged:(NSInteger)infoId {
    TTVideoEngineLog(@"TTS feature: recv audio switching call back, info Id: %ld, delegate is empty :%d", infoId, self.delegate == nil ? 1 : 0)
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(videoEngine:switchMediaInfoCompleted:)]) {
        [self.delegate videoEngine:self switchMediaInfoCompleted:infoId];
    }
}

- (void)playerIsReadyToPlay {
    TTVideoEngineLog(@"player is ready to play");
    [self seekToLastPlaytimeAfterSwitchResolution];
    self.startTime = 0;
    self.playerUrlDNSRetryCount = 0;
    if (!self.shouldPlay) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.shouldPlay) {
                [self pauseVideo:NO];
            }
        });
    }

    [self _buryDataWhenPlayerPrepared];

    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineReadyToPlay:)]) {
        [self.delegate videoEngineReadyToPlay:self];
    }
}

- (void)playbackDidFinish:(NSDictionary *)reason {
    TTVideoEngineLog(@"play back finish:%@",reason);
    NSError *error = [reason objectForKey:@"error"];
    // to do: call every loop, need process
    [self _buryDataWhenUserWillLeave];
    //
    if (self.isSwitchingDefinition && error) { // Switch resolution fail.
        [TTVideoEngineCopy assignEngine:self];
    }
    self.isSwitchingDefinition = NO;
    self.isRetrying = NO;
    self.playerIsPreparing = NO;
    if (!self.looping) {
        TTVideoEngineLog("post prepare looping no reset hasprepared");
        self.hasPrepared = NO;
    }
    self.didCallPrepareToPlay = NO;
    [self notifyDelegateSwitchComplete:(error == nil)];
    if (self.abrModule) {
        [self.abrModule stop];
    }
    [self _stopTimerToSyncPlayInfo];
    [self _stopCheckPreloadTimer];
    //
    if (error) {
        if (self.playDuration) {
            [self.playDuration stop];
        }
        [self didReceiveError:error];
    }
    else {
        _hasShownFirstFrame = NO;
        _hasAudioRenderStarted = NO;
        TTVideoEngineFinishReason finishReason = [reason[TTVideoEnginePlaybackDidFinishReasonUserInfoKey] integerValue];
        if (self.looping && finishReason == TTVideoEngineFinishReasonPlaybackEnded) {
            [self.eventLogger watchFinish];
        } else {
            if (self.playDuration) {
                [self.playDuration stop];
            }
            [self _buryDataWhenSendOneplayEvent];
            [self.eventLogger playbackFinish:finishReason];
            if (finishReason == TTVideoEngineFinishReasonPlaybackEnded) {
                _isComplete = YES;
            }
        }
        if (finishReason == TTVideoEngineFinishReasonUserExited) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineUserStopped:)]) {
                [self.delegate videoEngineUserStopped:self];
            }
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngineDidFinish:error:)]) {
                [self.delegate videoEngineDidFinish:self error:nil];
            }
            if (self.looping) {
                [self.eventLogger loopAgain];
            }
        }
    }
}


#pragma mark -
#pragma mark TTVideoEngineEventLogger Delegate

- (NSDictionary *)versionInfoForEventLogger:(id<TTVideoEngineEventLoggerProtocol>)eventLogger {
    if (self.isOwnPlayer) {
 
        return @{@"sv": kServerLogVersion,
                 @"pv": kOwnPlayerVersion,
                 @"pc": [self.player getVersion],
                 @"sdk_version":  [kTTVideoEngineVersion substringFromIndex: VERSION_PREFIX_LEN]
                 };
    }

    return @{@"sv": kServerLogVersion,
             @"pv": kSysPlayerVersion,
             @"pc": kSysPlayerCore,
             @"sdk_version":  [kTTVideoEngineVersion substringFromIndex: VERSION_PREFIX_LEN]
             };
}

- (NSDictionary *)bytesInfoForEventLogger:(id<TTVideoEngineEventLoggerProtocol>)eventLogger {
    long long numberOfBytesTransferred = [self.player numberOfBytesTransferred];
    long long numberOfBytesPlayed = [self.player numberOfBytesPlayed];
    long long downloadSpeed = [self.player downloadSpeed];
    long long videoBufferLength = [self.player videoBufferLength];
    long long audioBufferLength = [self.player audioBufferLength];
    long long videoBufferLengthDecoder = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDecoderBufferLen];
    long long audioBufferLengthDecoder = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioDecoderBufferLen];
    long long videoBufferLengthBasePlayer = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoBasePlayerBufferLen];
    long long audioBufferLengthBasePlayer = [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioBasePlayerBufferLen];
    long long singlePlayDownloadSize = [self.player getInt64ValueForKey:KeyIsSinglePlayDownloadBytes];
    long long accumulatePlayDownloadSize = [self.player getInt64ValueForKey:KeyIsAccumulateDownloadBytes];
    return @{@"vds": @(numberOfBytesTransferred),
             @"vps": @(numberOfBytesPlayed),
             @"download_speed": @(downloadSpeed),
             @"vlen": @(videoBufferLength),
             @"alen": @(audioBufferLength),
             @"vDecLen": @(videoBufferLengthDecoder),
             @"aDecLen": @(audioBufferLengthDecoder),
             @"vBaseLen": @(videoBufferLengthBasePlayer),
             @"aBaseLen": @(audioBufferLengthBasePlayer),
             @"single_vds": @(singlePlayDownloadSize),
             @"accu_vds": @(accumulatePlayDownloadSize)
             };
}

- (NSDictionary *)getGlobalMuteDic:(id<TTVideoEngineEventLoggerProtocol>)eventLogger {
    return sGlobalMuteDic;
}

- (NSString *)getLogValueStr:(NSInteger)key {
    switch (key) {
        case LOGGER_VALUE_NET_CLIENT:
            if (self.netClient == nil) {
                return @"own";
            }
            return @"user";
        case LOGGER_VALUE_BUFS_WHEN_BUFFER_START:
            if (self.player != nil) {
                return [self.player getStringValueForKey:KeyIsBufsWhenBufferStart];
            }
            return @"";
        case LOGGER_VALUE_MDL_VERSION:
            return [TTVideoEngine _ls_getMDLVersion];
        case LOGGER_VALUE_FILE_FORMAT:
            return [self.player getStringValueForKey:KeyIsFileFormat];
        case LOGGER_VALUE_GET_MDL_PLAY_LOG:
            return [self _ls_getMDLPlayLog:self.traceId];
        case LOGGER_VALUE_AV_PTS_DIFF_LIST:
            return [self.player getStringValueForKey:KeyIsAVPtsDiffList];
        case LOGGER_VALUE_VIDEO_DEC_OUTPUT_FPS_LIST:
            return [self.player getStringValueForKey:KeyIsVideoDecoderOutputFpsList];
        case LOGGER_VALUE_ERRC_WHEN_NOV_RENDERSTART:
            return [self.player getStringValueForKey:KeyIsRenderErrcWhenNoVRenderStart];
        case LOGGER_VALUE_PRELOAD_TRACE_ID: {
            NSString *preloadTraceId = nil;
            if (self.enableReportPreloadTraceId) {
                NSString *vid = self.playSource.videoId;
                preloadTraceId = [self _ls_getPreloadTraceId:vid];
                TTVideoEngineLog(@"get preloadTraceId = %@, videoID = %@", preloadTraceId, vid);
                
                //获取到预加载traceid之后即刻清除
                if (preloadTraceId && preloadTraceId.length > 0) {
                    [self _ls_resetPreloadTraceId:vid];
                    TTVideoEngineLog(@"reset preloadTraceId = %@", preloadTraceId);
                }
            }
            return preloadTraceId;
        }
        default:
            break;
    }
    return @"";
}

- (NSInteger)getLogValueInt:(NSInteger)key {
    switch (key) {
        case LOGGER_VALUE_ENGINE_STATE:
            return self.state;
        case LOGGER_VALUE_DURATION:
            return [self.player duration] * 1000;
        case LOGGER_VALUE_CURRENT_CONFIG_BITRATE:
            return [self.playSource bitrateForDashSourceOfType:_currentResolution];
        case LOGGER_VALUE_VIDEO_CODEC_PROFILE:
            if (_videoCodecProfile == -1)
                _videoCodecProfile =  [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoCodecProfile];
            return _videoCodecProfile;
        case LOGGER_VALUE_AUDIO_CODEC_PROFILE:
            if (_audioCodecProfile == -1)
                _audioCodecProfile = [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioCodecProfile];
            return _audioCodecProfile;
        case LOGGER_VALUE_GET_OUTLET_DROP_COUNT_ONCE:
            return [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoOutletDropCountOnce];
        case LOGGER_VALUE_CURRENT_PLAYBACK_TIME:
            return self.player.currentPlaybackTime;
        case LOGGER_VALUE_IS_MUTE:
            return (self.player.muted ? 1 : 0);
        case LOGGER_VALUE_CORE_VOLUME:
            return (NSInteger)(self.player.volume);
        case LOGGER_VALUE_CONTAINER_FPS:
            return [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsContainerFPS];
        case LOGGER_VALUE_VIDEODECODER_OUTPUT_FPS:
            return [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoDecoderOutputFps];
        case LOGGER_VALUE_BUFFER_VIDEO_LENGTH:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsVideoBufferLength];
        case LOGGER_VALUE_BUFFER_AUDIO_LENGTH:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAudioBufferLength];
        case LOGGER_VALUE_ENABLE_NNSR:
            return [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsEnableVideoSR];
        case LOGGER_VALUE_GET_NETWORK_CONNECT_COUNT:
            return [self.player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsGetNetworkConnectCount];
        case LOGGER_VALUE_ENABLE_GLOBAL_MUTE_FEATURE:
            return sEnableGlobalMuteFeature;
        default:
            break;
    }
    return 0;
}

- (int64_t)getLogValueInt64:(NSInteger)key {
    switch (key) {
        case LOGGER_VALUE_CLOCK_DIFF:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsClockDiff];
        case LOGGER_VALUE_AVOUTSYNC_MAX_AVDIFF:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsAVOutsyncMaxAVDiff];
        case LOGGER_VALUE_MASK_DOWNLOAD_SIZE:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMaskDownloadSize];
        case LOGGER_VALUE_SUBTITLE_DOWNLOAD_SIZE:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsSubTitleDownloadSize];
        case LOGGER_VALUE_FILE_SIZE:
            return [self.player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMediaFileSize];
        case LOGGER_VALUE_PLAYER_REQ_OFFSET: {
            int64_t playerReqOffsetDValue = (0 == self.enableGetPlayerReqOffset) ? -1 : -2;
            return [self.player getInt64Value:playerReqOffsetDValue forKey:KeyIsPlayerReqOffset];
        }
        default:
            break;
    }
    
    return LOGGER_INTEGER_INVALID_VALUE;
}

- (CGFloat)getLogValueFloat:(NSInteger)key {
    switch (key) {
        case LOGGER_VALUE_VIDEO_OUT_FPS:
            return [self.player getFloatValueForKey:KeyIsVideoOutFPS];
        default:
            break;
    }
    
    return LOGGER_FLOAT_INVALID_VALUE;
}

- (void)onInfo:(NSInteger)key value:(NSInteger)value extraInfo:(NSDictionary *)extraInfo {
    switch (key) {
        case LoggerOptionKeyAVOutsyncStateChanged:
            if (_options.enableAVOutsyncCallback &&
                self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:avOutsyncStateDidChanged:extraInfo:)]) {
                [self.delegate videoEngine:self avOutsyncStateDidChanged:value extraInfo:extraInfo];
            }
            break;
        case LoggerOptionKeyNOVARenderStateChanged:
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:noVARenderStateDidChange:extraInfo:)]) {
                [self.delegate videoEngine:self noVARenderStateDidChange:value extraInfo:extraInfo];
            }
            break;
            
        default:
            break;
    }
}

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

#pragma mark -
#pragma mark TTVideoPlayerEngineInfoProtocol

- (dispatch_queue_t)usingSerialTaskQueue {
    if (self.usingEngineQueue) {
        return _taskQueue ?: TTVideoEngineGetQueue();
    }
    return TTVideoEngineGetQueue();
}

- (id<TTVideoEngineFFmpegProtocol>) getFFmpegProtocolObject {
    
    return _ffmpegProtocol;
}

#pragma mark - TTAVPlayerSubInfoInterface

- (void)onSubInfoCallBack:(NSDictionary *)subInfo {
    if (!self.subEnable) return;
    
    NSInteger pts = [[subInfo valueForKey:kTTAVPlayerSubInfoPts] integerValue];
    NSString *content = [subInfo valueForKey:kTTAVPlayerSubInfoContent];
    NSInteger duration = [[subInfo valueForKey:kTTAVPlayerSubInfoDuration] integerValue];
    
    if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubtitleInfoCallBack:)]) {
        TTVideoEngineSubInfo *subInfo = [[TTVideoEngineSubInfo alloc] init];
        subInfo.pts = pts;
        subInfo.content = content;
        subInfo.duration = duration;
        [self.subtitleDelegate videoEngine:self onSubtitleInfoCallBack:subInfo];
    }
    
    if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubtitleInfoCallBack:pts:)]) {
        [self.subtitleDelegate videoEngine:self onSubtitleInfoCallBack:content pts:pts];
    }
}

- (void)onSubSwitchCompleted:(BOOL)success languageId:(NSInteger)languageId {
    if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubSwitchCompleted:currentSubtitleId:)]) {
        [self.subtitleDelegate videoEngine:self onSubSwitchCompleted:success currentSubtitleId:languageId];
    }
}

- (void)onSubLoadFinished:(BOOL)success code:(NSInteger)code {
    if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubLoadFinished:)]) {
        [self.subtitleDelegate videoEngine:self onSubLoadFinished:success];
    }
}

- (void)onSubLoadFinished:(BOOL)success code:(NSInteger)code info:(NSDictionary *)info {
    TTVideoEngineLog(@"subtitle: onSubLoadFinished, success: %d, code %ld, info: %@", success, code, info);
    if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubLoadFinished:info:)]) {
        TTVideoEngineLoadInfo *loadInfo = nil;
        NSNumber *value = info[kTTAVPlayerSubLoadInfoFirstPts];
        if (value) {
            loadInfo = [[TTVideoEngineLoadInfo alloc] init];
            
            NSInteger firstPts = [value integerValue];
            loadInfo.firstPts = firstPts;
            loadInfo.code = success ? 0 : code;
        }
        [self.subtitleDelegate videoEngine:self onSubLoadFinished:success info:loadInfo];
    }
}

#pragma mark - TTAVPlayerMaskInfoInterface
- (void)onMaskInfoCallBack:(NSString*)svg pts:(NSUInteger)pts {
    if (self.barrageMaskEnable && self.maskInfoDelegate && [self.maskInfoDelegate respondsToSelector:@selector(videoEngine:onMaskInfoCallBack:pts:)]) {
        [self.maskInfoDelegate videoEngine:self onMaskInfoCallBack:svg pts:pts];
    }
}

#pragma mark -
#pragma mark IVCABRIInfoListener

- (void)onInfo:(int)code withDetail:(int)detailCode {
    @autoreleasepool {
        if (code == ON_GET_PREDICT_RESULT) {
            VCABRResult *result = [self.abrModule getPredict];
            int size = [result getSize];
            if (size == 0) return;
            self.isUsedAbr = self.enableDashAbr || self.isUsedAbr;
            for (int i = 0; i < size; i++) {
                VCABRResultElement *element = [result elementAtIndex:i];
                //TODO::select bitrate
                int bitrate = (int)element.bitrate;
                if ([self.dashABRDelegate respondsToSelector:@selector(videoEnginePredictNextBitrate:bitrate:)]) {
                    [self.dashABRDelegate videoEnginePredictNextBitrate:self bitrate:bitrate];
                }
                
                if (self.abrSwitchMode == TTVideoEngineDashABRSwitchAuto && self.enableDashAbr) {
                    [self.player setIntValue:bitrate forKey:KeyIsABRPredictVideoBitrate];
                }
                return;
            }
        }
    }
}

#pragma mark -
#pragma mark IVCABRInitParams

- (int64_t)getStartTime {
    return self.startPlayTimestamp;
}

- (float)getProbeInterval {
    return self.abrTimerInterval;
}

- (int)getTrackType {
    return 0;
}

#pragma mark -
#pragma mark IVCABRPlayStateSupplier

- (float)getPlaySpeed {
    return self.playbackSpeed;
}

- (int64_t)getExpectedBitrate {
    return -1;//todo c: lack of api
}

- (float)getNetworkSpeed {
    float speed = -1.0;
    Class predictAction = [[TTVideoEngineActionManager shareInstance] actionClassWithProtocal:@protocol(TTVideoEngineNetworkPredictorAction)];
    if ([predictAction respondsToSelector:@selector(getPredictSpeed)]) {
        speed = [predictAction getPredictSpeed];
    }
    return speed;
}

- (float)getSpeedConfidence {
    float speedConfidence = -1;
    Class predictAction = [[TTVideoEngineActionManager shareInstance] actionClassWithProtocal:@protocol(TTVideoEngineNetworkPredictorAction)];
    if ([predictAction respondsToSelector:@selector(getSpeedConfidence)]) {
        speedConfidence = [predictAction getSpeedConfidence];
    }
    return speedConfidence;
}

- (int)getCurrentDownloadVideoBitrate {
    return [self.player getIntValueForKey:KeyIsABRDownloadVideoBitrate];
}

- (int)getCurrentDownloadAudioBitrate {
    return self.currentDownloadAudioBitrate;
}

- (int)getMaxCacheVideoTime {
    return [self.player getIntValueForKey:KeyIsSettingCacheMaxSeconds] * 1000;
}

- (int)getMaxCacheAudioTime {
    return [self.player getIntValueForKey:KeyIsSettingCacheMaxSeconds] * 1000;
}

- (int)getPlayerVideoCacheTime {
    return [self.player videoBufferLength];
}

- (int)getPlayerAudioCacheTime {
    return [self.player audioBufferLength];
}

- (NSArray<id<IVCABRModuleSpeedRecord>> *)getTimelineNetworkSpeed {
   return nil;
}

- (nullable NSDictionary<NSString *, id<IVCABRBufferInfo>> *)getVideoBufferInfo {
    return nil;
}

- (nullable NSDictionary<NSString *, id<IVCABRBufferInfo>> *)getAudioBufferInfo {
    return nil;
}

- (int)getNetworkState {
    TTVideoEngineNetWorkStatus netStatus = [[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus];
    if (netStatus == TTVideoEngineNetWorkStatusWiFi) {
        return 0;
    } else if (netStatus == TTVideoEngineNetWorkStatusWWAN) {
        return 1;
    } else {
        return -1;
    }
}

- (int)getLoaderType {
    return 0;
}

- (int)getCurrentPlaybackTime {
    return 0;
}

#pragma mark - networkPredictorReaction

- (void)predictorSpeedNetworkChanged:(float)speed timestamp:(int64_t)timestamp {
    if ([self.networkPredictorDelegate respondsToSelector:@selector(predictorSpeedNetworkChanged:timestamp:)]) {
        [self.networkPredictorDelegate predictorSpeedNetworkChanged:speed timestamp:timestamp];
    }
}

- (void)updateSingleNetworkSpeed:(NSDictionary *)videoDownDic audioInfo:(NSDictionary *)audioDownDic realInterval:(int)timeInterval {
    [self.eventLogger updateSingleNetworkSpeed:videoDownDic audioInfo:audioDownDic realInterval:timeInterval];
}

- (NSInteger)getCurrentVideoBufLength {
    return [self.player videoBufferLength];
}

- (NSInteger)getCurrentAudioBufLength {
    return [self.player audioBufferLength];
}

- (NSInteger)getPlayerVideoMaxCacheBufferLength {
    return [self.player getIntValueForKey:KeyIsSettingCacheMaxSeconds] * 1000;
}

- (NSInteger)getPlayerAudioMaxCacheBufferLength {
    return [self.player getIntValueForKey:KeyIsSettingCacheMaxSeconds] * 1000;
}

+ (ABRPredictAlgoType)getPredictAlgoType {
    return sPredictAlgo;
}

+ (ABROnceAlgoType)getOnceSelectAlgoType {
    return sOnceSelectAlgo;
}

/// MARK: - TTVideoEngineMDLFetcherDelegate
- (NSString*)getId {
    return self.engineHash;
}

- (NSString*)getFallbackApi {
    NSString *apiString = nil;
    //fallbackApi is not null, use directlly
    if (self.playSource && [self.playSource isKindOfClass:[TTVideoEnginePlayVidSource class]]) {
        apiString = [(TTVideoEnginePlayVidSource *) self.playSource fallbackApi];
    }
    //fallbackApi is null, get from dataSource
    if (isEmptyStringForVideoPlayer(apiString)) {
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(apiForFetcher:)]) {
            apiString = [self.dataSource apiForFetcher:self.apiVersion];
        } else if (self.dataSource && [self.dataSource respondsToSelector:@selector(apiForFetcher)]) {
            apiString = [self.dataSource apiForFetcher];
        }
    }
    
    if(self.boeEnable){
         apiString = TTVideoEngineBuildBoeUrl(apiString);
    }
    apiString = TTVideoEngineBuildHttpsApi(apiString);
    return apiString;
}

- (void)onMdlRetryStart:(NSError *)error {
    if ([self getEventLogger]) {
        NSInteger curPos = [self currentPlaybackTime] * 1000;
        [[self getEventLogger] moviePlayRetryStartWithError:error strategy:TTVideoEngineRetryStrategyFetchInfo curPos:curPos];
    }
}

- (void)onMdlRetryEnd {
    if ([self getEventLogger]) {
        [[self getEventLogger] moviePlayRetryEnd];
    }
}

- (void)onRetry:(NSError*)error {
    if (!error || ![self getEventLogger]) {
        return;
    }
    [[self getEventLogger] needRetryToFetchVideoURL:error apiVersion:self.apiVersion];
}

- (void)onLog:(NSString*)message {
    if ([self getEventLogger]) {
        [[self getEventLogger] logMessage:message];
    }
}

- (void)onError:(NSError*)error fileHash:(NSString*)fileHash {
    if ([self getEventLogger]) {
        [[self getEventLogger] mdlRetryResult:MDL_RETRY_RESULT_ERROR fileHash:fileHash error:error];
    }
}

- (void)onCompletion:(TTVideoEngineModel*)model newModel:(BOOL)newModel fileHash:(NSString*)fileHash {
    TTVideoEngineLog(@"fetch info success");
    if ([self getEventLogger]) {
        NSInteger resultCode = newModel ? MDL_RETRY_RESULT_SUCCESS : MDL_RETRY_RESULT_SUCCESS_CACHE;
        [[self getEventLogger] mdlRetryResult:resultCode fileHash:fileHash error:nil];
    }
    if (newModel) {
        [self logFetchedVideoInfo:model.videoInfo];
    }
}

//MARK: - Private Method

- (BOOL)_isMainUrl {
    if ([TTVideoEngine ls_isStarted]) {
        return self.medialoaderEnable  && self.currentHostnameURL;
    } else {
        return self.playSource.isMainUrl;;
    }
}

- (BOOL)isDashSource {
    BOOL temResult = self.playSource.supportDash;
    return temResult;
}

- (NSString *)getFileFormat {
    if (self.player != nil) {
        return [self.player getStringValueForKey:KeyIsFileFormat];;
    }
    return @"";
}

- (NSString *)getStreamTrackInfo {
    if (self.player != nil) {
        return [self.player getStringValueForKey:KeyIsStreamTrackInfo];
    }
    return @"";
}

- (void)_createCacheFileDirAndDeleteInvalidDataIfNeed {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *cacheFileDir = [self _defaultCacheFileDataDirectory];
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:cacheFileDir]) {/// Invalid cache data.
                NSString *needRemoveCacheDir = [[cacheFileDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"com_engine_media_tmp"];
                [fm moveItemAtPath:cacheFileDir toPath:needRemoveCacheDir error:nil];
                [fm createDirectoryAtPath:cacheFileDir withIntermediateDirectories:YES attributes:nil error:nil];
                [fm removeItemAtPath:needRemoveCacheDir error:nil];
            } else {
                [fm createDirectoryAtPath:cacheFileDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
        });
    });
}

- (NSString* )_defaultCacheFileDataDirectory {
    static NSString* cacheFileDir = nil;
    if (cacheFileDir == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDir = [paths objectAtIndex:0];
        cacheFileDir = [cachesDir stringByAppendingPathComponent:@"media"];
    }
    return cacheFileDir;
}

- (void)_ls_logProxyUrl:(NSString *)proxyUrl {
    [self.eventLogger proxyUrl:proxyUrl];
}

+ (NSString *)_engineVersionString {
    return [kTTVideoEngineVersion substringFromIndex: VERSION_PREFIX_LEN];
}

- (NSString *)_resolutionStringForType:(TTVideoEngineResolutionType)type {
    CODE_ERROR(_resolutionMap == nil);

    if (_resolutionMap) {
        __block NSString *tem = @"360p";
        [_resolutionMap.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            if (type == obj.integerValue) {
                tem = key;
                *stop = YES;
            }
        }];

        return tem;
    } else {
        return @"360p";
    }
}

- (void)_userWillLeave {
    [self setIdleTimerDisabledOnMainQueue:NO];
    [TTVideoEngineCopy reset];
    [TTVideoEngineStrategy.helper removeLogData:_playSource.videoId];
    [TTVideoEngineStrategy.helper removeLogDataByTraceId:_traceId];
    self.didCallPrepareToPlay = NO;
    self.settingMask = 0;
    self.didSetAESrcPeak = NO;
    self.didSetAESrcLoudness = NO;
    self.hasPrepared = NO;
    [self.bashDefaultMDLKeys removeAllObjects];
    if (self.performanceLogEnable) {
        [TTVideoEnginePerformanceCollector removeObserver:self.eventLogger];
    }
    
    if (self.localServerTaskKeys.count > 0) {
        [self _ls_removePlayTaskByKeys:self.localServerTaskKeys];
        [TTVideoEngine _ls_removeObserver:self forKeys:self.localServerTaskKeys];
        [self.localServerTaskKeys removeAllObjects]; // need after _ls_removeObserver
    }
    [self _stopTimerToSyncPlayInfo];
    [self _stopCheckPreloadTimer];
    [TTVideoEnginePool.instance stopObserve:self.hash];
}

- (NSString *)_traceIdBaseTime:(NSTimeInterval)time {
    NSString *deviceId = nil;
    if (_dataSource && [_dataSource respondsToSelector:@selector(appInfo)]) {
        NSDictionary *appInfo = [_dataSource appInfo].copy;
        if (appInfo && appInfo.count > 0) {
            deviceId = appInfo[TTVideoEngineDeviceId];
        }
    }
    if (deviceId == nil && TTVideoEngineAppInfo_Dict.count > 0) {
        deviceId = TTVideoEngineAppInfo_Dict[TTVideoEngineDeviceId];
    }

    NSString *traceId = TTVideoEngineGenerateTraceId(deviceId, (uint64_t)time);
    TTVideoEngineLog(@"generate track-id: %@",traceId);
    return traceId;
}

- (void)_printEngineCallTrace {
    TTVIDEOENGINE_PRINT_METHOD
}

- (NSString *)_engineDebugInfo {
    return [NSString stringWithFormat:@"state = %@, playbackstate = %@, lastUserAction = %@",stateString(self.state),playbackStateString(self.playbackState),userActionString(self.lastUserAction)];
}

- (void)_ls_cancelPreload:(nonnull NSString* )cancelReason info:(NSDictionary *)infoDic{
    [TTVideoEngine ls_cancelAllTasks];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (infoDic != nil) {
        [info addEntriesFromDictionary:infoDic];
    }
    [info setObject:TTVideoEnginePreloadCancelReason forKey:cancelReason];
    [TTVideoEnginePreloader notifyPreloadCancel:self info:info];
    
}

- (void)_ls_tryToNotifyPrelaod {
    NSTimeInterval currTime = CACurrentMediaTime();
    if (self.easyPreloadNotifyTime > 1 && (currTime - self.easyPreloadNotifyTime) < self.easyPreloadThreshold) {
        return;
    }
    
    NSInteger videoBufferMillisecond = [_player getInt64ValueForKey:KeyIsVideoBufferLength];
    NSInteger audioBufferMillisecond = [_player getInt64ValueForKey:KeyIsAudioBufferLength];
    
    TTVideoEngineLog(@"video buffer. %ld, audio buffer. %ld",(long)videoBufferMillisecond,(long)audioBufferMillisecond);
    
    NSInteger upperLimit = _preloadUpperBufferMs > 0 ? _preloadUpperBufferMs : 20000;
    NSInteger lowerLimit = _preloadLowerBufferMs > 0 ? _preloadLowerBufferMs : 5000;
    if (videoBufferMillisecond > upperLimit || audioBufferMillisecond > upperLimit) {
        self.easyPreloadNotifyTime = currTime;
        [TTVideoEnginePreloader notifyPreload:self
                                         info:@{TTVideoEnginePreloadSuggestBytesSize:@(800*1024*1024),
                                                TTVideoEnginePreloadSuggestCount:@(3)}];
        return;
    }
    
    NSInteger duration = [_player getInt64ValueForKey:KeyIsDuration];
    NSInteger position = [_player getInt64ValueForKey:KeyIsCurrentPosition];
    
    if (self.preloadDurationCheck) {
        duration = [self duration] * 1000;
        position = [self currentPlaybackTime] * 1000;
    }
    
    if (duration <= upperLimit) {
        //max duration lower than limit check cache end
        if (videoBufferMillisecond >= (duration - position)) {
            self.easyPreloadNotifyTime = currTime;
            [TTVideoEnginePreloader notifyPreload:self
                                             info:@{TTVideoEnginePreloadSuggestBytesSize:@(800*1024*1024),
                                                    TTVideoEnginePreloadSuggestCount:@(3)}];
            return;
        }
    }
    
    if (videoBufferMillisecond < lowerLimit || audioBufferMillisecond < lowerLimit) {
        if ((duration - position) > lowerLimit) {
            [self _ls_cancelPreload:TTVideoEnginePreloadLowBufferCancel info:@{TTVideoEnginePreloadCancelConfigBuffer:@(lowerLimit),TTVideoEnginePreloadCancelCurrentBuffer:@(videoBufferMillisecond)}];
        }
    }
}

- (void)_registerMdlProtocolHandle {
    if (_medialoaderProtocolRegistered) {
        return;
    }
    void *handle = [TTVideoEngine ls_getNativeMedialoaderHandle];
    TTVideoEngineLog(@"medialoader get handle:%p \n",handle);
    if (handle == NULL) {
        return;
    }
    [self.player setValueVoidPTR:handle forKey:KeyIsMediaLoaderRegisterNativeHandle];
    _medialoaderProtocolRegistered = [self.player getMedialoaderProtocolRegistered];
}

- (void)_registerHLSProxyProtocolHandle {
    
    if (![TTVideoEngine ls_localServerConfigure].isEnableHLSProxy) {
        return;
    }
    if (_hlsproxyProtocolRegistered) {
        return;
    }
#if USE_HLSPROXY
    void *handle = [HLSProxyModule getHlsProxyProtocol];
    TTVideoEngineLog(@"hlsproxymodlue get handle:%p \n",handle);
    if (handle == NULL) {
        return;
    }
    [self.player setValueVoidPTR:handle forKey:KeyIsHLSProxyRegisterNativeHandle];
    _hlsproxyProtocolRegistered = [self.player getHLSProxyProtocolRegistered];
#endif
}

- (void)_setupSubtitleInfo {
    //direct url situation
    if (self.subDecInfoModel.subtitleCount) {
        TTVideoEngineLog(@"subtitle: in sub model way")
        [self.eventLogger setSubtitleLangsCount:self.subDecInfoModel.subtitleCount];
        [self __setupSubtitleInfoWithSubModel];
    }
    
    //vid / video model situation
    else if (self.playSource.subtitleInfos && self.playSource.subtitleInfos.count) {
        TTVideoEngineLog(@"subtitle: in vid request way")
        [self.eventLogger setSubtitleLangsCount:self.playSource.subtitleInfos.count];
        [self __setupSubtitleInfoWithRequest];
    }
}

- (void)__setupSubtitleInfoWithSubModel {
    [self.eventLogger setSubtitleEnableOptLoad:self.options.enableSubtitleLoadOpt];
    [self.eventLogger setSubtitleThreadEnable:self.subThreadEnable];
    if (!self.subThreadEnable) return;
    NSString *jsonString = [self.subDecInfoModel jsonString];
    if (jsonString.length) {
        self.player.subTitleUrlInfo = jsonString;
        TTVideoEngineLog(@"subtitle: set sub model info finished")
    }
}

- (void)__setupSubtitleInfoWithRequest {
    [self.eventLogger setSubtitleEnableOptLoad:self.options.enableSubtitleLoadOpt];
    [self.eventLogger setSubtitleThreadEnable:self.subThreadEnable];
    if (!self.subThreadEnable) return;
    NSString *host = self.subtitleHostName;
    NSString *vid = self.playSource.videoId;
    NSString *fileId = [self.playSource usingUrlInfo].fieldId;
    NSString *language = self.subLangQuery;
    NSString *format = self.options.subFormatQuery;
    NSString *urlString = [self _getSubtitleUrlWithHostName:host
                                                        vid:vid
                                                     fileId:fileId
                                                   language:language
                                                     format:format];
    //log
    [self.eventLogger setSubtitleRequestUrl:urlString];
    if (!urlString.length)
        return;
    
    TTVideoEngineLog(@"subtitle: url info request")
    @weakify(self)
    [self _requestSubtitleInfoWithUrlString:urlString handler:^(NSString * _Nullable jsonString, NSError * _Nullable error) {
        @strongify(self)
        if (jsonString.length) {
            self.player.subTitleUrlInfo = jsonString;
            TTVideoEngineLog(@"subtitle: set requested url info finished")
        }
        
        //log
        [self.eventLogger setSubtitleRequestFinishTime:[[NSDate date] timeIntervalSince1970] * 1000];
        if (error)
            [self.eventLogger setSubtitleError:error];
    }];
}

- (void)setLoadControl:(id<TTAVPlayerLoadControlInterface>)loadControl {
    _loadControl = loadControl;
    [self.player setLoadControl:self.loadControl];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_LOADCONTROL value:1];
}

- (void)setMaskInfoDelegate:(id<TTVideoEngineMaskDelegate>)maskInfoDelegate {
    _maskInfoDelegate = maskInfoDelegate;
}

- (void)setAiBarrageInfoDelegate:(id<TTVideoEngineAIBarrageDelegate>)aiBarrageInfoDelegate {
    TTVideoEngineLog(@"AIBarrage: set AI Barrage delegate: %d", aiBarrageInfoDelegate != nil ? 1 : 0);
    [self.aiBarrager resetBarrageDelegate:aiBarrageInfoDelegate];
}

- (nonnull NSString *) produceUserAgentString {
    NSInteger appId = -1;
    if (TTVideoEngineAppInfo_Dict[TTVideoEngineAID] &&
        [TTVideoEngineAppInfo_Dict[TTVideoEngineAID] respondsToSelector:@selector(integerValue)]) {
        appId = [TTVideoEngineAppInfo_Dict[TTVideoEngineAID] integerValue];
    }
    
    NSString *traceId = @"null";
    if (self.eventLogger) {
        traceId = [self.eventLogger getTraceId];
    }
    
    NSString *appSessionId = @"null";
    TTVideoEngineEventUtil *sharedEventUtil = [TTVideoEngineEventUtil sharedInstance];
    if (sharedEventUtil.appSessionId) {
        appSessionId = sharedEventUtil.appSessionId;
    }
    
    NSString *tag = _logInfoTag ?: @"default";
    
    NSString *uaStr = [NSString stringWithFormat:@"appId:%ld,os:iOS,traceId:%@,appSessionId:%@,tag:%@", appId, traceId, appSessionId, tag];
    return uaStr;
}

- (void)_reportPreloadGearData {
    
    //for min play data statistics
    int64_t min_audio_frame_size = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMinAudioFrameSize];
    int64_t min_video_frame_size = [_player getInt64Value:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsMinVideoFrameSize];
    int min_video_frame_count = [_player getIntValue:LOGGER_INTEGER_INVALID_VALUE forKey:KeyIsFeedInCountBeforeFirstDecode];
    [self.eventLogger setInt64Option:LOGGER_OPTION_MIN_VIDEO_FRAME_SIZE value:min_video_frame_size];
    [self.eventLogger setInt64Option:LOGGER_OPTION_MIN_AUDIO_FRAME_SIZE value:min_audio_frame_size];
    [self.eventLogger setIntOption:LOGGER_OPTION_MIN_FEEDIN_COUNT_BEFORE_DECODED value:min_video_frame_count];
    if (self.enablePlayerPreloadGear) {
        NSString *gearInfo = [self.player getStringValueForKey:KeyIsPreloadGear];
        NSDictionary *gearInfoDic = TTVideoEngineStringToDicForIntvalue(gearInfo, @"=", @";");
        if (gearInfoDic && [gearInfoDic isKindOfClass:[NSDictionary class]]) {
            [self.eventLogger setPreloadGearInfo:gearInfoDic];
        }
    }
}

#pragma mark - observer for key

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
   if (context == Context_playerView_playViewBounds) {
       CGRect bounds = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
       CGFloat scale = [UIScreen mainScreen].scale;
       TTVideoEngineLog(@"[ABR] set displayViewBounds:%f, %f",CGRectGetWidth(bounds) * scale,CGRectGetHeight(bounds) * scale);
       NSInteger viewWidth = CGRectGetWidth(bounds) * [UIScreen mainScreen].scale;
       NSInteger viewHeight = CGRectGetHeight(bounds) * [UIScreen mainScreen].scale;
       [self.abrModule setIntValue:viewWidth forKey:ABRKeyIsPlayerDisplayWidth];
       [self.abrModule setIntValue:viewHeight forKey:ABRKeyIsPlayerDisplayHeight];
    }
}

- (void) removeObserversForAbr {
    @try {
        [self.playerView removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(bounds))
                           context:Context_playerView_playViewBounds];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
}

- (void)setEnableAVStack:(NSInteger)enableAVStack {
    _enableAVStack = enableAVStack;
    [_player setIntValue:(int)enableAVStack forKey:KeyIsEnableAVStack];
}

- (void)setMaskStopTimeout:(NSInteger)maskStopTimeout {
    _maskStopTimeout = maskStopTimeout;
    [_player setIntValue:(int)maskStopTimeout forKey:KeyIsMaskStopTimeout];
}

- (void)setSubtitleStopTimeout:(NSInteger)subtitleStopTimeout {
    _subtitleStopTimeout = subtitleStopTimeout;
    [_player setIntValue:(int)subtitleStopTimeout forKey:KeyIsSubtitleStopTimeout];
}

- (void)setTerminalAudioUnitPool:(BOOL)terminalAudioUnitPool {
    _terminalAudioUnitPool = terminalAudioUnitPool;
    [_player setIntValue:terminalAudioUnitPool forKey:KeyIsTerminalAudioUnitPool];
}

#pragma mark - lazy load
- (id<TTVideoEngineNetClient>)subtitleNetworkClient {
    if (!_subtitleNetworkClient) {
        _subtitleNetworkClient = [[TTVideoEngineNetwork alloc] initWithTimeout:10.0];
    }
    return _subtitleNetworkClient;
    
}

- (TTVideoEngineAVAIBarrager *)aiBarrager {
    if (!_aiBarrager) {
        _aiBarrager = [[TTVideoEngineAVAIBarrager alloc] initWithVideoEngine:self];
    }
    return _aiBarrager;
}

- (id<TTVideoEngineNetworkPredictorAction>)networkPredictorAction {
    if (!_networkPredictorAction) {
        _networkPredictorAction = [[TTVideoEngineActionManager shareInstance] actionObjWithProtocal:@protocol(TTVideoEngineNetworkPredictorAction)];
    }
    return _networkPredictorAction;
}

- (Class)networkPredictorActionClass {
    Class objclass = [[TTVideoEngineActionManager shareInstance] actionClassWithProtocal:@protocol(TTVideoEngineNetworkPredictorAction)];
    return objclass;
}

- (void)setIsEnablePostPrepareMsg:(BOOL)isEnablePostPrepareMsg {
    _isEnablePostPrepareMsg = isEnablePostPrepareMsg;
    [_player setIntValue:isEnablePostPrepareMsg forKey:KeyIsPostPrepare];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_ASYNC_PREPARE value:isEnablePostPrepareMsg?1:0];
}

- (void)setAudioLatencyQueueByTime:(BOOL)audioLatencyQueueByTime {
    _audioLatencyQueueByTime = audioLatencyQueueByTime;
    [_player setIntValue:audioLatencyQueueByTime forKey:KeyIsDynAudioLatencyByTime];
}

- (void)setVideoEndIsAllEof:(BOOL)videoEndIsAllEof {
    _videoEndIsAllEof = videoEndIsAllEof;
    [_player setIntValue:videoEndIsAllEof forKey:KeyIsSettingVideoEndIsAllEof];
}

- (void)setEnableBufferingMilliSeconds:(BOOL)enableBufferingMilliSeconds {
    _enableBufferingMilliSeconds = enableBufferingMilliSeconds;
    [_player setIntValue:enableBufferingMilliSeconds forKey:KeyIsEnableBufferingMilliSeconds];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_BUFFER_MILLI_SECONDS value:enableBufferingMilliSeconds?1:0];
}

- (void)setEnable720pSR:(BOOL)enable720pSR {
    _enable720pSR = enable720pSR;
    [_player setIntValue:enable720pSR forKey:KeyIsEnable720PSR];
}

- (void)setEnableKeepFormatThreadAlive:(BOOL)enableKeepFormatThreadAlive {
    _enableKeepFormatThreadAlive = enableKeepFormatThreadAlive;
    [_player setIntValue:enableKeepFormatThreadAlive forKey:KeyIsKeepFormatThreadAlive];
    [self.eventLogger setIntOption:LOGGER_OPTION_ENABLE_FORMATER_KEEP_ALIVE value:enableKeepFormatThreadAlive?1:0];
}

- (void)setEnableFFCodecerHeaacV2Compat:(BOOL)enableFFCodecerHeaacV2Compat {
    _enableFFCodecerHeaacV2Compat = enableFFCodecerHeaacV2Compat;
    [_player setIntValue:enableFFCodecerHeaacV2Compat forKey:KeyIsEnablePrimingWorkAround];
}

- (void)setDefaultBufferingEndMilliSeconds:(NSInteger)defaultBufferingEndMilliSeconds {
    _defaultBufferingEndMilliSeconds = defaultBufferingEndMilliSeconds;
    [_player setIntValue:defaultBufferingEndMilliSeconds forKey:KeyIsDefaultBufferingEndMilliSeconds];
    [self.eventLogger setIntOption:LOGGER_OPTION_BUFFER_END_MILLI_SECONDS value:defaultBufferingEndMilliSeconds];
}

- (void)setMaxBufferEndMilliSeconds:(NSInteger)maxBufferEndMilliSeconds {
    _maxBufferEndMilliSeconds = maxBufferEndMilliSeconds;
    [_player setIntValue:maxBufferEndMilliSeconds forKey:KeyIsMaxBufferEndMilliSeconds];
}

- (void)setDecreaseVtbStackSize:(NSInteger)decreaseVtbStackSize {
    _decreaseVtbStackSize = decreaseVtbStackSize;
    [_player setIntValue:decreaseVtbStackSize forKey:KeyIsDecreaseVtbStackSize];
}

- (void)setDisableShortSeek:(BOOL)disableShortSeek {
    _disableShortSeek = disableShortSeek;
    [_player setIntValue:disableShortSeek forKey:KeyIsDisableShortSeek];
    [self.eventLogger setIntOption:LOGGER_OPTION_DISABLE_SHORT_SEEK value:disableShortSeek?1:0];
}

- (void)setHdr10VideoModelLowBound:(NSInteger)hdr10VideoModelLowBound {
    _hdr10VideoModelLowBound = hdr10VideoModelLowBound;
}

- (void)setHdr10VideoModelHighBound:(NSInteger)hdr10VideoModelHighBound {
    _hdr10VideoModelHighBound = hdr10VideoModelHighBound;
}

- (void) setPreferSpdl4HDR:(BOOL)preferSpdl4HDR {
    _preferSpdl4HDR = preferSpdl4HDR;
     [_player setIntValue:preferSpdl4HDR forKey:KeyIsPreferSpdlForHDR];
}


- (void)setEnableLazyAudioUnitOp:(BOOL)enableLazyAudioUnitOp {
    _enableLazyAudioUnitOp = enableLazyAudioUnitOp;
    [_player setIntValue:enableLazyAudioUnitOp forKey:KeyIsEnableLazyVoiceOp];
}

- (void)setPreferSpdl4HDRUrl:(BOOL)preferSpdl4HDRUrl {
    _preferSpdl4HDRUrl = preferSpdl4HDRUrl;
}

- (void)setFFmpegProtocol:(id<TTVideoEngineFFmpegProtocol>) obj {
    if ([obj conformsToProtocol:@protocol(TTVideoEngineFFmpegProtocol)]) {
        _ffmpegProtocol = obj;
    }
}

- (void)setIsEnableVsyncHelper:(NSInteger)isEnableVsyncHelper {
    _isEnableVsyncHelper = isEnableVsyncHelper;
    [_player setIntValue:isEnableVsyncHelper forKey:KeyIsEnableVsyncHelper];
}

- (void)setCustomizedVideoRenderingFrameRate:(NSInteger)customizedVideoRenderingFrameRate {
    _customizedVideoRenderingFrameRate = customizedVideoRenderingFrameRate;
    [_player setIntValue:customizedVideoRenderingFrameRate forKey:KeyIsCustomizedVideoRenderingFrameRate];
}

- (void)_tryConfigVodStrategyInfo {
    /// vod strategy get playerHolder
    if ([TTVideoEngine ls_localServerConfigure].enableIOManager) {
        NSString *mediaId = self.playSource.videoId;
        [_eventLogger addFeature:FEATURE_KEY_PLAY_LOAD value:@(self.options.preciseCache)];
        if ([self.playSource isKindOfClass:[TTVideoEnginePlayVidSource class]]) {
            if (self.options.enableStrategyAutoAddMedia) {
                [TTVideoEngineStrategy.helper.manager addMedia:[(TTVideoEnginePlayVidSource *)self.playSource fetchData].toMediaInfoJsonString
                                                       sceneId:nil
                                                          last:NO
                                                       interim:YES];
            }
        }
        else if ([self.playSource isMemberOfClass:[TTVideoEnginePlayLocalSource class]]) {
            mediaId = TTVideoEngineBuildMD5(self.playSource.currentUrl);
        }
        else if ([self.playSource isKindOfClass:[TTVideoEnginePlayUrlSource class]]) {
            if (self.options.enableStrategyAutoAddMedia) {
                [TTVideoEngineStrategy.helper.manager addMedia:[(TTVideoEnginePlayUrlSource *)self.playSource mediaInfo].ttvideoengine_jsonString
                                                       sceneId:nil
                                                          last:NO
                                                       interim:YES];
            }
        }
        
        if (self.options.enableStrategyAutoAddMedia) {
            TTVideoEngineLog(@"vod strategy, mediaId = %@, traceId = %@",mediaId,_traceId);
            if (mediaId.length > 0) {
                [_player setValueString:mediaId forKey:KeyIsMediaId];
            }
            
            int64_t iPlayer = [_player getInt64ValueForKey:KeyIsGetPlayerHolder];
            if (iPlayer != 0) {
                [[TTVideoEngineStrategy.helper manager] createPlayer:iPlayer mediaId:mediaId traceId:_traceId tag:_logInfoTag ?: @"default"];
                [[TTVideoEngineStrategy.helper manager] setPlayerOption:iPlayer optionKey:VCVodStrategyPlayerOptionRangeControl optionValue:_options.enableStrategyRangeControl];
            }
        }
    }
}

- (void)_configHardwareDecode {
    NSInteger hdConfig = [[TTVideoEngineSettings.settings getVodNumber:@"config_hardware_type" dValue:@0] integerValue];
    if (hdConfig > 0) {
        if (hdConfig == 2) {/// VideoModle
            NSString *decoding_mode = [self.playSource decodingMode];
            if([decoding_mode isEqualToString:@"hw"]){
                _hardwareDecode = YES;
                self.player.hardwareDecode = YES;
            }
        }
        else if(hdConfig == 3) { /// settings
            /// for videoModel
            NSDictionary *codeDict = nil;
            if ([[[self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"] getValueStr:VALUE_CODEC_TYPE] isEqualToString:kTTVideoEngineCodecH264]) {
                codeDict = [TTVideoEngineSettings.settings getVodDict:@"hardware_decode_bytevc0"];
            } else if ([[[self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"] getValueStr:VALUE_CODEC_TYPE] isEqualToString:kTTVideoEngineCodecByteVC1]) {
                codeDict = [TTVideoEngineSettings.settings getVodDict:@"hardware_decode_bytevc1"];
            } else if ([[[self.playSource urlInfoForResolution:self.currentResolution mediaType:@"video"] getValueStr:VALUE_CODEC_TYPE] isEqualToString:kTTVideoEngineCodecByteVC2]) {
                codeDict = [TTVideoEngineSettings.settings getVodDict:@"hardware_decode_bytevc2"];
            }
            if (codeDict) {
                NSInteger hardware = [[codeDict objectForKey:@"value"] integerValue];
                NSArray *allowList = [codeDict objectForKey:@"allow_tag_list"];
                NSArray *blockList = [codeDict objectForKey:@"block_tag_list"];
                NSString *tag = _logInfoTag ?: @"default";
                if (blockList && [blockList isKindOfClass:[NSArray class]]) {
                    if (![blockList containsObject:tag]) {
                        _hardwareDecode = hardware;
                        self.player.hardwareDecode = hardware;
                    }
                } else if (allowList && [allowList isKindOfClass:[NSArray class]]) {
                    if ([allowList containsObject:tag]) {
                        _hardwareDecode = hardware;
                        self.player.hardwareDecode = hardware;
                    }
                } else if (!allowList && !blockList) {
                    _hardwareDecode = hardware;
                    self.player.hardwareDecode = hardware;
                }
            } else {
                NSInteger hardware = [[TTVideoEngineSettings.settings getVodNumber:@"hardware_decode" dValue:@(_hardwareDecode)] integerValue];
                _hardwareDecode = hardware;
                self.player.hardwareDecode = hardware;
            }
            
            TTVideoEngineLog(@"hardware use settings. value is %d, dict: %@", _hardwareDecode, codeDict);
        }
    }
    else {
        if(_didSetHardware == NO || _serverDecodingMode == YES){
            NSString *decoding_mode = [self.playSource decodingMode];
            if([decoding_mode isEqualToString:@"hw"]){
                _hardwareDecode = YES;
                self.player.hardwareDecode = YES;
            }
        }
    }
}

- (NSArray<TTVideoEngineURLInfo *> *)getUrlInfoList {
    return [self.playSource getVideoList];
}

- (void) _syncPlayInfoToMdlForKey:(NSInteger)key Value:(int64_t)value {
    if(self.medialoaderEnable == NO || self.medialoaderCdnType == 0) {
        return;
    }
    
    NSInteger mdlKey;
    switch (key) {
        case VEKPlayInfoRenderStart:
            mdlKey = MdlKeyPlayInfoRenderStart;
            break;
        case VEKPlayInfoPlayingPos:
            mdlKey = MdlKeyPlayInfoPlayingPos;
            break;
        case VEKPlayInfoLoadPercent:
            mdlKey = MdlKeyPlayInfoLoadPercent;
            break;
        case VEKPlayInfoBufferingStart:
            mdlKey = MdlKeyPlayInfoBufferingStart;
            break;
        case VEKPlayInfoBufferingEnd:
            mdlKey = MdlKeyPlayInfoBufferingEnd;
            break;
        case VEKPlayInfoCurrentBuffer:
            mdlKey = MdlKeyPlayInfoCurrentBuffer;
            break;
        case VEKPlayInfoSeekAction:
            mdlKey = MdlKeyPlayInfoSeekAction;
            break;
        default:
            return;
    }
    
    if(key == VEKPlayInfoCurrentBuffer) {
        // get current buffer
        value = -1;
        int64_t vb = [self.player getInt64ValueForKey:KeyIsVideoBufferLength];
        int64_t ab = [self.player getInt64ValueForKey:KeyIsAudioBufferLength];
        if(ab > 0 && ab > 0) {
            value = MIN(vb, ab);
        } else if(ab <= 0) {
            value = vb;
        } else if(vb <= 0) {
            value = ab;
        }
    }
    [self ls_setPlayInfo:mdlKey Traceid:_traceId Value:value];
}

- (void) _startTimerToSyncPlayInfo {
    if(self.medialoaderEnable == NO || self.medialoaderCdnType == 0 || self.mediaLoaderPcdnTimerInterval == 0) {
        return;
    }
    
    if (self.pcdnTimer && [self.pcdnTimer isValid]) {
        [self.pcdnTimer invalidate];
    }
    @weakify(self)
    void (^pcdnBlock)(void) = ^(){
        @strongify(self);
        if (!self) {
            return;
        }

        [self _syncPlayInfoToMdlForKey:VEKPlayInfoCurrentBuffer Value:0];
    };
    NSTimeInterval ti = self.mediaLoaderPcdnTimerInterval / 1000.0f;
    self.pcdnTimer = [NSTimer ttvideoengine_scheduledTimerWithTimeInterval:ti queue:dispatch_get_global_queue(0,0) block:pcdnBlock repeats:YES];
}

- (void) _stopTimerToSyncPlayInfo {
    if (self.pcdnTimer && [self.pcdnTimer isValid]) {
        [self.pcdnTimer invalidate];
    }
}

- (void)_startCheckPreloadTimer {
    if (!self.isEnablePreloadCheckTimer || self.easyPreloadThreshold <= 0) {
        return;
    }
    
    if (self.checkPreloadTimer && [self.checkPreloadTimer isValid]) {
        [self.checkPreloadTimer invalidate];
    }
    @weakify(self)
    void (^block)(void) = ^(){
        @strongify(self);
        if (!self) {
            return;
        }

        [self _ls_tryToNotifyPrelaod];
    };
    NSTimeInterval ti = self.easyPreloadThreshold;
    self.checkPreloadTimer = [NSTimer ttvideoengine_scheduledTimerWithTimeInterval:ti queue:dispatch_get_global_queue(0,0) block:block repeats:YES];
}

- (void)_stopCheckPreloadTimer {
    if (self.checkPreloadTimer && [self.checkPreloadTimer isValid]) {
        [self.checkPreloadTimer invalidate];
    }
}

- (void)setRecheckVPLSforDirectBuffering:(BOOL)recheckVPLSforDirectBuffering {
    _recheckVPLSforDirectBuffering = recheckVPLSforDirectBuffering;
}

- (NSString*)responderChain {
    if (!_responderChain) {
        NSMutableString *str = [NSMutableString string];
        for (UIResponder *responder = self.playerView;
             responder != nil;
             responder = [responder nextResponder]) {
            if (![responder isMemberOfClass:[UIView class]]) {
                [str appendFormat:@"%@,", [responder class]];
            }
        }
        _responderChain = [str copy];
    }
    return _responderChain;
}

- (void)crosstalkHappen:(NSMutableArray *)crosstalkEngines {
    NSMutableArray *infoList = [NSMutableArray array];
    
    NSDictionary *selfDict = @{
        @"tag" : self.logInfoTag?:@"",
        @"subtag" : self.subtag?:@"",
        @"view_tree_info" : self.responderChain?:@""
    };
    [infoList addObject:selfDict];
    
    for (TTVideoEngine *engine in crosstalkEngines) {
        if (![engine isEqual:self]) {
            NSDictionary *dict = @{
                @"tag" : engine.logInfoTag?:@"",
                @"subtag" : engine.subtag?:@"",
                @"view_tree_info" : engine.responderChain?:@""
            };
            [infoList addObject:dict];
        }
    }
    
    [_eventLogger crosstalkHappen:crosstalkEngines.count infoList:infoList];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEngine:crosstalkHappen:)]) {
        [self.delegate videoEngine:self crosstalkHappen:nil];
    }
}

- (NSDictionary*)getEnginePlayInfo {
    int64_t videoBufferLen = [self.player getInt64ValueForKey:KeyIsVideoBufferLength];
    int64_t audioBufferLen = [self.player getInt64ValueForKey:KeyIsAudioBufferLength];
    return @{
        @"tag" : self.logInfoTag?:@"",
        @"subTag" : self.subtag?:@"",
        @"playbackState" : @(self.playbackState),
        @"hasLoadingResources" : (videoBufferLen > 0 || audioBufferLen > 0) ? @(YES) : @(NO)
    };
}

- (void)setCustomCompanyID:(nullable NSString *)companyID {
    if ([companyID isKindOfClass:[NSString class]]) {
        self.mCompanyId = companyID;
    }
}

@end
