#import "TTDownloadSliceTask.h"
#import "TTDownloadSubSliceBackgroundTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTDownloadSubSliceBackgroundTask()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (atomic, strong) NSURLSession *backgroundSession;

@property (atomic, strong) NSURLSessionDownloadTask *task;

@property (readwrite, atomic, copy) NSString *urlKey;

@property (readwrite, atomic, copy) NSString *secondUrl;

@property (readwrite, atomic, copy) NSString *sliceStorageDir;

@property (atomic, assign) int64_t currRangeEnd;
@end

@implementation TTDownloadSubSliceBackgroundTask
@synthesize urlKey = _urlKey;
@synthesize secondUrl = _secondUrl;
@synthesize sliceStorageDir = _sliceStorageDir;

- (id)initWhithSliceConfig:(TTDownloadSliceTaskConfig*)sliceConfig downloadTask:(TTDownloadTask *)downloadTask {
    self = [super init];

    if (self) {
        self.downloadTask            = downloadTask;
        self.downloadSliceTaskConfig = sliceConfig;
        self.isTaskValid             = YES;
        self.urlKey                  = sliceConfig.urlKey;
        self.secondUrl               = sliceConfig.secondUrl;
        self.currSubSliceInfo        = [sliceConfig.subSliceInfoArray lastObject];
        self.userParameters          = downloadTask.userParameters;
        self.sliceStorageDir         = downloadTask.downloadTaskSliceFullPath;
        self.currRangeEnd            = 0L;
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"bgDlLog:bgTask::TTDownloadSubSliceBackgroundTask dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

- (void)clearReferenceCount {
    self.downloadTask = nil;
    self.currSubSliceInfo = nil;
    self.downloadSliceTaskConfig = nil;
    self.userParameters = nil;
}

#pragma mark "backgroundDownload"
- (void)initSession {
    if (!self.downloadTask.isAppAtBackground) {
        return;
    }

    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *identifier = [NSString stringWithFormat:@"%@.%@.%d.%lu.%u.identifier", bundleId, self.currSubSliceInfo.fileStorageDir, self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, arc4random()];
    DLLOGD(@"bgDlLog:bgTask::initSession:identifier=%@", identifier);
    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];

    BOOL isBackgroundDownloadWifiOnlyDisable = [self.downloadTask getIsBackgroundDownloadWifiOnlyDisable];

    if (isBackgroundDownloadWifiOnlyDisable) {
        configuration.discretionary = YES;
    } else {
        configuration.allowsCellularAccess = NO;
    }

    configuration.sessionSendsLaunchEvents = YES;
    self.backgroundSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
}

- (void)setInvaildForBgTask {
    self.isTaskValid = NO;
    DLLOGD(@"dlLog:setInvaildForBgTask:self.backgroundTask.state=%ld", (long)self.task.state);
    if (self.task && self.task.state != NSURLSessionTaskStateCompleted && self.task.state != NSURLSessionTaskStateCanceling) {
        [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        }];
    }
}

- (void)setHttpHeaderField:(NSMutableURLRequest *)request {
    NSString *rangeValue = nil;
    if (self.downloadTask.isSkipGetContentLength && ![self.downloadTask isRangeDownloadEnable]) {
        /**
         *The old code maybe use follow logic.So we must keep it.
         */
        rangeValue = [NSString stringWithFormat:@"bytes=%lld-", self.downloadSliceTaskConfig.startByte];
    } else {
        rangeValue = [NSString stringWithFormat:@"bytes=%lld-%lld", self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte - 1];
        self.currRangeEnd = self.downloadSliceTaskConfig.endByte;
    }

    [request setValue:rangeValue forHTTPHeaderField:@"Range"];
    if (self.userParameters.httpHeaders && self.userParameters.httpHeaders.count > 0) {
        [self.userParameters.httpHeaders removeObjectForKey:@"Range"];
        NSArray *arr = [self.userParameters.httpHeaders allKeys];
        for (int i = 0; i < arr.count; ++i) {
            if (arr[i]) {
                [request setValue:[self.userParameters.httpHeaders objectForKey:arr[i]] forHTTPHeaderField:arr[i]];
            }
        }
    }
}

