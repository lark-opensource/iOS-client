//
//  IESFileDownloadTask.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import "IESFileDownloadTask.h"

@interface IESFileDownloadTask ()<NSURLSessionDownloadDelegate> {
    BOOL executing;
    BOOL finished;
}

@property (nonatomic,   copy) NSArray<NSURLRequest *> *requests;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, copy) NSDictionary<NSString *, id> *extraInfoDict;

@end

@implementation IESFileDownloadTask

- (instancetype)initWithURLRequests:(NSArray<NSURLRequest *> *)requests filePath:(NSString *)filePath;
{
    NSParameterAssert(filePath);
    NSParameterAssert(requests.count > 0);
    
    self = [super init];
    if (self) {
        _filePath = filePath;
        _requests = [requests copy];
        _downloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

#pragma mark - Helpers

- (void)downloadRequestAtIndex:(NSUInteger)index
{
    if (index >= self.requests.count) {
        [self willChangeValueForKey:@"isExecuting"];
        executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        [self.downloadSession finishTasksAndInvalidate];
        return;
    }
    
    NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:self.requests[index]];
    [downloadTask resume];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSError *error;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    }
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.filePath] error:&error];
    
    if (error) {
        _error = error;
        [self downloadRequestAtIndex:++self.index];
        return;
    } else {
        if (downloadTask.response && [downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *downloadResponse = (NSHTTPURLResponse *)downloadTask.response;
            self.extraInfoDict = @{ IESEffectNetworkResponse :  downloadResponse,
                                    IESEffectNetworkResponseStatus : @(downloadResponse.statusCode),
                                    IESEffectNetworkResponseHeaderFields : downloadResponse.allHeaderFields.description
                                    };
        }
        _error = nil;
        [self willChangeValueForKey:@"isExecuting"];
        executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        [self.downloadSession finishTasksAndInvalidate];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        _error = error;
        [self downloadRequestAtIndex:++self.index];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    self.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
}

#pragma mark - Override

- (void)setProgress:(CGFloat)progress
{
    progress = MAX(_progress, progress);
    if (progress != _progress) {
        _progress = progress;
        !self.progressBlock ? : self.progressBlock(_progress);
    }
}

- (void)start
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{
    [self downloadRequestAtIndex:0];
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isExecuting
{
    return executing;
}

- (BOOL)isFinished
{
    return finished;
}

@end

