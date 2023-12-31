
#import <TTNetworkManager/TTNetworkManager.h>

#import "TTDownloadCommonTools.h"
#import "TTDownloadManager.h"
#import "TTDownloadSliceForegroundTask.h"
#import "TTDownloadSliceTask.h"
#import "TTDownloadSliceTaskConfig.h"
#import "TTDownloadSubSliceBackgroundTask.h"
#import "TTDownloadTask.h"
#import "TTDownloadTaskConfig.h"
#import "TTDownloadTracker.h"
#import "TTDownloadTrackModel.h"
#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
#import "TTDownloadDynamicThrottle.h"
#import "TTObservation.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class TTDownloadSliceForegroundTask;

typedef void (^GetContentLengthCallbackBlock)(NSError *error, id obj, TTHttpResponse *response);

@interface TTDownloadTask()
@property (nonatomic, copy) NSArray *urlLists;
@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, assign) BOOL isResume;
@property (nonatomic, assign) BOOL isUseKey;

@property (nonatomic, assign) int8_t getLengthRetryMax;
@property (nonatomic, assign) BOOL isStartDownloadingFlag;
@property (nonatomic, assign) int64_t throttleNetSpeed;

@property (nonatomic, strong) DownloadResultNotification *resultNotification;
@property (nonatomic, strong) DownloadProgressInfo *progressInfo;

/**
 *Use it only in single thread
 */
@property (nonatomic, copy) NSString *cacheFullPath;
/**
*Use it only in single thread
*/
@property (nonatomic, copy) NSString *cacheBackupDir;
/**
 *Use it in multithreading environment.
 */
@property (atomic, assign) int32_t sliceCountHasDownloaded;
/**
 *Use it in multithreading environment.
 */
@property (atomic, assign) int32_t sliceCancelCount;
/**
 *Use it in multithreading environment.
 */
@property (atomic, assign) int32_t sliceDownloadFailedCount;
/**
 *Use it in multithreading environment.
 */
@property (atomic, strong) NSMutableArray<TTDownloadSliceTask *> *downloadSliceTaskArray;

@property (atomic, strong) NSMutableArray<TTDownloadSliceTask *> *downloadSliceBgTaskArray;

@property (atomic, strong) NSMutableArray<TTHttpResponse *> *httpResponseArray;
/**
 *Use it in multithreading environment.
 */
@property (atomic, assign) BOOL isDelete;
/**
 *Use it in multithreading environment.
 */
@property (atomic, strong) dispatch_semaphore_t getContentLengthSem;
/**
 *Use it in multithreading environment.
 */
@property (atomic, copy) NSString *fileMd5Value;

@property (nonatomic, assign) int64_t lastHadDownloadedLength;

@property (nonatomic, assign) int8_t sliceDownloadEndCount;

@property (atomic, strong) TTHttpTask *requestTask;

@property (atomic, assign) BOOL isAppBeActiveSemWait;

@property (atomic, assign) NetworkStatus currentNetType;

@property (atomic, assign) BOOL isTrackerEnable;
/**
 *If skip get content length,we don't know whether url support range or not.
 *So this parameter can set value about range.Default value is NO.If you want to set YES,it means
 *if url doesn't support range, maybe will download failed.So please ensure server support range before
 *you set this value to YES.
 */
@property (atomic, assign) BOOL isServerSupportRangeDefault;

#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
@property (atomic, strong) TTDownloadDynamicThrottle *dynamicThrottle;
@property (atomic, assign) BOOL isDynamicThrottleEnable;
#endif

@property (atomic, copy) NSString *etag;
@property (atomic, copy) NSString *lastModifiedTime;
@property (atomic, copy) NSString *maxAgeTime;

@property (atomic, assign) BOOL isCacheInvalid;
@property (atomic, assign) BOOL isContentLengthInvalid;
@property (atomic, assign) BOOL isCheckRangeFailed;

@property (atomic, assign) BOOL isRcvHeaderCallback;
@property (atomic, assign) BOOL isCheckCacheFromNet;
@property (atomic, copy) NSString *originEtag;
@property (atomic, copy) NSString *originMaxAge;

@property (atomic, assign) BOOL isMergingSlicesAtForeground;

@property (atomic, assign) BOOL isNoNetCancel;
@property (nonatomic, copy) TTMd5Callback TTMd5Callback;
@end

@interface TTDownloadTask()
@property (nonatomic, strong) dispatch_source_t timer;
@end

@implementation TTDownloadTask

- (id)initWithObjectDownloadTaskConfig:(TTDownloadTaskConfig *)downloadTaskConfig {
    self = [super init];
    if (self) {
        self.isResume                   = NO;
        self.isUseKey                   = NO;
        self.isStartDownloadingFlag     = NO;
        self.isCancelTask               = NO;
        self.isServerSupportAcceptRange = NO;
        self.contentTotalLength         = 0;
        self.needDownloadLengthTotal    = 0;
        self.sliceCancelCount           = 0;
        self.sliceCountHasDownloaded    = 0;
        self.sliceDownloadFailedCount   = 0;
        self.getLengthRetryMax          = GET_LENGTH_RETRY_MAX;
        self.taskConfig                 = (TTDownloadTaskConfig*)downloadTaskConfig;
        self.downloadSliceTaskArray     = [[NSMutableArray alloc] init];
        self.downloadSliceBgTaskArray   = [[NSMutableArray alloc] init];
        self.httpResponseArray          = [[NSMutableArray alloc] init];
        self.lastHadDownloadedLength    = 0;
        self.throttleNetSpeed           = 0;
        self.isWifiOnlyCancel           = NO;
        self.sliceDownloadEndCount      = 0;
        self.backgroundTaskCancelSem    = [self createSemWithRetry];
        self.dllog                      = [[TTDownloadLogLite alloc] init];
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:TTReachabilityChangedNotification
                                                 object:[TTReachability reachabilityForInternetConnection]];
}

- (void)addHttpResponse:(TTHttpResponse *)response {
    if (!response) {
        return;
    }
    @synchronized (self.httpResponseArray) {
        [self.httpResponseArray addObject:response];
    }
}

- (void)sliceCountHasDownloadedIncrease {
    @synchronized(self) {
        self.sliceCountHasDownloaded++;
        DLLOGD(@"dlLog8:sliceCountHasDownloadedIncrease:isBackground=%d,after self.sliceCountHasDownloaded=%d", self.isAppAtBackground,self.sliceCountHasDownloaded);
    }
}

- (void)sliceCancelCountIncrease {
    @synchronized(self) {
        self.sliceCancelCount++;
        DLLOGD(@"dlLog8:sliceCancelCountIncrease:isBackground=%d,after self.sliceCancelCount=%d", self.isAppAtBackground,self.sliceCancelCount);
    }
}

- (void)sliceDownloadFailedCountIncrease {
    @synchronized(self) {
        self.sliceDownloadFailedCount++;
        DLLOGD(@"dlLog8:sliceDownloadFailedCountIncrease:isBackground=%d,after self.sliceDownloadFailedCount=%d", self.isAppAtBackground,self.sliceDownloadFailedCount);
    }
}

- (void)addBackgroundDownloadedBytes:(int64_t)increaseBytes {
    if (self.isTrackerEnable) {
        [self.trackModel addBgDownloadBytes:increaseBytes];
    }
}

- (void)backgroundDownloadedCounterIncrease {
    @synchronized(self) {
        self.backgroundDownloadedCounter++;
        DLLOGD(@"dlLog8:sliceDownloadFailedCountIncrease:isBackground=%d,after self.backgroundDownloadedCounter=%d", self.isAppAtBackground,self.backgroundDownloadedCounter);
    }
}

- (void)backgroundFailedCounterIncrease {
    @synchronized(self) {
        self.backgroundFailedCounter++;
        DLLOGD(@"dlLog8:sliceDownloadFailedCountIncrease:isBackground=%d,after self.backgroundFailedCounter=%d", self.isAppAtBackground, self.backgroundFailedCounter);
    }
}

- (void)startTask:(NSString *)url
         urlLists:(NSArray *)urlLists
         fileName:(NSString *)fileName
         md5Value:(NSString *)md5Value
         isResume:(BOOL)isResume
         isUseKey:(BOOL)isUseKey
    progressBlock:(TTDownloadProgressBlock)progressBlock
      resultBlock:(TTDownloadResultBlock)resultBlock {
    self.isResume           = isResume;
    self.isUseKey           = isUseKey;
    self.urlKey             = url;
    self.urlLists           = urlLists;
    self.throttleNetSpeed   = [self getThrottleNetSpeed];
    self.fileName           = fileName;
    self.fileMd5Value       = md5Value;
    self.progressInfo       = [[DownloadProgressInfo alloc] init];
    self.resultNotification = [[DownloadResultNotification alloc] init];
    self.trackModel         = nil;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startTaskImpl];
    });
}

- (void)configTrackModel {
    if ([[TTDownloadManager shareInstance] getTrackModelFromDBForTask:self]) {
        [self refreshTrackModel:self.trackModel];
    } else {
        self.trackModel = [self createTrackModel];
    }

    self.trackModel.trackStatus = TRACK_NONE;
}

- (TTDownloadTrackModel *)createTrackModel {
    TTDownloadTrackModel *trackModel = [[TTDownloadTrackModel alloc] init];
    if (self.isUseKey) {
        trackModel.url = self.urlLists.firstObject;
    } else {
        trackModel.url = self.urlKey;
    }

    if (self.taskConfig) {
        trackModel.fileStorageDir = self.taskConfig.fileStorageDir;
        trackModel.md5Value = self.taskConfig.md5Value;
    } else {
        trackModel.fileStorageDir = [[TTDownloadManager class] calculateUrlMd5:self.urlKey];
        trackModel.md5Value = self.fileMd5Value;
    }

    trackModel.name = self.fileName;
    trackModel.downloadId = [TTDownloadTrackModel generateDownloadIdWithUrl:trackModel.url fileName:trackModel.name];

    trackModel.curRetryTime = 0;
    trackModel.curRestoreTime = 0;
    trackModel.curUrlRetryTime = 0;

    trackModel.downloadTime = 0;
    trackModel.gclTime = 0;
    trackModel.md5Time = 0;
    trackModel.sliceMergeTime = 0;

    trackModel.isBgDownloadEnable = NO;
    trackModel.bgDownloadTime = 0;
    trackModel.curBgDownloadBytes = 0;

    [self refreshTrackModel:trackModel];
    return trackModel;
}

- (void)refreshTrackModel:(TTDownloadTrackModel *)trackModel {
    trackModel.urlRetryCount = [self getUrlRetryTimes];
    trackModel.urlRetryInterval = [self getContentLengthWaitMaxInterval];
    trackModel.retryCount = [self getSliceMaxRetryTimes];
    trackModel.sliceCount = [self getSliceMaxNumber];
    trackModel.retryInterval = [self getRetryTimeoutInterval];
    trackModel.retryIntervalIncrement = [self getRetryTimeoutIntervalIncrement];
    trackModel.httpsDegradeEnable = [self getIsHttps2HttpFallback];

    trackModel.throttleNetSpeed = self.throttleNetSpeed;
    trackModel.isWifiOnly = [self getIsDownloadWifiOnly];

    trackModel.restoreCount = [self getRestoreTimesAutomatic];
    trackModel.isBgDownloadEnable = [self getIsBackgroundDownloadEnable];
}

- (BOOL)replaceScheme:(NSString *)url {
    NSRange range = [url rangeOfString:URL_SCHEME_HTTPS options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound && 0 == range.location) {
        NSString *str = [NSString stringWithFormat:@"%@", url];
        str = [str stringByReplacingCharactersInRange:range withString:URL_SCHEME_HTTP];
        DLLOGD(@"url=%p,str=%p,url=%@,str=%@", url, str, url, str);
        if (!self.urlLists) {
            self.urlLists = [NSArray array];
        }
        self.urlLists = [self.urlLists arrayByAddingObject:str];
        return YES;
    }
    return NO;
}

- (BOOL)httpsDegrade {
    if (self.isUseKey && (!self.urlLists || self.urlLists.count <= 0)) {
        return NO;
    }
    if (!self.isUseKey) {
        [self replaceScheme:self.urlKey];
    }

    if (self.urlLists) {
        for (NSString *url in self.urlLists) {
            [self replaceScheme:url];
        }
    }
    return YES;
}

- (BOOL)calculateContentLength {
    int degradeFlag = -1;
    if (self.urlLists) {
        degradeFlag = (int)self.urlLists.count - 1;
    }
    /**
     *If isFallback is YES,will append all of http url.
     */
    BOOL isFallback = [self getIsHttps2HttpFallback];
    if (isFallback) {
        [self httpsDegrade];
    }
    
    if (!self.isUseKey && [self getContentLengthWithRetry:self.urlKey]) {
        self.secondUrl = nil;
        self.trackModel.secondUrl = nil;
        return YES;
    } else {
        if (self.urlLists) {
            for (id obj in self.urlLists) {
                DLLOGD(@"dlLog:id obj in urlLists= %@", (NSString *)obj);
                
                if (self.isCancelTask) {
                    DLLOGD(@"cancel task while get content length");
                    return NO;
                }
                
                if ([self getContentLengthWithRetry:(NSString*)obj]) {
                    self.secondUrl = (NSString*)obj;

                    if (self.isTrackerEnable) {
                        self.trackModel.secondUrl = self.secondUrl;
                        NSUInteger index = [self.urlLists indexOfObject:obj];
                        if (index != NSNotFound && index > degradeFlag) {
                            self.trackModel.hasHttpsDegrade = YES;
                        }
                    }

                    return YES;
                }
            }
        }
    }
    DLLOGD(@"calculateContentLength:urlKey=%@,secondUrl=%@", self.urlKey, self.secondUrl);
    return NO;
}

- (BOOL)getContentLengthWithRetry:(NSString*)url {

    int8_t retryMax = [self getUrlRetryTimes];

    DLLOGD(@"dlLog:getContentLengthWithRetry,url=%@", url);
    if (nil == (self.getContentLengthSem = [self createSemWithRetry])) {
        DLLOGE(@"create sem failed");
        return NO;
    }
    DLLOGD(@"retryMax=%d", retryMax);
    while (retryMax-- > 0) {
        if (self.isCancelTask) {
            DLLOGD(@"cancel task while get content length");
            if (self.isDelete) {
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            }
            return NO;
        }

        [self.trackModel addCurUrlRetryTime:1];

        [self getContentLength:url];
        //If wait response time more than 65s,will stop wait and cancel task.
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, CONTENT_LENGTH_WAIT_TIME);
        dispatch_semaphore_wait(self.getContentLengthSem, timeout);
        if (self.isCancelTask) {
            DLLOGD(@"cancel task while get content length");
            if (self.isDelete) {
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            }
            return NO;
        }
        if (self.isContentLengthInvalid) {
            //content length != user's expection, may be hijacked
            DLLOGD(@"dlLog:getContentLengthWithRetry: content length fore check failed");
            return NO;
        }
        if (self.contentTotalLength > 0) {
            DLLOGD(@"dlLog:getContentLengthWithRetry:self.contentTotalLength=%lld", self.contentTotalLength);
            if ([self isRangeDownloadEnable]) {
                self.needDownloadLengthTotal = [self getRangeLength:self.userParameters.startOffset endRange:self.userParameters.endOffset];
            } else {
                self.needDownloadLengthTotal = self.contentTotalLength;
            }
            
            return YES;
        }
        
        if (self.requestTask) {
            [self.requestTask cancel];
        }
        
        if (retryMax > 0) {
            int64_t waitTime = [self getContentLengthWaitMaxInterval];
            [NSThread sleepForTimeInterval:waitTime];
        }
        
    }
    return NO;
}

- (void)getHeaderFields:(TTHttpResponse *)response {
    
    NSString *contentLengthString = nil;
    NSString *contentRange = (NSString *)[[response allHeaderFields] objectForKey:@"Content-Range"];
    if (contentRange) {
        contentLengthString = [TTDownloadManager getSubStringAfterKey:contentRange key:@"/"];
    } else {
        //If url doesn't support range,it just has Content-Length.
        contentLengthString = (NSString *)[[response allHeaderFields] objectForKey:@"Content-Length"];
    }

    int64_t contentLength = [contentLengthString longLongValue];
    if (contentLength > 0) {
        int64_t userExpectFileLength = [self.userParameters expectFileLength];
        if ([self isPreCheckFileLength] && userExpectFileLength > 0 && userExpectFileLength != contentLength) {
            //pre-check whether content length equals to user's expected file length
            self.isContentLengthInvalid = YES;
            DLLOGD(@"+++getHeaderFields: content length pre-check failed!");
            return;
        }
        self.contentTotalLength = contentLength;
        if ([self isRangeDownloadEnable]) {
            self.trackModel.totalBytes = [self getRangeLength:self.userParameters.startOffset endRange:self.userParameters.endOffset];
        } else {
            self.trackModel.totalBytes = self.contentTotalLength;
        }
        
        if (response.statusCode == 206) {
            self.isServerSupportAcceptRange = YES;
        }
    }
    
    self.lastModifiedTime = (NSString *)[[response allHeaderFields] objectForKey:@"last-modified"];
    self.etag = (NSString *)[[response allHeaderFields] objectForKey:@"etag"];
    self.maxAgeTime = nil;

    if ([self getIsCheckCacheValid]) {
        //Cache-Control
        NSString *maxAgeStr = (NSString *)[[response allHeaderFields] objectForKey:@"Cache-Control"];
        NSString *value = [TTDownloadManager getSubStringAfterKey:maxAgeStr key:@"max-age="];
        if (value) {
            int64_t maxAge = [value longLongValue];
            self.maxAgeTime = [TTDownloadManager getFormatTime:maxAge];
        }

        [self checkCache];
    }
}

