//
//  TTVideoEngine+Private.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/9.
//

#import "TTVideoEngine.h"
#import "TTVideoEngineInfoFetcher.h"
#import "TTVideoEngineDNSParser.h"
#import "TTVideoNetUtils.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEnginePlayer.h"
#import "TTVideoEngine+SubTitle.h"
#import "TTVideoEngineOptions.h"
#import "TTVideoEnginePlaySourceHeader.h"
#import "TTVideoEnginePlaySource.h"

FOUNDATION_EXTERN UInt64 const kTTVideoEngineHardwareDecodMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineRenderEngineMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineNetworkTimeOutMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineCacheMaxSecondsMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineBufferingTimeOutMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineReuseSocketMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineCacheVideoModelMask;
FOUNDATION_EXTERN UInt64 const kTTVideoEngineUploadAppLogMask;

NS_ASSUME_NONNULL_BEGIN

#ifndef __TTVIDEOENGINE_PUT_METHOD__
#define __TTVIDEOENGINE_PUT_METHOD__
#ifdef DEBUG
#define TTVIDEOENGINE_PUT_METHOD do{\
NSString *key = [NSString stringWithFormat:@"Engine-%p",self];\
NSString *method = [NSString stringWithFormat:@"time = %f. %@",CACurrentMediaTime(),NSStringFromSelector(_cmd)];\
[TTVideoEngine _putWithKey:key method:method];\
}while(NO);
#else
#define TTVIDEOENGINE_PUT_METHOD
#endif
//
#ifdef DEBUG
#define TTVIDEOENGINE_PRINT_METHOD [TTVideoEngine _printAllMethod];
#else
#define TTVIDEOENGINE_PRINT_METHOD
#endif
#endif

/// cache app info.
FOUNDATION_EXTERN NSDictionary *TTVideoEngineAppInfo_Dict;

