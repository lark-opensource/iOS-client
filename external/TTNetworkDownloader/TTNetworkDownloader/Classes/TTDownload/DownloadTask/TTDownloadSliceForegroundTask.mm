#import "TTDownloadSliceForegroundTask.h"
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kRange = @"Range";
static NSString * const kIfModifiedSince = @"If-Modified-Since";

typedef void (^ProgressCallbackBlock)(int64_t current, int64_t total);
typedef void (^CompletionHandlerBlock)(TTHttpResponse *response, NSURL *filePath, NSError *error);
typedef void (^SliceHeaderCallback)(TTHttpResponse *response);

@interface TTDownloadSliceForegroundTask()

@property (atomic, strong) TTHttpTask *task;

@property (atomic, assign) BOOL isRestartImmediately;
/**
 *The key uniquely identify a task.
 */
@property (readwrite, atomic, copy) NSString *urlKey;
/**
 *Second url.
 */
@property (readwrite, atomic, copy) NSString *secondUrl;

@property (readwrite, atomic, copy) NSString *sliceStorageDir;

@property (readwrite, atomic, assign) BOOL isRangeDownloadCompleted;

@end

@implementation TTDownloadSliceForegroundTask

@synthesize urlKey = _urlKey;
@synthesize secondUrl = _secondUrl;
@synthesize sliceStorageDir = _sliceStorageDir;

- (void)decreseRetryTimesAtomic {
    @synchronized(self) {
        self.downloadSliceTaskConfig.retryTimes--;
        DLLOGD(@"dlLog:decreseRetryTimesAtomic:self.downloadSliceTaskConfig.retryTimes=%d", self.downloadSliceTaskConfig.retryTimes);
    }
}