- (BOOL)checkCacheInHeaderCallback {

    if (!self.lastModifiedTime || !self.originExtendConfig.lastModifiedTime) {
        return NO;
    }
    DLLOGD(@"optimizeSmallTest:start compare last_modify,curr=%@,old=%@", self.lastModifiedTime, self.originExtendConfig.lastModifiedTime);
    if (![TTDownloadManager compareDate:self.lastModifiedTime withDate:self.originExtendConfig.lastModifiedTime]) {
        return YES;
    } else if (self.etag
               && (NSOrderedSame == [self.etag caseInsensitiveCompare:self.originExtendConfig.etag])) {
        return YES;
    }

    return NO;
}


- (void)checkCache {
    /**
     *New request doesn't check.
     */
    if (!self.taskConfig) {
        return;
    }
    
    if (self.maxAgeTime) {
        self.taskConfig.extendConfig.maxAgeTime = self.maxAgeTime;
        //update maxAgeTime
        NSError *error = nil;
        if (![[TTDownloadManager shareInstance] updateExtendConfigSync:self.taskConfig error:&error]) {
            DLLOGD(@"error=%@", error);
        }
    }
    
    /**
     *If lastModifiedTime is nil,we can't check cache. So we will delete task default.And send new request.
     *This action can be controlled by isRetainCacheIfCheckFailed.
     */
    if (!self.lastModifiedTime || !self.taskConfig.extendConfig.lastModifiedTime) {
        if (![self getIsRetainCacheIfCheckFailed]) {
            self.isCacheInvalid = YES;
            return;
        }
    }
    
    if (![TTDownloadManager compareDate:self.lastModifiedTime withDate:self.taskConfig.extendConfig.lastModifiedTime]) {
        return;
    } else if (self.etag
               && (NSOrderedSame == [self.etag caseInsensitiveCompare:self.taskConfig.extendConfig.etag])) {
        return;
    }

    self.isCacheInvalid = YES;
}

- (NSDictionary *)setRangeAndMergeUserHeader {
    //Set range.
    NSMutableDictionary *headerField = [NSMutableDictionary dictionary];
    [headerField setObject:@"bytes=0-0" forKey:@"Range"];
    
    if (self.userParameters.httpHeaders && self.userParameters.httpHeaders.count > 0) {
        [self.userParameters.httpHeaders removeObjectForKey:@"Range"];
        [headerField addEntriesFromDictionary:self.userParameters.httpHeaders];
    }
    DLLOGD(@"headerField=%@", headerField);
    return headerField;
}

- (void)getContentLength:(NSString*)url {
    DLLOGD(@"getContentLength:url=%@", url);
    dispatch_semaphore_t holdSem = self.getContentLengthSem;
    __weak __typeof(self)weakSelf = self;
    /**
     *The callback that report the result of get content length.
     */
    GetContentLengthCallbackBlock callback = ^(NSError *error, id obj, TTHttpResponse *response) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (nil == strongSelf) {
            return;
        }
        if (!error && response) {
            [strongSelf getHeaderFields:response];
            
            if (!strongSelf.fileMd5Value) {
                //Need get md5 from server.But now it doesn't implement.
                strongSelf.fileMd5Value = nil;
            }
        } else if (error && response) {
            [strongSelf addHttpResponse:response];
            DLLOGD(@"CreateDirectory Error：%@ %@ %@ ", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
        }

        strongSelf.requestTask = nil;
        
        DLLOGD(@"dlLog:Content-Length=%lld,Accept-Ranges=%d,fileMd5=%@", strongSelf.contentTotalLength, strongSelf.isServerSupportAcceptRange, strongSelf.fileMd5Value);
        if (nil != strongSelf.getContentLengthSem) {
            dispatch_semaphore_signal(holdSem);
        }
    };
    
    NSDictionary *header = [self setRangeAndMergeUserHeader];
    NSString *method = @"GET";
    self.requestTask =
        [[TTNetworkManager shareInstance] requestForBinaryWithResponse:url
                                                                params:nil
                                                                method:method
                                                      needCommonParams:[self getIsCommonParamEnable]
                                                           headerField:header
                                                       enableHttpCache:NO
                                                            autoResume:NO
                                                     requestSerializer:nil
                                                    responseSerializer:nil
                                                              progress:nil
                                                              callback:callback
                                                  callbackInMainThread:NO];
    if (self.requestTask) {
        if ([self getTTNetProtectTimeout] > 0) {
            self.requestTask.protectTimeout = [self getTTNetProtectTimeout];
            DLLOGD(@"setTimeout:self.task.protectTimeout=%f", self.requestTask.protectTimeout);
        }
        if ([self getTTNetRcvHeaderTimeout] > 0) {
            self.requestTask.recvHeaderTimeout = [self getTTNetRcvHeaderTimeout];
            DLLOGD(@"setTimeout: self.task.recvHeaderTimeout=%f", self.requestTask.recvHeaderTimeout);
        }
        if ([self getTTNetReadDataTimeout] > 0) {
            self.requestTask.readDataTimeout = [self getTTNetReadDataTimeout];
            DLLOGD(@"setTimeout:self.task.readDataTimeout=%f", self.requestTask.readDataTimeout);
        }
        if ([self getTTNetRequestTimeout] > 0) {
            self.requestTask.timeoutInterval = [self getTTNetRequestTimeout];
            DLLOGD(@"setTimeout:self.task.timeoutInterval=%f", self.requestTask.timeoutInterval);
        }
        
        [self.requestTask resume];
        
        if (self.isCancelTask) {
            [self.requestTask cancel];
        }
    }
}

- (int16_t)getTTNetRequestTimeout {
    int16_t value = [[[TTDownloadManager shareInstance] getTncConfig] getTTNetRequestTimeout];
    if (value > 0) {
        return value;
    } else {
        return self.userParameters.ttnetRequestTimeout;
    }
}

- (int16_t)getTTNetReadDataTimeout {
    int16_t value = [[[TTDownloadManager shareInstance] getTncConfig] getTTNetReadDataTimeout];
    if (value > 0) {
        return value;
    } else {
        return self.userParameters.ttnetReadDataTimeout;
    }
}

- (int16_t)getTTNetRcvHeaderTimeout {
    int16_t value = [[[TTDownloadManager shareInstance] getTncConfig] getTTNetRcvHeaderTimeout];
    if (value > 0) {
        return value;
    } else {
        return self.userParameters.ttnetRcvHeaderTimeout;
    }
}

- (int16_t)getTTNetProtectTimeout {
    int16_t value = [[[TTDownloadManager shareInstance] getTncConfig] getTTNetProtectTimeout];
    if (value > 0) {
        return value;
    } else {
        return self.userParameters.ttnetProtectTimeout;
    }
}

- (void)updateContentLength:(TTHttpResponse *)response {
    NSString *contentLengthString = nil;
    NSString *contentRange = (NSString *)[[response allHeaderFields] objectForKey:@"Content-Range"];
    if (contentRange) {
        contentLengthString = [TTDownloadManager getSubStringAfterKey:contentRange key:@"/"];
    } else {
        //If url doesn't support range,it just has Content-Length.
        contentLengthString = (NSString *)[[response allHeaderFields] objectForKey:@"Content-Length"];
    }

    int64_t contentLength = [contentLengthString longLongValue];
    if (contentLength > 0) {
        int64_t userExpectFileLength = [self.userParameters expectFileLength];
        if ([self isPreCheckFileLength] && userExpectFileLength > 0 && userExpectFileLength != contentLength) {
            //pre-check whether content length equals to user's expected file length
            self.isContentLengthInvalid = YES;
            DLLOGD(@"+++getHeaderFields: content length pre-check failed!");
            return;
        }
        self.contentTotalLength = contentLength;
        
        [self updateSliceConfig];
        
        self.trackModel.totalBytes = self.contentTotalLength;
    }
}

- (NSString *)getMaxAgeTiming:(TTHttpResponse *)response {
    //Cache-Control
    NSString *maxAgeStr = (NSString *)[[response allHeaderFields] objectForKey:@"Cache-Control"];
    NSString *value = [TTDownloadManager getSubStringAfterKey:maxAgeStr key:@"max-age="];
    
    if (value) {
        int64_t maxAge = [value longLongValue];
        return [TTDownloadManager getFormatTime:maxAge];
    } else {
        return nil;
    }
}

- (void)updateSupportRange {
    self.isServerSupportAcceptRange = YES;
    self.taskConfig.isSupportRange = YES;
    [[TTDownloadManager shareInstance] updateTaskConfigInDicLock:self.taskConfig];
}

- (BOOL)parserHeader:(TTHttpResponse *)response {
    DLLOGD(@"optimizeSmallTest:header code=%ld", (long)response.statusCode);
    BOOL isRcvHeaderCallback = NO;
    if (self.isCheckCacheFromNet) {
        if (response.statusCode == 304) {
            /**
             *Cache valid case
             */
            self.maxAgeTime = [self getMaxAgeTiming:response];
            self.lastModifiedTime = self.originExtendConfig.lastModifiedTime;
            self.etag = self.originExtendConfig.etag;
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
            /**
             *Cache invalid and receive new data.Set isCheckCacheFromNet to NO.
             */
            self.isCheckCacheFromNet = NO;
            self.originExtendConfig = nil;
            
            [self updateContentLength:response];
            if (response.statusCode == 206) {
                [self updateSupportRange];
            }
            
            self.maxAgeTime = [self getMaxAgeTiming:response];
            self.lastModifiedTime = (NSString *)[[response allHeaderFields] objectForKey:@"last-modified"];
            self.etag = (NSString *)[[response allHeaderFields] objectForKey:@"etag"];
            /**
             *When start background task, we must receive header information.
             */
            isRcvHeaderCallback = YES;
            
        } else {
            /**
             *Error case.First we must restore origin config.
             */
            self.maxAgeTime = self.originExtendConfig.maxAgeTime;
            self.lastModifiedTime = self.originExtendConfig.lastModifiedTime;
            self.etag = self.originExtendConfig.etag;
        }
        
        DLLOGD(@"optimizeSmallTest:maxAge=%@,lastModified=%@,etag=%@", self.maxAgeTime, self.lastModifiedTime, self.etag);
        [self.taskConfig.extendConfig updateConfig:_maxAgeTime
                                      lastModified:_lastModifiedTime
                                              etag:_etag
                                 startDownloadTime:_originExtendConfig.startDownloadTime
                                       componentId:_originExtendConfig.componentId];

        NSError *error1 = nil;
        if (![[TTDownloadManager shareInstance] updateExtendConfigSync:self.taskConfig error:&error1]) {
            DLLOGD(@"error=%@", error1);
        }
    } else {
        /**
         *New task case
         */
        if (response.statusCode >= 200 && response.statusCode < 300) {
            
            [self updateContentLength:response];
            if (self.isContentLengthInvalid) {
                DLLOGD(@"Content-Length mismatch with user's expectation");
                return NO;
            }
            if (response.statusCode == 206) {
                [self updateSupportRange];
            }
            
            if (![self rangeCheck:self.isServerSupportAcceptRange
                    contentLength:self.contentTotalLength
                      startOffset:self.userParameters.startOffset
                        endOffset:self.userParameters.endOffset]) {
                self.isCheckRangeFailed = YES;
                return NO;
            }
            
            self.maxAgeTime = [self getMaxAgeTiming:response];
            self.lastModifiedTime = (NSString *)[[response allHeaderFields] objectForKey:@"last-modified"];
            self.etag = (NSString *)[[response allHeaderFields] objectForKey:@"etag"];
            
            DLLOGD(@"optimizeSmallTest:maxAge=%@,lastModified=%@,etag=%@", _maxAgeTime, _lastModifiedTime, _etag);
            [self.taskConfig.extendConfig updateConfig:_maxAgeTime
                                          lastModified:_lastModifiedTime
                                                  etag:_etag
                                     startDownloadTime:_taskConfig.extendConfig.startDownloadTime
                                           componentId:_taskConfig.extendConfig.componentId];
            
            //update
            NSError *error = nil;
            if (![[TTDownloadManager shareInstance] updateExtendConfigSync:self.taskConfig error:&error]) {
                DLLOGD(@"error=%@", error);
            }
            
            /**
            *When start background task, we must receive header information.
            */
            isRcvHeaderCallback = YES;
        }
    }
    self.isRcvHeaderCallback = isRcvHeaderCallback;
    return YES;
}

- (void)updateSliceConfig {
    if (self.taskConfig.sliceTotalNeedDownload == 1) {
        TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray firstObject];
        if (sliceConfig && (self.contentTotalLength > 0)) {
            if ([self isRangeDownloadEnable]) {
                sliceConfig.sliceTotalLength = [self getRangeLength:self.userParameters.startOffset endRange:self.userParameters.endOffset];
            } else {
                sliceConfig.sliceTotalLength = self.contentTotalLength;
            }
            NSError *error = nil;
            if (![[TTDownloadManager shareInstance] updateSliceConfig:sliceConfig taskConfig:self.taskConfig error:&error]) {
                DLLOGD(@"error=%@", error);
            }
        }
    }
}

- (BOOL)isRangeDownloadEnable {
    return ((self.userParameters.startOffset > 0) || (self.userParameters.endOffset > 0));
}

- (int64_t)getRangeLength:(int64_t)startRange endRange:(int64_t)endRange {
    int64_t length = 0L;
    if (startRange >= 0 && endRange >= 0) {
        length = endRange - startRange + 1L;
    } else if (startRange == -1L && endRange >= 0L) {
        length = endRange + 1L;
    } else if (startRange >= 0L && endRange == -1L) {
        length = self.contentTotalLength - startRange;
    } else {
        length = self.contentTotalLength;
    }
    return length;
}

- (BOOL)rangeCheck:(BOOL)isSupportRange
     contentLength:(int64_t)contentLength
       startOffset:(int64_t)startOffset
         endOffset:(int64_t)endOffset {
    DLLOGD(@"isSupportRange=%d,contentLength=%lld,startOffset=%lld,endOffset=%lld", isSupportRange, contentLength, startOffset, endOffset);
    if (![self isRangeDownloadEnable]) {
        return YES;
    }
    
    if (!isSupportRange) {
        DLLOGD(@"ragne task must support range");
        return NO;
    }
    
    if (((endOffset >= 0L) && ((endOffset + 1L) > contentLength))
        || ((startOffset >= 0L) && ((startOffset + 1L) > contentLength))) {
        DLLOGD(@"check range failed 1");
        return NO;
    } else if ((startOffset >= 0) && (endOffset >= 0) && (startOffset > endOffset)) {
        DLLOGD(@"check range failed 2");
        return NO;
    }

    return YES;
}

- (void)countSliceNumberAndSize {
    self.taskConfig.sliceTotalNeedDownload = 1;
    if ([self isRangeDownloadEnable]) {
        self.firstSliceNeedDownloadLength = [self getRangeLength:self.userParameters.startOffset endRange:self.userParameters.endOffset];
    } else {
        self.firstSliceNeedDownloadLength = self.contentTotalLength;
    }
    
    
    BOOL isSliced = [self getIsSliced];

    if (self.throttleNetSpeed == 0 && self.isServerSupportAcceptRange && isSliced && !self.isSkipGetContentLength) {
        int64_t allowDivisionSize = [self getMinDevisionSize];
        NSInteger sliceTotal = [self getSliceMaxNumber];
        self.taskConfig.sliceTotalNeedDownload = sliceTotal;
        
        int64_t length = self.contentTotalLength;
        if ([self isRangeDownloadEnable]) {
            length = [self getRangeLength:self.userParameters.startOffset
                                 endRange:self.userParameters.endOffset];
        }

        if (length > allowDivisionSize) {
            if (length % sliceTotal == 0) {
                self.firstSliceNeedDownloadLength = floorf(length / sliceTotal);
            } else {
                self.firstSliceNeedDownloadLength = floorf(length / sliceTotal) + 1;
            }
        }
    }

    DLLOGD(@"dlLog:self.sliceTotalNeedDownload=%d,self.firstSliceNeedDownloadLength=%lld", self.taskConfig.sliceTotalNeedDownload, self.firstSliceNeedDownloadLength);
}

- (int64_t)getStartOffset {
    if (self.userParameters.startOffset < 0L) {
        return 0L;
    }
    return self.userParameters.startOffset;
}