- (void)start {
    if (!self.downloadTask.isAppAtBackground) {
        return;
    }
    
    [self initSession];
    
    if (!self.downloadTask.isAppAtBackground) {
        return;
    }

    NSString *realUrl = self.secondUrl ? self.secondUrl : self.urlKey;
    
    if (self.userParameters.backgroundBOEDomain) {
        NSURLComponents *url = [[NSURLComponents alloc] initWithString:realUrl];
        DLLOGD(@"url=%@", url);
        url.host = [NSString stringWithFormat:@"%@%@", url.host, self.userParameters.backgroundBOEDomain];
        realUrl = [url string];
    }

    NSURL *url = [NSURL URLWithString:realUrl];
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url];
    
    [self setHttpHeaderField:mRequest];
    self.task = [self.backgroundSession downloadTaskWithRequest:mRequest];
    
    if (!self.downloadTask.isAppAtBackground) {
        return;
    }

    [[TTDownloadManager shareInstance] addBgIdentifierDicLock:self.backgroundSession.configuration.identifier value:self.urlKey];
    [self.task resume];
}

/**
 *  NSURLSessionTaskStateRunning = 0,    The task is currently being serviced by the session
 *  NSURLSessionTaskStateSuspended = 1,
 *  NSURLSessionTaskStateCanceling = 2,  The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message.
 *  NSURLSessionTaskStateCompleted = 3,  The task has completed and the session will receive no more delegate notifications
 */
- (void)cancel {
    DLLOGD(@"bgDlLog:bgTask::timing:+_++++call backgroundSliceTaskCancel cancel+++++sliceNumber=%d,sub=%ld,subName=%@,status=%ld,retainCount=%ld",
           self.currSubSliceInfo.sliceNumber, self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName, (long)self.task.state, CFGetRetainCount((__bridge CFTypeRef)(self)));
    if (self.task && self.downloadSliceTaskConfig.sliceStatus != DOWNLOADED) {
        DLLOGD(@"bgDlLog:bgTask::++++++++backgroundSliceTaskCancel++++2+++++");
        [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            DLLOGD(@"resumeData=%@", resumeData);
        }];
    }
}

