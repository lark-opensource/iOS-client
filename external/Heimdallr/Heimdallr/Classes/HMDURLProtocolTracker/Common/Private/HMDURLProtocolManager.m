//
//  HMDURLProtocolManager.m
//  Heimdallr
//
//  Created by fengyadong on 2018/12/11.
//

#import "HMDURLProtocolManager.h"
#import "HMDThreadSafeDictionary.h"
#import "NSURLSessionTask+HMDURLProtocol.h"

static HMDURLProtocolManager *shared;

@interface HMDURLProtocolManager()<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>

@property (nonatomic, strong, readwrite) dispatch_queue_t session_queue;
@property (nonatomic, strong) HMDThreadSafeDictionary *taskDict;
@property (nonatomic, strong, readwrite) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@end

@implementation HMDURLProtocolManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _taskDict = [[HMDThreadSafeDictionary alloc] init];
        
        _session_queue = dispatch_queue_create("com.heimdallr.session.queue", DISPATCH_QUEUE_SERIAL);
        _delegateQueue = [[NSOperationQueue alloc] init];
        if ([_delegateQueue respondsToSelector:@selector(setUnderlyingQueue:)]) {
            [_delegateQueue setUnderlyingQueue:_session_queue];
        }
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 10;
        config.timeoutIntervalForRequest = 60;
        config.timeoutIntervalForResource = 60;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_delegateQueue];
    }
    return self;
}

- (NSURLSessionDataTask *)generateDataTaskWithURLRequest:(NSURLRequest *)request
                   underlyingDelegate:(id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>)deleagte {
    if (!deleagte || !request) {
        return nil;
    }
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    [self.taskDict setObject:deleagte forKey:[NSString stringWithFormat:@"%lu",(unsigned long)dataTask.taskIdentifier]];
    
    [dataTask resume];
    
    return dataTask;
}

- (id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate>)underlyingDelgateForTaskIdentifier:(NSUInteger)identifier {
    return [self.taskDict objectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)identifier]];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate> delegate = [self underlyingDelgateForTaskIdentifier:task.taskIdentifier];
    if ([delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [task hmdPerformBlock:^{
            [delegate URLSession:session task:task didCompleteWithError:error];
        }];
    }
    
    [self.taskDict removeObjectForKey:[NSString stringWithFormat:@"%lu",task.taskIdentifier]];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate> delegate = [self underlyingDelgateForTaskIdentifier:dataTask.taskIdentifier];
    if ([delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [dataTask hmdPerformBlock:^{
            [delegate URLSession:session dataTask:dataTask didReceiveData:data];
        }];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate> delegate = [self underlyingDelgateForTaskIdentifier:dataTask.taskIdentifier];
    if ([delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [dataTask hmdPerformBlock:^{
            [delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }];
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate> delegate = [self underlyingDelgateForTaskIdentifier:task.taskIdentifier];
    if ([delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [task hmdPerformBlock:^{
            [delegate URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
        }];
    } else {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)){
    id<NSURLSessionTaskDelegate,NSURLSessionDataDelegate> delegate = [self underlyingDelgateForTaskIdentifier:task.taskIdentifier];
    if ([delegate respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]) {
        [task hmdPerformBlock:^{
            [delegate URLSession:session task:task didFinishCollectingMetrics:metrics];
        }];
    }
}

@end