- (void)fillSliceInfo {
    [self countSliceNumberAndSize];
    DLLOGD(@"self.throttleNetSpeed=%lld,self.taskConfig.sliceTotalNeedDownload=%hhd", self.throttleNetSpeed, self.taskConfig.sliceTotalNeedDownload);
    for (int i = 0; i < self.taskConfig.sliceTotalNeedDownload; i++) {
        TTDownloadSliceTaskConfig *sliceTaskConfig = [[TTDownloadSliceTaskConfig alloc] init];
        sliceTaskConfig.urlKey                     = self.urlKey;
        sliceTaskConfig.secondUrl                  = self.secondUrl;
        sliceTaskConfig.sliceNumber                = i + 1;
        sliceTaskConfig.throttleNetSpeed           = ceilf(self.throttleNetSpeed / self.taskConfig.sliceTotalNeedDownload);
        sliceTaskConfig.hasDownloadedLength        = 0;
        DLLOGD(@"dlLog:debug hasDownloadedLength 5 = %ld", 0L);
        if (self.taskConfig.sliceTotalNeedDownload > 1 && (i + 1 == self.taskConfig.sliceTotalNeedDownload)) {
            if ([self isRangeDownloadEnable]) {
                int64_t length = [self getRangeLength:self.userParameters.startOffset
                                             endRange:self.userParameters.endOffset];
                sliceTaskConfig.sliceTotalLength   = length - (self.firstSliceNeedDownloadLength * i);
            } else {
                sliceTaskConfig.sliceTotalLength   = self.contentTotalLength - (self.firstSliceNeedDownloadLength * i);
            }
        } else {
            sliceTaskConfig.sliceTotalLength       = self.firstSliceNeedDownloadLength;
        }
        
        if ([self isRangeDownloadEnable]) {
            sliceTaskConfig.startByte = [self getStartOffset] + self.firstSliceNeedDownloadLength * i;
        } else {
            sliceTaskConfig.startByte = self.firstSliceNeedDownloadLength * i;
        }
        sliceTaskConfig.endByte = sliceTaskConfig.startByte + sliceTaskConfig.sliceTotalLength;

        //Create subSlice.
        TTDownloadSubSliceInfo *subSlice = [[TTDownloadSubSliceInfo alloc] init];
        subSlice.sliceNumber = sliceTaskConfig.sliceNumber;

        subSlice.subSliceNumber   = 0;
        if (self.isServerSupportAcceptRange) {
            subSlice.subSliceName = [NSString stringWithFormat:@"%d-%lu", subSlice.sliceNumber, (unsigned long)subSlice.subSliceNumber];
        } else {
            subSlice.subSliceName = self.taskConfig.fileStorageName;
        }
        subSlice.subSliceFullPath = [self.downloadTaskSliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
        subSlice.rangeStart       = sliceTaskConfig.startByte;
        //will update rangeEnd by real file size.
        subSlice.rangeEnd         = -1;
        subSlice.fileStorageDir   = self.taskConfig.fileStorageDir;
        [sliceTaskConfig.subSliceInfoArray addObject:subSlice];

        [self.taskConfig.downloadSliceTaskConfigArray addObject:sliceTaskConfig];
        DLLOGD(@"dlLog:fillSliceInfo:Number=%d,urlKey=%@,secondUrl=%@", sliceTaskConfig.sliceNumber, sliceTaskConfig.urlKey, sliceTaskConfig.secondUrl);
    }
}

- (BOOL)createDownloadTaskConfig {
    self.taskConfig                 = [[TTDownloadTaskConfig alloc] init];
    self.taskConfig.userParam       = self.userParameters;
    self.taskConfig.urlKey          = self.urlKey;
    self.taskConfig.secondUrl       = self.secondUrl;
    self.taskConfig.fileStorageName = self.fileName;
    self.taskConfig.fileStorageDir  = [[TTDownloadManager class] calculateUrlMd5:self.urlKey];
    self.taskConfig.md5Value        = self.fileMd5Value;
    self.taskConfig.downloadStatus  = FAILED;
    
    self.taskConfig.restoreTimesAuto = [self getRestoreTimesAutomatic];
    DLLOGD(@"dlLog:self.taskConfig.restoreTimesAuto=%d", self.taskConfig.restoreTimesAuto);
    self.taskConfig.versionType     = ADD_SUB_SLICE_TABLE_VERSION;
    self.taskConfig.isSupportRange  = self.isServerSupportAcceptRange;
    
    TTDownloadTaskExtendConfig *extendConfig = [[TTDownloadTaskExtendConfig alloc] init];
    extendConfig.etag = self.etag;
    extendConfig.lastModifiedTime = self.lastModifiedTime;
    extendConfig.maxAgeTime = self.maxAgeTime;
    extendConfig.startDownloadTime = [TTDownloadManager getFormatTime:0];
    extendConfig.componentId = _userParameters.componentId;
    self.taskConfig.extendConfig = extendConfig;

    [self fillSliceInfo];

    if (self.isTrackerEnable) {
        self.trackModel.fileStorageDir = self.taskConfig.fileStorageDir;
        self.trackModel.md5Value = self.taskConfig.md5Value;
        self.trackModel.isWifiOnly = [self getIsDownloadWifiOnly];
    }
    
    NSError *error = nil;
    BOOL ret = [[TTDownloadManager shareInstance] addDownloadTaskConfig:self.taskConfig error:&error];
    if (!ret) {
        [self.dllog addDownloadLog:nil error:error];
    }
    return ret;
}

- (BOOL)createRestoreFlags {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *flagFilePath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:RESTORE_MODE_FLAG_NAME];

    if (self.taskConfig.restoreTimesAuto > 0) {
        if (![fileManager fileExistsAtPath:flagFilePath]) {
            NSError *error = nil;
            if (![TTDownloadManager createNewFileAtPath:flagFilePath error:&error]) {
                DLLOGE(@"error=%@", error.description);
                [self.dllog addDownloadLog:nil error:error];
                return NO;
            }
        }
    }
    return YES;
}

- (void)getFullPath {
    NSString *md5 = [[TTDownloadManager class] calculateUrlMd5:self.urlKey];
    self.downloadTaskFullPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:md5];
    self.downloadTaskSliceFullPath = [self.downloadTaskFullPath stringByAppendingPathComponent:SLICE_DIR];
    
    self.cacheBackupDir = [[TTDownloadManager shareInstance].cachePath stringByAppendingPathComponent:kTTDownloaderCheckCacheBackupDir];
    
    self.cacheFullPath = [self.cacheBackupDir stringByAppendingPathComponent:md5];
    
    DLLOGD(@"downloadTaskFullPath=%@,downloadTaskSliceFullPath=%@", self.downloadTaskFullPath, self.downloadTaskSliceFullPath);
}

- (BOOL)createDownloadTaskDir {
    //Create download directory.
    NSError *error = nil;
    if (![[TTDownloadManager class] createDir:self.downloadTaskFullPath error:&error]) {
        [self.dllog addDownloadLog:nil error:error];
        return NO;
    }
    //Create sub directory for sub slice.
    error = nil;
    if (![[TTDownloadManager class] createDir:self.downloadTaskSliceFullPath error:&error]) {
        [self.dllog addDownloadLog:nil error:error];
        return NO;
    }
    [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:self.downloadTaskFullPath];
    return YES;
}

- (void)fillSliceThrottleNetSpeed:(int)realSliceCount {
    /**
     *Calculate every slice's throttle net speed.
     */
    int64_t realSpeed;
    if (realSliceCount > 0) {
        realSpeed = ceilf(self.throttleNetSpeed / realSliceCount);
    } else {
        realSpeed = 0;
    }
    for (TTDownloadSliceTaskConfig *sliceInfo in self.taskConfig.downloadSliceTaskConfigArray) {
        if (INIT == sliceInfo.sliceStatus) {
            sliceInfo.throttleNetSpeed = realSpeed;
        }
    }
}

- (BOOL)fillSliceInfoByRealFileSize:(BOOL)isBackgroundTask {
    NSString *downloadTaskPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:self.taskConfig.fileStorageDir];
    self.realSliceCount = 0;
    self.needDownloadLengthTotal = 0L;
    self.contentTotalLength = 0L;

    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath]) {
        NSString *downloadTaskPath2 = [[TTDownloadManager shareInstance].cachePath stringByAppendingPathComponent:self.taskConfig.fileStorageDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath2]) {
            [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2 toPath:downloadTaskPath overwrite:YES error:nil];
            [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
        }
    }

    if (![[TTDownloadManager class] isArrayValid:self.taskConfig.downloadSliceTaskConfigArray]) {
        return NO;
    }
    for (TTDownloadSliceTaskConfig *slice in self.taskConfig.downloadSliceTaskConfigArray) {
        if (![slice updateSliceConfig:self isBackgroundTask:isBackgroundTask]) {
            DLLOGE(@"updateSliceConfig failed,return;");
            return NO;
        }
    }
    DLLOGD(@"dlLog:fillSliceInfoByRealFileSize:needDownloadLengthTotal=%lld", self.needDownloadLengthTotal);
    /**
     * Calculate every slice's throttle net speed.
     */
    [self fillSliceThrottleNetSpeed:self.realSliceCount];
    /**
     *Record the slice count that had downloaded.
     */
    self.sliceDownloadEndCount = self.sliceCountHasDownloaded;
    return YES;
}

- (BOOL)createSliceDownloadTask {
    for (TTDownloadSliceTaskConfig *slice in self.taskConfig.downloadSliceTaskConfigArray) {
        slice.isCancel       = NO;
        slice.retryTimes = [self getSliceMaxRetryTimes];
        slice.retryTimesMax  = slice.retryTimes;
        
        TTDownloadSliceTask *sliceTask = [[TTDownloadSliceForegroundTask alloc] initWhithSliceConfig:slice downloadTask:self];
        DLLOGD(@"dlLog:debug3:new sliceTask 1 addr=%p", sliceTask);
        @synchronized (self.downloadSliceTaskArray) {
            [self.downloadSliceTaskArray addObject:sliceTask];
        }
    }
    /**
     * Check self.downloadSliceTaskArray
     */
    if (![[TTDownloadManager class] isArrayValid:self.downloadSliceTaskArray]
        && self.taskConfig.sliceTotalNeedDownload != self.downloadSliceTaskArray.count) {
        return NO;
    }
    return YES;
}

- (void)updateDownloadTaskStatus:(DownloadStatus)status {
    if (status < INIT || status > MAX) {
        DLLOGD(@"status error");
        return;
    }
    if (self.taskConfig) {
        self.taskConfig.downloadStatus = status;
    } else {
        DLLOGD(@"taskConfig is nil,can't update status");
        return;
    }
    
    if (DOWNLOADING == status) {
        [[TTDownloadManager shareInstance] updateDownloadingTaskInDicLock:self];
    }
    NSError *error = nil;
    if (![[TTDownloadManager shareInstance] updateDownloadTaskConfig:self.urlKey status:status error:&error]) {
        DLLOGD(@"error=%@", error);
    }
}

- (BOOL)checkDownloadFinished {
    BOOL ret = NO;
    DLLOGD(@"sliceHasDownload=%d,sliceCancel=%d,sliceFailed=%d,sliceTotal=%d", self.sliceCountHasDownloaded, self.sliceCancelCount, self.sliceDownloadFailedCount, self.taskConfig.sliceTotalNeedDownload);

    if (self.sliceCountHasDownloaded >= self.taskConfig.sliceTotalNeedDownload) {
        DLLOGD(@"dlLog:getSliceCountHasDownloaded] >= self.sliceTotalNeedDownload");
        //Update progress if download completely.
        [self onceRunInTimer];
        
        /**
         *Try to delete cache file if exist.
         */
        [[TTDownloadManager shareInstance] deleteFile:self.cacheFullPath];

        DLLOGD(@"fg try to mergeAllSlice");
        self.isMergingSlicesAtForeground = YES;
        StatusCode code = [self mergeAllSlice];
        DLLOGD(@"mergeAllSlice code=%ld", (long)code);

        ret = YES;
        switch (code) {
            case ERROR_MERGE_SUCCESS:
                [self updateDownloadTaskStatus:DOWNLOADED];
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:NO isDeleteMergeFile:NO isDeleteSliceFile:YES];
                [self asyncStatusReport:DOWNLOAD_SUCCESS];
                [self processFinishEventIsSaveDB:YES];
                DLLOGD(@"dlLog:downlaod success");
                break;
            case ERROR_NO_RANGE_SLICE_NO_ONE:
            case ERROR_SKIP_GET_CONTENT_LEN_LAST_STATUS_ERROR:
            case ERROR_MERGE_SLICE_SIZE_ERROR:
            case ERROR_RANGE_TASK_NOT_SUPPORT_RANGE:
            case ERROR_CHECK_LAST_SUB_SLICE_SIZE_FAILED:
            case ERROR_TTMD5_CHECK_FAILED:
            case ERROR_MD5_CHECK_FAILED_WHILE_MERGE:
            case ERROR_DOWNLOADED_FILE_MISS:
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
                [self updateDownloadTaskStatus:DELETED];
                [self asyncStatusReport:code];
                BOOL isSaveDB = YES;
                if (code == ERROR_MERGE_SLICE_SIZE_ERROR) {
                    isSaveDB = NO;
                }
                [self processFailEventWithCode:code failMsg:@"mergeAllSlice failed" isSaveDB:isSaveDB];
                break;
            default:
                [self updateDownloadTaskStatus:FAILED];
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:NO isDeleteMergeFile:YES isDeleteSliceFile:NO];
                [self processFailEventWithCode:code failMsg:@"mergeAllSlice failed" isSaveDB:YES];
                [self asyncStatusReport:code];
                DLLOGD(@"dlLog:mergeAllSlice failed");
                break;
        }
    } else if (self.sliceDownloadFailedCount > 0 && ((self.sliceDownloadFailedCount + self.sliceCountHasDownloaded) >= self.taskConfig.sliceTotalNeedDownload)) {
        if (self.isCheckCacheFromNet) {
            DLLOGD(@"optimizeSmallTest:check failed return cache");
            NSError *error = nil;
            if ([TTDownloadManager moveItemAtPath:self.cacheFullPath toPath:self.downloadTaskFullPath overwrite:YES error:&error]) {
                [self updateDownloadTaskStatus:DOWNLOADED];
                if ([self isIgnoreMaxAgeCheck]) {
                    [self asyncStatusReport:ERROR_FILE_DOWNLOADED];
                } else {
                    [self asyncStatusReport:ERROR_CHECK_CACHE_FAILED];
                }
            } else {
                if (error) {
                    DLLOGD(@"error=%@", error);
                }
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
                [self updateDownloadTaskStatus:DELETED];
                [self asyncStatusReport:ERROR_CHECK_CACHE_FAILED];
            }
        } else {
            /**
             *If download failed,will retry to restore task.
             */
            if ([self tryRestoreTask]) {
                DLLOGD(@"dlLog:restore times > 0 will restore");
                return NO;
            }

            [self updateDownloadTaskStatus:FAILED];
            [self processFailEventWithCode:ERROR_DOWNLOAD_FAILED failMsg:@"getSliceDownloadFailedCount>0" isSaveDB:YES];
            [self asyncStatusReport:ERROR_DOWNLOAD_FAILED];
        }
        ret = YES;
        DLLOGD(@"dlLog:getSliceDownloadFailedCount>0");
    } else if (self.sliceCancelCount > 0 && ((self.sliceCancelCount + self.sliceDownloadFailedCount + self.sliceCountHasDownloaded) >= self.taskConfig.sliceTotalNeedDownload)) {

        if (self.isDelete) {
            self.isDelete = NO;
            BOOL isDeleteSuccess = [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            if (isDeleteSuccess) {
                [self updateDownloadTaskStatus:DELETED];
                [self asyncStatusReport:ERROR_DELETE_SUCCESS];
            } else {
                [self updateDownloadTaskStatus:FAILED];
                [self asyncStatusReport:ERROR_DELETE_FAIL];
                [self processFailEventWithCode:ERROR_DELETE_FAIL failMsg:@"delete failed after cancel" isSaveDB:NO];
            }
        } else if (self.isCheckCacheFromNet) {
            DLLOGD(@"optimizeSmallTest:check cancel return cache");
            NSError *error = nil;
            if ([TTDownloadManager moveItemAtPath:self.cacheFullPath toPath:self.downloadTaskFullPath overwrite:YES error:&error]) {
                [self updateDownloadTaskStatus:DOWNLOADED];
                [self asyncStatusReport:ERROR_FILE_DOWNLOADED];
            } else {
                if (error) {
                    DLLOGD(@"error=%@", error);
                }
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
                [self updateDownloadTaskStatus:DELETED];
                [self asyncStatusReport:ERROR_CHECK_CACHE_FAILED];
            }
            
        } else {
            
            /**
             *If APP switch to background,won't end thread.Because when back to foreground,
             *it can work immediately.
             */
            if (self.isRestartTask && self.isAppAtBackground) {
                DLLOGD(@"dlLog:sem:foreground cancel,start background downloadint task");
                return NO;
            }

            if (self.isMobileSwitchToWifiCancel) {
                DLLOGD(@"dlLog:self.isMobileSwitchToWifiCancel=YES,restartTask in wifi");
                self.isMobileSwitchToWifiCancel = NO;
                if (!self.isAppAtBackground) {
                    [self restartTask];
                }
                return NO;
            }
            [self updateDownloadTaskStatus:CANCELLED];

            if (self.isNoNetCancel) {
                [self processFailEventWithCode:ERROR_NO_NET_CANCEL
                                       failMsg:@"No net cancel successfully!" isSaveDB:YES];
                [self asyncStatusReport:ERROR_NO_NET_CANCEL];
            } else if (self.isWifiOnlyCancel) {
                [self processFailEventWithCode:ERROR_WIFI_ONLY_CANCEL
                                       failMsg:@"wifionly cancel successfully!" isSaveDB:YES];
                [self asyncStatusReport:ERROR_WIFI_ONLY_CANCEL];
            } else if (self.isContentLengthInvalid) {
                [self asyncStatusReport:ERROR_FORE_CHECK_CONTENT_LENGTH_FAIL];
            } else if (self.isCheckRangeFailed) {
                [self asyncStatusReport:ERROR_RANGE_CHECK_FAILED];
            } else {
                [self processFailEventWithCode:ERROR_CANCEL_SUCCESS
                                       failMsg:@"user cancel successfully!" isSaveDB:YES];
                [self asyncStatusReport:ERROR_CANCEL_SUCCESS];
            }
        }
        ret = YES;
        DLLOGD(@"dlLog:getSliceCancelCount>0");
    }
    if (ret) {
        [self onDownloadProcessEnd];
    }
    return ret;
}