- (id)initWhithSliceConfig:(TTDownloadSliceTaskConfig*)downloadSliceTaskConfig downloadTask:(TTDownloadTask*)downloadTask {
    self = [super init];
    if (self) {
        self.downloadSliceTaskConfig = downloadSliceTaskConfig;
        self.urlKey                  = downloadSliceTaskConfig.urlKey;
        self.secondUrl               = downloadSliceTaskConfig.secondUrl;
        self.isTaskValid             = YES;
        self.downloadTask            = downloadTask;
        self.sliceStorageDir         = downloadTask.downloadTaskSliceFullPath;
        self.currSubSliceInfo        = [downloadSliceTaskConfig.subSliceInfoArray lastObject];
        self.isRestartImmediately    = NO;
        self.userParameters          = downloadTask.userParameters;
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:debug3:dealloc:function=%s addr=%p", __FUNCTION__, self);
}

- (BOOL)updateSubSliceInfoByRealFileSize {
    
    if (self.downloadTask.isSkipGetContentLength && self.currSubSliceInfo.sliceStatus == DOWNLOADED) {
        self.downloadSliceTaskConfig.sliceStatus = DOWNLOADED;
        if (!self.currSubSliceInfo.isImmutable) {
            self.currSubSliceInfo.rangeEnd = self.downloadSliceTaskConfig.hasDownloadedLength;
        }
        [self.downloadTask sliceCountHasDownloadedIncrease];
        DLLOGD(@"dlLog:updateSubSliceInfoByRealFileSize:slice DOWNLOADED,don't retry again,slicenumber=%d", self.downloadSliceTaskConfig.sliceNumber);
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int64_t subSliceFileLength = 0L;

    NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:self.currSubSliceInfo.subSliceFullPath error:nil];
    int64_t lastSubSliceStartRangeForRetry = self.currSubSliceInfo.rangeStart;

    if (nil == fileAttributeDic && [fileManager fileExistsAtPath:self.currSubSliceInfo.subSliceFullPath]) {
        self.downloadSliceTaskConfig.sliceStatus = FAILED;
        [self.downloadTask sliceDownloadFailedCountIncrease];
        return NO;
    } else if (!self.downloadTask.taskConfig.isSupportRange) {
        /**
         *If task doesn't support range, will delete exist slice and restart again.
         */
        if ([fileManager fileExistsAtPath:self.currSubSliceInfo.subSliceFullPath]) {
            [fileManager removeItemAtPath:self.currSubSliceInfo.subSliceFullPath error:nil];
        }
        self.downloadSliceTaskConfig.hasDownloadedLength = 0;
        DLLOGD(@"dlLog:debug hasDownloadedLength 1 = %lld", self.downloadSliceTaskConfig.hasDownloadedLength);
    } else {
        subSliceFileLength = fileAttributeDic.fileSize;
    }
    
    lastSubSliceStartRangeForRetry = self.currSubSliceInfo.rangeStart + subSliceFileLength;
    
    DLLOGD(@"dlLog:sliceNumber=%d,lastSubSliceStartRangeForRetry=%lld,self.downloadSliceTaskConfig.endByte=%lld",
           self.downloadSliceTaskConfig.sliceNumber, lastSubSliceStartRangeForRetry, self.downloadSliceTaskConfig.endByte);
    if (!self.downloadTask.isSkipGetContentLength && lastSubSliceStartRangeForRetry == self.downloadSliceTaskConfig.endByte) {
        self.downloadSliceTaskConfig.sliceStatus = DOWNLOADED;
        if (!self.currSubSliceInfo.isImmutable) {
            self.currSubSliceInfo.rangeEnd = self.downloadSliceTaskConfig.endByte;
        }
        [self.downloadTask sliceCountHasDownloadedIncrease];
        DLLOGD(@"dlLog:updateSubSliceInfoByRealFileSize:slice DOWNLOADED,don't retry again,slicenumber=%d", self.downloadSliceTaskConfig.sliceNumber);
        return NO;
    } else if (!self.downloadTask.isSkipGetContentLength && lastSubSliceStartRangeForRetry > self.downloadSliceTaskConfig.endByte) {
        DLLOGD(@"dlLog:slice size invalid:slice number=%d,lastSubSliceStartRangeForRetry=%lld,self.downloadSliceTaskConfig.endByte=%lld", self.downloadSliceTaskConfig.sliceNumber, lastSubSliceStartRangeForRetry, self.currSubSliceInfo.rangeEnd);
        [fileManager removeItemAtPath:self.currSubSliceInfo.subSliceFullPath error:nil];
        lastSubSliceStartRangeForRetry = self.currSubSliceInfo.rangeStart;
    }
    
    self.downloadSliceTaskConfig.startByte = lastSubSliceStartRangeForRetry;
    
    self.downloadSliceTaskConfig.hasDownloadedLength = [[TTDownloadManager class] getHadDownloadedLength:self.downloadSliceTaskConfig isReadLastSubSlice:YES];
    DLLOGD(@"dlLog:debug hasDownloadedLength 2 = %lld", self.downloadSliceTaskConfig.hasDownloadedLength);
    DLLOGD(@"dlLog:updateSubSliceInfoByRealFileSize:startByte=%lld,endByte=%lld,self.downloadTask.firstSliceNeedDownloadLength=%lld,self.downloadSliceTaskConfig.SliceNumber=%d", self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte,self.downloadTask.firstSliceNeedDownloadLength,self.downloadSliceTaskConfig.sliceNumber);
    return YES;
}

- (NSDictionary *)setRangeAndMergeUserHeader:(int64_t)startByte endByte:(int64_t)endByte {
    //Set range.
    NSMutableDictionary *headerField = [NSMutableDictionary dictionary];
    
    NSString *rangeValue = nil;
    if (self.downloadTask.isSkipGetContentLength) {
        rangeValue = [NSString stringWithFormat:@"bytes=%lld-", startByte];
    } else {
        rangeValue = [NSString stringWithFormat:@"bytes=%lld-%lld", startByte, endByte - 1];
    }
    DLLOGD(@"debugRange:setRangeAndMergeUserHeader:sliceNo=%d,subNo=%d,subName=%@,rangeValue=%@", self.currSubSliceInfo.sliceNumber, self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName, rangeValue);
    
    [headerField setObject:rangeValue forKey:kRange];
    
    if ([self.downloadTask getIsCheckCacheValid]) {
        DLLOGD(@"optimizeSmallTest:slice start lastModifiedTime=%@", self.downloadTask.originExtendConfig.lastModifiedTime);
        if (self.downloadTask.originExtendConfig.lastModifiedTime) {
            [headerField setObject:self.downloadTask.originExtendConfig.lastModifiedTime forKey:kIfModifiedSince];
        }
    }

    if (self.userParameters.httpHeaders && self.userParameters.httpHeaders.count > 0) {
        [self.userParameters.httpHeaders removeObjectForKey:kIfModifiedSince];
        [self.userParameters.httpHeaders removeObjectForKey:kRange];
        [headerField addEntriesFromDictionary:self.userParameters.httpHeaders];
    }
    DLLOGD(@"dlLog:headerField=%@", headerField);
    return headerField;
}

- (void)start {
    self.currSubSliceInfo = [self.downloadSliceTaskConfig.subSliceInfoArray lastObject];
    
    DLLOGD(@"fg task info:sliceNo=%d,subSliceNo=%lu,subSliceName=%@,sliceStatus=%ld,startRange=%lld,endRange=%lld,subStartRange=%lld,subEndRange=%lld,throttle=%lld", self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName, (long)self.downloadSliceTaskConfig.sliceStatus, self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte, self.currSubSliceInfo.rangeStart, self.currSubSliceInfo.rangeEnd, self.downloadSliceTaskConfig.throttleNetSpeed);
    
    /**
     *Invalid task check.
     */
    if (!self.currSubSliceInfo || !self.isTaskValid) {
        if (self.downloadSliceTaskConfig && self.downloadTask) {
            self.downloadSliceTaskConfig.sliceStatus = FAILED;
            [self.downloadTask sliceDownloadFailedCountIncrease];
        }
        return;
    }
    DLLOGD(@"self.downloadSliceTaskConfig.throttleNetSpeed=%lld", self.downloadSliceTaskConfig.throttleNetSpeed);
    if (!self.downloadTask) {
        return;
    }
    
    if (self.downloadSliceTaskConfig.retryTimes == NOT_RETRY) {
        DLLOGD(@"dlLog:donot retry again");
        self.downloadSliceTaskConfig.sliceStatus = FAILED;
        return;
    }
    /**
     *If no net,it won't send real request and will decrease retry times.If retry times reach 0,task will return failed.
     */
    if ([[TTDownloadManager class] isNetworkUnreachable]) {
        [self decreseRetryTimesAtomic];
        if (self.downloadSliceTaskConfig.retryTimes == NOT_RETRY) {
            self.downloadSliceTaskConfig.sliceStatus = FAILED;
            [self.downloadTask sliceDownloadFailedCountIncrease];
        } else {
            self.downloadSliceTaskConfig.sliceStatus = RETRY;
        }
        DLLOGD(@"dlLog:no net,so don't download slice sliceNumber=%d", self.downloadSliceTaskConfig.sliceNumber);
        if (self.downloadTask.sem) {
            dispatch_semaphore_signal(self.downloadTask.sem);
        }
        return;
    }
    
    if ((WAIT_RETRY == self.downloadSliceTaskConfig.sliceStatus)
        || (RESTART == self.downloadSliceTaskConfig.sliceStatus)) {
        
        if (![self updateSubSliceInfoByRealFileSize]) {
            DLLOGD(@"dlLog:don't retry again");
            /**
             * Here cant' call sliceDownloadFailedCountIncrease, because updateSubSliceInfoByRealFileSize
             * had called sliceDownloadFailedCountIncrease.
             */
            self.downloadSliceTaskConfig.retryTimes = NOT_RETRY;
            if (self.downloadTask.sem) {
                dispatch_semaphore_signal(self.downloadTask.sem);
            }
            return;
        }
        
        DLLOGD(@"dlLog:start(),retry or restart status=%ld,sliceNumber=%d,StartByte=%lld,endByte=%lld,hasDownloadlength=%lld",
               (long)self.downloadSliceTaskConfig.sliceStatus,
               self.downloadSliceTaskConfig.sliceNumber,
               self.downloadSliceTaskConfig.startByte,
               self.downloadSliceTaskConfig.endByte,
               self.downloadSliceTaskConfig.hasDownloadedLength);
    }
    
    self.downloadSliceTaskConfig.sliceStatus = DOWNLOADING;
    DLLOGD(@"dlLog:slice start:sliceConfig.urlKey=%@,sliceConfig.secondUrl=%@", self.downloadSliceTaskConfig.urlKey, self.downloadSliceTaskConfig.secondUrl);
    NSString *downloadUrl     = self.downloadTask.taskConfig.secondUrl ? self.downloadTask.taskConfig.secondUrl : self.downloadTask.taskConfig.urlKey;
    NSString *slicePath       = [self.downloadTask.downloadTaskSliceFullPath stringByAppendingPathComponent:self.currSubSliceInfo.subSliceName];
    NSURL *fileDestinationURL = nil;
    @try {
        fileDestinationURL = [NSURL fileURLWithPath:slicePath];
    } @catch (NSException *exception) {
        if (self.downloadSliceTaskConfig && self.downloadTask) {
            self.downloadSliceTaskConfig.sliceStatus = FAILED;
            [self.downloadTask sliceDownloadFailedCountIncrease];
        }
        return;
    }
    
    int64_t originalHasDownloadLength = self.downloadSliceTaskConfig.hasDownloadedLength;
    
    NSDictionary *headerField = [self setRangeAndMergeUserHeader:self.downloadSliceTaskConfig.startByte endByte:self.downloadSliceTaskConfig.endByte];
    
    DLLOGD(@"dlLog:sliceNO=%d,subNO=%lu,key=%@,downloadUrl=%@,startByte=%lld,endByte=%lld,file=%@", self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, self.urlKey, downloadUrl, self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte, fileDestinationURL);
    
    if (self.downloadSliceTaskConfig.isCancel) {
        DLLOGD(@"dlLog:call sliceCancelCountIncrease 1");
        [self.downloadTask sliceCancelCountIncrease];
        self.downloadSliceTaskConfig.sliceStatus = CANCELLED;
        if (self.downloadTask.sem) {
            dispatch_semaphore_signal(self.downloadTask.sem);
        }
        return;
    }
    [self.downloadTask.trackModel addCurRetryTime:1];
    dispatch_semaphore_t holdSem = self.downloadTask.sem;
    /**
     *Progress report.
     */
    __weak __typeof(self)weakSelf = self;
    ProgressCallbackBlock progressCallback = ^(int64_t current, int64_t total) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf.isTaskValid) {
            DLLOGD(@"dlLog:sliceTask is invalid,return");
            return;
        }
        strongSelf.downloadSliceTaskConfig.hasDownloadedLength = originalHasDownloadLength + current;
        
        if (strongSelf.downloadTask.isSkipGetContentLength
            && [strongSelf.downloadTask isRangeDownloadEnable]
            && (([strongSelf.downloadTask getStartOffset] + strongSelf.downloadSliceTaskConfig.hasDownloadedLength) >= strongSelf.downloadSliceTaskConfig.endByte)) {
            strongSelf.isRangeDownloadCompleted = YES;
            [strongSelf cancel];
        }
        
    };
    
    int64_t endByte = self.downloadSliceTaskConfig.endByte;
    
    SliceHeaderCallback headerCallback = ^(TTHttpResponse *response) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.downloadTask.onHeaderCallback) {
            if (!strongSelf.downloadTask.onHeaderCallback(response)) {
                /**
                 *Cancel task, and return cache.
                 */
                if (strongSelf.task) {
                    [strongSelf.task cancel];
                }
            }
        }
    };

    /**
     *Download result report.
     */
    CompletionHandlerBlock completionHandler = ^(TTHttpResponse *response, NSURL *filePath, NSError *error) {
        
        if (!self.isTaskValid) {
            DLLOGD(@"dlLog:sliceTask is invalid,return");
            return;
        }

        if (self.downloadTask.isAppAtBackground && self.downloadTask.isRestartTask) {
            self.downloadSliceTaskConfig.sliceStatus = BACKGROUND;
            return;
        }
        
        if (error) {
            DLLOGD(@"dlLog:finish:error=%ld", (long)[error code]);
            
            if ([error code] == NSURLErrorCancelled || (response.statusCode == 304)) {
                if (self.isRangeDownloadCompleted) {
                    DLLOGD(@"skip get content length,range download finished,endByte=%lld,hadDownload=%lld,stepRangeEnd=%lld", self.downloadSliceTaskConfig.endByte, self.downloadSliceTaskConfig.hasDownloadedLength, [self.downloadTask getStartOffset] + self.downloadSliceTaskConfig.hasDownloadedLength);

                    self.downloadSliceTaskConfig.sliceStatus = DOWNLOADED;
                    if (!self.currSubSliceInfo.isImmutable) {
                        self.currSubSliceInfo.rangeEnd = endByte;
                    }
                    self.currSubSliceInfo.sliceStatus = DOWNLOADED;
                    NSError *error = nil;
                    if (![[TTDownloadManager shareInstance] insertOrUpdateSubSliceInfo:self.currSubSliceInfo error:&error]) {
                        [self.downloadTask.dllog addDownloadLog:@"fgRangeTask error" error:error];
                    }
                    [self.downloadTask sliceCountHasDownloadedIncrease];
                    
                } else {
                    DLLOGD(@"dlLog8:call sliceCancelCountIncrease 2");
                    [self.downloadTask sliceCancelCountIncrease];
                    self.downloadSliceTaskConfig.sliceStatus = CANCELLED;
                    DLLOGD(@"dlLog:timing:+_++++foreground cancel finished+++++sliceNumber=%d,sub=%lu,subName=%@",
                           self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName);
                }
            } else {
                if (self.isRestartImmediately) {
                    DLLOGD(@"dlLog:switch:isRestartImmediately=YES,RESTART");
                    self.isRestartImmediately = NO;
                    self.downloadSliceTaskConfig.sliceStatus = RESTART;
                } else {
                    [self.downloadTask addHttpResponse:response];
                    DLLOGD(@"dlLog:retryCallback:sliceNumber=%d,will retry,startByte=%lld,endByte=%lld", self.downloadSliceTaskConfig.sliceNumber, self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte);
                    [self decreseRetryTimesAtomic];
                    if (self.downloadSliceTaskConfig.retryTimes == NOT_RETRY) {
                        self.downloadSliceTaskConfig.sliceStatus = FAILED;
                        [self.downloadTask sliceDownloadFailedCountIncrease];
                    } else {
                        self.downloadSliceTaskConfig.sliceStatus = RETRY;
                    }
                }
            }
        } else {
            DLLOGD(@"dlLog:finish:slice download successfully");
            self.downloadSliceTaskConfig.sliceStatus = DOWNLOADED;
            if (!self.currSubSliceInfo.isImmutable) {
                self.currSubSliceInfo.rangeEnd = endByte;
            }
            self.currSubSliceInfo.sliceStatus = DOWNLOADED;

            NSError *error = nil;
            if (self.downloadTask.isSkipGetContentLength) {
                if (![[TTDownloadManager shareInstance] insertOrUpdateSubSliceInfo:self.currSubSliceInfo error:&error]) {
                    [self.downloadTask.dllog addDownloadLog:@"fgTask error" error:error];
                }
            }
            [self.downloadTask sliceCountHasDownloadedIncrease];
        }
        
        self.task = nil;
        DLLOGD(@"dlLog:1:wake up downloadTask pthread");
        if (nil != holdSem) {
            dispatch_semaphore_signal(holdSem);
        }
    };
    
    self.task = [[TTNetworkManager shareInstance] downloadTaskBySlice:downloadUrl
                                                           parameters:nil
                                                          headerField:headerField
                                                     needCommonParams:[self.downloadTask getIsCommonParamEnable]
                                                    requestSerializer:nil
                                                     progressCallback:progressCallback
                                                          destination:fileDestinationURL
                                                           autoResume:NO
                                                    completionHandler:completionHandler];
    if (self.task) {
        [_task setThrottleNetSpeed:self.downloadSliceTaskConfig.throttleNetSpeed];
        [_task setHeaderCallback:headerCallback];

        _task.enableHttpCache = NO;
       
        DLLOGD(@"setTimeout:self.task.protectTimeout=%d", [self.downloadTask getTTNetProtectTimeout]);
        if ([self.downloadTask getTTNetProtectTimeout] > 0) {
            self.task.protectTimeout = [self.downloadTask getTTNetProtectTimeout];
        }
        
        DLLOGD(@"setTimeout: self.task.recvHeaderTimeout=%d", [self.downloadTask getTTNetRcvHeaderTimeout]);
        if ([self.downloadTask getTTNetRcvHeaderTimeout] > 0) {
            self.task.recvHeaderTimeout = [self.downloadTask getTTNetRcvHeaderTimeout];
        }
        
        DLLOGD(@"setTimeout:self.task.readDataTimeout=%d", [self.downloadTask getTTNetReadDataTimeout]);
        if ([self.downloadTask getTTNetReadDataTimeout] > 0) {
            self.task.readDataTimeout = [self.downloadTask getTTNetReadDataTimeout];
        }
        
        DLLOGD(@"setTimeout:self.task.timeoutInterval=%d", [self.downloadTask getTTNetRequestTimeout]);
        if ([self.downloadTask getTTNetRequestTimeout] > 0) {
            self.task.timeoutInterval = [self.downloadTask getTTNetRequestTimeout];
        }
        self.task.enableHttpCache = NO;
        [self.task resume];
    }
    
    if (self.downloadSliceTaskConfig.isCancel) {
        if (self.task) {
            [self.task cancel];
        } else {
            DLLOGD(@"dlLog8:call sliceCancelCountIncrease 3");
            [self.downloadTask sliceCancelCountIncrease];
            self.downloadSliceTaskConfig.sliceStatus = CANCELLED;
        }
    }
}

