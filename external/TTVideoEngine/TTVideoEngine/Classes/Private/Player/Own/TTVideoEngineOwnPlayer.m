//
//  TTOwnAVPlayer.m
//  Article
//
//  Created by panxiang on 16/10/24.
//
//

#import "TTVideoEngineDualCore.h"
#import "TTVideoEngineOwnPlayerVanGuard.h"
#import "TTVideoEngineOwnPlayer.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineExtraInfo.h"
#import "TTVideoEngine+Private.h"
#import "NSTimer+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#include <pthread.h>
#import <TTPlayerSDK/TTAVPlayer.h>

// resume play after stall
static const float kMaxHighWaterMarkMilli = 5 * 1000;
static const NSInteger kPlayerItemBroken = 5003;

static void *Context_player_currentItem = &Context_player_currentItem;
static void *Context_player_loadState = &Context_player_loadState;
static void *Context_player_playbackState = &Context_player_playbackState;

static void *Context_playerItem_loadedTimeRanges = &Context_playerItem_loadedTimeRanges;
static void *Context_playerItem_state = &Context_playerItem_state;
static void *Context_playerItem_playbackBufferEmpty = &Context_playerItem_playbackBufferEmpty;
static void *Context_playerItem_playbackBufferFull = &Context_playerItem_playbackBufferFull;
static void *Context_playerItem_playbackLikelyToKeepUp = &Context_playerItem_playbackLikelyToKeepUp;

static NSString *const kTTVideoEngineHTTPHeaderHostKey = @"Host";
static NSString *const kTTVideoEngineHTTPHeaderUAKey = @"User-Agent";
static NSString *const kTTVideoEngineHTTPHeaderUAValue = @"ttplayer(ios-sdk)";

static BOOL kMedialoaderProtocolRegistered = false;
static BOOL kHLSProxyProtocolRegistered = false;

@interface TTVideoEngineOwnPlayer()

@property(nonatomic, assign) NSTimeInterval playableDuration;
@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, strong) UIView *view;
@property(nonatomic, assign) NSInteger bufferingProgress;
@property(nonatomic, assign) BOOL isPreparedToPlay;
@property(nonatomic, copy) NSString *filePath;
@property(nonatomic, copy) NSString *fileKey;
@property(nonatomic, copy) NSString *decryptionKey;
@property(nonatomic, copy) NSString *defaultCacheFileDir;
@property (nonatomic, copy) NSString* vid;
@property (nonatomic, assign) DrmCreater drmCreater;
@property (nonatomic, readwrite) TTVideoEngineDrmType drmType;
@property (nonatomic, assign) NSInteger drmDowngrade;
@property (nonatomic, copy) NSString *tokenUrlTemplate;
@property (nonatomic, assign) NSInteger cacheMaxSeconds;
@property (nonatomic, assign) NSInteger bufferingTimeOut;
@property (nonatomic, assign) NSInteger maxBufferEndTime;
@property (nonatomic, copy) NSString *playUrl;
@property (nonatomic, copy) NSString *videoCheckInfo;
@property (nonatomic, copy) NSString *audioCheckInfo;
@property (nonatomic, assign) BOOL hijackExit;
@property (nonatomic, assign) BOOL reportRequestHeaders;
@property (nonatomic, assign) BOOL reportResponseHeaders;
/// 0: init value;  -1: not support background; 1: support background;
@property (nonatomic, assign) NSInteger currentAudioCategory;
@property (nonatomic, assign) BOOL enableTimerBarPercentage;
@property (nonatomic, assign) BOOL enableDashAbr;
@property (nonatomic, assign) BOOL enableIndexCache;
@property (nonatomic, assign) BOOL enableFragRange;
@property (nonatomic, assign) BOOL enableAsync;
@property (nonatomic, readwrite) TTVideoEngineRangeMode rangeMode;
@property (nonatomic, readwrite) TTVideoEngineReadMode readMode;
@property (nonatomic, assign) NSInteger videoRangeSize;
@property (nonatomic, assign) NSInteger audioRangeSize;
@property (nonatomic, assign) NSInteger videoRangeTime;
@property (nonatomic, assign) NSInteger audioRangeTime;
@property (nonatomic, assign) NSInteger skipFindStreamInfo;
@property (nonatomic, readwrite) TTVideoEngineUpdateTimestampMode updateTimestampMode;
@property (nonatomic, assign) BOOL enableOpenTimeout;
@property (nonatomic, assign) BOOL handleAudioExtradata;
@property (nonatomic, assign) BOOL enableTTHlsDrm;
@property(nonatomic, copy) NSString *ttHlsDrmToken;
@property (nonatomic, assign) BOOL enableEnterBufferingDirectly;
@property (nonatomic, assign) NSInteger outputFramesWaitNum;
@property (nonatomic, assign) NSInteger startPlayAudioBufferThreshold;
@property (nonatomic, assign) TTVideoEngineAudioChannelType audioChannelType;
@property (nonatomic, assign) BOOL audioEffectEnabled;
@property (nonatomic, assign) CGFloat audioEffectPregain;
@property (nonatomic, assign) CGFloat audioEffectThreshold;
@property (nonatomic, assign) CGFloat audioEffectRatio;
@property (nonatomic, assign) CGFloat audioEffectPredelay;
@property (nonatomic, assign) CGFloat audioEffectPostgain;
@property (nonatomic, assign) NSInteger audioEffectType;
@property (nonatomic, assign) CGFloat audioEffectSrcLoudness;
@property (nonatomic, assign) CGFloat audioEffectSrcPeak;
@property (nonatomic, assign) CGFloat audioEffectTarLoudness;
@property (nonatomic, assign) BOOL audioUnitPoolEnabled;
@property (nonatomic, assign) BOOL avSyncStartEnable;
@property (nonatomic, assign) BOOL codecDropSkippedFrame;
@property (nonatomic, assign) NSInteger threadWaitTimeMS;
@property (nonatomic, assign) BOOL enableRadioMode;
@property (nonatomic, assign) BOOL playerLazySeek;
@property (nonatomic, assign) BOOL dummyAudioSleep;
@property (nonatomic, copy) NSString *barrageMaskUrl;
@property (nonatomic, copy) NSString *aiBarrageUrl;
@property (nonatomic, assign) BOOL isPreparedAsync;
@property (nonatomic, assign) BOOL isPlayedinPreparedAsync;
@property (nonatomic, assign) NSInteger defaultBufferEndTime;
@property (nonatomic, assign) NSInteger decoderOutputType;
@property (nonatomic, assign) NSInteger prepareMaxCachesMs;
@property (nonatomic, assign) NSInteger mdlCacheMode;
@property (nonatomic, assign) NSInteger httpAutoRangeOffset;
@property (nonatomic, assign) id<TTAVPlayerLoadControlInterface> loadControl;
@property (nonatomic, weak) id<TTAVPlayerMaskInfoInterface> maskInfo;
@property (nonatomic, weak) id<TTAVPlayerMaskInfoInterface> aiBarrageInfo;
@property (nonatomic, assign) BOOL enableNNSR;
@property (nonatomic, assign) NSInteger nnsrFPSThreshold;
@property (nonatomic, assign) BOOL enableRange;
@property (nonatomic, assign) NSInteger normalClockType;
@property (nonatomic, assign) BOOL enableAllResolutionVideoSR;
@property (nonatomic, assign) NSInteger skipBufferLimit;
@property (nonatomic, assign) NSInteger enableAVStack;
@property (nonatomic, assign) BOOL terminalAudioUnitPool;
@property (nonatomic, assign) BOOL audioLatencyQueueByTime;
@property (nonatomic, assign) BOOL videoEndIsAllEof;
@property (nonatomic, assign) BOOL enableBufferingMilliSeconds;
@property (nonatomic, assign) BOOL enableKeepFormatThreadAlive;
@property (nonatomic, assign) BOOL enable720pSR;
@property (nonatomic, assign) BOOL enableFFCodecerHeaacV2Compat;
@property (nonatomic, assign) NSInteger defaultBufferingEndMilliSeconds;
@property (nonatomic, assign) NSInteger maxBufferEndMilliSeconds;
@property (nonatomic, assign) NSInteger decreaseVtbStackSize;
@property (nonatomic, assign) BOOL isEnablePostPrepareMsg;
@property (nonatomic, assign) BOOL disableShortSeek;
@property (nonatomic, assign) BOOL IsPreferNearestSample;
@property (nonatomic, assign) NSInteger preferNearestMaxPosOffset;
@property (nonatomic, assign) NSInteger findStreamInfoProbeSize;
@property (nonatomic, assign) NSInteger findStreamInfoProbeDuration;
@property (nonatomic, assign) NSInteger isEnableRefreshByTime;
@property (nonatomic, assign) NSInteger liveStartIndex;
@property (nonatomic, assign) NSInteger enableFallbackSWDecode;
@property (nonatomic, assign) BOOL enableHDR10;
@property (nonatomic, assign) BOOL preferSpdl4HDR;
@property (nonatomic, assign) BOOL stopSourceAsync;
@property (nonatomic, assign) BOOL enableSeekInterrupt;
@property (nonatomic, assign) BOOL enableLazyAudioUnitOp;
@property (nonatomic, assign) NSInteger changeVtbSizePicSizeBound;
@property (nonatomic, assign) BOOL enableRangeCacheDuration;
@property (nonatomic, assign) BOOL enableVoiceSplitHeaacV2;
@property (nonatomic, assign) BOOL enableAudioHardwareDecode;
@property (nonatomic, assign) BOOL delayBufferingUpdate;
@property (nonatomic, assign) BOOL noBufferingUpdate;
@property (nonatomic, assign) BOOL enableHookVoice;
@property (nonatomic, assign) BOOL keepVoiceDuration;
@property (nonatomic, assign) NSInteger voiceBlockDuration;
@property (nonatomic, assign) BOOL enableSRBound;
@property (nonatomic, assign) NSInteger srLongDimensionLowerBound;
@property (nonatomic, assign) NSInteger srLongDimensionUpperBound;
@property (nonatomic, assign) NSInteger srShortDimensionLowerBound;
@property (nonatomic, assign) NSInteger srShortDimensionUpperBound;
@property (nonatomic, assign) BOOL filePlayNoBuffering;
@property (nonatomic, copy) NSString *mediaId;
@property (nonatomic, strong) NSMutableArray* effectParamArray;
@property (nonatomic, copy, nullable) NSString *userAgent;
@property (nonatomic, assign) BOOL enablePostStart;
@property (nonatomic, assign) BOOL enablePlayerPreloadGear;
@property (nonatomic, assign) NSInteger isEnableVsyncHelper;
@property (nonatomic, assign) NSInteger customizedVideoRenderingFrameRate;
@property (nonatomic, assign) BOOL enablePlaySpeedExtend;

@end


@implementation TTVideoEngineOwnPlayer {
    pthread_mutex_t _mutex;
    NSURL   *_playURL;
    NSDictionary *_header;
    id<TTVideoEngineDualCore> _dualCore;
    NSObject<TTAVPlayerItemProtocol>  *_playerItem;
    NSObject<TTAVPlayerProtocol>  *_player;
    UIView<TTPlayerViewProtocol> * _view;
    void *audioWrapper;
    void *videoWrapper;
    void *_medialoaderProtocolHandle;
    BOOL _medialoaderProtocolRegistered;
    void *_hlsProxyProtocolHandle;
    TTVideoEngineEnhancementType _enhancementType;
    TTVideoEngineImageScaleType _imageScaleType;
    TTVideoEngineImageLayoutType _imageLayoutType;
    TTVideoEngineRenderType _renderType;
    TTVideoEngineAudioDeviceType _hijackDummyVoice;
    AudioRenderDevice _audioDeviceType;
    BOOL _looping;
    BOOL _seekEndEnabled;
    NSInteger _smoothDelayedSeconds;
    NSInteger _defaultVideoBitrate;
    NSInteger _embellishTime;
    NSInteger _loopStartTime;
    NSInteger _loopEndTime;
    NSInteger _reuseSocket;
    NSInteger _disableAccurateStart;
    
    BOOL _isPrerolling;
    
    NSTimeInterval _seekingTime;
    BOOL _isSeeking;
    BOOL _isError;
    BOOL _isCompleted;
    BOOL _isShutdown;
    BOOL _isMuted;
    BOOL _playedToEnd;
    BOOL _ignoreAudioInterruption;
    BOOL _isPaused;
    
    CGFloat _playbackSpeed;
    
    NSMutableArray *_registeredNotifications;
    
    NSMutableDictionary<NSNumber*, NSNumber*> *_intOptions;
    NSMutableDictionary<NSNumber*, NSNumber*> *_floatOptions;
    BOOL _didStop;
    
    void *_precisePausePts;
}