- (BOOL)tryRestoreTask {
    /**
     *If net bad,will retry to restore.
     */
    if (self.taskConfig.restoreTimesAuto > 0) {
        /**
         *If no net,won't restore.If net available,will try to restore.
         */
        if ([[TTDownloadManager class] isNetworkUnreachable]) {
            DLLOGD(@"dlLog:failed,no net");
        } else {
            /**
             *If net available,it means net is bad.So will restore immediately.
             */
            self.taskConfig.restoreTimesAuto--;
            DLLOGD(@"dlLog:bad net,the rest of count= %d", self.taskConfig.restoreTimesAuto);
            [[TTDownloadManager shareInstance] updateTaskConfigInDicLock:self.taskConfig];
            [self restartTask];
            return YES;
        }
    }
    return NO;
}

- (void)onDownloadProcessEnd {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
}

- (void)asyncStatusReport:(StatusCode)status {
    [[TTDownloadManager shareInstance] deleteBgIdentifierWithValueLock:self.urlKey];
    /**
     *If user cancel task.Task won't restore any more.
     */
    if (ERROR_CANCEL_SUCCESS == status && self.taskConfig.restoreTimesAuto > 0 && !self.isWifiOnlyCancel) {
        self.taskConfig.restoreTimesAuto = 0;
        [[TTDownloadManager shareInstance] updateTaskConfigInDicLock:self.taskConfig];
    }

    self.resultNotification.urlKey    = self.urlKey;
    self.resultNotification.secondUrl = self.secondUrl;
    self.resultNotification.code      = status;

    /**
     *If tracker enable,report tracker log.
     */
    if (self.isTrackerEnable && self.trackModel) {
        self.resultNotification.trackModel = [self.trackModel copy];
    } else {
        self.resultNotification.trackModel = nil;
    }

    DLLOGD(@"report resultNotification.code=%ld", (long)self.resultNotification.code);
    NSString *downloadTaskPath = nil;
    NSString *fullPath = nil;
    if (ERROR_FILE_DOWNLOADED == status || DOWNLOAD_SUCCESS == status) {
        downloadTaskPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:_taskConfig.fileStorageDir];
        _resultNotification.downloadedFilePath = [downloadTaskPath stringByAppendingPathComponent:_taskConfig.fileStorageName];
        fullPath = _resultNotification.downloadedFilePath;

        if (![[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath]) {
            NSString *downloadTaskPath2 = [[TTDownloadManager shareInstance].cachePath stringByAppendingPathComponent:self.taskConfig.fileStorageDir];
            if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath2]) {
                [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2 toPath:downloadTaskPath overwrite:YES error:nil];
                [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
            } else {
                self.resultNotification.code = ERROR_DOWNLOADED_FILE_MISS;
            }
        }
    } else {
        downloadTaskPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:[[TTDownloadManager class] calculateUrlMd5:self.urlKey]];
    }
    
    if ((self.taskConfig.restoreTimesAuto <= 0)
        || (ERROR_FILE_DOWNLOADED == status)
        || (DOWNLOAD_SUCCESS == status)) {
        [self.taskConfig clearUserBlock];
    }

    [[TTDownloadManager shareInstance] deleteDownloadingTaskInDicLock:self.urlKey];
    self.resultNotification.httpResponseArray = self.httpResponseArray;
 
#ifdef DOWNLOADER_DEBUG
    for (TTHttpResponse *info in self.httpResponseArray) {
        DLLOGD(@"http error code is %ld", (long)info.statusCode);
    }
#endif

    self.resultNotification.downloaderLog = [self.dllog toJSONString];

    DownloadResultNotification *copyNotification = [self.resultNotification copy];
    //try to clear cache if exist.
    [[TTDownloadManager shareInstance] deleteFile:self.cacheFullPath];
    
    [TTDownloadManager shareInstance].onCompletionHandler(copyNotification);
    
    [self checkUserPathAndTryToMove:status];
    
    @synchronized (self) {
        self.resultBlock(self.resultNotification);
    }
    /**
     * Check directory and file.If check unsuccessfully, clear cache.
     */
    if (![TTDownloadCommonTools isDirectoryExist:downloadTaskPath] || ((ERROR_FILE_DOWNLOADED == status || DOWNLOAD_SUCCESS == status) && (![TTDownloadCommonTools isFileExist:fullPath] || _userParameters.isClearDownloadedTaskCacheAuto))) {
        [self clearTaskConfig];
    }
}

- (void)checkUserPathAndTryToMove:(StatusCode)status {
    if (_userParameters.userCachePath && ((ERROR_FILE_DOWNLOADED == status) || (DOWNLOAD_SUCCESS == status))) {
        NSString *realPath = [TTDownloadCommonTools getUserRealFullPath:_userParameters.userCachePath];
        NSError *error = nil;
        if ([TTDownloadManager moveItemAtPath:_resultNotification.downloadedFilePath
                                       toPath:realPath
                                    overwrite:YES
                                        error:&error]) {
            _resultNotification.downloadedFilePath = realPath;
        } else {
            [_dllog addDownloadLog:nil error:error];
            _resultNotification.code = ERROR_MOVE_TO_USER_DIR_FAILED;
            _resultNotification.downloadedFilePath = nil;
        }
        /**
         * Clear cache after move file to user's directory.
         */
        [self clearTaskConfig];
    }
}

#ifdef DOWNLOADER_DEBUG
+ (NSString *)netQualityTypeToString:(TTNetEffectiveConnectionType)type {
    NSString *typeStr = @"unknown type";
    switch(type) {
        case EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK";
            break;
        case EFFECTIVE_CONNECTION_TYPE_UNKNOWN:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_UNKNOWN";
            break;
        case EFFECTIVE_CONNECTION_TYPE_OFFLINE:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_OFFLINE";
            break;
        case EFFECTIVE_CONNECTION_TYPE_SLOW_2G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_SLOW_2G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_3G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_3G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_SLOW_4G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_SLOW_4G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_MODERATE_4G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_MODERATE_4G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_GOOD_4G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_GOOD_4G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G";
            break;
        case EFFECTIVE_CONNECTION_TYPE_LAST:
            typeStr = @"EFFECTIVE_CONNECTION_TYPE_LAST";
            break;
        default:
            break;
    }
    return typeStr;
}
#endif

- (void)fetchDownloadProgressInfo {
    DLLOGD(@"fetchDownloadProgressInfo:Timing:++++++++++start++++++++");
    self.progressInfo.urlKey    = self.urlKey;
    self.progressInfo.secondUrl = self.secondUrl;
    int64_t hasDownloadedLength = 0;
    int64_t sliceTotalLength    = 0;
    
    if (self.taskConfig && [[TTDownloadManager class] isArrayValid:self.taskConfig.downloadSliceTaskConfigArray]) {
        for (TTDownloadSliceTaskConfig *sliceConfig in self.taskConfig.downloadSliceTaskConfigArray) {
            DLLOGD(@"dlLog:fetchDownloadProgressInfo:sliceNumber=%d,hasDownloadedLength=%lld", sliceConfig.sliceNumber, sliceConfig.hasDownloadedLength);
            hasDownloadedLength += [[TTDownloadManager class] getHadDownloadedLength:sliceConfig isReadLastSubSlice:YES];
            sliceTotalLength    += sliceConfig.sliceTotalLength;
        }
    }
     
    if (self.taskConfig.downloadStatus == DOWNLOADED) {
        self.progressInfo.progress = 1.0;
    } else {
        if (sliceTotalLength > 0) {
            self.progressInfo.progress = (float)hasDownloadedLength / sliceTotalLength;
        } else {
            self.progressInfo.progress = 0.0;
        }
        DLLOGD(@"dlLog:fetchDownloadProgressInfo:progress=%f,hasDownloadedLength=%lld,totalLength=%lld", self.progressInfo.progress, hasDownloadedLength, sliceTotalLength);
    }
    
    self.progressInfo.downloadedSize = hasDownloadedLength;
    self.progressInfo.totalSize = sliceTotalLength;

    if (self.lastHadDownloadedLength > 0) {
        self.progressInfo.netDownloadSpeed = hasDownloadedLength - self.lastHadDownloadedLength;
        if (self.progressInfo.netDownloadSpeed < 0) {
            self.progressInfo.netDownloadSpeed = hasDownloadedLength;
        }
    } else {
        self.progressInfo.netDownloadSpeed = 0;
    }
    self.lastHadDownloadedLength = hasDownloadedLength;
    self.trackModel.curBytes = hasDownloadedLength;
#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
    if (self.isDynamicThrottleEnable) {
        [self tryDynamicThrottle];
    }
#endif
    DLLOGD(@"fetchDownloadProgressInfo:Timing:+++++++++end++++++++++");
}

#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
- (void)tryDynamicThrottle {
 
    TTNetworkQuality *nqe = [[TTNetworkManager shareInstance] getNetworkQuality];
    DLLOGD(@"dynamicSpeed:rtt=%ld,httpRtt=%ld,dsKbps=%ld,speed=%lld",
           (long)nqe.transportRttMs, (long)nqe.httpRttMs, nqe.downstreamThroughputKbps, self.progressInfo.netDownloadSpeed);
    TTNetEffectiveConnectionType type = [[TTNetworkManager shareInstance] getEffectiveConnectionType];

    DLLOGD(@"dynamicSpeed:net type = %@", [TTDownloadTask netQualityTypeToString:type]);

    [self.dynamicThrottle dynamicCheckAndThrottle:nqe
                                   netQualityType:type
                                            speed:self.progressInfo.netDownloadSpeed
                                    throttleSpeed:self.throttleNetSpeed];
}
#endif

- (void)onceRunInTimer {

    [self fetchDownloadProgressInfo];
    if (self.progressBlock) {
        self.progressBlock(self.progressInfo);
    }
}

- (void)startTimer {

    //Delay time for timer.
    NSTimeInterval delayTime       = 1.0f;
    //timer interval.
    NSTimeInterval timeInterval    = 1.0f;
    dispatch_queue_t queue         = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //set start time.
    dispatch_time_t startDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
    //set timer.
    dispatch_source_set_timer(self.timer, startDelayTime, timeInterval * NSEC_PER_SEC, 0);

    __weak typeof(self) wself = self;
    dispatch_source_set_event_handler(self.timer, ^{
        __strong typeof(wself) sself = wself;
        if (sself == nil) {
            return;
        }
        [sself onceRunInTimer];
    });
    //Start timer.
    dispatch_resume(self.timer);
}
/**
 *need_disk_size < 0 ----->Don't check.
 *need_disk_size = 0 ----->Just check contentlength.
 *need_disk_size > 0 ----->check need_disk_size.
 */
- (BOOL)isFreeSpaceEnough:(int64_t)need_disk_size {
    if (need_disk_size < 0) {
        return YES;
    }
    int64_t freeSize = [[TTDownloadManager class] freeDiskSpace];
    DLLOGD(@"dlLog:free size is: %lld, contentLength=%lld, needDownloadLengthTotal=%lld", freeSize, self.contentTotalLength, self.needDownloadLengthTotal);
    if (GET_FREE_DISK_SPACE_ERROR == freeSize) {
        DLLOGD(@"dlLog:get free disk space failed");
        /**
         *If get free disk size failed,will return YES.Do nothing.
         */
        return YES;
    }
    if (need_disk_size && (need_disk_size < self.contentTotalLength)) {
        return ((need_disk_size + FREE_DISK_GAP) < freeSize);
    }
    if (((self.contentTotalLength + FREE_DISK_GAP) > freeSize) || ((self.contentTotalLength + self.needDownloadLengthTotal + FREE_DISK_GAP) > freeSize)) {
        DLLOGD(@"dlLog:free space not enough,");
        return NO;
    }
    return YES;
}

- (void)resetDownloadTaskConfig {
    self.sliceDownloadFailedCount    = 0;
    self.sliceCountHasDownloaded     = 0;
    self.sliceCancelCount            = 0;
    self.backgroundFailedCounter     = 0;
    self.backgroundDownloadedCounter = 0;
}

- (BOOL)startBackgroundTaskImpl {
    DLLOGD(@"dlLog:startBackgroundTaskImpl,");
    
    if (!self.isAppAtBackground) {
        return NO;
    }

    if (self.taskConfig) {
        [self resetDownloadTaskConfig];
        DLLOGD(@"bgDlLog:bgTask:startBackgroundTaskImpl:fillSliceInfoByRealFileSize");
        if (![self fillSliceInfoByRealFileSize:YES]) {
            DLLOGE(@"bgDlLog:bgTask:fillSliceInfoByRealFileSize error when switch to background");
            return NO;
        }

        DLLOGD(@"dlLog:dlLog:real startBackgroundTaskImpl");
        int8_t backgroundSliceCount = 0;
        for (int i = 0; i < self.taskConfig.downloadSliceTaskConfigArray.count; i++) {
            TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray objectAtIndex:i];
            if (DOWNLOADED != sliceConfig.sliceStatus) {
                sliceConfig.sliceStatus = BACKGROUND;
                backgroundSliceCount++;
                TTDownloadSubSliceBackgroundTask *bgTask = [[TTDownloadSubSliceBackgroundTask alloc] initWhithSliceConfig:sliceConfig downloadTask:self];
                @synchronized (self.downloadSliceBgTaskArray) {
                    [self.downloadSliceBgTaskArray addObject:bgTask];
                }
                [bgTask start];
            }
        }
        /**
         *If backgroundSliceCount is 0, we think all of slices downloaded completely.
         *But if merging slices at foreground,we must do nothing!
         */
        if (!backgroundSliceCount && !self.isMergingSlicesAtForeground) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self checkBackgroundDownloadFinished];
            });
            return YES;
        }
        
        return YES;
    }
    return NO;
}

- (BOOL)checkBackgroundDownloadFinished {
    BOOL ret = NO;
    DLLOGD(@"bg:backgroundDownloadedCounter=%d,self.backgroundFailedCounter=%d,self.taskConfig.sliceTotalNeedDownload=%d",
           self.backgroundDownloadedCounter, self.backgroundFailedCounter,
           self.taskConfig.sliceTotalNeedDownload);
    if ((self.backgroundDownloadedCounter > 0) && (self.backgroundDownloadedCounter >= self.taskConfig.sliceTotalNeedDownload)) {
        DLLOGD(@"checkBackgroundDownloadFinished:background download finished,will merge");
        self.isBackgroundMerging = YES;
        self.trackModel.isBackgroundDownloadFinish = YES;
        DLLOGD(@"bg try to mergeAllSlice");
        StatusCode code = [self mergeAllSlice];
        ret = YES;
        switch (code) {
            case ERROR_MERGE_SUCCESS:
                [self updateDownloadTaskStatus:DOWNLOADED];
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:NO isDeleteMergeFile:NO isDeleteSliceFile:YES];
                DLLOGD(@"dlLog:bgMulti:background downlaod success");
                break;
            default:
                self.isStopWhileLoop = YES;
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:NO isDeleteMergeFile:YES isDeleteSliceFile:NO];
                break;
        }
    } else if (self.backgroundFailedCounter > 0 && ((self.backgroundFailedCounter + self.backgroundDownloadedCounter) >= self.taskConfig.sliceTotalNeedDownload)) {
        DLLOGD(@"bgDlLog:bgTask::checkBackgroundDownloadFinished:BackgroundFailedCounter=%d", self.backgroundFailedCounter);
        ret = YES;
    }
    if (self.isRestartTask && self.backgroundTaskCancelSem) {
        DLLOGD(@"bgMulti:send bg cancel sem");
        dispatch_semaphore_signal(self.backgroundTaskCancelSem);
    }
    
    if (self.sem) {
        DLLOGD(@"bgMulti:send while sem");
        dispatch_semaphore_signal(self.sem);
    }
    
    return ret;
}

- (void)setRestartImmediately {
    if (DOWNLOADING != self.taskConfig.downloadStatus) {
        return;
    }
    @synchronized (self.downloadSliceTaskArray) {
        for (TTDownloadSliceForegroundTask *sliceTask in self.downloadSliceTaskArray) {
            switch (sliceTask.downloadSliceTaskConfig.sliceStatus) {
                case DOWNLOADING:
                case RETRY:
                case WAIT_RETRY:
                case RESTART:
                    [sliceTask setRestartImmediately];
                    break;
                    
                default:
                    break;
            }
        }
    }
}

- (void)ignoreFgTaskCallback {
    @synchronized (self.downloadSliceTaskArray) {
        if (![TTDownloadManager isArrayValid:self.downloadSliceTaskArray]) {
            return;
        }
        for (TTDownloadSliceForegroundTask *fgTask in self.downloadSliceTaskArray) {
            fgTask.isTaskValid = NO;
        }
    }
}

