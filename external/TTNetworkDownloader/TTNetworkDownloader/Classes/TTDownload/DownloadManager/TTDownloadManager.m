
#import "TTDownloadApi.h"
#import "TTDownloadCommonTools.h"
#import "TTDownloadLogLite.h"
#import "TTDownloadManager.h"
#import "TTDownloadSliceTaskConfig.h"
#import "TTDownloadStorageCenter.h"
#import "TTDownloadTask.h"
#import "TTDownloadTracker.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ResultBlock)(DownloadResultNotification *resultNotification);
typedef void (^ProgressBlock)(DownloadProgressInfo *progress);

static const int16_t kConcurrentTaskCountMax = 50;

NSString *const kTTDownloaderRestoreResultNotification = @"kTTDownloaderRestoreResultNotification";
NSString *const kTTDownloaderRestoreResultNotificationParamKey = @"resultNotification";
static const int8_t kTTDownloadLoadDBRetryTimes = 3;

@implementation DownloadProgressInfo
@end

@implementation DownloadResultNotification

- (id)copyWithZone:(NSZone *)zone {
    DownloadResultNotification *obj = [[DownloadResultNotification alloc] init];
    obj.urlKey = self.urlKey;
    obj.secondUrl = self.secondUrl;
    obj.code = self.code;
    obj.downloadedFilePath = self.downloadedFilePath;
    obj.trackModel = [self.trackModel copy];
    obj.httpResponseArray = [self.httpResponseArray mutableCopy];
    obj.downloaderLog = self.downloaderLog;
    return obj;
}

- (void)addLog:(NSString *)log {
    [_downloaderLog stringByAppendingFormat:@",{%@}", log];
}

@end

@implementation DownloadInfo
@end

@implementation DownloadGlobalParameters

+ (void)load {
    DLLOGD(@"dlLog++++++++call load in DownloadGlobalParameters+++++++++++++");
}

- (id)init {
    self = [super init];
    if (self) {
        self.urlRetryTimes                 = 0;
        self.retryTimeoutInterval          = 0;
        self.retryTimeoutIntervalIncrement = 0;
        self.isSliced                      = NO;
        self.sliceMaxNumber                = 0;
        self.minDevisionSize               = 0;
        self.mergeDataLength               = 0;
        self.sliceMaxRetryTimes            = 0;
        self.contentLengthWaitMaxInterval  = 0;
        self.throttleNetSpeed              = 0;
        self.isDownloadWifiOnly            = NO;
        self.restoreTimesAutomatic         = 0;
        self.isHttps2HttpFallback          = NO;
        self.isUseTracker                  = NO;
        self.isBackgroundDownloadEnable    = NO;
        self.isSkipGetContentLength        = YES;
        self.isServerSupportRangeDefault   = NO;
        self.startOffset                  = -1L;
        self.endOffset                    = -1L;
        self.queuePriority                 = QUEUE_PRIORITY_LOW;
        self.insertType                    = QUEUE_TAIL;
        self.isBackgroundDownloadWifiOnlyDisable = NO;
        self.disableBackgroundDownloadIOSVersionList = [[NSMutableArray alloc] init];
        self.backgroundDownloadDisableWifiOnlyVersionList = [[NSMutableArray alloc] init];
    }
    return self;
}



- (id)copyWithZone:(NSZone * _Nullable)zone {
    DownloadGlobalParameters *param = [[[self class] allocWithZone:zone] init];
    param.urlRetryTimes = _urlRetryTimes;
    param.retryTimeoutInterval = _retryTimeoutInterval;
    param.retryTimeoutIntervalIncrement = _retryTimeoutIntervalIncrement;
    param.isSliced = _isSliced;
    param.sliceMaxNumber = _sliceMaxNumber;
    param.minDevisionSize = _minDevisionSize;
    param.mergeDataLength = _mergeDataLength;
    param.sliceMaxRetryTimes = _sliceMaxRetryTimes;
    param.contentLengthWaitMaxInterval = _contentLengthWaitMaxInterval;
    param.throttleNetSpeed = _throttleNetSpeed;
    param.isHttps2HttpFallback = _isHttps2HttpFallback;
    param.isDownloadWifiOnly = _isDownloadWifiOnly;
    param.restoreTimesAutomatic = _restoreTimesAutomatic;
    param.isUseTracker = _isUseTracker;
    param.isBackgroundDownloadEnable = _isBackgroundDownloadEnable;
    param.disableBackgroundDownloadIOSVersionList = [_disableBackgroundDownloadIOSVersionList mutableCopy];
    param.isBackgroundDownloadWifiOnlyDisable = _isBackgroundDownloadWifiOnlyDisable;
    param.backgroundDownloadDisableWifiOnlyVersionList = [_backgroundDownloadDisableWifiOnlyVersionList mutableCopy];
    param.httpHeaders = [NSMutableDictionary dictionaryWithDictionary:_httpHeaders];
    param.isSkipGetContentLength = _isSkipGetContentLength;
    param.isServerSupportRangeDefault = _isServerSupportRangeDefault;
    param.observationBufferLength = _observationBufferLength;
    param.checkObservationBufferLength = _checkObservationBufferLength;
    param.measureSpeedTimes = _measureSpeedTimes;
    param.startThrottleBandWidthMin = _startThrottleBandWidthMin;
    param.rttGap = _rttGap;
    param.speedGap = _speedGap;
    param.matchConditionPercent = _matchConditionPercent;
    param.dynamicBalanceDivisionThreshold = _dynamicBalanceDivisionThreshold;
    param.bandwidthDeltaCoefficient = _bandwidthDeltaCoefficient;
    param.bandwidthDeltaConstant = _bandwidthDeltaConstant;
    param.isCheckCacheValid = _isCheckCacheValid;
    param.isRetainCacheIfCheckFailed = _isRetainCacheIfCheckFailed;
    param.isUrgentModeEnable = _isUrgentModeEnable;
    param.isClearCacheIfNoMaxAge = _isClearCacheIfNoMaxAge;
    param.expectFileLength = _expectFileLength;
    param.preCheckFileLength = _preCheckFileLength;
    param.isTTNetUrgentModeEnable = _isTTNetUrgentModeEnable;
    param.ttnetRequestTimeout = _ttnetRequestTimeout;
    param.ttnetReadDataTimeout = _ttnetReadDataTimeout;
    param.ttnetRcvHeaderTimeout = _ttnetRcvHeaderTimeout;
    param.ttnetProtectTimeout = _ttnetProtectTimeout;
    param.cacheLifeTimeMax = _cacheLifeTimeMax;
    param.componentId = _componentId;
    param.isRestartImmediatelyWhenNetworkChange = _isRestartImmediatelyWhenNetworkChange;
    param.isStopIfNoNet = _isStopIfNoNet;
    param.startOffset = _startOffset;
    param.endOffset = _endOffset;
    param.isIgnoreMaxAgeCheck = _isIgnoreMaxAgeCheck;
    param.backgroundBOEDomain = _backgroundBOEDomain;
    param.isClearDownloadedTaskCacheAuto = _isClearDownloadedTaskCacheAuto;
    param.userCachePath = _userCachePath;
    param.isCommonParamEnable = _isCommonParamEnable;
    param.TTMd5Callback = _TTMd5Callback;
    return param;
}

+(BOOL)propertyIsOptional:(NSString *)propertyName{
    return YES;
}

@end

@interface TTDownloadManager()

@property (atomic, strong) DownloadGlobalParameters *downloadGlobalParameter;

@property (atomic, assign) int16_t downloadingTaskMax;

@property (atomic, strong) NSMutableDictionary<NSString *, TTDownloadTaskConfig *> *downloadTaskConfigDic;

@property (atomic, strong) NSMutableDictionary<NSString *, TTDownloadTask *> *downloadingTaskDic;

@property (atomic, strong) NSMutableDictionary<NSString *, NSString *> *bgIdentifierDic;

@property (atomic, strong) NSMutableDictionary<NSString *, NSString *> *checkCancelTaskDic;

@property (atomic, strong) NSLock *checkCancelTaskDicLock;

@property (atomic, strong) NSLock *bgIdentifierDicLock;

@property (atomic, strong) NSLock *downloadTaskConfigDicLock;

@property (atomic, strong) NSLock *downloadingTaskDicLock;

@property (atomic, strong) NSLock *loadConfigFromStorageLock;

@property (nonatomic, strong) TTDownloadStorageCenter *downloadStorageCenter;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (atomic, assign) NetworkStatus previousNetStatus;

@property (atomic, assign) BOOL isTryRestoreTaskWhenRestart;

@property (nonatomic, strong) TTDownloadTncConfigManager *tncConfigManager;

@property (atomic, assign) BOOL isClearAllCache;
@property (atomic, assign) BOOL isClearNoExpireTimeCache;
@property (atomic, assign, readwrite) BOOL isAppBackground;

@property (nonatomic, assign, readwrite)int8_t loadDataFromDBRetryTimes;
@end

@implementation TTDownloadManager
@synthesize downloadStorageCenter = _downloadStorageCenter;

- (TTDownloadStorageCenter *)downloadStorageCenter {
    if (!_downloadStorageCenter) {
        _downloadStorageCenter = [[TTDownloadStorageCenter alloc] initWithDownloadStorageImplType:TTDownloadStorageImplTypeSqlite];
    }
    return _downloadStorageCenter;
}

- (void)setDownloadStorageCenter:(TTDownloadStorageCenter *)value {
    _downloadStorageCenter = value;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.downloadingTaskMax                = kConcurrentTaskCountMax;
        self.downloadTaskConfigDic             = [NSMutableDictionary dictionary];
        self.downloadingTaskDic                = [NSMutableDictionary dictionary];
        self.bgIdentifierDic                   = [NSMutableDictionary dictionary];
        self.checkCancelTaskDic                = [NSMutableDictionary dictionary];
        self.isHadLoadConfigFromStorage        = NO;
        self.downloadTaskConfigDicLock         = [[NSLock alloc] init];
        self.downloadingTaskDicLock            = [[NSLock alloc] init];
        self.loadConfigFromStorageLock         = [[NSLock alloc] init];
        self.bgIdentifierDicLock               = [[NSLock alloc] init];
        self.checkCancelTaskDicLock            = [[NSLock alloc] init];
        self.cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        self.appSupportPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
        self.urgentModeTempRootDir = [self.cachePath stringByAppendingPathComponent:kUrgentModeTempDir];
        self.fileManager                       = [NSFileManager defaultManager];
        self.downloadStorageCenter             = nil;
        self.downloadGlobalParameter           = nil;
        self.previousNetStatus                 = NotReachable;
        self.isTryRestoreTaskWhenRestart       = NO;
        self.tncConfigManager                  = [[TTDownloadTncConfigManager alloc] init];
        self.loadDataFromDBRetryTimes          = kTTDownloadLoadDBRetryTimes;

        NSError *error = nil;
        [[TTDownloadManager class] createDir:self.appSupportPath error:&error];
        if (error) {
            DLLOGE(@"error=%@", error.description);
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appReachabilityChanged:)
                                                     name:TTReachabilityChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidFinishLaunchingNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TTReachabilityChangedNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)applicationEnterBackground {
    DLLOGD(@"bgTask:Timing:enter Background");
    self.isAppBackground = YES;
}

