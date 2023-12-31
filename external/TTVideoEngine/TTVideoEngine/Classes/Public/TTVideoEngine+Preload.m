//
//  TTVideoEngine+Preload.m
//  TTVideoEngine
//
//  Created by 黄清 on 2018/11/28.
//

#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineInfoFetcher.h"
#import "TTVideoEnginePreloadQueue.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngine+Options.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineDownloader+Private.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineEnvConfig.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngine+Tracker.h"
#import "TTVideoEngineCollector.h"
#import "TTVideoEngineSettings.h"
#import "TTVideoEngineStrategy.h"

#import "TTVideoEngineStartUpSelector.h"
#import "TTVideoEngineActionManager.h"
#import "TTVideoEngineNetworkPredictorAction.h"

#import <pthread.h>
#import <MDLMediaDataLoader/AVMDLDataLoader.h>
#import "TTVideoEngineKeys.h"

#if USE_HLSPROXY
#import <PlaylistCacheModule/HLSProxyModule.h>
#import <PlaylistCacheModule/HLSProxySettings.h>
#import <PlaylistCacheModule/HLSLoaderManager.h>
#endif
/// Default priority, will enque task from the back.
const NSInteger TTVideoEnginePrloadPriorityDefault = 0;
/// Default priority, will exec when no other play/preload task
const NSInteger TTVideoEnginePrloadPriorityIDLE = 10;
/// High priority, will enque task from the front.
const NSInteger TTVideoEnginePrloadPriorityHigh    = 100;
/// Highest priority, will enque task from the front ,and only cancel by the key.
const NSInteger TTVideoEnginePrloadPriorityHighest = 10000;

NSString * const HLSPROXY_HEADER = @"hlsproxy://";

static NSInteger s_preload_strategy = 0;

typedef NS_ENUM(NSInteger, MDLTaskType) {
    MDLTaskPlay         = 1,
    MDLTaskPreload      = 2,
    MDLTaskDownload     = 3,
};

void mdl_alog_write_var(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, ...) {
    if (_format == NULL) {
        return;
    }
    
    @autoreleasepool{
        if(g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogMDL) {
            va_list arg;
            va_start(arg, _format);
            char temp[4 *1024] = {'\0'};
            vsnprintf(temp, sizeof(temp), _format, arg);
            va_end(arg);
            NSString *log = [NSString stringWithFormat:@"%s", temp];
            TTVideoEngineLogMethod(TTVideoEngineLogSourceMDL, (kBDLogLevel)_level, log);
        }
    }
}

@interface TTVideoEnginePreloaderURLItem ()
/// Custom header
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSString *> *customHeaders;
@end

@interface TTVideoEngineLocalServerConfigure ()
+ (instancetype)configure;
@end

@class _TTVideoEnginePreloadTask;
@protocol _TTVideoEnginePreloadTaskDelegate <NSObject>

@required
- (void)taskFinished:(_TTVideoEnginePreloadTask *)task;

@end

@interface _TTVideoEngineTaskQueue : NSObject
@property(atomic, assign) NSInteger maxCount;
@property(nonatomic, assign, readonly) NSInteger count;
- (nullable _TTVideoEnginePreloadTask *)backTask;
- (nullable _TTVideoEnginePreloadTask *)popBackTask;
- (nullable _TTVideoEnginePreloadTask *)taskForKey:(NSString *)key;
- (nullable _TTVideoEnginePreloadTask *)popTaskForKey:(NSString *)key;
- (nullable _TTVideoEnginePreloadTask *)taskForVideoId:(NSString *)videoId;
- (nullable _TTVideoEnginePreloadTask *)popTaskForVideoId:(NSString *)videoId;
- (BOOL)enqueueTask:(_TTVideoEnginePreloadTask *)task;
- (BOOL)containTask:(_TTVideoEnginePreloadTask *)task;
- (BOOL)containTaskForKey:(NSString *)key;
- (void)popAllTasks;
- (void)popTask:(_TTVideoEnginePreloadTask *)task;
@end

@interface _TTVideoEngineLocalServerObserver : NSObject<TTVideoEnginePreloadQueueItem>

@property (nonatomic, weak) id<TTVideoEngineLocalServerToEngineProtocol> target;
@property (nonatomic, copy) NSString *key;

@end

@implementation _TTVideoEngineLocalServerObserver

/// MARK: - TTVideoEnginePreloadQueueItem
- (NSString *)itemKey {
    return self.key;
}

@end

@interface _TTVideoEnginePreloadTrackItem : NSObject
@property(nonatomic,   copy) NSString *taskKey;
@property(nonatomic,   copy) NSString *proxyUrl;
@property(nonatomic, assign) TTVideoEngineResolutionType usingResolution;
@property(nonatomic, nullable, copy) NSString *decryptionKey;
@property(nonatomic, nullable, strong) TTVideoEngineURLInfo *urlInfo;
@property(nonatomic,   copy) NSArray *urls;
@property(nonatomic, assign) TTVideoEngineCacheState cacheState;

@property(nonatomic, assign) NSInteger preloadHeaderSize;
@property(nonatomic, assign) NSInteger preloadFooterSize;
@property(nonatomic, assign) NSInteger preloadOffset;
@property(nonatomic, assign) NSInteger preloadSize;
@property(nonatomic, assign) NSInteger mediaSize;
@property(nonatomic, assign) NSInteger cacheSize;
@property(nonatomic,   copy) NSString *localFilePath;
@property(nonatomic,   copy) NSString *customHeader;
@property(nonatomic,   copy) NSString *tag;
@property(nonatomic,   copy) NSString *subtag;
@property(nonatomic,   copy) NSString *extraInfo;

@property(nonatomic, assign) BOOL isFooterPreloaded;

@end

@implementation _TTVideoEnginePreloadTrackItem

- (instancetype)init {
    if (self = [super init]) {
        _usingResolution = TTVideoEngineResolutionTypeUnknown;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    
    if (![object isKindOfClass:[_TTVideoEnginePreloadTrackItem class]]) {
        return NO;
    }
    
    _TTVideoEnginePreloadTrackItem *other = (_TTVideoEnginePreloadTrackItem *)object;
    return [other.taskKey isEqualToString:_taskKey];
}

@end

@interface _TTVideoEnginePreloadTask : NSObject<TTVideoInfoFetcherDelegate>

@property(nonatomic,   weak) id<_TTVideoEnginePreloadTaskDelegate> delegate;
@property(nonatomic,   copy) NSString *videoId;
@property(nonatomic, assign) TTVideoEngineResolutionType targetResolution;
@property(nonatomic, assign) int64_t preloadMilliSecond;
@property(nonatomic, assign) int64_t preloadMilliSecondOffset;
@property(nonatomic, assign) int64_t preloadOffset;
@property(nonatomic, assign) int64_t preSize;
@property(nonatomic, strong) TTVideoEngineInfoFetcher *fetcher;
@property(nonatomic, strong) TTVideoEngineModel *responseData;
@property(nonatomic, strong) NSError  *responseError;
@property(nonatomic, strong) TTVideoEnginePreloaderURLItem *urlItem;
@property(nonatomic, strong) TTVideoEnginePreloaderVidItem *vidItem;
@property(nonatomic, strong) TTVideoEnginePreloaderVideoModelItem *videoModelItem;
@property(nonatomic, assign) NSInteger priorityLevel;
@property(nonatomic, assign) BOOL onceNotify;
@property(nonatomic, assign) NSInteger dashVideoPreloadSize;
@property(nonatomic, assign) NSInteger dashAudioPreloadSize;

@property(nonatomic, strong) NSMutableArray *tracks;
@end

@implementation _TTVideoEnginePreloadTask

- (instancetype)init {
    if (self = [super init]) {
        _tracks = [NSMutableArray array];
        _dashVideoPreloadSize = -1;
        _dashAudioPreloadSize = -1;
    }
    return self;
}

- (_TTVideoEnginePreloadTrackItem *)getTrackItem:(NSString *)key {
    NSAssert(s_string_valid(key), @"key is invalid");
    _TTVideoEnginePreloadTrackItem *item = nil;
    NSArray *tracks = self.tracks.copy;
    if (tracks.count > 0) {
        for (_TTVideoEnginePreloadTrackItem *tem in tracks) {
            if ([key isEqualToString:tem.taskKey]) {
                item = tem;
                break;
            }
        }
    }
    return item;
}

- (_TTVideoEnginePreloadTrackItem *)addTrackItemByKey:(NSString *)key {
    NSAssert(s_string_valid(key), @"key is invalid");
    _TTVideoEnginePreloadTrackItem *retItem = [self getTrackItem:key];
    if (!retItem) {
        retItem = [[_TTVideoEnginePreloadTrackItem alloc] init];
        retItem.taskKey = key;
        [self.tracks addObject:retItem];
    }
    return retItem;
}

- (void)removeVidPlaceholderTrack {
    if (_vidItem == nil) {
        return;
    }

    if (_tracks.count == 1) {
        [_tracks removeLastObject];
    }
}

- (BOOL)preloadCahceComplete {
    BOOL ret = YES;
    NSArray *tracks = self.tracks.copy;
    if (tracks.count > 0) {
        for (_TTVideoEnginePreloadTrackItem *tem in tracks) {
            if (tem.cacheSize < tem.preloadSize && tem.cacheSize < tem.mediaSize) {
                ret = NO;
                break;
            }
        }
    }
    return ret;
}

+ (instancetype)preloadTask:(NSString *)key
                    videoId:(NSString *)videoId
                    preSize:(NSInteger)preSize
                    vidItem:(TTVideoEnginePreloaderVidItem *)vidItem {
    return [self preloadTask:key videoId:videoId preloadOffset:0 preSize:preSize vidItem:vidItem];
}

+ (instancetype)preloadTask:(NSString *)key
                    videoId:(NSString *)videoId
              preloadOffset:(NSInteger)preloadOffset
                    preSize:(NSInteger)preSize
                    vidItem:(TTVideoEnginePreloaderVidItem *)vidItem {
    return [self preloadTask:key videoId:videoId preSize:preSize vidItem:vidItem videoModeltem:nil];
}

+ (instancetype)preloadTask:(NSString *)key
                    videoId:(NSString *)videoId
                    preSize:(NSInteger)preSize
                    vidItem:(TTVideoEnginePreloaderVidItem *)vidItem
              videoModeltem:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem {
    
    NSAssert(s_string_valid(key), @"key is invalid");
    _TTVideoEnginePreloadTask *task = [[_TTVideoEnginePreloadTask alloc] init];
    _TTVideoEnginePreloadTrackItem *track = [task addTrackItemByKey:key];
    track.preloadSize = preSize;
    
    task.videoId = videoId;
    task.preSize = preSize;
    task.vidItem = vidItem;
    
    if (videoModelItem) {
        task.priorityLevel = videoModelItem.priorityLevel;
        task.targetResolution = videoModelItem.resolution;
        task.responseData = videoModelItem.videoModel;
    }
    
    // Fetcher
    if (vidItem) {
        TTVideoEngineInfoFetcher *fetcher = [[TTVideoEngineInfoFetcher alloc] init];
        fetcher.retryCount = 3;
        fetcher.cacheModelEnable = YES;
        fetcher.delegate = (id<TTVideoInfoFetcherDelegate>)task;
        task.fetcher = fetcher;
    }
    
    return task;
}

- (void)notifyPreloadProgress:(TTVideoEngineLoadProgress *)progress {
    TTVideoEngineLog(@"preload task progress. progress: %@", progress);
    TTVideoRunOnMainQueue(^{
        if (self.urlItem.preloadProgress) {
            self.urlItem.preloadProgress(progress);
        } else if (self.vidItem.preloadProgress) {
            self.vidItem.preloadProgress(progress);
        } else if (self.videoModelItem.preloadProgress) {
            self.videoModelItem.preloadProgress(progress);
        }
    }, NO);
}

- (void)notifyPreloadEnd:(TTVideoEngineLocalServerTaskInfo *)info error:(NSError *)error {
    TTVideoEngineLog(@"preload task finished. info: %@, error: %@",info,error);
    TTVideoRunOnMainQueue(^{
        if (!self.onceNotify) {
            self.onceNotify = YES;
            
            if (self.urlItem.preloadEnd) {
                self.urlItem.preloadEnd(info, error);
            } else if (self.vidItem.preloadEnd) {
                self.vidItem.preloadEnd(info, error);
            } else if (self.videoModelItem.preloadEnd) {
                self.videoModelItem.preloadEnd(info, error);
            }
        }
    }, NO);
}

- (void)notifyPreloadStart:(NSDictionary*) info {
    TTVideoEngineLog(@"preload task started. info: %@",info);
    TTVideoRunOnMainQueue(^{
        if (self.urlItem.preloadDidStart) {
            self.urlItem.preloadDidStart(info);
        } else if (self.vidItem.preloadDidStart) {
            self.vidItem.preloadDidStart(info);
        } else if (self.videoModelItem.preloadDidStart) {
            self.videoModelItem.preloadDidStart(info);
        }
    }, NO);
}

/// MARK: - TTVideoInfoFetcherDelegate

- (void)infoFetcherDidFinish:(NSInteger)status {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskFinished:)]) {
        [self.delegate taskFinished:self];
    }
}

- (void)infoFetcherDidFinish:(TTVideoEngineModel *)videoModel error:(NSError *)error {
    if (videoModel) {
        self.responseData = videoModel;
    }
    self.responseError = error;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskFinished:)]) {
        [self.delegate taskFinished:self];
    }
}

- (void)infoFetcherShouldRetry:(NSError *)error {
    
}

- (void)infoFetcherDidCancel {
    
}

- (void)infoFetcherFinishWithDNSError:(NSError *)error {
    
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    
    if (![object isKindOfClass:[_TTVideoEnginePreloadTask class]]) {
        return NO;
    }
    
    _TTVideoEnginePreloadTask *other = (_TTVideoEnginePreloadTask *)object;
    if ([other.videoId isEqualToString:_videoId]) {
        if ([[other.tracks lastObject] isEqual:[_tracks lastObject]]) {
            return YES;
        }
    }
    return NO;
}

@end

@interface _TTVideoEnginePreloadTaskGroup : _TTVideoEnginePreloadTask

@property (nonatomic, strong) _TTVideoEnginePreloadTask* nextPreloadTask;

+ (instancetype)preloadTask:(NSString *)key
                    videoId:(NSString *)videoId
              preloadOffset:(NSInteger)preloadOffset
                    preSize:(NSInteger)preSize
              videoModeltem:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem
                   nextTask:(_TTVideoEnginePreloadTask*) nextTask;

@end

@implementation _TTVideoEnginePreloadTaskGroup

+ (instancetype)preloadTask:(NSString *)key
                    videoId:(NSString *)videoId
              preloadOffset:(NSInteger)preloadOffset
                    preSize:(NSInteger)preSize
              videoModeltem:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem
                   nextTask:(_TTVideoEnginePreloadTask*) nextTask {
    NSAssert(s_string_valid(key), @"key is invalid");
    _TTVideoEnginePreloadTaskGroup *task = [[_TTVideoEnginePreloadTaskGroup alloc] init];
    _TTVideoEnginePreloadTrackItem *track = [task addTrackItemByKey:key];
    track.preloadSize = preSize;
    track.preloadOffset = preloadOffset;
    
    task.preloadOffset = preloadOffset;
    task.videoId = videoId;
    task.preSize = preSize;
    task.nextPreloadTask = nextTask;
    
    if (videoModelItem) {
        task.priorityLevel = videoModelItem.priorityLevel;
        task.targetResolution = videoModelItem.resolution;
        task.responseData = videoModelItem.videoModel;
    }

    
    return task;
}

@end

#ifndef __TTVIDEOENGINE_PRELOAD__
#define __TTVIDEOENGINE_PRELOAD__
#define PRELOAD [_TTVideoEnginePreloadManager shareLoader]
#endif

#ifndef __MODULE_IS_RUNING__
#define __MODULE_IS_RUNING__
#define MODULE_IS_RUNING NSAssert(_running, @"data loader need start");\
if (_running == NO) {\
return;\
}
#endif

@class HLSLoaderManager;

@interface _TTVideoEnginePreloadManager : NSObject {
    pthread_mutex_t _runStateLock;
}

@property(nonatomic,   weak) id<TTVideoEnginePreloadDelegate> preloadDelegate;
@property(nonatomic,   copy) TTVideoEngineSpeedInfoBlock speedInfoBlock;
@property(nonatomic, strong) _TTVideoEngineTaskQueue *preloadTasks;
@property(nonatomic, strong) _TTVideoEngineTaskQueue *executeTasks;
@property(nonatomic, strong) _TTVideoEngineTaskQueue *allPlayTasks;
@property(nonatomic, strong) _TTVideoEngineTaskQueue *allPreloadTasks;
@property(nonatomic, strong) TTVideoEnginePreloadQueue *observes;
@property(nonatomic, strong) TTVideoEnginePreloadQueue *progressObjects;
@property(nonatomic, strong) AVMDLDataLoader *preloader;
@property(nonatomic, strong) HLSLoaderManager *playlistLoaderManager;
@property(nonatomic, assign, getter=isRunning) BOOL running;
@property(nonatomic, assign) NSInteger heartBeatInterval;
@property(nonatomic, strong) NSTimer* heartBeatTimer;
@property(nonatomic, strong) dispatch_queue_t heartBeatQueue;
@property (nonatomic, strong) NSLock *speedInfoBlockLock;

- (void) updateTimer;
- (nullable NSString *)_headerString:(NSDictionary *)header;
@end

@implementation _TTVideoEnginePreloadManager

- (void)dealloc {
    pthread_mutex_destroy(&_runStateLock);
}

+ (instancetype)shareLoader {
    static _TTVideoEnginePreloadManager *s_loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_loader = [[_TTVideoEnginePreloadManager alloc] init];
    });
    return s_loader;
}

- (instancetype)init {
    if (self = [super init]) {
        _preloadTasks = [[_TTVideoEngineTaskQueue alloc] init];
        _executeTasks = [[_TTVideoEngineTaskQueue alloc] init];
        _executeTasks.maxCount = 4;
        _observes = [[TTVideoEnginePreloadQueue alloc] init];
        _allPlayTasks = [[_TTVideoEngineTaskQueue alloc] init];
        _allPreloadTasks = [[_TTVideoEngineTaskQueue alloc] init];
        _progressObjects = [[TTVideoEnginePreloadQueue alloc] init];
        _heartBeatInterval = 0;
        _speedInfoBlockLock = [[NSLock alloc] init];
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init (&attr);
        pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_runStateLock, &attr);
        pthread_mutexattr_destroy (&attr);
    }
    return self;
}

- (void)setPreloadDelegate:(id<TTVideoEnginePreloadDelegate>)preloadDelegate {
    _preloadDelegate = preloadDelegate;
}

- (void)start {
    pthread_mutex_lock(&_runStateLock);
    if (_running) {
        pthread_mutex_unlock(&_runStateLock);
        return;
    }
    
    if (self.preloader == nil) {
        AVMDLDataLoaderConfigure* configObject = [AVMDLDataLoaderConfigure defaultConfigure];

        if ([TTVideoEngineLocalServerConfigure configure].isEnableMDL2) {
            configObject.isEnableMDL2 = [TTVideoEngineLocalServerConfigure configure].isEnableMDL2;
        }

        if ([TTVideoEngineLocalServerConfigure configure].isEnableLazyBufferPool) {
            configObject.isEnableLazyBufferpool = [TTVideoEngineLocalServerConfigure configure].isEnableLazyBufferPool;
        }
        _preloader = [AVMDLDataLoader dataLoaderWithConfigure:configObject];
        [configObject setTryCount:0];
        [_preloader setDelegate:(id<AVMDLDataLoaderProtocol>)self];
    }
    
#if USE_HLSPROXY
    if ([TTVideoEngine ls_localServerConfigure].isEnableHLSProxy) {
        [HLSProxyModule setProxyUrlGenerator:[[AVMDLDataLoader shareInstance] getUrlGenerator]];
        _playlistLoaderManager = [HLSLoaderManager shareInstance];
        [_playlistLoaderManager setPreloaderDelegate:(id<TaskMeassgeProcotol>)self];
    }
#endif
    NSError *error = nil;
    // configure
    [self _configureSetting];
    //
    [self.preloader start:&error];
    if (error) {
        _running = NO;
        TTVideoEngineLog(@"local server start fail. error = %@",error);
        if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(preloaderErrorForVid:errorType:error:)]) {
            [_preloadDelegate preloaderErrorForVid:nil errorType:TTVideoEngineDataLoaderErrorStart error:error];
        }
    } else {
        _running = YES;
    }
    
    [self _configureMdlAlog];
    [self _vodStrategyConfig];
    pthread_mutex_unlock(&_runStateLock);
    
    /// Settings
    TTVideoEngineSettings.settings.config().load();
    
    if(_heartBeatInterval > 0 && _running) {
        // start heart beat task
        _heartBeatQueue = dispatch_queue_create("vcloud.mdl.heartbeat.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(_heartBeatQueue, ^{
            __weak id weakSelf = self;
            _heartBeatTimer = [NSTimer timerWithTimeInterval:_heartBeatInterval/1000
                                                      target:weakSelf
                                                    selector:@selector(updateTimer)
                                                    userInfo:nil
                                                     repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.heartBeatTimer forMode:NSDefaultRunLoopMode];
            CFRunLoopRun();
        });
    }
}