@synthesize delegate = _delegate;
@synthesize view = _view;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;
@synthesize playableDuration = _playableDuration;
@synthesize bufferingProgress = _bufferingProgress;
@synthesize playbackState = _playbackState;
@synthesize loadState = _loadState;
@synthesize scalingMode = _scalingMode;
@synthesize isPauseWhenNotReady = _isPauseWhenNotReady;
@synthesize volume = _volume;
@synthesize muted = _muted;
@synthesize asyncInit = _asyncInit;
@synthesize asyncPrepare = _asyncPrepare;
@synthesize playbackSpeed = _playbackSpeed;
@synthesize resourceLoaderDelegate = _resourceLoaderDelegate;
@synthesize accessLog = _accesslog;
@synthesize enhancementType = _enhancementType;
@synthesize imageScaleType = _imageScaleType;
@synthesize imageLayoutType = _imageLayoutType;
@synthesize renderType = _renderType;
@synthesize renderEngine = _renderEngine;
@synthesize cacheFileMode = _cacheFileMode;
@synthesize testSpeedMode = _testSpeedMode;
@synthesize filePath = _filePath;
@synthesize fileKey = _fileKey;
@synthesize decryptionKey = _decryptionKey;
@synthesize openTimeOut = _openTimeOut;
@synthesize startTime = _startTime;
@synthesize hardwareDecode = _hardwareDecode;
@synthesize ksyByteVC1Decode = _ksyByteVC1Decode;
@synthesize drmCreater = _drmCreater;
@synthesize vid = _vid;
@synthesize drmType = _drmType;
@synthesize drmDowngrade = _drmDowngrade;
@synthesize tokenUrlTemplate = _tokenUrlTemplate;
@synthesize rotateType = _rotateType;
@synthesize loopWay = _loopWay;
@synthesize playUrl = _playUrl;
@synthesize barrageMaskUrl = _barrageMaskUrl;
@synthesize videoCheckInfo = _videoCheckInfo;
@synthesize audioCheckInfo = _audioCheckInfo;
@synthesize hijackExit = _hijackExit;
@synthesize reportRequestHeaders = _reportRequestHeaders;
@synthesize reportResponseHeaders = _reportResponseHeaders;
@synthesize enableDashAbr = _enableDashAbr;
@synthesize enableIndexCache = _enableIndexCache;
@synthesize enableFragRange = _enableFragRange;
@synthesize enableAsync = _enableAsync;
@synthesize rangeMode = _rangeMode;
@synthesize readMode = _readMode;
@synthesize videoRangeSize = _videoRangeSize;
@synthesize audioRangeSize = _audioRangeSize;
@synthesize videoRangeTime = _videoRangeTime;
@synthesize audioRangeTime = _audioRangeTime;
@synthesize skipFindStreamInfo = _skipFindStreamInfo;
@synthesize updateTimestampMode = _updateTimestampMode;
@synthesize enableOpenTimeout = _enableOpenTimeout;
@synthesize handleAudioExtradata = _handleAudioExtradata;
@synthesize mirrorType = _mirrorType;
@synthesize optimizeMemoryUsage = _optimizeMemoryUsage;
@synthesize barrageMaskEnable = _barrageMaskEnable;
@synthesize aiBarrageEnable = _aiBarrageEnable;
@synthesize engine = _engine;
@synthesize loadControl = _loadControl;
@synthesize maskInfo = _maskInfo;
@synthesize enableReportAllBufferUpdate = _enableReportAllBufferUpdate;
@synthesize subInfo = _subInfo;
@synthesize subEnable = _subEnable;
@synthesize subTitleUrlInfo = _subTitleUrlInfo;
@synthesize subLanguageId = _subLanguageId;
@synthesize enableRemoveTaskQueue = _enableRemoveTaskQueue;

- (instancetype)init
{
    return [self initWithType:TTVideoEnginePlayerTypeVanGuard async:NO];
}

- (instancetype)initWithType:(TTVideoEnginePlayerType)type async:(BOOL)async
{
    if (self = [super init]) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init (&attr);
        pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_mutex, &attr);
        pthread_mutexattr_destroy (&attr);
        _dualCore = [[TTPlayerVanGuardFactory alloc] init];
 
        _intOptions = [NSMutableDictionary dictionary];
        _floatOptions = [NSMutableDictionary dictionary];
        if (!async) {
            _view = [_dualCore viewWithFrame:[[UIScreen mainScreen] bounds]];
            _view.renderType = TTPlayerViewRenderTypeOpenGLES;
            _view.rotateType = TTPlayerViewRotateTypeNone;
        }
        _isPrerolling           = NO;
        // _isSeeking              = NO;
        _isError                = NO;
        _isCompleted            = NO;
        _playedToEnd            = NO;
        _testSpeedMode          = -1;
        _defaultVideoBitrate    = 0;
        _embellishTime          = 0;
        _loopStartTime          = 0;
        _loopEndTime            = 0;
        self.bufferingProgress  = 0;
        _isPreparedAsync        = NO;
        _isPlayedinPreparedAsync = NO;
        
        _loadState = TTVideoEngineLoadStateStalled;
        _playbackState = TTVideoEnginePlaybackStateStopped;
        _imageScaleType = TTVideoEngineImageScaleTypeLinear;
        _enhancementType = TTVideoEngineEnhancementTypeNone;
        _renderType = TTVideoEngineRenderTypeDefault;
        _renderEngine = TTVideoEngineRenderEngineOpenGLES;
        _audioDeviceType = AudioRenderDevcieDefault;
        _hijackDummyVoice = TTVideoEngineDeviceDefault;
        _mirrorType = -1;
        _decoderOutputType = 1;
        _smoothDelayedSeconds = -1;
        _drmType = TTVideoEngineDrmNone;
        _drmDowngrade = 0;
        _imageLayoutType = TTVideoEngineLayoutTypeToFill;
        
        _accesslog = [[TTVideoEngineAVPlayerItemAccessLog alloc] init];
        _startTime = 0;
        _openTimeOut = 5;
        _playbackSpeed = 1.0;
        _volume = 1.0;
        _asyncInit = false;
        _asyncPrepare = false;
        _cacheMaxSeconds = 30;
        _bufferingTimeOut = 30;
        _maxBufferEndTime = 4;
        _startPlayAudioBufferThreshold = 0;
        _audioEffectEnabled = NO;
        _audioEffectPregain = 0.25;
        _audioEffectThreshold = -18;
        _audioEffectRatio = 8;
        _audioEffectPredelay = 0.007;
        _audioEffectPostgain = 0.0;
        _audioEffectType = 0;
        _audioEffectSrcLoudness = 0.0;
        _audioEffectSrcPeak = 0.0;
        _audioEffectTarLoudness = 0.0;
        _optimizeMemoryUsage = YES;
        _view.memoryOptimizeEnabled = YES;
        _dummyAudioSleep = YES;
        _defaultBufferEndTime = 2;
        _hardwareDecode = YES;
        _handleAudioExtradata = YES;
        _barrageMaskEnable = NO;
        _aiBarrageEnable = NO;
        _subEnable = NO;
        _enableNNSR = NO;
        _nnsrFPSThreshold = 32;
        _prepareMaxCachesMs = 1000;
        _enableRange = NO;
        _enableAllResolutionVideoSR = NO;
        _enableAVStack = 0;
        _terminalAudioUnitPool = NO;
        _audioLatencyQueueByTime = NO;
        _videoEndIsAllEof = NO;
        _enable720pSR = NO;
        _enableFFCodecerHeaacV2Compat = NO;
        _enableKeepFormatThreadAlive = NO;
        _enableBufferingMilliSeconds = NO;
        _isEnablePostPrepareMsg = NO;
        _disableShortSeek = NO;
        _IsPreferNearestSample = NO;
        _playerLazySeek = YES;
        _preferNearestMaxPosOffset = 1048576;
        _defaultBufferingEndMilliSeconds = 1000;
        _maxBufferEndMilliSeconds = 5000;
        _decreaseVtbStackSize = 0;
        _enableHDR10 = NO;
        _findStreamInfoProbeSize = 5000000;
        _findStreamInfoProbeDuration = 0;
        _isEnableRefreshByTime = 0;
        _liveStartIndex = -3;
        _enableFallbackSWDecode = 1;
        _precisePausePts = nil;
        _isEnableVsyncHelper = 0;
        _customizedVideoRenderingFrameRate = 0;
        _enablePlaySpeedExtend = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRenderStart:) name:TTPlayerAudioRenderStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoSizeChange:) name:TTPlayerVideoSizeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoBitrateChange:) name:TTPlayerVideoBitrateChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOpened:) name:TTPlayerDeviceOpenedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preBufferingStart:) name:TTPlayerPreBufferingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outleterPaused:) name:TTPlayerOutleterPausedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(barrageMaskInfoNotificate:) name:TTPlayerBarrageMaskInfoNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avOutsyncStart:) name:TTPlayerAVOutsyncStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avOutsyncEnd:) name:TTPlayerAVOutsyncEndNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noVARenderStart:) name:@"TTPlayerNoVARenderStartNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noVARenderEnd:) name:@"TTPlayerNoVARenderEndNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimeNoVideoFrame:) name:TTPlayerStartTimeNoVideoFrame object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaInfoDidChanged:) name:TTPlayerInfoIdChangedNotification object:nil];
    }
    //TTVideoEngineLog(@"TTAVMoviePlayerController init: %p", self);
    return self;
}

- (void)dealloc {
    [self shutdown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    pthread_mutex_destroy(&_mutex);
    //TTVideoEngineLog(@"TTAVMoviePlayerController dealloc: %p", self);
}

- (NSURL *)contentURL {
    return _playURL;
}

- (void)setContentURL:(NSURL *)contentURL {
    _playURL = contentURL;
    
    if (!contentURL) {
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainOwnPlayer code:TTVideoEngineErrorUrlEmpty userInfo:@{@"info":@"contentUrl is null"}]];
    }
    TTVideoEngineLog(@"current url %@",contentURL);
}

- (void)setAVPlayerItem:(AVPlayerItem *)playerItem {
}

- (void)prepareToPlaySetPlayer {
    if (_delegate && [_delegate respondsToSelector:@selector(playerDidCreateKernelPlayer)]) {
        [_delegate playerDidCreateKernelPlayer];
    }
    
    _isPreparedToPlay = NO;
    
    [_intOptions enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [_player setIntValue:[obj intValue] forKey:[key intValue]];
    }];
    [_floatOptions enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [_player setFloatValue:[obj floatValue] forKey:[key intValue]];
    }];
