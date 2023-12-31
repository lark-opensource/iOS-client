//
//  BDDownloadManager.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDDownloadManager.h"
#import "BDDownloadTask+Private.h"
#import "BDDownloadManager+Private.h"
#import "BDDownloadTask+WebImage.h"
#import "BDDownloadTask.h"
#import "BDDownloadTaskConfig.h"
#import <pthread.h>
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif


@interface BDDownloadManager ()<BDDownloadTaskDelegate> {
    pthread_mutex_t _mutex;
}

@property (nonatomic, strong, nonnull) NSMapTable *weakTasks; // strong-weak url-task

@end

@implementation BDDownloadManager

@synthesize timeoutInterval;
@synthesize timeoutIntervalForResource;
@synthesize defaultHeaders;
@synthesize enableLog;
@synthesize checkMimeType;
@synthesize checkDataLength;
@synthesize isCocurrentCallback;    // 生成名为 isCocurrentCallback 的成员变量
@synthesize maxConcurrentTaskCount = _maxConcurrentTaskCount;   // 生成名为_maxConcurrentTaskCount的成员变量

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_mutex, 0);
        _weakTasks = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        _operationQueue = [[NSOperationQueue alloc] init];
        _maxConcurrentTaskCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return self;
}


#pragma mark - public Method

- (BDDownloadTask *)downloadWithURL:(NSURL *)url
                         identifier:(NSString *)identifier
                   startImmediately:(BOOL)immediately
{
    return (BDDownloadTask *)[self downloadWithURL:url
                                        identifier:identifier
                                          priority:NSOperationQueuePriorityNormal
                                   timeoutInterval:0
                                  startImmediately:immediately
                                  progressDownload:NO
                  heicProgressDownloadForThumbnail:NO
                                        verifyData:YES];
}

- (BDDownloadTask *)downloadWithURL:(NSURL *)url
                         identifier:(NSString *)identifier
                    timeoutInterval:(CFTimeInterval)timeoutInterval
                   startImmediately:(BOOL)immediately
{
    return (BDDownloadTask *)[self downloadWithURL:url
                                        identifier:identifier
                                          priority:NSOperationQueuePriorityNormal
                                   timeoutInterval:0
                                  startImmediately:immediately
                                  progressDownload:NO
                  heicProgressDownloadForThumbnail:NO
                                        verifyData:YES];
}

- (BDDownloadTask *)downloadWithURL:(NSURL *)url
                         identifier:(NSString *)identifier
                           priority:(NSOperationQueuePriority)priority
                    timeoutInterval:(CFTimeInterval)timeoutInterval
                   startImmediately:(BOOL)immediately
                   progressDownload:(BOOL)progressDownload
                        verifyData:(BOOL)verifyData
{
    return (BDDownloadTask *)[self downloadWithURL:url
                                        identifier:identifier
                                          priority:priority
                                   timeoutInterval:timeoutInterval
                                  startImmediately:immediately
                                  progressDownload:progressDownload
                  heicProgressDownloadForThumbnail:NO
                                        verifyData:verifyData];
}

- (BDDownloadTask *)downloadWithURL:(NSURL *)url
                         identifier:(NSString *)identifier
                           priority:(NSOperationQueuePriority)priority
                    timeoutInterval:(CFTimeInterval)timeoutInterval
                   startImmediately:(BOOL)immediately
                   progressDownload:(BOOL)progressDownload
   heicProgressDownloadForThumbnail:(BOOL)progressDownloadForThumbnail
                         verifyData:(BOOL)verifyData
{
    BDDownloadTaskConfig *config = [BDDownloadTaskConfig new];
    config.priority = priority;
    config.timeoutInterval = timeoutInterval;
    config.immediately = immediately;
    config.progressDownload = progressDownload;
    config.progressDownloadForThumbnail = progressDownloadForThumbnail;
    config.verifyData = verifyData;
    config.requestHeaders = [NSDictionary dictionary];
    
    return (BDDownloadTask *)[self downloadWithURL:url identifier:identifier config:config];
}

- (BDDownloadTask *)downloadWithURL:(NSURL *)url
                         identifier:(NSString *)identifier
                             config:(BDDownloadTaskConfig *)config
{
    BDDownloadTask *task = nil;
    pthread_mutex_lock(&_mutex);
    task = [_weakTasks objectForKey:identifier];
    if (!task || task.isFinished || task.isCancelled) {
        task = [self _creatTaskWithURL:url identifier:identifier timeout:config.timeoutInterval];
        task.requestHeaders = config.requestHeaders;
        task.isProgressiveDownload = config.progressDownload;
        task.needHeicProgressDownloadForThumbnail = config.progressDownloadForThumbnail;
        if (!config.verifyData) {
            task.checkDataLength = NO;
            task.checkMimeType = NO;
        }
        if (!task.tempPath) {
            task.tempPath = [self.tempPath stringByAppendingPathComponent:task.identifier];
        }
        task.queuePriority = config.priority;
        [_weakTasks setObject:task forKey:identifier];
        [_operationQueue addOperation:task];
    } else {
        if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|reuse|taskIdentifier: %@", task.identifier);
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] download|reuse|taskIdentifier: %@", task.identifier);
#endif
        }
        if (!task.isExecuting) {
            task.isProgressiveDownload = config.progressDownload;
            if (task.queuePriority < config.priority) {
                task.queuePriority = config.priority;
            }
        }
    }
    
    pthread_mutex_unlock(&_mutex);
    return task;
}