- (BOOL)isRunning {
    BOOL tem = NO;
    if (pthread_mutex_trylock(&_runStateLock) == 0) {
        tem = _running;
        pthread_mutex_unlock(&_runStateLock);
    }
    return tem;
}

- (void)close {
    pthread_mutex_lock(&_runStateLock);
    if (!_running) {
        pthread_mutex_unlock(&_runStateLock);
        return;
        
    }
    _running = NO;
    pthread_mutex_unlock(&_runStateLock);
    
    _preloadDelegate = nil;
    [self _cancelAllTasks];
    [self.preloader close];
}

- (void)updateTimer {
    pthread_mutex_lock(&_runStateLock);
    if (_running) {
        do {
            if (_preloader == nil || _preloadDelegate == nil) {
                break;
            }
            NSString* costLog = [_preloader getStringValue:0];
            if (costLog == nil) {
                TTVideoEngineLog(@"get cost log failed");
                break;
            }
            TTVideoEngineLog(@"get cost log: %@", costLog);
            NSData* data = [costLog dataUsingEncoding:NSUTF8StringEncoding];
            if (data == nil || data.length == 0) {
                TTVideoEngineLog(@"invalid cost log");
                break;
            }
            NSError *error;
            NSDictionary *logDict = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:&error];
            if (logDict != nil) {
                [self logUpdate:logDict];
            }
        } while(0);
    } else {
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    pthread_mutex_unlock(&_runStateLock);
}

/// Task Manager

- (void)addTask:(NSString *)key vidItem:(TTVideoEnginePreloaderVidItem *)vidItem {
    if (vidItem == nil || !s_string_valid(vidItem.videoId)) {
        TTVideoEngineLog(@"ls_addTask:... videoId invalid.");
        if (vidItem.preloadEnd) {
            vidItem.preloadEnd(nil, [NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                        code:TTVideoEnginePreloadErrCodeParameter
                                                    userInfo:@{@"reason":@"videoId invalid"}]);
        }
        return;
    }
    
    [self _addTask:key vid:vidItem.videoId preSize:vidItem.preloadSize urlItem:nil vidItem:vidItem videoModeltem:nil];
}

- (void)addTaskWithURLItem:(TTVideoEnginePreloaderURLItem *)urlItem {
    if (!urlItem || !s_string_valid(urlItem.key)) {
        TTVideoEngineLog(@"url preload urlItem invalid");
        if (urlItem.preloadEnd) {
            urlItem.preloadEnd(nil, [NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                        code:TTVideoEnginePreloadErrCodeParameter
                                                    userInfo:@{@"reason":@"url preload urlItem invalid"}]);
        }
        return;
    }
    
    [self _addTask:urlItem.key vid:urlItem.videoId preSize:urlItem.preloadSize urlItem:urlItem vidItem:nil videoModeltem:nil];
}

- (void)addTask:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem {
    NSString *videoId = [videoModelItem.videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
    if (!s_string_valid(videoId)) {
        TTVideoEngineLog(@"addTask:... videoId invalid.");
        if (videoModelItem.preloadEnd) {
            videoModelItem.preloadEnd(nil, [NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                               code:TTVideoEnginePreloadErrCodeParameter
                                                           userInfo:@{@"reason":@"videoId invalid"}]);
        }
        return;
    }
    TTVideoEngineLog(@"videoId = %@, targetResolution = %@",videoId,@(videoModelItem.resolution));
    TTVideoEngineResolutionType temType = videoModelItem.resolution;
    videoModelItem.videoModel.videoInfo.params = videoModelItem.params;
    TTVideoEngineURLInfo *urlModel = [videoModelItem.videoModel.videoInfo videoInfoForType:&temType autoMode:YES];
    videoModelItem.resolution = temType;
    
    NSString *key = [urlModel getValueStr:VALUE_FILE_HASH];
    if (!s_string_valid(key)) {
        TTVideoEngineLog(@"addTask:... filehash invalid.");
        if (videoModelItem.preloadEnd) {
            videoModelItem.preloadEnd(nil, [NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                               code:TTVideoEnginePreloadErrCodeParameter
                                                           userInfo:@{@"reason":@"filehash invalid."}]);
        }
        return;
    }
    
    [self _addTask:key vid:videoId preSize:videoModelItem.preloadSize urlItem:nil vidItem:nil videoModeltem:videoModelItem];
}

- (void)_addTask:(NSString *)key
             vid:(nullable NSString *)videoId
         preSize:(NSInteger)preSize
         urlItem:(TTVideoEnginePreloaderURLItem *)urlItem
         vidItem:(TTVideoEnginePreloaderVidItem *)vidItem
   videoModeltem:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem {
    _TTVideoEnginePreloadTask* task = [_TTVideoEnginePreloadTask preloadTask:key
                                                                     videoId:videoId
                                                               preloadOffset:0
                                                                     preSize:preSize
                                                                     vidItem:vidItem];
    task.urlItem = urlItem;
    task.videoModelItem = videoModelItem;
    task.responseData = videoModelItem.videoModel;
    task.dashVideoPreloadSize = videoModelItem.dashVideoPreloadSize;
    task.dashAudioPreloadSize = videoModelItem.dashAudioPreloadSize;
    
    if (urlItem) {
        task.priorityLevel = urlItem.priorityLevel;
        task.targetResolution = TTVideoEngineResolutionTypeUnknown;
    } else if (vidItem) {
        task.priorityLevel = vidItem.priorityLevel;
        task.delegate = (id<_TTVideoEnginePreloadTaskDelegate>)self;
        task.targetResolution = vidItem.resolution;
    } else if (videoModelItem) {
        // gear strategy
        if(videoModelItem.enableGearStrategy) {
            TTVideoEngineGearMutilParam params = [NSMutableDictionary new];
            TTVideoEngineGearContext *strategyContext = [TTVideoEngineGearContext new];
            strategyContext.videoModel = videoModelItem.videoModel;
            TTVideoEngineGearParam result = [TTVideoEngineStrategy.helper gearVideoModel:videoModelItem.videoModel type:TTVideoEngineGearPreloadType extraInfo:params context:strategyContext];
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
                TTVideoEngineLog(@"[GearStrategy] addTask videoBitrate=%d audioBitrate=%d", videoBitrate, audioBitrate);
                TTVideoEngineURLInfo *selectedInfo = [TTVideoEngineStrategy.helper urlInfoFromModel:videoModelItem.videoModel bitrate:videoBitrate mediaType:TTVideoEngineGearKeyMediaTypeVideo];
                if(selectedInfo) {
                    videoModelItem.resolution = [selectedInfo videoDefinitionType];
                    TTVideoEngineLog(@"[GearStrategy] addTask selected result: %ld", videoModelItem.resolution);
                }
            }
        }
        task.priorityLevel = videoModelItem.priorityLevel;
        task.targetResolution = videoModelItem.resolution;
        task.preloadMilliSecond = videoModelItem.preloadMilliSecond;
        task.preloadMilliSecondOffset = videoModelItem.preloadMilliSecondOffset;
    }
    
    if ([self.preloadTasks containTaskForKey:key] ||
        [self.executeTasks containTaskForKey:key] ||
        [self.allPreloadTasks containTaskForKey:key]) {
        [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                             code:TTVideoEnginePreloadErrCodeSameTask
                                                         userInfo:@{@"reason":@"same task",@"key":key?:@""}]];
        return;
    }
    
    TTVideoEngineLog(@"local server add preload task, key = %@, rawKey = %@, preloadSize:%ld",key,videoId,(long)preSize);
    
    [self.preloadTasks enqueueTask:task];
    
    [self _startExecuteTask];
}

- (void)_startExecuteTask {
    MODULE_IS_RUNING
    
    _TTVideoEnginePreloadTask *task = [self.preloadTasks backTask];
    if (!task || ![self.executeTasks enqueueTask:task]) {
        return;
    }
    
    [self.preloadTasks popBackTask];
    
    if (task.responseData != nil || !s_array_is_empty(task.urlItem.urls)) {
        [self _exectTask:task];
        return;
    }
    /// Need fetch videoInfo
    NSString* apiString = nil;
    NSString* authString = nil;
    [task removeVidPlaceholderTrack];
    NSDictionary* params = @{@"codec_type":(task.vidItem.codecType == TTVideoEngineByteVC2 ? @"4":(task.vidItem.codecType == TTVideoEngineByteVC1 ? @"3":@"0")),
                             @"format_type":(task.vidItem.dashEnable ? @"dash" : @"mp4"),
                             @"ssl":(task.vidItem.httpsEnable ? @"1" : @"0")};
    
    /// First use the callback of vidItem.
    if (task.vidItem.apiStringCall) {
        apiString = task.vidItem.apiStringCall(task.vidItem.apiVersion, task.vidItem.videoId);
        
        if (task.vidItem.authCall) {
            authString = task.vidItem.authCall(task.vidItem.apiVersion, task.vidItem.videoId);
        }
    }
    
    if (!s_string_valid(apiString) && _preloadDelegate && [_preloadDelegate respondsToSelector:@selector(apiStringForVid:resolution:)]) {
        apiString = [_preloadDelegate apiStringForVid:task.videoId resolution:task.targetResolution];
        
        if ([_preloadDelegate respondsToSelector:@selector(authStringForVid:resolution:)]) {
            authString = [_preloadDelegate authStringForVid:task.videoId resolution:task.targetResolution];
        }
    }
    
    if(apiString && task.vidItem.boeEnable){
        apiString = TTVideoEngineBuildBoeUrl(apiString);
    }
    apiString = TTVideoEngineBuildHttpsUrl(apiString);
    TTVideoEngineLog(@"preload task start fetch video model. apiString = %@, authString = %@, apiVersion = %zd",apiString,authString,task.vidItem.apiVersion);
    task.fetcher.networkSession = task.vidItem.netClient;
    task.fetcher.apiversion = task.vidItem.apiVersion;
    if (apiString) {
        [task.fetcher fetchInfoWithAPI:apiString parameters:params auth:authString vid:task.videoId];
    }
}

- (void)cancelTaskByVideoId:(NSString *)vid {
    if (!vid) {
        return;
    }
    
    NSMutableArray *temKeys = [NSMutableArray array];
    _TTVideoEnginePreloadTask *task = nil;
    task = [self.preloadTasks taskForVideoId:vid];
    NSArray *tracks = task.tracks.copy;
    for (_TTVideoEnginePreloadTrackItem *tem in tracks) {
        [temKeys ttvideoengine_addObject:tem.taskKey];
    }
    
    task = [self.executeTasks taskForVideoId:vid];
    tracks = task.tracks.copy;
    for (_TTVideoEnginePreloadTrackItem *tem in tracks) {
        [temKeys ttvideoengine_addObject:tem.taskKey];
    }
    
    task = [self.allPreloadTasks taskForVideoId:vid];
    tracks = task.tracks.copy;
    for (_TTVideoEnginePreloadTrackItem *tem in tracks) {
        [temKeys ttvideoengine_addObject:tem.taskKey];
    }
    
    /// cancel task by key.
    for (NSString *key in temKeys.copy) {
        [self cancelTaskByKey:key];
    }
}

- (void)cancelTaskByKey:(NSString *)key {
    MODULE_IS_RUNING
    
    _TTVideoEnginePreloadTask *task = nil;
    if (task = [self.executeTasks popTaskForKey:key]) {
        [task.fetcher cancel];
        [self _notifyCanceled:task];
    }
    else if (task = [self.preloadTasks popTaskForKey:key]) {
        [task.fetcher cancel];
        [self _notifyCanceled:task];
    }
    else if (task = [self.allPreloadTasks popTaskForKey:key]) {
#if USE_HLSPROXY
        if (_playlistLoaderManager) {
            [_playlistLoaderManager cancelByKey:key];
        }
#endif
        [self.preloader cancelTaskByKey:key];
        
        [self _notifyCanceled:task];
    }
}

- (void)cancelAllTasks {
    MODULE_IS_RUNING
    
    [self _cancelAllTasks];
}

- (void)cancelAllIdlePreloadTasks {
    MODULE_IS_RUNING
    
    [self _cancelAllIdlePreloadTasks];
}

- (void)clearAllCaches {
    [self.preloader clearAllCaches];
#if USE_HLSPROXY
    if (_playlistLoaderManager) {
        [_playlistLoaderManager removeAllFileCache];
    }
#endif
}

- (void)removeFileCacheByKey:(NSString *)key {
    [self.preloader removeFileCacheByKey:key];
#if USE_HLSPROXY
    [_playlistLoaderManager removeFileCacheByKey:key];
#endif
}

- (int64_t)getAllCacheSize {
    int64_t size = [self.preloader getAllCacheSize];
#if USE_HLSPROXY
    if (_playlistLoaderManager) {
        size += [_playlistLoaderManager getAllCacheSize];
    }
#endif
    return size;
}

- (int64_t)getCacheSizeByKey:(NSString *)key {
    int64_t temResult = [self.preloader getCacheSizeByKey:key];
#if USE_HLSPROXY
    if (_playlistLoaderManager) {
        temResult += [_playlistLoaderManager getCacheSizeByKey:key];
    }
#endif
    return temResult;
}

- (int64_t)tryQuickGetCacheSizeByKey:(NSString *)key {
    return [self.preloader tryQuickGetCacheSizeByKey:key];
}

- (int64_t)getCacheSizeByFilePath:(NSString *)filePath {
    NSString *key = [TTVideoEngine _ls_keyFromFilePath:filePath];
    return [self.preloader getCacheSize:key filePath:filePath];
}

- (NSString *)getCacheInfoByKey:(NSString *)key {
    return [self.preloader getCacheFileInfo:key];
}

- (NSString *)getCacheInfoByFilePath:(NSString *)filePath {
    NSString *key = [TTVideoEngine _ls_keyFromFilePath:filePath];
     return [self.preloader getCacheFileInfo:key filePath:filePath];
}

- (void)getCacheSizeByKey:(NSString *)key result:(void(^)(int64_t size))result {
    [self.preloader cacheSizeByKey:key result:result];
}

- (void)disableAutoTrimForKey:(NSString *)key {
    [self.preloader setFileAutoDeleteFlag:key flag:1];
}

- (void)enableAutoTrimForKey:(NSString *)key {
    [self.preloader setFileAutoDeleteFlag:key flag:0];
}

- (void)getCacheSizeByFilePath:(NSString *)filePath result:(void (^)(int64_t))result {
    NSString *key = [TTVideoEngine _ls_keyFromFilePath:filePath];
    [self.preloader getCacheSize:key filePath:filePath result:result];
}

- (void*)getNativeMedialoaderHandle {
    return [self.preloader getMdlProtocolHandle];
}

- (void)_notifyCanceled:(_TTVideoEnginePreloadTask *)task {
    TTVideoRunOnMainQueue(^{
        if (!task.onceNotify) {
            task.onceNotify = YES;

            if (task.urlItem.preloadCanceled) {
                task.urlItem.preloadCanceled();
            } else if (task.vidItem.preloadCanceled) {
                task.vidItem.preloadCanceled();
            } else if (task.videoModelItem.preloadCanceled) {
                task.videoModelItem.preloadCanceled();
            }
        }
    }, NO);
}

- (void)setSpeedInfoBlock:(TTVideoEngineSpeedInfoBlock)speedInfoBlock {
    [_speedInfoBlockLock lock];
    _speedInfoBlock = speedInfoBlock;
    [_speedInfoBlockLock unlock];
}

- (void)_cancelAllTasks {
    _TTVideoEnginePreloadTask *task = nil;
    NSMutableArray *temTasks = [NSMutableArray array];
    if (self.executeTasks.count > 0) {
        while (task = [self.executeTasks popBackTask]) {
            if (task.priorityLevel >= TTVideoEnginePrloadPriorityHighest) {
                [temTasks addObject:task];
            } else {
                [task.fetcher cancel];
                [self _notifyCanceled:task];
            }
        }
        
        for (_TTVideoEnginePreloadTask *temTask in temTasks) {
            [self.executeTasks enqueueTask:temTask];
        }
        [temTasks removeAllObjects];
    }
    
    if (self.preloadTasks.count > 0) {
        while (task = [self.preloadTasks popBackTask]) {
            if (task.priorityLevel >= TTVideoEnginePrloadPriorityHighest) {
                [temTasks addObject:task];
            } else {
                [self _notifyCanceled:task];
            }
        }
        
        for (_TTVideoEnginePreloadTask *temTask in temTasks) {
            [self.preloadTasks enqueueTask:temTask];
        }
        [temTasks removeAllObjects];
    }

    if (self.allPreloadTasks.count > 0) {
        BOOL mdlCancel = NO;
        while (task = self.allPreloadTasks.popBackTask) {
            if (task.priorityLevel >= TTVideoEnginePrloadPriorityHighest) {
                [temTasks addObject:task];
            } else {
                mdlCancel = YES;
                [self _notifyCanceled:task];
            }
        }
        
        if (mdlCancel) {
#if USE_HLSPROXY
            [_playlistLoaderManager cancelAll];
#endif
            [self.preloader cancelAll];
        }
        
        for (_TTVideoEnginePreloadTask *temTask in temTasks) {
            [self.allPreloadTasks enqueueTask:temTask];
        }
        [temTasks removeAllObjects];
    }
}

- (void)_cancelAllIdlePreloadTasks {
    [self.preloader cancelAllIdle];
}

- (void)_preConnectUrl:(NSString*) urlString {
    if (!urlString || [NSURL URLWithString:urlString] == nil) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    int defaultPort = -1;
    if ([urlString hasPrefix:@"https"]) {
        defaultPort = 443;
    } if ([urlString hasPrefix:@"http"]) {
        defaultPort = 80;
    }
    NSString* host = url.host;
    NSNumber* port = url.port;
    if (host) {
        int portNum = [port intValue] ?: defaultPort;
        [self.preloader preConnectByHost:host port:portNum];
    }
}

- (BOOL)switchToDefaultNetwork {
    return [self.preloader switchToDefaultNetwork];
}

- (BOOL)switchToCellularNetwork {
    return [self.preloader switchToCellularNetwork];
}

- (void)suspendSocketCheck {
    [self.preloader suspendPreconnect];
}

- (void)resumeSocketCheck {
    [self.preloader resumePreconnect];
}

- (void) _copyCache:(TTVideoEngineCopyCacheItem *)copyCacheItem {
    AVMDLCopyOperation *copyOperation = [[AVMDLCopyOperation alloc]
                                         initWithKey:copyCacheItem.fileKey destPath:copyCacheItem.destPath
                                         waitIfCaching:copyCacheItem.waitIfCaching
                                         completionBlock:copyCacheItem.completionBlock];
    copyOperation.forceCopy = copyCacheItem.forceCopy;
    copyOperation.infoBlock = copyCacheItem.infoBlock;
    [PRELOAD.preloader asyncCopy:copyOperation];
}

/// MARK: - Observer

- (void)addObserver:(_TTVideoEngineLocalServerObserver *)observer {
    NSParameterAssert(observer.target && observer.key);
    NSArray *temObserves = [self.observes itemsForKey:observer.key];
    BOOL shouldAdd = YES;
    //
    if (temObserves.count > 0) {
        for (_TTVideoEngineLocalServerObserver *obj in temObserves) {
            if (obj.target == observer.target) {
                shouldAdd = NO;
                break;
            }
        }
    }
    //
    if (shouldAdd) {
        [self.observes enqueueItem:observer];
    }
}

- (void)removeObserver:(_TTVideoEngineLocalServerObserver *)observer {
    NSArray *temObserves = [self.observes itemsForKey:observer.key];
    if (temObserves.count > 0) {
        _TTVideoEngineLocalServerObserver *resultObserver = nil;
        for (_TTVideoEngineLocalServerObserver *obj in temObserves) {
            if (obj.target == observer.target) {
                resultObserver = obj;
                break;
            }
        }
        //
        if (resultObserver) {
            [self.observes popItem:resultObserver];
            resultObserver.target = nil;
            resultObserver.key = nil;
        }
    }
}

/// MARK: -