- (void)applicationDidBecomeActive {
    DLLOGD(@"enter Foreground");
    self.isAppBackground = NO;
}

- (TTDownloadTncConfigManager *)getTncConfig {
    return self.tncConfigManager;
}

- (BOOL)checkInvalidValue:(DownloadGlobalParameters *)globalParameters {
    if (!globalParameters) {
        return YES;
    }
    if (globalParameters.urlRetryTimes < 0 || globalParameters.urlRetryTimes > 10) {
        DLLOGD(@"dlLog:error:globalParameters.urlRetryTimes=%ld", (long)globalParameters.urlRetryTimes);
        return NO;
    }
    //max = 100 s
    if (globalParameters.retryTimeoutInterval < 0 || globalParameters.retryTimeoutInterval > 100) {
        DLLOGD(@"dlLog:error:globalParameters.retryTimeoutInterval=%ld", (long)globalParameters.retryTimeoutInterval);
        return NO;
    }
    if (globalParameters.retryTimeoutIntervalIncrement < 0 || globalParameters.retryTimeoutIntervalIncrement > 100) {
        DLLOGD(@"dlLog:error:retryTimeoutIntervalIncrement=%ld", (long)globalParameters.retryTimeoutIntervalIncrement);
        return NO;
    }
    if (globalParameters.sliceMaxNumber < 0 || globalParameters.sliceMaxNumber > 4) {
        DLLOGD(@"dlLog:error:sliceMaxNumber=%ld", (long)globalParameters.sliceMaxNumber);
        return NO;
    }
    if (globalParameters.minDevisionSize < 0) {
        DLLOGD(@"dlLog:error:minDevisionSize=%ld", (long)globalParameters.minDevisionSize);
        return NO;
    }
    //max 50M
    if (globalParameters.mergeDataLength < 0 || globalParameters.mergeDataLength > 50) {
        DLLOGD(@"dlLog:error:mergeDataLength=%ld", (long)globalParameters.mergeDataLength);
        return NO;
    }
    //max 10
    if (globalParameters.sliceMaxRetryTimes < 0 || globalParameters.sliceMaxRetryTimes > 10) {
        DLLOGD(@"dlLog:error:sliceMaxRetryTimes=%ld", (long)globalParameters.sliceMaxRetryTimes);
        return NO;
    }
    //max 60s
    if (globalParameters.contentLengthWaitMaxInterval < 0 || globalParameters.contentLengthWaitMaxInterval > 60) {
        DLLOGD(@"dlLog:error:contentLengthWaitMaxInterval=%ld", (long)globalParameters.contentLengthWaitMaxInterval);
        return NO;
    }
    if (globalParameters.restoreTimesAutomatic < 0 || globalParameters.restoreTimesAutomatic > 100) {
        DLLOGD(@"dlLog:error:restoreTimesAutomatic=%ld", (long)globalParameters.restoreTimesAutomatic);
        return NO;
    }
    return true;
}

- (BOOL)getIsForceCacheLifeTimeMaxEnable {
    int8_t value = _tncConfigManager.tncIsForceCacheLifeTimeMaxEnable;
    if (value >= 0) {
        return value > 0 ? YES : NO;
    }
    return self.isForceCacheLifeTimeMaxEnable;
}

- (bool)setGlobalDownloadParameters:(DownloadGlobalParameters *)globalParameters {
    if (nil == globalParameters) {
        return NO;
    }
    if (![self checkInvalidValue:globalParameters]) {
        return NO;
    }
    self.downloadGlobalParameter = [globalParameters copy];
    return YES;
}

- (DownloadGlobalParameters *)getGlobalDownloadParameters {
    return self.downloadGlobalParameter;
}

- (int)startDownloadWithURL:(NSString *)urlKey
                   isUseKey:(BOOL)isUseKey
                   fileName:(NSString *)fileName
                   md5Value:(NSString *)md5Value
                   urlLists:(NSArray *)urlLists
                   progress:(TTDownloadProgressBlock)progress
                     status:(TTDownloadResultBlock)status
             userParameters:(DownloadGlobalParameters *)userParameters {
    return [self startDownloadCommon:urlKey
                            fileName:fileName
                            md5Value:md5Value
                            urlLists:urlLists
                            isResume:NO
                            isUseKey:isUseKey
                    progressCallBack:progress
          resultNotificationCallBack:status
                      userParameters:userParameters];
}

- (int)resumeDownloadWithURL:(NSString *)urlKey
                    isUseKey:(BOOL)isUseKey
                    urlLists:(NSArray *)urlLists
                    progress:(TTDownloadProgressBlock)progress
                      status:(TTDownloadResultBlock)status
              userParameters:(DownloadGlobalParameters *)userParameters {
    return [self startDownloadCommon:urlKey
                            fileName:nil
                            md5Value:nil
                            urlLists:urlLists
                            isResume:YES
                            isUseKey:isUseKey
                    progressCallBack:progress
          resultNotificationCallBack:status
                      userParameters:userParameters];
}

- (void)queryDownloadInfoWithURL:(NSString *)url
               downloadInfoBlock:(TTDownloadInfoBlock)downloadInfoBlock
                          status:(DownloadStatus)status {
    if (url == nil || downloadInfoBlock == nil) {
        DLLOGD(@"Query Params Error url:%@ downloadInfoBlock:%@", url, downloadInfoBlock);
        return;
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self runQueryDownloadInfo:[NSArray arrayWithObjects:url, downloadInfoBlock, nil]
                            status:status];
    });
}

- (bool)setThrottleNetSpeedWithURL:(NSString *)url bytesPerSecond:(int64_t)bytesPerSecond {
    if (nil == url) {
        return NO;
    }

    TTDownloadTask *ttDownloadingTask = [[TTDownloadManager shareInstance] findDownloadingTaskInDicLock:url];
    if (ttDownloadingTask) {
        [ttDownloadingTask setThrottleSpeed:bytesPerSecond];
    } else {
        return NO;
    }
    return YES;
}

- (void)cancelDownloadWithURL:(NSString *)url block:(TTDownloadResultBlock)block {
    if (url == nil) {
        DLLOGD(@"Cancel Params Error url:%@", url);
        return;
    }
    [[TTDownloadManager shareInstance] deleteCheckCancelTaskDicLock:url];
    TTDownloadTask *ttDownloadingTask = [[TTDownloadManager shareInstance] findDownloadingTaskInDicLock:url];
    if (ttDownloadingTask) {
        if (block) {
            [ttDownloadingTask setBlock:block];
        }

        [ttDownloadingTask cancelTask];
    } else {
        if (block) {
            DownloadResultNotification *result = [[DownloadResultNotification alloc] init];
            result.urlKey = url;
            result.code   = ERROR_CANCEL_SUCCESS;
            block(result);
        }
    }
}

- (void)deleteDownloadWithURL:(NSString *)url
                  resultBlock:(TTDownloadResultBlock)resultBlock {
    if (url == nil || resultBlock == nil) {
        DLLOGD(@"Delete Params Error url:%@ resultBlock:%@", url, resultBlock);
        return;
    }
    [[TTDownloadManager shareInstance] deleteCheckCancelTaskDicLock:url];
    TTDownloadTask *ttDownloadingTask = [[TTDownloadManager shareInstance] findDownloadingTaskInDicLock:url];
    
    if (ttDownloadingTask) {
        [ttDownloadingTask deleteTask:resultBlock];
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self runDeleteDownloadFile:[NSArray arrayWithObjects:url, resultBlock, nil]];
        });
    }
}

- (void)asyncStatusReport:(NSString *)url
           secondUrl:(NSString *)secondUrl
              status:(StatusCode)status
         resultBlock:(TTDownloadResultBlock)resultNotificationCallBack
          taskConfig:(TTDownloadTaskConfig *)taskConfig {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        DownloadResultNotification *resultNotification = [[DownloadResultNotification alloc] init];
        resultNotification.urlKey    = url;
        resultNotification.secondUrl = secondUrl;
        resultNotification.code      = status;

        if (ERROR_FILE_DOWNLOADED == status) {
            NSString *fileStorePath = [[self.appSupportPath stringByAppendingPathComponent:taskConfig.fileStorageDir] stringByAppendingPathComponent:taskConfig.fileStorageName];
            resultNotification.downloadedFilePath = fileStorePath;
            
            if (![[self fileManager] fileExistsAtPath:fileStorePath]) {
                NSString *fileStorePath2 = [[self.cachePath stringByAppendingPathComponent:taskConfig.fileStorageDir] stringByAppendingPathComponent:taskConfig.fileStorageName];
                if ([[self fileManager] fileExistsAtPath:fileStorePath2]) {
                    [[TTDownloadManager class] moveItemAtPath:fileStorePath2 toPath:fileStorePath overwrite:YES error:nil];
                    [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:fileStorePath];
                } else {
                    resultNotification.code = ERROR_DOWNLOADED_FILE_MISS;
                    resultNotification.downloadedFilePath = nil;
                }
            }
            [self deleteDownloadFile:taskConfig isDeleteDB:NO isDeleteMergeFile:NO isDeleteSliceFile:YES];
        }
        [[TTDownloadManager shareInstance] deleteCheckCancelTaskDicLock:url];
        
        DownloadResultNotification *copyNotification = [resultNotification copy];
        
        resultNotificationCallBack(resultNotification);
        [TTDownloadManager shareInstance].onCompletionHandler(copyNotification);
    });
}

- (BOOL)getIsWifiOnlyEnable:(DownloadGlobalParameters *)param {
    int8_t isWifiOnly = [[TTDownloadManager shareInstance] getTncConfig].tncIsDownloadWifiOnly;
    
    if (isWifiOnly >= 0) {
        return isWifiOnly > 0 ? YES : NO;
    }
    return param ? param.isDownloadWifiOnly : NO;
}

- (void)setWifiOnlyWithUrlKey:(NSString *)urlKey isWifiOnly:(BOOL)isWifiOnly {
    if (!urlKey) {
        return;
    }
    
    [self loadConfigFromStorage:nil];
    TTDownloadTaskConfig *taskConfig = [self findTaskConfigInDicLock:urlKey];
    if (!taskConfig) {
        return;
    }
    
    //update taskConfig's isDownloadWifiOnly parameter
    taskConfig.userParam.isDownloadWifiOnly = isWifiOnly;
    
    TTDownloadTask *task = [self findDownloadingTaskInDicLock:urlKey];
    task.userParameters.isDownloadWifiOnly = isWifiOnly;
    
    //update ParametersTable
    NSError *error = nil;
    if (![self updateParametersTable:taskConfig error:&error]) {
        DLLOGD(@"error=%@", error);
    }
    
    //check if we are downloading in cellular network but isWifiOnly == YES
    if (task && [self.class isMobileNet] && isWifiOnly) {
        DLLOGD(@"task is canceled in setWifiOnlyWithUrlKey, urlKey is %@", urlKey);
        task.isWifiOnlyCancel = YES;
        [task cancelTask];
    }
}

