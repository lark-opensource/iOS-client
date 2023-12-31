//
//  BDTTNetPreloadManager.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/16.
//

#import "BDTTNetPreloadManager.h"
#import "BDPreloadManager.h"
#import "BDPreloadMonitor.h"

#import <BDAlogProtocol/BDAlogProtocol.h>

static NSString * const TAG = @"BDPreload";

@interface BDTTNetPreloadOperation ()

@property (assign, nonatomic, getter = isExecuting, readwrite) BOOL executing;
@property (assign, nonatomic, getter = isFinished, readwrite) BOOL finished;
@property (nonatomic, strong, readwrite) TTHttpTask *task;

@end

@implementation BDTTNetPreloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start {
    self.executing = YES;
    
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"WebView preload start %@", self.urlString);
    [self sendRequest];
    
}

- (void)sendRequest {
    
    __weak typeof(self) wself = self;
    TTNetworkObjectFinishBlockWithResponse finishCallBack = ^(NSError *error, id obj, TTHttpResponse *response) {
        __strong typeof(wself) self = wself;
        BDALOG_PROTOCOL_INFO_TAG(TAG, @"TTNet preload end %@ %@", self.urlString, error ?: @"success");
        
        long long contentLength = [[response.allHeaderFields objectForKey:@"Content-Length"] longLongValue];
        contentLength = contentLength > 0 ? contentLength : (([obj isKindOfClass:[NSData class]])? ((NSData *)obj).length : 0);
        
        [BDPreloadMonitor trackPreloadWithKey:self.urlString
                                        scene:@"TTNet"
                                  trafficSize:contentLength
                                        error:error
                                        extra:@{@"url":self.urlString?:@""}];
        
        if (!error || self.retryCount == 0) {
            if (self.completion) {
                self.completion(error, obj, response);
            }
            
            self.finished = YES;
            self.executing = NO;
        } else {
            self.retryCount --;
            BDALOG_PROTOCOL_INFO_TAG(TAG, @"TTNet preload retry %@ %@", self.urlString, @(self.retryCount));
            [self sendRequest];
        }
    };
    
    if (self.isBinary) {
        self.task = [[TTNetworkManager shareInstance] requestForBinaryWithResponse:self.urlString
                                                                            params:self.params
                                                                            method:self.method
                                                                  needCommonParams:self.needCommonParams
                                                                 requestSerializer:self.requestSerializer
                                                                responseSerializer:self.responseSerializer
                                                                        autoResume:NO
                                                                          callback:finishCallBack];
    } else {
        self.task = [[TTNetworkManager shareInstance] requestForJSONWithResponse:self.urlString
                                                                          params:self.params
                                                                          method:self.method
                                                                needCommonParams:self.needCommonParams
                                                                     headerField:self.headerField
                                                               requestSerializer:self.requestSerializer
                                                              responseSerializer:self.responseSerializer
                                                                      autoResume:NO
                                                                        callback:finishCallBack];
    }
    
    
    if (self.timeoutInterval > 0) {
        self.task.timeoutInterval = self.timeoutInterval;
    }
    [self.task setPriority:0.25f]; // Very Low
    [self.task resume];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)cancel {
    [super cancel];
    // 取消网络任务
    [self.task cancel];
}

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

- (void)setRetryCount:(NSUInteger)retryCount {
    if (retryCount >= 0 && retryCount <= 3) {
        _retryCount = retryCount;
    }
}

@end

@implementation BDTTNetPreloadManager

+ (void)requestForJSONWithResponse:(NSString *)URL
                          callback:(TTNetworkJSONFinishBlockWithResponse)callback {
    BDTTNetPreloadOperation *task = [[BDTTNetPreloadOperation alloc] init];
    task.urlString = URL;
    task.bdp_preloadKey = URL;
    task.bdp_scene = @"TTNet";
    task.method = @"GET";
    task.needCommonParams = YES;
    task.completion = callback;
    
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
}

+ (void)requestForJSONWithResponse:(NSString *)URL
                            params:(id)params
                            method:(NSString *)method
                  needCommonParams:(BOOL)commonParams
                       headerField:(NSDictionary *)headerField
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                   timeoutInterval:(NSTimeInterval)timeoutInterval
                        retryCount:(NSUInteger)retryCount
                          onlyWiFi:(BOOL)onlyWiFi
                          callback:(TTNetworkJSONFinishBlockWithResponse)callback {
    BDTTNetPreloadOperation *task = [[BDTTNetPreloadOperation alloc] init];
    task.urlString = URL;
    task.bdp_preloadKey = URL;
    task.params = params;
    task.method = method;
    task.needCommonParams = commonParams;
    task.headerField = headerField;
    task.requestSerializer = requestSerializer;
    task.responseSerializer = responseSerializer;
    task.completion = callback;
    task.timeoutInterval = timeoutInterval;
    task.retryCount = retryCount;
    task.bdp_onlyWifi = onlyWiFi;
    
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
}

+ (void)requestForJSONWithResponse:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(NSDictionary *)headerField
                         requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                  callback:(TTNetworkJSONFinishBlockWithResponse)callback {

    [self requestForJSONWithResponse:URL
                              params:params
                              method:method
                    needCommonParams:commonParams
                         headerField:headerField
                   requestSerializer:requestSerializer
                  responseSerializer:responseSerializer
                     timeoutInterval:0
                          retryCount:0
                            onlyWiFi:NO
                            callback:(TTNetworkJSONFinishBlockWithResponse)callback];
}

+ (void)requestForBinaryWithResponse:(NSString *)URL
                            callback:(TTNetworkObjectFinishBlockWithResponse)callback {
    BDTTNetPreloadOperation *task = [[BDTTNetPreloadOperation alloc] init];
    task.urlString = URL;
    task.bdp_preloadKey = URL;
    task.bdp_scene = @"TTNet";
    task.method = @"GET";
    task.needCommonParams = YES;
    task.completion = callback;
    task.isBinary = YES;
    
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
}

+ (void)requestForBinaryWithResponse:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                  responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                            callback:(TTNetworkObjectFinishBlockWithResponse)callback {
    BDTTNetPreloadOperation *task = [[BDTTNetPreloadOperation alloc] init];
    task.urlString = URL;
    task.bdp_preloadKey = URL;
    task.params = params;
    task.method = method;
    task.needCommonParams = commonParams;
    task.headerField = headerField;
    task.requestSerializer = requestSerializer;
    task.responseSerializer = responseSerializer;
    task.bdp_scene = @"TTNet";
    task.completion = callback;
    task.isBinary = YES;
    
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
    
}

+ (void)requestForBinaryWithResponse:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                  responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                     timeoutInterval:(NSTimeInterval)timeoutInterval
                          retryCount:(NSUInteger)retryCount
                            callback:(TTNetworkObjectFinishBlockWithResponse)callback {
    BDTTNetPreloadOperation *task = [[BDTTNetPreloadOperation alloc] init];
    task.urlString = URL;
    task.bdp_preloadKey = URL;
    task.params = params;
    task.method = method;
    task.needCommonParams = commonParams;
    task.headerField = headerField;
    task.requestSerializer = requestSerializer;
    task.responseSerializer = responseSerializer;
    task.completion = callback;
    task.isBinary = YES;
    task.retryCount = retryCount;
    task.timeoutInterval = timeoutInterval;
    task.bdp_scene = @"TTNet";
    
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
    
}

@end