- (void)_configureSetting {
    TTVideoEngineLocalServerConfigure *configure = [TTVideoEngineLocalServerConfigure configure];
    if (configure.maxCacheSize > 0) {
        PRELOAD.preloader.configure.maxCacheSize = configure.maxCacheSize;
    }
    if (configure.openTimeOut > 0) {
        PRELOAD.preloader.configure.openTimeOut = configure.openTimeOut;
    }
    if (configure.rwTimeOut > 0) {
        PRELOAD.preloader.configure.rwTimeOut = configure.rwTimeOut;
    }
    PRELOAD.preloader.configure.tryCount = configure.tryCount;
    if (configure.preloadParallelNum > 0) {
        PRELOAD.preloader.configure.preloadParallelNum = configure.preloadParallelNum;
    } else {
        PRELOAD.preloader.configure.preloadParallelNum = 2; // default
    }
    if (configure.maxCacheAge > 0) {
        PRELOAD.preloader.configure.maxCacheAge = configure.maxCacheAge;
    }
    if (s_string_valid(configure.cachDirectory)) {
        PRELOAD.preloader.configure.cachDirectory = configure.cachDirectory;
    }
    if (s_string_valid(configure.downloadDirectory)) {
        PRELOAD.preloader.configure.downloadDir = configure.downloadDirectory;
    }
    
    if (s_string_valid(configure.mdlExtensionOpts)) {
        PRELOAD.preloader.configure.mdlExtensionOpts = configure.mdlExtensionOpts;
    }
    PRELOAD.preloader.configure.checksumLevel = configure.checksumLevel;
    PRELOAD.preloader.configure.isEnableExternDNS = configure.enableExternDNS ? 1 : 0;
    PRELOAD.preloader.configure.isEnableSoccketReuse = configure.enableSoccketReuse ? 1 : 0;
    PRELOAD.preloader.configure.isEnableLazyBufferpool = configure.isEnableLazyBufferPool ? 1 : 0;
    PRELOAD.preloader.configure.enablePreconnect = configure.isEnablePreConnect ? 1 : 0;
    PRELOAD.preloader.configure.preconnectNum = configure.preConnectNum;
    PRELOAD.preloader.configure.socketIdleTimeout = configure.socketIdleTimeout;
    PRELOAD.preloader.configure.writeFileNotifyIntervalMS =configure.writeFileNotifyIntervalMS;
    PRELOAD.preloader.configure.isEnableAlog = configure.isEnableMDLAlog;
    PRELOAD.preloader.configure.isEnableNewBufferpool = configure.isEnableNewBufferpool;
    PRELOAD.preloader.configure.newBufferpoolBlockSize = configure.newBufferpoolBlockSize;
    PRELOAD.preloader.configure.newBufferpoolResidentSize = configure.newBufferpoolResidentSize;
    PRELOAD.preloader.configure.newBufferpoolGrowBlockCount = configure.newBufferpoolGrowBlockCount;
    PRELOAD.preloader.configure.isEnablePlayLog = configure.isEnablePlayLog;
    TTVideoEngineLog(@"set write file notify intervalMS: %zd",configure.writeFileNotifyIntervalMS);
    PRELOAD.preloader.configure.isEnableSessionReuse = configure.isEnableSessionReuse ? 1 : 0;
    PRELOAD.preloader.configure.sessionTimeout = configure.sessionTimeout;
    PRELOAD.preloader.configure.maxTlsVersion = configure.maxTlsVersion;
    PRELOAD.preloader.configure.isEnableLoaderPreempt = configure.isEnableLoaderPreempt ? 1 : 0;
    PRELOAD.preloader.configure.nextDownloadThreshold = configure.nextDownloadThreshold;
    PRELOAD.preloader.configure.maxIPV6Count = configure.maxIPV6Count;
    PRELOAD.preloader.configure.maxIPV4Count = configure.maxIPV4Count;
    //default enable auth
    PRELOAD.preloader.configure.isEnableAuth = 1;
    _heartBeatInterval = configure.heartBeatInterval;
    PRELOAD.preloader.configure.isEnableFileExtendBuffer = configure.isEnableFileExtendBuffer ? 1 : 0;
    PRELOAD.preloader.configure.isEnableNetScheduler = configure.isEnableNetScheduler ? 1 : 0;
    PRELOAD.preloader.configure.isNetSchedulerBlockAllNetErr = configure.isNetSchedulerBlockAllNetErr ? 1 : 0;
    PRELOAD.preloader.configure.netSchedulerBlockDuration = configure.netSchedulerBlockDuration;
    PRELOAD.preloader.configure.netSchedulerBlockErrCount = configure.netSchedulerBlockErrCount;
    PRELOAD.preloader.configure.isAllowTryTheLastUrl = configure.isAllowTryLastUrl ? 1 : 0;
    PRELOAD.preloader.configure.isEnableCacheReqRange = configure.isEnableCacheReqRange ? 1: 0;
    PRELOAD.preloader.configure.isEnableLocalDNSThreadOptimize = configure.isEnableLocalDNSThreadOptimize;
    PRELOAD.preloader.configure.fileExtendSizeKB = configure.fileExtendSizeKB;
    PRELOAD.preloader.configure.isEnableFixCancelPreload = configure.isEnableFixCancelPreload ? 1: 0;
    PRELOAD.preloader.configure.isEnableDNSNoLockNotify = configure.isEnableDNSNoLockNotify;
    

    PRELOAD.preloader.configure.connectPoolStragetyValue = configure.connectPoolStragetyValue;
    PRELOAD.preloader.configure.maxAliveHostNum = configure.maxAliveHostNum;
    PRELOAD.preloader.configure.maxSocketReuseCount = configure.maxSocketReuseCount;
    
    PRELOAD.preloader.configure.isEnableEarlyData = configure.isEnableEarlyData;
    PRELOAD.preloader.configure.cacheDirMaxCacheSize = configure.cacheDirMaxCacheSize;
    PRELOAD.preloader.configure.forbidByPassCookie = configure.isEnableByPassCookie ? 1 : 0;
    PRELOAD.preloader.configure.socketTrainingCenterConfigStr = configure.socketTrainingCenterConfigStr;
    PRELOAD.preloader.configure.netSchedulerBlockHostErrIpCount = configure.netSchedulerBlockHostErrIpCount;
    PRELOAD.preloader.configure.isEnableIOManager = configure.enableIOManager;
    PRELOAD.preloader.configure.socketRecvBufferSize = configure.socketRecvBufferSizeByte;
    PRELOAD.preloader.configure.mUseNewSpeedTestForSingle = configure.isEnableNewNetworkSpeedTest ? 1 : 0;
    PRELOAD.preloader.configure.isEnableMaxCacheAgeForAllDir =
    configure.isEnableMaxCacheAgeForAllDir;
        
    PRELOAD.preloader.configure.maxFileMemCacheSize = configure.maxFileMemCacheSize;
    PRELOAD.preloader.configure.maxFileMemCacheNum = configure.maxFileMemCacheNum;
    
    PRELOAD.preloader.configure.isEnableReqWaitNetReachable = configure.isEnableReqWaitNetReachable;
    PRELOAD.preloader.configure.loadMonitorTimeInternal = configure.loadMonitorTimeInternal;
    PRELOAD.preloader.configure.loadMonitorMinAllowLoadSize = configure.loadMonitorMinAllowLoadSize;
    PRELOAD.preloader.configure.netSchedulerConfigStr = configure.netSchedulerConfigStr;
    PRELOAD.preloader.configure.loaderType = configure.loaderType;
    
    // appinfo
    NSMutableDictionary *appInfo = [NSMutableDictionary dictionary];
    [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAID] forKey:@"app_id"];
    [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAppName] forKey:@"app_name"];
    [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineDeviceId] forKey:@"device_id"];
    [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineAppVersion] forKey:@"app_version"];
    [appInfo setValue:TTVideoEngineAppInfo_Dict[TTVideoEngineChannel] forKey:@"app_channel"];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:appInfo options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (jsonData) {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    PRELOAD.preloader.configure.appInfo = jsonString;
    PRELOAD.preloader.configure.dynamicPreconnectConfigStr = configure.dynamicPreconnectConfigStr;
    PRELOAD.preloader.configure.isEnableUseOriginalUrl = configure.isEnableUseOriginalUrl ? 1 : 0;
    PRELOAD.preloader.configure.isEnableLoaderLogExtractUrls = configure.isEnableLoaderLogExtractUrls;
    PRELOAD.preloader.configure.maxLoaderLogNum = configure.maxLoaderLogNum;
    PRELOAD.preloader.configure.isEnableCellularUp = configure.isEnableMultiNetwork;
    PRELOAD.preloader.configure.temporaryOptStr = configure.temporaryOptStr;
    PRELOAD.preloader.configure.threadStackSizeLevel = configure.threadStackSizeLevel;
    PRELOAD.preloader.configure.isEnableUnLimitHttpHeader = configure.isEnableUnlimitHttpHeader;
    PRELOAD.preloader.configure.enableThreadPoolCheckIdle = configure.isEnableThreadPoolCheckIdle;
    PRELOAD.preloader.configure.threadPoolIdleTTLSecond = configure.threadPoolIdleTTLSecond;
    PRELOAD.preloader.configure.threadPoolMinCount = configure.threadPoolMinCount;
    PRELOAD.preloader.configure.enableFileMutexOptimize = configure.isEnableFileMutexOptimize;
    PRELOAD.preloader.configure.isEnableMDL2 = configure.isEnableMDL2;
    PRELOAD.preloader.configure.skipCdnUrlBeforeExpireSec = configure.skipCDNBeforeExpire;
    PRELOAD.preloader.configure.fileBufferOptStr = configure.fileRingBufferOptStr;
    if (configure.isIgnoreTextSpeedTest) {
        PRELOAD.preloader.configure.ignoreTextSpeedTest = configure.isIgnoreTextSpeedTest;
    }
    if (configure.ringBufferSize > 0) {
        PRELOAD.preloader.configure.ringBufferSize = configure.ringBufferSize;
    }
    
    NSString* ua = @"";
    if (!isEmptyStringForVideoPlayer(configure.customUA_1)) {
        ua = [ua stringByAppendingString: configure.customUA_1];
    }
    if (!isEmptyStringForVideoPlayer(configure.customUA_2)) {
        if(ua.length >0 ) {
            ua = [ua stringByAppendingString: @","];
        }
        ua = [ua stringByAppendingString: configure.customUA_2];
    }
    if (!isEmptyStringForVideoPlayer(configure.customUA_3)) {
        if(ua.length >0 ) {
            ua = [ua stringByAppendingString: @","];
        }
        ua = [ua stringByAppendingString: configure.customUA_3];
    }
    PRELOAD.preloader.configure.customUA = ua;
    
    if (s_string_valid(configure.vendorTestIdStr)) {
        PRELOAD.preloader.configure.vendorTestId = configure.vendorTestIdStr;
    }
    if (s_string_valid(configure.vendorGroupIdStr)) {
        PRELOAD.preloader.configure.vendorGroupId = configure.vendorGroupIdStr;
    }
    /// mdl need
    [AVMDLDataLoader setDnsTTHostString:TTVideoEngineEnvConfig.dnsTTHost];
    [AVMDLDataLoader setDnsGoogleHostString:TTVideoEngineEnvConfig.dnsGoogleHost];
    [AVMDLDataLoader setDnsServerHostString:TTVideoEngineEnvConfig.dnsServerHost];
    [AVMDLDataLoader setTestReachabilityHostString:TTVideoEngineEnvConfig.testReachabilityHost];
#if USE_HLSPROXY
    [[HLSProxySettings sharedInstance] setStrOption:HLSProxySettingsCacheDir value:configure.cachDirectory];
#endif
}


- (void)_configureMdlAlog {
    NSAssert(PRELOAD.isRunning, @"data loader need start");
    [PRELOAD.preloader setAlogWriteCallback:&mdl_alog_write_var];
}

- (void)_vodStrategyConfig {
    if ([TTVideoEngineLocalServerConfigure configure].enableIOManager) {
        TTVideoEngineStrategy.helper.ioManager = [PRELOAD.preloader getIOManagerHandle];
        [TTVideoEngineStrategy.helper start];
    }
}

/// MARK: - _TTVideoEnginePreloadTaskDelegate
- (void)taskFinished:(_TTVideoEnginePreloadTask *)task {
    // Setup resolution map.
    [task.responseData.videoInfo setUpResolutionMap:task.vidItem.resolutionMap];
    //
    TTVideoEngineLog(@"preload task,fetch video-model finish. model: %@,  error: %@",task.responseData,task.responseError);
    //
    if (task.vidItem.fetchDataEnd) {
        task.vidItem.fetchDataEnd(task.responseData, task.responseError);
        task.targetResolution = task.vidItem.resolution;
    }
    
    if (task.vidItem.onlyFetchVideoModel == NO) {
        [self _exectTask:task];
    }
    //
    if (task.responseError) {
        if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(preloaderErrorForVid:errorType:error:)]) {
            [_preloadDelegate preloaderErrorForVid:task.videoId errorType:TTVideoEngineDataLoaderErrorFetchVideoInfo error:task.responseError];
        }
        
        [task notifyPreloadEnd:nil error:task.responseError];
    }
    
    ///  reset property
    task.fetcher = nil;
    task.delegate = nil;
}

- (TTVideoEngineURLInfo *)__selectAutoResolutionIfNeeded:(TTVideoEngineInfoModel *)infoModel {
    TTVideoEngineLog(@"auto res: mdl auto resolution ----------")
    
    if (!infoModel) {
        TTVideoEngineLog(@"auto res: null input info model")
        return nil;
    }
    
    if (![TTVideoEngine ls_localServerConfigure].isEnableAutoResolution) {
        TTVideoEngineLog(@"auto res: ls auto select switcher is not opening")
        return nil;
    }
    
    TTVideoEngineAutoResolutionParams *params = [TTVideoEngine ls_localServerConfigure].autoResolutionParams;
    TTVideoEngineURLInfo *info = [TTVideoEngine _getAutoResolutionInfo:params
                                                             infoModel:infoModel];
    
    if (!info) {
        TTVideoEngineLog(@"auto res: ls empty selected result")
        return nil;
    }
    
    TTVideoEngineLog(@"auto res: ls auto select result: %lu", (unsigned long)[info getVideoDefinitionType])
    return info;
}

- (void)_exectTask:(_TTVideoEnginePreloadTask *)task {
    if (!task) {
        [self performSelector:@selector(_startExecuteTask)];
        return;
    }
    
    /// Remove task from executeTasks.
    [self.executeTasks popTask:task];
    
    if (task.vidItem) {
        task.responseData.videoInfo.params = task.vidItem.params;
    } else if (task.videoModelItem) {
        task.responseData.videoInfo.params = task.videoModelItem.params;
    }
    
    if (task.responseData) {
        NSMutableArray<TTVideoEngineURLInfo *> *infolist = [NSMutableArray array];
        TTVideoEngineResolutionType targetResolution = task.targetResolution;
        
        //auto resolution selected ----
        TTVideoEngineURLInfo *info = [self __selectAutoResolutionIfNeeded:task.responseData.videoInfo];
        if (info) {
            targetResolution = [info getVideoDefinitionType];
        }
        //auto resolution selected ----
        
        TTVideoEngineResolutionType temType = targetResolution;
        
        if([[task.responseData.videoInfo getValueStr:VALUE_DYNAMIC_TYPE] isEqualToString:@"segment_base"]){
            TTVideoEngineURLInfo *audioInfo = [task.responseData.videoInfo videoInfoForType:&temType mediaType:@"audio" autoMode:YES];
            temType = targetResolution;
            TTVideoEngineURLInfo *videoInfo = [task.responseData.videoInfo videoInfoForType:&temType mediaType:@"video" autoMode:YES];
            
            long audioPreloadOffset = 0;
            long videoPreloadOffset = 0;
            
            if (task.preloadMilliSecondOffset > 0 ) {
                
                if (audioInfo.packetOffset != nil && [audioInfo.packetOffset objectForKey:@(task.preloadMilliSecondOffset / 1000.0)]) {
                    audioPreloadOffset = [[audioInfo.packetOffset objectForKey:@(task.preloadMilliSecondOffset / 1000.0)] longValue];
                }
                
                if (videoInfo.packetOffset != nil && [videoInfo.packetOffset objectForKey:@(task.preloadMilliSecondOffset / 1000.0)]) {
                    videoPreloadOffset = [[videoInfo.packetOffset objectForKey:@(task.preloadMilliSecondOffset / 1000.0)] longValue];
                }
                
                if(audioInfo.fitterInfo != nil && audioPreloadOffset == 0) {
                    audioPreloadOffset = [audioInfo.fitterInfo calculateSizeBySecond:task.preloadMilliSecondOffset / 1000.0];
                }
                
                if (videoInfo.fitterInfo != nil && videoPreloadOffset == 0) {
                    videoPreloadOffset = [videoInfo.fitterInfo calculateSizeBySecond:task.preloadMilliSecondOffset / 1000.0];
                }
            }

            long videoPreloadSize = 0;
            long audioPreloadSize = 0;
            long videoPreloadHeaderSize = 0;
            long audioPreloadHeaderSize = 0;
            
            long audioPreloadPresetSize = task.preSize;
            long videoPreloadPresetSize = task.preSize;
            
            if (task.dashAudioPreloadSize >= 0) {
                audioPreloadPresetSize = task.dashAudioPreloadSize;
            }
            
            if (task.dashVideoPreloadSize >= 0) {
                videoPreloadPresetSize = task.dashVideoPreloadSize;
            }
            
            if (task.preloadMilliSecond > 0 || task.preloadMilliSecondOffset > 0) {
                if(audioInfo.fitterInfo != nil) {
                    audioPreloadSize = [audioInfo.fitterInfo calculateSizeBySecond:task.preloadMilliSecond / 1000.0] - audioPreloadOffset;
                    //audio probe size need confirm
                    audioPreloadHeaderSize = audioInfo.fitterInfo.headerSize + (100 * 1024);
                }
                
                if (videoInfo.fitterInfo != nil) {
                    videoPreloadSize = [videoInfo.fitterInfo calculateSizeBySecond:task.preloadMilliSecond / 1000.0] - videoPreloadOffset;
                    //video probe size need confirm
                    videoPreloadHeaderSize = (videoInfo.fitterInfo.headerSize > videoPreloadSize) ?
                    videoInfo.fitterInfo.headerSize : videoPreloadSize;
                }
            }
            
            if (task.preloadMilliSecondOffset > 0) {
                // preload with offset, small audio size may can not start play
                videoPreloadSize = videoPreloadPresetSize;
                
                if ([TTVideoEngineLocalServerConfigure configure].mDashAudioPreloadRatio > 0) {
                    audioPreloadSize = task.preSize * [TTVideoEngineLocalServerConfigure configure].mDashAudioPreloadRatio/100;
                    NSInteger audioPrleoadMinSize = [TTVideoEngineLocalServerConfigure configure].mDashAudioPreloadMinSize;
                    if (audioPrleoadMinSize > 0 && audioPreloadSize < audioPrleoadMinSize) {
                        audioPreloadSize = audioPrleoadMinSize;
                    }
                } else {
                    audioPreloadSize = audioPreloadPresetSize;
                }
            }
            if ((videoPreloadSize <= 0 || audioPreloadSize <=0) && videoInfo != nil && audioInfo != nil &&
                (task.dashAudioPreloadSize == -1 && task.dashVideoPreloadSize == -1)) {
                long videoBitrate = videoInfo.bitrate;
                long audioBitrate = audioInfo.bitrate;
                if (videoBitrate > 0 && audioBitrate > 0) {
                    videoPreloadSize = task.preSize * videoBitrate / (videoBitrate + audioBitrate) + videoPreloadOffset;
                    audioPreloadSize = task.preSize * audioBitrate / (videoBitrate + audioBitrate) + videoPreloadOffset;
                }
            }
            
            if (videoPreloadSize <= 0) {
                videoPreloadSize = videoPreloadPresetSize + videoPreloadOffset;
            }
            
            if (audioPreloadSize <= 0) {
                audioPreloadSize = audioPreloadPresetSize + audioPreloadOffset;
            }
            
            NSString *temFilehash = [audioInfo getValueStr:VALUE_FILE_HASH];
            if(audioInfo != nil && s_string_valid(temFilehash)) {
                [infolist addObject:audioInfo];
                _TTVideoEnginePreloadTrackItem *audioTrack = [task getTrackItem:temFilehash];
                if (!audioTrack) {
                    audioTrack = [task addTrackItemByKey:temFilehash];
                }
                audioTrack.preloadSize = audioPreloadSize;
                audioTrack.preloadOffset = audioPreloadOffset;
                audioTrack.preloadHeaderSize = audioPreloadHeaderSize;
                
                TTVideoEngineLog(@"preload info, dash audio videoId = %@, targetResolution = %@, useResolution = %@",task.videoId,@(targetResolution),@(audioTrack.usingResolution));
                [self _prepareUrlInfo:audioInfo task:task track:audioTrack];
                
                [self _startMDLPreloadTask:task track:audioTrack];
            }
            else {
                [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                                     code:TTVideoEnginePreloadErrCodeParameter
                                                                 userInfo:@{@"info":@"info is null"}]];
            }
            
            temFilehash = [videoInfo getValueStr:VALUE_FILE_HASH];
            if(videoInfo != nil && s_string_valid(temFilehash)) {
                [infolist addObject:videoInfo];
                _TTVideoEnginePreloadTrackItem *videoTrack = [task getTrackItem:temFilehash];
                if (!videoTrack) {
                    videoTrack = [task addTrackItemByKey:temFilehash];
                }
                videoTrack.taskKey = temFilehash;
                videoTrack.preloadSize = videoPreloadSize;
                videoTrack.preloadOffset = videoPreloadOffset;
                videoTrack.preloadHeaderSize = videoPreloadHeaderSize;
                TTVideoEngineLog(@"preload info, dash video videoId = %@, targetResolution = %@, useResolution = %@",task.videoId,@(targetResolution),@(videoTrack.usingResolution));
                [self _prepareUrlInfo:videoInfo task:task track:videoTrack];
                
                [self _startMDLPreloadTask:task track:videoTrack];
            }
            else {
                [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                                     code:TTVideoEnginePreloadErrCodeParameter
                                                                 userInfo:@{@"info":@"info is null"}]];
            }
            
        } else {
            TTVideoEngineURLInfo *info = [task.responseData.videoInfo videoInfoForType:&temType autoMode:YES];
            NSString *temFilehash = [info getValueStr:VALUE_FILE_HASH];
            if (info && s_string_valid(temFilehash)) {
                [infolist addObject:info];
                _TTVideoEnginePreloadTrackItem *track = [task getTrackItem:temFilehash];
                
                long videoPreloadOffset = 0;
                long videoHeaderSize = 0;
                if (task.preloadMilliSecondOffset > 0 && info.fitterInfo != nil) {
                    videoPreloadOffset = [info.fitterInfo calculateSizeBySecond:task.preloadMilliSecondOffset / 1000.0];
                    videoHeaderSize = info.fitterInfo.headerSize;
                }

                long videoPreloadSize = 0;
                if (task.preloadMilliSecond > 0 && info.fitterInfo != nil) {
                    videoPreloadSize = [info.fitterInfo calculateSizeBySecond:task.preloadMilliSecond / 1000.0] - videoPreloadOffset;
                }
                
                if (videoPreloadSize <= 0) {
                    videoPreloadSize = task.preSize + videoPreloadOffset;
                }
                
                if (!track) {
                    track = [task addTrackItemByKey:temFilehash];
                }
                track.preloadSize = videoPreloadSize;
                track.preloadOffset = videoPreloadOffset;
                track.preloadHeaderSize = videoHeaderSize;
                TTVideoEngineLog(@"preload info, not dash videoId = %@, targetResolution = %@, useResolution = %@",task.videoId,@(targetResolution),@(track.usingResolution ));
                [self _prepareUrlInfo:info task:task track:track];
                
                [self _startMDLPreloadTask:task track:track];
            }
            else {
                [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                                     code:TTVideoEnginePreloadErrCodeParameter
                                                                 userInfo:@{@"info":@"info is null"}]];
            }
        }
        
        if (infolist.count == 0) {
            TTVideoEngineLog(@"invalid videoModel");
        } else if (task.vidItem.usingUrlInfo) {
            task.vidItem.usingUrlInfo(infolist);
        } else if (task.videoModelItem.usingUrlInfo) {
            task.videoModelItem.usingUrlInfo(infolist);
        }
    }
    else if (!s_array_is_empty(task.urlItem.urls)) {
        _TTVideoEnginePreloadTrackItem *track = [task.tracks firstObject];
        NSAssert(track != nil, @"track is null");
        track.preloadSize = task.preSize;
        track.usingResolution = task.targetResolution;
        track.urls = task.urlItem.urls;
        track.localFilePath = task.urlItem.cacheFilePath;
        track.customHeader = [self _headerString:task.urlItem.customHeaders];
        track.preloadFooterSize = task.urlItem.preloadFooterSize;
        track.tag = [NSString stringWithFormat:@"%@", task.urlItem.tag ? task.urlItem.tag : @"unknown"];
        if (s_string_valid(task.urlItem.subTag)) {
            track.subtag = [NSString stringWithString:task.urlItem.subTag];
        }
        
        
        [self _startMDLPreloadTask:task track:track];
    }
    else {
        [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                             code:TTVideoEnginePreloadErrCodeParameter
                                                         userInfo:@{@"info":@"info or urls is null"}]];
    }
    
    // exect next task.
    [self performSelector:@selector(_startExecuteTask)];
}