- (int)startDownloadCommon:(NSString *)url
                  fileName:(NSString *)fileName
                  md5Value:(NSString *)md5Value
                  urlLists:(NSArray *)urlLists
                  isResume:(BOOL)isResume
                  isUseKey:(BOOL)isUseKey
          progressCallBack:(TTDownloadProgressBlock)progressCallBack
resultNotificationCallBack:(TTDownloadResultBlock)resultNotificationCallBack
            userParameters:(DownloadGlobalParameters *)userParameters {

    if (nil == resultNotificationCallBack) {
        DLLOGD(@"dlLog:resultNotificationCallBack is nil");
        NSException *exception = [NSException exceptionWithName: @"CallBackException"
                                                         reason: @"resultNotificationCallBack can't be nil"
                                                       userInfo: nil];
        @throw exception;
    }

    [[TTDownloadManager shareInstance] addCheckCancelTaskDicLock:url];

    StatusCode ret = ERROR_INIT;
    if (isUseKey) {
        if (!url || !url.length) {
            ret = ERROR_KEY_INVALID;
        } else if (!urlLists || urlLists.count < 1) {
            ret = ERROR_KEY_NEED_VALID_URL_IN_URLLISTS;
        }
    } else {
        NSURL *URL = [NSURL URLWithString:url];
        DLLOGD(@"dlLog: scheme:%@, host:%@", [URL scheme], [URL host]);
        if (!URL || ![URL scheme] || ![URL host]) {
            DLLOGD(@"dLLog:error ERROR_URL_INVALID");
            ret = ERROR_URL_INVALID;
        }
    }
    if (ret != ERROR_INIT) {
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ret
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return (int)ret;
    }

    if (nil == progressCallBack) {
        DLLOGD(@"dlLog:ERROR_CALLBACK_NULL");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_CALLBACK_NULL
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_CALLBACK_NULL;
    }

    if ([[TTDownloadManager class] isNetworkUnreachable]) {
        DLLOGD(@"dlLog:no net will return");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_NET_UNAVAILABLE
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_NET_UNAVAILABLE;
    }

    if ([self getIsWifiOnlyEnable:userParameters]) {
        if (![[TTDownloadManager class] isWifi]) {
            [self asyncStatusReport:url
                          secondUrl:nil
                             status:ERROR_WIFI_ONLY_BUT_NO_WIFI
                        resultBlock:resultNotificationCallBack
                         taskConfig:nil];
            return ERROR_WIFI_ONLY_BUT_NO_WIFI;
        }
    }

    if ((!fileName || !fileName.length) && !isResume) {
        DLLOGD(@"dlLog:ERROR_FILE_NAME_ERROR");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_FILE_NAME_ERROR
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_FILE_NAME_ERROR;
    }

    DownloadGlobalParameters *mergeParam = nil;
    if (userParameters) {
        DLLOGD(@"dlLog:userParameters is not null,throttle=%lld", userParameters.throttleNetSpeed);
        mergeParam = [userParameters copy];
    } else if (self.downloadGlobalParameter) {
        mergeParam = [self.downloadGlobalParameter copy];
    }
    DLLOGD(@"dLLog:checkInvalidValue:mergeParam");
    if (![self checkInvalidValue:mergeParam]) {
        DLLOGD(@"dLLog:error ERROR_GLOBAL_PARAMETERS_INVALID");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_GLOBAL_PARAMETERS_INVALID
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_GLOBAL_PARAMETERS_INVALID;
    }
    TTDownloadTaskConfig *taskConfig = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:url];
    if (nil != taskConfig) {
        if (DOWNLOADING == taskConfig.downloadStatus) {
            DLLOGD(@"dlLog:ERROR_FILE_DOWNLOADING");
            [self asyncStatusReport:url
                          secondUrl:taskConfig.secondUrl
                             status:ERROR_FILE_DOWNLOADING
                        resultBlock:resultNotificationCallBack
                         taskConfig:nil];
            return ERROR_FILE_DOWNLOADING;
        }
    }
    if (isResume && nil == taskConfig && [TTDownloadManager shareInstance].isHadLoadConfigFromStorage) {
        DLLOGD(@"dlLog:ERROR_NO_TASK_CAN_RESUME");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_NO_TASK_CAN_RESUME
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_NO_TASK_CAN_RESUME;
    }

    if ([[TTDownloadManager shareInstance] getDownloadingTaskDicCount] > [TTDownloadManager shareInstance].downloadingTaskMax) {
        DLLOGD(@"download task overflow");
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_DOWNLOAD_TASK_COUNT_OVERFLOW
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_DOWNLOAD_TASK_COUNT_OVERFLOW;
    }

    DLLOGD(@"dlLog:start create downloadTask object");
    TTDownloadTask *downloadTask = [[TTDownloadTask alloc] initWithObjectDownloadTaskConfig:taskConfig];
    downloadTask.urlKey = url;
    downloadTask.progressBlock = progressCallBack;
    downloadTask.resultBlock = resultNotificationCallBack;

    downloadTask.userParameters = mergeParam;

    if (![[TTDownloadManager shareInstance] addDownloadingTaskToDicLock:downloadTask]) {
        DLLOGD(@"find task in downloadingTaskDic");
        [self asyncStatusReport:url
                      secondUrl:taskConfig.secondUrl
                         status:ERROR_FILE_DOWNLOADING
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_FILE_DOWNLOADING;
    }

    if (![[TTDownloadManager shareInstance] findCheckCancelTaskDicLock:url]) {
        /**
         * if can't find in dic, it means this task cancel in dispatcher module.
         * so return.
         */
        [[TTDownloadManager shareInstance] deleteDownloadingTaskInDicLock:url];
        [self asyncStatusReport:url
                      secondUrl:nil
                         status:ERROR_CANCEL_SUCCESS
                    resultBlock:resultNotificationCallBack
                     taskConfig:nil];
        return ERROR_CANCEL_SUCCESS;
    } else {
        [[TTDownloadManager shareInstance] deleteCheckCancelTaskDicLock:url];
    }
    
    [downloadTask startTask:url
                   urlLists:urlLists
                   fileName:fileName
                   md5Value:md5Value
                   isResume:isResume
                   isUseKey:isUseKey
              progressBlock:progressCallBack
                resultBlock:resultNotificationCallBack];
    DLLOGD(@"dlLog:ERROR_START_DOWNLOAD");
    return ERROR_START_DOWNLOAD;
}

