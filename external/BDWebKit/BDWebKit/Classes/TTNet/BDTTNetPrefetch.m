//
//  BDTTNetPrefetch.m
//  AsheImpl
//
//  Created by luoqisheng on 2020/3/11.
//

#import "BDTTNetPrefetch.h"
#import "BDWebKitSettingsManger.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <objc/runtime.h>

#define BDTTNetPrefetchLogTag @"BDTTNetPrefetch"
#define BDTTNetPrefetch_InfoLog(format, ...)  BDALOG_PROTOCOL_INFO_TAG(BDTTNetPrefetchLogTag, format, ##__VA_ARGS__)
#define BDTTNetPrefetch_ErrorLog(format, ...)  BDALOG_PROTOCOL_ERROR_TAG(BDTTNetPrefetchLogTag, format, ##__VA_ARGS__)

#pragma mark - const
 
NSString * const BDTTNetPrefetchIdentifier = @"ttnet-prefetch-id";
NSString * const BDTTNetPrefetchResponseTimeStampKey = @"ttnet-prefetch-response-ts";

#pragma mark - NSURLRequset

@implementation NSURLRequest (BDTTNetPrefetch)

- (NSString *)prefetchID {
    NSMutableDictionary *headers = self.allHTTPHeaderFields.mutableCopy?: @{}.mutableCopy;
    NSString *prefetchID = [headers btd_stringValueForKey:BDTTNetPrefetchIdentifier];
    if (prefetchID) {
        return prefetchID;
    }
    
    return [self.URL.absoluteString btd_md5String];
}

@end

@implementation NSHTTPURLResponse (BDTTNetPrefetch)

- (NSUInteger)prefetchResponseTimeStamp {
    return  [self.allHeaderFields btd_unsignedIntegerValueForKey:BDTTNetPrefetchResponseTimeStampKey];
}

- (BOOL)isPrefetch {
    NSNumber *isPrefetch = [self.allHeaderFields btd_objectForKey:BDTTNetPrefetchResponseTimeStampKey default:nil];//来自预取会带响应时间
    return isPrefetch != nil;
}

@end

#pragma mark - NSOperationQueue

@interface NSOperationQueue (FIFOQueue)
- (void)addOperationAfterLastWithBlock:(void (^)(void))block;
@end

@implementation NSOperationQueue (FIFOQueue)

- (void)addOperationAfterLastWithBlock:(void (^)(void))block {
    if (self.maxConcurrentOperationCount != 1) {
        self.maxConcurrentOperationCount = 1;
    }

    NSOperation *lastOp = self.operations.lastObject;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:block];
    if (lastOp != nil) {
        [op addDependency:lastOp];
    }
    [self addOperation:op];
}

@end

#pragma mark - BDTTNetPrefetch && BDTTNetPrefetchTask extension

@interface BDTTNetPrefetch ()

@property (strong) NSMutableDictionary *taskMap;
@property (strong) NSHashTable<id<BDTTNetPrefetchObserver>> *observers;

@end

@interface BDTTNetPrefetchTask()

@property (strong) NSOperationQueue *operationQueue;
@property (strong) TTHttpTask *httpTask;
@property (strong) NSDate *prefetchDate;
@property (strong) NSDate *hitDate;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) BOOL hasResendRequest;
@end

#pragma mark - BDTTNetPrefetchTask

@implementation BDTTNetPrefetchTask

- (instancetype)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.underlyingQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
        self.operationQueue.suspended = YES;
        self.request = request;
    }
    return self;
}

- (void)prefetch {
   __weak typeof(self)weakSelf = self;
   NSOperationQueue *operationQueue = self.operationQueue;
   TTNetworkChunkedDataReadBlock dataCB = ^(NSData *data) {
       BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request Received Data: %ld", data.length);
       [operationQueue addOperationAfterLastWithBlock:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.dataCallback && !strongSelf.hasResendRequest) {
                strongSelf.dataCallback(data);
            }
       }];
   };
   
   TTNetworkObjectFinishBlockWithResponse finishCB = ^(NSError *error, id obj, TTHttpResponse *response) {
       BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request Finish, Error: %@", error);
       weakSelf.failed = error != nil;
       [operationQueue addOperationAfterLastWithBlock:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.callbackWithResponse && !strongSelf.hasResendRequest) {
                strongSelf.callbackWithResponse(error, obj, response);
            }
       }];
   };

   TTNetworkURLRedirectBlock redirectCB = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
       BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request Redirect, newURL: %@", new_location);
       [operationQueue addOperationAfterLastWithBlock:^{
           __strong __typeof(weakSelf)strongSelf = weakSelf;
           if (strongSelf.redirectCallback) {
                strongSelf.redirectCallback(new_location, old_repsonse);
           }
       }];
   };
    
    TTNetworkChunkedDataHeaderBlock headerCB = ^(TTHttpResponse *response) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request Received Response, allHeaderFields: %@, request: %@", response.allHeaderFields, self.request.URL);
        weakSelf.response = response;
        weakSelf.responseDate = NSDate.date;
        response.allHeaderFields[BDTTNetPrefetchResponseTimeStampKey] = @((int64_t)[NSDate.date timeIntervalSince1970] * 1000).stringValue;
        BOOL shouldResendRequest = [self shouldResendRequestWithResponse:response];
        
        if (shouldResendRequest) {
            [self resendRequestAfterRejected];
        } else {
            NSString *prefetchId = weakSelf.request.prefetchID;
            [BDTTNetPrefetch.shared.observers.allObjects btd_forEach:^(id<BDTTNetPrefetchObserver> _Nonnull obj) {
                if ([obj respondsToSelector:@selector(prefetchDidReceiveResponse: withPrefetchId:)]) {
                    [obj prefetchDidReceiveResponse:response withPrefetchId:prefetchId];
                }
            }];
            
            [operationQueue addOperationAfterLastWithBlock:^{
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                if (strongSelf.headerCallback) {
                    strongSelf.headerCallback(response);
                }
            }];
        }
    };
    
    BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request Begin: %@", self.request.URL);
    [self loadRequest:self.request withHeaderCallback:headerCB dataCallback:dataCB finishCallback:finishCB redirectCallback:redirectCB];
}