- (void)_startMDLPreloadTask:(_TTVideoEnginePreloadTask *)task track:(nullable _TTVideoEnginePreloadTrackItem *)trackItem {
    NSAssert(task != nil && trackItem != nil, @"task or track is null");
    
    BOOL isHLSProxy = NO;
#if USE_HLSPROXY
    isHLSProxy = [HLSProxyModule isM3u8:trackItem.urls.firstObject] && _playlistLoaderManager != nil;
#endif
    if (trackItem.preloadOffset > 0 && trackItem.preloadOffset < (trackItem.preloadHeaderSize + 100*1024)) {
        // if preload_offset - header_size < 100K, merge together preload [0-preloadoffset + preloadSize]
        trackItem.preloadSize += trackItem.preloadOffset;
        trackItem.preloadOffset = 0;
    }
    
    if (trackItem.preloadOffset > 0) {
        
        AVMDLPreloadTaskSpec *preloadSpec = [[AVMDLPreloadTaskSpec alloc] init];
        preloadSpec.key = trackItem.taskKey;
        preloadSpec.rawKey = task.videoId;
        preloadSpec.preloadOffset = 0;
        preloadSpec.preloadSize = trackItem.preloadHeaderSize;
        preloadSpec.urls = trackItem.urls;
        preloadSpec.filePath = trackItem.localFilePath;
        preloadSpec.priorityLevel  = task.priorityLevel;
        preloadSpec.customHeader = trackItem.customHeader;
        preloadSpec.tag = trackItem.tag;
        preloadSpec.subtag = trackItem.subtag;
        preloadSpec.extrInfo = trackItem.extraInfo;
        
        trackItem.proxyUrl = [self.preloader generateUrlByTaskSpec:preloadSpec];
        
        if (s_string_valid(trackItem.proxyUrl)) {
            [self.preloader startTaskByKey:trackItem.taskKey];
            
        }
        
        AVMDLPreloadTaskSpec *preloadSpec1 = [[AVMDLPreloadTaskSpec alloc] init];
        preloadSpec1.key = trackItem.taskKey;
        preloadSpec1.rawKey = task.videoId;
        preloadSpec1.preloadOffset = trackItem.preloadOffset;
        preloadSpec1.preloadSize = trackItem.preloadSize;
        preloadSpec1.urls = trackItem.urls;
        preloadSpec1.filePath = trackItem.localFilePath;
        preloadSpec1.priorityLevel  = task.priorityLevel;
        preloadSpec1.customHeader = trackItem.customHeader;
        preloadSpec1.tag = trackItem.tag;
        preloadSpec1.subtag = trackItem.subtag;
        preloadSpec1.extrInfo = trackItem.extraInfo;
        
        trackItem.proxyUrl = [self.preloader generateUrlByTaskSpec:preloadSpec1];
    } else {
        
        AVMDLPreloadTaskSpec *preloadSpec = [[AVMDLPreloadTaskSpec alloc] init];
        preloadSpec.key = trackItem.taskKey;
        preloadSpec.rawKey = task.videoId;
        preloadSpec.preloadOffset = 0;
        preloadSpec.preloadSize = trackItem.preloadSize;
        preloadSpec.urls = trackItem.urls;
        preloadSpec.filePath = trackItem.localFilePath;
        preloadSpec.priorityLevel  = task.priorityLevel;
        preloadSpec.customHeader = trackItem.customHeader;
        preloadSpec.tag = trackItem.tag;
        preloadSpec.subtag = trackItem.subtag;
        preloadSpec.extrInfo = trackItem.extraInfo;
        if (!isHLSProxy) {
            trackItem.proxyUrl = [self.preloader generateUrlByTaskSpec:preloadSpec];
        } else {
#if USE_HLSPROXY
            trackItem.proxyUrl = [_playlistLoaderManager startHLSPreloadTask:preloadSpec];
#endif
        }
    }
    
    
    if (s_string_valid(trackItem.proxyUrl)) {
        if (!isHLSProxy) {
            [self.preloader startTaskByKey:trackItem.taskKey];
        }
        [self.allPreloadTasks popTask:task];
        [self.allPreloadTasks enqueueTask:task];
        TTVideoEngineLog(@"[preload] start preload task. allPreloadTasks size: %zd key = %@, rawKey = %@",self.allPreloadTasks.count,trackItem.taskKey, task.videoId);
    }
    else {
        [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                             code:TTVideoEnginePreloadErrCodeParameter
                                                         userInfo:@{@"info":@"proxyUrl is invalid"}]];
    }
}

- (nullable NSString*)generateUrlByTaskSpec:(AVMDLTaskSpec *)taskSpec {
    
    BOOL isHls = NO;
    if ([taskSpec isKindOfClass:[AVMDLPlayTaskSpec class]]) {
        AVMDLPlayTaskSpec* playTask = (AVMDLPlayTaskSpec*)taskSpec;
        isHls = (playTask.fileType == 1);
    }
    if (!isHls) {
        NSArray<NSString*> *urls = taskSpec.urls;
#if USE_HLSPROXY
        isHls = [HLSProxyModule isM3u8:urls.firstObject];
#endif
    }
    NSString *proxyURL = [self.preloader generateUrlByTaskSpec:taskSpec];
    if (proxyURL != nil && isHls && _playlistLoaderManager) {
        proxyURL = [NSString stringWithFormat:@"%@%@",HLSPROXY_HEADER,proxyURL];
    }
    return proxyURL;
}

- (void)_prepareUrlInfo:(TTVideoEngineURLInfo *)urlInfo
                   task:(_TTVideoEnginePreloadTask *)task
                  track:(_TTVideoEnginePreloadTrackItem *)trackItem {
    TTVideoEngineLog(@"preload vidItem, key : %@, usingResolution :%d",trackItem.taskKey, trackItem.usingResolution);
    
    NSArray* urls = [urlInfo allURLForVideoID:nil transformedURL:NO];
    if (urls && urls.count > 0) {
        NSString *temFilehash = [urlInfo getValueStr:VALUE_FILE_HASH];
        NSString *filePath = nil;
        if (s_string_valid(temFilehash)) {
            if (task.vidItem.cacheFilePath) {
                filePath = task.vidItem.cacheFilePath(urlInfo);
            }
            else if (task.videoModelItem.cacheFilePath) {
                filePath = task.videoModelItem.cacheFilePath(urlInfo);
            }
            if (filePath && ![filePath containsString:temFilehash]) {
                NSAssert([filePath containsString:temFilehash],@"filePath invalid");
                filePath = nil;
            }
            if (s_string_valid(filePath)) {
                temFilehash = [TTVideoEngine _ls_keyFromFilePath:filePath];
            }
        }
        
        if (!s_string_valid(temFilehash)) {
            TTVideoEngineLog(@"exect task fail. filehash invalid");
            [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                                 code:TTVideoEnginePreloadErrCodeParameter
                                                             userInfo:@{@"reason":@"key is null"}]];
            return;
        }
        
        trackItem.taskKey = temFilehash; /// update taskKey
        trackItem.urlInfo = urlInfo;
        trackItem.decryptionKey = [urlInfo getValueStr:VALUE_PLAY_AUTH];;
        trackItem.urls = urls;
        trackItem.localFilePath = filePath;
        trackItem.usingResolution = [urlInfo getVideoDefinitionType];
        
        if (task.urlItem) {
            trackItem.tag = [NSString stringWithFormat:@"%@", task.urlItem.tag ? task.urlItem.tag : @"unknown"];
            if (s_string_valid(task.urlItem.subTag)) {
                trackItem.subtag = [NSString stringWithString:task.urlItem.subTag];
            }
        } else if (task.vidItem) {
            trackItem.tag = [NSString stringWithFormat:@"%@", task.vidItem.tag ? task.vidItem.tag : @"unknown"];
            if (s_string_valid(task.vidItem.subTag)) {
                trackItem.subtag = [NSString stringWithString:task.vidItem.subTag];
            }
        } else if (task.videoModelItem) {
            trackItem.tag = [NSString stringWithFormat:@"%@", task.videoModelItem.tag ? task.videoModelItem.tag : @"unknown"];
            if (s_string_valid(task.videoModelItem.subTag)) {
                trackItem.subtag = [NSString stringWithString:task.videoModelItem.subTag];
            }
        }
        
        // for p2p extraInfo
        NSString* fileId = [urlInfo getValueStr:VALUE_FILE_ID];
        if (fileId == nil) {
            fileId = @"";
        }
        NSString* p2pVerify = [urlInfo getValueStr:VALUE_P2P_VERIFYURL];
        if (p2pVerify == nil) {
            p2pVerify = @"";
        }
        NSInteger bitrate = [urlInfo getValueInt:VALUE_BITRATE];
        trackItem.extraInfo = [NSString stringWithFormat:@"fileid=%@&bitrate=%ld&pcrc=%@&tag=%@", fileId, (long)bitrate, p2pVerify, trackItem.tag];
    }
    else {
        [task notifyPreloadEnd:nil error:[NSError errorWithDomain:kTTVideoErrorDomainPreload
                                                             code:TTVideoEnginePreloadErrCodeParameter
                                                         userInfo:@{@"reason":@"urls is null"}]];
    }
}

- (nullable NSString *)_headerString:(NSDictionary *)header {
    if (!header || header.count < 1) {
        return nil;
    }
    
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *key in header.allKeys) {
        NSString *value = @"";
        if ([[header objectForKey:key] isKindOfClass:[NSString class]]) {
            value = [header objectForKey:key];
        }
        [headerString appendString:[NSString stringWithFormat:@"%@: %@\r\n",[key capitalizedString],value]];
    }
    return headerString.copy;
}

/// MARK: - AVMDLDataLoaderProtocol
- (void)didFinishTask:(NSString *)rawKey error:(NSError *)error {
    TTVideoEngineMDLLog(@"local server didFinishTask, key = %@, error = %@",rawKey, error);
    
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerDidFinishTask:error:)]) {
        [_preloadDelegate localServerDidFinishTask:rawKey error:error];
    }
}

- (void)logUpdate:(NSDictionary *)logDict {
    TTVideoEngineMDLLog(@"local server logUpdate:, logInfo = %@",logDict);
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:logDict];
    NSString* logType = [logDict objectForKey:@"log_type"];
    if (logType != nil && [logType isEqualToString:@"heart_beat"] == YES && [logDict objectForKey:@"_play_consumed_data"] == nil) {
        int64_t playConSumed = [TTVideoEngineCollector getPlayConsumeSize];
        [dict addEntriesFromDictionary:@{@"_play_consumed_data" : [NSNumber numberWithLongLong:playConSumed]}];
    }
    
    
    if ([TTVideoEngineEventManager sharedManager].innerDelegate) {
        [[TTVideoEngineEventManager sharedManager] addEvent:dict];
    }
    else {
        id<TTVideoEngineReporterProtocol> reportManager = [[TTVideoEngine reportHelperClass] sharedManager];
        if (reportManager && reportManager.enableAutoReportLog) {
            [reportManager autoReportEventlogIfNeededV1WithParams:dict];
        } else {
            if (logDict && _preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerLogUpdate:)]) {
                [_preloadDelegate localServerLogUpdate:dict];
            }
        }
    }
}

- (void)testSpeedInfo:(long)timeInternalMs size:(long)sizeByte {
     TTVideoEngineMDLLog(@"local server testSpeedInfo:size:, timeInternalMs = %ld, sizeByte = %ld",timeInternalMs, sizeByte);
    
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerTestSpeedInfo:size:)]) {
        [_preloadDelegate localServerTestSpeedInfo:timeInternalMs size:sizeByte];
    }
}

/// cacheSize_$$_originSize_$$_key_$$_localFileUrl

- (void)taskProgress:(NSString *)taskInfo taskType:(NSInteger)taskType flag:(NSInteger)flag {
    TTVideoEngineLog(@"taskInfo: %@ taskType: %zd flag: %zd",taskInfo,taskType,flag);
#if USE_HLSPROXY
    if (_playlistLoaderManager && [_playlistLoaderManager taskProgress:taskInfo taskType:taskType flag:flag]) {
        return;
    }
#endif
    TTVideoEngineLocalServerTaskInfo *info = [self _processTaskInfo:taskInfo isPreload:taskType == 2 flag:flag];
    if (taskType == MDLTaskDownload) {
        return;
    }
    
    if (!info) {
        return;
    }
    
    //
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerTaskProgress:)]) {
        [_preloadDelegate localServerTaskProgress:info];
    }
    
    TTVideoEngineMDLLog(@"local server play task end. key = %@, rawKey = %@",info.key,info.videoId);
}

- (void)taskFailed:(NSString *)key taskType:(NSInteger)taskType error:(NSError *)error {
    TTVideoEngineMDLLog(@"task fail, key:%@, error:%@",key,error);
    
    if (taskType == MDLTaskDownload) {
        [self dataloader:_preloader downloadFail:key error:error];
        return;
    }
#if USE_HLSPROXY
    if (_playlistLoaderManager && [_playlistLoaderManager taskFailed:key taskType:taskType error:error]) {
        return;
    }
#endif
    _TTVideoEnginePreloadTask *task = nil;
    task = [self.allPreloadTasks taskForKey:key];
    if (task) {
        TTVideoEngineLoadProgress *loadProgress = [self.progressObjects popItemForKey:task.videoId];
        if (!loadProgress) {
            loadProgress = [self.progressObjects popItemForKey:key];
        }
        if (!loadProgress) {
            loadProgress = [[TTVideoEngineLoadProgress alloc] init];
        }
        loadProgress.videoId = task.videoId;
        loadProgress.taskType = TTVideoEngineDataLoaderTaskTypePreload;
        [loadProgress setUp:task];
        [loadProgress receiveError:key error:error];
        [task notifyPreloadProgress:loadProgress];
        if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(mediaLoaderLoadProgress:)]) {
            [_preloadDelegate mediaLoaderLoadProgress:loadProgress];
        }
        
        [self.progressObjects enqueueItem:loadProgress];
        
        
        if (loadProgress.cacheEnd || loadProgress.isPreloadComplete) {
            [self.allPreloadTasks popTask:task];
            [self.progressObjects popItem:loadProgress];
            
            [task notifyPreloadEnd:nil error:error];
        }
    }
}

- (void)taskOpened:(NSString *)key taskType:(NSInteger) taskType info:(NSDictionary *)info {
    if (key == nil || info == nil) {
        return;
    }
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(onTaskOpenWithInfo:)]) {
        [_preloadDelegate onTaskOpenWithInfo:info];
    }
#if USE_HLSPROXY
    if (_playlistLoaderManager && [_playlistLoaderManager taskOpened:key taskType:taskType info:info]) {
        return;
    }
#endif
    if (taskType != MDLTaskPreload) {
        return;
    }
    
    TTVideoEngineMDLLog(@"[preload] preload task opened, key:%@, info:%@", key, info);
    
    _TTVideoEnginePreloadTask *task = nil;
    task = [self.allPreloadTasks taskForKey:key];
    if (task) {
        [task notifyPreloadStart:info];
    }
}

/// cacheSize,originSize,key,localFileUrl
- (void)preloadEnd:(NSString *)taskInfo {
#if USE_HLSPROXY
    if (_playlistLoaderManager && [_playlistLoaderManager preloadEnd:taskInfo]) {
        return ;
    }
#endif
    TTVideoEngineLocalServerTaskInfo *info = [self _processTaskInfo:taskInfo isPreload:YES flag:-1];
    if (!info) {
        return;
    }
    
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerTaskProgress:)]) {
        [_preloadDelegate localServerTaskProgress:info];
    }
    
     TTVideoEngineMDLLog(@"local server preload task end. key = %@, rawKey = %@, cacheSize = %zd",info.key,info.videoId,info.cacheSizeFromZero);
}

- (void)preloadTaskCanceled:(NSString *)key {
    TTVideoEngineMDLLog(@"preload task canceled, key:%@",key);
#if USE_HLSPROXY
    if (_playlistLoaderManager && [_playlistLoaderManager preloadTaskCanceled:key]) {
        return ;
    }
#endif
    _TTVideoEnginePreloadTask *task = nil;
    task = [self.allPreloadTasks taskForKey:key];
    if (task) {
        [self.allPreloadTasks popTask:task];
        TTVideoEngineMDLLog(@"mdl callback,preload task canceled, key:%@",key);
        [self _notifyCanceled:task];
    }
}

- (NSString*)getStringBykey:(NSString *)key code:(NSInteger)code type:(NSInteger)type {
    TTVideoEngineMDLLog(@"local server getStringBykey. key = %@, code = %@  type = %@",key,@(code),@(type));
    
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerGetStringBykey:code:type:)]) {
        return [_preloadDelegate localServerGetStringBykey:key code:code type:type];
    }
    return nil;
}
- (NSString*)getCustomHttpHeader:(NSString *)url taskType:(NSInteger)taskType {
    TTVideoEngineMDLLog(@"local server getcustom header url %@",url);
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerGetCustomHttpHeader:)]) {
        
        NSDictionary* header = [_preloadDelegate localServerGetCustomHttpHeader:url];
        if (!header || header.count < 1) {
            return nil;
        }
        
        NSMutableString *headerString = [NSMutableString string];
        for (NSString *key in header.allKeys) {
            NSString *value = @"";
            if ([[header objectForKey:key] isKindOfClass:[NSString class]]) {
                value = [header objectForKey:key];
            }
            [headerString appendString:[NSString stringWithFormat:@"%@: %@\r\n",[key capitalizedString],value]];
        }
        return headerString.copy;
    }
    return nil;
}