//    [_player setIntValue:false forKey:KeyIsEnableThirdPartyProtocol];
    if ([_engine respondsToSelector:@selector(getFFmpegProtocolObject)]) {
        id<TTVideoEngineFFmpegProtocol> ffmpegProtocol = [_engine getFFmpegProtocolObject];
        if ([ffmpegProtocol conformsToProtocol:@protocol(TTVideoEngineFFmpegProtocol)]) {
            NSString *registerName = [_player getStringValueForKey:KeyIsThirdPartyProtocolName];
            NSString *thirdPartyName = [ffmpegProtocol getProtocolName];
            BOOL isRegistered = [registerName isEqualToString:thirdPartyName];
            if (isRegistered == NO) {
                void *protocolPtr = [ffmpegProtocol getURLProtocol];
                [_player setValueVoidPTR:protocolPtr forKey:KeyIsThirdPartyProtocolPtr];
            }
            if([ffmpegProtocol respondsToSelector:@selector(getAVDictionary)]) {
                void *avdictionary = [ffmpegProtocol getAVDictionary];
                [_player setValueVoidPTR:avdictionary forKey:KeyIsThirdPartyAVDictionarylPtr];
            }
        }
    }
    [_player setIntValue:_enablePlaySpeedExtend forKey:KeyIsPlaySpeedExtendEnable];
    [self setPlayerImageScaleType:self.imageScaleType];
    [self setPlayerEnhancementType:self.enhancementType];
    [self setPlayerLayoutType:self.imageLayoutType];
    [self setPlayerRenderType:self.renderType];
    [self setPlayerViewRenderEngine:self.renderEngine];
    [self setPlayerLooping:self.looping];
    [self setPlayerOpenTimeOut:self.openTimeOut];
    [self setPlayerSmoothDelayedSeconds:self.smoothDelayedSeconds];
    [self setPlayerStartTime:self.startTime];
    [self setPlayerPlaybackSpeed:self.playbackSpeed];
    [self setPlayerKsyByteVC1Decode:self.ksyByteVC1Decode];
    // [self setPlayerAudioDevice:_audioDeviceType];
    [_player setIntValue:_audioDeviceType forKey:KeyIsAudioDevice];

    if (_fileKey != nil) {
        [_player setValueString:_fileKey forKey:KeyIsMediaFileKey];
    }
    if (_filePath != nil) {
        [_player setCacheFile:_filePath mode:kOpenFileMode];
    }
    if (_defaultCacheFileDir) {
        [_player setValueString:_defaultCacheFileDir forKey:KeyIsCacheFileDir];
    }
    if (_decryptionKey != nil) {
        [_player setValueString:_decryptionKey forKey:KeyIsDecryptionKey];
    }
    if (_videoCheckInfo != nil) {
        [_player setValueString:_videoCheckInfo forKey:KeyIsVideoCheckInfo];
    }
    if (_audioCheckInfo != nil) {
        [_player setValueString:_audioCheckInfo forKey:KeyIsAudioCheckInfo];
    }
    [_player setIntValue:_barrageMaskEnable forKey:KeyIsBarrageMaskEnable];
    [_player setIntValue:_aiBarrageEnable ? 1 : 0 forKey:KeyIsAIBarrageEnable];
    [_player setIntValue:_subEnable  forKey:KeyIsSubEnable];
    [_player setIntValue:_subLanguageId  forKey:KeyIsSwitchSubId];
    [_player setIntValue:_hijackExit forKey:KeyIsHijackExit];
    [_player setIntValue:_seekEndEnabled forKey:KeyIsSeekEndEnable];
    [_player setIntValue:_cacheFileMode forKey:KeyIsCacheFileMode];
    [_player setIntValue:_testSpeedMode forKey:KeyIsTestSpeed];
    [_player setIntValue:_defaultVideoBitrate forKey:KeyIsDefaultVideoBitrate];
    [_player setIntValue:_embellishTime forKey:KeyIsEmbellishVolumeTime];
    [_player setIntValue:_loopStartTime forKey:KeyIsLoopStartTime];
    [_player setIntValue:_loopEndTime forKey:KeyIsLoopEndTime];
    [_player setIntValue:_reuseSocket forKey:KeyIsReuseSocket];
    [_player setIntValue:_disableAccurateStart forKey:KeyIsDisableAccurateStartTime];
    [_player setIntValue:_cacheMaxSeconds forKey:KeyIsSettingCacheMaxSeconds];
    [_player setIntValue:_bufferingTimeOut forKey:KeyIsBufferingTimeOut];
    [_player setIntValue:_maxBufferEndTime forKey:KeyIsMaxBufferEndTime];
    [_player setIntValue:_defaultBufferEndTime forKey:KeyIsDefaultBufferEndTime];
    [_player setIntValue:_enableEnterBufferingDirectly forKey:KeyIsEnterBufferingDirectly];
    [_player setIntValue:_mirrorType forKey:KeyIsMirrorType];
    [_player setIntValue:_audioEffectEnabled forKey:KeyIsEnableAudioEffect];
    [_player setIntValue:_threadWaitTimeMS forKey:KeyIsThreadWaitTimeMS];
    [_player setFloatValue:_audioEffectPregain forKey:KeyIsAudioEffectPregain];
    [_player setFloatValue:_audioEffectThreshold forKey:KeyIsAudioEffectThreshold];
    [_player setFloatValue:_audioEffectRatio forKey:KeyIsAudioEffectRatio];
    [_player setFloatValue:_audioEffectPredelay forKey:KeyIsAudioEffectPredelay];
    [_player setFloatValue:_audioEffectPostgain forKey:KeyIsAudioEffectPostgain];
    [_player setIntValue:_enableNNSR forKey:KeyIsEnableVideoSR];
    [_player setIntValue:_nnsrFPSThreshold forKey:KeyIsEnableVideoSRFPSThreshold];
    [_player setIntValue:_enableAllResolutionVideoSR forKey:KeyIsEnableAllResolutionVideoSR];
    [_player setIntValue:_enableRange forKey:KeyIsEnableRange];
    [_player setIntValue:_audioEffectType forKey:KeyIsAudioEffectType];
    [_player setFloatValue:_audioEffectSrcLoudness forKey:KeyIsAESrcLufs];
    [_player setFloatValue:_audioEffectTarLoudness forKey:KeyIsAETarLufs];
    [_player setFloatValue:_audioEffectSrcPeak forKey:KeyIsAESrcPeak];
    [_player setIntValue:(int)_skipBufferLimit forKey:KeyIsSkipBufferLimit];
    [_player setIntValue:_enableAVStack forKey:KeyIsEnableAVStack];
    [_player setIntValue:_terminalAudioUnitPool forKey:KeyIsTerminalAudioUnitPool];
    [_player setIntValue:_audioLatencyQueueByTime forKey:KeyIsDynAudioLatencyByTime];
    [_player setIntValue:_videoEndIsAllEof forKey:KeyIsSettingVideoEndIsAllEof];
    [_player setIntValue:_enableBufferingMilliSeconds forKey:KeyIsEnableBufferingMilliSeconds];
    [_player setIntValue:_defaultBufferingEndMilliSeconds forKey:KeyIsDefaultBufferingEndMilliSeconds];
    [_player setIntValue:_maxBufferEndMilliSeconds forKey:KeyIsMaxBufferEndMilliSeconds];
    [_player setIntValue:_enable720pSR forKey:KeyIsEnable720PSR];
    [_player setIntValue:_enableFFCodecerHeaacV2Compat forKey:KeyIsEnablePrimingWorkAround];
    [_player setIntValue:_enableKeepFormatThreadAlive forKey:KeyIsKeepFormatThreadAlive];
    if(_outputFramesWaitNum > 1) {
        [_player setIntValue:_outputFramesWaitNum forKey:KeyIsOutputFramesWaitNum];
    }
    [_player setIntValue:_startPlayAudioBufferThreshold forKey:KeyIsStartPlayAudioBufferThreshold];
    [_player setIntValue:(int)_decreaseVtbStackSize forKey:KeyIsDecreaseVtbStackSize];
    [_player setIntValue:_isEnablePostPrepareMsg forKey:KeyIsPostPrepare];
    [_player setIntValue:_disableShortSeek forKey:KeyIsDisableShortSeek];
    [_player setIntValue:_IsPreferNearestSample forKey:KeyIsPreferNearestSample];
    [_player setIntValue:_preferNearestMaxPosOffset forKey:KeyIsPreferNearestMaxPosOffset];
    [_player setIntValue:(int)_findStreamInfoProbeSize forKey:KeyIsFindStreamInfoProbeSize];
    [_player setIntValue:(int)_findStreamInfoProbeDuration forKey:KeyIsFindStreamInfoProbeDuration];
    [_player setIntValue:(int)_isEnableRefreshByTime forKey:KeyIsEnableRefreshByTime];
    [_player setIntValue:(int)_liveStartIndex forKey:KeyIsLiveStartIndex];
    [_player setIntValue:(int)_enableFallbackSWDecode forKey:KeyIsEnableFallbackSwDec];
    [_player setIntValue:_enableHDR10 forKey:KeyIsEnableHDR10];
    [_player setIntValue:_isEnableVsyncHelper forKey:KeyIsEnableVsyncHelper];
    [_player setIntValue:_customizedVideoRenderingFrameRate forKey:KeyIsCustomizedVideoRenderingFrameRate];
    if(_testSpeedMode > TTVideoEngineTestSpeedModeDisable) {
        [_player setValueVoidPTR:(void*)extraInfoCallback forKey:KeyIsExtraInfoCallBack];
    }
    if (g_TTVideoEngineLogDelegate || (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagPlayer
                                       || g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogPlayer)) {
        [_player setValueVoidPTR:(void*)TTVideoEngineCustomLog forKey:KeyIsLogInfoCallBack];
    }
    [_player setValueVoidPTR:audioWrapper forKey:KeyIsAudioProcessWrapperPTR];
    TTVideoEngineLog(@"set audio wrappper, %p",audioWrapper);
    if (videoWrapper != NULL) {
        [_player setValueVoidPTR:videoWrapper forKey:KeyIsVideoWrapperPTR];
    }
    _player.hardwareDecode = _hardwareDecode;
    if (_drmCreater != nil) {
        [_player setDrmCreater:_drmCreater];
    }
    if (_vid != nil) {
        [_player setValueString:_vid forKey:KeyIsVideoId];
    }
    [_player setIntValue:_drmType forKey:KeyIsDrmType];
    [_player setIntValue:_drmDowngrade forKey:KeyIsDrmDowngrade];
    if (_tokenUrlTemplate != nil) {
        [_player setValueString:_tokenUrlTemplate forKey:KeyIsTokenUrlTemplate];
    }
    if (_playUrl != nil) {
        [_player setValueString:_playUrl forKey:KeyIsFileUrl];
    }
    if(_barrageMaskUrl != nil){
        TTVideoEngineLog(@"barrage mask url :%@\n", _barrageMaskUrl);
        [_player setValueString:_barrageMaskUrl forKey:KeyIsBarrageMaskUrl];
    }
    if (_aiBarrageUrl.length) {
        TTVideoEngineLog(@"AIBarrage: url: %@\n", _aiBarrageUrl);
        [_player setValueString:_aiBarrageUrl forKey:KeyIsAIBarrageUrl];
    }
    if (_maskInfo != nil) {
        [_player setMaskInfoInterface:_maskInfo];
    }
    if (_aiBarrageInfo != nil) {
        [_player setAIBarrageInfoInterface:_aiBarrageInfo];
    }
    if (_subInfo != nil) {
        [_player setSubInfoInterface:_subInfo];
    }
    [_player setValueString:_mediaId forKey:KeyIsMediaId];
    [_player setIntValue:_reportRequestHeaders forKey:KeyIsReportRequestHeaders];
    [_player setIntValue:_reportResponseHeaders forKey:KeyIsReportResponseHeaders];
    [_player setIntValue:_enableTimerBarPercentage forKey:KeyIsTimeBarPercentage];
    [_player setIntValue:_enableDashAbr forKey:KeyIsEnableDashABR];
    [_player setIntValue:_enableIndexCache forKey:KeyIsEnableIndexCache];
    [_player setIntValue:_enableFragRange forKey:KeyIsEnableFragRange];
    [_player setIntValue:_enableAsync forKey:KeyIsEnableAsync];
    [_player setIntValue:_rangeMode forKey:KeyIsRangeMode];
    [_player setIntValue:_readMode forKey:KeyIsReadMode];
    [_player setIntValue:_videoRangeSize forKey:KeyIsVideoRangeSize];
    [_player setIntValue:_audioRangeSize forKey:KeyIsAudioRangeSize];
    [_player setIntValue:_videoRangeTime forKey:KeyIsVideoRangeTime];
    [_player setIntValue:_audioRangeTime forKey:KeyIsAudioRangeTime];
    [_player setIntValue:_skipFindStreamInfo forKey:KeyIsSkipFindStreamInfo];
    [_player setIntValue:_updateTimestampMode forKey:KeyIsUpdateTimestampMode];
    [_player setIntValue:_enableOpenTimeout forKey:KeyIsEnableOpenTimeout];
    [_player setIntValue:_handleAudioExtradata forKey:KeyIsHandleAudioExtradata];
    [_player setIntValue:_enableTTHlsDrm forKey:KeyIsTTHlsDrm];
    [_player setValueString:_ttHlsDrmToken forKey:KeyIsTTHlsDrmToken];
    [_player setIntValue:_audioUnitPoolEnabled forKey:KeyIsUseAudioPool];
    [_player setIntValue:_avSyncStartEnable forKey:KeyIsAVStartSync];
    [_player setIntValue:_codecDropSkippedFrame forKey:KeyIsCodecDropSikppedFrame];
    [_player setIntValue:_enableRadioMode forKey:KeyIsRadioMode];
    [_player setIntValue:_playerLazySeek forKey:KeyIsSeekLazyInRead];
    [_player setIntValue:_dummyAudioSleep forKey:KeyIsDummyAudioSleep];
    [_player setIntValue:_prepareMaxCachesMs forKey:KeyIsPrepareMaxCacheMs];
    [_player setIntValue:_mdlCacheMode forKey:KeyIsMDLCacheMode];
    [_player setIntValue:_httpAutoRangeOffset forKey:KeyIsHttpAutoRangeOffset];
    [_player setIntValue:_normalClockType forKey:KeyIsNormalClockType];
    [_player setIntValue:_stopSourceAsync forKey:KeyIsStopSourceAsync];
    [_player setIntValue:_enableSeekInterrupt forKey:KeyIsEnableSeekInterrupt];
    [_player setIntValue:1 forKey:KeyIsUpdateClockWithOffset];
    [_player setIntValue:_enableLazyAudioUnitOp forKey:KeyIsEnableLazyVoiceOp];
    [_player setIntValue:_enableRangeCacheDuration forKey:KeyIsEnableRangeCacheDuration];
    [_player setIntValue:_enableVoiceSplitHeaacV2 forKey:KeyIsVoiceSplitHeaacV2];
    [_player setIntValue:_enableAudioHardwareDecode forKey:KeyIsAudioHardwareDecode];
    [_player setIntValue:_delayBufferingUpdate forKey:KeyIsDelayBufferingUpdate];
    [_player setIntValue:_noBufferingUpdate forKey:KeyIsNoBufferingUpdate];
    [_player setIntValue:_keepVoiceDuration forKey:KeyIsKeepVoiceDuration];
    [_player setIntValue:_voiceBlockDuration forKey:KeyIsVoiceBlockDuration];
    [_player setIntValue:_enableSRBound forKey:KeyIsEnableSRBound];
    [_player setIntValue:_srLongDimensionLowerBound forKey:KeyIsSRLongDimensionLowerBound];
    [_player setIntValue:_srLongDimensionUpperBound forKey:KeyIsSRLongDimensionUpperBound];
    [_player setIntValue:_srShortDimensionLowerBound forKey:KeyIsSRShortDimensionLowerBound];
    [_player setIntValue:_srShortDimensionUpperBound forKey:KeyIsSRShortDimensionUpperBound];
    [_player setIntValue:_filePlayNoBuffering forKey:KeyIsFilePlayNoBuffering];
    [_player setIntValue:_audioChannelType forKey:KeyIsAudioChannelCtl];
    [_player setIntValue:YES forKey:KeyIsEnableImageScale];
    [_player setValueString:_userAgent forKey:KeyIsHttpUserAgent];
    [_player setIntValue:_enablePostStart forKey:KeyIsPostStart];
    [_player setIntValue:_enablePlayerPreloadGear forKey:KeyIsEnablePreloadGear];
    if (_changeVtbSizePicSizeBound > 0) {
        [_player setIntValue:_changeVtbSizePicSizeBound forKey:KeyIsChangeVtbSizePicSizeBound];
    }
    if (_loadControl != nil) {
        [_player setLoadControlInterface:_loadControl];
    }
    if (_medialoaderProtocolHandle != NULL) {
        [_player setValueVoidPTR:_medialoaderProtocolHandle forKey:KeyIsMediaLoaderRegisterNativeHandle];
        int registered = [_player getIntValue:0 forKey: keyIsMediaLoaderNativeHandleStatus];
        
        TTVideoEngineLog(@"medialoader protocol registered :%d \n", registered);
        kMedialoaderProtocolRegistered = (registered == 0);
    }
    if (_hlsProxyProtocolHandle != NULL) {
        [_player setValueVoidPTR:_hlsProxyProtocolHandle forKey:KeyIsHLSProxyRegisterNativeHandle];
        int registered = [_player getIntValue:0 forKey: keyIsHLSProxyNativeHandleStatus];
        
        TTVideoEngineLog(@"hlsproxy protocol registered :%d \n", registered);
        kHLSProxyProtocolRegistered = (registered == 0);
    }
    if (_precisePausePts != nil) {
        [_player setValueVoidPTR:_precisePausePts forKey:KeyIsSetPrecisePausePts];
    }

    if (_enableNNSR == YES) {
        [_player setIntValue:1 forKey:KeyIsVideoSRType];
    }
    //rear player doesn't support effect yet
    if ([_player isKindOfClass:[TTAVPlayer class]]) {
        if ((_effectParamArray != nil && _effectParamArray.count > 0)) {
            while (_effectParamArray.count > 0) {
                [_player setValue:[_effectParamArray objectAtIndex:0]];
                [_effectParamArray removeObjectAtIndex:0];
            }
        }
    }
    
    if (_preferSpdl4HDR) {
        [_view setOptionForKey:TTPlayerViewPreferSpdlForHDR value:@(YES)];
        if ([_view needRemoveView:_player]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerViewWillRemove)]) {
                [self.delegate playerViewWillRemove];
            }
        }
    }
    [_view setOptionForKey:TTPlayerViewHandleBackgroundAvView value:@(YES)];
    [_view setPlayer:_player];
    
    if (_asyncPrepare && _asyncInit) {
        dispatch_async([self _getTaskQueue], ^{
            [_player prepare];
        });
    } else {
       [_player prepare];
    }
}

- (NSString *)getVersion {
    return [_dualCore getVersion];
}

- (void)prepareToPlay {
    _isError = NO;
    if (_didStop) { // reuse
        _didStop = NO;
    }
    if (_isCompleted) {
        _isCompleted = NO;
    }
    _playedToEnd = NO;
    _isPrerolling = NO;
    
    if (self.enableRemoveTaskQueue) {
        //for remove taskQueue AB Test
        _asyncInit = NO;
        _asyncPrepare = NO;
    }

    if (!_isPreparedToPlay) {
        [self resetPlayer];
        [self didPrepareToPlayUrl:_playURL];
    }
}

- (void)setValueVoidPTR:(void *)voidPtr forKey:(int)key {
    [_player setValueVoidPTR:voidPtr forKey:key];
    switch (key) {
        case KeyIsAudioProcessWrapperPTR:
            audioWrapper = voidPtr;
            break;
        case KeyIsVideoWrapperPTR:
            videoWrapper = voidPtr;
            break;
        case KeyIsMediaLoaderRegisterNativeHandle:
            _medialoaderProtocolHandle = voidPtr;
            break;
        case KeyIsHLSProxyRegisterNativeHandle:
            _hlsProxyProtocolHandle = voidPtr;
            break;
        case KeyIsSetPrecisePausePts:
            _precisePausePts = voidPtr;
            break;
        default:
            break;
    }
}