- (void)resendRequestAfterRejected {
    self.hasResendRequest = YES;
    __weak typeof(self)weakSelf = self;
    NSOperationQueue *operationQueue = self.operationQueue;
    [self cancel]; // 请求中命中被拒绝的预取请求，cancel 并重新发起
    NSURLRequest *request = [self nomalRequest];
    BDTTNetPrefetch_InfoLog(@"SSR Prefetch, re-request since hitting the refused prefetch-request, URL: %@", request.URL);
    
    TTNetworkChunkedDataHeaderBlock headerCB = ^(TTHttpResponse *response) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Resend Request, Received Response, allHeaderFields: %@, request: %@", response.allHeaderFields, self.request.URL);
        
        [BDTTNetPrefetch.shared.observers.allObjects btd_forEach:^(id<BDTTNetPrefetchObserver> _Nonnull obj) {
            if ([obj respondsToSelector:@selector(didResendRequestWithResponse:)]) {
                [obj didResendRequestWithResponse:response];
            }
        }];
        
        [operationQueue addOperationAfterLastWithBlock:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.headerCallback) {
                strongSelf.headerCallback(response);
            }
        }];
    };
    
    TTNetworkChunkedDataReadBlock dataCB = ^(NSData *data) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Resend Request, Received Data: %ld", data.length);
        [operationQueue addOperationAfterLastWithBlock:^{
             __strong __typeof(weakSelf)strongSelf = weakSelf;
             if (strongSelf.dataCallback) {
                 strongSelf.dataCallback(data);
             }
        }];
    };
    
    TTNetworkObjectFinishBlockWithResponse finishCB = ^(NSError *error, id obj, TTHttpResponse *response) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Resend Request, Finish With Error: %@", error);
        weakSelf.failed = error != nil;
        [operationQueue addOperationAfterLastWithBlock:^{
             __strong __typeof(weakSelf)strongSelf = weakSelf;
             if (strongSelf.callbackWithResponse) {
                 strongSelf.callbackWithResponse(error, obj, response);
             }
        }];
    };

    TTNetworkURLRedirectBlock redirectCB = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Resend Request, Redirect to newURL: %@", new_location);
        [operationQueue addOperationAfterLastWithBlock:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.redirectCallback) {
                 strongSelf.redirectCallback(new_location, old_repsonse);
            }
        }];
    };
    
    [self loadRequest:request withHeaderCallback:headerCB dataCallback:dataCB finishCallback:finishCB redirectCallback:redirectCB];
}

// 请求参数中去掉 pre_request 的正常请求, 重新拼接新的 URL
- (NSURLRequest *)nomalRequest {
    NSString *originalURL = [NSString stringWithFormat:@"%@://%@", self.request.URL.absoluteString.btd_scheme, self.request.URL.absoluteString.btd_path];
    NSMutableDictionary *originalParams = [self.request.URL btd_queryItemsWithDecoding].mutableCopy;
    [originalParams removeObjectForKey:@"pre_request"];
    NSURL *newURL = [[NSURL URLWithString:originalURL] btd_URLByMergingQueries:originalParams.copy];
    NSURLRequest *request = [NSURLRequest requestWithURL:newURL];
    return request;
}

/*
 判断当前的预取请求是否在请求中命中，如果在 pre_request = 2 的情况下请求中命中，并且这次的预取请求被拒绝了，需要重新发一次请求（不包含 pre_request）
 */
- (BOOL)shouldResendRequestWithResponse:(TTHttpResponse *)response {
    BOOL shouldResend = NO;
    NSMutableDictionary *allHeaderFields = response.allHeaderFields;
    NSInteger preRejectType = [allHeaderFields btd_intValueForKey:@"pre-reject" default:0];
    NSDictionary *requestParams = [self.request.URL btd_queryItemsWithDecoding];
    NSInteger preRequestType = [requestParams btd_intValueForKey:@"pre_request" default:0];
    shouldResend = self.hitPrefetch && (preRequestType == 2) && (preRejectType != 0);
    return shouldResend;
}