- (void)onCDNLog:(NSString *)log {
    TTVideoEngineMDLLog(@"cdn log is:%@",log);
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerCDNLog:)]) {
        NSData *data = [log dataUsingEncoding:NSUTF8StringEncoding];
        if(data == nil || data.length == 0) {
            return;
        }
        NSError *error;
        NSDictionary *logDict = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:&error];
        if (logDict == nil) {
            return;
        }
        [_preloadDelegate localServerCDNLog:logDict];
    }
}

- (void)dataloader:(id)loader downloadProgress:(NSString *)info {
    NSArray *temArrray = [info componentsSeparatedByString:@","];
    if (temArrray.count < 4) {
        return;
    }
    //
    int64_t cacheSize = [[temArrray objectAtIndex:0] longLongValue];
    int64_t mediaSize = [[temArrray objectAtIndex:1] longLongValue];
    NSString *key = [temArrray objectAtIndex:2];
    NSString *localFilePath = [temArrray objectAtIndex:3];
    
    [[TTVideoEngineDownloader shareLoader] progress:key
                                               info:@{@"cacheSize":@(cacheSize),
                                                      @"mediaSize":@(mediaSize),
                                                      @"path":localFilePath?:@""}];
}

- (void)dataloader:(id)loader downloadFail:(NSString *)key error:(NSError *)error {
    [[TTVideoEngineDownloader shareLoader] downloadFail:key error:error];
}

- (void)dataloader:(id)loader downloadSuspend:(NSString *)key {
    [[TTVideoEngineDownloader shareLoader] downloadDidSuspend:key];
}

- (void)testSpeedInfoByTime:(int64_t)timeInternalMs sizeByte:(int64_t)sizeByte type:(NSString *)type key:(NSString *)key extraInfoDic:(nonnull NSDictionary *)extraInfo info:(nonnull NSString *)info {
    [_speedInfoBlockLock lock];
    if (self.speedInfoBlock) {
        self.speedInfoBlock(timeInternalMs, sizeByte, type, key, info, extraInfo);
    }
    [_speedInfoBlockLock unlock];
    if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(localServerTestSpeedInfo:size:)]) {
           [_preloadDelegate localServerTestSpeedInfo:timeInternalMs size:sizeByte];
    }
}

- (void)onMultiNetworkSwitch:(NSString*) targetNetwork currentNetwork:(NSString *)currentNetwork {
    if(_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(onMultiNetworkSwitch:currentNetwork:)]) {
        [_preloadDelegate onMultiNetworkSwitch:targetNetwork currentNetwork:currentNetwork];
    }
}

/// state: 1 start, 2 stop;
/// taskType: 1 play, 2 preload;
- (void)taskStateChange:(NSString *)taskKey taskType:(NSInteger)taskType state:(NSInteger)state {
    if (s_preload_strategy != TTVideoEnginePrelaodNewStrategy) {
        TTVideoEngineLog(@"[preload] strategy is not new");
        return;
    }
}

- (TTVideoEngineLocalServerTaskInfo *)_processTaskInfo:(NSString *)taskInfo
                                             isPreload:(BOOL)isPreload
                                                  flag:(NSInteger)flag {
    NSArray *temArrray = [taskInfo componentsSeparatedByString:@","];
    if (temArrray.count < 4) {
        NSAssert(NO, @"info is invalid");
        return nil;
    }
    //
    int64_t cacheSize = [[temArrray objectAtIndex:0] longLongValue];
    int64_t mediaSize = [[temArrray objectAtIndex:1] longLongValue];
    NSString *key = [temArrray objectAtIndex:2];
    NSString *localFilePath = [temArrray objectAtIndex:3];
    //
    
    _TTVideoEngineTaskQueue *temQueue = nil;
    _TTVideoEnginePreloadTask *task = nil;
    if (isPreload) {
        task = [self.allPreloadTasks taskForKey:key];
        if (!task) {
            return nil;
        }
        temQueue = self.allPreloadTasks;
    }
    else {
        task = [self.allPlayTasks taskForKey:key];
        if (!task) {
            return nil;
        }
        temQueue = self.allPlayTasks;
    }
    
    if (task && mediaSize > 0) {
        _TTVideoEnginePreloadTrackItem *track = [task getTrackItem:key];
        if (track) {
            track.mediaSize = mediaSize;
            track.cacheSize = cacheSize;
            track.localFilePath = localFilePath;
            track.cacheState = flag;
        }
        
        do {
            if (!isPreload || track.preloadFooterSize == 0 || track.isFooterPreloaded) {
                break;
            }
            if (track.mediaSize == track.cacheSize) {
                break;
            }
            
            NSUInteger footerOffset = (track.mediaSize <= track.preloadFooterSize) ? 0 : track.mediaSize - track.preloadFooterSize;
            if (footerOffset < track.cacheSize) {
                footerOffset = track.cacheSize;
            }
            
            track.isFooterPreloaded = YES;
            
            task.preloadOffset = footerOffset;
            task.preSize = track.preloadFooterSize;
            track.preloadOffset = footerOffset;
            track.preloadSize = track.preloadFooterSize;
        
            [self _startMDLPreloadTask:task track: track];
        
            return nil;
        } while (0);
        
        
        ///
        TTVideoEngineLoadProgress *loadProgress = nil;
        loadProgress = [self.progressObjects popItemForKey:task.videoId];
        if (!loadProgress) {
            loadProgress = [self.progressObjects popItemForKey:key];
        }
        if (!loadProgress) {
            loadProgress = [[TTVideoEngineLoadProgress alloc] init];
        }
        loadProgress.videoId = task.videoId;
        loadProgress.taskType = isPreload ? TTVideoEngineDataLoaderTaskTypePreload : TTVideoEngineDataLoaderTaskTypePlay;
        [loadProgress setUp:task];
        [self.progressObjects enqueueItem:loadProgress];
        
        [task notifyPreloadProgress:loadProgress];

        if (_preloadDelegate && [_preloadDelegate respondsToSelector:@selector(mediaLoaderLoadProgress:)]) {
            [_preloadDelegate mediaLoaderLoadProgress:loadProgress];
        }
        ///
        
        if (loadProgress.cacheEnd || loadProgress.preloadComplete) {
            if (isPreload) {
                [self.progressObjects popItem:loadProgress];
            }
            [temQueue popTaskForKey:key];
            
            TTVideoEngineLocalServerTaskInfo *taskProgress = [TTVideoEngineLocalServerTaskInfo new];
            taskProgress.videoId = task.videoId;
            taskProgress.cacheSizeFromZero = cacheSize;
            taskProgress.mediaSize = mediaSize;
            taskProgress.key = key;
            taskProgress.localFilePath = localFilePath;
            taskProgress.resolution = track.usingResolution;
            taskProgress.decryptionKey = track.decryptionKey;
            taskProgress.preloadSize = task.preSize;
            taskProgress.urlInfo = track.urlInfo;
            taskProgress.taskType = loadProgress.taskType;
            
            if (!isPreload) { // notify engine.
                [self _playTaskEndNotify:taskProgress flag:flag];
            }
            
            if ([task isKindOfClass:[_TTVideoEnginePreloadTaskGroup class]]) {
                _TTVideoEnginePreloadTaskGroup *queueTask = (_TTVideoEnginePreloadTaskGroup *)task;
                _TTVideoEnginePreloadTask *next = [queueTask nextPreloadTask];
                if (next) {
                    // do next
                    TTVideoEngineLog(@"[preload] preload next: %@, offset:%lld",key, [next preloadOffset]);
                    [self.preloadTasks enqueueTask:next];
                    [self _startExecuteTask];
                }
            } else {
                [task notifyPreloadEnd:taskProgress error:nil];
            }
            
            return taskProgress;
        }
    }
    //
    return nil;
}

- (void)_playTaskEndNotify:(TTVideoEngineLocalServerTaskInfo *)info flag:(NSInteger)flag {
    NSArray *temObservers = [self.observes itemsForKey:info.key];
    if (temObservers.count > 0) {
        TTVideoRunOnMainQueue(^{
            for (_TTVideoEngineLocalServerObserver *observer in temObservers) {
                CGFloat progress = info.cacheSizeFromZero * 1.0 / (CGFloat)info.mediaSize;
                if ([observer.target respondsToSelector:@selector(updateCacheProgress:flag:observer:progress:)]) {
                    [observer.target updateCacheProgress:info.key flag:flag observer:observer.target progress:progress];
                }
            }
        }, NO);
    }
}

@end


@interface TTVideoEngine()

@end

@implementation TTVideoEngine (Preload)

- (void)ls_setDirectURL:(NSString *)url key:(nonnull NSString *)key {
    [self ls_setDirectURL:url key:key videoId:nil];
}

- (void)ls_setDirectURL:(NSString *)url filePath:(NSString *)filePath {
    if (!s_string_valid(url)) {
        return;
    }
    [self ls_setDirectURLs:@[url] filePath:filePath];
}

- (void)ls_setDirectURL:(NSString *)url key:(NSString *)key videoId:(nullable NSString *)videoId {
    if (!s_string_valid(url)) {
        return;
    }
    
    [self ls_setDirectURLs:@[url] key:key videoId:videoId];
}

- (void)ls_setDirectURLs:(NSArray<NSString *> *)urls key:(NSString *)key {
    [self ls_setDirectURLs:urls key:key videoId:nil];
}

- (void)ls_setDirectURLs:(NSArray<NSString *> *)urls key:(NSString *)key videoId:(nullable NSString *)videoId {
    if (s_array_is_empty(urls)) {
        return;
    }
    //
    if (!s_string_valid(key)) {
        [self setDirectPlayURLs:urls];
    } else if (self.medialoaderEnable && PRELOAD.isRunning) {
        [self.localServerTaskKeys removeAllObjects];
        
        NSString *proxyUrl = [self _ls_proxyUrl:key
                                         rawKey:videoId ?: key
                                           urls:urls
                                      extraInfo:nil
                                       filePath:nil];
        
        TTVideoEngineLog(@"local server, setDirectURL:rawKey:  proxyUrl:%@ \n",proxyUrl);
        //
        [self setDirectPlayURL:proxyUrl cacheFile:nil];
        [(TTVideoEnginePlayUrlSource *)self.playSource setMediaInfo:[TTVideoEnginePlayUrlSource mediaInfo:videoId key:key urls:urls]];
        
        [self _ls_addTask:videoId
                      key:key
               resolution:TTVideoEngineResolutionTypeUnknown
                 proxyUrl:proxyUrl
            decryptionKey:self.decryptionKey
                     info:nil
                     urls:urls];
        //
    } else {
        [self setDirectPlayURLs:urls];
    }
}

- (void)ls_setDirectURLItem:(TTVideoEngineDirectURLItem *)urlItem {
    if (urlItem == nil || s_array_is_empty(urlItem.urls)) {
        return;
    }
    //
    if (!s_string_valid(urlItem.key)) {
        [self setDirectPlayURLs:urlItem.urls];
    } else if (self.medialoaderEnable && PRELOAD.isRunning) {
        [self.localServerTaskKeys removeAllObjects];
        
        NSString *proxyUrl = [self _ls_proxyUrl:urlItem];
        
        TTVideoEngineLog(@"local server, setDirectURL:rawKey:  proxyUrl:%@ \n",proxyUrl);
        //
        [self setDirectPlayURL:proxyUrl cacheFile:nil];
        [(TTVideoEnginePlayUrlSource *)self.playSource setMediaInfo:[TTVideoEnginePlayUrlSource mediaInfo:urlItem.videoId key:urlItem.key urls:urlItem.urls]];
        
        [self _ls_addTask:urlItem.videoId
                      key:urlItem.key
               resolution:TTVideoEngineResolutionTypeUnknown
                 proxyUrl:proxyUrl
            decryptionKey:self.decryptionKey
                     info:nil
                     urls:urlItem.urls];
        //
    } else {
        [self setDirectPlayURLs:urlItem.urls];
    }
}

- (void)ls_setDirectURLs:(NSArray<NSString *> *)urls filePath:(NSString *)filePath {
    if (s_array_is_empty(urls)) {
        return;
    }
    //
    if (!s_string_valid(filePath)) {
        [self setDirectPlayURLs:urls];
    } else if (self.medialoaderEnable && PRELOAD.isRunning) {
        [self.localServerTaskKeys removeAllObjects];
        
        NSString *key = [TTVideoEngine _ls_keyFromFilePath:filePath];
        NSString *proxyUrl = [self _ls_proxyUrl:key
                                         rawKey:key
                                           urls:urls
                                      extraInfo:nil
                                       filePath:filePath];
        
        TTVideoEngineLog(@"local server, setDirectURL:filePath:  proxyUrl:%@ \n",proxyUrl);
        //
        [self setDirectPlayURL:proxyUrl cacheFile:nil];
        [(TTVideoEnginePlayUrlSource *)self.playSource setMediaInfo:[TTVideoEnginePlayUrlSource mediaInfo:key key:key urls:urls]];
        
        [self _ls_addTask:nil
                      key:key
               resolution:TTVideoEngineResolutionTypeUnknown
                 proxyUrl:proxyUrl
            decryptionKey:self.decryptionKey
                     info:nil
                     urls:urls];
        //
    } else {
        [self setDirectPlayURLs:urls];
    }
}

- (void)ls_setDirectURL:(NSString *)url key:(NSString *)key videoId:(nullable NSString *)videoId extraInfo:(nullable NSString *)extraInfo {
    [self ls_setDirectURLs:@[url] key:key videoId:videoId extraInfo:extraInfo];
}
- (void)ls_setDirectURLs:(NSArray<NSString *> *)urls key:(NSString *)key videoId:(nullable NSString *)videoId extraInfo:(nullable NSString *)extraInfo {
    if (s_array_is_empty(urls)) {
        return;
    }
    //
    if (!s_string_valid(key)) {
        [self setDirectPlayURLs:urls];
    } else if (self.medialoaderEnable && PRELOAD.isRunning) {
        [self.localServerTaskKeys removeAllObjects];
        
        NSString *proxyUrl = [self _ls_proxyUrl:key
                                         rawKey:videoId ?: key
                                           urls:urls
                                      extraInfo:extraInfo
                                       filePath:nil];
        
        TTVideoEngineLog(@"local server, setDirectURL:rawKey:  proxyUrl:%@ \n",proxyUrl);
        //
        [self setDirectPlayURL:proxyUrl cacheFile:nil];
        [(TTVideoEnginePlayUrlSource *)self.playSource setMediaInfo:[TTVideoEnginePlayUrlSource mediaInfo:videoId key:key urls:urls]];
        
        [self _ls_addTask:videoId
                      key:key
               resolution:TTVideoEngineResolutionTypeUnknown
                 proxyUrl:proxyUrl
            decryptionKey:self.decryptionKey
                     info:nil
                     urls:urls];
        //
    } else {
        [self setDirectPlayURLs:urls];
    }
}

- (void)ls_setPlayInfo:(NSInteger)key Traceid:(NSString *)traceId Value:(int64_t)value {
    [PRELOAD.preloader setInt64ValueByKey:key StrKey:traceId Value:value];
}

- (void)setSpeedPredictBlock:(nullable TTVideoEngineSpeedInfoBlock)block {
    PRELOAD.speedInfoBlock = block;
}

+ (void)ls_setPreloadDelegate:(id<TTVideoEnginePreloadDelegate>)delegate {
    PRELOAD.preloadDelegate = delegate;
}

//+ (void)ls_setSpeedInfoCallback:(nullable TTVideoEngineSpeedInfoBlock)block {
//    PRELOAD.speedInfoBlock = block;
//}

+ (id<TTVideoEnginePreloadDelegate>)preloadDelegate {
    return PRELOAD.preloadDelegate;
}

+ (TTVideoEngineLocalServerConfigure *)ls_localServerConfigure {
    return [TTVideoEngineLocalServerConfigure configure];
}

+ (void)ls_setMaxConcurrentNumber:(NSInteger)number {
    if (number < 0 || number > 4) {
        number = 4;
    }
    
    PRELOAD.executeTasks.maxCount = number;
}

+ (void)ls_start {
    [PRELOAD start];
}

+ (BOOL)ls_isStarted {
    return PRELOAD.isRunning;
}

+ (void)ls_close {
    [PRELOAD close];
}

+ (void*)ls_getNativeMedialoaderHandle {
    return [PRELOAD getNativeMedialoaderHandle];
}

/// Task Manager

+ (void)ls_addTask:(NSString *)key vidItem:(TTVideoEnginePreloaderVidItem *)vidItem {
    TTVideoRunOnMainQueue(^{
        [PRELOAD addTask:key vidItem:vidItem];
    }, NO);
}

+ (void)ls_addTaskWithVidItem:(TTVideoEnginePreloaderVidItem *)vidItem {
    TTVideoRunOnMainQueue(^{
        NSString *key = [NSString stringWithFormat:@"%@_%@_%@_%@_%@",vidItem.videoId,@(vidItem.resolution),@(vidItem.codecType),@(vidItem.dashEnable),@(vidItem.httpsEnable)];
        [PRELOAD addTask:key vidItem:vidItem];
    }, NO);
}

+ (void)ls_addTask:(TTVideoEngineModel *)infoModel resolution:(TTVideoEngineResolutionType)type preloadSize:(NSInteger)preloadSize {
    TTVideoEnginePreloaderVideoModelItem *videoModeltem = [TTVideoEnginePreloaderVideoModelItem videoModelItem:infoModel
                                                                                                    resolution:type
                                                                                                   preloadSize:preloadSize
                                                                                                        params:nil];
    [self ls_addTaskWithVideoModelItem:videoModeltem];
}

+ (void)ls_addTask:(TTVideoEngineModel *)infoModel resolution:(TTVideoEngineResolutionType)type preloadSize:(NSInteger)preloadSize filePath:(nullable NSString * _Nonnull (^)(TTVideoEngineURLInfo * _Nonnull))filePath {
    TTVideoEnginePreloaderVideoModelItem *videoModeltem = [TTVideoEnginePreloaderVideoModelItem videoModelItem:infoModel
                                                                                                    resolution:type
                                                                                                   preloadSize:preloadSize
                                                                                                        params:nil];
    videoModeltem.cacheFilePath = filePath;
    [self ls_addTaskWithVideoModelItem:videoModeltem];
}

+ (void)ls_addTask:(TTVideoEngineModel *)infoModel resolution:(TTVideoEngineResolutionType)type params:(NSDictionary *)params preloadSize:(NSInteger)preloadSize {
    TTVideoEnginePreloaderVideoModelItem *videoModeltem = [TTVideoEnginePreloaderVideoModelItem videoModelItem:infoModel
                                                                                                    resolution:type
                                                                                                   preloadSize:preloadSize
                                                                                                        params:params];
    [self ls_addTaskWithVideoModelItem:videoModeltem];
}

+ (void)ls_addTaskWithURLItem:(TTVideoEnginePreloaderURLItem *)urlItem {
    TTVideoRunOnMainQueue(^{
        [PRELOAD addTaskWithURLItem:urlItem];
    }, NO);
}

+ (void)ls_addTaskWithVideoModelItem:(TTVideoEnginePreloaderVideoModelItem *)videoModelItem {
    TTVideoRunOnMainQueue(^{
        [PRELOAD addTask:videoModelItem];
    }, NO);
}

+ (void)ls_addTask:(NSString *)key vid:(nullable NSString *)videoId preSize:(NSInteger)preSize url:(nonnull NSString *)url {
    if (!s_string_valid(url)) {
        return;
    }
    
    [self ls_addTask:key vid:videoId preSize:preSize urls:@[url]];
}

+ (void)ls_addTaskForUrl:(NSString *)url vid:(NSString *)videoId preSize:(NSInteger)preSize filePath:(NSString *)filePath {
    if (!s_string_valid(url)) {
        return;
    }
    
    [self ls_addTaskForUrls:@[url] vid:videoId preSize:preSize filePath:filePath];
}

+ (void)ls_addTask:(NSString *)key vid:(NSString *)videoId preSize:(NSInteger)preSize urls:(NSArray<NSString *> *)urls {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePreloaderURLItem *urlItem = [TTVideoEnginePreloaderURLItem urlItemWithKey:key videoId:videoId urls:urls preloadSize:preSize];
        [PRELOAD addTaskWithURLItem:urlItem];
    }, NO);
}

+ (void)ls_addTaskForUrls:(NSArray<NSString *> *)urls vid:(NSString *)videoId preSize:(NSInteger)preSize filePath:(NSString *)filePath {
    TTVideoRunOnMainQueue(^{
        TTVideoEnginePreloaderURLItem *urlItem = [TTVideoEnginePreloaderURLItem urlItemWitFilePath:filePath videoId:videoId urls:urls preloadSize:preSize];
        [PRELOAD addTaskWithURLItem:urlItem];
    }, NO);
}