- (void)cancel {
    DLLOGD(@"dlLog:self.downloadTask.isAppAtBackground=%d,self.downloadTask.isMobileSwitchToWifiCancel=%d",
           self.downloadTask.isAppAtBackground, self.downloadTask.isMobileSwitchToWifiCancel);
    if ((!self.downloadTask.isAppAtBackground && !self.downloadTask.isMobileSwitchToWifiCancel)
        || self.downloadTask.isCancelTask) {
        self.downloadSliceTaskConfig.isCancel = YES;
    }
    DLLOGD(@"dlLog:timing:+_++++foreground start cancel+++++sliceNumber=%d,sub=%lu,subName=%@",
           self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName);
    if (self.startTaskDelayHandle) {
        [TTNetworkUtil dispatchDelayedBlockImmediately:self.startTaskDelayHandle];
    }
    
    if (self.task != nil) {
        [self.task cancel];
    }
}

- (bool)setThrottleNetSpeed:(int64_t)bytesPerSecond {
    self.downloadSliceTaskConfig.throttleNetSpeed = bytesPerSecond;
    if (DOWNLOADING == self.downloadSliceTaskConfig.sliceStatus && self.task) {
        [self.task setThrottleNetSpeed:bytesPerSecond];
    }
    return YES;
}

- (void)clearReferenceCount {
    DLLOGD(@"bgDlLog:bgTask:clearReferenceCount");
    self.isTaskValid = NO;
    self.downloadTask = nil;
    self.downloadSliceTaskConfig = nil;
    self.currSubSliceInfo = nil;
}

- (void)setRestartImmediately {
    self.isRestartImmediately = YES;
}

@end

NS_ASSUME_NONNULL_END
