
#import "TTDownloadApi.h"
#import "TTDownloadDispatcher.h"
#import "TTDownloadManager.h"

#define INTERFACE_WAIT_TIME_MAX 5 * NSEC_PER_SEC

@implementation TTDownloadApi {
    TTDownloadManager *downloadManager;
    TTDownloadDispatcher *dispatcher;
}

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {
        downloadManager = [TTDownloadManager shareInstance];
        dispatcher = [[TTDownloadDispatcher alloc] init];
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

- (void)setGlobalDownloadParameters:(DownloadGlobalParameters *)globalParameters {
    [downloadManager setGlobalDownloadParameters:globalParameters];
}

- (void)setDownloadEventBlock:(TTDownloadEventBlock)eventBlock {
    [downloadManager setEventBlock:eventBlock];
}

- (void)dispatchTask:(NSString *)urlKey
      userParameters:(DownloadGlobalParameters *)userParameters
         resultBlock:(TTDownloadResultBlock)resultBlock
            progress:(TTDownloadProgressBlock)progress
                work:(DoWork)work {
    if (!urlKey || !work) {
        return;
    }
    
    if ([self preResourcesCheck:urlKey
                       progress:progress
                    resultBlock:resultBlock
                 userParameters:userParameters]) {
        return;
    }
    
    TTDispatcherTask *task = [[TTDispatcherTask alloc] init];
    task.urlKey = urlKey;
    task.userParameters = [userParameters copy];
    task.onRealTask = work;
    task.resultBlock = resultBlock;
    [dispatcher enqueue:task];
}

- (void)reportDownloadProgress:(TTDownloadTaskConfig *)taskConfig
                      progress:(TTDownloadProgressBlock)progressBlock
                   resultBlock:(TTDownloadResultBlock)resultBlock {

    DownloadResultNotification *resultNotification = [[DownloadResultNotification alloc] init];

    resultNotification.downloadedFilePath = [TTDownloadManager getFullFilePath:taskConfig];
    resultNotification.code = ERROR_FILE_DOWNLOADED;
    resultNotification.urlKey = taskConfig.urlKey;
    resultNotification.secondUrl = taskConfig.secondUrl;
    
    DownloadProgressInfo *progressInfo = [[DownloadProgressInfo alloc] init];
    progressInfo.progress = 1.0;
    progressInfo.urlKey = taskConfig.urlKey;
    progressInfo.secondUrl = taskConfig.secondUrl;
    progressInfo.totalSize = [taskConfig getTotalLength];
    progressInfo.downloadedSize = progressInfo.totalSize;
    
    if (progressBlock) {
        progressBlock(progressInfo);
    }
    if (resultBlock) {
        resultBlock(resultNotification);
    }
}

- (BOOL)preResourcesCheck:(NSString *)urlKey
                 progress:(TTDownloadProgressBlock)progress
              resultBlock:(TTDownloadResultBlock)resultBlock
           userParameters:(DownloadGlobalParameters *)userParameters {
    if (!progress || !resultBlock || !urlKey) {
        return NO;
    }
    TTDownloadTaskConfig *taskConfig = nil;
    if (userParameters.isCheckCacheValid
        && !userParameters.isIgnoreMaxAgeCheck
        && !userParameters.isUrgentModeEnable
        && !userParameters.isTTNetUrgentModeEnable
        && ![dispatcher isResourceDownloading:urlKey]
        && (taskConfig = [[TTDownloadManager shareInstance] findTaskConfigInDicLock:urlKey])
        && DOWNLOADED == taskConfig.downloadStatus
        && ([TTDownloadManager compareDate:[TTDownloadManager getFormatTime:0] withDate:taskConfig.extendConfig.maxAgeTime] >= 0)
        && [[NSFileManager defaultManager] fileExistsAtPath:[TTDownloadManager getFullFilePath:taskConfig]]) {
        [self reportDownloadProgress:taskConfig
                            progress:progress
                         resultBlock:resultBlock];
        return YES;
    }
    return NO;
}

- (int)startDownloadWithURL:(NSString *)urlKey
               fileName:(NSString *)fileName
               md5Value:(NSString *)md5Value
               urlLists:(NSArray<NSString *> *)urlLists
               progress:(TTDownloadProgressBlock)progress
                 status:(TTDownloadResultBlock)status
             userParameters:(DownloadGlobalParameters *)userParameters {
    
    [self dispatchTask:urlKey
        userParameters:userParameters
           resultBlock:(TTDownloadResultBlock)status
              progress:(TTDownloadProgressBlock)progress
                  work:^(DownloadGlobalParameters *params) {
        [self->downloadManager startDownloadWithURL:urlKey
                                           isUseKey:NO
                                           fileName:fileName
                                           md5Value:md5Value
                                           urlLists:urlLists
                                           progress:progress
                                             status:status
                                     userParameters:params];
    }];
    return ERROR_START_DOWNLOAD;
}


- (int)startDownloadWithKey:(NSString *)key
                   fileName:(NSString *)fileName
                   md5Value:(NSString *)md5Value
                   urlLists:(NSArray<NSString *> *)urlLists
                   progress:(TTDownloadProgressBlock)progress
                     status:(TTDownloadResultBlock)status
             userParameters:(DownloadGlobalParameters *)userParameters {

    [self dispatchTask:key
        userParameters:userParameters
           resultBlock:status
              progress:(TTDownloadProgressBlock)progress
                  work:^(DownloadGlobalParameters *params) {
        [self->downloadManager startDownloadWithURL:key
                                           isUseKey:YES
                                           fileName:fileName
                                           md5Value:md5Value
                                           urlLists:urlLists
                                           progress:progress
                                             status:status
                                     userParameters:params];
    }];
    return ERROR_START_DOWNLOAD;
}

- (int)resumeDownloadWithURL:(NSString *)urlKey
                    progress:(TTDownloadProgressBlock)progress
                      status:(TTDownloadResultBlock)status
              userParameters:(DownloadGlobalParameters *)userParameters {

    [self dispatchTask:urlKey
        userParameters:userParameters
           resultBlock:status
              progress:(TTDownloadProgressBlock)progress
                  work:^(DownloadGlobalParameters *params) {
        [self->downloadManager resumeDownloadWithURL:urlKey
                                            isUseKey:NO
                                            urlLists:nil
                                            progress:progress
                                              status:status
                                      userParameters:params];
    }];
    return ERROR_START_DOWNLOAD;
}

- (int)resumeDownloadWithKey:(NSString *)key
                    urlLists:(NSArray<NSString *> *)urlLists
                    progress:(TTDownloadProgressBlock)progress
                      status:(TTDownloadResultBlock)status
              userParameters:(DownloadGlobalParameters *)userParameters {

    [self dispatchTask:key
        userParameters:userParameters
           resultBlock:status
              progress:(TTDownloadProgressBlock)progress
                  work:^(DownloadGlobalParameters *params) {
        [self->downloadManager resumeDownloadWithURL:key
                                            isUseKey:YES
                                            urlLists:urlLists
                                            progress:progress
                                              status:status
                                      userParameters:params];
    }];
    return ERROR_START_DOWNLOAD;
}

- (void)cancelDownloadWithURL:(NSString *)urlKey {
    [self cancelTaskAsync:urlKey block:nil];
}

- (void)cancelTaskAsync:(NSString *)urlKey block:(TTDownloadResultBlock)block {
    TTDispatcherTask *task = [[TTDispatcherTask alloc] init];
    task.urlKey = urlKey;
    task.onRealTask = ^(DownloadGlobalParameters *params) {
        [self->downloadManager cancelDownloadWithURL:urlKey block:block];
    };
    [dispatcher cancelTask:task];
}

- (void)cancelTaskSync:(NSString *)urlKey {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    TTDownloadResultBlock cancelBlock = ^(DownloadResultNotification *resultNotification) {
        DLLOGD(@"debug:cancelTaskSync:send sem");
        dispatch_semaphore_signal(sem);
    };
    [self cancelTaskAsync:urlKey block:cancelBlock];
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, INTERFACE_WAIT_TIME_MAX);
    DLLOGD(@"debug:cancelTaskSync:start wait");
    dispatch_semaphore_wait(sem, timeout);
    DLLOGD(@"debug:cancelTaskSync:end wait");
}