/// Private @property
@interface TTVideoEngine ()
@property (nonatomic, weak) id<TTVideoEngineFFmpegProtocol> ffmpegProtocol;
@property (nonatomic, strong) id<TTVideoEnginePlaySource> playSource;
@property (nonatomic, strong) TTVideoEnginePlayer  *player;
@property (nonatomic, strong) TTVideoEngineOptions *options;
@property (nonatomic, assign) NSInteger cacheMaxSeconds;
@property (nonatomic, assign) TTVideoEngineRotateType rotateType;
@property (nonatomic, assign) NSInteger bufferingTimeOut;
@property (nonatomic, assign) NSInteger maxBufferEndTime;
/// The key of current play task.
@property (nonatomic, strong) NSMutableArray *localServerTaskKeys;
@property (nonatomic, assign) NSInteger loopWay;
/** Set boe enable. */
@property (nonatomic, assign) BOOL boeEnable;
/** Set boe enable. */
@property (nonatomic, assign) BOOL serverDecodingMode;
/** Set dns cache enable. */
@property (nonatomic, assign) BOOL dnsCacheEnable;
/** Set dns expired time. */
@property (nonatomic, assign) NSInteger dnsExpiredTime;
/** net work status. */
@property (nonatomic, assign) TTVideoEngineNetWorkStatus currentNetworkStatus;
/// Default: 0
@property (nonatomic, assign) UInt64 settingMask;
@property (nonatomic, assign, readonly) long long bitrate;
@property (nonatomic, assign, readonly) long long audioBitrate;
@property (nonatomic, assign, readonly) long long videoAreaFrame;
/** Set bash enable. */
@property (nonatomic, assign) BOOL bashEnable;
/** Set hls seamless switch enable. */
@property (nonatomic, assign) BOOL hlsSeamlessSwitch;
/** Set mask thread enable. */
@property (nonatomic, assign) BOOL barrageMaskThreadEnable;
/** Set AI Barrage thread enable */
@property (nonatomic, assign) BOOL aiBarrageThreadEnable;
/** Set sub enable. */
@property (nonatomic, assign) BOOL subThreadEnable;
/** Set mask enable dataloader */
@property (nonatomic, assign) BOOL maskEnableDataLoader;
/** Set barrage mask enable. */
@property (nonatomic, assign) BOOL barrageMaskEnable;
/** Set AI barrage enable */
@property (nonatomic, assign) BOOL aiBarrageEnable;
/** barrage mask url*/
@property (nonatomic, copy) NSString *barrageMaskUrl;
/** Set subtitle enable. */
@property (nonatomic, assign) BOOL subEnable;
/** Set subtitle language id */
@property (nonatomic, assign) NSInteger currentSubLangId;
/** record subtitle info*/
@property (nonatomic, copy, nullable) NSDictionary *subtitleInfo;
/** subtitle request language query */
@property (nonatomic, copy, nullable) NSString *subLangQuery;
@property (nonatomic, nullable, strong) TTVideoEngineURLInfo *currentVideoInfo;
@property (nonatomic, nullable, strong) TTVideoEngineURLInfo *dynamicVideoInfo;
@property (nonatomic, nullable, strong) TTVideoEngineURLInfo *dynamicAudioInfo;
/// ...
/** drm creater */
@property (nonatomic, assign) DrmCreater drmCreater;
/** drm type */
@property (nonatomic, assign) TTVideoEngineDrmType drmType;
/** drm downgrade */
@property (nonatomic, assign) NSInteger drmDowngrade;
/** drm retry */
@property (nonatomic, assign) BOOL drmRetry;
/** drm token url template */
@property (nonatomic, copy) NSString *tokenUrlTemplate;
/** check info string */
@property (nonatomic, copy) NSString *checkInfoString;
/** bash url */
@property (nonatomic,   copy, readwrite) NSString *playUrl;
/** Using mediaDataLoader,limit the size of cache file. */
@property (nonatomic, assign) NSInteger limitMediaCacheSize;
@property (nonatomic, assign) NSInteger preloadUpperBufferMs;
@property (nonatomic, assign) NSInteger preloadLowerBufferMs;
@property (nonatomic, assign) BOOL preloadDurationCheck;
@property (nonatomic, assign) BOOL isEnablePreloadCheckTimer;
/** Support for setting expired VideoModel. */
@property (nonatomic, assign) BOOL supportExpiredModel;
/** config map */
@property (nonatomic, strong) NSDictionary *currentParams;
/** Set https enable. */
@property (nonatomic, assign) BOOL httpsEnabled;
/** Set https enable by app. */
@property (nonatomic, assign) BOOL enableHttps;
/** Set https enable by retry. */
@property (nonatomic, assign) BOOL retryEnableHttps;
/** Performance log switch. */
@property (nonatomic, assign) BOOL performanceLogEnable;
/** Set check hijack. */
@property (nonatomic, assign) BOOL checkHijack;
/** hijack retry enable. */
@property (nonatomic, assign) BOOL hijackRetryEnable;
/** hijack retry count. */
@property (nonatomic, assign) BOOL isHijackRetried;
/** hijack retry main dns type */
@property (nonatomic, assign) TTVideoEngineDnsType hijackRetryMainDnsType;
/** hijack retry backup dns type */
@property (nonatomic, assign) TTVideoEngineDnsType hijackRetryBackupDnsType;
/** Set seek end enable. */
@property (nonatomic, assign) BOOL seekEndEnabled;
@property (nonatomic, copy) NSString *subtag;
@property (nonatomic, copy) NSString *customStr;
/** Disable short seek */
@property (nonatomic, assign) BOOL disableShortSeek;
/** report request headers. */
@property (nonatomic, assign) BOOL reportRequestHeaders;
/** report response headers. */
@property (nonatomic, assign) BOOL reportResponseHeaders;
@property (nonatomic, assign, readonly) CGFloat videoOutputFPS;
@property (nonatomic, assign, readonly) CGFloat containerFPS;
/** Enable cache duration to calc buffer percentage */
@property (nonatomic, assign) BOOL enableTimerBarPercentage;
/** enable dash abr */
@property (nonatomic, assign) BOOL enableDashAbr;
/** code type */
@property (nonatomic, assign) TTVideoEngineEncodeType codecType;
/** whether used abr in per playback  */
@property(nonatomic, assign) BOOL isUsedAbr;
/**abr switch mode*/
@property(nonatomic, assign) TTVideoEngineDashABRSwitchMode abrSwitchMode;
/** abr probe count */
@property (nonatomic, assign, readonly) NSInteger abrProbeCount;
/** abr switch count */
@property (nonatomic, assign, readonly) NSInteger abrSwitchCount;
/** abr average bitrate */
@property (nonatomic, assign, readonly) NSInteger abrAverageBitrate;
/** abr average play speed */
@property (nonatomic, assign, readonly) CGFloat abrAveragePlaySpeed;