- (void)loadRequest:(NSURLRequest *)request
 withHeaderCallback:(TTNetworkChunkedDataHeaderBlock)headerCB
       dataCallback:(TTNetworkChunkedDataReadBlock)dataCB
     finishCallback:(TTNetworkObjectFinishBlockWithResponse)finishCB
   redirectCallback:(TTNetworkURLRedirectBlock)redirectCB {
    self.httpTask = [[TTNetworkManager shareInstance] requestForWebview:request
                                                             autoResume:NO
                                                        enableHttpCache:[BDWebKitSettingsManger bdTTNetCacheControlEnable]
                                                         headerCallback:headerCB
                                                           dataCallback:dataCB
                                                   callbackWithResponse:finishCB
                                                       redirectCallback:redirectCB];
    
    self.httpTask.timeoutInterval = [BDWebKitSettingsManger bdFixTTNetTimeout];
    [self.httpTask resume];
}

- (void)resume {
    self.operationQueue.suspended = NO;
}

- (void)cancel {
    if (self.httpTask.state == TTHttpTaskStateRunning) {
        [self.httpTask cancel];
    }
}

- (uint64_t)opitimizeMillSecond {
    if (!self.prefetchDate || !self.hitDate) {
        return 0;
    }
    return (uint64_t)([self.hitDate timeIntervalSinceDate:self.prefetchDate] * 1000);
}

- (BOOL)isValid {
    NSUInteger cacheTime = self.cacheTime?:30;
    if (self.failed) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch, failed to prefetch: %@", self.request.URL);
        return NO;
    }
    
    if (self.responseDate) {
        NSUInteger timeInterval = (NSUInteger)[NSDate.date timeIntervalSinceDate:self.responseDate];
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch Request, prefetch %@, request: %@", (timeInterval < cacheTime) ? @"Valid" : @"Expired", self.request.URL);
        return timeInterval < cacheTime;
    }

    if (self.prefetchDate && !self.responseDate) {
        BDTTNetPrefetch_InfoLog(@"SSR Prefetch, hit prefetch-request: %@", self.request.URL);
        return YES;
    }

    return NO;
}

@end

#pragma mark - BDTTNetPrefetch

@implementation BDTTNetPrefetch

+ (instancetype)shared {
    static BDTTNetPrefetch *prefetch = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        prefetch = [BDTTNetPrefetch new];
    });
    return prefetch;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.taskMap = @{}.mutableCopy;
        self.observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addPrefetchObserver:(id<BDTTNetPrefetchObserver>)observer {
    if (observer) {
        [self.observers addObject:observer];
    }
}

- (BDTTNetPrefetchTask *)prefetchTaskWithPrefetchId:(NSString *)prefetchId {
    return [self.taskMap btd_objectForKey:prefetchId default:nil];
}

- (BDTTNetPrefetchTask *)dequeuePrefetchTaskWithRequest:(NSURLRequest *)request {
    if (![BDWebKitSettingsManger bdEnablePrefetch]) {
        return nil;
    }
    
    __block BDTTNetPrefetchTask *targetTask = nil;
    __block NSString *targetId = nil;
    @synchronized (self) {
        NSMutableArray *expiredTasks = @[].mutableCopy;
        [self.taskMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull prefetchId, BDTTNetPrefetchTask * _Nonnull task, BOOL * _Nonnull stop) {
            // 清理无效预取任务
            if (![task isValid]) {
                [expiredTasks addObject:prefetchId];
            }
            
            if ([prefetchId isEqualToString:request.prefetchID] && [task isValid]) {
                targetId = prefetchId;
                targetTask = task;
            }
            
        }];
        
        if (targetId) {
            [self.taskMap removeObjectForKey:targetId];
        }
        
        if (expiredTasks.count) {
            [self.taskMap removeObjectsForKeys:expiredTasks];
        }
    }
    
    targetTask.hitDate = NSDate.date;
    return targetTask;
}

- (void)prefetchWithRequest:(NSURLRequest *)request {
    
    if (![BDWebKitSettingsManger bdEnablePrefetch]) {
        return;
    }
    
    BDTTNetPrefetchTask *task = [[BDTTNetPrefetchTask alloc] initWithRequest:request];
    @synchronized (self) {
        if (![self containsRequest:request]) {
            self.taskMap[request.prefetchID] = task;
            task.prefetchDate = NSDate.date;
            [task prefetch];
        } 
    }
}

- (BOOL)containsRequest:(NSURLRequest *)request {
    @synchronized (self) {
        BDTTNetPrefetchTask *task = [self.taskMap btd_objectForKey:request.prefetchID default:nil];
        if ([task isValid]) {
            return YES;
        }
    }
    return NO;
}

@end