- (BDDownloadTask *)taskWithIdentifier:(NSString *)identifier
{
    BDDownloadTask *task = nil;
    pthread_mutex_lock(&_mutex);
    task = [_weakTasks objectForKey:identifier];
    pthread_mutex_unlock(&_mutex);
    return task;
}

- (void)cancelTaskWithIdentifier:(NSString *)identifier
{
    pthread_mutex_lock(&_mutex);
    BDDownloadTask *task = [_weakTasks objectForKey:identifier];
    if (task) {
        [_weakTasks removeObjectForKey:identifier];
        [task cancel];
    }
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - private Method

- (BDDownloadTask *)_creatTaskWithURL:(NSURL *)url
                           identifier:(NSString *)identifier
                              timeout:(CFTimeInterval)timeout
{
    BDDownloadTask *task = [[[self downloadTaskClass] alloc] initWithURL:url];
    task.identifier = identifier;
    task.delegate = self;
    task.timeoutInterval = timeout > 0.0 ? timeout : self.timeoutInterval;
    task.defaultHeaders = self.defaultHeaders;
    task.timeoutIntervalForResource = self.timeoutIntervalForResource;
    task.downloadResumeEnabled = self.downloadResumeEnabled;
    task.enableLog = self.enableLog;
    task.checkMimeType = self.checkMimeType;
    task.checkDataLength = self.checkDataLength;
    task.isCocurrentCallback = self.isCocurrentCallback;
    return task;
}

- (BOOL)isTaskInRunningTasks:(BDDownloadTask *)task
{
    if (task) {
        BDDownloadTask *runningTask = (BDDownloadTask *)[self taskWithIdentifier:task.identifier];
        return runningTask == task;
    }
    return NO;
}

#pragma mark - BDDownloadTaskDelegate For Each Task

- (void)downloadTask:(BDDownloadTask *)task failedWithError:(NSError *)error
{
    if ([self isTaskInRunningTasks:task]) {
         [self.delegate downloader:self task:task failedWithError:error];
     }
}

- (void)downloadTask:(BDDownloadTask *)task
    finishedWithData:(NSData *)data
            savePath:(NSString *)savePath
{
    // 某些情况downloadTask：receivedSize：expectedSize：未调用，这里重新设置
    task.expectedSize = data.length;
    task.receivedSize = data.length;
    if ([self isTaskInRunningTasks:task]) {
        [self.delegate downloader:self
                             task:task
                 finishedWithData:data
                         savePath:savePath];
    }
}

- (void)downloadTask:(BDDownloadTask *)task
        receivedSize:(NSInteger)receivedSize
        expectedSize:(NSInteger)expectedSize;
{
    if ([self isTaskInRunningTasks:task]) {
       [self.delegate downloader:self
                            task:task
                    receivedSize:receivedSize
                    expectedSize:expectedSize];
   }
}

- (void)downloadTask:(BDDownloadTask *)dataTask
      didReceiveData:(NSData *)data
            finished:(BOOL)finished
{
    if ([(id)self.delegate respondsToSelector:@selector(downloader:task:didReceiveData:finished:)]
        && [self isTaskInRunningTasks:dataTask]) {
        [self.delegate downloader:self
                             task:dataTask
                   didReceiveData:data
                         finished:finished];
    }
}

- (void)downloadTaskDidCanceled:(BDDownloadTask *)task
{
}

//heic 缩略图解码repack功能相关
- (BOOL)isRepackNeeded:(NSData *)data
{
    if ([(id)self.delegate respondsToSelector:@selector(isRepackNeeded:)]) {
        return [self.delegate isRepackNeeded:data];
    }
    return NO;
}

- (NSMutableData *)heicRepackData:(NSData *)data
{
    if ([(id)self.delegate respondsToSelector:@selector(heicRepackData:)]) {
        return [self.delegate heicRepackData:data];
    }
    return nil;
}

#pragma mark - Accessor

- (NSString *)tempPath
{
    if (!_tempPath) {
        _tempPath = NSTemporaryDirectory();
    }
    return _tempPath;
}

- (Class)downloadTaskClass
{
    if (!_downloadTaskClass) {
        _downloadTaskClass = NSClassFromString(@"BDDownloadChromiumTask");
    }
    NSAssert(_downloadTaskClass, @"download task not implemented");
    return _downloadTaskClass;
}

- (void)setMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount {
    [self.operationQueue setMaxConcurrentOperationCount:maxConcurrentTaskCount];
    _maxConcurrentTaskCount = maxConcurrentTaskCount;
}

- (NSArray<BDDownloadTask *>*)allTasks {
    return _operationQueue.operations;
}

@end