@property(nonatomic, assign, readonly) NSInteger abrDiddAbs;

@property(nonatomic, assign) TTVideoEngineDashSegmentFlag segmentFormatFlag;
@property(nonatomic, assign) NSInteger mABR4GMaxResolutionIndex;

@property(nonatomic, assign) BOOL isRegistedObservePlayViewBound;

/** enable index cache */
@property (nonatomic, assign) BOOL enableIndexCache;
/** enable frag range */
@property (nonatomic, assign) BOOL enableFragRange;
/** enable async */
@property (nonatomic, assign) BOOL enableAsync;
/** range mode */
@property (nonatomic, assign) TTVideoEngineRangeMode rangeMode;
/** read mode */
@property (nonatomic, assign) TTVideoEngineReadMode readMode;
/** video range size */
@property (nonatomic, assign) NSInteger videoRangeSize;
/** audio range size */
@property (nonatomic, assign) NSInteger audioRangeSize;
/** video range time */
@property (nonatomic, assign) NSInteger videoRangeTime;
/** audio range time */
@property (nonatomic, assign) NSInteger audioRangeTime;
/** skip find stream info */
@property (nonatomic, assign) BOOL skipFindStreamInfo;
/** update timestamp mode */
@property (nonatomic, assign) TTVideoEngineUpdateTimestampMode updateTimestampMode;
/** enable open timeout */
@property (nonatomic, assign) BOOL enableOpenTimeout;
/** enable tt hls drm */
@property (nonatomic, assign) BOOL enableTTHlsDrm;
/** tt hls drm token*/
@property (nonatomic, copy) NSString *ttHlsDrmToken;
/** nnsr */
@property (nonatomic, assign) BOOL enableNNSR;
/** nnsr fps threshold */
@property (nonatomic, assign) NSInteger nnsrFpsThreshold;
/** all resolution sr */
@property (nonatomic, assign) BOOL enableAllResolutionVideoSR;
/** range */
@property (nonatomic, assign) BOOL enableRange;
/// First frame metrics.
@property (nonatomic,   copy) NSDictionary *firstFrameMetrics;
/// player log info.
@property (nonatomic,   copy) NSString *playerLog;
/// Bytes read by the player
@property (nonatomic, assign, readonly) int64_t playBytes;
@property (nonatomic, assign) NSInteger idleTimerAutoMode;
@property (nonatomic, assign) BOOL enableEnterBufferingDirectly;
@property (nonatomic, assign) TTVideoEngineMirrorType mirrorType;
//output buffer wait in avplayer
@property (nonatomic, assign) NSInteger outputFramesWaitNum;
@property (nonatomic, assign) NSInteger startPlayAudioBufferThreshold;
@property (nonatomic, assign) BOOL audioEffectEnabled;
@property (nonatomic, assign) BOOL aeForbidCompressor;
@property (nonatomic, assign) CGFloat audioEffectPregain;
@property (nonatomic, assign) CGFloat audioEffectThreshold;
@property (nonatomic, assign) CGFloat audioEffectRatio;
@property (nonatomic, assign) CGFloat audioEffectPredelay;
@property (nonatomic, assign) CGFloat audioEffectPostgain;
@property (nonatomic, assign) NSInteger audioEffectType;
@property (nonatomic, assign) CGFloat audioEffectSrcLoudness;
@property (nonatomic, assign) CGFloat audioEffectSrcPeak;
@property (nonatomic, assign) CGFloat audioEffectTarLoudness;
@property (nonatomic, assign) BOOL optimizeMemoryUsage;
@property (nonatomic, assign) BOOL audioUnitPoolEnabled;
@property (nonatomic, assign) BOOL avSyncStartEnable;
@property (nonatomic, assign) NSInteger threadWaitTimeMS;
@property (nonatomic, assign) BOOL codecDropSkippedFrame;
@property (nonatomic, assign) BOOL playerLazySeek;
@property (nonatomic, strong) NSDictionary *videoInfoDict;
@property (nonatomic, assign) NSInteger abrTimerInterval;
@property (nonatomic, assign) int64_t startPlayTimestamp;
@property (nonatomic, assign) BOOL useFallbackApi;
@property (nonatomic, assign) BOOL fallbackApiMDLRetry;
@property (nonatomic,   copy) NSString *engineHash;
@property (nonatomic, assign) BOOL useEphemeralSession;
@property (nonatomic, assign) BOOL dummyAudioSleep;
@property (nonatomic,   copy) NSString *playSourceId;
@property (nonatomic, assign) BOOL usingEngineQueue;
@property (nonatomic, assign, readonly) NSInteger currentVideoTime;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) NSInteger defaultBufferEndTime;
@property (nonatomic, assign) TTVideoEngineDecoderOutputType decoderOutputType;
@property (nonatomic, assign) NSInteger prepareMaxCacheMs;
@property (nonatomic, assign) NSInteger mdlCacheMode;
@property (nonatomic, assign) NSInteger httpAutoRangeOffset;
@property (nonatomic, assign) NSInteger normalClockType;
@property (nonatomic, assign) NSInteger skipBufferLimit;
@property (nonatomic, assign) NSInteger enableReportAllBufferUpdate;
@property (nonatomic, strong) id<TTVideoEngineNetClient> subtitleNetworkClient;