- (void)setValueString:(NSString *)string forKey:(int)key
{
    if (string != nil) {
        [_player setValueString:string forKey:key];
    }
    switch (key) {
        case KeyIsDecryptionKey:
            _decryptionKey = string;
            break;
        case KeyIsMediaFileKey:
            _fileKey = string;
            break;
        case KeyIsCacheFileDir:
            _defaultCacheFileDir = string;
            break;
        case KeyIsVideoId:
            _vid = string;
            break;
        case KeyIsTokenUrlTemplate:
            _tokenUrlTemplate = string;
            break;
        case KeyIsFileUrl:
            _playUrl = string;
            break;
        case KeyIsVideoCheckInfo:
            _videoCheckInfo = string;
            break;
        case KeyIsAudioCheckInfo:
            _audioCheckInfo = string;
            break;
        case KeyIsTTHlsDrmToken:
            _ttHlsDrmToken = string;
            break;
        case KeyIsBarrageMaskUrl:
            _barrageMaskUrl = string;
            break;
        case KeyIsAIBarrageUrl:
            _aiBarrageUrl = string;
            break;
        case KeyIsMediaId:
            _mediaId = string;
            break;
        case KeyIsHttpUserAgent:
            _userAgent = string;
            break;
        default:
            break;
    }
}

- (void)setCacheFile:(NSString *)path mode:(int)mode
{
    if (path != nil) {
        [_player setCacheFile:path mode:mode];
    }
    _filePath = path;
}

- (void)setPlayerAudioDevice:(TTVideoEngineAudioDeviceType)audioDeviceType {
    if (audioDeviceType != TTVideoEngineDeviceHookedDummy) {
        _hijackDummyVoice = audioDeviceType;
    }
    if (audioDeviceType == TTVideoEngineDeviceHookedDummy) {
        audioDeviceType = _hijackDummyVoice;
        _enableHookVoice = NO;
        TTVideoEngineLog(@"hooked audio:%d", audioDeviceType);
    } else if (_enableHookVoice) {
        audioDeviceType = TTVideoEngineDeviceDummyAudio;
    }
    AudioRenderDevice renderDevice = AudioRenderDeviceAudioUnit;
    switch (audioDeviceType) {
        case TTVideoEngineDeviceAudioUnit:
            renderDevice = AudioRenderDeviceAudioUnit;
            break;
        case TTVideoEngineDeviceAudioGraph:
            renderDevice = AudioRenderDeviceAudioGraph;
            break;
        case TTVideoEngineDeviceDummyAudio:
            renderDevice = AudioRenderDeviceNone;
            break;
            
        default:
            break;
    }
    _audioDeviceType = renderDevice;
    [_player setIntValue:renderDevice forKey:KeyIsAudioDevice];
}

- (void)setIntValue:(int)value forKey:(int)key
{
    if (key == KeyIsAudioDevice) {
        _audioDeviceType = value;
        [self setPlayerAudioDevice:value];
        return;
    }
    [_player setIntValue:value forKey:key];
    switch (key) {
        case KeyIsCacheFileMode:
            _cacheFileMode = value;
            break;
        case KeyIsTestSpeed:
            _testSpeedMode = value;
            break;
        case KeyIsDefaultVideoBitrate:
            _defaultVideoBitrate = value;
            break;
        case KeyIsEmbellishVolumeTime:
            _embellishTime = value;
            break;
        case KeyIsLoopStartTime:
            _loopStartTime = value;
            break;
        case KeyIsLoopEndTime:
            _loopEndTime = value;
            break;
        case KeyIsReuseSocket:
            _reuseSocket = value;
            break;
        case KeyIsDisableAccurateStartTime:
            _disableAccurateStart = value;
            break;
        case KeyIsDrmType:
            _drmType = value;
            break;
        case KeyIsDrmDowngrade:
            _drmDowngrade = value;
            break;
        case KeyIsSettingCacheMaxSeconds:
            self.cacheMaxSeconds = value;
            break;
        case KeyIsBufferingTimeOut:
            self.bufferingTimeOut = value;
            break;
        case KeyIsMaxBufferEndTime:
            self.maxBufferEndTime = value;
            break;
        case KeyIsSeekEndEnable:
            _seekEndEnabled = value;
            break;
        case KeyIsReportRequestHeaders:
            _reportRequestHeaders = value;
            break;
        case KeyIsReportResponseHeaders:
            _reportResponseHeaders = value;
            break;
        case KeyIsTimeBarPercentage:
            _enableTimerBarPercentage = value;
            break;
        case KeyIsHijackExit:
            _hijackExit = value;
            break;
        case KeyIsEnableDashABR:
            _enableDashAbr = value;
            break;
        case KeyIsEnableIndexCache:
            _enableIndexCache = value;
            break;
        case KeyIsEnableFragRange:
            _enableFragRange = value;
            break;
        case KeyIsEnableAsync:
            _enableAsync = value;
            break;
        case KeyIsRangeMode:
            _rangeMode = value;
            break;
        case KeyIsReadMode:
            _readMode = value;
            break;
        case KeyIsVideoRangeSize:
            _videoRangeSize = value;
            break;
        case KeyIsAudioRangeSize:
            _audioRangeSize = value;
            break;
        case KeyIsVideoRangeTime:
            _videoRangeTime = value;
            break;
        case KeyIsAudioRangeTime:
            _audioRangeTime = value;
            break;
        case KeyIsSkipFindStreamInfo:
            _skipFindStreamInfo = value;
            break;
        case KeyIsUpdateTimestampMode:
            _updateTimestampMode = value;
            break;
        case KeyIsEnableOpenTimeout:
            _enableOpenTimeout = value;
            break;
        case KeyIsTTHlsDrm:
            _enableTTHlsDrm = value;
            break;
        case KeyIsEnterBufferingDirectly:
            _enableEnterBufferingDirectly = value;
            break;
        case KeyIsMirrorType:
            _mirrorType = value;
            break;
        case KeyIsOutputFramesWaitNum:
            self.outputFramesWaitNum = value;
            break;
        case KeyIsStartPlayAudioBufferThreshold:
            self.startPlayAudioBufferThreshold = value;
            break;
        case KeyIsAudioChannelCtl:
            self.audioChannelType = value;
            break;
        case KeyIsEnableAudioEffect:
            self.audioEffectEnabled = value;
            break;
        case KeyIsUseAudioPool:
            self.audioUnitPoolEnabled = value;
            break;
        case KeyIsAVStartSync:
            self.avSyncStartEnable = value;
            break;
        case KeyIsThreadWaitTimeMS:
            self.threadWaitTimeMS = value;
            break;
        case KeyIsCodecDropSikppedFrame:
            self.codecDropSkippedFrame = value;
            break;
        case KeyIsRadioMode:
            self.enableRadioMode = value;
            break;
        case KeyIsSeekLazyInRead:
            self.playerLazySeek = value;
            break;
        case KeyIsDummyAudioSleep:
            self.dummyAudioSleep = value;
            break;
        case KeyIsDefaultBufferEndTime:
            self.defaultBufferEndTime = value;
            break;
        case KeyIsVTBOutputRGB:
            self.decoderOutputType = value;
            break;
        case KeyIsPrepareMaxCacheMs:
            self.prepareMaxCachesMs = value;
            break;
        case KeyIsMDLCacheMode:
            self.mdlCacheMode = value;
            break;
        case KeyIsHttpAutoRangeOffset:
            self.httpAutoRangeOffset = value;
            break;
        case KeyIsEnableVideoSR:
            self.enableNNSR = value;
            break;
        case KeyIsEnableVideoSRFPSThreshold:
            self.nnsrFPSThreshold = value;
            break;
        case KeyIsEnableRange:
            self.enableRange = value;
            break;
        case KeyIsAudioEffectType:
            self.audioEffectType = value;
            break;
        case KeyIsNormalClockType:
            self.normalClockType = value;
            break;
        case KeyIsEnableAllResolutionVideoSR:
            self.enableAllResolutionVideoSR = value;
            break;
        case KeyIsSkipBufferLimit:
            self.skipBufferLimit = value;
            [_player setIntValue:value forKey:KeyIsSkipBufferLimit];
            break;
        case KeyIsEnableAVStack:
            self.enableAVStack = value;
            break;
        case KeyIsTerminalAudioUnitPool:
            self.terminalAudioUnitPool = value;
            break;
        case KeyIsDynAudioLatencyByTime:
            self.audioLatencyQueueByTime = value;
            break;
        case KeyIsSettingVideoEndIsAllEof:
            self.videoEndIsAllEof = value;
            break;
        case KeyIsEnableBufferingMilliSeconds:
            self.enableBufferingMilliSeconds = value;
            break;
        case KeyIsDefaultBufferingEndMilliSeconds:
            self.defaultBufferingEndMilliSeconds = value;
            break;
        case KeyIsMaxBufferEndMilliSeconds:
            self.maxBufferEndMilliSeconds = value;
            break;
        case KeyIsDecreaseVtbStackSize:
            self.decreaseVtbStackSize = value;
            break;
        case KeyIsPostPrepare:
            self.isEnablePostPrepareMsg = value;
            break;
        case KeyIsDisableShortSeek:
            self.disableShortSeek = value;
            break;
        case KeyIsPreferNearestSample:
            self.IsPreferNearestSample = value;
            break;
        case KeyIsPreferNearestMaxPosOffset:
            self.preferNearestMaxPosOffset = value;
            break;
        case KeyIsEnable720PSR:
            self.enable720pSR = value;
            break;
        case KeyIsKeepFormatThreadAlive:
            self.enableKeepFormatThreadAlive = value;
            break;
        case KeyIsEnableHDR10:
            self.enableHDR10 = value;
            break;
        case KeyIsFindStreamInfoProbeSize:
            self.findStreamInfoProbeSize = value;
            break;
        case KeyIsFindStreamInfoProbeDuration:
            self.findStreamInfoProbeDuration = value;
            break;
        case KeyIsEnableRefreshByTime:
            self.isEnableRefreshByTime = value;
            break;
        case KeyIsLiveStartIndex:
            self.liveStartIndex = value;
            break;
        case KeyIsEnableFallbackSwDec:
            self.enableFallbackSWDecode = value;
            break;
        case KeyIsEnablePrimingWorkAround:
            self.enableFFCodecerHeaacV2Compat = value;
            break;
        case KeyIsPreferSpdlForHDR:
            self.preferSpdl4HDR = value;
            break;
        case KeyIsStopSourceAsync:
            self.stopSourceAsync = value;
            break;
        case KeyIsEnableSeekInterrupt:
            self.enableSeekInterrupt = value;
            break;
        case KeyIsChangeVtbSizePicSizeBound:
            self.changeVtbSizePicSizeBound = value;
            break;
        case KeyIsEnableLazyVoiceOp:
            self.enableLazyAudioUnitOp = value;
            break;
        case KeyIsEnableRangeCacheDuration:
            self.enableRangeCacheDuration = value;
            break;
        case KeyIsVoiceSplitHeaacV2:
            self.enableVoiceSplitHeaacV2 = value;
            break;
        case KeyIsAudioHardwareDecode:
            self.enableAudioHardwareDecode = value;
            break;
        case KeyIsDelayBufferingUpdate:
            self.delayBufferingUpdate = value;
            break;
        case KeyIsNoBufferingUpdate:
            self.noBufferingUpdate = value;
            break;
        case KeyIsKeepVoiceDuration:
            self.keepVoiceDuration = value;
            break;
        case KeyIsVoiceBlockDuration:
            self.voiceBlockDuration = value;
            break;
        case KeyIsEnableSRBound:
            self.enableSRBound = value;
            break;
        case KeyIsSRLongDimensionLowerBound:
            self.srLongDimensionLowerBound = value;
            break;
        case KeyIsSRLongDimensionUpperBound:
            self.srLongDimensionUpperBound = value;
            break;
        case KeyIsSRShortDimensionLowerBound:
            self.srShortDimensionLowerBound = value;
            break;
        case KeyIsSRShortDimensionUpperBound:
            self.srShortDimensionUpperBound = value;
            break;
        case KeyIsFilePlayNoBuffering:
            self.filePlayNoBuffering = value;
            break;
        case KeyIsHijackVoiceType:
            self.enableHookVoice = value;
            if (value) {
                [_player setIntValue:AudioRenderDeviceNone forKey:KeyIsAudioDevice];
                _audioDeviceType = AudioRenderDeviceNone;
            }
            break;
        case KeyIsPostStart:
            self.enablePostStart = value;
            break;
        case KeyIsEnablePreloadGear:
            self.enablePlayerPreloadGear = value;
            break;
        case KeyIsEnableVsyncHelper:
            self.isEnableVsyncHelper = value;
            break;
        case KeyIsCustomizedVideoRenderingFrameRate:
            self.customizedVideoRenderingFrameRate = value;
            break;
        case KeyIsPlaySpeedExtendEnable:
            self.enablePlaySpeedExtend = value;
            break;
        default:
            _intOptions[@(key)] = @(value);
            break;
    }
}

- (void)setFloatValue:(float)value forKey:(int)key {
    [_player setIntValue:value forKey:key];
    switch (key) {
        case KeyIsAudioEffectPregain:
            self.audioEffectPregain = value;
            break;
        case KeyIsAudioEffectThreshold:
            self.audioEffectThreshold = value;
            break;
        case KeyIsAudioEffectRatio:
            self.audioEffectRatio = value;
            break;
        case KeyIsAudioEffectPredelay:
            self.audioEffectPredelay = value;
            break;
        case KeyIsAudioEffectPostgain:
            self.audioEffectPostgain = value;
            break;
        case KeyIsAESrcLufs:
            self.audioEffectSrcLoudness = value;
            break;
        case KeyIsAETarLufs:
            self.audioEffectTarLoudness = value;
            break;
        case KeyIsAESrcPeak:
            self.audioEffectSrcPeak = value;
            break;
        default:
            _floatOptions[@(key)] = @(value);
            break;
    }
}

- (void)setEffect:(NSDictionary *)effectParam {
    if (_player == nil) {
        if (_effectParamArray == nil) {
            _effectParamArray = [NSMutableArray arrayWithObject:effectParam];
        } else {
            [_effectParamArray addObject:effectParam];
        }
    } else {
        if ([_player isKindOfClass:[TTAVPlayer class]]) {
            [_player setValue:effectParam];
        }
    }
}