- (void)applicationEnterBackground_ {
    DLLOGD(@"bgDlLog:bgTask:Timing:enter Background");
    self.isAppAtBackground = YES;
    
    if ((self.onHeaderCallback && !self.isRcvHeaderCallback)
        || self.isWifiOnlyCancel
        || self.isMobileSwitchToWifiCancel
        || self.isMergingSlicesAtForeground
        || [self getIsCheckCacheValid]) {
        DLLOGD(@"stop background download");
        return;
    }
    
    BOOL isBackgroundDownloadEnable = [self getIsBackgroundDownloadEnable];

    if (self.isTrackerEnable) {
        self.trackModel.isBgDownloadEnable = isBackgroundDownloadEnable;
    }

    DLLOGD(@"bgDlLog:isBackgroundDownloadEnable=%d", isBackgroundDownloadEnable);
    if (!isBackgroundDownloadEnable) {
        
        if (DOWNLOADING == self.taskConfig.downloadStatus
            && !self.isCancelTask) {
            [self setRestartImmediately];
        }
        return;
    } else if (DOWNLOADING == self.taskConfig.downloadStatus
        && self.taskConfig.isSupportRange
        && !self.isCancelTask
        && !self.isBackgroundMerging) {
        [self startBackgroundDownload];
    }

    if (self.isTrackerEnable) {
        [self.trackModel addDownloadTimeWithReSet];
        [[TTDownloadManager shareInstance] addTrackModelToDB:self.trackModel];
    }
}

- (void)startBackgroundDownload {

    if (@available(iOS 9.0, *)) {
        if (self.isAppBeActiveSemWait && self.backgroundTaskCancelSem) {
            DLLOGD(@"bgDlLog:bgTask:send dispatch_semaphore_signal(self.backgroundTaskCancelSem)");
            dispatch_semaphore_signal(self.backgroundTaskCancelSem);
        }

        self.isRestartTask = YES;
        [self ignoreFgTaskCallback];
        [self cancelTaskWithNeedTrack:NO];
        [self onDownloadProcessEnd];

        if (self.isTrackerEnable) {
            // Record foreground bytes that had downloaded.
            // If APP is killed in background.it will calculate background bytes by foreground bytes.
            [self.trackModel recordFgDownloadBytes];
            [self.trackModel setBgDownloadStartTime];
        }

        if (![self startBackgroundTaskImpl]) {
            DLLOGE(@"dlLog:start background download failed");
        }
    }
}

- (void)applicationDidBecomeActive_ {
    DLLOGD(@"dlLog:enter Foreground");
    self.isAppAtBackground = NO;
    
    if (self.isBackgroundMerging) {
        @synchronized (self.downloadSliceBgTaskArray) {
            [self.downloadSliceBgTaskArray removeAllObjects];
        }
        return;
    }
    
    if (self.isRestartTask) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self cancelAllBackgroundTask];
            
            if (self.backgroundTaskCancelSem) {
                //
                dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, BACKGROUND_CANCEL_WAIT_TIME);
                DLLOGD(@"dlLog:applicationDidBecomeActive_:start wait backgroundTaskCancelSem");
                self.isAppBeActiveSemWait = YES;
                dispatch_semaphore_wait(self.backgroundTaskCancelSem, timeout);
                self.isAppBeActiveSemWait = NO;
                DLLOGD(@"dlLog:applicationDidBecomeActive_: wait backgroundTaskCancelSem end");
                [self ignoreAllBackgroundTask];
            }

            if (self.isTrackerEnable) {
                if (self.trackModel.isBgDownloadEnable) {
                    NSTimeInterval bgDownloadTimeSlice = [self.trackModel addBgDownloadTimeWithReSet];
                    self.trackModel.downloadTime += bgDownloadTimeSlice;
                }

                [self.trackModel setDownloadStartTime];
            }
            
            [self tryContinueForegroundDownloading];
        });
    }

}

- (void)cancelAllBackgroundTask {
    @synchronized (self.downloadSliceBgTaskArray) {
        for (int i = 0; i < self.downloadSliceBgTaskArray.count; i++) {
            TTDownloadSliceTask *bgTask = [self.downloadSliceBgTaskArray objectAtIndex:i];
            [bgTask cancel];
        }
    }
}

- (void)ignoreAllBackgroundTask {
    @synchronized (self.downloadSliceBgTaskArray) {
        for (TTDownloadSubSliceBackgroundTask *bgTask in self.downloadSliceBgTaskArray) {
            [bgTask setInvaildForBgTask];
        }
        [self.downloadSliceBgTaskArray removeAllObjects];
    }
    [[TTDownloadManager shareInstance] runBgCompletedHandler];
}

- (BOOL)tryContinueForegroundDownloading {
    if (self.isAppAtBackground) {
        return NO;
    }

    if (self.isRestartTask) {
        DLLOGD(@"enter foreground become active will restart task");
        [self resetDownloadTaskConfig];
        if (DOWNLOADED != self.taskConfig.downloadStatus) {
            if (![self fillSliceInfoByRealFileSize:NO]) {
                DLLOGE(@"dlLog:fillSliceInfoByRealFileSize error when switch to foreground");
                self.isStopWhileLoop = YES;
                if (self.sem) {
                    dispatch_semaphore_signal(self.sem);
                }
                return NO;
            }
            [self restartTask];
            self.isRestartTask = NO;
            [self startTimer];
        }
        if (self.sem) {
            dispatch_semaphore_signal(self.sem);
        }
    }
    return YES;
}

- (dispatch_semaphore_t)createSemWithRetry {
    dispatch_semaphore_t sem;
    uint8_t retry = CREATE_SEM_RETRY_TIMES;

    while (nil == (sem = dispatch_semaphore_create(0))) {
        if (0 == --retry) {
            return nil;
        }
    }
    return sem;
}

- (void)appReachabilityChanged:(NSNotification *)notification {
    DLLOGD(@"dlLog:++++++++++downloadTask net change++++++++++");
    NetworkStatus currType = [[TTDownloadManager class] getCurrentNetType];
    if (!self.isAppAtBackground) {
        if (self.userParameters
            && self.userParameters.isStopIfNoNet
            && NotReachable == currType) {
            self.isNoNetCancel = YES;
            [self cancelTask];
            return;
        }

        if ([self getIsDownloadWifiOnly] && ReachableViaWWAN == currType) {
            //When wifi only enable,task will be canceled if net type is cellular network.
            self.isWifiOnlyCancel = YES;
            DLLOGD(@"dlLog:wifi only mode,but current mobile net cancel task");
            [self cancelTaskWithNeedTrack:NO];
        } else if (![self getIsDownloadWifiOnly] && ReachableViaWWAN == self.currentNetType && ReachableViaWiFi == currType) {
            self.isMobileSwitchToWifiCancel = YES;
            [self cancelTaskWithNeedTrack:NO];
        } else {
            if ([self getIsRestartImmediatelyWhenNetworkChange]) {
                self.isMobileSwitchToWifiCancel = YES;
                [self cancelTaskWithNeedTrack:NO];
            }
        }
    }
    self.currentNetType = currType;
}

- (void)mergeTncAndUserConfig {
    self.isTrackerEnable = [self getIsUseTracker];
}

- (BOOL)getIsCheckCacheValid {
    int8_t isCheckCacheValid = [[TTDownloadManager shareInstance] getTncConfig].tncIsCheckCache;
    
    if (isCheckCacheValid >= 0) {
        return isCheckCacheValid > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isCheckCacheValid : NO;
}

#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
- (void)createDynamicThrottle {
    __weak typeof(self) wself = self;
    self.dynamicThrottle = [[TTDownloadDynamicThrottle alloc] initWithOutputAction:^(int64_t speed) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) {
            return;
        }
        sself.throttleNetSpeed = speed;
        [sself setThrottleNetSpeed2:sself.throttleNetSpeed];
    } params:self.userParameters throttleSpeed:self.throttleNetSpeed];
}
#endif