+ (void)ls_preConnectUrl:(NSString *)url {
    [PRELOAD _preConnectUrl:url];
}

+ (BOOL)switchToDefaultNetwork {
    return [PRELOAD switchToDefaultNetwork];
}

+ (BOOL)switchToCellularNetwork {
    return [PRELOAD switchToCellularNetwork];
}

+ (void)suspendSocketCheck {
    [PRELOAD suspendSocketCheck];
}
+ (void)resumeSocketCheck {
    [PRELOAD resumeSocketCheck];
}


+ (void)ls_copyCache:(TTVideoEngineCopyCacheItem *)copyCacheItem {
    [PRELOAD _copyCache:copyCacheItem];
}

// MARK: -

+ (void)ls_cancelTaskByKey:(NSString *)key {
    [PRELOAD cancelTaskByKey:key];
}

+ (void)ls_cancelTaskByFilePath:(NSString *)filePath {
    NSString *key = [TTVideoEngine _ls_keyFromFilePath:filePath];
    [PRELOAD cancelTaskByKey:key];
}

+ (void)ls_cancelTaskByVideoId:(NSString *)vid {
    [PRELOAD cancelTaskByVideoId:vid];
}

+ (void)ls_cancelAllTasks {
    [PRELOAD cancelAllTasks];
}

+ (void)ls_cancelAllIdlePreloadTasks {
    [PRELOAD cancelAllIdlePreloadTasks];
}

+ (void)ls_clearAllCaches {
    [PRELOAD clearAllCaches];
}

+ (void)ls_removeFileCacheByKey:(NSString *)key {
    [PRELOAD removeFileCacheByKey:key];
}

+ (int64_t)ls_getAllCacheSize {
    return [PRELOAD getAllCacheSize];
}

+ (void)ls_getAllCacheSizeWithCompletion:(void(^)(int64_t cacheSize))block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int64_t size = [PRELOAD getAllCacheSize];
        !block ?: block(size);
    });
}

+ (int64_t)ls_getCacheSizeByKey:(NSString *)key {
    return [PRELOAD getCacheSizeByKey:key];
}

+ (int64_t)ls_tryQuickGetCacheSizeByKey:(NSString *)key {
    return [PRELOAD tryQuickGetCacheSizeByKey:key];
}

+ (void)ls_disableAutoTrimForKey:(NSString *)key {
    [PRELOAD disableAutoTrimForKey:key];
}

+ (NSDictionary*)ls_getCDNLog:(NSString *)key {
    NSString* ret = [PRELOAD.preloader getCDNLog:key];
    if (ret == NULL) {
        return NULL;
    }
    NSData *data = [ret dataUsingEncoding:NSUTF8StringEncoding];
    if(data == nil || data.length == 0) {
        return NULL;
    }
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
}

static NSInteger s_mdl_DNSTTL = 120;
+ (void)ls_DNSTTL:(NSInteger)ttl {
    [AVMDLDataLoader setUpDNSTTL:ttl];
    s_mdl_DNSTTL = ttl;
    TTVideoEngineLog(@"ls_DNSTTL: %zd",ttl);
}

+ (NSInteger)ls_getDNSTTL {
    return s_mdl_DNSTTL;
}

static NSInteger s_mdl_main_dns_parse_type = TTVideoEngineDnsTypeLocal;
static NSInteger s_mdl_backup_dns_parse_type = TTVideoEngineDnsTypeLocal;
+ (void)ls_mainDNSParseType:(TTVideoEngineDnsType)mainType backup:(TTVideoEngineDnsType)backupType {
    static NSDictionary *s_dns_map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_dns_map = @{
            @(TTVideoEngineDnsTypeLocal):@(TTVideoEngineMDLDnsTypeLocal),
            @(TTVideoEngineDnsTypeHttpAli):@(TTVideoEngineMDLDnsTypeTT),
            @(TTVideoEngineDnsTypeHttpTT):@(TTVideoEngineMDLDnsTypeTT),
            @(TTVideoEngineDnsTypeHttpGoogle):@(TTVideoEngineMDLDnsTypeGoogle)
        };
    });
    
    NSInteger temMainType = [s_dns_map[@(mainType)] integerValue], temBackupType = [s_dns_map[@(backupType)] integerValue];
    
    [AVMDLDataLoader setUpFirstDNSParseType:temMainType backup:temBackupType];
    s_mdl_main_dns_parse_type = temMainType;s_mdl_backup_dns_parse_type = temBackupType;
    TTVideoEngineLog(@"ls_mainDNSParseType: %zd backup: %zd",temMainType,temBackupType);
}

+ (TTVideoEngineDnsType)ls_getMainDNSParseType {
    return s_mdl_main_dns_parse_type;
}

+ (TTVideoEngineDnsType)ls_getBackupDNSParseType {
    return s_mdl_backup_dns_parse_type;
}

static NSInteger s_mdl_backup_wait_time = 0.0;
+ (void)ls_backupDNSParserWaitTime:(double)second {
    [AVMDLDataLoader setUpBackupDNSParserWaitTime:second];
    s_mdl_backup_wait_time = second;
    TTVideoEngineLog(@"ls_backupDNSParserWaitTime: %f",second);
}

+ (double)ls_getBackupDNSParserWaitTime {
    return s_mdl_backup_wait_time;
}

static NSInteger s_mdl_dns_parallel = 0;
static NSInteger s_mdl_dns_refresh = 0;
+ (void)ls_setDNSParallel:(NSInteger)parallel{
    [AVMDLDataLoader setUpDNSEnableParallel:parallel];
    s_mdl_dns_parallel = parallel;
    TTVideoEngineLog(@"ls_setDNSParallel: %zd",parallel);
}

+ (NSInteger)ls_getDNSParallel {
    return s_mdl_dns_parallel;
}

+ (void)ls_setDNSRefresh:(NSInteger)refresh{
    [AVMDLDataLoader setUpDNSEnableRefresh:refresh];
    s_mdl_dns_refresh =refresh;
    TTVideoEngineLog(@"ls_setDNSRefresh: %zd",refresh);
}

+ (NSInteger)ls_getDNSRefresh {
    return s_mdl_dns_refresh;
}

+ (void)ls_clearAllDNSCache {
    if ([PRELOAD.preloader respondsToSelector:@selector(clearAllDNSCache)]) {
        [PRELOAD.preloader clearAllDNSCache];
    }
}

+ (void)ls_enableAutoTrimForKey:(NSString *)key {
    [PRELOAD enableAutoTrimForKey:key];
}

+ (int64_t)ls_getCacheSizeByFilePath:(NSString *)filePath {
    return [PRELOAD getCacheSizeByFilePath:filePath];
}

+ (nullable TTVideoEngineLocalServerCacheInfo *)ls_getCacheFileInfoByKey:(NSString *)key {
    NSString *temString = [PRELOAD getCacheInfoByKey:key];
    if (!temString) {
        return nil;
    }
    //
    return [self _processFileInfo:temString];
}

+ (nullable TTVideoEngineLocalServerCacheInfo *)ls_getCacheFileInfoByFilePath:(NSString *)filePath {
    NSString *temString = [PRELOAD getCacheInfoByFilePath:filePath];
    if (!temString) {
        return nil;
    }
    //
    return [self _processFileInfo:temString];
}

+ (void)ls_getCacheSizeByKey:(NSString *)key result:(void(^)(int64_t size))result {
    [PRELOAD getCacheSizeByKey:key result:result];
}

+ (void)ls_getCacheSizeByFilePath:(NSString *)filePath result:(void (^)(int64_t))result {
    [PRELOAD getCacheSizeByFilePath:filePath result:result];
}

+ (int64_t) ls_getCacheFileSize:(TTVideoEngineModel *)infoModel
                     resolution:(TTVideoEngineResolutionType)resolution {
    int64_t cacheSize = 0;
    TTVideoEngineResolutionType temResolution = resolution;
    TTVideoEngineURLInfo *infoAudio = [infoModel.videoInfo videoInfoForType:&temResolution mediaType:@"audio" autoMode:YES];
    if (infoAudio != nil) {
        cacheSize += [TTVideoEngine ls_getCacheSizeByKey:infoAudio.fileHash];
    }
    temResolution = resolution;
    TTVideoEngineURLInfo *infoVideo = [infoModel.videoInfo videoInfoForType:&temResolution mediaType:@"video" autoMode:YES];
    if (infoVideo != nil) {
        cacheSize += [TTVideoEngine ls_getCacheSizeByKey:infoVideo.fileHash];
    }
    return cacheSize;
}

+ (void)ls_getCacheFileSize:(TTVideoEngineModel *)infoModel
                 resolution:(TTVideoEngineResolutionType)resolution
                     result:(void(^)(int64_t size))result {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int64_t size = [self ls_getCacheFileSize:infoModel resolution:resolution];
        if (result) {
            result(size);
        }
    });
}

+ (void)setPreloadStrategy:(TTVideoEnginePrelaodStrategy)preloadStrategy {
    if (s_preload_strategy != preloadStrategy) {
        s_preload_strategy = preloadStrategy;
        
        if ([PRELOAD.preloader respondsToSelector:@selector(setPreloadStrategy:)]) {
            PRELOAD.preloader.preloadStrategy = preloadStrategy;
        }
        TTVideoEngineLog(@"[preload] set preload strategy. %zd",preloadStrategy);
    }
}

+ (TTVideoEnginePrelaodStrategy)preloadStrategy {
    return s_preload_strategy;
}

/// MARK: -

/// MARK: - Private Method
+ (TTVideoEngineLocalServerCacheInfo *)_processFileInfo:(NSString *)fileInfo {
    NSArray *temArrray = [fileInfo componentsSeparatedByString:@","];
    if (temArrray.count < 4) {
        NSAssert(NO, @"info is invalid");
        return nil;
    }
    //
    int64_t cacheSize = [[temArrray objectAtIndex:0] longLongValue];
    int64_t mediaSize = [[temArrray objectAtIndex:1] longLongValue];
    NSString *localFilePath = [temArrray objectAtIndex:3];
    TTVideoEngineLocalServerCacheInfo *info = [[TTVideoEngineLocalServerCacheInfo alloc] init];
    info.mediaSize = mediaSize;
    info.cacheSizeFromZero = cacheSize;
    info.localFilePath = localFilePath;
    return info;
}

- (NSString*)_ls_proxyUrl:(TTVideoEngineDirectURLItem *)urlItem {
    NSAssert(PRELOAD.isRunning, @"data loader need start");
    ///TODO: p2p extraInfo
    ///PRELOAD.preloader.extraInfo = extra;
    
    TTVideoEngineLog(@"medialoader enable:%d, native:%d \n",self.medialoaderEnable, self.medialoaderNativeEnable);
    BOOL useNative = NO;
    if (self.medialoaderNativeEnable) {
        [self _registerMdlProtocolHandle];
        useNative = self.medialoaderProtocolRegistered;
        if (self.options.enableNativeMdlCheckTranscode) {
            useNative = TTVideoEngineIsTranscodeUrls(urlItem.urls);
        }
    }
    
    NSMutableArray<NSString *> *urlsPost = [NSMutableArray arrayWithArray:urlItem.urls];
    BOOL isThirdParty = [self _removeThirdPartyProtocolHead:urlsPost];
    if (isThirdParty) {
        urlItem.urls = urlsPost;
    }
    AVMDLPlayTaskSpec *spec = [[AVMDLPlayTaskSpec alloc] init];
    spec.key = urlItem.key;
    spec.rawKey = urlItem.videoId ?: urlItem.key;
    spec.limitSize = self.limitMediaCacheSize;
    spec.urls = urlItem.urls;
    spec.isNative = useNative;
    spec.urlExpiredTime = urlItem.urlExpiredTime;
    NSString *proxyUrl = [PRELOAD generateUrlByTaskSpec:spec];
    if (isThirdParty) {
        proxyUrl = [self _addThirdPartyProtocolHead:proxyUrl];
    }
    return proxyUrl;
}

- (NSString *)_ls_proxyUrl:(NSString *)key rawKey:(NSString *)rawKey urls:(NSArray<NSString *> *)urls extraInfo:(nullable NSString *)extra filePath:(NSString *)filePath {
    NSAssert(PRELOAD.isRunning, @"data loader need start");
    ///TODO: p2p extraInfo
    ///PRELOAD.preloader.extraInfo = extra;
    
    TTVideoEngineLog(@"medialoader enable:%d, native:%d \n",self.medialoaderEnable, self.medialoaderNativeEnable);
    BOOL useNative = NO;
    if (self.medialoaderNativeEnable) {
        [self _registerMdlProtocolHandle];
        useNative = self.medialoaderProtocolRegistered;
        if (self.options.enableNativeMdlCheckTranscode) {
            useNative = TTVideoEngineIsTranscodeUrls(urls);
        }
    }
    
    NSMutableArray<NSString *> *urlsPost = [NSMutableArray arrayWithArray:urls];
    BOOL isThirdParty = [self _removeThirdPartyProtocolHead:urlsPost];
    if (isThirdParty) {
        urls = urlsPost;
    }
    AVMDLPlayTaskSpec *spec = [[AVMDLPlayTaskSpec alloc] init];
    spec.key = key;
    spec.rawKey = rawKey;
    spec.limitSize = self.limitMediaCacheSize;
    spec.urls = urls;
    spec.filePath = filePath;
    spec.isNative = useNative;
    spec.extrInfo = extra;
    NSString *proxyUrl = [PRELOAD generateUrlByTaskSpec:spec];
    if (isThirdParty) {
        proxyUrl = [self _addThirdPartyProtocolHead:proxyUrl];
    }
    return proxyUrl;
}

- (void)_ls_addTask:(nullable NSString *)videoId
                key:(NSString *)key
         resolution:(TTVideoEngineResolutionType)type
           proxyUrl:(NSString *)proxyUrl
      decryptionKey:(nullable NSString *)decryptionKey
               info:(nonnull TTVideoEngineURLInfo *)info
               urls:(nonnull NSArray *)urls {
    NSParameterAssert(key && key.length > 0);
    //
    _TTVideoEnginePreloadTask *task = nil;
    if (!task) {
        task = [PRELOAD.allPlayTasks popTaskForVideoId:videoId];
    }
    if (!task) {
        task = [PRELOAD.allPlayTasks popTaskForKey:key];
    }
    if (!task) {
       task = [[_TTVideoEnginePreloadTask alloc] init];
    }
    
    task.videoId = videoId;
    _TTVideoEnginePreloadTrackItem *track = [task getTrackItem:key];
    if (!track) {
        track = [task addTrackItemByKey:key];
    }
    track.proxyUrl = proxyUrl;
    track.usingResolution = type;
    track.decryptionKey = decryptionKey;
    track.urlInfo = info;
    track.urls = urls;
    [PRELOAD.allPlayTasks enqueueTask:task];
    
    TTVideoEngineLog(@"put play task, proxyUrl = %@",track.proxyUrl);
    TTVideoEngineLog(@"play media vid: %@,  using resolution: %@",videoId,@(type));
    [self _ls_logProxyUrl:proxyUrl];
    if (key) {
        [self.localServerTaskKeys addObject:key];
    }
    self.playSourceId = videoId ?: key; /// must have a valid value.
    [TTVideoEngine _ls_addObserver:self forKey:key];
}

- (void)_ls_removePlayTaskByKeys:(NSArray *)keys {
    for (NSString *key in keys.copy) {
        [PRELOAD.allPlayTasks popTaskForKey:key];
    }
    
    [PRELOAD.progressObjects popItemForKey:self.playSourceId];
}

+ (NSString *)_ls_getMDLVersion {
    NSString* version = nil;
    version = [PRELOAD.preloader getVersion];
    return [version copy];
}

- (NSString*)_ls_getMDLPlayLog:(NSString *)traceId {
    return [PRELOAD.preloader getPlayLog:traceId];
}

+ (void)_ls_addObserver:(__weak id)observer forKey:(NSString *)key {
    _TTVideoEngineLocalServerObserver *obj = [[_TTVideoEngineLocalServerObserver alloc] init];
    obj.target = observer;
    obj.key = key;
    [PRELOAD addObserver:obj];
}

+ (void)_ls_removeObserver:(__weak id)observer forKeys:(NSArray *)keys {
    for (NSString *key in keys) {
        _TTVideoEngineLocalServerObserver *obj = [[_TTVideoEngineLocalServerObserver alloc] init];
        obj.target = observer;
        obj.key = key;
        [PRELOAD removeObserver:obj];
    }
}

+ (nullable NSString *)_ls_keyFromFilePath:(NSString *)filePath {
    NSString *temKey = [filePath stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""];
    return TTVideoEngineBuildMD5(temKey);
}

+ (void)_ls_forceRemoveFileCacheByKey:(NSString *)key {
    if ([PRELOAD.preloader respondsToSelector:@selector(forceRemoveFileCacheByKey:)]) {
        [PRELOAD.preloader forceRemoveFileCacheByKey:key];
    }
#if USE_HLSPROXY
    [PRELOAD.playlistLoaderManager removeFileCacheByKey:key];
#endif
}

+ (NSInteger)_ls_getPreloadTaskNumber {
    return PRELOAD.preloadTasks.count + PRELOAD.executeTasks.count + PRELOAD.allPreloadTasks.count;
}

- (BOOL) _removeThirdPartyProtocolHead: (NSMutableArray<NSString *> *)urls {
    //
    if (urls == nil || self.ffmpegProtocol == nil ||
        ![self.ffmpegProtocol respondsToSelector:@selector(getProtocolName)]) {
        return NO;
    }
    BOOL ret = NO;
    NSString *protocolName = [self.ffmpegProtocol getProtocolName];
    protocolName = [NSString stringWithFormat:@"%@%@",protocolName,@":"];
    
    for (int i = 0;i < urls.count;i++) {
        NSString *url = urls[i];
        BOOL hasThirdParty = [url hasPrefix:protocolName];
        if (hasThirdParty == NO) {
            return NO;
        }
        ret = YES;
        NSString *nestedUrl = [url substringFromIndex:protocolName.length];
        urls[i] = nestedUrl;
    }
    
    return ret;
}
- (NSString *) _addThirdPartyProtocolHead:(NSString *)url {
    if (url == nil || self.ffmpegProtocol == nil ||
        ![self.ffmpegProtocol respondsToSelector:@selector(getProtocolName)]) {
        return url;
    }
    NSString *protocolName = [self.ffmpegProtocol getProtocolName];
    NSString *ret = [NSString stringWithFormat:@"%@%@%@",protocolName,@":",url];
    return ret;
};

- (nullable NSString *) _ls_getPreloadTraceId:(NSString *)rawKey {
    return [PRELOAD.preloader getPreloadTraceId:rawKey];
}

- (void) _ls_resetPreloadTraceId:(NSString *)rawKey {
    return [PRELOAD.preloader resetPreloadTraceId:rawKey];
}

@end

@implementation TTVideoEngine (Downloader_Private)
+ (nullable NSString *)_ls_downloadUrl:(NSString *)key
                                rawKey:(nullable NSString *)rawKey
                                  urls:(NSArray<NSString *> *)urls {
    return [PRELOAD.preloader downloadUrl:key rawKey:rawKey urls:urls];
}
+ (void)_ls_startDownload:(NSString *)downloadUrl {
    [PRELOAD.preloader startDownload:downloadUrl];
}
+ (void)_ls_cancelDownloadByKey:(NSString *)key {
    [PRELOAD.preloader suspendDownloadByKey:key];
}
@end

@implementation TTVideoEnginePreloaderVidItem

+ (instancetype)preloaderVidItem:(NSString *)vid
                       reslution:(TTVideoEngineResolutionType)resolution
                     preloadSize:(NSInteger)preloaderSize
                       isByteVC1:(BOOL)byteVC1 {
    return [TTVideoEnginePreloaderVidItem preloaderVidItem:vid reslution:resolution preloadSize:preloaderSize codec:byteVC1?TTVideoEngineByteVC1:TTVideoEngineH264];
}

+ (instancetype)preloaderVidItem:(NSString *)vid
                       reslution:(TTVideoEngineResolutionType)resolution
                     preloadSize:(NSInteger)preloaderSize
                           codec:(TTVideoEngineEncodeType)codecType {
    TTVideoEnginePreloaderVidItem *temItem = [TTVideoEnginePreloaderVidItem new];
    temItem.videoId = vid;
    temItem.resolution = resolution;
    temItem.preloadSize = preloaderSize;
    temItem.codecType = codecType;
    temItem.dashEnable = NO;
    temItem.httpsEnable = NO;
    temItem.boeEnable = NO;
    temItem.apiVersion = TTVideoEnginePlayAPIVersion1;
    temItem.resolutionMap = TTVideoEngineDefaultVideoResolutionMap();
    
    return temItem;
}

- (void)setByteVC1Enable:(BOOL)byteVC1Enable {
    if (byteVC1Enable)
        _codecType = TTVideoEngineByteVC1;
    else
        _codecType = _codecType > TTVideoEngineByteVC1 ? _codecType : TTVideoEngineH264;
}