- (void)setCustomHeader:(NSDictionary *)header {
    _header = header;
}

- (int64_t)getInt64ValueForKey:(int)key {
    return [_player getInt64Value:0 forKey:key];
}

- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key {
    return [_player getInt64Value:dValue forKey:key];
}

- (int )getIntValueForKey:(int)key {
    return [_player getIntValue:0 forKey:key];
}

- (int)getIntValue:(int)dValue forKey:(int)key {
    return [_player getIntValue:dValue forKey:key];
}

- (CGFloat)getFloatValueForKey:(int)key {
    return [_player getFloatValueForKey:key];
}

- (NSString *)getStringValueForKey:(int)key {
    return [_player getStringValueForKey:key];
}

- (CVPixelBufferRef)copyPixelBuffer {
    if (_renderEngine == TTVideoEngineRenderEngineOutput) {
        return [_view copyPixelBuffer];
    }
    return [_player copyPixelBuffer];
}

- (void)setDrmCreater:(DrmCreater)drmCreater {
    _drmCreater = drmCreater;
    [_player setDrmCreater:drmCreater];
}

- (void)playerPlay {
    _isPrerolling = YES;
    if (!_player.currentItem && _playerItem) {
        _isCompleted = NO;
        _playedToEnd = NO;
        _isError = NO;
        _isPreparedToPlay = NO;
        [_player replaceCurrentItemWithPlayerItem:_playerItem];
        [self setPlayerLooping:self.looping];
    }
    if (_asyncInit) {
        dispatch_async([self _getTaskQueue], ^{
            pthread_mutex_lock(&_mutex);
            if (!_isPaused) {
                [_player play];
            }
            pthread_mutex_unlock(&_mutex);
        });
    } else {
        [_player play];
    }
}

- (void)play {
    //
    _isPaused = NO;
    [self _play];
}

- (void)_play {
    if (_asyncPrepare && _asyncInit) {
        if(_isPreparedAsync == YES) {
            _isPlayedinPreparedAsync = YES;
            return;
        }
    }
    if (_didStop) { // reuse
        _didStop = NO;
    }
    if (_isCompleted) {
        _isCompleted = NO;
        [_player seekToTime:kCMTimeZero];
    }
    //
    _isPauseWhenNotReady = NO;
    _playedToEnd = NO;
//    _isPreparedToPlay = YES;
    //
    [self playerPlay];
}

- (void)pause:(BOOL)async{
    pthread_mutex_lock(&_mutex);
    _isPaused = YES;
    [self _pause:async];
    pthread_mutex_unlock(&_mutex);
}

- (void)_pause:(BOOL)async{
    _isPrerolling = NO;
    [_player pause:async];
    if (!self.isPreparedToPlay) {
        _isPauseWhenNotReady = YES;
    }
}

- (void)pause {
    [self pause:NO];
}

- (void)_pause {
    [self _pause:NO];
}

- (void)stop {
    //
    _isPreparedToPlay = NO;
    _isPlayedinPreparedAsync = NO;
    _isPreparedAsync = NO;
    if (!_isCompleted) {
        [self pause];
        _isCompleted = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonUserExited)}];
        }
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
    //
    _didStop = YES;

}
- (void)close {
    //[self _stopSectionWatchDurationTimer];
    //
    if(_player) {
        [_player closeWithoutRelease];
    }
    //
    _didStop = YES;
}

- (void)closeAsync {
    if (_player) {
        [_player close:YES];
    }
    _didStop = YES;
}


- (BOOL)isPrerolling {
    return _isPrerolling;
}

- (BOOL)isPlaying {
    BOOL isPlaying = (_player.playbackState == AVPlayerPlaybackStatePlaying);
    //TTVideoEngineLog(@"isPlaying %@",isPlaying ? @"YES":@"NO");
    return isPlaying;
}

- (void)shutdown {
    //
    _isShutdown = YES;
    
    [self stop];
    
    if (_player) {
        [_player close];
    }
    
    [self resetPlayer];
    
    self.view = nil;
    _player = nil;
}

- (void)resetPlayer {
    if (_playerItem != nil) {
        [self removePlayerItemObservers:_playerItem];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:nil
                                                      object:_playerItem];
        
        _playerItem = nil;
    }
    
    if (_player) {
        [self removePlayerObservers];
        //
    }
    if (_view != nil) {
        [_view setPlayer:nil];
    }
}

- (float)currentRate {
#warning todop check
    return 0;
}

- (NSString *)currentCDNHost {
    return nil;
}

- (long long)numberOfBytesPlayed {
    return [_player getInt64Value:0 forKey:KeyIsPlayBytes];
}

- (long long)numberOfBytesTransferred {
    return [_player getInt64Value:0 forKey:KeyIsDownloadBytes];
}

- (long long)downloadSpeed {
    return [_player getInt64Value:0 forKey:KeyIsPlayerDownloadSpeed];
}

- (long long)videoBufferLength {
    return [_player getInt64Value:0 forKey:KeyIsVideoBufferMilliSeconds];
}

- (long long)audioBufferLength {
    return [_player getInt64Value:0 forKey:KeyIsAudioBufferMilliSeconds];
}

- (long long)mediaSize {
    return [_player getInt64Value:-1 forKey:KeyIsMediaFileSize];
}

- (void)playNextWithURL:(NSURL *)url complete:(void(^)(BOOL success))complete {
    NSMutableDictionary *httpHeader = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ %@",kTTVideoEngineHTTPHeaderUAValue,[TTVideoEngine _engineVersionString]]forKey:kTTVideoEngineHTTPHeaderUAKey];
    if (_header) {
        [httpHeader addEntriesFromDictionary:_header];
    }
    [_player playNextWithURL:url
                     options:[httpHeader copy]
           completionHandler:^(BOOL finished) {
               complete(finished);
           }];
}

- (void)switchStreamBitrate:(NSInteger)bitrate ofType:(TTMediaStreamType)type completion:(void(^)(BOOL success))finished {
    [_player switchStreamBitrate:bitrate type:type completionHandler:finished];
}

- (TTVideoEngineImageScaleType)imageScaleType {
    return _imageScaleType;
}

- (void)setImageScaleType:(TTVideoEngineImageScaleType)imageScaleType {
    _imageScaleType = imageScaleType;
    [self setPlayerImageScaleType:imageScaleType];
}

- (void)setPlayerImageScaleType:(TTVideoEngineImageScaleType)imageScaleType {
    ImageScaleType type = LinearScale;
    switch (imageScaleType) {
        case TTVideoEngineImageScaleTypeLinear:
            type = LinearScale;
            break;
        case TTVideoEngineImageScaleTypeLanczos:
            type = LanczosScale;
            break;
            
        default:
            break;
    }
    [_player setIntValue:type forKey:KeyIsImageScaleType];
}

- (TTVideoEngineEnhancementType)enhancementType {
    return _enhancementType;
}

- (void)setEnhancementType:(TTVideoEngineEnhancementType)enhancementType {
    _enhancementType = enhancementType;
    [self setPlayerEnhancementType:enhancementType];
}

- (void)setPlayerEnhancementType:(TTVideoEngineEnhancementType)enhancementType {
    ImageEnhancementType type = DefaultEnhancement;
    switch (enhancementType) {
        case TTVideoEngineEnhancementTypeNone:
            type = DefaultEnhancement;
            break;
        case TTVideoEngineEnhancementTypeContrast:
            type = ContrastEnhancement;
            break;
            
        default:
            break;
    }
    [_player setIntValue:type forKey:KeyIsImageEnhancementType];
}

- (TTVideoEngineImageLayoutType)imageLayoutType {
    return _imageLayoutType;
}

- (void)setImageLayoutType:(TTVideoEngineImageLayoutType)imageLayoutType {
    _imageLayoutType = imageLayoutType;
    [self setPlayerLayoutType:imageLayoutType];
}

- (void)setPlayerLayoutType:(TTVideoEngineImageLayoutType)imageLayoutType {
    ImageLayoutType type = ImageScaleAspectFit;
    switch (imageLayoutType) {
        case TTVideoEngineLayoutTypeAspectFit:
            type = ImageScaleAspectFit;
            break;
        case TTVideoEngineLayoutTypeToFill:
            type = ImageScaleToFill;
            break;
        case TTVideoEngineLayoutTypeAspectFill:
            type = ImageScaleAspectFill;
            break;
            
        default:
            break;
    }
    [_player setIntValue:type forKey:KeyIsImageLayout];
}

- (TTVideoEngineRenderType)renderType {
    return _renderType;
}

- (void)setRenderType:(TTVideoEngineRenderType)renderType {
    _renderType = renderType;
    [self setPlayerRenderType:renderType];
}

- (void)setPlayerRenderType:(TTVideoEngineRenderType)renderType {
    VideoRenderType type = VideoRenderTypeNone;
    switch (renderType) {
        case TTVideoEngineRenderTypePlane:
            type = VideoRenderTypePlane;
            break;
        case TTVideoEngineRenderTypePano:
            type = VideoRenderTypePano;
            break;
        case TTVideoEngineRenderTypeVR:
            type = VideoRenderTypeVR;
            break;
        case TTVideoEngineRenderTypeDefault:
            type = VideoRenderTypeNone;
            break;
            
        default:
            break;
    }
    [_player setIntValue:type forKey:KeyIsRenderType];
}

- (void)setVolume:(CGFloat)volume {
    if (volume < 0.0f || volume > 1.0f) {
        return;
    }
    _volume = volume;
    /* http://t.wtturl.cn/vrM9N2/  引起主线程卡住， setVolume 对于 AudioUnit 不生效。 */
    if (_player && _audioDeviceType != AudioRenderDeviceAudioUnit) {
        _player.volume = volume;
    }
}

- (void)setRenderEngine:(TTVideoEngineRenderEngine)renderEngine {
    _renderEngine = renderEngine;
    [self setPlayerViewRenderEngine:renderEngine];
}

- (TTVideoEngineRenderEngine)renderEngine {
    return _renderEngine;
}

- (TTVideoEngineRenderEngine)finalRenderEngine {
    switch (_view.lastRenderType) {
        case TTPlayerViewRenderTypeOpenGLES:
            return TTVideoEngineRenderEngineOpenGLES;
        case TTPlayerViewRenderTypeMetal:
            return TTVideoEngineRenderEngineMetal;
        case TTPlayerViewRenderTypeOutput:
            return TTVideoEngineRenderEngineOutput;
        case TTPlayerViewRenderTypeSampleBufferDisplayLayer:
            return TTVideoEngineRenderEngineSBDLayer;
        default:
            return TTVideoEngineRenderEngineSBDLayer;;
    }
    return TTVideoEngineRenderEngineSBDLayer;
}

- (void)setPlayerViewRenderEngine:(TTVideoEngineRenderEngine)renderEngine {
    TTPlayerViewRenderType viewRenderType = TTPlayerViewRenderTypeOpenGLES;
    switch (renderEngine) {
        case TTVideoEngineRenderEngineMetal:
            viewRenderType = TTPlayerViewRenderTypeMetal;
            break;
        case TTVideoEngineRenderEngineOpenGLES:
            viewRenderType = TTPlayerViewRenderTypeOpenGLES;
            break;
        case TTVideoEngineRenderEngineOutput: {
            viewRenderType = TTPlayerViewRenderTypeOutput;
            [_player setIntValue:self.decoderOutputType forKey:KeyIsVTBOutputRGB];
            break;
        }
        case TTVideoEngineRenderEngineSBDLayer:
            viewRenderType = TTPlayerViewRenderTypeSampleBufferDisplayLayer;
            break;
        default:
            viewRenderType = TTPlayerViewRenderTypeOpenGLES;
            break;
    }
    _view.renderType = viewRenderType;
}

- (CGFloat)playbackSpeed {
    return _playbackSpeed;
}

- (void)setPlaybackSpeed:(CGFloat)playbackSpeed {
    _playbackSpeed = playbackSpeed;
    [self setPlayerPlaybackSpeed:playbackSpeed];
}

- (void)setPlayerPlaybackSpeed:(CGFloat)playbackSpeed {
    [_player setSpeed:(float)playbackSpeed];
}

- (NSTimeInterval)startTime {
    return _startTime;
}

- (void)setStartTime:(NSTimeInterval)startTime {
    _startTime = startTime;
    [self setPlayerStartTime:startTime];
}

- (void)setPlayerStartTime:(NSTimeInterval)startTime {
    [_player setIntValue:(int)(startTime * 1000) forKey:KeyIsStartTime];
}

- (BOOL)hardwareDecode {
    return _player.isHardwareDecode;
}

- (void)setHardwareDecode:(BOOL)hardwareDecode {
    _hardwareDecode = hardwareDecode;
}

- (BOOL)ksyByteVC1Decode {
    return _ksyByteVC1Decode;
}

- (void)setKsyByteVC1Decode:(BOOL)ksyByteVC1Decode {
    _ksyByteVC1Decode = ksyByteVC1Decode;
    [self setPlayerKsyByteVC1Decode:ksyByteVC1Decode];
}

- (void)setPlayerKsyByteVC1Decode:(BOOL)ksyByteVC1Decode {
    [_player setIntValue:ksyByteVC1Decode forKey:KeyIsUsedKsyCodec];
}

- (void)setLoopWay:(NSInteger)loopWay {
    _loopWay = loopWay;
}

- (BOOL)looping {
    return _looping;
}

- (void)setLooping:(BOOL)looping {
    _looping = looping;
    [self setPlayerLooping:looping];
}

- (void)setAsyncInit:(BOOL)isAsyncInit {
    _asyncInit = isAsyncInit;
    if (self.enableRemoveTaskQueue) {
        _asyncInit = NO;
    }
}

- (void)setAsyncPrepare:(BOOL)isAsyncPrepare {
    _asyncPrepare = isAsyncPrepare;
    if (self.enableRemoveTaskQueue) {
        _asyncPrepare = NO;
    }
}

- (void)setPlayerLooping:(BOOL)looping {
    if (_loopWay > 0) {
        [_player setLoop:looping];
    }
}

- (void)setBarrageMaskEnable:(BOOL)barrageMaskEnable {
    _barrageMaskEnable = barrageMaskEnable;
    [_player setIntValue:_barrageMaskEnable?1:0 forKey:KeyIsBarrageMaskEnable];
}

- (void)setAiBarrageEnable:(BOOL)aiBarrageEnable {
    _aiBarrageEnable = aiBarrageEnable;
    [_player setIntValue:_aiBarrageEnable forKey:aiBarrageEnable];
}