- (void)checkDownloadTaskConfigDic:(NSMutableDictionary *)allDownloadTaskConfig
                        errorArray:(NSMutableArray<NSError *> *)errorArray {
    if (!allDownloadTaskConfig || allDownloadTaskConfig.count <=0) {
        return;
    }
    for (NSString *key in allDownloadTaskConfig) {
        DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
        TTDownloadTaskConfig *obj = [allDownloadTaskConfig objectForKey:key];
        
        if ((obj.userParam.cacheLifeTimeMax > 0)
            && ([TTDownloadManager compareDate:obj.extendConfig.startDownloadTime
                                      withDate:[TTDownloadManager getFormatTime:(-obj.userParam.cacheLifeTimeMax)]] >= 0)) {
            /**
             *Cache expired
             */
            [self deleteDownloadFile:obj isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            continue;
        }
        
        if ((obj && obj.downloadStatus == DOWNLOADED) || [[TTDownloadManager class] isTaskConfigValid:obj]) {
            NSString *downloadTaskPath = [self.appSupportPath stringByAppendingPathComponent:obj.fileStorageDir];
            NSString *downloadTaskPath2 = [self.cachePath stringByAppendingPathComponent:obj.fileStorageDir];

            if ([[self fileManager] fileExistsAtPath:downloadTaskPath]) {
                [[TTDownloadManager shareInstance] addTaskConfigToDicLock:obj];
            } else if ([[self fileManager] fileExistsAtPath:downloadTaskPath2]) {
                [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2 toPath:downloadTaskPath overwrite:YES error:nil];
                [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
                [[TTDownloadManager shareInstance] addTaskConfigToDicLock:obj];
            } else {
                [self deleteDownloadFile:obj isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            }
        } else {
            /**
             *if config is error,will retry to read from db agian. after try times reach 3,will delete this task's config.And downloading it as a new task.
             */
            __block TTDownloadTaskConfig *objTemp = nil;
            int retryTimesMax = 3;

            NSError *error1 = nil;
            while (retryTimesMax-- > 0) {
                if (![self.downloadStorageCenter queryDownloadTaskConfigWithUrlSync:obj.urlKey downloadTaskResultBlock:^(TTDownloadTaskConfig *obj){
                    objTemp = obj;
                } error:&error1]) {
                    if (errorArray && error1 && errorArray.count < 100) {
                        [errorArray addObject:error1];
                    }
                }
                if ([[TTDownloadManager class] isTaskConfigValid:objTemp]) {
                    [[TTDownloadManager shareInstance] addTaskConfigToDicLock:objTemp];
                    break;
                }
            }

            if (retryTimesMax < 0) {
                [self deleteDownloadFile:objTemp isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            }
        }
        DOWNLOADER_AUTO_RELEASE_POOL_END
    }
}

- (void)clearAllCache:(NSMutableDictionary<NSString *, TTDownloadTaskConfig *> *)allDownloadTaskConfig {
    if (!allDownloadTaskConfig || allDownloadTaskConfig.count <= 0) {
        return;
    }
    for (NSString *key in allDownloadTaskConfig) {
        DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
        TTDownloadTaskConfig *obj = [allDownloadTaskConfig objectForKey:key];
        
        if (obj) {
            [self deleteDownloadFile:obj isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
        }
        DOWNLOADER_AUTO_RELEASE_POOL_END
    }
}

+ (BOOL)isShouldClearCache:(TTDownloadTaskConfig *)taskConfig
                      type:(ClearCacheType)type
             clearCacheKey:(const NSArray<NSString *> * _Nullable)list {
    BOOL ret = NO;
    if (!taskConfig) {
        return ret;
    }
    switch (type) {
        case CLEAR_ALL_CACHE:
            ret = YES;
            break;
        case CLEAR_CACHE_BY_KEY:
            if (list && list.count > 0) {
                for (NSString *key in list) {
                    if (key.length > 0 && [taskConfig.urlKey rangeOfString:key].location != NSNotFound) {
                        ret = YES;
                        break;
                    }
                }
            }
            break;
        case CLEAR_CACHE_BY_COMPONENT_ID:
            if (list && list.count > 0) {
                for (NSString *key in list) {
                    if ((key.length > 0)
                        && taskConfig.extendConfig.componentId
                        && [taskConfig.extendConfig.componentId isEqualToString:key]) {
                        ret = YES;
                        break;
                    }
                }
            }
            break;
        default:
            break;
    }
    return ret;
}

- (void)cleanDBAndRebuild {
    NSString *downloadDBPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ttnet_downloader_db.sqlite"];

    if ([TTDownloadManager isFileExist:downloadDBPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:downloadDBPath error:&error];
        if (error) {
            DLLOGE(@"Delete File Error：%@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
        }
    }
    //Create new DB.
    self.downloadStorageCenter = [[TTDownloadStorageCenter alloc] initWithDownloadStorageImplType: TTDownloadStorageImplTypeSqlite];
}

- (BOOL)loadConfigFromStorage:(NSMutableArray<NSError *> *)errorArray {
    BOOL ret = YES;
    [[TTDownloadManager shareInstance].loadConfigFromStorageLock lock];
    if ([TTDownloadManager shareInstance].isHadLoadConfigFromStorage) {
        [[TTDownloadManager shareInstance].loadConfigFromStorageLock unlock];
        return ret;
    }
    /**
     *Delete urgent mode temporary directory
     */
    DLLOGD(@"urgent mode:urgentModeTempRootDir=%@", self.urgentModeTempRootDir);
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.urgentModeTempRootDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.urgentModeTempRootDir error:nil];
    }
    
    NSString *sameTaskBackupDir = [[TTDownloadCommonTools shareInstance].systemTempDir stringByAppendingPathComponent:kMergeTaskDownloadedFileBackupDir];
    if ([TTDownloadCommonTools isDirectoryExist:sameTaskBackupDir]) {
        [TTDownloadCommonTools deleteFile:sameTaskBackupDir];
    }
    
    __block NSMutableDictionary *allDownloadTaskConfigTemp = nil;
    NSError *error1 = nil;
    ret = [self.downloadStorageCenter queryAllDownloadTaskConfigSync:^(NSMutableDictionary *allDownloadTaskConfig) {
        if (allDownloadTaskConfig) {
            allDownloadTaskConfigTemp = allDownloadTaskConfig;
        }
    } error:&error1];

    if (ret) {
        if (self.isClearAllCache) {
            [self clearAllCache:allDownloadTaskConfigTemp];
        } else {
            [self checkDownloadTaskConfigDic:allDownloadTaskConfigTemp
                                  errorArray:errorArray];
            
            /* When load config from db, report incomplete task's log */
            __block NSMutableDictionary<NSString *, TTDownloadTrackModel *> *allTrackModelDic = nil;
            NSError *error2 = nil;
            if (![self.downloadStorageCenter queryAllDownloadTrackModelSync:^(NSMutableDictionary *allDownloadTrackModel) {
                if (allDownloadTrackModel) {
                    allTrackModelDic = allDownloadTrackModel;
                }
            } error:&error2]) {
                if (errorArray && error2 && (errorArray.count < 100)) {
                    [errorArray addObject:error2];
                }
            }

            for (NSString *key in [TTDownloadManager shareInstance].downloadTaskConfigDic) {
                TTDownloadTaskConfig *obj = [self.downloadTaskConfigDic objectForKey:key];
                if (obj && obj.userParam.isUseTracker && obj.downloadStatus == FAILED && [allTrackModelDic objectForKey:obj.fileStorageDir]) {
                    TTDownloadTrackModel *trackModel = [allTrackModelDic objectForKey:obj.fileStorageDir];
                    if (trackModel.trackStatus == TRACK_NONE) {
                        /* get background bytes */
                        if (trackModel.isBgDownloadEnable) {
                            DownloadInfo *info = [[DownloadInfo alloc] init];
                            [self calculateDownloadSize:info taskConfig:obj];
                            trackModel.totalBytes = info.totalSize;
                            trackModel.curBytes = info.downloadedSize;
                            [trackModel calBgDownloadBytes];
                        }
                        [TTDownloadTracker.sharedInstance sendUncompleteEventWithModel:trackModel];
                        NSError *error3 = nil;
                        if (![TTDownloadManager.shareInstance.downloadStorageCenter insertDownloadTrackModelSync:trackModel error:&error3]) {
                            if (errorArray && error3 && (errorArray.count < 100)) {
                                [errorArray addObject:error3];
                            }
                        }
                    }
                }
            }
        }
    } else {
        if (errorArray && error1 && (errorArray.count < 100)) {
            [errorArray addObject:error1];
        }
    }

    if (!ret) {
        if (--_loadDataFromDBRetryTimes <= 0) {
            //We must delete DB and rebuild it.
            _loadDataFromDBRetryTimes = kTTDownloadLoadDBRetryTimes;
            [self cleanDBAndRebuild];
            ret = YES;
            [TTDownloadManager shareInstance].isHadLoadConfigFromStorage = ret;
            [[TTDownloadManager shareInstance].loadConfigFromStorageLock unlock];
            return ret;
        }
    }

    [TTDownloadManager shareInstance].isHadLoadConfigFromStorage = ret;
    [[TTDownloadManager shareInstance].loadConfigFromStorageLock unlock];
    return ret;
}

- (BOOL)addDownloadTaskConfig:(TTDownloadTaskConfig *)downloadTaskConfig error:(NSError **)error {
    if (![[TTDownloadManager class] isTaskConfigValid:downloadTaskConfig]) {
        return NO;
    }
    
    [[TTDownloadManager shareInstance] addTaskConfigToDicLock:downloadTaskConfig];
    if (![self.downloadStorageCenter insertDownloadTaskConfigSync:downloadTaskConfig error:error]) {
        [[TTDownloadManager shareInstance] deleteTaskConfigInDicLock:downloadTaskConfig.urlKey];
        return NO;
    }
    return YES;
}

- (BOOL)removeDownloadTaskConfig:(TTDownloadTaskConfig *)config error:(NSError **)error {
    if (nil == config) {
        return NO;
    }
    [[TTDownloadManager shareInstance] deleteTaskConfigInDicLock:config.urlKey];
    if (![self.downloadStorageCenter deleteDownloadTaskConfigSync:config error:error]) {
        return NO;
    }

    if (config.userParam.isUseTracker) {
        if (![self.downloadStorageCenter deleteDownloadTrackModelWithUrlMd5Sync:config.fileStorageDir error:error]) {
            return NO;
        }
    }

    return YES;
}

#pragma mark - checkCancelTaskDic
- (BOOL)addCheckCancelTaskDicLock:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock lock];
    [[TTDownloadManager shareInstance].checkCancelTaskDic setObject:@"cancel" forKey:urlKey];
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock unlock];
    return YES;
}

- (BOOL)deleteCheckCancelTaskDicLock:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock lock];
    [[TTDownloadManager shareInstance].checkCancelTaskDic removeObjectForKey:urlKey];
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock unlock];
    return YES;
}

- (BOOL)findCheckCancelTaskDicLock:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock lock];
    id ret = [[TTDownloadManager shareInstance].checkCancelTaskDic objectForKey:urlKey];
    [[TTDownloadManager shareInstance].checkCancelTaskDicLock unlock];
    return ret ? YES : NO;
}

#pragma mark - bgIdentifierArray

- (BOOL)findBgIdentifierDicLock:(NSString *)identifier {
    if (nil == identifier) {
        return NO;
    }
    [[TTDownloadManager shareInstance].bgIdentifierDicLock lock];
    NSString *value = [[TTDownloadManager shareInstance].bgIdentifierDic objectForKey:identifier];
    [[TTDownloadManager shareInstance].bgIdentifierDicLock unlock];
    return value ? YES : NO;
}

- (BOOL)addBgIdentifierDicLock:(NSString *)identifier value:(NSString *)urlKey{
    if (nil == identifier) {
        return NO;
    }
    [[TTDownloadManager shareInstance].bgIdentifierDicLock lock];
    [[TTDownloadManager shareInstance].bgIdentifierDic setObject:urlKey forKey:identifier];
    [[TTDownloadManager shareInstance].bgIdentifierDicLock unlock];
    return YES;
}

- (BOOL)deleteBgIdentifierWithValueLock:(NSString *)value {
    if (!value) {
        return NO;
    }
    DLLOGD(@"deleteBgIdentifierWithValueLock:timging--start");
    [[TTDownloadManager shareInstance].bgIdentifierDicLock lock];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSArray *key = [[TTDownloadManager shareInstance].bgIdentifierDic allKeys];
    
    for (int i = 0; i < [TTDownloadManager shareInstance].bgIdentifierDic.count; i++) {
        if (![value isEqualToString:[TTDownloadManager shareInstance].bgIdentifierDic[key[i]]]) {
            [dic setObject:[TTDownloadManager shareInstance].bgIdentifierDic[key[i]] forKey:key[i]];
        }
    }
    [TTDownloadManager shareInstance].bgIdentifierDic = dic;
    [[TTDownloadManager shareInstance].bgIdentifierDicLock unlock];
    DLLOGD(@"deleteBgIdentifierWithValueLock:timging--end");
    return YES;
}

- (BOOL)deleteBgIdentifierDicLock:(NSString *)identifier {
    if (nil == identifier) {
        return NO;
    }
    [[TTDownloadManager shareInstance].bgIdentifierDicLock lock];
    [[TTDownloadManager shareInstance].bgIdentifierDic removeObjectForKey:identifier];
    [[TTDownloadManager shareInstance].bgIdentifierDicLock unlock];
    return YES;
}

- (void)clearBgIdentifierDicLock {
    [[TTDownloadManager shareInstance].bgIdentifierDicLock lock];
    [[TTDownloadManager shareInstance].bgIdentifierDic removeAllObjects];
    [[TTDownloadManager shareInstance].bgIdentifierDicLock unlock];
}

#pragma mark - DownloadingTaskDic

- (TTDownloadTask*)findDownloadingTaskInDicLock:(NSString *)url {
    if (nil == url) {
        return nil;
    }
    TTDownloadTask *task;
    [[TTDownloadManager shareInstance].downloadingTaskDicLock lock];
    task = [[TTDownloadManager shareInstance].downloadingTaskDic objectForKey:url];
    [[TTDownloadManager shareInstance].downloadingTaskDicLock unlock];
    return task;
}

- (BOOL)addDownloadingTaskToDicLock:(TTDownloadTask*)task {
    BOOL ret = NO;

    if (nil == task) {
        return ret;
    }
    [[TTDownloadManager shareInstance].downloadingTaskDicLock lock];
    TTDownloadTask *taskTemp = [[TTDownloadManager shareInstance].downloadingTaskDic objectForKey:task.urlKey];
    if (!taskTemp) {
        ret = YES;
        [[TTDownloadManager shareInstance].downloadingTaskDic setObject:task forKey:task.urlKey];
    }
    [[TTDownloadManager shareInstance].downloadingTaskDicLock unlock];
    return ret;
}