- (void)clearTaskConfig {
    [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
    [self updateDownloadTaskStatus:DELETED];
    self.taskConfig = nil;
}

- (StatusCode)checkCacheFromNet {
    /**
     *If self.taskConfig.extendConfig.lastModifiedTime is nil, we don't need send net request.
     */
    if (self.taskConfig.extendConfig.lastModifiedTime) {
        NSString *realUrl = self.taskConfig.secondUrl ? self.taskConfig.secondUrl : self.taskConfig.urlKey;
        if (![self getContentLengthWithRetry:realUrl]) {
            return ERROR_CHECK_CACHE_FAILED;
        }
    } else {
        if (![self getIsRetainCacheIfCheckFailed]) {
            self.isCacheInvalid = YES;
        }
    }
    
    DLLOGD(@"cacheTest:check cache,curr.lastTime=%@,last.lastTime=%@,curr.etag=%@,last.etag=%@", self.lastModifiedTime, self.taskConfig.extendConfig.lastModifiedTime, self.etag, self.taskConfig.extendConfig.etag);
    
    if (self.isCacheInvalid) {
        DLLOGD(@"cacheTest:++++++cache invalid++++++");
        [self clearTaskConfig];
    }
    return ERROR_CHECK_CACHE_COMPLETED;
}

- (BOOL)getIsUrgentModeEnable {
    int8_t isUrgentModeEnable = [[TTDownloadManager shareInstance] getTncConfig].tncIsUrgentModeEnable;
    
    if (isUrgentModeEnable >= 0) {
        return isUrgentModeEnable > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isUrgentModeEnable : NO;
}

- (BOOL)getIsClearCacheIfNoMaxAge {
    int8_t isClearCacheIfNoMaxAge = [[TTDownloadManager shareInstance] getTncConfig].tncIsClearCacheIfNoMaxAge;
    
    if (isClearCacheIfNoMaxAge >= 0) {
        return isClearCacheIfNoMaxAge > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isClearCacheIfNoMaxAge : NO;
}

- (BOOL)getIsRetainCacheIfCheckFailed {
    int8_t isRetainCacheIfCheckFailed = [[TTDownloadManager shareInstance] getTncConfig].tncIsRetainCacheIfCheckFailed;
    
    if (isRetainCacheIfCheckFailed >= 0) {
        return isRetainCacheIfCheckFailed > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isRetainCacheIfCheckFailed : NO;
}

- (BOOL)isPreCheckFileLength {
    int8_t TNCSwitchValue = [[[TTDownloadManager shareInstance] getTncConfig] preCheckFileLength];
    if (TNCSwitchValue >= 0) {
        return TNCSwitchValue > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.preCheckFileLength : NO;
}

- (BOOL)getIsTTNetUrgentModeEnable {
    int8_t value = [[TTDownloadManager shareInstance] getTncConfig].tncIsTTNetUrgentModeEnable;
    if (value >= 0) {
        return value > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isTTNetUrgentModeEnable : NO;
}

- (BOOL)getIsCommonParamEnable {
    int8_t value = [[TTDownloadManager shareInstance] getTncConfig].tncIsCommonParamEnable;
    if (value >= 0) {
        return value > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isCommonParamEnable : NO;
}

- (BOOL)callTTNetInterface {
    
    [[TTDownloadManager shareInstance] loadConfigFromStorage:nil];
    self.taskConfig = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:self.urlKey];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *realUrl = self.urlKey;
    NSString *fileName = self.fileName;
    NSDictionary *headerField = self.userParameters.httpHeaders;
    
    if (self.isUseKey) {
        realUrl = [self.urlLists firstObject];
        self.secondUrl = realUrl;
    }
    
    if (self.taskConfig) {
        if (!fileName) {
            fileName = self.taskConfig.fileStorageName;
        }
        if (!headerField) {
            headerField = self.taskConfig.userParam.httpHeaders;
        }
        if (!realUrl) {
            realUrl = self.taskConfig.secondUrl ? self.taskConfig.secondUrl : self.taskConfig.urlKey;
        }
    }
    
    if (!realUrl || !fileName) {
        return NO;
    }
    
    NSString *md5 = [TTDownloadManager calculateUrlMd5:self.urlKey];
    
    NSString *tempTaskDirFullPath = [[TTDownloadManager shareInstance].urgentModeTempRootDir stringByAppendingPathComponent:md5];
    
    @synchronized (kUrgentModeTempDir) {
        NSError *error = nil;
        if (![[TTDownloadManager class] createDir:[TTDownloadManager shareInstance].urgentModeTempRootDir error:&error]) {
            [self.dllog addDownloadLog:nil error:error];
            return NO;
        }
        
        if ([fileManager fileExistsAtPath:tempTaskDirFullPath]) {
            [fileManager removeItemAtPath:tempTaskDirFullPath error:nil];
        }
        error = nil;
        if (![[TTDownloadManager class] createDir:tempTaskDirFullPath error:&error]) {
            [self.dllog addDownloadLog:nil error:error];
            return NO;
        }
    }

    NSString *filePath = [tempTaskDirFullPath stringByAppendingPathComponent:fileName];
    DLLOGD(@"urgentMode:filePath=%@", filePath);
    NSURL *fileDestinationURL = [NSURL fileURLWithPath:filePath];
    
    if (self.isDelete) {
        [fileManager removeItemAtPath:tempTaskDirFullPath error:nil];
        [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
        return NO;
    }
    
    self.requestTask = [[TTNetworkManager shareInstance] downloadTaskWithRequest:realUrl parameters:nil headerField:headerField needCommonParams:NO progress:nil destination:fileDestinationURL completionHandler:^(TTHttpResponse *response, NSURL *url, NSError *error) {
        
        BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];

        self.requestTask = nil;
        if (self.isDelete) {
            [fileManager removeItemAtPath:tempTaskDirFullPath error:nil];
            [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
        }
        
        if (!error && exist) {
            [self urgentModeProgressReport:filePath];
            [self syncUrgentModeStatusReport:DOWNLOAD_SUCCESS fullPath:filePath];
        } else {
            [self syncUrgentModeStatusReport:ERROR_URGENT_MODE_FAILED fullPath:nil];
        }
    }];
    if (self.isCancelTask && self.requestTask) {
        [self.requestTask cancel];
    }
    return YES;
}

- (void)urgentModeProgressReport:(NSString *)filePath {
    if (!filePath) {
        return;
    }
    
    if (self.progressBlock) {
        NSError *error = nil;
        NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        if (!error) {
            DLLOGD(@"urgent mode file size=%lld", fileAttributeDic.fileSize);
            self.progressInfo.downloadedSize = fileAttributeDic.fileSize;
            self.progressInfo.totalSize = fileAttributeDic.fileSize;
        }
        self.progressInfo.progress = 1.0;
        self.progressBlock(self.progressInfo);
    }
}

- (void)syncUrgentModeStatusReport:(StatusCode)status fullPath:(NSString *)fullPath {
    /**
     *If enable urgent mode.Task won't restore any more.
     */
    if (_taskConfig.restoreTimesAuto > 0) {
        _taskConfig.restoreTimesAuto = 0;
        [[TTDownloadManager shareInstance] updateTaskConfigInDicLock:_taskConfig];
    }

    _resultNotification.urlKey    = _urlKey;
    _resultNotification.secondUrl = _secondUrl;
    _resultNotification.code      = status;

    DLLOGD(@"report resultNotification.code=%ld", (long)_resultNotification.code);
    if (ERROR_FILE_DOWNLOADED == status || DOWNLOAD_SUCCESS == status) {
        _resultNotification.downloadedFilePath = fullPath;
    }

    [[TTDownloadManager shareInstance] deleteDownloadingTaskInDicLock:_urlKey];
    _resultNotification.httpResponseArray = _httpResponseArray;

    DownloadResultNotification *copyNotification = [_resultNotification copy];
    [TTDownloadManager shareInstance].onCompletionHandler(copyNotification);
    
    [self checkUserPathAndTryToMove:status];
    
    if (_resultBlock) {
        _resultBlock(_resultNotification);
    }
}

- (void)checkDownloadDir {
    if (![TTDownloadManager isDirectoryExist:self.downloadTaskFullPath]
        || ((DOWNLOADED != self.taskConfig.downloadStatus)
            && ![TTDownloadManager isDirectoryExist:self.downloadTaskSliceFullPath])) {
        /**
         *If download directory doesn't exist,we must clear all cache of this task.
         *Thus,download it as new one.
         */
        [self clearTaskConfig];
    }
}

-(void)deleteDownloadDir {
    if ([TTDownloadCommonTools isDirectoryExist:_downloadTaskFullPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:_downloadTaskFullPath error:&error];
        if (error) {
            DLLOGD(@"delete dir failed,error=%@", error.description);
        }
    }
}

- (void)startTaskImpl {
    
    _TTMd5Callback = _userParameters.TTMd5Callback;
    _userParameters.TTMd5Callback = nil;
    
    StatusCode ret = [TTDownloadCommonTools checkDownloadPathValid:_userParameters.userCachePath];
    if (ERROR_USER_CHECK_PATH_SUCCESS != ret) {
        [self updateDownloadTaskStatus:FAILED];
        [self processFailEventWithCode:ret failMsg:@"user directory invalid" isSaveDB:NO];
        [self asyncStatusReport:ret];
        return;
    }
    
    if ([self getIsTTNetUrgentModeEnable]) {
        DLLOGD(@"ttnet11: interface start");
        if (![self callTTNetInterface]) {
            [self syncUrgentModeStatusReport:ERROR_URGENT_MODE_FAILED fullPath:nil];
        }
        DLLOGD(@"ttnet11: interface end");
        return;
    }
    
    [self getFullPath];
    
    [self mergeTncAndUserConfig];
    
    if (self.isTrackerEnable) {
        [self configTrackModel];

        if (!self.taskConfig) {
            [self processCreateEventIsSaveDB:NO];
        }
        [TTDownloadTracker.sharedInstance sendEvent:self.isResume ? TTDownloadEventStart : TTDownloadEventFirstStart eventModel:self.trackModel];
    }

    self.currentNetType = [[TTDownloadManager class] getCurrentNetType];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterBackground_)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive_)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appReachabilityChanged:)
                                                 name:TTReachabilityChangedNotification
                                               object:[TTReachability reachabilityForInternetConnection]];

    NSMutableArray *errorList = [[NSMutableArray alloc] init];
    if (![[TTDownloadManager shareInstance] loadConfigFromStorage:errorList]) {
        DLLOGD(@"dlLog:load config from Storage failed");
        [self processFailEventWithCode:ERROR_LOAD_CONFIG_FROM_DB_FAILED failMsg:@"load config from Storage failed" isSaveDB:NO];
        NSString *errorStr = [TTDownloadManager arrayToNSString:errorList];
        DLLOGD(@"errorStr=%@", errorStr);
        [self.dllog addDownloadLog:errorStr error:nil];
        [self asyncStatusReport:ERROR_LOAD_CONFIG_FROM_DB_FAILED];
        return;
    }
    self.taskConfig = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:self.urlKey];
    
    if (_taskConfig) {
        [self checkDownloadDir];
    }

    if (_taskConfig && [self getIsUrgentModeEnable]) {
        /**
         *If urgent mode enable, downloader will use default config.
         *But we can set new config on TNC If need.
         */
        if (self.userParameters.httpHeaders && _userParameters.httpHeaders.count > 0) {
            /**
             *Keep headers
             */
            DownloadGlobalParameters *newParam = [[DownloadGlobalParameters alloc] init];
            newParam.httpHeaders = _userParameters.httpHeaders;
            _userParameters = newParam;
        } else {
            _userParameters = nil;
        }
        [self clearTaskConfig];
    }

    if (_taskConfig && [self getIsCheckCacheValid]) {
        NSError *error = nil;
        if (![TTDownloadManager createDir:_cacheBackupDir error:&error]) {
            [self.dllog addDownloadLog:nil error:error];
            [self processFailEventWithCode:ERROR_CREATE_CACHE_BACKUP_DIR_FAILED failMsg:@"create cache backup dir failed" isSaveDB:NO];
            [self asyncStatusReport:ERROR_CREATE_CACHE_BACKUP_DIR_FAILED];
            return;
        }
        
        if ([self getIsClearCacheIfNoMaxAge]) {
            if (_taskConfig.extendConfig && !_taskConfig.extendConfig.maxAgeTime) {
                [self clearTaskConfig];
            }
        }
        
        if (_taskConfig
            && ([self isIgnoreMaxAgeCheck]
                || ([TTDownloadManager compareDate:[TTDownloadManager getFormatTime:0] withDate:_taskConfig.extendConfig.maxAgeTime] < 0))) {
             DLLOGD(@"local cache invalid");
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if (DOWNLOADED == _taskConfig.downloadStatus) {
                _isCheckCacheFromNet = YES;
                BOOL isDir = NO;
                if ([fileManager fileExistsAtPath:_downloadTaskFullPath isDirectory:&isDir] && isDir) {
                    NSError *error = nil;
                    if ([TTDownloadManager moveItemAtPath:_downloadTaskFullPath
                                                   toPath:_cacheFullPath
                                                overwrite:YES
                                                    error:&error]) {
                        _originExtendConfig = _taskConfig.extendConfig;
                        _taskConfig.extendConfig = nil;
                    } else {
                        /**
                         *If move file failed,start new request.
                         */
                        DLLOGE(@"error=%@", error);
                        _isCheckCacheFromNet = NO;
                        _originExtendConfig = nil;
                    }
                }
                
                [self clearTaskConfig];
            } else {
                StatusCode ret;
                if (ERROR_CHECK_CACHE_COMPLETED != (ret = [self checkCacheFromNet])) {
                    [self processFailEventWithCode:ret failMsg:@"check cache failed" isSaveDB:NO];
                    [self asyncStatusReport:ret];
                    return;
                }
            }
         }
    }

    if (_taskConfig.userParam) {
        if (_userParameters) {
            if (_taskConfig.userParam.isClearDownloadedTaskCacheAuto != _userParameters.isClearDownloadedTaskCacheAuto) {
                _taskConfig.userParam.isClearDownloadedTaskCacheAuto = _userParameters.isClearDownloadedTaskCacheAuto;
            }
            if (_userParameters.userCachePath) {
                _taskConfig.userParam.userCachePath = _userParameters.userCachePath;
            }
            if ([_taskConfig.userParam isDownloadWifiOnly] != [_userParameters isDownloadWifiOnly]) {
                //isDownloadWifiOnly use the latest value in resume situation
                [_taskConfig.userParam setIsDownloadWifiOnly:_userParameters.isDownloadWifiOnly];
            }
            
            if ([_taskConfig.userParam throttleNetSpeed] != [_userParameters throttleNetSpeed]) {
                [_taskConfig.userParam setThrottleNetSpeed:[_userParameters throttleNetSpeed]];
            }
            
            if (![[_taskConfig.md5Value lowercaseString] isEqualToString:[_fileMd5Value lowercaseString]]) {
                _taskConfig.md5Value = _fileMd5Value;
            }
            
            if ([_taskConfig.userParam preCheckFileLength] != [_userParameters preCheckFileLength]) {
                [_taskConfig.userParam setPreCheckFileLength:[_userParameters preCheckFileLength]];
            }
            
            if ([_taskConfig.userParam expectFileLength] != [_userParameters expectFileLength]) {
                [_taskConfig.userParam setExpectFileLength:[_userParameters expectFileLength]];
            }
            
            if ([_taskConfig.userParam restoreTimesAutomatic] != [_userParameters restoreTimesAutomatic]) {
                [_taskConfig.userParam setRestoreTimesAutomatic:[_userParameters restoreTimesAutomatic]];
            }
            
            if ([_taskConfig.userParam isBackgroundDownloadEnable] != [_userParameters isBackgroundDownloadEnable]) {
                [_taskConfig.userParam setIsBackgroundDownloadEnable:[_userParameters isBackgroundDownloadEnable]];
            }
            NSError *error = nil;
            //save the latest value to db, for automatic recovery next time
            if (![[TTDownloadManager shareInstance] updateParametersTable:_taskConfig error:&error]) {
                [_dllog addDownloadLog:nil error:error];
            }
        }
        _userParameters = _taskConfig.userParam;
        _isSkipGetContentLength = _userParameters.isSkipGetContentLength;
        _isServerSupportRangeDefault = _userParameters.isServerSupportRangeDefault;
    } else if (_taskConfig && !_taskConfig.userParam) {
        /**
         * If userParameter is nil, we must update isSkipGetContentLength.
         */
        _isSkipGetContentLength = [self getIsSkipGetContentLength];
    }
    //Here,if self.taskConfig isn't nil, will resume task.Otherwise start a new task.
    if (nil == _taskConfig) {
        /**
         *Delete exist directory, before start a new task.
         */
        [self deleteDownloadDir];
        /**
         *If caller's parameter is nil, we will create it.
         */
        if (!_userParameters) {
            _userParameters = [[DownloadGlobalParameters alloc] init];
        }
        
        if ([[TTDownloadManager shareInstance] getIsForceCacheLifeTimeMaxEnable]
            && _userParameters
            && ((_userParameters.cacheLifeTimeMax != kByPassCheckCacheLifeTime)
                && (_userParameters.cacheLifeTimeMax <= 0))) {
            [self processFailEventWithCode:ERROR_MUST_SET_CACHE_LIFE_TIME failMsg:@"must set cacheLifeTimeMax" isSaveDB:NO];
            [self asyncStatusReport:ERROR_MUST_SET_CACHE_LIFE_TIME];
            return;
        }
        
        if (self.isTrackerEnable) {
            [self createTrackModel];
        }
        [self processStartEventIsSaveDB:NO];
        [self processFirstStartEventIsSaveDB:NO];

        self.isSkipGetContentLength = [self getIsSkipGetContentLength];
        if (self.isSkipGetContentLength) {
            self.isServerSupportRangeDefault = [self getIsServerSupportRangeDefault];
        }

        if (self.isResume) {
            [self processFailEventWithCode:ERROR_NO_TASK_CAN_RESUME failMsg:@"no task can resume" isSaveDB:NO];
            [self asyncStatusReport:ERROR_NO_TASK_CAN_RESUME];
            return;
        }

        if (self.isSkipGetContentLength) {
            DLLOGD(@"dlLog:skip get content length");
            self.isServerSupportAcceptRange = self.isServerSupportRangeDefault;
            if (self.isUseKey) {
                self.secondUrl = [self.urlLists firstObject];
            }
            
            __weak __typeof(self)weakSelf = self;
            self.onHeaderCallback = ^(TTHttpResponse *response) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                DLLOGD(@"optimizeSmallTest:self.headerCallback start**code=%ld",
                       (long)response.statusCode);
                if (strongSelf.contentTotalLength > 0 || strongSelf.taskConfig.sliceTotalNeedDownload != 1) {
                    DLLOGD(@"optimizeSmallTest:contentTotalLength > 0 || strongSelf.taskConfig.sliceTotalNeedDownload != 1");
                    return YES;
                }
                /**
                 *Parser headers.
                 */
                if (![strongSelf parserHeader:response]) {
                    return NO;
                }
                /**
                 *Check cache.
                 */
                if ([strongSelf getIsCheckCacheValid] && strongSelf.isCheckCacheFromNet) {
                    if (response.statusCode == 304 || [strongSelf checkCacheInHeaderCallback]) {
                        /**
                          *Will cancel task and return cache
                          */
                        return NO;
                    }
                }
                DLLOGD(@"optimizeSmallTest:reach end");
                return YES;
            };
        } else {
            NSTimeInterval gclStartTime = CFAbsoluteTimeGetCurrent();
            BOOL gclRet = [self calculateContentLength];
            
            if (self.isTrackerEnable) {
                self.trackModel.gclTime = ceil((CFAbsoluteTimeGetCurrent() - gclStartTime) * 1000);
            }

            if (!gclRet) {
                if (self.isDelete) {
                    [self updateDownloadTaskStatus:DELETED];
                } else {
                    [self updateDownloadTaskStatus:FAILED];
                }
                StatusCode code = ERROR_GET_CONTENT_LENGTH_FAILED;
                if (self.isCancelTask) {
                    code = ERROR_CANCEL_SUCCESS;
                }
                if (self.isContentLengthInvalid) {
                    code = ERROR_FORE_CHECK_CONTENT_LENGTH_FAIL;
                }
                [self processFailEventWithCode:code failMsg:@"get content length failed" isSaveDB:NO];
                [self asyncStatusReport:code];
                DLLOGD(@"dlLog:get content length failed");
                return;
            } else {
                //check range
                if (![self rangeCheck:self.isServerSupportAcceptRange
                       contentLength:self.contentTotalLength
                         startOffset:self.userParameters.startOffset
                           endOffset:self.userParameters.endOffset]) {

                    [self updateDownloadTaskStatus:DELETED];
                    StatusCode code = ERROR_RANGE_CHECK_FAILED;
                    [self processFailEventWithCode:code failMsg:@"range check failed" isSaveDB:NO];
                    [self asyncStatusReport:code];
                    DLLOGD(@"dlLog:range check failed");
                    return;
                }
            }
        }

        if (self.isCancelTask) {
            DLLOGD(@"dlLog:cancel task");
            if (self.isDelete) {
                [self updateDownloadTaskStatus:DELETED];
                [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
                [self asyncStatusReport:ERROR_DELETE_SUCCESS];
            } else {
                [self updateDownloadTaskStatus:CANCELLED];
                [self processFailEventWithCode:ERROR_CANCEL_SUCCESS failMsg:@"is cancel task" isSaveDB:NO];
                [self asyncStatusReport:ERROR_CANCEL_SUCCESS];
            }

            return;
        }
        
        if (![self createDownloadTaskConfig]) {
            DLLOGD(@"dlLog:cancel task");
            [self updateDownloadTaskStatus:FAILED];
            [self processFailEventWithCode:ERROR_CREATE_DOWNLOAD_CONFIG_FAILED failMsg:@"create config failed" isSaveDB:NO];
            [self asyncStatusReport:ERROR_CREATE_DOWNLOAD_CONFIG_FAILED];
            return;
        }

        if (![self createDownloadTaskDir]) {
            [self updateDownloadTaskStatus:CANCELLED];
            [self asyncStatusReport:ERROR_CREATE_DOWNLOAD_TASK_DIR];
            [self processFailEventWithCode:ERROR_CREATE_DOWNLOAD_TASK_DIR failMsg:@"can not create download task dir" isSaveDB:YES];
            return;
        }
        
        if (![self createRestoreFlags]) {
            [self updateDownloadTaskStatus:FAILED];
            [self processFailEventWithCode:ERROR_CREATE_RESTORE_FLAG_FAILED failMsg:@"create restore flag failed" isSaveDB:YES];
            [self asyncStatusReport:ERROR_CREATE_RESTORE_FLAG_FAILED];
            return;
        }
    } else {

        self.secondUrl = self.taskConfig.secondUrl;
        self.throttleNetSpeed = [self getThrottleNetSpeed];
        
        if (self.isTrackerEnable) {
            [self configTrackModel];
            self.trackModel.secondUrl = self.secondUrl;
        }
        [self processStartEventIsSaveDB:YES];
        
        if (DOWNLOADED == self.taskConfig.downloadStatus) {
            DLLOGD(@"optimizeSmallTest:config!=nil return cache");
            [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:NO isDeleteMergeFile:NO isDeleteSliceFile:YES];
            [self asyncStatusReport:ERROR_FILE_DOWNLOADED];
            [self processFailEventWithCode:ERROR_FILE_DOWNLOADED failMsg:@"file already downloaded" isSaveDB:YES];
            return;
        }

        if (self.isTrackerEnable) {
            self.trackModel.isWifiOnly = [self getIsDownloadWifiOnly];
        }

        if (self.taskConfig.isAutoRestore && self.taskConfig.restoreTimesAuto > 0) {
            self.taskConfig.restoreTimesAuto--;
            [self.trackModel addCurRestoreTime:1];
            [[TTDownloadManager shareInstance] updateTaskConfigInDicLock:self.taskConfig];
            self.taskConfig.isAutoRestore = NO;
        }
        
        if ([self getIsDownloadWifiOnly] && ![[TTDownloadManager class] isWifi]) {
            [self updateDownloadTaskStatus:FAILED];
            [self asyncStatusReport:ERROR_WIFI_ONLY_BUT_NO_WIFI];
            [self processFailEventWithCode:ERROR_WIFI_ONLY_BUT_NO_WIFI failMsg:@"wifi only but no wifi" isSaveDB:YES];
            DLLOGD(@"dlLog:resume task is wifi only mode,return");
            return;
        }

        if (![[TTDownloadManager class] isArrayValid:self.taskConfig.downloadSliceTaskConfigArray]) {
            [self updateDownloadTaskStatus:FAILED];
            [self processFailEventWithCode:ERROR_ARRAY_INVALID failMsg:@"downloadSliceTaskConfigArray error" isSaveDB:YES];
            [self asyncStatusReport:ERROR_ARRAY_INVALID];
            return;
        }
        TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray firstObject];
        DLLOGD(@"dlLog:--urlKey=%@,secondUrl=%@", sliceConfig.urlKey, sliceConfig.secondUrl);
        self.firstSliceNeedDownloadLength      = sliceConfig.sliceTotalLength;
        self.fileName                          = self.taskConfig.fileStorageName;
        self.fileMd5Value                      = self.taskConfig.md5Value;
        self.isServerSupportAcceptRange        = self.taskConfig.isSupportRange;
        /**
         *If user call key interface,get the real url from urlList.
         */
        if (self.isUseKey) {
            NSString *secondUrl = [self.urlLists firstObject];
            if (secondUrl) {
                self.taskConfig.secondUrl = secondUrl;
            }

            self.secondUrl = self.taskConfig.secondUrl;
            self.trackModel.secondUrl = self.secondUrl;
            if (nil == self.taskConfig.secondUrl) {
                DLLOGD(@"when use key,can't get valid url in urlLists");
                [self updateDownloadTaskStatus:FAILED];
                [self asyncStatusReport:ERROR_KEY_NEED_VALID_URL_IN_URLLISTS];
                [self processFailEventWithCode:ERROR_KEY_NEED_VALID_URL_IN_URLLISTS failMsg:@"when use key,can't get valid url in urlLists" isSaveDB:YES];
                return;
            }
        }
        
        DLLOGD(@"dlLog:startTaskImpl:urlKey=%@,secondUrl=%@", self.taskConfig.urlKey, self.taskConfig.secondUrl);

        if (![self fillSliceInfoByRealFileSize:NO]) {
            DLLOGD(@"dlLog:slice size error");
            [self updateDownloadTaskStatus:FAILED];
            [self asyncStatusReport:ERROR_SLICE_SIZE_ERROR];
            [self processFailEventWithCode:ERROR_SLICE_SIZE_ERROR failMsg:@"slice size error" isSaveDB:NO];
            return;
        }
    }

    if (![self createSliceDownloadTask]) {
        [self updateDownloadTaskStatus:FAILED];
        [self processFailEventWithCode:ERROR_CRATE_SLICE_DOWNLOAD_TASK_FAILED failMsg:@"downloadSliceTaskConfigArray error" isSaveDB:YES];
        [self asyncStatusReport:ERROR_CRATE_SLICE_DOWNLOAD_TASK_FAILED];
        return;
    }

    if (self.isWifiOnlyCancel) {
        [self updateDownloadTaskStatus:CANCELLED];
        [self processFailEventWithCode:ERROR_WIFI_ONLY_CANCEL failMsg:@"downloadSliceTaskConfigArray error" isSaveDB:YES];
        [self asyncStatusReport:ERROR_WIFI_ONLY_CANCEL];
        return;
    }
    
    /**
     *Record block to restore task when net available.
     */
    self.taskConfig.progressBlock = self.progressBlock;
    @synchronized (self) {
        self.taskConfig.resultBlock = self.resultBlock;
    }
    DLLOGD(@"dlLog:start+++self.sliceTotalNeedDownload=%d,sliceCountHasDownloaded=%d",
          self.taskConfig.sliceTotalNeedDownload, _sliceCountHasDownloaded);

    if (nil == (self.sem = [self createSemWithRetry])) {
        [self updateDownloadTaskStatus:FAILED];
        [self asyncStatusReport:ERROR_CREATE_SEM_FAILED];
        [self processFailEventWithCode:ERROR_CREATE_SEM_FAILED failMsg:@"CREATE_SEM_FAILED" isSaveDB:YES];
        return;
    }

    if (self.isTrackerEnable) {
        [self.trackModel setDownloadStartTime];
    }

    [self startTimer];
    
    if (self.isCancelTask) {
        [self onDownloadProcessEnd];
        if (self.isDelete) {
            BOOL isDeleteSuccess = [[TTDownloadManager shareInstance] deleteDownloadFile:self.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
            if (isDeleteSuccess) {
                [self updateDownloadTaskStatus:DELETED];
                [self asyncStatusReport:ERROR_DELETE_SUCCESS];
            } else {
                [self updateDownloadTaskStatus:FAILED];
                [self asyncStatusReport:ERROR_DELETE_FAIL];
                [self processFailEventWithCode:ERROR_DELETE_FAIL failMsg:@"delete failed after cancel" isSaveDB:NO];
            }
            return;
        }
        [self updateDownloadTaskStatus:FAILED];
        [self asyncStatusReport:ERROR_CANCEL_SUCCESS];
        [self processFailEventWithCode:ERROR_CANCEL_SUCCESS failMsg:@"ERROR_CANCEL_SUCCESS" isSaveDB:YES];
        return;
    }
#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
    if (self.throttleNetSpeed <= kDynamicThrottleBalanceEnable) {
        self.isDynamicThrottleEnable = YES;
        [self createDynamicThrottle];
    }
#endif

    while (true) {
        if (DOWNLOADED == self.taskConfig.downloadStatus) {
            [self downloadResultReport:DOWNLOADED reportStatusCode:DOWNLOAD_SUCCESS];
            DLLOGD(@"bgMulti:*******isBackgroundDownloadFinished=YES*****download task end**************");
            return;
        }
        
        if (self.isStopWhileLoop) {
            [self downloadResultReport:FAILED reportStatusCode:ERROR_FOREGROUND_CONTINUE_TASK_FAILED];
            DLLOGD(@"bgMulti:*******self.isStopWhileLoop=YES*****download task end**************");
            return;
        }
        
        if (self.isBackgroundMerging) {
            DLLOGD(@"bgMulti:self.isBackgroundMerging=YES,wait background merge");
            dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME_MAX);
            dispatch_semaphore_wait(self.sem, timeout);
            continue;
        }
        
        DLLOGD(@"dlLog:start check result");
        if ([self checkDownloadFinished]) {
            DLLOGD(@"dlLog:************download task end**************");
            return;
        }
        
        if (!_isStartDownloadingFlag
            && [TTDownloadManager shareInstance].isAppBackground
            && [self getIsBackgroundDownloadEnable]
            && !self.isCancelTask) {
            DLLOGD(@"bgMulti:new task will start background download");
            self.isAppAtBackground = [TTDownloadManager shareInstance].isAppBackground;
            
            //Here start background download.
            if (self.isAppAtBackground) {
                _isStartDownloadingFlag = YES;
                [self updateDownloadTaskStatus:DOWNLOADING];
                //try to background download.
                DLLOGD(@"bgMulti:+++++++++++start background+++++++++");
                [self startBackgroundDownload];
            }
        }

        for (int i = 0; i < self.taskConfig.downloadSliceTaskConfigArray.count; i++) {
            TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray objectAtIndex:i];
            if ((INIT == sliceConfig.sliceStatus)
                || (RESTART == sliceConfig.sliceStatus)) {
                DLLOGD(@"1:sliceNo=%d,sliceStatus=%ld,startRange=%lld,endRange=%lld", sliceConfig.sliceNumber, (long)sliceConfig.sliceStatus, sliceConfig.startByte, sliceConfig.endByte);
                TTDownloadSliceForegroundTask *sliceTask = [self createNewFgSliceTask:sliceConfig];
                [sliceTask start];
            } else if (RETRY == sliceConfig.sliceStatus) {
                DLLOGD(@"2:sliceNo=%d,sliceStatus=%ld,startRange=%lld,endRange=%lld", sliceConfig.sliceNumber, (long)sliceConfig.sliceStatus, sliceConfig.startByte, sliceConfig.endByte);
                sliceConfig.sliceStatus = WAIT_RETRY;
                int64_t sliceRetryInterval = [self getRetryInterval:sliceConfig];

                TTDownloadSliceForegroundTask *sliceTask = [self createNewFgSliceTask:sliceConfig];

                DLLOGD(@"sliceRetryInterval=%lld", sliceRetryInterval);
                @synchronized(sliceConfig) {
                    sliceTask.startTaskDelayHandle = [TTNetworkUtil dispatchBlockAfterDelay:(sliceConfig.isCancel ? 0 : sliceRetryInterval) block:^{
                        DLLOGD(@"dlLog:retry block run");
                        [sliceTask start];
                    }];
                }
            }
        }

        if (!self.isStartDownloadingFlag) {
            self.isStartDownloadingFlag = YES;
            [self updateDownloadTaskStatus:DOWNLOADING];
        }
        /**
         *When some slice download completely,we must adjust throttle net speed for per slice.
         */
        [self checkAndAdjustThrottleSpeed];

        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME_MAX);
        dispatch_semaphore_wait(self.sem, timeout);
    }
}