- (NSInteger)openTimeOut {
    return _openTimeOut;
}

- (void)setOpenTimeOut:(NSInteger)openTimeOut {
    _openTimeOut = openTimeOut;
    [self setPlayerOpenTimeOut:openTimeOut];
}

- (void)setPlayerOpenTimeOut:(NSInteger)openTimeOut {
    [_player setIntValue:openTimeOut * 1000000 forKey:KeyIsHttpTimeOut];
}

- (NSInteger)smoothDelayedSeconds {
    return _smoothDelayedSeconds;
}

- (void)setSmoothDelayedSeconds:(NSInteger)smoothDelayedSeconds {
    _smoothDelayedSeconds = smoothDelayedSeconds;
    [self setPlayerSmoothDelayedSeconds:smoothDelayedSeconds];
}

- (void)setPlayerSmoothDelayedSeconds:(NSInteger)smoothDelayedSeconds {
    [_player setIntValue:smoothDelayedSeconds forKey:KeyIsSmoothDelayedSec];
}

- (void)setCacheMaxSeconds:(NSInteger)cacheMaxSeconds {
    if (cacheMaxSeconds >= 1) {
        _cacheMaxSeconds = cacheMaxSeconds;
        [_player setIntValue:cacheMaxSeconds forKey:KeyIsSettingCacheMaxSeconds];
    }
}

- (void)setBufferingTimeOut:(NSInteger)bufferingTimeOut {
    _bufferingTimeOut = bufferingTimeOut;
    [_player setIntValue:bufferingTimeOut forKey:KeyIsBufferingTimeOut];
}

- (void)setMaxBufferEndTime:(NSInteger)maxBufferEndTime {
    _maxBufferEndTime = maxBufferEndTime;
    [_player setIntValue:maxBufferEndTime forKey:KeyIsMaxBufferEndTime];
}

- (void)setEnableTimerBarPercentage:(BOOL)enableTimerBarPercentage {
    _enableTimerBarPercentage = enableTimerBarPercentage;
    [_player setIntValue:enableTimerBarPercentage forKey:KeyIsTimeBarPercentage];
}

- (void)setEnableTTHlsDrm:(BOOL)enableTTHlsDrm {
    _enableTTHlsDrm = enableTTHlsDrm;
    [_player setIntValue:enableTTHlsDrm forKey:KeyIsTTHlsDrm];
}

- (void)setTtHlsDrmToken:(NSString *)ttHlsDrmToken {
    _ttHlsDrmToken = ttHlsDrmToken;
    [_player setValueString:ttHlsDrmToken forKey:KeyIsTTHlsDrmToken];
}

- (void)setEnableEnterBufferingDirectly:(BOOL)enableEnterBufferingDirectly {
    _enableEnterBufferingDirectly = enableEnterBufferingDirectly;
    [_player setIntValue:enableEnterBufferingDirectly forKey:KeyIsEnterBufferingDirectly];
}

- (void)setOutputFramesWaitNum:(NSInteger)outputFramesWaitNum {
    if (outputFramesWaitNum > 1) {
        _outputFramesWaitNum = outputFramesWaitNum;
        [_player setIntValue:outputFramesWaitNum forKey:KeyIsOutputFramesWaitNum];
    }
}

- (void)setOptimizeMemoryUsage:(BOOL)optimizeMemoryUsage {
    _optimizeMemoryUsage = optimizeMemoryUsage;
    _view.memoryOptimizeEnabled = optimizeMemoryUsage;
}

- (void)setThreadWaitTimeMS:(NSInteger)threadWaitTimeMS {
    _threadWaitTimeMS = threadWaitTimeMS;
    [_player setIntValue:threadWaitTimeMS forKey:KeyIsThreadWaitTimeMS];
}

- (void) setDefaultBufferEndTime:(NSInteger)defaultBufferEndTime {
    _defaultBufferEndTime = defaultBufferEndTime;
    [_player setIntValue:defaultBufferEndTime forKey:KeyIsDefaultBufferEndTime];
}

- (void) setPrepareMaxCachesMs:(NSInteger)prepareMaxCachesMs {
    _prepareMaxCachesMs = prepareMaxCachesMs;
    [_player setIntValue:prepareMaxCachesMs forKey:KeyIsPrepareMaxCacheMs];
}

- (void) setMdlCacheMode:(NSInteger)mdlCacheMode {
    _mdlCacheMode = mdlCacheMode;
    [_player setIntValue:mdlCacheMode forKey:KeyIsMDLCacheMode];
}

- (void) setHttpAutoRangeOffset:(NSInteger)httpAutoRangeOffset {
    _httpAutoRangeOffset = httpAutoRangeOffset;
    [_player setIntValue:httpAutoRangeOffset forKey:KeyIsHttpAutoRangeOffset];
}

- (void)setRotateType:(TTVideoEngineRotateType)rotateType {
    _rotateType = rotateType;
    //
    TTPlayerViewRotateType temRotateType = TTPlayerViewRotateTypeNone;
    switch (rotateType) {
        case TTVideoEngineRotateTypeNone:
            temRotateType = TTPlayerViewRotateTypeNone;
            break;
        case TTVideoEngineRotateType90:
            temRotateType = TTPlayerViewRotateType90;
            break;
        case TTVideoEngineRotateType180:
            temRotateType = TTPlayerViewRotateType180;
            break;
        case TTVideoEngineRotateType270:
            temRotateType = TTPlayerViewRotateType270;
            break;
        default:
            break;
    }
    [_view setRotateType:temRotateType];
}

- (NSDictionary *)metadata {
    NSDictionary *dict = [NSDictionary dictionary];
    NSString *meta = [_player getStringValueForKey:KeyIsMetaDataInfo];
    if (!meta) {
        return dict;
    }
    NSData *jsonData = [meta dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return dict;
    }
    NSError *error;
    NSDictionary *metaData = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&error];
    if (!metaData || error) {
        return dict;
    }
    return metaData;
}

- (UIImage *)attachedPic {
    return _player.attachedPic;
}

// MARK: - async initialization
- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)viewWrapper {
    if (_view != viewWrapper.playerView
        && [viewWrapper.playerView conformsToProtocol:@protocol(TTPlayerViewProtocol)] ) {
        TTVideoEngineLog(@"async init: set own player view success");
        _view = (UIView<TTPlayerViewProtocol> *)viewWrapper.playerView;
        if (_preferSpdl4HDR) {
            [_view setOptionForKey:TTPlayerViewPreferSpdlForHDR value:@(YES)];
            if ([_view needRemoveView:_player]) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(playerViewWillRemove)]) {
                    [self.delegate playerViewWillRemove];
                }
            }
        }
        
        [_view setOptionForKey:TTPlayerViewHandleBackgroundAvView value:@(YES)];
        [_view setPlayer:_player];
        _view.renderType = _renderEngine;
        _view.memoryOptimizeEnabled = _optimizeMemoryUsage;
        [self setRotateType:_rotateType];
        [self setScalingMode:_scalingMode];
    }
}


#pragma mark - Player Observers

- (void)addPlayerObservers {
    [_player addObserver:self
              forKeyPath:NSStringFromSelector(@selector(currentItem))
                 options:NSKeyValueObservingOptionNew
                 context:Context_player_currentItem];
    
    
    [_player addObserver:self
              forKeyPath:NSStringFromSelector(@selector(playbackState))
                 options:NSKeyValueObservingOptionNew
                 context:Context_player_playbackState];
    
    [_player addObserver:self
              forKeyPath:NSStringFromSelector(@selector(loadState))
                 options:NSKeyValueObservingOptionNew
                 context:Context_player_loadState];
}

- (void)removePlayerObservers {
    @try
    {
        [_player removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(currentItem))
                        context:Context_player_currentItem];
    }
    @catch (NSException *exception)
    {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try
    {
        [_player removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(playbackState))
                        context:Context_player_playbackState];
    }
    @catch (NSException *exception)
    {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try
    {
        [_player removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(loadState))
                        context:Context_player_loadState];
    }
    @catch (NSException *exception)
    {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
}

#pragma mark - PlayerItem Observers

- (void)addPlayerItemObservers:(NSObject<TTAVPlayerItemProtocol>  *)playerItem {
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackLikelyToKeepUp];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(status))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_state];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferFull))
                    options:NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackBufferFull];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(loadedProgress))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_loadedTimeRanges];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackBufferEmpty];
    
}

- (void)removePlayerItemObservers:(NSObject<TTAVPlayerItemProtocol>  *)playerItem {
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                           context:Context_playerItem_playbackLikelyToKeepUp];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferFull))
                           context:Context_playerItem_playbackBufferFull];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                           context:Context_playerItem_playbackBufferEmpty];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(status))
                           context:Context_playerItem_state];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(loadedProgress))
                           context:Context_playerItem_loadedTimeRanges];
    } @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete renderComplete:(void(^)(BOOL isSeekInCached))renderComplete {
    if (!_player || !_isPreparedToPlay) {
        complete(NO);
        return;
    }
    
    TTVideoEngineLog(@"seekToTime %f begin", aCurrentPlaybackTime);
    
    _seekingTime = aCurrentPlaybackTime;
//    _isSeeking = YES;
    
//    _loadState = TTVideoEngineLoadStateUnknown;
//    if (aCurrentPlaybackTime > 0) {//解除死循环 ,非最优方案 (弱网下,播放视频,在视频ready之前,点击赞赏,等待,会触发死循环)
//        [self didLoadStateChange];
//    }
    
    //Fatal Exception: NSInvalidArgumentException, AVPlayerItem cannot service a seek request with a completion handler until its status is TTAVPlayerItemStatusReadyToPlay.
    @try {
        _isSeeking = YES;
        @weakify(self)
        //
        //
        AVSeekType seekType = AVSeekTypeAny;
        if ([_engine respondsToSelector:@selector(playerSeekMode)]) {
            seekType = (AVSeekType)[_engine playerSeekMode];
        }
        [_player seekToTime:CMTimeMakeWithSeconds(aCurrentPlaybackTime, NSEC_PER_SEC)
          completionHandler:^(BOOL finished) {
             @strongify(self)
              if (!self) {
                  return ;
              }
            
              if (finished) {
                  //                  dispatch_async(dispatch_get_main_queue(), ^{
//                  self->_isSeeking--;
//                  self->_loadState = TTVideoEngineLoadStateUnknown;
//                  if (aCurrentPlaybackTime > 0) {//解除死循环 ,非最优方案
//                      [self didLoadStateChange];
//                  }
                  if (!TTVideoIsNullObject(complete)) {
                      complete(finished);
                  }
                  //                  });
                  TTVideoEngineLog(@"seekToTime %f finished", aCurrentPlaybackTime);
              } else {
                  TTVideoEngineLog(@"seekToTime %f cancelled", aCurrentPlaybackTime);
              }
        } renderCompleteHandler:^(BOOL isSeekInCached) {
            @strongify(self)
             if (!self) {
                 return ;
             }
             self->_isSeeking = NO;
            if (!TTVideoIsNullObject(renderComplete)) {
                renderComplete(isSeekInCached);
            }
        } flag:seekType];
        
    } @catch (NSException *exception) {
//        _isSeeking = NO;
    }
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete {
    [self setCurrentPlaybackTime:aCurrentPlaybackTime complete:complete renderComplete:^(BOOL isSeekInCached){}];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime {
    [self setCurrentPlaybackTime:aCurrentPlaybackTime complete:^(BOOL success) {
    }];
}

- (NSTimeInterval)currentPlaybackTime {
    if (!_player)
        return 0.0f;
    if (_playedToEnd) {
        return self.duration;
    }
//    if (_isSeeking)
//        return _seekingTime;
    return CMTimeGetSeconds([_player currentTime]);
}

- (TTVideoEnginePlaybackState)playbackState {
    if (!_player || !_isPreparedToPlay)
        return TTVideoEnginePlaybackStateStopped;
    
    TTVideoEnginePlaybackState mpState = TTVideoEnginePlaybackStateStopped;
    if (_isError) {
        mpState = TTVideoEnginePlaybackStateError;
    }
    else if (_player.playbackState == AVPlayerPlaybackStateStopped || _player.playbackState == AVPlayerPlaybackStateUnknown) {
        mpState = TTVideoEnginePlaybackStateStopped;
    }
    else if ([self isPlaying]) {
        mpState = TTVideoEnginePlaybackStatePlaying;
    }
    else {
        mpState = TTVideoEnginePlaybackStatePaused;
    }
    return mpState;
}

- (TTVideoEngineLoadState)loadState {
    if (!_player|| !_isPreparedToPlay || ![_player currentItem]) {
        return TTVideoEngineLoadStateUnknown;
    }
    
    if (_isError) {
        return TTVideoEngineLoadStateError;
    }
    
    switch (_player.loadState) {
        case AVPlayerLoadStateStalled:
            return TTVideoEngineLoadStateStalled;
            break;
        case AVPlayerLoadStatePlayable:
            return TTVideoEngineLoadStatePlayable;
            break;
        case AVPlayerLoadStateError:
            return TTVideoEngineLoadStateError;
            break;
        default:
            return TTVideoEngineLoadStateUnknown;
            break;
    }
}

- (void)setIgnoreAudioInterruption:(BOOL)ignore {
    _ignoreAudioInterruption = ignore;
}

- (void)setMuted:(BOOL)muted
{
    _isMuted = muted;
    
    if (_player) {
        _player.muted = muted;
    }
}

- (BOOL)isMuted {
    if (_player) {
        return _player.isMuted;
    }
    
    return _isMuted;
}

- (BOOL)isCustomPlayer {
    return YES;
}

- (void)didPrepareToPlayUrl:(NSURL *)url {
    if (_isShutdown || _isCompleted){
        return;
    }

    if (_asyncPrepare && _asyncInit) {
        _isPreparedAsync = YES;
        dispatch_async([self _getTaskQueue], ^{
            _playerItem = [_dualCore playerItemWithURL:url];
            [self addPlayerItemObservers:_playerItem];

            _isCompleted = NO;
            _playedToEnd = NO;

            NSMutableDictionary *httpHeader = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ %@",kTTVideoEngineHTTPHeaderUAValue,[TTVideoEngine _engineVersionString]] forKey:kTTVideoEngineHTTPHeaderUAKey];
            if (_header) {
                [httpHeader addEntriesFromDictionary:_header];
            }

            if (!_player){
                _player = [_dualCore playerWithItem:_playerItem options:[httpHeader copy]];
            }
            TTVideoRunOnMainQueue(^{
                _isPreparedAsync = NO;
                [self addPlayerObservers];
                _player.muted = _isMuted;
                _player.volume = self.volume;

                if (_player.currentItem != _playerItem) {
                    [_player replaceCurrentItemWithPlayerItem:_playerItem options:[httpHeader copy]];
                }

                [_player setIntValue:_ignoreAudioInterruption forKey:KeyIsIgnorAudioInterruption];
                [self prepareToPlaySetPlayer];
                if(_isPlayedinPreparedAsync == YES) {
                    _isPlayedinPreparedAsync = NO;
                    [self _play];
                }
            }, NO);
        });
    } else {
        _playerItem = [_dualCore playerItemWithURL:url];
        [self addPlayerItemObservers:_playerItem];

        _isCompleted = NO;
        _playedToEnd = NO;

        NSMutableDictionary *httpHeader = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ %@",kTTVideoEngineHTTPHeaderUAValue,[TTVideoEngine _engineVersionString]] forKey:kTTVideoEngineHTTPHeaderUAKey];
        if (_header) {
            [httpHeader addEntriesFromDictionary:_header];
        }

        if (!_player){
            _player = [_dualCore playerWithItem:_playerItem options:[httpHeader copy]];
        }
        [self addPlayerObservers];
        _player.muted = _isMuted;
        _player.volume = self.volume;
        if (_player.currentItem != _playerItem) {
            [_player replaceCurrentItemWithPlayerItem:_playerItem options:[httpHeader copy]];
        }
        [_player setIntValue:_ignoreAudioInterruption forKey:KeyIsIgnorAudioInterruption];
        [self prepareToPlaySetPlayer];
    }
}

- (void)didPlaybackStateChange {
    TTVideoRunOnMainQueue(^{
        if (_playbackState != self.playbackState) {
            _playbackState = self.playbackState;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(playbackStateDidChange:)]) {
                [self.delegate playbackStateDidChange:self.playbackState];
            }
            
            switch (_playbackState) {
                case TTVideoEnginePlaybackStatePlaying:
                    TTVideoEngineLog(@"TTVideoEnginePlaybackStatePlaying");
                    break;
                case TTVideoEnginePlaybackStateStopped:
                    TTVideoEngineLog(@"TTVideoEnginePlaybackStateStopped");
                    break;
                case TTVideoEnginePlaybackStatePaused:
                    TTVideoEngineLog(@"TTVideoEnginePlaybackStatePaused");
                    break;
                default:
                    break;
            }
        }
    }, NO);
}