-(BOOL)deleteDownloadingTaskInDicLock:(NSString *)url {
    if (nil == url) {
        return NO;
    }
    [[TTDownloadManager shareInstance].downloadingTaskDicLock lock];
    [[TTDownloadManager shareInstance].downloadingTaskDic removeObjectForKey:url];
    [[TTDownloadManager shareInstance].downloadingTaskDicLock unlock];
    return YES;
}

-(BOOL)updateDownloadingTaskInDicLock:(TTDownloadTask*)task {
    if (nil == task) {
        return NO;
    }
    [[TTDownloadManager shareInstance].downloadingTaskDicLock lock];
    [[TTDownloadManager shareInstance].downloadingTaskDic setObject:task forKey:task.urlKey];
    [[TTDownloadManager shareInstance].downloadingTaskDicLock unlock];
    return YES;
}

- (NSUInteger) getDownloadingTaskDicCount {
    [[TTDownloadManager shareInstance].downloadingTaskDicLock lock];
    NSUInteger count = [TTDownloadManager shareInstance].downloadingTaskDic.count;
    [[TTDownloadManager shareInstance].downloadingTaskDicLock unlock];
    return count;
}
#pragma mark - TaskConfigDic

- (TTDownloadTaskConfig*)findTaskConfigInDicLock:(NSString *)url {
    if (nil == url) {
        return nil;
    }
    TTDownloadTaskConfig *config;
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
    config = [[TTDownloadManager shareInstance].downloadTaskConfigDic objectForKey:url];
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];
    return config;
}

- (BOOL)addTaskConfigToDicLock:(TTDownloadTaskConfig*)downloadTaskConfig {
    if (nil == downloadTaskConfig) {
        return NO;
    }
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
    [[TTDownloadManager shareInstance].downloadTaskConfigDic setObject:downloadTaskConfig forKey:downloadTaskConfig.urlKey];
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];
    return YES;
}

-(BOOL)deleteTaskConfigInDicLock:(NSString *)url {
    if (nil == url) {
        return NO;
    }
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
    [[TTDownloadManager shareInstance].downloadTaskConfigDic removeObjectForKey:url];
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];
    return YES;
}

-(BOOL)updateTaskConfigInDicLock:(TTDownloadTaskConfig*)downloadTaskConfig {
    if (nil == downloadTaskConfig) {
        return NO;
    }
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
    [[TTDownloadManager shareInstance].downloadTaskConfigDic setObject:downloadTaskConfig forKey:downloadTaskConfig.urlKey];
    [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];

    NSError *error = nil;
    if (![self updateParametersTable:downloadTaskConfig error:&error]) {
        DLLOGD(@"error=%@", error);
    }
    
    return YES;
}

- (BOOL)updateDownloadTaskConfig:(NSString *)url status:(DownloadStatus)status error:(NSError *__autoreleasing *)error {
    if (nil == url || status < INIT || status > CANCELLED) {
        return NO;
    }
    TTDownloadTaskConfig *config = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:url];
    if (nil == config) {
        DLLOGD(@"can't find downloadTaskConfig for key %@", url);
        return NO;
    }
    config.downloadStatus = status;

    if (DOWNLOADED == status) {
        [self.downloadStorageCenter updateDownloadTaskConfigSync:config error:error];
    }
    if (DOWNLOADING != status) {
        [[TTDownloadManager shareInstance] deleteDownloadingTaskInDicLock:url];
    }
    if (DELETED == status) {
        [[TTDownloadManager shareInstance] deleteTaskConfigInDicLock:url];
    }
    return YES;
}

#pragma mark - DeleteDownloadFile
- (void)runDeleteDownloadFile:(NSArray *)deleteInfoArrays {
    if ((deleteInfoArrays == nil) || (deleteInfoArrays.count < 2)) {
        return;
    }

    [[TTDownloadManager shareInstance] loadConfigFromStorage:nil];
    
    NSString *url                                  = deleteInfoArrays[0];
    TTDownloadResultBlock resultBlock              = deleteInfoArrays[1];
    
    TTDownloadTaskConfig *taskConfig               = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:url];
    DownloadResultNotification *resultNotification = [[DownloadResultNotification alloc] init];
    resultNotification.urlKey                      = taskConfig.urlKey;
    resultNotification.secondUrl                   = taskConfig.secondUrl;
    
    DownloadStatus status;

    if (!taskConfig) {
        resultNotification.code = ERROR_DELETE_SUCCESS;
        status = DELETED;
    } else if ([self deleteDownloadFile:taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES]) {
        DLLOGD(@"dlLog:delete:runDeleteDownloadFile:ERROR_DELETE_SUCCESS");
        resultNotification.code = ERROR_DELETE_SUCCESS;
        status = DELETED;
    } else {
        DLLOGD(@"dlLog:delete:runDeleteDownloadFile:ERROR_DELETE_FAIL");
        status = FAILED;
        resultNotification.code = ERROR_DELETE_FAIL;
    }

    DLLOGD(@"urgent mode:urgentModeTempRootDir=%@", self.urgentModeTempRootDir);
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.urgentModeTempRootDir]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *md5 = [TTDownloadManager calculateUrlMd5:url];
        NSString *tempTaskDirFullPath = [self.urgentModeTempRootDir stringByAppendingPathComponent:md5];
        if ([fileManager fileExistsAtPath:tempTaskDirFullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:tempTaskDirFullPath error:nil];
        }
    }
    
    NSError *error = nil;
    if (![self updateDownloadTaskConfig:taskConfig.urlKey status:status error:&error]) {
        DLLOGD(@"error=%@", error);
    }
    resultBlock(resultNotification);
}