- (BOOL)byteVC1Enable {
    return _codecType == TTVideoEngineByteVC1;
}

@end

@implementation TTVideoEnginePreloaderVideoModelItem

- (instancetype)init {
    if (self = [super init]) {
        _dashAudioPreloadSize = -1;
        _dashVideoPreloadSize = -1;
    }
    return self;
}

+ (instancetype)videoModelItem:(TTVideoEngineModel *)data
                    resolution:(TTVideoEngineResolutionType)resolution
      preloadMilliSecondOffset:(NSInteger)preloadMilliSecondOffset
                   preloadSize:(NSInteger)preloadSize
                        params:(nullable NSDictionary *)params {
    TTVideoEnginePreloaderVideoModelItem *item = [[TTVideoEnginePreloaderVideoModelItem alloc] init];
    item.videoModel = data;
    item.preloadMilliSecondOffset = preloadMilliSecondOffset;
    item.resolution = resolution;
    item.preloadSize = preloadSize;
    item.params = params;
    return item;
}

+ (instancetype)videoModelItem:(TTVideoEngineModel *)data
                    resolution:(TTVideoEngineResolutionType)resolution
                   preloadSize:(NSInteger)preloadSize
                        params:(NSDictionary *)params {
    TTVideoEnginePreloaderVideoModelItem *item = [[TTVideoEnginePreloaderVideoModelItem alloc] init];
    item.videoModel = data;
    item.resolution = resolution;
    item.preloadSize = preloadSize;
    item.params = params;
    return item;
}

@end

@implementation TTVideoEngineDirectURLItem

+ (nullable instancetype)urlItem:(NSString *)key
                            urls:(NSArray<NSString *> *)urls
                  urlExpiredTime:(NSInteger) urlExpiredTime {
    
    if (!s_string_valid(key) || urls.count < 1) {
        return nil;
    }
    
    TTVideoEngineDirectURLItem *urlItem = [[TTVideoEngineDirectURLItem alloc] init];
    urlItem.key = key;
    urlItem.urls = urls;
    urlItem.urlExpiredTime = urlExpiredTime;
    
    return urlItem;
}

@end

@implementation TTVideoEnginePreloaderURLItem

+ (nullable instancetype)urlItem:(NSString *)key
                         videoId:(nullable NSString *)videoId
                     preloadSize:(NSInteger)preloadSize
                            urls:(NSArray<NSString *> *)urls {
    return [self urlItemWithKey:key videoId:videoId urls:urls preloadSize:preloadSize];
}

+ (nullable instancetype)urlItemWithKey:(NSString *)key
                                videoId:(nullable NSString *)videoId
                                   urls:(NSArray<NSString *> *)urls
                            preloadSize:(NSInteger)preloadSize {
    if (!s_string_valid(key) || urls.count < 1) {
        return nil;
    }
    
    TTVideoEnginePreloaderURLItem *urlItem = [[TTVideoEnginePreloaderURLItem alloc] init];
    urlItem.key = key;
    urlItem.videoId = videoId;
    urlItem.urls = urls;
    urlItem.preloadSize = preloadSize;
    urlItem.priorityLevel = TTVideoEnginePrloadPriorityDefault;
    return urlItem;
}

+ (nullable instancetype)urlItemWitFilePath:(NSString *)cacheFilePath
                                    videoId:(nullable NSString *)videoId
                                       urls:(NSArray<NSString *> *)urls
                                preloadSize:(NSInteger)preloadSize {
    if (!s_string_valid(cacheFilePath) || urls.count < 1) {
        return nil;
    }
    
    TTVideoEnginePreloaderURLItem *urlItem = [[TTVideoEnginePreloaderURLItem alloc] init];
    urlItem.key = [TTVideoEngine _ls_keyFromFilePath:cacheFilePath];
    urlItem.cacheFilePath = cacheFilePath;
    urlItem.videoId = videoId;
    urlItem.urls = urls;
    urlItem.preloadSize = preloadSize;
    urlItem.priorityLevel = TTVideoEnginePrloadPriorityDefault;
    return urlItem;
}


- (void)setCustomHeaderValue:(NSString *)value forKey:(NSString *)key {
//    TTVideoEngineLog(@"url preload, set custom header. key: %@", key);
    if (!value || !key) {
        return;
    }
    if (!self.customHeaders) {
        self.customHeaders = [NSMutableDictionary dictionary];
    }
    
    [self.customHeaders setObject:value forKey:key];
}

@end

@implementation TTVideoEngineLocalServerTaskInfo

@end

@implementation TTVideoEngineLocalServerCacheInfo

@end

@implementation TTVideoEngineLocalServerCDNLog

@end

@implementation TTVideoEngineLocalServerConfigure

- (instancetype)init {
    if (self = [super init]) {
        _preloadParallelNum = 2;
        _maxCacheAge = 14*24*60*60;// 14d
        _socketIdleTimeout = 120;// 120s
        _isEnableAuth = 1;
        _heartBeatInterval = 0;
        _writeFileNotifyIntervalMS = 500;
        _maxIPV4Count = INT32_MAX;
        _maxIPV6Count = INT32_MAX;
        _maxTlsVersion = 2;//tlsv2
        _isEnablePreConnect = FALSE;
        _preConnectNum = 3;
        _isEnableSessionReuse = FALSE;
        _sessionTimeout = 3600;//seconds
        _isEnableLoaderPreempt = 0;
        _nextDownloadThreshold = 0;
        _isEnableNetScheduler = FALSE;
        _isNetSchedulerBlockAllNetErr = FALSE;
        _netSchedulerBlockErrCount = 0;
        _netSchedulerBlockDuration = 0;
        _isAllowTryLastUrl = FALSE;
        _isEnableCacheReqRange = FALSE;
        _isEnablePlayLog = 1;
        _isEnableLocalDNSThreadOptimize = NO;
        _connectPoolStragetyValue = 0;
        _maxAliveHostNum = 0;
        _maxSocketReuseCount = 0;
        _isEnableFixCancelPreload = NO;
        _isEnableDNSNoLockNotify = NO;
        _isEnableEarlyData = 0;
        _isEnableByPassCookie = NO;
        _socketRecvBufferSizeByte = 0;
        _isEnableMaxCacheAgeForAllDir = NO;
        _maxFileMemCacheNum = 0;
        _maxFileMemCacheSize = 0;
        _isEnableReqWaitNetReachable = NO;
        _loadMonitorTimeInternal = 0;
        _loadMonitorMinAllowLoadSize = 0;
        _isEnableMultiNetwork = FALSE;
        _loaderType = 0;
        _isEnableUseOriginalUrl = NO;
        _threadStackSizeLevel = 0;
        _isEnableThreadPoolCheckIdle = NO;
        _threadPoolMinCount = 0;
        _threadPoolIdleTTLSecond = 0;
        _isEnableFileMutexOptimize = FALSE;
        _isEnableMDL2 = NO;
        _skipCDNBeforeExpire = 0;
        _ringBufferSize = 0;
#if USE_HLSPROXY
        _isEnableHLSProxy = YES;
#else
        _isEnableHLSProxy = NO;
#endif
    }
    return self;
}

+ (instancetype)configure {
    static TTVideoEngineLocalServerConfigure *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[[self class] alloc] init];
    });
    return s_instance;
}

- (void)setOptions:(NSDictionary<VEMDLKeyType,id> *)options {
    [options.copy enumerateKeysAndObjectsUsingBlock:^(VEMDLKeyType  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]
            || [obj isKindOfClass:[NSString class]]
            || [obj isKindOfClass:[NSDictionary class]]) {
            [self setOptionForKey:key value:obj];
        } else {
            TTVideoEngineLogE(@"setOptions:  value type error ~ ~ ");
        }
    }];
}

/// key is a type of VEKKey or VEKGetKey.
- (void)setOptionForKey:(VEMDLKeyType)key value:(id)value {
    switch (key.integerValue) {
        //
        case VEMDLKeyMaxCacheSize_NSInteger :
            self.maxCacheSize = [value integerValue];
            break;
            /// TCP establishment time.
        case VEMDLKeyOpenTimeOut_NSInteger:
            self.openTimeOut = [value integerValue];
            break;
            /// TCP read write time.
        case VEMDLKeyRWTimeOut_NSInteger:
            self.rwTimeOut = [value integerValue];
            break;
            /// Error occurred, number of retries.
        case VEMDLKeyTryCount_NSInteger:
            self.tryCount = [value integerValue];
            break;
            /// Paralle task number.
        case VEMDLKeyPreloadParallelNum_NSInteger:
            self.preloadParallelNum = [value integerValue];
            break;
            /// is enable oc dns parse.
        case VEMDLKeyEnableExternDNS_BOOL:
            self.enableExternDNS = [value boolValue];
            break;
            /// reuse socket.
        case VEMDLKeyEnableSoccketReuse_BOOL:
            self.enableSoccketReuse = [value boolValue];
            break;
            /// socket idle timeout.
        case VEMDLKeySocketIdleTimeout_NSInteger:
            self.socketIdleTimeout = [value integerValue];
            break;
            /// checksumlevel.
        case VEMDLKeyChecksumLevel_NSInteger:
            self.checksumLevel = [value integerValue];
            break;
            /// The longest time that cached data exists. unit is second.
            /// Default value is 14*24*60*60, 14 day.
        case VEMDLKeyMaxCacheAge_NSInteger:
            self.maxCacheAge = [value integerValue];
            break;
            /// The Cache data folder.
        case VEMDLKeyCachDirectory_NSString:
            self.cachDirectory = value;
            break;
            /// is enable auth play
        case VEMDLKeyIsEnableAuth_NSInteger:
            self.isEnableAuth = [value integerValue];
            break;
            // heart beat interval, 0 is disable, unit: ms
        case VEMDLKeyHeartBeatInterval_NSInteger:
            self.heartBeatInterval = [value integerValue];
            break;
            /// download dir.
        case VEMDLKeyDownloadDirectory_NSString:
            self.downloadDirectory = value;
            break;
        case VEMDLKeyWriteFileNotifyIntervalMS_NSInteger:
            self.writeFileNotifyIntervalMS = [value integerValue];
            break;
        case VEMDLKeyIsEnableLazyBufferPool_BOOL:
            self.isEnableLazyBufferPool = [value boolValue];
            break;
        case VEMDLKeyIsEnablePreConnect_BOOL:
            self.isEnablePreConnect = [value boolValue];
            break;
        case VEMDLKeyPreConnectNum_NSInteger:
            self.preConnectNum = [value integerValue];
            break;
        case VEMDLKeyIsEnableMDLAlog_BOOL:
            self.isEnableMDLAlog = [value boolValue];
            break;
        case VEMDLKeyIsEnableNewBufferpool_BOOL:
            self.isEnableNewBufferpool = [value boolValue];
            break;
        case VEMDLKeyNewBufferpoolBlockSize_NSInteger:
            self.newBufferpoolBlockSize = [value integerValue];
            break;
        case VEMDLKeyNewBufferpoolResidentSize_NSInteger:
            self.newBufferpoolResidentSize = [value integerValue];
            break;
        case VEMDLKeyNewBufferpoolGrowBlockCount_NSInteger:
            self.newBufferpoolGrowBlockCount = [value integerValue];
            break;
        case VEMDLKeyIsEnableSessionReuse_BOOL:
            self.isEnableSessionReuse = [value boolValue];
            break;
        case VEMDLKeySessionTimeout_NSInteger:
            self.sessionTimeout = [value integerValue];
            break;
        case VEMDLKeyMaxTlsVersion_NSInteger:
            self.maxTlsVersion = [value integerValue];
            break;
        case VEMDLKeyIsEnableLoaderPreempt_BOOL:
            self.isEnableLoaderPreempt = [value boolValue];
            break;
        case VEMDLKeyNextDownloadThreshold_NSInteger:
            self.nextDownloadThreshold = [value integerValue];
            break;
        case VEMDLKeyMaxIPV4Count_NSInteger:
            self.maxIPV4Count = [value integerValue];
            break;
        case VEMDLKeyMaxIPV6Count_NSInteger:
            self.maxIPV6Count = [value integerValue];
            break;
        case VEMDLKeyIsEnablePlayLog_BOOL:
            self.isEnablePlayLog = [value boolValue];
            break;
        case VEMDLKeyIsEnableFileExtendBuffer_BOOL:
            self.isEnableFileExtendBuffer = [value boolValue];
            break;
        case VEMDLKeyFileExtendSizeKB_NSInteger:
            self.fileExtendSizeKB = [value integerValue];
            break;
        case VEMDLKeyIsEnableDNSNoLockNotify_BOOL:
            self.isEnableDNSNoLockNotify = [value boolValue];
            break;
        case VEMDLKeyIsEnableNetScheduler_BOOL:
            self.isEnableNetScheduler = [value boolValue];
            break;
        case VEMDLKeyIsEnableFixCancelPreload_BOOL:
            self.isEnableFixCancelPreload = [value boolValue];
            break;
        case VEMDLKeyIsNetSchedulerBlockAllNetErr_BOOL:
            self.isNetSchedulerBlockAllNetErr = [value boolValue];
            break;
        case VEMDLKeyNetSchedulerBlockErrCount_NSInteger:
            self.netSchedulerBlockErrCount = [value integerValue];
            break;
        case VEMDLKeyNetSchedulerBlockDuration_NSInteger:
            self.netSchedulerBlockDuration = [value integerValue];
            break;
        case VEMDLKeyIsAllowTryLastUrl_BOOL:
            self.isAllowTryLastUrl = [value boolValue];
            break;
        case VEMDLKeyIsEnableLocalDNSThreadOptimize_BOOL:
            self.isEnableLocalDNSThreadOptimize = [value boolValue];
            break;
        case VEMDLKeyIsEnableCacheReqRange_BOOL:
            self.isEnableCacheReqRange = [value boolValue];
            break;
        case VEMDLKeyConnectPoolStragetyValue_NSInteger:
            self.connectPoolStragetyValue = [value integerValue];
            break;
        case VEMDLKeyMaxAliveHostNum_NSInteger:
            self.maxAliveHostNum = [value integerValue];
            break;
        case VEMDLKeyMaxSocketReuseCount_NSInteger:
            self.maxSocketReuseCount = [value integerValue];
            break;
        case VEMDLKeyIsEnableEarlyData_NSInteger:
            self.isEnableEarlyData = [value integerValue];
            break;
        case VEMDLKeyIsCacheDirMaxCacheSize_NSDictionary:
            if ([value isKindOfClass:[NSDictionary class]]) {
                self.cacheDirMaxCacheSize = value;
            }
            break;
        case VEMDLKeyIsEnableByPassCookie_BOOL:
            self.isEnableByPassCookie = [value boolValue];
            break;
        case VEMDLKeyIsNetSchedulerBlockHostErrIpCount_NSInteger:
            self.netSchedulerBlockHostErrIpCount = [value integerValue];
            break;
        case VEMDLKeyIsSocketTrainingCenterConfig_NSString:
            self.socketTrainingCenterConfigStr = value;
            break;
        case VEMDLKeyIsEnableIOManager_BOOL:
            self.enableIOManager = [value boolValue];
            break;
        case VEMDLKeyIsEnableMaxCacheAgeForAllDir_BOOL:
            self.isEnableMaxCacheAgeForAllDir = [value boolValue];
            break;
        case VEMDLKeyIsFileMemCacheMaxSize_NSInteger:
            self.maxFileMemCacheSize = [value integerValue];
            break;
        case VEMDLKeyIsFileMemCacheMaxNum_NSInteger:
            self.maxFileMemCacheNum = [value integerValue];
            break;
        case VEMDLKeyIsEnableReqWaitNetReachable_BOOL:
            self.isEnableReqWaitNetReachable = [value boolValue];
            break;
        case VEMDLKeyIsLoadMonitorTimeInternal_NSInteger:
            self.loadMonitorTimeInternal = [value integerValue];
            break;
        case VEMDLKeyIsLoadMonitorMinAllowLoadSize_NSInteger:
            self.loadMonitorMinAllowLoadSize = [value integerValue];
            break;
        case VEMDLKeyIsNetSchedulerConfigStr_NSString:
            self.netSchedulerConfigStr = value;
            break;
        case VEMDLKeyIsEnableMultiNetwork_BOOL:
            self.isEnableMultiNetwork = [value boolValue];
            break;
        case VEMDLKeyIsDynamicPreconnectConfigStr_NSString:
            self.dynamicPreconnectConfigStr = value;
            break;
        case VEMDLKeyIsEnableUseOriginalUrl_BOOL:
            self.isEnableUseOriginalUrl = [value boolValue];
            break;
        case VEMDLKeyIsEnableLoaderLogExtractUrls_BOOL:
            self.isEnableLoaderLogExtractUrls = [value boolValue];
            break;
        case VEMDLKeyIsMaxLoaderLogNum_NSInteger:
            self.maxLoaderLogNum = [value integerValue];
            break;
        case VEMDLKeyIsThreadStackSizeLevel:
            self.threadStackSizeLevel = [value integerValue];
            break;
        case VEMDLKeyIsEnableUnlimitHttpHeader_BOOL:
            self.isEnableUnlimitHttpHeader = [value boolValue];
            break;
        case VEMDLKeyIsThreadPoolMinCount:
            self.threadPoolMinCount = [value integerValue];
            break;
        case VEMDLKeyIsEnableThreadPoolCheckIdle:
            self.isEnableThreadPoolCheckIdle = [value boolValue];
            break;
        case VEMDLKeyIsThreadPoolIdleTTLSecond:
            self.threadPoolIdleTTLSecond = [value integerValue];
            break;
        case VEMDLKeyIsLoaderType_NSInteger:
            self.loaderType = [value integerValue];
            break;
        case VEMDLKeyIsExtensionOpts_NSString:
            if ([value isKindOfClass:[NSDictionary class]] && [NSJSONSerialization isValidJSONObject:value]) {
                NSError *error = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];
                if (jsonData && !error) {
                    self.mdlExtensionOpts = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }
            }
            break;
        case VEMDLKeyIsDashAudioPreloadRatio_NSInteger:
            self.mDashAudioPreloadRatio = [value integerValue];
            break;
        case VEMDLKeyIsDashAudioPreloadMinSize_NSInteger:
            self.mDashAudioPreloadMinSize = [value integerValue];
            break;
        case VEMDLKeyIsTemporaryOptStr_NSString:
            self.temporaryOptStr = value;
            break;
        case VEMDLKeyIsCustomUA_1_NSString:
            self.customUA_1 = value;
            break;
        case VEMDLKeyIsCustomUA_2_NSString:
            self.customUA_2 = value;
            break;
        case VEMDLKeyIsCustomUA_3_NSString:
            self.customUA_3 = value;
            break;
        case VEMDLKeyIsVendorTestId_NSString:
            self.vendorTestIdStr = value;
            break;
        case VEMDLKeyIsEnableMDL2_BOOL:
            self.isEnableMDL2 = [value boolValue];
            break;    
        case VEMDLKeyIsVendorGroupId_NSString:
            self.vendorGroupIdStr = value;
            break;
        case VEMDLKeyIsEnableFileMutexOptimize_BOOL:
            self.isEnableFileMutexOptimize = [value boolValue];
            break;
        case VEMDLKeyIsSkipCDNBeforeExpire_NSInteger:
            self.skipCDNBeforeExpire = [value boolValue];
            break;
        case VEMDLKeyIsRingBufferSize_NSInteger:
            self.ringBufferSize = [value integerValue];
            break;
        case VEMDLKeyIsFileRingBufferOpts_NSString:
            self.fileRingBufferOptStr = value;
            break;
        case VEMDLKeyIsIgnoreTextSpeedTest_BOOL:
            self.isIgnoreTextSpeedTest = [value boolValue];
            break;
        case VEKKeyHLSProxyProtocolEnable_BOOL:
            self.isEnableHLSProxy = [value boolValue];
            break;
        default:
            break;
    }
}