- (void)didLoadStateChange {
    if (_loadState != self.loadState) {
        _loadState = self.loadState;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(loadStateDidChange:stallReason:)]) {
            [self.delegate loadStateDidChange:self.loadState stallReason:[self resonFromPlayerCore:_player.stallReason]];
        }
        
        if ((self.loadState & TTVideoEngineLoadStateStalled) != 0) {
            TTVideoEngineLog(@"_loadState TTVideoEngineLoadStateStalled");
        }
        else if ((self.loadState & TTVideoEngineLoadStatePlayable) != 0) {
            TTVideoEngineLog(@"_loadState TTVideoEngineLoadStatePlayable");
        }
        else if ((self.loadState & TTVideoEngineLoadStateUnknown) != 0) {
            TTVideoEngineLog(@"_loadState TTVideoEngineLoadStateUnknown");
        }
    }
}

- (void)didPlayableDurationUpdate {
    NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
    int playableDurationMilli          = (int)(self.playableDuration * 1000);
    int currentPlaybackTimeMilli       = (int)(currentPlaybackTime * 1000);
    int bufferedDurationMilli          = playableDurationMilli - currentPlaybackTimeMilli;
    if (bufferedDurationMilli > 0) {
        self.bufferingProgress = bufferedDurationMilli * 100 / kMaxHighWaterMarkMilli;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playableDurationUpdate:)]) {
        [self.delegate playableDurationUpdate:self.playableDuration];
    }
}

- (void)onError:(NSError *)error {
    _isError = YES;
    _isCompleted = YES;
    _isPrerolling = NO;
    _isPreparedToPlay = NO;
    _isPreparedAsync = NO;
    _isPlayedinPreparedAsync = NO;
    //[self _stopSectionWatchDurationTimer];
    
    __block NSError *blockError = error;
    
    TTVideoEngineLog(@"AVPlayer: onError\n");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self didPlaybackStateChange];
        [self didLoadStateChange];
        if (blockError == nil) {
            blockError = [self createErrorWithCode:kPlayerItemBroken
                                       description:@"player item broken"
                                            reason:@"unknow"];
        }
        else {
            blockError = [NSError errorWithDomain:kTTVideoErrorDomainOwnPlayer code:blockError.code userInfo:blockError.userInfo];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{
                                               TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonPlaybackError),
                                               @"error": blockError
                                               }];
        }
        //
    });
}

- (void)assetFailedToPrepareForPlayback:(NSError *)error {
    if (_isShutdown || _isCompleted)
        return;
    
    [self onError:error];
}

- (void)playerItemDidReachEnd {
    TTVideoEngineLog(@"playerItemDidReachEnd");
    if (_isShutdown || _isCompleted) return;
    
    _isPreparedAsync = NO;
    _isPlayedinPreparedAsync = NO;

    if (_looping) {
        TTVideoRunOnMainQueue(^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
                [self.delegate playbackDidFinish:@{TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonPlaybackEnded)}];
            }
            if (_loopWay == 0) {/// Engine way.
                _isPreparedToPlay = NO;
                //close directly buffering when loop implemented in engine
                self.enableEnterBufferingDirectly = false;
                if (!_isPaused) {
                    [self _play];
                }
            }
        }, NO);
        
        return;
    }

    _isCompleted = YES;
    _playedToEnd = YES;
    _isPrerolling = NO;
    //
    TTVideoRunOnMainQueue(^{
        [self didPlaybackStateChange];
        [self didLoadStateChange];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonPlaybackEnded)}];
        }
        //
    }, NO);
}


#pragma mark KVO

- (void)item:(NSObject<TTAVPlayerItemProtocol> *)playerItem statusChanged:(TTAVPlayerItemStatus)status {
    switch (status) {
        case TTAVPlayerItemStatusReadyToPlay: {
            TTVideoEngineLog(@"player is prepared");
            _isPreparedToPlay = YES;
            NSTimeInterval duration = CMTimeGetSeconds(playerItem.duration);
            if (duration <= 0 || isnan(duration)) {
                self.duration = 0.0f;
            }
            else {
                self.duration = duration;
            }
            [_view setPlayer:_player];
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerIsPrepared)]) {
                [self.delegate playerIsPrepared];
            }
        }
            break;
        case TTAVPlayerItemStatusReadyForDisplay: {
            TTVideoEngineLog(@"player is ready to display");
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerReadyToDisplay)]) {
                [self.delegate playerReadyToDisplay];
            }
        }
            break;
        case TTAVPlayerItemStatusReadyToRender: {
            TTVideoEngineLog(@"player is ready to render");
            _isSeeking = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerIsReadyToPlay)]) {
                [self.delegate playerIsReadyToPlay];
            }
            if (_isPauseWhenNotReady || _isPaused) {
                [self _pause];
            }
            //
            //
            break;
        }
            
        case TTAVPlayerItemStatusFailed: {
            [self assetFailedToPrepareForPlayback:playerItem.error];
        }
            break;
        case TTAVPlayerItemStatusCompleted: {
            [self playerItemDidReachEnd];
        }
        default:
            break;
    }
    
    [self didPlaybackStateChange];
    [self didLoadStateChange];
}

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if (_isShutdown || _isCompleted) {
        return;
    }
    
    if (context == Context_playerItem_state) {
        /* AVPlayerItem "status" property value observer. */
        TTAVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        TTVideoEngineLog(@"status %ld",status);
        NSObject<TTAVPlayerItemProtocol>  *playerItem = (NSObject<TTAVPlayerItemProtocol>  *)object;
        [self item:playerItem statusChanged:status];
    }
    else if (context == Context_playerItem_loadedTimeRanges) {
        //TTVideoEngineLog(@"%@", @"Context_playerItem_loadedTimeRanges");
        NSObject<TTAVPlayerItemProtocol>  *playerItem = (NSObject<TTAVPlayerItemProtocol>  *)object;
        if(_enableReportAllBufferUpdate == YES) {
            if (_player != nil) {
                self.playableDuration = playerItem.loadedProgress * 1.0/100.0 * CMTimeGetSeconds(playerItem.duration);
                [self didPlayableDurationUpdate];
            }
            else {
                self.playableDuration = 0;
            }
        } else {
            if (_player != nil && (playerItem.status == TTAVPlayerItemStatusReadyToPlay || playerItem.status == TTAVPlayerItemStatusReadyToRender || playerItem.status == TTAVPlayerItemStatusReadyForDisplay || (playerItem.loadedProgress >= 99 && playerItem.status == TTAVPlayerItemStatusUnknown && !CMTIME_IS_INDEFINITE(playerItem.duration)))) {
                self.playableDuration = playerItem.loadedProgress * 1.0/100.0 * CMTimeGetSeconds(playerItem.duration);
                [self didPlayableDurationUpdate];
            }
            else {
                self.playableDuration = 0;
            }
        }
    }
    else if (context == Context_playerItem_playbackLikelyToKeepUp) {
        NSObject<TTAVPlayerItemProtocol>  *playerItem = (NSObject<TTAVPlayerItemProtocol>  *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackLikelyToKeepUp: %@",
             playerItem.isPlaybackLikelyToKeepUp ? @"YES" : @"NO");
        [self beginToPlayWithPlayerItem:playerItem];
    }
    else if (context == Context_playerItem_playbackBufferEmpty) {
        NSObject<TTAVPlayerItemProtocol>  *playerItem = (NSObject<TTAVPlayerItemProtocol>  *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackBufferEmpty: %@",
             playerItem.isPlaybackBufferEmpty ? @"YES" : @"NO");
        [self didLoadStateChange];
    }
    else if (context == Context_playerItem_playbackBufferFull) {
        NSObject<TTAVPlayerItemProtocol>  *playerItem = (NSObject<TTAVPlayerItemProtocol>  *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackBufferFull: %@",
             playerItem.isPlaybackBufferFull ? @"YES" : @"NO");
        [self beginToPlayWithPlayerItem:playerItem];
    }
    else if (context == Context_player_playbackState) {
        switch (_player.playbackState) {
            case AVPlayerPlaybackStatePlaying:
                _isPrerolling = YES;
                TTVideoEngineLog(@"AVPlayerPlaybackStatePlaying");
                break;
            case AVPlayerPlaybackStateStopped:
                _isPrerolling = NO;
                TTVideoEngineLog(@"AVPlayerPlaybackStateStopped");
                break;
            case AVPlayerPlaybackStatePaused:
                _isPrerolling = NO;
                TTVideoEngineLog(@"AVPlayerPlaybackStatePaused");
                break;
            case AVPlayerPlaybackStateError:
                _isPrerolling = NO;
                TTVideoEngineLog(@"AVPlayerPlaybackStateError");
                break;
            case AVPlayerPlaybackStateUnknown:
                TTVideoEngineLog(@"AVPlayerPlaybackStateUnknown");
                break;
            default:
                break;
        }
        [self didPlaybackStateChange];
    }
    else if (context == Context_player_loadState) {
        switch (_player.loadState) {
            case AVPlayerLoadStateStalled:
                TTVideoEngineLog(@"AVPlayerLoadStateStalled");
                break;
            case AVPlayerLoadStatePlayable:
                TTVideoEngineLog(@"AVPlayerLoadStatePlayable");
                break;
            case AVPlayerLoadStateError:
                TTVideoEngineLog(@"AVPlayerLoadStateError");
                break;
            case AVPlayerLoadStateUnknown:
                TTVideoEngineLog(@"AVPlayerLoadStateUnknown");
                break;
            default:
                break;
        }
        [self didLoadStateChange];
    }
    else if (context == Context_player_currentItem) {
        NSObject<TTAVPlayerItemProtocol>  *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        TTVideoEngineLog(@"Context_player_currentItem: %@", newPlayerItem);
        
        if (newPlayerItem == (id)[NSNull null])
        {
//            NSError *error = [self createErrorWithCode:kCurrentPlayerItemIsNil
//                                           description:@"current player item is nil"
//                                                reason:nil];
//            [self assetFailedToPrepareForPlayback:error];
        }
        else /* Replacement of player currentItem has occurred */
        {
            if (_preferSpdl4HDR) {
                [_view setOptionForKey:TTPlayerViewPreferSpdlForHDR value:@(YES)];
                if ([_view needRemoveView:_player]) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playerViewWillRemove)]) {
                        [self.delegate playerViewWillRemove];
                    }
                }
            }
            [_view setOptionForKey:TTPlayerViewHandleBackgroundAvView value:@(YES)];
            [_view setPlayer:_player];
            
            [self didPlaybackStateChange];
            [self didLoadStateChange];
        }
    }
    else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (void)videoSizeChange:(NSNotification *)note {
    if (_player != [note object]) {
        return;
    }
    NSInteger width = [[[note userInfo] objectForKey: kTTPlayerVideoSizeWidthKey] integerValue];
    NSInteger height = [[[note userInfo] objectForKey:kTTPlayerVideoSizeHeightKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerVideoSizeChange:height:)]) {
        [self.delegate playerVideoSizeChange:width height:height];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerVideoSizeChange)]) {
        [self.delegate playerVideoSizeChange];
    }
}

- (void)videoBitrateChange:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger bitrate = [[[note userInfo] objectForKey:kTTPlayerBitrateKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerVideoBitrateChanged:)]) {
        [self.delegate playerVideoBitrateChanged:bitrate];
    }
}

- (void)deviceOpened:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger streamType = [[[note userInfo] objectForKey:kTTPlayerStreamTypeKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDeviceOpened:)]) {
        [self.delegate playerDeviceOpened:(TTVideoEngineStreamType)streamType];
    }
}

- (void)audioRenderStart:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerAudioRenderStart)]) {
        [self.delegate playerAudioRenderStart];
    }
    TTVideoEngineLog(@"audio render start");
}

- (void)mediaInfoDidChanged:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger infoId = [[[note userInfo] objectForKey:kTTPlayerInfoIdKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerMediaInfoDidChanged:)]) {
        [self.delegate playerMediaInfoDidChanged:infoId];
    }
}