- (BOOL)deleteDownloadFile:(TTDownloadTaskConfig *)ttDownloadTaskConfig
                isDeleteDB:(BOOL)isDeleteDB
         isDeleteMergeFile:(BOOL)isDeleteMergeFile
         isDeleteSliceFile:(BOOL)isDeleteSliceFile {
    DLLOGD(@"enter deleteDownloadFile isDeleteDB=%d,isDeleteMergeFile=%d,isDeleteSliceFile=%d", isDeleteDB, isDeleteMergeFile, isDeleteSliceFile);
    if (!ttDownloadTaskConfig) {
        return YES;
    }
    NSString *downloadTaskPath = [self.appSupportPath stringByAppendingPathComponent:ttDownloadTaskConfig.fileStorageDir];

    if (![[self fileManager] fileExistsAtPath:downloadTaskPath]) {
        NSString *downloadTaskPath2 = [self.cachePath stringByAppendingPathComponent:ttDownloadTaskConfig.fileStorageDir];
        if ([[self fileManager] fileExistsAtPath:downloadTaskPath2]) {
            [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2 toPath:downloadTaskPath overwrite:YES error:nil];
            [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
        }
    }

    if (isDeleteSliceFile) {
        /**
         * delete subslice
         */
        NSString *slicePath = [downloadTaskPath stringByAppendingPathComponent:SLICE_DIR];
        if (![self deleteFile:slicePath]) {
            DLLOGD(@"dlLog:delete:deleteDownloadFile:deleteFile:slicePath failed");
            return NO;
        }
        
        NSError *error = nil;
        if (![self deleteSubSliceInfo:ttDownloadTaskConfig error:&error]) {
            DLLOGD(@"dlLog:delete:deleteSubSliceInfo:ttDownloadTaskConfig failed");
            DLLOGD(@"error=%@", error);
            return NO;
        }
    }

    if (isDeleteMergeFile) {
        NSString *mergeFilePath = [downloadTaskPath stringByAppendingPathComponent:ttDownloadTaskConfig.fileStorageName];
        if (![self deleteFile:mergeFilePath]) {
            DLLOGD(@"dlLog:delete:deleteDownloadFile:deleteFile:mergeFilePath failed");
            return NO;
        }
    }

    if (isDeleteDB) {
        if (![self deleteFile:downloadTaskPath]) {
            DLLOGD(@"dlLog:delete:deleteDownloadFile:deleteFile:downloadTaskPath failed");
            return NO;
        }

        NSError *error = nil;
        if (![self.downloadStorageCenter deleteDownloadTaskConfigSync:ttDownloadTaskConfig error:&error]) {
            if (error) {
                DLLOGD(@"error=%@", error.description);
            }
            DLLOGD(@"dlLog:delete:deleteDownloadFile:deleteDownloadTaskConfigSync:ttDownloadTaskConfig failed");
            return NO;
        } else {
            DLLOGD(@"dlLog:delete:deleteDownloadFile:deleteDownloadTaskConfigSync:ttDownloadTaskConfig successfully");
            /* delete trackModel */
            if (ttDownloadTaskConfig.userParam.isUseTracker) {
                error = nil;
                if (![self.downloadStorageCenter deleteDownloadTrackModelWithUrlMd5Sync:ttDownloadTaskConfig.fileStorageDir error:&error]) {
                    DLLOGD(@"error=%@", error.description);
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)deleteFile:(NSString *)filePath {
    BOOL isExits = [[self fileManager] fileExistsAtPath:filePath];
    
    if (isExits) {
        NSError *error;
        [[self fileManager] removeItemAtPath:filePath error:&error];
        
        if (error) {
            DLLOGD(@"Delete File Error：%@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
            return NO;
        }
    }
    
    return YES;
}


- (void)runQueryDownloadInfo:(NSArray *)downloadInfoArrays
                      status:(DownloadStatus)status {
    if ((downloadInfoArrays == nil) || (downloadInfoArrays.count < 2)) {
        return;
    }
    NSString *url                         = downloadInfoArrays[0];
    TTDownloadInfoBlock downloadInfoBlock = downloadInfoArrays[1];
    
    [[TTDownloadManager shareInstance] loadConfigFromStorage:nil];
    /**
     *Urgent mode, we hope caller restart request.
     */
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.urgentModeTempRootDir]) {
        downloadInfoBlock(nil);
        return;
    }

    TTDownloadTaskConfig *taskConfig      = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:url];
    
    if (nil != taskConfig || DOWNLOADING == status || QUEUE_WAIT == status) {
        DownloadInfo *downloadInfo = [[DownloadInfo alloc] init];
        downloadInfo.urlKey        = url;
        if (DOWNLOADING == status || QUEUE_WAIT == status) {
            downloadInfo.status    = status;
        } else {
            downloadInfo.status    = taskConfig.downloadStatus;
        }
        downloadInfo.inputFileName = taskConfig.fileStorageName;
        downloadInfo.secondUrl     = taskConfig.secondUrl;
        if (taskConfig.downloadStatus == DOWNLOADED) {
            NSString *fileFullPath = [[self.appSupportPath stringByAppendingPathComponent:taskConfig.fileStorageDir] stringByAppendingPathComponent:taskConfig.fileStorageName];
            if ([self.fileManager fileExistsAtPath:fileFullPath]) {
                downloadInfo.fileFullPath = fileFullPath;
            }
        }
        [self calculateDownloadSize:downloadInfo taskConfig:taskConfig];
        downloadInfoBlock(downloadInfo);
    } else {
        downloadInfoBlock(nil);
    }
}

- (void)calculateDownloadSize:(DownloadInfo *)downloadInfo
                   taskConfig:(TTDownloadTaskConfig *)taskConfig {
    if (!downloadInfo || !taskConfig) {
        return;
    }

    NSString *downloadTaskPath = [self.appSupportPath stringByAppendingPathComponent:taskConfig.fileStorageDir];
    int64_t downloadedSize     = 0;
    int64_t totalSize          = 0;

    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath]) {
        NSString *downloadTaskPath2 = [[TTDownloadManager shareInstance].cachePath stringByAppendingPathComponent:taskConfig.fileStorageDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath2]) {
            [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2 toPath:downloadTaskPath overwrite:YES error:nil];
            [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
        }
    }
    
    if (downloadInfo.status != DOWNLOADED) {
        if (![[TTDownloadManager class] isArrayValid:taskConfig.downloadSliceTaskConfigArray]) {
            return;
        }

        for (int i = 0; i < taskConfig.downloadSliceTaskConfigArray.count; i++) {
            TTDownloadSliceTaskConfig *slice = [taskConfig.downloadSliceTaskConfigArray objectAtIndex:i];
            downloadedSize += [[TTDownloadManager class] getHadDownloadedLength:slice isReadLastSubSlice:YES];
            totalSize += slice.sliceTotalLength;
        }
    } else {
        NSString *mergeFilePath = [downloadTaskPath stringByAppendingPathComponent:taskConfig.fileStorageName];
        
        if ([[self fileManager] fileExistsAtPath:mergeFilePath]) {
            NSError *error;
            NSDictionary *fileAttributeDic = [[self fileManager] attributesOfItemAtPath:mergeFilePath error:&error];
            
            if (error) {
                DLLOGD(@"Merge File Size Error：%@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
            } else {
                downloadedSize = fileAttributeDic.fileSize;
                totalSize = downloadedSize;
            }
        }
    }
    
    downloadInfo.downloadedSize = downloadedSize;
    downloadInfo.totalSize = totalSize;
}

#pragma mark - TrackModel

- (BOOL)addTrackModelToDB:(TTDownloadTrackModel *)ttDTM {
    if (!ttDTM) {
        return NO;
    }
    NSError *error = nil;
    BOOL ret = [self.downloadStorageCenter insertDownloadTrackModelSync:ttDTM error:&error];
    if (!ret) {
        DLLOGD(@"error=%@", error);
    }
    return ret;
}

- (BOOL)getTrackModelFromDBForTask:(TTDownloadTask *)task {
    if (!task.taskConfig.fileStorageDir) {
        return NO;
    }

    NSError *error = nil;
    BOOL ret = [self.downloadStorageCenter queryDownloadTrackModelWithUrlMd5Sync:task.taskConfig.fileStorageDir downloadTrackResultBlock:^(id trackModel) {
        task.trackModel = (TTDownloadTrackModel *)trackModel;
    } error:&error];
    if (!ret) {
        DLLOGD(@"error=%@", error);
    }
    return ret;
}

+ (int64_t)freeDiskSpace {
    NSError *error = nil;
    NSString *dirPath = NSTemporaryDirectory();

    if (@available(iOS 11.0, *)) {
        NSURL *fileUrl = [NSURL fileURLWithPath:dirPath];
        NSNumber *freeSpace = nil;
        [fileUrl getResourceValue:&freeSpace forKey:NSURLVolumeAvailableCapacityForImportantUsageKey error:&error];
        if (freeSpace && !error) {
            return [freeSpace longLongValue];
        }
    }

    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:dirPath error:&error];
    if (dictionary && !error) {
        return [dictionary[NSFileSystemFreeSize] longLongValue];
    }
    return GET_FREE_DISK_SPACE_ERROR;
}



+ (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite error:(NSError **)error {
    
    if (!path || !toPath) {
        return NO;
    }
    
    NSFileManager * manager = [NSFileManager defaultManager];

    if ([manager fileExistsAtPath:toPath]) {
        if (overwrite) {
            if (![manager removeItemAtPath:toPath error:error]) {
                if (*error) {
                    DLLOGD(@"Delete File Error：%@ %@ %@", [*error localizedDescription], [*error localizedFailureReason], [*error localizedRecoverySuggestion]);
                    return NO;
                }
            }
        } else {
            if (![manager removeItemAtPath:path error:error]) {
                if (*error) {
                    DLLOGD(@"Delete File Error：%@ %@ %@", [*error localizedDescription], [*error localizedFailureReason], [*error localizedRecoverySuggestion]);
                }
                return NO;
            }
            return YES;
        }
    }

    if (![manager moveItemAtPath:path toPath:toPath error:error]) {
        if (*error) {
            DLLOGD(@"Delete File Error：%@ %@ %@", [*error localizedDescription], [*error localizedFailureReason], [*error localizedRecoverySuggestion]);
        }
        return NO;
    }
    return YES;
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString {
    NSURL* URL= [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);

    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        DLLOGD(@"9898Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (BOOL)isWifi {
    return ReachableViaWiFi == [[TTDownloadManager class] getCurrentNetType];
}

+ (BOOL)isNetworkUnreachable {
    return NotReachable == [[TTDownloadManager class] getCurrentNetType];
}

+ (BOOL)isMobileNet {
    return ReachableViaWWAN == [[TTDownloadManager class] getCurrentNetType];
}

+ (NetworkStatus)getCurrentNetType {
    NSString *net;
    NetworkStatus internetStatus = [[TTReachability reachabilityForInternetConnection] currentReachabilityStatus];

    switch (internetStatus) {
        case ReachableViaWiFi:
            net = @"WIFI";
            break;
        case ReachableViaWWAN:
            net = @"Mobile network";
            break;
        case NotReachable:
            net = @"Net unavalible";
        default:
            break;
    }
    DLLOGD(@"getCurrentNetType:net type is %@", net);
    return internetStatus;
}

- (void)setEventBlock:(TTDownloadEventBlock)eventBlock {
    _eventBlock = eventBlock;
    TTDownloadTracker.sharedInstance.eventBlock = eventBlock;
}

+ (void)load {
    DLLOGD(@"dlLog++++++++APP Start call load+++++++++++++");
    [[NSNotificationCenter defaultCenter] addObserver:[TTDownloadManager shareInstance] selector:@selector(appFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)tryRestoreTask {
    DLLOGD(@"dlLog:++++++tryRestoreTask++++++++++");
    NSString *flagsPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:RESTORE_MODE_FLAG_NAME];
    if (![[TTDownloadManager shareInstance].fileManager fileExistsAtPath:flagsPath]) {
        DLLOGD(@"dlLog:no restore falg file return");
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
        DLLOGD(@"dlLog:++++++call loadConfigFromStorage++++++++");
        if (![[TTDownloadManager shareInstance] loadConfigFromStorage:nil]) {
            DLLOGD(@"dlLog:loadConfigFromStorage failed");
            return;
        }
        NSMutableDictionary *restoreTaskDic = [NSMutableDictionary dictionary];
        __block BOOL isDeleteFlagFile = YES;
        [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
        DLLOGD(@"dlLog:+++++downloadTaskConfigDic size is %lu++++++", (unsigned long)[TTDownloadManager shareInstance].downloadTaskConfigDic.count);
        [[TTDownloadManager shareInstance].downloadTaskConfigDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TTDownloadTaskConfig * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.downloadStatus != DOWNLOADED && obj.restoreTimesAuto > 0) {
                isDeleteFlagFile = NO;
            }
            if (obj.downloadStatus != DOWNLOADED && obj.downloadStatus != DOWNLOADING && obj.restoreTimesAuto > 0 && obj.resultBlock && obj.progressBlock) {
                [restoreTaskDic setObject:obj forKey:obj.urlKey];
            }
        }];
        [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];

        if (isDeleteFlagFile) {
            DLLOGD(@"dlLog:+++++++delete restore flag file++tryRestoreTask++++++");
            [[TTDownloadManager shareInstance] deleteFile:flagsPath];
        }
        DLLOGD(@"dlLog:the count of retore task is ：%lu", (unsigned long)restoreTaskDic.count);
        if (restoreTaskDic.count > 0) {
            int8_t realTaskCount = 0;
            for (NSString *key in restoreTaskDic) {
                if (realTaskCount++ == [TTDownloadManager shareInstance].downloadingTaskMax) {
                    DLLOGD(@"dlLog:task count overflow");
                    break;
                }
                DLLOGD(@"dlLog:restore task key:%@", key);
                TTDownloadTaskConfig *obj = [restoreTaskDic objectForKey:key];
                DLLOGD(@"dlLog:+++++net unavailable restore++++urlKey=%@,secondUrl=%@", obj.urlKey, obj.secondUrl);
                obj.isAutoRestore = YES;
                self.isTryRestoreTaskWhenRestart = YES;
                [[TTDownloadManager shareInstance] restoreTask:obj.urlKey
                                                     secondUrl:obj.secondUrl
                                            resultNotification:obj.resultBlock
                                                      progress:obj.progressBlock];
            }
        }
    });
}

- (void)appReachabilityChanged:(NSNotification *)notification {
    DLLOGD(@"dlLog:+++++TTDownloadManager net change+++++++");
    NetworkStatus status = [[TTDownloadManager class] getCurrentNetType];
    DLLOGD(@"dlLog:status=%ld,self.previousNetStatus=%ld", (long)status, (long)self.previousNetStatus);

    if ((NotReachable == self.previousNetStatus && NotReachable != status) || (ReachableViaWiFi == status)) {
        [self tryRestoreTask];
    }
    [TTDownloadManager shareInstance].previousNetStatus = status;

    if (!self.isTryRestoreTaskWhenRestart) {
        DLLOGD(@"dlLog:Net unavailable when reboot,net available Now，start restore");
        [self restartAppTryRestroreTask];
    }
}

- (void)appFinishLaunching {
    [self restartAppTryRestroreTask];
}

- (void)restartAppTryRestroreTask {
    /**
     *To avoid affecting performance,we use file flags to decide whether should try to restroe.
     */
    NSString *flagsPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:RESTORE_MODE_FLAG_NAME];
    if (![[TTDownloadManager shareInstance].fileManager fileExistsAtPath:flagsPath]) {
        DLLOGD(@"dlLog:+++++++no restore flag file return+++++++++");
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
        DLLOGD(@"dlLog:+++++++find restore flag file will try to restore+++++++++");
        /**
         *Just try to restore in WIFI.
         */
        if (![[TTDownloadManager class] isWifi]) {
            DLLOGD(@"dlLog:+++++++no wifi when App restart restore return+++++++++");
            return;
        }

        if (![[TTDownloadManager shareInstance] loadConfigFromStorage:nil]) {
            DLLOGD(@"dlLog:restartAppTryRestroreTask:loadConfigFromStorage failed");
            return;
        }
        NSMutableDictionary *restoreTaskDic = [NSMutableDictionary dictionary];
        __block BOOL isDeleteFlagFile = YES;
        [[TTDownloadManager shareInstance].downloadTaskConfigDicLock lock];
        DLLOGD(@"+++++downloadTaskConfigDic size is %lu++++++", (unsigned long)[TTDownloadManager shareInstance].downloadTaskConfigDic.count);
        [[TTDownloadManager shareInstance].downloadTaskConfigDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TTDownloadTaskConfig * _Nonnull obj, BOOL * _Nonnull stop) {
            DLLOGD(@"Go through all task status ：obj.downloadStatus=%ld,obj.restoreTimesAuto=%d,obj.resultBlock=%p,obj.progressBlock=%p", (long)obj.downloadStatus, obj.restoreTimesAuto, obj.resultBlock, obj.progressBlock);

            if (obj.downloadStatus != DOWNLOADED && obj.restoreTimesAuto > 0) {
                isDeleteFlagFile = NO;
            }

            if (obj.downloadStatus != DOWNLOADED && obj.restoreTimesAuto > 0 && !obj.resultBlock && !obj.progressBlock) {
                DLLOGD(@"task add dic to restore：%@", obj.urlKey);
                [restoreTaskDic setObject:obj forKey:obj.urlKey];
            }
        }];
        [[TTDownloadManager shareInstance].downloadTaskConfigDicLock unlock];
        DLLOGD(@"restoreTaskDic :%lu", (unsigned long)restoreTaskDic.count);
        if (isDeleteFlagFile) {
            DLLOGD(@"+++++++delete restore flag file++restartAppTryRestroreTask++++++");
            [[TTDownloadManager shareInstance] deleteFile:flagsPath];
        }
        __weak __typeof(self)weakSelf = self;
        ResultBlock resultNotification = ^(DownloadResultNotification *resultNotification) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf postRestoreResultNotification:resultNotification];
        };
        
        ProgressBlock progress = ^(DownloadProgressInfo *progress) {
            DLLOGD(@"++restore task++++progress=%f++++++speed=%lld", progress.progress, progress.netDownloadSpeed);
        };
        
        if (restoreTaskDic.count > 0) {
            int8_t realTaskCount = 0;
            for (NSString *key in restoreTaskDic) {
                if (realTaskCount++ == [TTDownloadManager shareInstance].downloadingTaskMax) {
                    DLLOGD(@"dlLog:task count overflow");
                    break;
                }
                TTDownloadTaskConfig *obj = [restoreTaskDic objectForKey:key];
                obj.isAutoRestore = YES;
                
                DLLOGD(@"+++++start restore++++++urlKey=%@,secondUrl=%@", obj.urlKey, obj.secondUrl);
                self.isTryRestoreTaskWhenRestart = YES;
                [[TTDownloadManager shareInstance] restoreTask:obj.urlKey
                                                     secondUrl:obj.secondUrl
                                            resultNotification:resultNotification
                                                      progress:progress];
            }
        }
    });
}