@property (nonatomic, assign) BOOL notifyBufferBeforeFirstFrame;
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
@property (nonatomic, assign) NSInteger findStreamInfoProbeSize;
@property (nonatomic, assign) NSInteger findStreamInfoProbeDuration;
@property (nonatomic, assign) BOOL enableRefreshByTime;
@property (nonatomic, assign) NSInteger liveStartIndex;
@property (nonatomic, assign) BOOL enableFallbackSWDecode;
@property (nonatomic, assign) NSInteger maxAccumulatedErrCount;
@property (nonatomic, assign) NSInteger hdr10VideoModelLowBound;
@property (nonatomic, assign) NSInteger hdr10VideoModelHighBound;
@property (nonatomic, assign) BOOL preferSpdl4HDR;
@property (nonatomic, assign) BOOL stopSourceAsync;
@property (nonatomic, assign) BOOL enableSeekInterrupt;
@property (nonatomic, assign) BOOL enableLazyAudioUnitOp;
@property (nonatomic, assign, readonly) BOOL audioEffectOpened;
@property (nonatomic, assign) NSInteger audioCodecId;
@property (nonatomic, assign) NSInteger videoCodecId;
@property (nonatomic, assign) NSInteger audioCodecProfile;
@property (nonatomic, assign) NSInteger videoCodecProfile;
@property (nonatomic, assign) NSInteger changeVtbSizePicSizeBound;
@property (nonatomic, assign) BOOL enableRangeCacheDuration;
@property (nonatomic, assign) BOOL enableVoiceSplitHeaacV2;
@property (nonatomic, assign) BOOL enableAudioHardwareDecode;
@property (nonatomic, assign) BOOL delayBufferingUpdate;
@property (nonatomic, assign) BOOL noBufferingUpdate;
@property (nonatomic, assign) BOOL keepVoiceDuration;
@property (nonatomic, assign) NSInteger voiceBlockDuration;
@property (nonatomic, assign) BOOL preferSpdl4HDRUrl;
@property (nonatomic, assign) BOOL enableSRBound;
@property (nonatomic, assign) NSInteger srLongDimensionLowerBound;
@property (nonatomic, assign) NSInteger srLongDimensionUpperBound;
@property (nonatomic, assign) NSInteger srShortDimensionLowerBound;
@property (nonatomic, assign) NSInteger srShortDimensionUpperBound;
@property (nonatomic, assign) BOOL filePlayNoBuffering;
@property (nonatomic, assign) NSInteger maskStopTimeout;
@property (nonatomic, assign) NSInteger subtitleStopTimeout;
@property (nonatomic, assign) BOOL skipSetSameWindow;
@property (nonatomic, assign) BOOL cacheVoiceId;
@property (nonatomic, assign, readonly) NSInteger qualityType;
@property (nonatomic, assign) BOOL recheckVPLSforDirectBuffering;
@property (nonatomic, copy) NSString *responderChain;
/** 控制点播日志traceid关联预加载traceid*/
@property (nonatomic, assign) BOOL enableReportPreloadTraceId;
/** 控制移除engine实例绑定的taskQueue，用于线上AB实验*/
@property (nonatomic, assign) BOOL enableRemoveTaskQueue;
/** enable player post start*/
@property (nonatomic, assign) BOOL enablePostStart;
/** 是否开启分档位预加载数据获取*/
@property (nonatomic, assign) BOOL enablePlayerPreloadGear;
@property (nonatomic, assign) NSInteger enableGetPlayerReqOffset;
@property (nonatomic, assign) BOOL enableClearMdlCache;
@property (nonatomic, copy) NSString *mCompanyId;