- (BOOL)deleteTaskSync:(NSString *)urlKey {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block BOOL ret = NO;
    TTDownloadResultBlock deleteBlock = ^(DownloadResultNotification *resultNotification) {
        ret = (resultNotification.code == ERROR_DELETE_SUCCESS) ? YES : NO;
        dispatch_semaphore_signal(sem);
    };
    
    [self deleteDownloadWithURL:urlKey resultBlock:deleteBlock];
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, INTERFACE_WAIT_TIME_MAX);
    dispatch_semaphore_wait(sem, timeout);
    return ret;
}

- (void)deleteDownloadWithURL:(NSString *)urlKey
                  resultBlock:(TTDownloadResultBlock)resultBlock {
    TTDispatcherTask *task = [[TTDispatcherTask alloc] init];
    task.urlKey = urlKey;
    task.onRealTask = ^(DownloadGlobalParameters *params) {
        [self->downloadManager deleteDownloadWithURL:urlKey resultBlock:resultBlock];
    };
    [dispatcher deleteTask:task];
}

- (DownloadInfo *)queryTaskInfoSync:(NSString *)urlKey {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block DownloadInfo *info = nil;
    TTDownloadInfoBlock queryBlock = ^(DownloadInfo *downloadInfo) {
        info = downloadInfo;
        dispatch_semaphore_signal(sem);
    };
    [self queryDownloadInfoWithURL:urlKey downloadInfoBlock:queryBlock];
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, INTERFACE_WAIT_TIME_MAX);
    dispatch_semaphore_wait(sem, timeout);
    return info;
}