- (void)restoreTask:(NSString *)urlKey secondUrl:(NSString *)secondUrl resultNotification:(TTDownloadResultBlock)resultNotification progress:(TTDownloadProgressBlock)progress {
    DLLOGD(@"dlLog:TTDownloadManager:restoreTask,urlKey=%@,secondUrl=%@", urlKey, secondUrl);
    if (secondUrl) {
        NSArray *urlList = [NSArray arrayWithObject:secondUrl];
        [[TTDownloadApi shareInstance] resumeDownloadWithKey:urlKey
                                                    urlLists:urlList
                                                    progress:progress
                                                      status:resultNotification
                                              userParameters:nil];
    } else {
        [[TTDownloadApi shareInstance] resumeDownloadWithURL:urlKey
                                                    progress:progress
                                                      status:resultNotification
                                              userParameters:nil];
    }
}

- (void)postRestoreResultNotification:(DownloadResultNotification *)resultNotification {
    if (!resultNotification) {
        return;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithObject:resultNotification forKey:@"resultNotification"];
    DLLOGD(@"dlLog:++++++++postRestoreResultNotification++++++++++");
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTDownloaderRestoreResultNotification object:nil userInfo:dic];
}

- (BOOL)insertOrUpdateSubSliceInfo:(TTDownloadSubSliceInfo *)subslice error:(NSError *__autoreleasing *)error1 {
    return [self.downloadStorageCenter insertOrUpdateSubSliceInfo:subslice error:error1];
}

- (BOOL)updateSliceConfig:(TTDownloadSliceTaskConfig *)sliceConfig
               taskConfig:(TTDownloadTaskConfig *)taskConfig
                    error:(NSError *__autoreleasing *)error {
    BOOL ret = [self.downloadStorageCenter updateSliceConfig:sliceConfig sliceConfig:taskConfig error:error];
    DLLOGD(@"error=%@", *error);
    return ret;
}

- (BOOL)deleteSubSliceInfo:(TTDownloadTaskConfig *)taskConfig error:(NSError **)error {
    BOOL ret = [self.downloadStorageCenter deleteSubSliceInfo:taskConfig error:error];
    if (!ret) {
        DLLOGE(@"error=%@", *error);
    }
    return ret;
}

- (void)runBgCompletedHandler {
    if ([TTDownloadManager shareInstance].bgCompletedHandler) {
        DLLOGD(@"[TTDownloadManager shareInstance].bgCompletedHandler()");
        [TTDownloadManager shareInstance].bgCompletedHandler();
        [TTDownloadManager shareInstance].bgCompletedHandler = nil;
    }
}

- (BOOL)updateParametersTable:(TTDownloadTaskConfig *)taskConfig error:(NSError *__autoreleasing *)error {
    return [self.downloadStorageCenter updateParametersTable:taskConfig error:error];
}

- (BOOL)updateExtendConfigSync:(TTDownloadTaskConfig *)taskConfig error:(NSError *__autoreleasing *)error {
    return [self.downloadStorageCenter updateExtendConfigSync:taskConfig error:error];
}

- (BOOL)clearAllCache:(const ClearCacheType)type
        clearCacheKey:(const NSArray<NSString *> *)list
                error:(NSError **)error {
    if (CLEAR_ALL_CACHE == type) {
        /**
         *If caller want to clear all cache, we can clear them in loadConfigFromStorage to
         *avoid iterating through dictionary 2 times.
         */
        self.isClearAllCache = YES;
    } else if (CLEAR_NO_EXPIRE_TIME_CACHE == type) {
        self.isClearNoExpireTimeCache = YES;
    }
    [self loadConfigFromStorage:nil];
    BOOL ret = [self doClearCache:type clearCacheKey:list];
    self.isClearAllCache = NO;
    self.isClearNoExpireTimeCache = NO;
    return ret;
}

- (void)stopClearNoExpireCache {
    self.isClearNoExpireTimeCache = NO;
}

- (int64_t)getAllCacheCount {
    [self loadConfigFromStorage:nil];
    [self.downloadTaskConfigDicLock lock];
    int64_t count = self.downloadTaskConfigDic.count;
    [self.downloadTaskConfigDicLock unlock];
    return count;
}

- (int64_t)getAllNoExpireTimeCacheCount {
    [self loadConfigFromStorage:nil];
    [self.downloadTaskConfigDicLock lock];
    int64_t count = 0L;
    for (NSString *key in self.downloadTaskConfigDic) {
        TTDownloadTaskConfig *obj = [[TTDownloadManager shareInstance].downloadTaskConfigDic objectForKey:key];
        if (obj && obj.userParam.cacheLifeTimeMax <= 0) {
            ++count;
        }
    }
    [self.downloadTaskConfigDicLock unlock];
    return count;
}

- (BOOL)doClearCache:(ClearCacheType)type
       clearCacheKey:(const NSArray<NSString *> * _Nullable)list {
    [self.downloadTaskConfigDicLock lock];
    /**
     *If downloadTaskConfigDic size is 0, do nothing.
     */
    if (self.downloadTaskConfigDic.count <= 0) {
        [self.downloadTaskConfigDicLock unlock];
        return YES;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    BOOL isClearNoExpireTimeCacheCompleted = YES;
    for (NSString *key in self.downloadTaskConfigDic) {
        DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
        TTDownloadTaskConfig *obj = [[TTDownloadManager shareInstance].downloadTaskConfigDic objectForKey:key];
        if (!obj) {
            continue;
        }
        
        if ([self findDownloadingTaskInDicLock:obj.urlKey]) {
            [dic setObject:obj forKey:obj.urlKey];
        } else if (CLEAR_NO_EXPIRE_TIME_CACHE == type) {
            if (self.isClearNoExpireTimeCache) {
                if (obj.userParam.cacheLifeTimeMax <= 0) {
                    [self deleteDownloadFile:obj
                                  isDeleteDB:YES
                           isDeleteMergeFile:YES
                           isDeleteSliceFile:YES];
                    continue;
                }
            } else {
                isClearNoExpireTimeCacheCompleted = NO;
            }
            [dic setObject:obj forKey:obj.urlKey];
        } else if ([[self class] isShouldClearCache:obj type:type clearCacheKey:list]) {
            [self deleteDownloadFile:obj isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
        } else {
            [dic setObject:obj forKey:obj.urlKey];
        }
        DOWNLOADER_AUTO_RELEASE_POOL_END
    }
    [self.downloadTaskConfigDic removeAllObjects];
    self.downloadTaskConfigDic = dic;
    [self.downloadTaskConfigDicLock unlock];

    if (CLEAR_NO_EXPIRE_TIME_CACHE == type) {
        return isClearNoExpireTimeCacheCompleted;
    }
    return YES;
}

- (NSMutableDictionary *)getAllRuleFromDB:(NSError **)error {
    NSMutableDictionary *ret = [self.downloadStorageCenter getAllClearCacheRule:error];
    if (!ret) {
        DLLOGD(@"error = %@", *error);
    }
    return ret;
}

- (BOOL)insertOrUpdateClearCacheRule:(TTClearCacheRule *)rule
                               error:(NSError **)error {
    BOOL ret = [self.downloadStorageCenter insertOrUpdateClearCacheRule:rule error:error];
    if (!ret) {
        DLLOGD(@"error=%@", *error);
    }
    return ret;
}

- (BOOL)deleteClearCacheRule:(TTClearCacheRule *)rule
                       error:(NSError **)error {
    BOOL ret = [self.downloadStorageCenter deleteClearCacheRule:rule error:error];
    if (!ret) {
        DLLOGD(@"error=%@", *error);
    }
    return ret;
}

+ (BOOL)isArrayValid:(NSMutableArray *)array {
    return array && ![array isKindOfClass:[NSNull class]] && array.count > 0;
}

+ (BOOL)createDir:(NSString *)dirPath error:(NSError **)error {
    if (!dirPath) {
        return NO;
    }
    NSFileManager * manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:dirPath]) {
        [manager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:error];
        if (*error) {
            DLLOGD(@"CreateDirectory Error：%@ %@ %@ path: %@", [*error localizedDescription], [*error localizedFailureReason], [*error localizedRecoverySuggestion], dirPath);
            return NO;
        }
    }
    return YES;
    
}

