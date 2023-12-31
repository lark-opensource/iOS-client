//
//  BDWebViewPreloadManager.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/12.
//

#import "BDWebViewPreloadManager.h"
#import "BDPreloadManager.h"
#import "BDPreloadConfig.h"
#import "BDPreloadMonitor.h"
#import "BDWebViewPreloadTask.h"

#import <YYCache/YYCache.h>
#import <YYCache/YYMemoryCache.h>
#import <CommonCrypto/CommonDigest.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>


#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

static NSString * const TAG = @"BDPreload";

@interface BDWebViewPreloadManager()

@property (nonatomic, strong) YYCache *yyCache;
@property (nonatomic, copy) YYMemoryCache *taskCaches;

@end

@interface BDWebViewPreloadOperation : NSOperation

@property (nonatomic, copy) NSMutableData *data;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSDictionary *headerField;

@property (nonatomic, assign) BOOL useHTTPCaches;
@property (nonatomic, assign) NSTimeInterval cacheDuration;
@property (nonatomic, assign) BOOL skipSSLCertificateError;
@property (nonatomic, copy) void(^completion)(NSError *error);
@property (nonatomic, copy) void(^dataCompletion)(NSData *data, NSError *error);

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, strong) BDWebViewPreloadTask *task;

@end

@implementation BDWebViewPreloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithURLString:(NSString *)urlString
                      headerField:(NSDictionary *)headerField
                    useHttpCaches:(BOOL)useHttpCaches
                    cacheDuration:(NSTimeInterval)cacheDuration
                       dataCompletion:(void(^)(NSData *data, NSError *error))completion
{
    self = [super init];
    if (self) {
        _urlString = urlString;
        _headerField = headerField;
        _dataCompletion = completion;
        _useHTTPCaches = useHttpCaches;
        _cacheDuration = cacheDuration;
        _data = [NSMutableData data];
        self.bdp_scene = @"WebView";
        if ([[BDPreloadConfig sharedConfig] needVerifySSL:urlString]) {
            _skipSSLCertificateError = NO;
        } else {
            _skipSSLCertificateError = YES;
        }
    }
    return self;
}


- (instancetype)initWithURLString:(NSString *)urlString
                      headerField:(NSDictionary *)headerField
                    useHttpCaches:(BOOL)useHttpCaches
                    cacheDuration:(NSTimeInterval)cacheDuration
                       completion:(void(^)(NSError *error))completion
{
    self = [self initWithURLString:urlString headerField:headerField useHttpCaches:useHttpCaches cacheDuration:cacheDuration dataCompletion:nil];
    if (self) {
        self.completion = completion;
    }
    return self;
}

- (void)start
{
    self.executing = YES;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL btd_URLWithString:self.urlString]];
    request.HTTPMethod = @"GET";
    [request setAllHTTPHeaderFields:_headerField];
    
    @weakify(self);
    self.task = [[BDWebViewPreloadTask alloc] initWithRequest:request headerCallback:nil
                                                                dataCallback:^(NSData * _Nonnull obj) {
        @strongify(self);
        @synchronized (self.data) {
            [self.data appendData:obj];
        }
    } callbackWithResponse:^(NSError * _Nullable error, id  _Nullable obj, TTHttpResponse * _Nullable response) {
        // To match the old code, we dispatch the callback to main thread.
        @strongify(self);
        @weakify(self);
        btd_dispatch_async_on_main_queue(^{
            @strongify(self);
            [self finishWithObj:obj error:error response:response];
        });
    } redirectCallback:nil];
    if (_skipSSLCertificateError) {
        [self.task setSkipSSLCertificateError:YES];
    }
    [self.task setPriority:0.25f]; // Very Low
    
    [BDWebViewPreloadManager.sharedInstance setTask:self.task URLString:self.urlString];
    [self.task resume];
}

/**
 @note Note that we don't set  TTNetworkChunkedDataReadBlock to nil, thus, the obj here will receive nil.
 */