- (void)downloadResultReport:(DownloadStatus)downloadStatus
            reportStatusCode:(StatusCode)reportStatusCode {
    [self onceRunInTimer];
    [self onDownloadProcessEnd];
    [self updateDownloadTaskStatus:downloadStatus];
    [self asyncStatusReport:reportStatusCode];
    [self processFinishEventIsSaveDB:YES];
    [[TTDownloadManager shareInstance] runBgCompletedHandler];
}

- (TTDownloadSliceForegroundTask *)createNewFgSliceTask:(TTDownloadSliceTaskConfig *)sliceConfig {
    TTDownloadSliceForegroundTask *sliceTask = [[TTDownloadSliceForegroundTask alloc] initWhithSliceConfig:sliceConfig downloadTask:self];
    
    @synchronized (self.downloadSliceTaskArray) {
        TTDownloadSliceTask *oldSliceTask = [self.downloadSliceTaskArray objectAtIndex:(sliceConfig.sliceNumber - 1)];
        [self.downloadSliceTaskArray replaceObjectAtIndex:(sliceConfig.sliceNumber - 1) withObject:sliceTask];
        [oldSliceTask clearReferenceCount];
    }
    return sliceTask;
}

- (bool)isNeedBalanceThrottleSpeed {
    int8_t sliceDownloadEnd = self.sliceCountHasDownloaded + self.sliceCancelCount + self.sliceDownloadFailedCount;

    if (self.throttleNetSpeed > 0 && (sliceDownloadEnd > self.sliceDownloadEndCount) && sliceDownloadEnd != self.taskConfig.sliceTotalNeedDownload) {
        self.sliceDownloadEndCount = sliceDownloadEnd;
        DLLOGD(@"dlLog6:isNeedBalanceThrottleSpeed = YES");
        return YES;
    }
    DLLOGD(@"dlLog6:isNeedBalanceThrottleSpeed = NO");
    return NO;
}

- (void)checkAndAdjustThrottleSpeed {
    if ([self isNeedBalanceThrottleSpeed]) {
        [self setThrottleNetSpeed2:self.throttleNetSpeed];
    }
}

- (int64_t)getRetryInterval:(TTDownloadSliceTaskConfig *)sliceConfig {
    DLLOGD(@"getRetryInterval:max=%d,remainRetryTime=%d", sliceConfig.retryTimesMax, sliceConfig.retryTimes);
    int64_t retryTimeoutInterval = [self getRetryTimeoutInterval];
    DLLOGD(@"dlLog:retryTimeoutInterval=%lld", retryTimeoutInterval);

    int64_t retryTimeoutIntervalIncrement = [self getRetryTimeoutIntervalIncrement];
    DLLOGD(@"dlLog:retryTimeoutIntervalIncrement=%lld", retryTimeoutIntervalIncrement);

    int64_t realRetryTimeoutIntervalIncrement = retryTimeoutIntervalIncrement * (sliceConfig.retryTimesMax - sliceConfig.retryTimes - 1);
    if (realRetryTimeoutIntervalIncrement < 0) {
        realRetryTimeoutIntervalIncrement = 0L;
    }
    
    return (retryTimeoutInterval + retryTimeoutIntervalIncrement) * NSEC_PER_SEC;
}

- (BOOL)restartTask {
    self.sliceDownloadFailedCount = 0;
    self.sliceCountHasDownloaded = 0;
    self.sliceCancelCount = 0;
    @synchronized (self.downloadSliceTaskArray) {
        for (TTDownloadSliceTask *sliceTask in self.downloadSliceTaskArray) {
            sliceTask.downloadSliceTaskConfig.sliceStatus = RESTART;
            sliceTask.downloadSliceTaskConfig.retryTimes = sliceTask.downloadSliceTaskConfig.retryTimesMax > 0 ? sliceTask.downloadSliceTaskConfig.retryTimesMax : SLICE_MAX_RETRY_TIMES;
        }
    }
    return YES;
}

- (StatusCode)mergeSubSliceImpl {
    /**
     *If task's status is downloaded,will return immediately.
     */
    if (self.taskConfig.downloadStatus == DOWNLOADED) {
        DLLOGD(@"task's status is downloaded,return ERROR_MERGE_SUCCESS");
        return ERROR_MERGE_SUCCESS;
    }
    
    if (self.taskConfig.downloadSliceTaskConfigArray.count == 1 && ![self isRangeDownloadEnable]) {
        TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray firstObject];
        if (sliceConfig.subSliceInfoArray.count == 1) {
            TTDownloadSubSliceInfo *subSlice = [sliceConfig.subSliceInfoArray lastObject];
            NSString *fromPath = [self.downloadTaskSliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
            NSString *toPath = [self.downloadTaskFullPath stringByAppendingPathComponent:self.taskConfig.fileStorageName];
            DLLOGD(@"slice just one,rename it,fromPath=%@,toPath=%@", fromPath, toPath);
            NSError *error = nil;
            if (![[TTDownloadManager class] moveItemAtPath:fromPath toPath:toPath overwrite:YES error:&error]) {
                [self.dllog addDownloadLog:nil error:error];
                DLLOGD(@"Unable to move file %@ to %@", fromPath, self.downloadTaskFullPath);
                return ERROR_MOVE_DOWNLOAD_FILE_FAILED;
            } else {
                return ERROR_MERGE_SUCCESS;
            }
        }
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *mergedFilePath   = [self.downloadTaskFullPath stringByAppendingPathComponent:self.taskConfig.fileStorageName];
    DLLOGD(@"dlLog:mergeFilePath=%@", mergedFilePath);
    
    int64_t mergeDataLength = [self getMergeDataLength];
    
    DLLOGD(@"mergeImpl:mergeDataLength=%lld", mergeDataLength);
    if (![[TTDownloadManager shareInstance] deleteFile:mergedFilePath]) {
        DLLOGD(@"dlLog:delete merge file error");
        return ERROR_DELETE_MERGE_FILE_FAILED;
    }

    NSError *error = nil;
    if (![TTDownloadManager createNewFileAtPath:mergedFilePath error:&error]) {
        NSString *log = error.description;
        DLLOGE(@"error=%@", log);
        [self.dllog addDownloadLog:nil error:error];
        return ERROR_CREATE_MERGE_FILE_FAILED;
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:mergedFilePath];
    
    for (TTDownloadSliceTaskConfig *sliceConfig in self.taskConfig.downloadSliceTaskConfigArray) {
        DLLOGD(@"dlLog:slice number=%d,total size=%lld",sliceConfig.sliceNumber,sliceConfig.sliceTotalLength);
        if (!self.isSkipGetContentLength
            && ![self isRangeDownloadEnable]
            && (sliceConfig.hasDownloadedLength != sliceConfig.sliceTotalLength)) {
            DLLOGD(@"dlLog:slice size error,slice number:%d,real size=%lld,normal size=%lld", sliceConfig.sliceNumber, sliceConfig.hasDownloadedLength, sliceConfig.sliceTotalLength);
            [fileHandle closeFile];
            return ERROR_MERGE_SLICE_SIZE_ERROR;
        }

        StatusCode ret = [sliceConfig mergeSubSlice:self.downloadTaskSliceFullPath
                                         fileHandle:fileHandle
                                    mergeDataLength:mergeDataLength
                             isSkipGetContentLength:self.isSkipGetContentLength];
        if (ERROR_MERGE_SUCCESS != ret) {
            [fileHandle closeFile];
            [fileManager removeItemAtPath:mergedFilePath error:nil];
            return ret;
        }
    }
    [fileHandle closeFile];

    return ERROR_MERGE_SUCCESS;
}

- (void)p_sendMergeAllSliceEventWithStartInterval:(NSTimeInterval)mergeStartTime {
    if (self.isTrackerEnable == NO) {
        return;
    }

    self.trackModel.sliceMergeTime = ceil((CFAbsoluteTimeGetCurrent() - mergeStartTime) * 1000);
}

- (BOOL)checkLastSubSlice {
    if (self.isSkipGetContentLength || [self isRangeDownloadEnable]) {
        return YES;
    }
    for (TTDownloadSliceTaskConfig *sliceTaskConfig in self.taskConfig.downloadSliceTaskConfigArray) {
        if (![sliceTaskConfig checkLastSubSlice:self]) {
            return NO;
        }
    }
    return YES;
}
#ifdef DOWNLOADER_DEBUG
- (void) printSubSliceInfo {
    for (TTDownloadSliceTaskConfig *sliceTaskConfig in self.taskConfig.downloadSliceTaskConfigArray) {
        [sliceTaskConfig printSubSliceInfo:self];
    }
}
#endif
- (StatusCode)mergeAllSlice {
    NSTimeInterval mergeStartTime = CFAbsoluteTimeGetCurrent();
    NSString *downloadTaskPath = [[TTDownloadManager shareInstance].appSupportPath stringByAppendingPathComponent:self.taskConfig.fileStorageDir];

#ifdef DOWNLOADER_DEBUG
    [self printSubSliceInfo];
#endif
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath]) {
        NSString *downloadTaskPath2 = [[TTDownloadManager shareInstance].cachePath stringByAppendingPathComponent:self.taskConfig.fileStorageDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTaskPath2]) {
            [[TTDownloadManager class] moveItemAtPath:downloadTaskPath2
                                               toPath:downloadTaskPath
                                            overwrite:YES
                                                error:nil];
            [[TTDownloadManager class] addSkipBackupAttributeToItemAtPath:downloadTaskPath];
        } else {
            [self p_sendMergeAllSliceEventWithStartInterval:mergeStartTime];
            return ERROR_DOWNLOADED_FILE_MISS;
        }
    }
    NSString *mergedFilePath = [downloadTaskPath stringByAppendingPathComponent:self.taskConfig.fileStorageName];
    DLLOGD(@"dlLog:mergeFilePath=%@", mergedFilePath);

    if (![self checkLastSubSlice]) {
        return ERROR_CHECK_LAST_SUB_SLICE_SIZE_FAILED;
    }
    /**
     *If url support range, start merging.
     */
    if (self.isServerSupportAcceptRange) {
        StatusCode ret = [self mergeSubSliceImpl];
        if (ERROR_MERGE_SUCCESS != ret) {
            [self p_sendMergeAllSliceEventWithStartInterval:mergeStartTime];
            return ret;
        }
    } else {
        if ([self isRangeDownloadEnable]) {
            return ERROR_RANGE_TASK_NOT_SUPPORT_RANGE;
        }
        /**
         *If url doesn't support range,it means slice is the destination file.So just rename.
         */
        TTDownloadSliceTaskConfig *sliceConfig = [self.taskConfig.downloadSliceTaskConfigArray firstObject];
        if (self.taskConfig.downloadSliceTaskConfigArray.count == 1 && sliceConfig.subSliceInfoArray.count == 1) {
            TTDownloadSubSliceInfo *subSlice = [sliceConfig.subSliceInfoArray lastObject];
            NSString *fromPath = [self.downloadTaskSliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
            NSString *toPath = [self.downloadTaskFullPath stringByAppendingPathComponent:self.taskConfig.fileStorageName];
            NSError *error;
            if (![[TTDownloadManager class] moveItemAtPath:fromPath toPath:toPath overwrite:YES error:&error]) {
                DLLOGD(@"Unable to move file %@ to %@", fromPath, self.downloadTaskFullPath);
                [self.dllog addDownloadLog:nil error:error];
                [self p_sendMergeAllSliceEventWithStartInterval:mergeStartTime];
                return ERROR_MOVE_DOWNLOAD_FILE_FAILED;
            }
        } else {
            DLLOGE(@"task doesn't support range,and slice not one");
            [self p_sendMergeAllSliceEventWithStartInterval:mergeStartTime];
            return ERROR_NO_RANGE_SLICE_NO_ONE;
        }
        
    }

    [self p_sendMergeAllSliceEventWithStartInterval:mergeStartTime];
    /**
     *If md5 isn't nil, will check md5.Otherwise do nothing.
     */
    StatusCode md5CheckResult = [self md5Check:mergedFilePath];
    if ((ERROR_TTMD5_CHECK_FAILED == md5CheckResult)
        || ERROR_MD5_CHECK_FAILED_WHILE_MERGE == md5CheckResult) {
        return md5CheckResult;
    }

    return ERROR_MERGE_SUCCESS;
}