+ (NSMutableDictionary *)parseResumeData:(NSData *)resumeData {
    DLLOGD(@"dlLog:parseResumeData");
    if (!resumeData) {
        DLLOGE(@"dlLog:parseResumeData--->resumeData is nil return");
        return nil;
    }
    NSMutableDictionary *resumeDictionary = nil;
    NSKeyedUnarchiver *arch = nil;
    @try {
        NSError *error = nil;
        NSKeyedUnarchiver *arch = nil;
        if (@available(iOS 11.0, *)) {
            arch = [[NSKeyedUnarchiver alloc] initForReadingFromData:resumeData error:&error];

            DLLOGD(@"bgDlLog:parseResumeData,@available(iOS 11.0, *),initForReadingFromData,error=%@", error.description);
            NSError *decodeError1;
            NSSet *typeSet = [NSSet setWithObjects:[NSDictionary class],[NSMutableData class],nil];
            resumeDictionary = [arch decodeTopLevelObjectOfClasses:typeSet forKey:@"NSKeyedArchiveRootObjectKey" error:&decodeError1];
            DLLOGD(@"bgDlLog:parseResumeData:decodeError1=%@", decodeError1.description);

        } else if (@available(iOS 9.0, *)) {
            arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:resumeData];
            resumeDictionary = [arch decodeTopLevelObjectForKey:@"NSKeyedArchiveRootObjectKey" error:&error];
            DLLOGD(@"bgDlLog:parseResumeData,@available(iOS 9.0, *),initForReadingFromData,error=%@", error.description);
        }
        if (!resumeDictionary) {
            resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:nil error:&error];
            DLLOGD(@"bgDlLog:parseResumeData,last try parser%@", error.description);
        }
        if (arch) {
            [arch finishDecoding];
        }
        
    } @catch (NSException *exception) {
        if (arch) {
            [arch finishDecoding];
        }
        DLLOGE(@"bgDlLog:parseResumeData:Caught %@: %@", [exception name], [exception reason]);
    }
    DLLOGD(@"bgDlLog:parseResumeData:resumeDictionary.count=%lu", (unsigned long)resumeDictionary.count);
    return resumeDictionary;
}

+ (BOOL)isTaskConfigValid:(TTDownloadTaskConfig *)obj {
    if (obj && obj.urlKey && obj.fileStorageName && obj.fileStorageDir
        && [[TTDownloadManager class] isArrayValid:obj.downloadSliceTaskConfigArray]
        && obj.sliceTotalNeedDownload == obj.downloadSliceTaskConfigArray.count) {
        for (TTDownloadSliceTaskConfig *slice in obj.downloadSliceTaskConfigArray) {
            if (![[TTDownloadManager class] isArrayValid:slice.subSliceInfoArray]) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

+ (int64_t)getHadDownloadedLength:(TTDownloadSliceTaskConfig *)sliceTaskConfig isReadLastSubSlice:(BOOL)isReadLastSubSlice {
    DLLOGD(@"dlLog:subSliceInfo>>>start");
    if (nil == sliceTaskConfig) {
        return 0L;
    }
    int64_t hadDownloadedLength = 0L;
    
    for (int i = 0; i < sliceTaskConfig.subSliceInfoArray.count; i++) {
        TTDownloadSubSliceInfo *subSlice = [sliceTaskConfig.subSliceInfoArray objectAtIndex:i];
        if (subSlice.rangeEnd > 0) {
            hadDownloadedLength += (subSlice.rangeEnd - subSlice.rangeStart);
        }
        DLLOGD(@"dlLog:subSliceInfo>>>sliceNber=%d,subSliceNumber=%lu,subName=%@,subSlice.range=%lld-%lld,downloadLength=%lld", subSlice.sliceNumber, (unsigned long)subSlice.subSliceNumber, subSlice.subSliceName, subSlice.rangeStart, subSlice.rangeEnd, subSlice.rangeEnd - subSlice.rangeStart);
    }
    
    if (isReadLastSubSlice) {
        TTDownloadSubSliceInfo *subSlice = [sliceTaskConfig.subSliceInfoArray lastObject];
        if (subSlice && subSlice.rangeEnd <= 0) {
            NSString *AppSupportPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
            NSString *sliceFullPath = [[AppSupportPath stringByAppendingPathComponent:[[TTDownloadManager class] calculateUrlMd5:sliceTaskConfig.urlKey]] stringByAppendingPathComponent:SLICE_DIR];
            NSString *subSliceFullPath = [sliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
            BOOL isDir = YES;
            if ([[NSFileManager defaultManager] fileExistsAtPath:subSliceFullPath isDirectory:&isDir]) {
                if (!isDir)
                {
                    NSError *error = nil;
                    NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:subSliceFullPath error:&error];
                    if (!error) {
                        DLLOGD(@"dlLog:getHadDownloadedLength:last sub slice size=%lld", fileAttributeDic.fileSize);
                        hadDownloadedLength += fileAttributeDic.fileSize;
                    } else {
                        DLLOGD(@"dlLog:getHadDownloadedLength:last sub slice size Error：%@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
                    }
                }
            }
            
        }
    }
    
    DLLOGD(@"dlLog:subSliceInfo>>>sliceNumber=debug %d,sliceTotalLength=%lld,hadDownloadedLength=%lld", sliceTaskConfig.sliceNumber, sliceTaskConfig.sliceTotalLength, hadDownloadedLength);
    DLLOGD(@"dlLog:subSliceInfo>>>end");
    return hadDownloadedLength;
}

+ (NSString *)calculateUrlMd5:(NSString *)url {
    if (nil == url) {
        return nil;
    }
    NSData* urlData = [url dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlMd5 = [[TTNetworkUtil md5Hex:urlData] lowercaseString];
    DLLOGD(@"dlLog:calculateUrlMd5:urlMd5=%@", urlMd5);
    return urlMd5;
}
/**
 *Sometimes createFileAtPath function failed to create new file if iOS version >= 13.0, so we use createNewFileAtPath instead.
 */
+ (BOOL)createNewFileAtPath:(NSString *)path error:(NSError **)error {
    if (!path) {
        return NO;
    }
    NSData* data = [@"" dataUsingEncoding:NSUTF8StringEncoding];

    if (![data writeToFile:path options:NSDataWritingFileProtectionNone error:error]) {
        return NO;
    }
    return YES;
}

+ (dispatch_source_t)createAndStartTimer:(TimeoutCallBack)onTimeoutCallBack {
    if (!onTimeoutCallBack) {
        return nil;
    }
    //Delay time for timer.
    NSTimeInterval delayTime       = 1.0f;
    //timer interval.
    NSTimeInterval timeInterval    = 1.0f;
    dispatch_queue_t queue         = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (!timer) {
        return nil;
    }
    //set start time.
    dispatch_time_t startDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
    //set timer.
    dispatch_source_set_timer(timer, startDelayTime, timeInterval * NSEC_PER_SEC, 0);

    dispatch_source_set_event_handler(timer, onTimeoutCallBack);
    //Start timer.
    dispatch_resume(timer);
    return timer;
}

+ (void)stopTimer:(dispatch_source_t)timer {
    if (timer) {
        dispatch_source_cancel(timer);
    }
}

+ (NSString *)getSubStringAfterKey:(NSString *)str key:(NSString *)key {
    if (!key || !str) {
        return nil;
    }
    NSString *subStr = nil;

    NSRange subRange = [str rangeOfString:key];
    if (subRange.location != NSNotFound) {
        subStr = [str substringFromIndex:subRange.location + subRange.length];
    }
    if (subStr.length == 0) {
        subStr = nil;
    }
    return subStr;
}

/**
     NSOrderedAscending  --->startDate < endDate
     NSOrderedSame         --->startDate = endDate
     NSOrderedDescending--->startDate > endDate
 */
+ (int)compareDate:(NSString*)startDate withDate:(NSString*)endDate {
    DLLOGD(@"optimizeSmallTest:startDate=%@,endData=%@", startDate, endDate);
    if (!startDate || !endDate) {
        return kDateCompareError;
    }
    int comparisonResult = kDateCompareError;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kDateFormat];
    NSDate *date1 = [formatter dateFromString:startDate];
    NSDate *date2 = [formatter dateFromString:endDate];
    if (!date1 || !date2) {
        return kDateCompareError;
    }
    NSComparisonResult result = [date1 compare:date2];
    switch (result) {
            //date2 > date1
        case NSOrderedAscending:
            comparisonResult = 1;
            break;
            //date2 < date1
        case NSOrderedDescending:
            comparisonResult = -1;
            break;
            //date2 = date1
        case NSOrderedSame:
            comparisonResult = 0;
            break;
        default:
            DLLOGD(@"erorr dates %@, %@", date1, date2);
            break;
    }
    return comparisonResult;
}

+ (NSString *)getFormatTime:(int64_t)tick {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    NSString *dateStr = nil;
    if (!tick) {
        dateStr = [dateFormatter stringFromDate:date];
    } else {
        NSDate *newDate = [date dateByAddingTimeInterval:tick];
        dateStr = [dateFormatter stringFromDate:newDate];
    }
    return dateStr;
}

+ (NSString *)getFullFilePath:(TTDownloadTaskConfig *)taskConfig {
    NSString *downloadTaskPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:taskConfig.fileStorageDir];
    return [downloadTaskPath stringByAppendingPathComponent:taskConfig.fileStorageName];
}

+ (BOOL)isDirectoryExist:(NSString *)directoryPath {
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir];
    return isExist && isDir;
}

+ (NSString *)arrayToNSString:(NSArray<NSError *> *)array {
    if (![TTDownloadManager isArrayValid:array]) {
        return nil;
    }
    NSString *str = nil;
    for (NSError *error in array) {
        str = str ? [NSString stringWithFormat:@"%@;%@", str, error.description] : error.description;
    }
    return str;
}

+ (BOOL)isFileExist:(NSString *)filePath {
    BOOL isDir = YES;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    return isExist && !isDir;
}

@end

NS_ASSUME_NONNULL_END