- (void)queryDownloadInfoWithURL:(NSString *)urlKey
               downloadInfoBlock:(TTDownloadInfoBlock)downloadInfoBlock {
    TTDispatcherTask *task = [[TTDispatcherTask alloc] init];
    task.urlKey = urlKey;
    task.onRealQueryTask = ^(DownloadStatus status) {
        [self->downloadManager queryDownloadInfoWithURL:urlKey downloadInfoBlock:downloadInfoBlock status:status];
    };
    [dispatcher queryTask:task];
}

- (BOOL)setDownlodingTaskCountMax:(int16_t)taskCount {
    return [dispatcher setDownlodingTaskCountMax:taskCount];
}

- (int16_t)getDownlodingTaskCountMax {
    return [dispatcher getDownlodingTaskCountMax];
}

- (bool)setThrottleNetSpeedWithURL:(NSString *)urlKey bytesPerSecond:(int64_t)bytesPerSecond {
    return [downloadManager setThrottleNetSpeedWithURL:urlKey bytesPerSecond:bytesPerSecond];
}

- (const NSInteger)getAllTaskCount {
    return [dispatcher getAllTaskCount];
}

- (const NSInteger)getQueueWaitTaskCount {
    return [dispatcher getQueueWaitTaskCount];
}

- (BOOL)clearAllCache:(const ClearCacheType)type clearCacheKey:(const NSArray<NSString *> * _Nullable)list {
    if ([NSThread isMainThread]) {
        return NO;
    }
    NSError *error = nil;
    BOOL ret = [downloadManager clearAllCache:type clearCacheKey:list error:&error];
    DLLOGD(@"error=%@", error);
    return ret;
}

- (void)stopClearNoExpireCache {
    [downloadManager stopClearNoExpireCache];
}

- (int64_t)getAllCacheCount {
    if ([NSThread isMainThread]) {
        return -1;
    }
    return [downloadManager getAllCacheCount];
}

- (int64_t)getAllNoExpireTimeCacheCount {
    if ([NSThread isMainThread]) {
        return -1;
    }
    return [downloadManager getAllNoExpireTimeCacheCount];
}

- (void)setWifiOnlyWithUrlKey:(const NSString * )urlKey isWifiOnly:(const BOOL)isWifiOnly {
    if (![dispatcher setWifiOnlyWithUrlKey:urlKey isWifiOnly:isWifiOnly]) {
        [downloadManager setWifiOnlyWithUrlKey:urlKey isWifiOnly:isWifiOnly];
    }
}

- (void)setIsForceCacheLifeTimeMaxEnable:(BOOL)enable {
    downloadManager.isForceCacheLifeTimeMaxEnable = enable;
}

@end