/// ...
//!OCLINT
+ (NSString *)_engineVersionString;

//获取event内部信息
- (id)getEventLogger;

/**
-get video sr width
-on condition of video sr enable
-@return video display width
-*/
- (NSInteger)getVideoSRWidth;

/**
-get video sr height
-on condition of video sr enable
-@return video display height
-*/
- (NSInteger)getVideoSRHeight;

/**
 @return file format:
         dash
         hls
         bash
         mov
         flv
 */
- (NSString *)getFileFormat;

- (NSString *)getStreamTrackInfo;

/** get  urlinfo list of videoModel*/
- (NSArray<TTVideoEngineURLInfo *> *)getUrlInfoList;
/** get predict algo */
+ (ABRPredictAlgoType)getPredictAlgoType;

/** get once select algo type */
+ (ABROnceAlgoType)getOnceSelectAlgoType;

/**
 * when engine was given back to enginePool, stop method would be called.
 * engine should reset all options before it is reused by user.
 */
- (void)resetAllOptions;

/**
  * when we want to get a pure engine from enginePool, some engine parameters should be refresh.
 */
- (void)refreshEnginePara;

//发生串音后上报埋点以及回调消息
- (void)crosstalkHappen:(NSMutableArray*)crosstalkEngines;

//获取播放器信息
- (NSDictionary*)getEnginePlayInfo;

- (void)setEnableHookVoice:(BOOL)hook;

@end

/// Private
@class TTVideoEnginePlayer;
@interface TTVideoEngine (Private)
// Debug
+ (void)_putWithKey:(NSString *)key method:(NSString *)method;
+ (void)_printAllMethod;
@end

@interface TTVideoEngine (SubTitle)
//subtitle
- (NSString *_Nullable)_getSubtitleUrlWithHostName:(NSString *)hostName
                                               vid:(NSString *)vid
                                            fileId:(NSString *)fileId
                                          language:(nullable NSString *)language
                                            format:(nullable NSString *)format;

- (void)_requestSubtitleInfoWithUrlString:(NSString *)urlString
                                  handler:(void (^)(NSString * _Nullable, NSError * _Nullable))handler;
@end

@interface TTVideoEngine (autoRes)

+ (TTVideoEngineURLInfo *)_getAutoResolutionInfo:(TTVideoEngineAutoResolutionParams *)autoResParams playSource:(id<TTVideoEnginePlaySource>)playSource;

+ (TTVideoEngineURLInfo *)_getAutoResolutionInfo:(TTVideoEngineAutoResolutionParams *)autoResParams infoModel:(TTVideoEngineInfoModel *)infoModel;

@end

@interface TTVideoEngine (PCDN)

typedef NS_ENUM(NSInteger, VEKPlayInfo) {
    VEKPlayInfoRenderStart = 0,
    VEKPlayInfoPlayingPos  = 1,
    VEKPlayInfoLoadPercent = 2,
    VEKPlayInfoBufferingStart = 3,
    VEKPlayInfoBufferingEnd = 4,
    VEKPlayInfoCurrentBuffer = 5,
    VEKPlayInfoSeekAction = 6,
};

- (void) _syncPlayInfoToMdlForKey:(NSInteger)key Value:(int64_t)value;
- (void) _startTimerToSyncPlayInfo;
- (void) _stopTimerToSyncPlayInfo;

@end


@interface TTVideoEngineCopy : NSObject

/// Copy engine
+ (void)copyEngine:(TTVideoEngine *)engine;

/// Assign engine
+ (void)assignEngine:(TTVideoEngine *)engine;

/// Reset
+ (void)reset;

@end


NS_ASSUME_NONNULL_END