- (id)getOptionBykey:(VEKKeyType)key {
    id temValue = [NSNull null];
    switch (key.integerValue) {
        //
        case VEMDLKeyMaxCacheSize_NSInteger :
            temValue = @(self.maxCacheSize);
            break;
            /// TCP establishment time.
        case VEMDLKeyOpenTimeOut_NSInteger:
            temValue = @(self.openTimeOut);
            break;
            /// TCP read write time.
        case VEMDLKeyRWTimeOut_NSInteger:
            temValue = @(self.rwTimeOut);
            break;
            /// Error occurred, number of retries.
        case VEMDLKeyTryCount_NSInteger:
            temValue =  @(self.tryCount);
            break;
            /// Paralle task number.
        case VEMDLKeyPreloadParallelNum_NSInteger:
            temValue = @(self.preloadParallelNum);
            break;
            /// is enable oc dns parse.
        case VEMDLKeyEnableExternDNS_BOOL:
            temValue = @(self.enableExternDNS);
            break;
            /// reuse socket.
        case VEMDLKeyEnableSoccketReuse_BOOL:
            temValue = @(self.enableSoccketReuse);
            break;
            /// socket idle timeout.
        case VEMDLKeySocketIdleTimeout_NSInteger:
            temValue = @(self.socketIdleTimeout);
            break;
            /// checksumlevel.
        case VEMDLKeyChecksumLevel_NSInteger:
            temValue = @(self.checksumLevel);
            break;
            /// The longest time that cached data exists. unit is second.
            /// Default value is 14*24*60*60, 14 day.
        case VEMDLKeyMaxCacheAge_NSInteger:
            temValue = @(self.maxCacheAge);
            break;
            /// The Cache data folder.
        case VEMDLKeyCachDirectory_NSString:
            temValue = self.cachDirectory;
            break;
            /// is enable auth play
        case VEMDLKeyIsEnableAuth_NSInteger:
            temValue = @(self.isEnableAuth);
            break;
            // heart beat interval, 0 is disable, unit: ms
        case VEMDLKeyHeartBeatInterval_NSInteger:
            temValue = @(self.heartBeatInterval);
            break;
            /// download dir.
        case VEMDLKeyDownloadDirectory_NSString:
            temValue =  self.downloadDirectory;
            break;
        case VEMDLKeyWriteFileNotifyIntervalMS_NSInteger:
            temValue = @(self.writeFileNotifyIntervalMS);
            break;
        case VEMDLKeyIsEnableLazyBufferPool_BOOL:
            temValue = @(self.isEnableLazyBufferPool);
            break;
        case VEMDLKeyIsEnablePreConnect_BOOL:
            temValue = @(self.isEnablePreConnect);
            break;
        case VEMDLKeyPreConnectNum_NSInteger:
            temValue = @(self.preConnectNum);
            break;
        case VEMDLKeyIsEnableMDLAlog_BOOL:
            temValue = @(self.isEnableMDLAlog);
            break;
        case VEMDLKeyIsEnableNewBufferpool_BOOL:
            temValue = @(self.isEnableNewBufferpool);
            break;
        case VEMDLKeyNewBufferpoolBlockSize_NSInteger:
            temValue = @(self.newBufferpoolBlockSize);
            break;
        case VEMDLKeyNewBufferpoolResidentSize_NSInteger:
            temValue = @(self.newBufferpoolResidentSize);
            break;
        case VEMDLKeyNewBufferpoolGrowBlockCount_NSInteger:
            temValue = @(self.newBufferpoolGrowBlockCount);
            break;
        case VEMDLKeyIsEnableSessionReuse_BOOL:
            temValue = @(self.isEnableSessionReuse);
            break;
        case VEMDLKeySessionTimeout_NSInteger:
            temValue = @(self.sessionTimeout);
            break;
        case VEMDLKeyMaxTlsVersion_NSInteger:
            temValue = @(self.maxTlsVersion);
            break;
        case VEMDLKeyIsEnableLoaderPreempt_BOOL:
            temValue = @(self.isEnableLoaderPreempt);
            break;
        case VEMDLKeyNextDownloadThreshold_NSInteger:
            temValue = @(self.nextDownloadThreshold);
            break;
        case VEMDLKeyMaxIPV4Count_NSInteger:
            temValue = @(self.maxIPV4Count);
            break;
        case VEMDLKeyMaxIPV6Count_NSInteger:
            temValue = @(self.maxIPV6Count);
            break;
        case VEMDLKeyIsEnablePlayLog_BOOL:
            temValue = @(self.isEnablePlayLog);
            break;
        case VEMDLKeyIsEnableFileExtendBuffer_BOOL:
            temValue = @(self.isEnableFileExtendBuffer);
            break;
        case VEMDLKeyFileExtendSizeKB_NSInteger:
            temValue = @(self.fileExtendSizeKB);
            break;
        case VEMDLKeyIsEnableDNSNoLockNotify_BOOL:
            temValue = @(self.isEnableDNSNoLockNotify);
            break;
        case VEMDLKeyIsEnableFixCancelPreload_BOOL:
            temValue = @(self.isEnableFixCancelPreload);
            break;
        case VEMDLKeyIsEnableNetScheduler_BOOL:
            temValue = @(self.isEnableNetScheduler);
            break;
        case VEMDLKeyIsNetSchedulerBlockAllNetErr_BOOL:
            temValue = @(self.isNetSchedulerBlockAllNetErr);
            break;
        case VEMDLKeyNetSchedulerBlockErrCount_NSInteger:
            temValue = @(self.netSchedulerBlockErrCount);
            break;
        case VEMDLKeyNetSchedulerBlockDuration_NSInteger:
            temValue = @(self.netSchedulerBlockDuration);
            break;
        case VEMDLKeyIsAllowTryLastUrl_BOOL:
            temValue = @(self.isAllowTryLastUrl);
            break;
        case VEMDLKeyIsEnableLocalDNSThreadOptimize_BOOL:
            temValue = @(self.isEnableLocalDNSThreadOptimize);
            break;
        case VEMDLKeyIsEnableCacheReqRange_BOOL:
            temValue = @(self.isEnableCacheReqRange);
            break;
        case VEMDLKeyConnectPoolStragetyValue_NSInteger:
            temValue = @(self.connectPoolStragetyValue);
            break;
        case VEMDLKeyMaxAliveHostNum_NSInteger:
            temValue = @(self.maxAliveHostNum);
            break;
        case VEMDLKeyMaxSocketReuseCount_NSInteger:
            temValue = @(self.maxSocketReuseCount);
            break;
        case VEMDLKeyIsEnableEarlyData_NSInteger:
            temValue = @(self.isEnableEarlyData);
            break;
        case VEMDLKeyIsCacheDirMaxCacheSize_NSDictionary:
            temValue = self.cacheDirMaxCacheSize;
            break;
        case VEMDLKeyIsEnableByPassCookie_BOOL:
            temValue = @(self.isEnableByPassCookie);
            break;
        case VEMDLKeyIsNetSchedulerBlockHostErrIpCount_NSInteger:
            temValue = @(self.netSchedulerBlockHostErrIpCount);
            break;
        case VEMDLKeyIsSocketTrainingCenterConfig_NSString:
            temValue = self.socketTrainingCenterConfigStr;
            break;
        case VEMDLKeyIsEnableIOManager_BOOL:
            temValue = @(self.enableIOManager);
            break;
        case VEMDLKeyIsEnableMaxCacheAgeForAllDir_BOOL:
            temValue = @(self.isEnableMaxCacheAgeForAllDir);
            break;
        case VEMDLKeyIsFileMemCacheMaxSize_NSInteger:
            temValue = @(self.maxFileMemCacheSize);
            break;
        case VEMDLKeyIsFileMemCacheMaxNum_NSInteger:
            temValue = @(self.maxFileMemCacheNum);
            break;
        case VEMDLKeyIsEnableReqWaitNetReachable_BOOL:
            temValue = @(self.isEnableReqWaitNetReachable);
            break;
        case VEMDLKeyIsLoadMonitorTimeInternal_NSInteger:
            temValue = @(self.loadMonitorTimeInternal);
            break;
        case VEMDLKeyIsLoadMonitorMinAllowLoadSize_NSInteger:
            temValue = @(self.loadMonitorMinAllowLoadSize);
            break;
        case VEMDLKeyIsNetSchedulerConfigStr_NSString:
            temValue = self.netSchedulerConfigStr;
            break;
        case VEMDLKeyIsEnableMultiNetwork_BOOL:
            temValue = @(self.isEnableMultiNetwork);
            break;
        case VEMDLKeyIsDynamicPreconnectConfigStr_NSString:
            temValue = self.dynamicPreconnectConfigStr;
            break;
        case VEMDLKeyIsEnableUseOriginalUrl_BOOL:
            temValue = @(self.isEnableUseOriginalUrl);
            break;
        case VEMDLKeyIsEnableLoaderLogExtractUrls_BOOL:
            temValue = @(self.isEnableLoaderLogExtractUrls);
            break;
        case VEMDLKeyIsMaxLoaderLogNum_NSInteger:
            temValue = @(self.maxLoaderLogNum);
            break;
        case VEMDLKeyIsThreadStackSizeLevel:
            temValue = @(self.threadStackSizeLevel);
            break;
        case VEMDLKeyIsThreadPoolMinCount:
            temValue = @(self.threadPoolMinCount);
            break;
        case VEMDLKeyIsEnableThreadPoolCheckIdle:
            temValue = @(self.isEnableThreadPoolCheckIdle);
            break;
        case VEMDLKeyIsThreadPoolIdleTTLSecond:
            temValue = @(self.threadPoolIdleTTLSecond);
            break;
        case VEMDLKeyIsEnableUnlimitHttpHeader_BOOL:
            temValue = @(self.isEnableUnlimitHttpHeader);
            break;  
        case VEMDLKeyIsDashAudioPreloadRatio_NSInteger:
            temValue = @(self.mDashAudioPreloadRatio);
            break;
        case VEMDLKeyIsDashAudioPreloadMinSize_NSInteger:
            temValue = @(self.mDashAudioPreloadMinSize);
            break;
        case VEMDLKeyIsTemporaryOptStr_NSString:
            temValue = self.temporaryOptStr;
            break;
        case VEMDLKeyIsCustomUA_1_NSString:
            temValue = self.customUA_1;
            break;
        case VEMDLKeyIsCustomUA_2_NSString:
            temValue = self.customUA_2;
            break;
        case VEMDLKeyIsCustomUA_3_NSString:
            temValue = self.customUA_3;
            break;
        case VEMDLKeyIsVendorTestId_NSString:
            temValue = self.vendorTestIdStr;
            break;
        case VEMDLKeyIsEnableMDL2_BOOL:
            temValue = @(self.isEnableMDL2);
            break;
        case VEMDLKeyIsVendorGroupId_NSString:
            temValue = self.vendorGroupIdStr;
            break;
        case VEMDLKeyIsEnableFileMutexOptimize_BOOL:
            temValue = @(self.isEnableFileMutexOptimize);
            break;
        case VEMDLKeyIsSkipCDNBeforeExpire_NSInteger:
            temValue = @(self.skipCDNBeforeExpire);
            break;
        case VEMDLKeyIsRingBufferSize_NSInteger:
            temValue = @(self.ringBufferSize);
            break;
        case VEMDLKeyIsFileRingBufferOpts_NSString:
            temValue = self.fileRingBufferOptStr;
            break;
        case VEMDLKeyIsIgnoreTextSpeedTest_BOOL:
            temValue = @(self.isIgnoreTextSpeedTest);
            break;
        case VEKKeyHLSProxyProtocolEnable_BOOL:
            temValue = @(self.isEnableHLSProxy);
            break;
        default:
            break;
    }
    
    return temValue;
}


- (void)setPreloadParallelNum:(NSInteger)preloadParallelNum {
    if (_preloadParallelNum == preloadParallelNum) {
        return;
    }
    
    _preloadParallelNum = preloadParallelNum;
    if (_preloadParallelNum > 0 && [PRELOAD isRunning]) {
        [PRELOAD.preloader setPreloadParallelNum:_preloadParallelNum];
    }
}

- (void)setNetSchedulerConfigStr:(NSString *)netSchedulerConfigStr {
    if (![netSchedulerConfigStr isKindOfClass:[NSString class]]
        || [netSchedulerConfigStr isEqualToString:_netSchedulerConfigStr]) {
        return;
    }
    
    _netSchedulerConfigStr = netSchedulerConfigStr;
    if ([_netSchedulerConfigStr isKindOfClass:[NSString class]]
        && [_netSchedulerConfigStr length] > 0
        && [PRELOAD isRunning]) {
        [PRELOAD.preloader setNetSchedulerConfigStr:_netSchedulerConfigStr];
    }
}

- (void)setSocketTrainingCenterConfigStr:(NSString *)socketTrainingCenterConfigStr {
    if (![socketTrainingCenterConfigStr isKindOfClass:[NSString class]]
        || [socketTrainingCenterConfigStr isEqualToString:_socketTrainingCenterConfigStr]) {
        return;
    }
    
    _socketTrainingCenterConfigStr = socketTrainingCenterConfigStr;
    if ([_socketTrainingCenterConfigStr isKindOfClass:[NSString class]]
        && [_socketTrainingCenterConfigStr length] > 0
        && [PRELOAD isRunning]) {
        [PRELOAD.preloader setSocketTrainingCenterConfigStr:_socketTrainingCenterConfigStr];
    }
}

@end

@implementation TTVideoEngineLoadProgress (Private)

- (void)setUp:(_TTVideoEnginePreloadTask *)task {
    self.videoId = task.videoId;
    NSMutableArray *temArray = [NSMutableArray array];
    NSArray *tracks = task.tracks.copy;
    for (_TTVideoEnginePreloadTrackItem *track in tracks) {
        TTVideoEngineLoadCacheInfo *cacheInfo = [self getCahceInfo:track.taskKey];
        if (!cacheInfo) {
            cacheInfo = [[TTVideoEngineLoadCacheInfo alloc] init];
        }
        cacheInfo.cacheKey = track.taskKey;
        cacheInfo.mediaSize = track.mediaSize;
        cacheInfo.preloadHeaderSize = track.preloadHeaderSize;
        cacheInfo.preloadOffset = track.preloadOffset;
        cacheInfo.preloadSize = track.preloadSize;
        cacheInfo.resolution = track.usingResolution;
        cacheInfo.localFilePath = track.localFilePath;
        cacheInfo.cacheState = track.cacheState;
        [cacheInfo setCacheSize:track.cacheSize];
        [temArray addObject:cacheInfo];
    }
    self.cacheInfos = temArray;
}

@end


/// _TTVideoEnginePreloadTask.
/// Task Queue
@interface _TTVideoEngineTaskQueue () {
    pthread_mutex_t _lock;
    NSMutableArray *_taskArray;
}

@end
@implementation _TTVideoEngineTaskQueue

- (void)dealloc{
    [_taskArray removeAllObjects];
    _taskArray = nil;
    pthread_mutex_destroy(&_lock);
}

- (NSInteger)count{
    pthread_mutex_lock(&_lock);
    NSInteger count = _taskArray.count;
    pthread_mutex_unlock(&_lock);
    return count;
}

- (instancetype)init{
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _taskArray = [NSMutableArray array];
    }
    return self;
}


- (nullable _TTVideoEnginePreloadTask *)backTask {
    pthread_mutex_lock(&_lock);
    if (_taskArray.count == 0) {
         pthread_mutex_unlock(&_lock);
        return nil;
    }
    _TTVideoEnginePreloadTask *task = [_taskArray lastObject];
    pthread_mutex_unlock(&_lock);
    return task;
}

- (nullable _TTVideoEnginePreloadTask *)popBackTask {
    pthread_mutex_lock(&_lock);
    if (_taskArray.count == 0) {
        pthread_mutex_unlock(&_lock);
        return nil;
    }
    _TTVideoEnginePreloadTask *task = [_taskArray lastObject];
    [_taskArray removeObject:task];
    pthread_mutex_unlock(&_lock);
    return task;
}

- (nullable _TTVideoEnginePreloadTask *)taskForKey:(NSString *)key {
    if (!s_string_valid(key)) {
        return nil;
    }
    
    __block _TTVideoEnginePreloadTask *task = nil;
    pthread_mutex_lock(&_lock);
    [_taskArray enumerateObjectsUsingBlock:^(_TTVideoEnginePreloadTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *tracks = obj.tracks.copy;
        if (tracks.count > 0) {
            for (_TTVideoEnginePreloadTrackItem *item in tracks) {
                if ([item.taskKey isEqualToString:key]) {
                    task = obj;
                    *stop = YES;
                }
            }
        }
    }];
    pthread_mutex_unlock(&_lock);
    return task;
}

- (nullable _TTVideoEnginePreloadTask *)taskForVideoId:(NSString *)videoId {
    if (!s_string_valid(videoId)) {
        return nil;
    }
    
    __block _TTVideoEnginePreloadTask *task = nil;
    pthread_mutex_lock(&_lock);
    [_taskArray enumerateObjectsUsingBlock:^(_TTVideoEnginePreloadTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (s_string_valid(obj.videoId) && [obj.videoId isEqualToString:videoId]) {
            task = obj;
            *stop = YES;
        }
    }];
    pthread_mutex_unlock(&_lock);
    return task;
}

- (nullable _TTVideoEnginePreloadTask *)popTaskForVideoId:(NSString *)videoId {
    if (!s_string_valid(videoId)) {
        return nil;
    }
    
    __block _TTVideoEnginePreloadTask *task = nil;
    pthread_mutex_lock(&_lock);
    [_taskArray enumerateObjectsUsingBlock:^(_TTVideoEnginePreloadTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (s_string_valid(obj.videoId) && [obj.videoId isEqualToString:videoId]) {
            task = obj;
            *stop = YES;
        }
    }];
    if (task) {
        [_taskArray removeObject:task];
    }
    pthread_mutex_unlock(&_lock);
    return task;
}

- (nullable _TTVideoEnginePreloadTask *)popTaskForKey:(NSString *)key {
    if (!s_string_valid(key)) {
        return nil;
    }
    
    __block _TTVideoEnginePreloadTask *task = nil;
    pthread_mutex_lock(&_lock);
    [_taskArray enumerateObjectsUsingBlock:^(_TTVideoEnginePreloadTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *tracks = obj.tracks.copy;
        if (tracks.count > 0) {
            for (_TTVideoEnginePreloadTrackItem *item in tracks) {
                if ([item.taskKey isEqualToString:key]) {
                    task = obj;
                    *stop = YES;
                }
            }
        }
    }];
    if (task) {
        [_taskArray removeObject:task];
    }
    pthread_mutex_unlock(&_lock);
    return task;
}

- (BOOL)enqueueTask:(_TTVideoEnginePreloadTask *)task {
    if (task == nil) {
        return NO;
    }
    
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    if ([self _enoughTasks]) {
        result = NO;
    } else {
        [_taskArray addObject:task];
        result = YES;
    }
    pthread_mutex_unlock(&_lock);
    return result;
}

- (BOOL)containTask:(_TTVideoEnginePreloadTask *)task {
    NSParameterAssert(task != nil);
    if (task == nil) {
        return NO;
    }
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    result = [_taskArray containsObject:task];
    pthread_mutex_unlock(&_lock);
    return result;
}

- (BOOL)containTaskForKey:(NSString *)key {
    NSParameterAssert(s_string_valid(key));
    if (key == nil || key.length == 0) {
        return NO;
    }
    
    return !!([self taskForKey:key]);
}

- (void)popAllTasks {
    pthread_mutex_lock(&_lock);
    [_taskArray removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (void)popTask:(_TTVideoEnginePreloadTask *)task {
    NSParameterAssert(task != nil);
    if (task == nil) {
        return;
    }
    //
    pthread_mutex_lock(&_lock);
    [_taskArray removeObject:task];
    pthread_mutex_unlock(&_lock);
}

- (BOOL)_enoughTasks {
    if (_maxCount >= 1) {
        return _taskArray.count >= _maxCount;
    }else{
        return NO;
    }
}



@end

@implementation TTVideoEngine (MediaLoaderExperiment)

+ (void)setMDLNetUnReachableStopRetry:(BOOL) stopRetry {
    [AVMDLDataLoader setNetUnReachableStopRetry:stopRetry];
}

- (NSString*)ls_proxyUrl:(NSString *)key rawKey:(NSString *)rawKey urls:(NSArray<NSString *> *)urls extraInfo:(nullable NSString *)extra filePath:(nullable NSString *)filePath {
    return [self _ls_proxyUrl:key rawKey:rawKey urls:urls extraInfo:extra filePath:filePath];
}

@end

@implementation TTVideoEngineCopyCacheItem

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock {
    if (self = [super init]) {
        self.fileKey = key;
        self.destPath = path;
        self.waitIfCaching = NO;
        self.forceCopy = NO;
        self.completionBlock = completionBlock;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
              waitIfCaching:(BOOL)waitIfCaching
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock {
    if (self = [super init]) {
        self.fileKey = key;
        self.destPath = path;
        self.waitIfCaching = waitIfCaching;
        self.forceCopy = NO;
        self.completionBlock = completionBlock;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
               forceCopy:(BOOL)forceCopy
                infoBlock:(void(^)(NSDictionary<NSString*, id>* info))infoBlock
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock {
    if (self = [super init]) {
        self.fileKey = key;
        self.destPath = path;
        self.waitIfCaching = NO;
        self.forceCopy = forceCopy;
        self.infoBlock = infoBlock;
        self.completionBlock = completionBlock;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
              waitIfCaching:(BOOL)waitIfCaching
               forceCopy:(BOOL)forceCopy
                infoBlock:(void(^)(NSDictionary<NSString*, id>* info))infoBlock
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock {
    if (self = [super init]) {
        self.fileKey = key;
        self.destPath = path;
        self.waitIfCaching = waitIfCaching;
        self.forceCopy = forceCopy;
        if (forceCopy) {
            self.waitIfCaching = NO;
        }
        self.infoBlock = infoBlock;
        self.completionBlock = completionBlock;
    }
    return self;
}

@end





