//
//  BDWebViewPreloadTask.m
//  Musically
//
//  Created by gejunchen.ChenJr on 2022/11/1.
//

#import "BDWebViewPreloadTask.h"
#import <TTNetworkManager/TTHttpTask.h>
#import <TTNetworkManager/TTNetworkManager.h>

#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/BTDMacros.h>

#pragma mark - NSOperationQueue

@interface BDPreloadOperationQueue : NSOperationQueue

- (void)bdw_addOperationAfterLastWithBlock:(void (^)(void))block;

@end

@implementation BDPreloadOperationQueue

- (void)bdw_addOperationAfterLastWithBlock:(void (^)(void))block {
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

@interface BDWebViewPreloadTask()

@property (nonatomic, strong) BDPreloadOperationQueue *operationQueue;
@property (nonatomic, strong) TTHttpTask *httpTask;
@property (atomic, assign) BOOL failed;

@property (nonatomic, copy) TTNetworkChunkedDataHeaderBlock innerHeaderCallBack;
@property (nonatomic, copy) TTNetworkChunkedDataReadBlock innerDataCallBack;
@property (nonatomic, copy) TTNetworkObjectFinishBlockWithResponse innerCallBackWithResponse;
@property (nonatomic, copy) TTNetworkURLRedirectBlock innerRedirectCallBack;

@end

@implementation BDWebViewPreloadTask


#pragma mark - init

- (instancetype)initWithRequest:(NSURLRequest *)request
                 headerCallback:(TTNetworkChunkedDataHeaderBlock)headerCallback
                   dataCallback:(TTNetworkChunkedDataReadBlock)dataCallback
           callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse redirectCallback:(TTNetworkURLRedirectBlock)redirectCallback
{
    if (self = [super init]) {
        self.request = request;
        self.operationQueue = [[BDPreloadOperationQueue alloc] init];
        self.operationQueue.underlyingQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
        self.operationQueue.suspended = YES;
        
        @weakify(self);
        self.innerHeaderCallBack = ^(TTHttpResponse *response) {
            if (headerCallback) {
                headerCallback(response);
            }
            @strongify(self);
            BDALOG_PROTOCOL_INFO(@"SSR Prefetch Request Received Response, allHeaderFields: %@, request: %@", response.allHeaderFields, self.request.URL);
            self.responseDate = NSDate.date;
            @weakify(self);
            [self.operationQueue bdw_addOperationAfterLastWithBlock:^{
                @strongify(self);
                if (self.headerCallback) {
                    self.headerCallback(response);
                }
            }];
        };
        
        self.innerDataCallBack = ^(NSData *data) {
            if (dataCallback) {
                dataCallback(data);
            }
            @strongify(self);
            BDALOG_PROTOCOL_INFO(@"Preload Request Received Data: %ld", data.length);
            @weakify(self);
            [self.operationQueue bdw_addOperationAfterLastWithBlock:^{
                @strongify(self);
                if (self.dataCallback) {
                    self.dataCallback(data);
                }
            }];
        };

        self.innerRedirectCallBack = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
            if (redirectCallback) {
                redirectCallback(new_location, old_repsonse);
            }
            @strongify(self);
            BDALOG_PROTOCOL_INFO(@"Preload Request Redirect, newURL: %@", new_location);
            @weakify(self);
            [self.operationQueue bdw_addOperationAfterLastWithBlock:^{
                @strongify(self);
                if (self.redirectCallback) {
                    self.redirectCallback(new_location, old_repsonse);
                }
            }];
        };
        
        self.innerCallBackWithResponse = ^(NSError *error, id obj, TTHttpResponse *response) {
            @strongify(self);
            if (callbackWithResponse) {
                callbackWithResponse(error, obj, response);
            }
            BDALOG_PROTOCOL_INFO(@"Preload Request Finish, Error: %@", error);
            self.failed = error != nil;
            @weakify(self);
            [self.operationQueue bdw_addOperationAfterLastWithBlock:^{
                @strongify(self);
                if (self.callbackWithResponse) {
                    self.callbackWithResponse(error, obj, response);
                }
            }];
        };
        
        self.httpTask = [[TTNetworkManager shareInstance] requestForWebview:request
                                                                 autoResume:NO
                                                            enableHttpCache:NO
                                                             headerCallback:_innerHeaderCallBack
                                                               dataCallback:_innerDataCallBack
                                                       callbackWithResponse:_innerCallBackWithResponse
                                                           redirectCallback:_innerRedirectCallBack];
        self.httpTask.timeoutInterval = 10;
    }
    return self;
}

#pragma mark - operation

- (void)resume
{
    [self.httpTask resume];
}

- (void)reResume
{
    self.operationQueue.suspended = NO;
}

- (void)setSkipSSLCertificateError:(BOOL)skipSSLCertificateError
{
    [self.httpTask setSkipSSLCertificateError:skipSSLCertificateError];
}

- (void)setPriority:(float)priority
{
    [self.httpTask setPriority:priority];
}

- (void)cancel
{
    if (_httpTask.state == TTHttpTaskStateRunning) {
        [self.httpTask cancel];
        self.operationQueue.suspended = YES;
    }
}

- (BOOL)isValid
{
    NSUInteger cacheTime = 30;
    if (self.failed) {
        BDALOG_PROTOCOL_INFO(@"Failed to prefetch: %@", self.request.URL);
        return NO;
    }
    
    if (self.responseDate) {
        NSUInteger timeInterval = (NSUInteger)[NSDate.date timeIntervalSinceDate:self.responseDate];
        BDALOG_PROTOCOL_INFO(@"Preload Request, prefetch %@, request: %@", (timeInterval < cacheTime) ? @"Valid" : @"Expired", self.request.URL);
        return timeInterval < cacheTime;
    }

    if (self.startDate && !self.responseDate) {
        BDALOG_PROTOCOL_INFO(@"Preload Request, hit ttnet reuse: %@", self.request.URL);
        return YES;
    }
    return NO;
}

- (uint64_t)optimizedTime
{
    if (!self.startDate || !self.hitDate) {
        BDALOG_PROTOCOL_INFO(@"Preload Request not start yet");
        return 0;
    }
    return (uint64_t)([self.hitDate timeIntervalSinceDate:self.startDate] * 1000);
}

- (void)dealloc
{
    @autoreleasepool {
        [self.operationQueue cancelAllOperations];
        self.operationQueue.suspended = NO;
    }
}

@end

