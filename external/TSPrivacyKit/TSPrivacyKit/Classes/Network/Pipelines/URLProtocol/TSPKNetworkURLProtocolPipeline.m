//
//  TSPKURLProtocol.m
//  BDAlogProtocol
//
//  Created by admin on 2022/8/23.
//

#import "TSPKNetworkURLProtocolPipeline.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "NSURLRequest+TSPKCommonRequest.h"
#import "NSURLResponse+TSPKCommonResponse.h"
#import "TSPKLock.h"
#import <TSPrivacyKit/TSPKNetworkConfigs.h>

static NSString *const TSPKEventSourceTypeURLProtocol = @"protocol";

@interface TSPKNetworkURLProtocol : NSURLProtocol<NSURLSessionDelegate>

@property (nonatomic, strong) id<TSPKLock> lock;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLResponse *> *responseDict;
 
+ (void)start;
+ (void)stop;

@end

@implementation TSPKNetworkURLProtocol

+ (void)start {
    [NSURLProtocol registerClass:[self class]];
}

+ (void)stop {
    [NSURLProtocol unregisterClass:[self class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:TSPKNetworkSessionHandleKey inRequest:request]) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    [TSPKNetworkURLProtocolPipeline onRequest:mutableRequest];
    return mutableRequest;
}

- (void)startLoading {
    BOOL shouldDrop = [[NSURLProtocol propertyForKey:TSPKNetworkSessionDropKey inRequest:self.request] boolValue];
    if (shouldDrop) {
        NSDictionary *dic = @{
            @"error_msg": [NSString stringWithFormat:@"%@", [NSURLProtocol propertyForKey:TSPKNetworkSessionDropMessageKey inRequest:self.request]] ?: @"refuse by TSPKNetworkURLProtocol",
        };
        NSInteger code = [[NSURLProtocol propertyForKey:TSPKNetworkSessionDropCodeKey inRequest:self.request] intValue];
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:dic];
        [[self client] URLProtocol:self didFailWithError:error];
    } else {
        self.lock = [TSPKLockFactory getLock];
        self.responseDict = [NSMutableDictionary dictionary];
        
        NSMutableURLRequest *mutableReqeust = [self.request mutableCopy];
        [NSURLProtocol setProperty:@(YES) forKey:TSPKNetworkSessionHandleKey inRequest:mutableReqeust];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
        self.task = [session dataTaskWithRequest:mutableReqeust];
        [self.task resume];
        if ([TSPKNetworkConfigs enableURLProtocolURLSessionInvalidate]) {
            [session finishTasksAndInvalidate];
        }
    }
}

- (void)stopLoading {
    [self.task cancel];
    self.task = nil;
}

- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    [_lock lock];
    self.responseDict[@(dataTask.taskIdentifier)] = response;
    [_lock unlock];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_lock lock];
    NSNumber *identifier = @(dataTask.taskIdentifier);
    NSURLResponse *response = self.responseDict[identifier];
    [self.responseDict removeObjectForKey:identifier];
    [_lock unlock];
    [TSPKNetworkURLProtocolPipeline onResponse:response request:self.request data:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    completionHandler(proposedResponse);
}

@end

@implementation TSPKNetworkURLProtocolPipeline

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [TSPKNetworkURLProtocol start];
    });
}

@end