- (void)avOutsyncStart:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger pts = [[[note userInfo] objectForKey:kTTPlayerTimestamp] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerAVOutsyncStateChange:pts:)]) {
        [self.delegate playerAVOutsyncStateChange:TTVideoEngineAVOutsyncTypeStart pts:pts];
    }
}

- (void)avOutsyncEnd:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger pts = [[[note userInfo] objectForKey:kTTPlayerTimestamp] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerAVOutsyncStateChange:pts:)]) {
        [self.delegate playerAVOutsyncStateChange:TTVideoEngineAVOutsyncTypeEnd pts:pts];
    }
}

- (void)noVARenderStart:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    
    int noRenderType = [[[note userInfo] objectForKey:@"norender_type"] intValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerNOVARenderStateChange:noRenderType:)]) {
        [self.delegate playerNOVARenderStateChange:TTVideoEngineNOVARenderStateTypeStart noRenderType:noRenderType];
    }
}

- (void)noVARenderEnd:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    
    int noRenderType = [[[note userInfo] objectForKey:@"norender_type"] intValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerNOVARenderStateChange:noRenderType:)]) {
        [self.delegate playerNOVARenderStateChange:TTVideoEngineNOVARenderStateTypeEnd noRenderType:noRenderType];
    }
}

- (void)startTimeNoVideoFrame:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    
    int streamDuration = [[[note userInfo] objectForKey:kTTPlayerStreamDuration] intValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerStartTimeNoVideoFrame:)]) {
        [self.delegate playerStartTimeNoVideoFrame:streamDuration];
    }
}

- (void)preBufferingStart:(NSNotification *)note {
    if (_player != [note object]) {
        return;
    }
    NSInteger type = [[[note userInfo] objectForKey:kTTPlayerPreBufferingChangeTypeKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPreBuffering:)]) {
        [self.delegate playerPreBuffering:type];
    }
}

- (void)outleterPaused:(NSNotification *)note {
    if (_player !=  [note object]) {
        return;
    }
    NSInteger streamType = [[[note userInfo] objectForKey:kTTPlayerStreamTypeKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerOutleterPaused:)]) {
        [self.delegate playerOutleterPaused:(TTVideoEngineStreamType)streamType];
    }
    TTVideoEngineLog(@"outleter paused stream:%d",(int)streamType);
}

- (void)barrageMaskInfoNotificate:(NSNotification *)note {
    if (_player != [note object]) {
        return;
    }
    NSInteger maskError = [[[note userInfo] objectForKey:kTTPlayerBarrageMaskInfoErrorCodeKey] integerValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerBarrageMaskInfoCompleted:)]) {
        [self.delegate playerBarrageMaskInfoCompleted:maskError];
    }
}

- (void)beginToPlayWithPlayerItem:(NSObject<TTAVPlayerItemProtocol>*)playerItem {
    [self didLoadStateChange];
    
    if (_isPrerolling && _player.playbackState != AVPlayerPlaybackStatePlaying) {
        [self playerPlay];
    }
}

- (NSError*)createErrorWithCode: (NSInteger)code
                    description: (NSString*)description
                         reason: (NSString*)reason {
    if (description == nil) {
        description = @"";
    }
    if (reason == nil) {
        reason = @"";
    }
    
    NSString *localizedDescription = NSLocalizedString(description, description);
    NSString *localizedFailureReason = NSLocalizedString(reason, reason);
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               localizedDescription, NSLocalizedDescriptionKey,
                               localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                               @(-55555), @"internalCode",
                               nil];
    NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainOwnPlayer
                                         code:0
                                     userInfo:errorDict];
    return error;
}

- (void)setScalingMode:(TTVideoEngineScalingMode)aScalingMode {
    TTVideoEngineScalingMode newScalingMode = aScalingMode;
    switch (aScalingMode) {
        case TTVideoEngineScalingModeNone:
            [_view setContentMode:UIViewContentModeCenter];
            break;
        case TTVideoEngineScalingModeAspectFit:
            [_view setContentMode:UIViewContentModeScaleAspectFit];
            [_view setScaleType:TTPlayerViewScaleTypeAspectFit];
            break;
        case TTVideoEngineScalingModeAspectFill:
            [_view setContentMode:UIViewContentModeScaleAspectFill];
            [_view setScaleType:TTPlayerViewScaleTypeAspectFill];
            break;
        case TTVideoEngineScalingModeFill:
            [_view setContentMode:UIViewContentModeScaleToFill];
            [_view setScaleType:TTPlayerViewScaleTypeToFill];
            break;
        default:
            newScalingMode = _scalingMode;
    }
    
    _scalingMode = newScalingMode;
}

- (void)setAlignMode:(TTVideoEngineAlignMode)alignMode
{
    switch (alignMode) {
        case TTVideoEngineAlignModeCenter:
            [_view setAlignMode:TTPlayerViewAlignModeCenter];
            break;
        case TTVideoEngineAlignModeLeftTop:
            [_view setAlignMode:TTPlayerViewAlignModeLeftTop];
            break;
        case TTVideoEngineAlignModeLeftCenter:
            [_view setAlignMode:TTPlayerViewAlignModeLeftCenter];
            break;
        case TTVideoEngineAlignModeLeftBottom:
            [_view setAlignMode:TTPlayerViewAlignModeLeftBottom];
            break;
        case TTVideoEngineAlignModeTopCenter:
            [_view setAlignMode:TTPlayerViewAlignModeTopCenter];
            break;
        case TTVideoEngineAlignModeBottomCenter:
            [_view setAlignMode:TTPlayerViewAlignModeBottomCenter];
            break;
        case TTVideoEngineAlignModeRightTop:
            [_view setAlignMode:TTPlayerViewAlignModeRightTop];
            break;
        case TTVideoEngineAlignModeRightCenter:
            [_view setAlignMode:TTPlayerViewAlignModeRightCenter];
            break;
        case TTVideoEngineAlignModeRightBottom:
            [_view setAlignMode:TTPlayerViewAlignModeRightBottom];
            break;
        case TTVideoEngineAlignModeSelfDefineRatio:
            [_view setAlignMode:TTPlayerViewAlignModeSelfDefineRatio];
            break;
        default:
            break;
    }
}

- (void)setAlignRatio:(CGFloat)alignRatio
{
    [_view setAlignRatio:alignRatio];
}

- (void)setNormalizeCropArea:(CGRect)normalizeCropArea {
    if (!(CGRectIsNull(normalizeCropArea) || CGRectEqualToRect(CGRectZero, normalizeCropArea))) {
        _view.useNormalizeCropArea = YES;
        _view.normalizeCropArea = normalizeCropArea;
    }
}

- (TTVideoEngineStallReason)resonFromPlayerCore:(AVPlayerStallReason)coreReason {
    switch (coreReason) {
        case AVPlayerStallNetwork:
            return TTVideoEngineStallReasonNetwork;
        case AVPlayerStallDecoder:
            return TTVideoEngineStallReasonDecoder;
        case AVPlayerStallNone:
        default:
            return TTVideoEngineStallReasonNone;
    }
}

- (void)setPrepareFlag:(BOOL)flag {
    _isPreparedToPlay = flag;
}

- (NSString *)getIpAddress{
    return [_player getIPAddress];
}

- (BOOL)getMedialoaderProtocolRegistered {
    return kMedialoaderProtocolRegistered;
}

- (BOOL)getHLSProxyProtocolRegistered {
    return kHLSProxyProtocolRegistered;
}

- (dispatch_queue_t)_getTaskQueue {
    if (self.engine && [self.engine respondsToSelector:@selector(usingSerialTaskQueue)]) {
        return [self.engine usingSerialTaskQueue];
    }
    return TTVideoEngineGetQueue();
}

- (void)setLoadControl:(id<TTAVPlayerLoadControlInterface>)loadControl {
    _loadControl = loadControl;
    [_player setLoadControlInterface:_loadControl];
}

- (NSString *_Nullable)getSubtitleContent:(NSInteger)queryTime Params:(NSMutableDictionary *_Nullable)params {
    if (_player == nil) {
        return nil;
    }
    return [_player getSubtitleContent:queryTime Params:params];
}

- (void)setMaskInfo:(id<TTAVPlayerMaskInfoInterface>)maskInfo {
    _maskInfo = maskInfo;
    [_player setMaskInfoInterface:_maskInfo];
}

- (void)setAIBarrageInfo:(id<TTAVPlayerMaskInfoInterface>)barrageInfo {
    _aiBarrageInfo = barrageInfo;
    [_player setAIBarrageInfoInterface:_aiBarrageInfo];
}

- (void)setEnableReportAllBufferUpdate:(NSInteger)enableReportAllBufferUpdate {
    _enableReportAllBufferUpdate = enableReportAllBufferUpdate;
}

- (void)setSubInfo:(id<TTAVPlayerSubInfoInterface>)subInfo {
    _subInfo = subInfo;
    [_player setSubInfoInterface:_subInfo];
}

- (void)setSubEnable:(BOOL)subEnable {
    if (_subEnable != subEnable) {
        _subEnable = subEnable;
        [_player setIntValue:_subEnable?1:0 forKey:KeyIsSubEnable];
    }
}

- (void)setSubTitleUrlInfo:(NSString *)subTitleUrlInfo {
    if (subTitleUrlInfo.length) {
        _subTitleUrlInfo = subTitleUrlInfo;
        [_player setValueString:_subTitleUrlInfo forKey:KeyIsSubPathInfo];
    }
}

- (void)setSubLanguageId:(NSInteger)subLanguageId {
    _subLanguageId = subLanguageId;
    [_player setIntValue:subLanguageId forKey:KeyIsSwitchSubId];
}

- (void)setEnableRemoveTaskQueue:(BOOL)enableRemoveTaskQueue {
    _enableRemoveTaskQueue = enableRemoveTaskQueue;
}

- (void)refreshPara {
    _intOptions = [NSMutableDictionary dictionary];
    _floatOptions = [NSMutableDictionary dictionary];
    
    _isPrerolling           = NO;
    // _isSeeking              = NO;
    _isError                = NO;
    _isCompleted            = NO;
    _playedToEnd            = NO;
    _testSpeedMode          = -1;
    _defaultVideoBitrate    = 0;
    _embellishTime          = 0;
    _loopStartTime          = 0;
    _loopEndTime            = 0;
    self.bufferingProgress  = 0;
    _isPreparedAsync        = NO;
    _isPlayedinPreparedAsync = NO;
    _isPreparedToPlay = NO;
    
    _loadState = TTVideoEngineLoadStateStalled;
    _playbackState = TTVideoEnginePlaybackStateStopped;
    _imageScaleType = TTVideoEngineImageScaleTypeLinear;
    _enhancementType = TTVideoEngineEnhancementTypeNone;
    _renderType = TTVideoEngineRenderTypeDefault;
    _renderEngine = TTVideoEngineRenderEngineOpenGLES;
    _audioDeviceType = AudioRenderDevcieDefault;
    _mirrorType = TTVideoEngineMirrorTypeNone;
    _decoderOutputType = 1;
    _smoothDelayedSeconds = -1;
    _drmType = TTVideoEngineDrmNone;
    _drmDowngrade = 0;
    _imageLayoutType = TTVideoEngineLayoutTypeToFill;
    
    _accesslog = [[TTVideoEngineAVPlayerItemAccessLog alloc] init];
    _startTime = 0;
    _openTimeOut = 5;
    _playbackSpeed = 1.0;
    _volume = 1.0;
    _asyncInit = false;
    _asyncPrepare = false;
    _cacheMaxSeconds = 30;
    _bufferingTimeOut = 30;
    _maxBufferEndTime = 4;
    _startPlayAudioBufferThreshold = 0;
    _audioEffectEnabled = NO;
    _audioEffectPregain = 0.25;
    _audioEffectThreshold = -18;
    _audioEffectRatio = 8;
    _audioEffectPredelay = 0.007;
    _audioEffectPostgain = 0.0;
    _audioEffectType = 0;
    _audioEffectSrcLoudness = 0.0;
    _audioEffectSrcPeak = 0.0;
    _audioEffectTarLoudness = 0.0;
    _optimizeMemoryUsage = YES;
    _view.memoryOptimizeEnabled = YES;
    _dummyAudioSleep = YES;
    _defaultBufferEndTime = 2;
    _hardwareDecode = YES;
    _handleAudioExtradata = YES;
    _barrageMaskEnable = NO;
    _aiBarrageEnable = NO;
    _subEnable = NO;
    _enableNNSR = NO;
    _nnsrFPSThreshold = 32;
    _prepareMaxCachesMs = 1000;
    _enableRange = NO;
    _enableAllResolutionVideoSR = NO;
    _enableAVStack = 0;
    _terminalAudioUnitPool = NO;
    _audioLatencyQueueByTime = NO;
    _videoEndIsAllEof = NO;
    _enable720pSR = NO;
    _enableFFCodecerHeaacV2Compat = NO;
    _enableKeepFormatThreadAlive = NO;
    _enableBufferingMilliSeconds = NO;
    _isEnablePostPrepareMsg = NO;
    _disableShortSeek = NO;
    _IsPreferNearestSample = NO;
    _playerLazySeek = YES;
    _preferNearestMaxPosOffset = 1048576;
    _defaultBufferingEndMilliSeconds = 1000;
    _maxBufferEndMilliSeconds = 5000;
    _decreaseVtbStackSize = 0;
    _enableHDR10 = NO;
    _findStreamInfoProbeSize = 5000000;
    _findStreamInfoProbeDuration = 0;
    _isEnableRefreshByTime = 0;
    _liveStartIndex = -3;
    _enableFallbackSWDecode = 1;
    _enableLazyAudioUnitOp = YES;
    _precisePausePts = nil;
    _audioCheckInfo = nil;
    _videoCheckInfo = nil;
    _userAgent = nil;
    _enableRemoveTaskQueue = NO;
    _enablePostStart = NO;
    _enablePlayerPreloadGear = NO;
    //player reset
    if (_player) {
        [_player setValueString:_videoCheckInfo forKey:KeyIsVideoCheckInfo];
        [_player setValueString:_audioCheckInfo forKey:KeyIsAudioCheckInfo];
        [_player setIntValue:0 forKey:KeyIsResetInternalPlayerWhenReuse];
    }
    //TTPlayerView reset
    if (_view) {
        _view.hidden = NO;
        _view.frame = [UIScreen mainScreen].bounds;
        [_view removeFromSuperview];
    }
    _isEnableVsyncHelper = 0;
    _customizedVideoRenderingFrameRate = 0;
}

@end