- (StatusCode)md5Check:(NSString *)mergedFilePath {
    StatusCode ret = ERROR_MD5_CHECK_IGNORE;

    if (!_taskConfig.md5Value || ([_taskConfig.md5Value length] <= 0)) {
        return ret;
    }
    NSTimeInterval md5StartTime = CFAbsoluteTimeGetCurrent();
    NSString *serverMd5Value = [_taskConfig.md5Value lowercaseString];
    
    TTDownloadTTMd5Code ttmd5Code = TT_DOWNLOAD_TTMD5_NOT_SUPPORT;
    if (_TTMd5Callback) {
        ttmd5Code = _TTMd5Callback(_taskConfig.md5Value, mergedFilePath);
    }
    
    if (TT_DOWNLOAD_TTMD5_NOT_SUPPORT != ttmd5Code) {
        if (TT_DOWNLOAD_TTMD5_CHECK_PASS == ttmd5Code) {
            ret = ERROR_TTMD5_CHECK_OK;
        } else {
            ret = ERROR_TTMD5_CHECK_FAILED;
            [_dllog addDownloadLog:[NSString stringWithFormat:@"TTMd5 error code=%lu", (unsigned long)ttmd5Code] error:nil];
        }
    } else {
        NSString *mergeFileMd5Value = [[TTNetworkUtil calculateFileMd5WithFilePath:mergedFilePath] lowercaseString];
        DLLOGD(@"dlLog:mergeFileMd5Value=%@,serverMd5Value=%@", mergeFileMd5Value, serverMd5Value);
        if (![serverMd5Value isEqualToString:mergeFileMd5Value]) {
            ret = ERROR_MD5_CHECK_FAILED_WHILE_MERGE;
        } else {
            ret = ERROR_MD5_CHECK_OK;
        }
    }
    
    if (self.isTrackerEnable) {
        self.trackModel.md5Time = ceil((CFAbsoluteTimeGetCurrent() - md5StartTime) * 1000);
    }
    return ret;
}

- (void)deleteTask:(TTDownloadResultBlock)deleteResultBlock {
    if (deleteResultBlock) {
        [self setBlock:deleteResultBlock];
    }

    self.isDelete = YES;
    [self cancelTask];
}

- (void)setBlock:(TTDownloadResultBlock)block {
    @synchronized (self) {
        TTDownloadResultBlock oldBlock = self.resultBlock;
        self.resultBlock = ^(DownloadResultNotification *resultNotification) {
            if (oldBlock) {
                oldBlock(resultNotification);
            }
            if (block) {
                block(resultNotification);
            }
        };
    }
}

- (void)cancelTask {
    self.isCancelTask = YES;
    if (self.requestTask) {
        [self.requestTask cancel];
    }
    [self cancelTaskWithNeedTrack:YES];
}

- (void)cancelTaskWithNeedTrack:(BOOL)needTrack {
    if (self.taskConfig && (DOWNLOADED != self.taskConfig.downloadStatus)) {
        if (needTrack) {
            [self processCancelEventIsSaveDB:YES];
        }
        
        if (!self.isAppAtBackground && !self.isMobileSwitchToWifiCancel) {
            self.isCancelTask = YES;
        }

        @synchronized (self.downloadSliceTaskArray) {
            for (TTDownloadSliceTask *sliceTask in self.downloadSliceTaskArray) {
                [sliceTask cancel];
            }
        }

        if (needTrack) {
            [self processCancelEventIsSaveDB:YES];
        }
    }
}

- (int64_t)getRealNetSpeed:(int64_t)bytesPerSecond {
    int downloadingTaskCount = 0;

    if (self.taskConfig
        && (DOWNLOADING == self.taskConfig.downloadStatus)) {
        @synchronized (self.downloadSliceTaskArray) {
            for (TTDownloadSliceTask *sliceTask in self.downloadSliceTaskArray) {
                switch (sliceTask.downloadSliceTaskConfig.sliceStatus) {
                    case DOWNLOADING:
                    case RETRY:
                    case WAIT_RETRY:
                    case RESTART:
                    case INIT:
                        downloadingTaskCount++;
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    if (downloadingTaskCount > 0 && bytesPerSecond > 0) {
         return ceilf(bytesPerSecond / downloadingTaskCount);
    } else {
        return 0;
    }
}
#ifdef TT_DOWNLOAD_DYNAMIC_THROTTLE
- (void)setThrottleSpeed:(int64_t)speed {

    if ([[TTDownloadManager shareInstance] getTncConfig].isTncSetThrottleNetSpeed) {
        speed = [[[TTDownloadManager shareInstance] getTncConfig] getThrottleNetSpeed];
    }
    
    self.throttleNetSpeed = speed;
    if (speed <= kDynamicThrottleBalanceEnable) {
        self.isDynamicThrottleEnable = YES;
        if (!self.dynamicThrottle) {
            [self createDynamicThrottle];
        }
        [self.dynamicThrottle setDynamicThrottleSpeed:speed];
        [self.dynamicThrottle startMeasureBandwidth];
    } else {
        self.isDynamicThrottleEnable = NO;
        [self setThrottleNetSpeed2:speed];
    }
}
#endif
- (BOOL)setThrottleNetSpeed2:(int64_t)bytesPerSecond {
    
    if (bytesPerSecond < 0) {
        return NO;
    }

    int64_t realNetSpeed = [self getRealNetSpeed:bytesPerSecond];
    self.throttleNetSpeed = bytesPerSecond;

    if (self.taskConfig && (DOWNLOADING == self.taskConfig.downloadStatus)) {
        @synchronized (self.downloadSliceTaskArray) {
            for (TTDownloadSliceForegroundTask *sliceTask in self.downloadSliceTaskArray) {
                switch (sliceTask.downloadSliceTaskConfig.sliceStatus) {
                    case DOWNLOADING:
                    case RETRY:
                    case WAIT_RETRY:
                    case RESTART:
                    case INIT:
                        [sliceTask setThrottleNetSpeed:realNetSpeed];
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    return YES;
}

#pragma mark - track

- (void)processCreateEventIsSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendEvent:TTDownloadEventCreate eventModel:self.trackModel];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (void)processFirstStartEventIsSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendEvent:TTDownloadEventFirstStart eventModel:self.trackModel];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (void)processStartEventIsSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendEvent:TTDownloadEventStart eventModel:self.trackModel];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (void)processFailEventWithCode:(NSInteger)code failMsg:(NSString *)msg isSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendFailEventWithModel:self.trackModel failCode:code failMsg:msg];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (void)processCancelEventIsSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendCancelEventWithModel:self.trackModel];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (void)processFinishEventIsSaveDB:(BOOL)saveDB {
    if (!self.isTrackerEnable) {
        return;
    }

    [TTDownloadTracker.sharedInstance sendFinishEventWithModel:self.trackModel];
    if (saveDB) {
        [TTDownloadManager.shareInstance addTrackModelToDB:self.trackModel];
    }
}

- (int8_t)getUrlRetryTimes {
    int8_t retryMax = (self.userParameters && self.userParameters.urlRetryTimes > 0) ? self.userParameters.urlRetryTimes : GET_LENGTH_RETRY_MAX;

    if ([[[TTDownloadManager shareInstance] getTncConfig] getUrlRetryTimes] > 0) {
        retryMax = [[[TTDownloadManager shareInstance] getTncConfig] getUrlRetryTimes];
    }
    return retryMax;
}

- (NSTimeInterval)getRetryTimeoutInterval {
    int64_t retryTimeoutInterval = 10L;

    if ([[[TTDownloadManager shareInstance] getTncConfig] getRetryTimeoutInterval] > 0) {
        retryTimeoutInterval = [[[TTDownloadManager shareInstance] getTncConfig] getRetryTimeoutInterval];
    } else if (self.userParameters.retryTimeoutInterval > 0) {
        retryTimeoutInterval = self.userParameters.retryTimeoutInterval;
    }
    return retryTimeoutInterval;
}

- (NSTimeInterval)getRetryTimeoutIntervalIncrement {
    NSTimeInterval retryTimeoutIntervalIncrement = 0L;

    if ([[[TTDownloadManager shareInstance] getTncConfig] getRetryTimeoutIntervalIncrement] > 0) {
        retryTimeoutIntervalIncrement = [[[TTDownloadManager shareInstance] getTncConfig] getRetryTimeoutIntervalIncrement];
    } else if (self.userParameters.retryTimeoutIntervalIncrement > 0) {
        retryTimeoutIntervalIncrement = self.userParameters.retryTimeoutIntervalIncrement;
    }
    return retryTimeoutIntervalIncrement;
}

- (BOOL)isIgnoreMaxAgeCheck {
    int8_t isIgnoreMaxAge = [[TTDownloadManager shareInstance] getTncConfig].tncIsIgnoreMaxAgeCheck;

    if (isIgnoreMaxAge >= 0) {
        return isIgnoreMaxAge > 0 ? YES : NO;
    }

    if (self.userParameters) {
         return self.userParameters.isIgnoreMaxAgeCheck;
    }
    return NO;
}

- (BOOL)getIsSliced {
    int8_t isSliced = [[TTDownloadManager shareInstance] getTncConfig].tncIsSliced;
    
    if (isSliced >= 0) {
        return isSliced > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isSliced : NO;
}

- (NSInteger)getSliceMaxNumber {
    NSInteger sliceTotal = (self.userParameters && self.userParameters.sliceMaxNumber > 0 && self.userParameters.sliceMaxNumber <= ALLOW_SLICE_TOTAL_MAX ) ? self.userParameters.sliceMaxNumber : ALLOW_SLICE_TOTAL_MAX;
    
    if ([[[TTDownloadManager shareInstance] getTncConfig] getSliceMaxNumber] > 0) {
        sliceTotal = [[[TTDownloadManager shareInstance] getTncConfig] getSliceMaxNumber];
    }
    return sliceTotal;
}

- (int64_t)getMinDevisionSize {
    int64_t allowDivisionSize = (self.userParameters && self.userParameters.minDevisionSize > 0) ? self.userParameters.minDevisionSize : ALLOW_DIVISION_SIZE_MIN;
    
    if ([[[TTDownloadManager shareInstance] getTncConfig] getMinDevisionSize] > 0) {
        allowDivisionSize = [[[TTDownloadManager shareInstance] getTncConfig] getMinDevisionSize];
    }
    return allowDivisionSize;
}

- (int64_t)getMergeDataLength {
    int64_t mergeDataLength = (self.userParameters && self.userParameters.mergeDataLength > 0) ? self.userParameters.mergeDataLength * UNIT_1_M : MERGE_DATA_LENGTH;
    
    if ([[[TTDownloadManager shareInstance] getTncConfig] getMergeDataLength] > 0) {
        mergeDataLength = [[[TTDownloadManager shareInstance] getTncConfig] getMergeDataLength] * UNIT_1_M;
    }
    return mergeDataLength;
}

- (int8_t)getSliceMaxRetryTimes {
    int8_t retryTimes = SLICE_MAX_RETRY_TIMES;

    if ([[[TTDownloadManager shareInstance] getTncConfig] getSliceMaxRetryTimes] > 0) {
        retryTimes = [[[TTDownloadManager shareInstance] getTncConfig] getSliceMaxRetryTimes];
    } else if (self.userParameters.sliceMaxRetryTimes > 0) {
        retryTimes = self.userParameters.sliceMaxRetryTimes;
    }
    return retryTimes;
}

- (int64_t)getContentLengthWaitMaxInterval {
    int64_t waitTime = (self.userParameters && self.userParameters.contentLengthWaitMaxInterval > 0) ? self.userParameters.contentLengthWaitMaxInterval : CONTENT_LENGTH_RETRY_WAIT_TIME;
    if ([[[TTDownloadManager shareInstance] getTncConfig] getContentLengthWaitMaxInterval] > 0) {
        waitTime = [[[TTDownloadManager shareInstance] getTncConfig] getContentLengthWaitMaxInterval];
    }
    return waitTime;
}

- (int64_t)getThrottleNetSpeed {
    int64_t speed = self.userParameters ? self.userParameters.throttleNetSpeed : 0;
    if ([[TTDownloadManager shareInstance] getTncConfig].isTncSetThrottleNetSpeed) {
        speed = [[[TTDownloadManager shareInstance] getTncConfig] getThrottleNetSpeed];
    }
    return speed;
}

- (BOOL)getIsHttps2HttpFallback {
    int8_t isHttps2HttpFallback = [[TTDownloadManager shareInstance] getTncConfig].tncIsHttps2HttpFallback;
    
    if (isHttps2HttpFallback >= 0) {
        return isHttps2HttpFallback > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isHttps2HttpFallback : NO;
}

- (BOOL)getIsDownloadWifiOnly {
    int8_t isWifiOnly = [[TTDownloadManager shareInstance] getTncConfig].tncIsDownloadWifiOnly;
    if (isWifiOnly >= 0) {
        return isWifiOnly > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isDownloadWifiOnly : NO;
}

- (BOOL)getIsRestartImmediatelyWhenNetworkChange {
    int8_t isRestartImmediately = [[TTDownloadManager shareInstance] getTncConfig].restartImmediatelyWhenNetworkChange;
    if (isRestartImmediately >= 0) {
        return isRestartImmediately > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isRestartImmediatelyWhenNetworkChange : NO;
}

- (int8_t)getRestoreTimesAutomatic {
    int8_t restoreTimesAuto = self.userParameters && self.userParameters.restoreTimesAutomatic > 0 ? self.userParameters.restoreTimesAutomatic : 0;

    if ([[[TTDownloadManager shareInstance] getTncConfig] getRestoreTimesAutomatic] > 0) {
        restoreTimesAuto = [[[TTDownloadManager shareInstance] getTncConfig] getRestoreTimesAutomatic];
    }
    return restoreTimesAuto;
}

- (BOOL)getIsUseTracker {
    int8_t isTrackerEnable = [[TTDownloadManager shareInstance] getTncConfig].tncIsUseTracker;
    
    if (isTrackerEnable >= 0) {
        BOOL isUseTracker = isTrackerEnable > 0 ? YES : NO;
        if (_userParameters) {
            _userParameters.isUseTracker = isUseTracker;
        }
        return isUseTracker;
    }
    return _userParameters ? _userParameters.isUseTracker : NO;
}

- (BOOL)getIsBackgroundDownloadEnable {
    int8_t isBackgroundDownloadEnable = [[TTDownloadManager shareInstance] getTncConfig].tncIsBackgroundDownloadEnable;

    if (isBackgroundDownloadEnable >= 0) {
        return isBackgroundDownloadEnable > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isBackgroundDownloadEnable : NO;
}

- (BOOL)getIsBackgroundDownloadWifiOnlyDisable {
    int8_t isBackgroundDownloadWifiOnlyDisable = [[TTDownloadManager shareInstance] getTncConfig].tncIsBackgroundDownloadWifiOnlyDisable;
    
    if (isBackgroundDownloadWifiOnlyDisable >= 0) {
        return isBackgroundDownloadWifiOnlyDisable > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isBackgroundDownloadWifiOnlyDisable : NO;
}

- (BOOL)getIsSkipGetContentLength {
    int8_t isSkipGetContentLength = [[TTDownloadManager shareInstance] getTncConfig].tncIsSkipGetContentLength;
    if (isSkipGetContentLength >= 0) {
        return isSkipGetContentLength > 0 ? YES : NO;
    }
    return self.userParameters ? _userParameters.isSkipGetContentLength : YES;
}

- (BOOL)getIsServerSupportRangeDefault {
    int8_t isServerSupportRangeDefault = [[TTDownloadManager shareInstance] getTncConfig].tncIsServerSupportRangeDefault;

    if (isServerSupportRangeDefault >= 0) {
        return isServerSupportRangeDefault > 0 ? YES : NO;
    }
    return _userParameters ? _userParameters.isServerSupportRangeDefault : NO;
}

@end

NS_ASSUME_NONNULL_END
