//
//  BDPNetworkOperation.m
//  Timor
//
//  Created by liubo on 2018/11/19.
//

#import "BDPNetworkOperation.h"
#import "BDPUtils.h"

#define kBDPNetworkThreadName   @"BDPNetworkThread"
#define kBDPNetworkLockName     @"com.bytedance.networkOperation.lock"

typedef void(^BDPAppLoadingOperationCompletionBlock)(NSData *responseData, NSError *error);
typedef void(^BDPAppLoadingOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
typedef void(^BDPAppLoadingOperationBackgroundTaskCleanupBlock)(void);

@interface BDPNetworkOperation ()<NSURLConnectionDelegate>

@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSSet *runLoopModes;

@property (nonatomic, strong, readwrite) NSURLRequest *request;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSData *responseData;

@property (nonatomic, copy) BDPAppLoadingOperationProgressBlock downloadProgress;
@property (nonatomic, copy) BDPAppLoadingOperationCompletionBlock completionHandler;
@property (nonatomic, copy) BDPAppLoadingOperationBackgroundTaskCleanupBlock backgroundTaskCleanup;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) long long expectedSize;
@property (nonatomic, assign) long long totalBytesRead;

@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;

@end

#pragma mark - BDPNetworkOperation

@implementation BDPNetworkOperation
@synthesize outputStream = _outputStream;
@synthesize finished = _finished;
@synthesize executing = _executing;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:kBDPNetworkThreadName];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *staticNetworkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        staticNetworkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [staticNetworkRequestThread start];
    });
    
    return staticNetworkRequestThread;
}

#pragma mark - Init

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        self.request = request;
        [self buildNetworkOperation];
    }
    return self;
}

- (void)buildNetworkOperation {
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kBDPNetworkLockName;
}

- (void)dealloc {
    [self deallocOperation];
}

- (void)deallocOperation {
    if (_outputStream) {
        [_outputStream close];
        _outputStream = nil;
    }
    
    if (_backgroundTaskCleanup) {
        _backgroundTaskCleanup();
    }
}

#pragma mark - Utility

- (void)cancelConnection {
    NSDictionary *userInfo = nil;
    NSURL *url = [self.request URL];
    
    if(url != nil) {
        userInfo = @{NSURLErrorFailingURLErrorKey : url,
                     NSLocalizedDescriptionKey : @"The request is cancelled."};
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (!self.isFinished) {
        if (self.connection) {
            [self.connection cancel];
            [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:error];
        } else {
            self.error = error;
            [self invokeCompletionBlock];
        }
    }
}

- (void)startConnection {
    [self.lock lock];
    if (![self isCancelled]) {
        
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.outputStream open];
        [self.connection start];
        
        if (self.backgroundTaskCleanup == nil) {
            UIApplication *application = [UIApplication sharedApplication];
            UIBackgroundTaskIdentifier __block backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            
            WeakSelf;
            self.backgroundTaskCleanup = ^(){
                if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                    backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                }
            };
            
            backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
                StrongSelfIfNilReturn;
                if (self) {
                    [self cancel];
                    self.backgroundTaskCleanup();
                }
            }];
        }
    }
    [self.lock unlock];
}

- (void)invokeCompletionBlock {
    [self.outputStream close];
    if (self.responseData) {
        self.outputStream = nil;
    }
    
    if (self.completionHandler != nil) {
        BDPAppLoadingOperationCompletionBlock block = [self.completionHandler copy];
        NSData * responseData = [self.responseData copy];
        NSError * error = [self.error copy];
        
        dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
        dispatch_async(queue, ^{
            block(responseData, error);
        });
    }
    
    [self done];
}

- (void)reset {
    self.connection = nil;
    self.completionHandler = nil;
    self.downloadProgress = nil;
}

- (void)done {
    [self.lock lock];
    self.finished  = YES;
    self.executing = NO;
    [self reset];
    [self.lock unlock];
}

#pragma mark - KVO-Compliant

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma mark - Override

- (void)start {
    [self.lock lock];
    if (self.isCancelled) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    } else {
        self.executing = YES;
        [self performSelector:@selector(startConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    
    [self.lock unlock];
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        
        if (self.isExecuting) {
            [self cancelConnection];;
        }
    }
    
    [self.lock unlock];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

#pragma mark - stream

- (NSOutputStream *)outputStream {
    if (_outputStream == nil) {
        self.outputStream = [NSOutputStream outputStreamToMemory];
    }
    
    return _outputStream;
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    [self.lock lock];
    if (outputStream != _outputStream) {
        if (_outputStream) {
            [_outputStream close];
        }
        
        _outputStream = outputStream;
    }
    [self.lock unlock];
}

#pragma mark - block

- (void)setCompletionHandlerBlock:(void (^)(NSData *responseData, NSError *error))block {
    self.completionHandler = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    
    if ((self.response.statusCode / 100) == 2) {
        NSUInteger expected = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.expectedSize = expected;
    } else {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:self.response.statusCode
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"response status code: %ld",(long)self.response.statusCode]}];
        [self.connection cancel];
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.isCancelled) return;
    
    NSUInteger length = [data length];
    while (YES)
    {
        NSInteger totalNumberOfBytesWritten = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];
            
            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < (NSInteger)length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[(NSUInteger)totalNumberOfBytesWritten] maxLength:(length - (NSUInteger)totalNumberOfBytesWritten)];
                if (numberOfBytesWritten == -1) {
                    break;
                }
                totalNumberOfBytesWritten += numberOfBytesWritten;
            }
            break;
        }
        else {
            [self.connection cancel];
            if (self.outputStream.streamError) {
                [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:self.outputStream.streamError];
            }
            return;
        }
    }
    
    self.totalBytesRead += (long long)length;
    
    if (self.downloadProgress != nil) {
        BDPAppLoadingOperationProgressBlock block = [self.downloadProgress copy];
        long long blockTotalBytesRead = self.totalBytesRead;
        long long blockExpectedContentLength = self.response.expectedContentLength;
        
        dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
        dispatch_async(queue, ^{
            block(length, blockTotalBytesRead, blockExpectedContentLength);
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self invokeCompletionBlock];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    [self invokeCompletionBlock];
}

@end