- (void)finishWithObj:(NSData *)obj error:(NSError *)error response:(TTHttpResponse *)response
{
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"WebView preload end %@", self.urlString);
    // if current cache duration is equal to 0, then end the save operation.
    NSTimeInterval cacheDuration = _useHTTPCaches ? [self getHttpCachesIntervalWithResponse:response] : _cacheDuration;
    NSData *finalData = nil;
    @synchronized (self.data) {
        finalData = self.data;
    }
    if (!error && finalData && response && cacheDuration > 0) {
        BDPreloadCachedResponse *cachedResponse = [[BDPreloadCachedResponse alloc] init];
        cachedResponse.statusCode = response.statusCode;
        cachedResponse.allHeaderFields = response.allHeaderFields;
        cachedResponse.data = finalData;
        cachedResponse.cacheDuration = cacheDuration;
        cachedResponse.saveTime = CACurrentMediaTime();
        [[BDWebViewPreloadManager sharedInstance] saveResponse:cachedResponse forURLString:response.URL.absoluteString];
    }
    
    long long contentLength = [[response.allHeaderFields objectForKey:@"Content-Length"] longLongValue];
    contentLength = contentLength>0?contentLength:obj.length;

    [BDPreloadMonitor trackPreloadWithKey:self.urlString
                                    scene:@"WebView"
                              trafficSize:contentLength
                                    error:error
                                    extra:@{@"url":self.urlString?:@""}];
    
    if (self.dataCompletion) {
        self.dataCompletion(finalData, error);
    }
    
    if (self.completion) {
        self.completion(error);
    }
    
    self.finished = YES;
    self.executing = NO;
}

- (NSTimeInterval)getHttpCachesIntervalWithResponse:(TTHttpResponse *)response
{
    NSString *cacheControl = [response.allHeaderFields btd_stringValueForKey:@"cache-control"];
    if ([cacheControl containsString:@"no-cache"] || [cacheControl containsString:@"no-store"]) {
        return 0;
    }
    
    NSArray<NSString *> *cacheArray = [cacheControl componentsSeparatedByString:@","];
    __block NSTimeInterval maxAge = 0;
    __block NSTimeInterval sMaxAge = 0;
    [cacheArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:@"max-age"]) {
            NSArray *objArr = [obj componentsSeparatedByString:@"="];
            if (objArr.count == 2) {
                maxAge = [objArr.lastObject doubleValue];
            }
        }
        if ([obj containsString:@"s-maxage"]) {
            NSArray *objArr = [obj componentsSeparatedByString:@"="];
            if (objArr.count == 2) {
                sMaxAge = [objArr.lastObject doubleValue];
            }
        }
    }];
    
    // ensure max-age should be a positive number.
    sMaxAge = MAX(0, sMaxAge);
    maxAge = MAX(0, maxAge);
    return sMaxAge != 0 ? sMaxAge : maxAge;
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

- (NSString *)bdp_preloadKey {
    return self.urlString;
}

@end

@implementation BDWebViewPreloadManager


+ (instancetype)sharedInstance {
    static BDWebViewPreloadManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BDWebViewPreloadManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        NSString *getPath = [BDPreloadConfig sharedConfig].diskCachePath;
        _yyCache = [[YYCache alloc] initWithPath:getPath];
        _yyCache.diskCache.countLimit = [BDPreloadConfig sharedConfig].diskCountLimit;
        _yyCache.diskCache.ageLimit = [BDPreloadConfig sharedConfig].diskAgeLimit;
        _yyCache.memoryCache.costLimit = [BDPreloadConfig sharedConfig].memorySizeLimit;
        _yyCache.memoryCache.ageLimit = [BDPreloadConfig sharedConfig].memoryAgeLimit;
        _yyCache.memoryCache.autoTrimInterval = [BDPreloadConfig sharedConfig].memoryAgeLimit;
        _taskCaches = [[YYMemoryCache alloc] init];
        _taskCaches.shouldRemoveAllObjectsOnMemoryWarning = YES;
        _taskCaches.ageLimit = 30;
    }
    return self;
}

- (YYDiskCache *)diskCache {
    return self.yyCache.diskCache;
}

- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                useHttpCaches:(BOOL)useHttpCaches
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
                   completion:(void(^)(NSError *error))callback {
    if ([self responseForURLString:urlString]) {
        if (callback) {
            callback(nil);
        }
        return;
    }

    NSURL *URL = [NSURL btd_URLWithString:urlString];
    
    if (!URL) {
        BDALOG_PROTOCOL_INFO_TAG(TAG, @"Current URL is incorrect. URL: %@", urlString);
        NSError *error = [NSError errorWithDomain:@"kBDPreloadURLError" code:0 userInfo:nil];
        if (callback) {
            callback(error);
        }
        return;
    }
    
    NSOperation *task = [[BDWebViewPreloadOperation alloc] initWithURLString:urlString
                                                                 headerField:headerField
                                                               useHttpCaches:useHttpCaches
                                                               cacheDuration:cacheDuration
                                                                  completion:callback];
    
    task.bdp_scene = @"WebView";
    task.queuePriority = priority;
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
}

- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                useHttpCaches:(BOOL)useHttpCaches
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
               dataCompletion:(void (^)(NSData *, NSError *))callback
{
    BDPreloadCachedResponse *response = [self responseForURLString:urlString];
    if (response && response.data) {
        if (callback) {
            callback(response.data, nil);
        }
        return;
    }

    NSURL *URL = [NSURL btd_URLWithString:urlString];
    
    if (!URL) {
        BDALOG_PROTOCOL_INFO_TAG(TAG, @"Current URL is incorrect. URL: %@", urlString);
        NSError *error = [NSError errorWithDomain:@"kBDPreloadURLError" code:0 userInfo:nil];
        if (callback) {
            callback(nil, error);
        }
        return;
    }
    
    NSOperation *task = [[BDWebViewPreloadOperation alloc] initWithURLString:urlString
                                                                 headerField:headerField
                                                               useHttpCaches:useHttpCaches
                                                               cacheDuration:cacheDuration
                                                              dataCompletion:callback];
    task.bdp_scene = @"WebView";
    task.queuePriority = priority;
    [[BDPreloadManager sharedInstance] addPreloadTask:task];
}


- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
                   completion:(void(^)(NSError *error))callback {
    return [self fetchDataForURLString:urlString
                           headerField:headerField
                         useHttpCaches:NO
                         cacheDuration:cacheDuration
                         queuePriority:priority
                            completion:callback];
}

- (void)setTask:(BDWebViewPreloadTask *)preloadTask URLString:(NSString *)urlString
{
    BDWebViewPreloadTask *task = [BDWebViewPreloadManager.sharedInstance.taskCaches objectForKey:[urlString btd_md5String]];
    preloadTask.startDate = [NSDate date];
    // double check task valid.
    if (!task || ![task isValid]) {
        [BDWebViewPreloadManager.sharedInstance.taskCaches setObject:preloadTask forKey:[urlString btd_md5String]];
    }
}

- (BDWebViewPreloadTask *)taskForURLString:(NSString *)urlString
{
    NSString *urlKey = [urlString btd_md5String];
    BDWebViewPreloadTask *task = nil;
    // Lock it here to avoid get dirty value.
    @synchronized(self.taskCaches) {
        task = [self.taskCaches objectForKey:urlKey];
        task = [task isValid] ? task : nil;
        if (task) {
            // If someone get the task, we assume that they should reResume it. So we remove it from caches.
            [self.taskCaches removeObjectForKey:urlKey];
            task.hitDate = [NSDate date];
        }
    }
    return task;
}

- (BDPreloadCachedResponse *)responseForURLString:(NSString *)urlString {
    if (isEmptyString(urlString)) {
        return nil;
    }
    
    NSURL *url = [NSURL btd_URLWithString:urlString];
    if (!url) {
        return nil;
    }
    
    __auto_type components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.fragment = nil;
    BDPreloadCachedResponse *response = (BDPreloadCachedResponse *)[self.yyCache objectForKey:[self.class MD5HashString:components.URL.absoluteString]];
    if (response && (!response.data || (response.saveTime > 0.0 && response.cacheDuration >= 0.0 &&
                                        response.saveTime + response.cacheDuration < CACurrentMediaTime()))) {
        [self clearDataForURLString:urlString];
        return nil;
    }
    return response;
}

- (void)saveResponse:(nullable BDPreloadCachedResponse *)response forURLString:(NSString *)urlString {
    if (isEmptyString(urlString)) {
        return;
    }
    
    NSURL *url = [NSURL btd_URLWithString:urlString];
    
    if (!url) {
        return;
    }
    
    __auto_type components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.fragment = nil;
    [self.yyCache setObject:response forKey:[self.class MD5HashString: components.URL.absoluteString]];
}

- (void)clearDataForURLString:(NSString *)urlString {
    [self saveResponse:nil forURLString:urlString];
}

#pragma mark - Helper

+ (NSString *)MD5HashString:(NSString *)aString
{
    if (isEmptyString(aString)) {
        return nil;
    }
    const char *str = [aString UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (int)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@end