- (NSString *)getTempFilePath:(NSMutableDictionary *)resumeDictionary {
    if (!resumeDictionary) {
        return nil;
    }
    
    int download_version = [[resumeDictionary objectForKey:@"NSURLSessionResumeInfoVersion"] intValue];
    if (download_version > 1) {
        NSString *tmpFile = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoTempFileName"];
        return [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFile];
    } else {
        return [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    }
}

- (BOOL)moveTempToTaskDir:(NSData *)resumeData to:(NSString *)to{
    DLLOGD(@"bgDlLog:bgTask::moveTempToTaskDir++++enter moveTempToTaskDir++++to=%@", to);
    if (!resumeData || !to) {
        DLLOGE(@"bgDlLog:bgTask::moveTempToTaskDir,parameters error");
        return NO;
    }
    NSMutableDictionary *resumeDictionary;

    resumeDictionary = [[TTDownloadManager class] parseResumeData:resumeData];
    if (!resumeDictionary) {
        DLLOGE(@"bgDlLog:bgTask::moveTempToTaskDir,error resumeData is nil");
        return NO;
    }
#ifdef DOWNLOADER_DEBUG
    DLLOGD(@"bgDlLog:bgTask::moveTempToTaskDir:resumeDictionary:>>>>>>>>>>>>>>>>>>>>>>>>>>");
    NSArray *keyArr= [resumeDictionary allKeys];

    for (int i=0; i<keyArr.count; i++) {
        DLLOGD(@"bgDlLog:bgTask::moveTempToTaskDir:resumeDictionary %@---%@", keyArr[i], [resumeDictionary objectForKey:keyArr[i]]);
    }
    DLLOGD(@"bgDlLog:bgTask::moveTempToTaskDir:resumeDictionary<<<<<<<<<<<<<<<<<<<<<<<<<<<");
    
    DLLOGD(@"bgDlLog:bgTask::sleep:dlLog:bytesReceived=%@", [resumeDictionary objectForKey:@"NSURLSessionResumeBytesReceived"]);
#endif
    NSString *tempFileFullPath = [self getTempFilePath:resumeDictionary];
    if (!tempFileFullPath) {
        return NO;
    }
    DLLOGD(@"bgDlLog:bgTask:moveTempToTaskDir:full tmp file:%@,move to %@",tempFileFullPath, to);
    if (self.isTaskValid && tempFileFullPath && to) {
        NSError *error = nil;
        [[TTDownloadManager class] moveItemAtPath:tempFileFullPath toPath:to overwrite:NO error:&error];
        [self.downloadTask.dllog addDownloadLog:@"background:moveTempToTaskDir" error:error];
        if ([resumeDictionary[@"NSURLSessionResumeBytesReceived"] isKindOfClass:NSNumber.class]) {
            int64_t fileBytes = [resumeDictionary[@"NSURLSessionResumeBytesReceived"] longValue];
            [self.downloadTask addBackgroundDownloadedBytes:fileBytes];
        }
    } else {
        [[TTDownloadManager shareInstance] deleteFile:tempFileFullPath];
        return NO;
    }
    
    return YES;
}

#pragma mark NSURLSessionDownloadDelegate

/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:[location path] error:nil];
    DLLOGD(@"bgDlLog:bgTask:Background +++didFinishDownloadingToURL+++fileSize=%lld,path=%@,download range=%lld-%lld", fileAttributeDic.fileSize,
         [location path], self.downloadSliceTaskConfig.startByte, self.downloadSliceTaskConfig.endByte);
    
    if (!self.isTaskValid) {
        [self.backgroundSession resetWithCompletionHandler:^{
            DLLOGD(@"bgDlLog:bgTask:resetWithCompletionHandler3");
        }];
        [self.backgroundSession finishTasksAndInvalidate];
        return;
    }
    
    if (fileAttributeDic.fileSize > 0) {
        NSString *to = [self.sliceStorageDir stringByAppendingPathComponent:self.currSubSliceInfo.subSliceName];
        DLLOGD(@"bgDlLog:bgTask:++++to=%@", to);

        if (self.isTaskValid && to && [location path]) {
            NSError *error = nil;
            [[TTDownloadManager class] moveItemAtPath:[location path] toPath:to overwrite:NO error:&error];
            if (error) {
                DLLOGE(@"error=%@", error);
            }
        } else {
            [self.backgroundSession finishTasksAndInvalidate];
            [[TTDownloadManager shareInstance] deleteFile:[location path]];
            return;
        }

        self.currSubSliceInfo.sliceStatus = DOWNLOADED;
        if (!self.currSubSliceInfo.isImmutable) {
            self.currSubSliceInfo.rangeEnd = self.currRangeEnd;
        }

        DLLOGD(@"bgDlLog:bgTask:timing:+_++++didFinishDownloadingToURL+++++sliceNumber=%d,sub=%lu,subName=%@",
               self.currSubSliceInfo.sliceNumber, (unsigned long)self.currSubSliceInfo.subSliceNumber, self.currSubSliceInfo.subSliceName);

        [self.downloadTask addBackgroundDownloadedBytes:fileAttributeDic.fileSize];
        self.downloadSliceTaskConfig.hasDownloadedLength += fileAttributeDic.fileSize;
        DLLOGD(@"dlLog:debug hasDownloadedLength 4 = %lld", self.downloadSliceTaskConfig.hasDownloadedLength);

        if (self.downloadTask.isSkipGetContentLength) {
            DLLOGD(@"98:update last sub slice status to DOWNLOADED in db");
            NSError *error = nil;
            if (![[TTDownloadManager shareInstance] insertOrUpdateSubSliceInfo:self.currSubSliceInfo error:&error]) {
                [self.downloadTask.dllog addDownloadLog:@"background:didFinishDownloadingToURL" error:error];
            }
        }
        self.downloadSliceTaskConfig.sliceStatus = DOWNLOADED;

        if (self.downloadTask.isAppAtBackground) {
            [self.downloadTask backgroundDownloadedCounterIncrease];
        }
        
        [self.downloadTask checkBackgroundDownloadFinished];

        [self.backgroundSession resetWithCompletionHandler:^{
            DLLOGD(@"bgDlLog:bgTask:resetWithCompletionHandler4");
        }];
        
        [self clearReferenceCount];
    }
    [self.backgroundSession finishTasksAndInvalidate];
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    //DLLOGD(@"bgDlLog:+++++++++++++++bytesWritten=%lld,totalBytesWritten=%lld,totalBytesExpectedToWrite=%lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {}

#pragma mark "NSURLSessionTaskDelegate"

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {

    if (error) {
        if (!self.isTaskValid) {
            [self.backgroundSession resetWithCompletionHandler:^{
                DLLOGD(@"bgDlLog:bgTask:resetWithCompletionHandler");
            }];
            [self.backgroundSession invalidateAndCancel];
            return;
        }

        [self.downloadTask backgroundFailedCounterIncrease];
        
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            NSString *subSliceName = [self.sliceStorageDir stringByAppendingPathComponent:self.currSubSliceInfo.subSliceName];

            [self moveTempToTaskDir:resumeData to:subSliceName];
        }
    }

    [self.backgroundSession invalidateAndCancel];
    [self.backgroundSession resetWithCompletionHandler:^{
        DLLOGD(@"bgDlLog:bgTask:resetWithCompletionHandler2");
    }];
    
    [self.downloadTask checkBackgroundDownloadFinished];
    [self clearReferenceCount];
}

@end

NS_ASSUME_NONNULL_END
