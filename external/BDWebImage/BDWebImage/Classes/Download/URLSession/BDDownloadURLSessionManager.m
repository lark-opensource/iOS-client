//
//  BDDownloadURLSessionManager.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/4.
//

#import "BDDownloadURLSessionManager.h"
#import "BDDownloadManager+Private.h"
#import "BDDownloadURLSessionTask+Private.h"
#import "BDDownloadURLSessionTask.h"
#import "BDWebImageManager.h"

@interface BDDownloadURLSessionManager()<
NSURLSessionDownloadDelegate,
NSURLSessionDataDelegate,
BDDownloadTaskDelegate> {
    dispatch_queue_t _session_queue;
}
@property (nonatomic, retain)NSOperationQueue *delegateQueue;
@property (nonatomic, readwrite, strong)NSURLSession *session;
@end
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
@implementation BDDownloadURLSessionManager
#pragma clang diagnostic pop

- (instancetype)init
{
    self = [super init];
    if (self) {
        _session_queue = dispatch_queue_create("com.bd.imageLoadTaskQueue", DISPATCH_QUEUE_SERIAL);
        _delegateQueue = [[NSOperationQueue alloc] init];
        if ([_delegateQueue respondsToSelector:@selector(setUnderlyingQueue:)]) {
            [_delegateQueue setUnderlyingQueue:_session_queue];
        }
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 10;
        config.timeoutIntervalForRequest = self.timeoutInterval > 0.0 ? self.timeoutInterval : 30;
        config.timeoutIntervalForResource = self.timeoutIntervalForResource > 0.0 ? self.timeoutIntervalForResource : 30;
        config.HTTPAdditionalHeaders = @{@"Accept": [BDWebImageManager sharedManager].adaptiveDecodePolicy};
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_delegateQueue];
    }
    return self;
}

- (Class)downloadTaskClass
{
    return [BDDownloadURLSessionTask class];
}

#pragma mark - public Method

- (BDDownloadURLSessionTask *)taskWithTaskIdentifier:(NSInteger)taskIdentifier
{
    for (BDDownloadURLSessionTask *task in self.operationQueue.operations) {
        if (task.isExecuting && task.task.taskIdentifier == taskIdentifier) {
            return task;
        }
    }
    return nil;
}

#pragma mark - private Method

- (BDDownloadTask *)_creatTaskWithURL:(NSURL *)url identifier:(NSString *)identifier timeout:(CFTimeInterval)timeout
{
    BDDownloadURLSessionTask *task = (BDDownloadURLSessionTask *)[super _creatTaskWithURL:url identifier:identifier timeout:timeout];
    task.sessionManager = self;
    return task;
}


/* 这里使用的是Iterator 和 strategy,具体细节交给每个task取cover*/
#pragma mark NSURLSessionDataDelegate && NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    BDDownloadURLSessionTask *task = [self taskWithTaskIdentifier:dataTask.taskIdentifier];
    [task URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    BDDownloadURLSessionTask *task = [self taskWithTaskIdentifier:downloadTask.taskIdentifier];
    [task URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    BDDownloadURLSessionTask *task = [self taskWithTaskIdentifier:downloadTask.taskIdentifier];
    [task URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    BDDownloadURLSessionTask *task = [self taskWithTaskIdentifier:downloadTask.taskIdentifier];
    [task URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    BDDownloadURLSessionTask *loadTask = [self taskWithTaskIdentifier:task.taskIdentifier];
    if (loadTask) {
        [loadTask URLSession:session task:task didCompleteWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    BDDownloadURLSessionTask *loadTask = [self taskWithTaskIdentifier:dataTask.taskIdentifier];
    if (loadTask) {
        [loadTask URLSession:session dataTask:dataTask didReceiveData:data];
    }
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    BDDownloadURLSessionTask *loadTask = [self taskWithTaskIdentifier:task.taskIdentifier];
    if (loadTask) {
        [loadTask URLSession:session task:task didFinishCollectingMetrics:metrics];
    }
}
#pragma clang diagnostic pop


#pragma mark - BDDownloadTaskDelegate For Each Task
//下面都是模版方法，可以根据定制实现

- (void)downloadTask:(BDDownloadTask *)dataTask didReceiveData:(NSData *)data finished:(BOOL)finished {
    [self downloadTask:dataTask receivedSize:data.length expectedSize:dataTask.expectedSize];
    if ([(id)self.delegate respondsToSelector:@selector(downloader:task:didReceiveData:finished:)]) {
        [self.delegate downloader:self task:dataTask didReceiveData:data finished:finished];
    }
}

@end
