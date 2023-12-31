//
// JATNetworkOpt.m
// 
//
// Created by Aircode on 2022/8/3

#import "JATNetworkOpt.h"
#import <pthread/pthread.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <ByteDanceKit/NSDate+BTDAdditions.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTNetworkManager/TTNetworkManagerChromium.h>
#import <TTNetworkManager/TTHttpTask.h>
#import "JATNetworkOpt+Private.h"
#import "JATNetowrkOptTracker.h"
#import "JATFakeObjectAssert.h"

@class TTHttpTaskChromium;

#pragma mark - TTNetworkExtension
@interface TTNetworkManager (BDJATHOOK)

- (TTHttpTaskChromium *)buildJSONHttpTask:(NSString *)URL
                                   params:(id)params
                                   method:(NSString *)method
                         needCommonParams:(BOOL)needCommonParams
                              headerField:(NSDictionary *)headerField
                        requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                            verifyRequest:(BOOL)verifyRequest
                       isCustomizedCookie:(BOOL)isCustomizedCookie
                                 callback:(TTNetworkJSONFinishBlock)callback
                     callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                           dispatch_queue:(dispatch_queue_t)dispatch_queue;

- (TTHttpTaskChromium *)bdjat_buildJSONHttpTask:(NSString *)URL
                                         params:(id)params
                                         method:(NSString *)method
                               needCommonParams:(BOOL)needCommonParams
                                    headerField:(NSDictionary *)headerField
                              requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                             responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                     autoResume:(BOOL)autoResume
                                  verifyRequest:(BOOL)verifyRequest
                             isCustomizedCookie:(BOOL)isCustomizedCookie
                         callback:(TTNetworkJSONFinishBlock)callback
                           callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                 dispatch_queue:(dispatch_queue_t)dispatch_queue;

@end


@implementation TTNetworkManager (BDJATHOOK)

- (TTHttpTaskChromium *)bdjat_buildJSONHttpTask:(NSString *)URL
                                         params:(id)params
                                         method:(NSString *)method
                               needCommonParams:(BOOL)needCommonParams
                                    headerField:(NSDictionary *)headerField
                              requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                             responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                     autoResume:(BOOL)autoResume
                                  verifyRequest:(BOOL)verifyRequest
                             isCustomizedCookie:(BOOL)isCustomizedCookie
                                       callback:(TTNetworkJSONFinishBlock)callback
                           callbackWithResponse:(TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                 dispatch_queue:(dispatch_queue_t)dispatch_queue {
    BOOL isSubThread = pthread_main_np() == 0;
    if (isSubThread || !autoResume || ![[JATNetworkOpt shared] needSwitchToSubThreadForcelyWitURLString:URL]) {
        return [self bdjat_buildJSONHttpTask:URL
                                      params:params
                                      method:method
                            needCommonParams:needCommonParams
                                 headerField:headerField
                           requestSerializer:requestSerializer
                          responseSerializer:responseSerializer
                                  autoResume:autoResume
                               verifyRequest:verifyRequest
                          isCustomizedCookie:isCustomizedCookie
                                callback:callback
                    callbackWithResponse:callbackWithResponse
                              dispatch_queue:dispatch_queue];
    }
    
    TTHttpTask *task = [[TTHttpTask alloc] init];
    [[JATNetworkOpt shared] execTaskOnSubThread:^{
        [self bdjat_buildJSONHttpTask:URL
                              params:params
                              method:method
                    needCommonParams:needCommonParams
                         headerField:headerField
                   requestSerializer:requestSerializer
                  responseSerializer:responseSerializer
                          autoResume:autoResume
                       verifyRequest:verifyRequest
                  isCustomizedCookie:isCustomizedCookie
                        callback:callback
            callbackWithResponse:callbackWithResponse
                      dispatch_queue:dispatch_queue];
    }];

    return (TTHttpTaskChromium *)[JATFakeObjectAssert useFakeObjAssertWithTarget:task uploadException:YES];
}

- (TTHttpTask *)bdjat_requestForJSONWithURL:(NSString *)URL
                                     params:(id)params
                                     method:(NSString *)method
                           needCommonParams:(BOOL)commonParams
                                   callback:(TTNetworkJSONFinishBlock)callback {
    if (![TTNetworkManager shareInstance].dontCallbackInMainThread) {
        TTNetworkJSONFinishBlock execBlock = ^(NSError *error, id jsonObj) {
            if (callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(error, jsonObj);
                });
            }
        };
        return [self requestForJSONWithURL:URL params:params method:method needCommonParams:commonParams callback:execBlock callbackInMainThread:NO];
        
    }
    return [self bdjat_requestForJSONWithURL:URL params:params method:method needCommonParams:commonParams callback:callback];
}

@end

static NSUInteger kJATNetworkOptDefaultConcurrentCount = 3;

#pragma mark - JATNetworkOpt
@interface JATNetworkOpt()
{
    pthread_rwlock_t _pathLock;
}

@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, assign) BOOL enablePerformance;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSNumber *> *allowedPathDict;
@property (nonatomic, strong) NSMutableArray <NSString *> *fuzzyAllowedPathArray;
@property (nonatomic, strong) NSOperationQueue *sendSubThreadQueue;
@property (nonatomic, strong) JATNetowrkOptTracker *tracker;

@end

@implementation JATNetworkOpt

#pragma mark - life cycle method
+ (instancetype)shared {
    static JATNetworkOpt *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JATNetworkOpt alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_pathLock, NULL);
    }
    return self;
}

#pragma mark - public method
- (void)startWithType:(JATNetworkOptType)type {
    [self startWithType:type concurrentCount:kJATNetworkOptDefaultConcurrentCount];
}

- (void)startWithType:(JATNetworkOptType)type concurrentCount:(NSUInteger)concurrentCount {
    if (!self.isRunning) {
        self.isRunning = YES;
        self.sendSubThreadQueue = [[NSOperationQueue alloc] init];
        self.sendSubThreadQueue.maxConcurrentOperationCount = concurrentCount >= 1 ? concurrentCount : kJATNetworkOptDefaultConcurrentCount;
        if ((type & JATNetworkOptTypeTTNetBuidJsonMethodToSubThread) == JATNetworkOptTypeTTNetBuidJsonMethodToSubThread) {
            [self p_hookTTNetworkChriumHTTPRequestBuildJsonMethod];
        }
    }
}

- (void)updateAllowedMatchPathList:(NSDictionary<NSString *,NSNumber *> *)allowedPaths {
    if (!allowedPaths || allowedPaths.count == 0) {
        return;
    }
    pthread_rwlock_wrlock(&_pathLock);
    [allowedPaths enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] &&
            [obj isKindOfClass:[NSNumber class]]) {
            [self.allowedPathDict setValue:obj forKey:key];
        }
    }];
    pthread_rwlock_unlock(&_pathLock);
}

- (void)updateAllowedFuzzyPathList:(NSDictionary<NSString *,NSNumber *> *)allowedPaths {
    if (!allowedPaths || allowedPaths.count == 0) {
        return;
    }
    pthread_rwlock_wrlock(&_pathLock);
    [allowedPaths enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] &&
            [obj isKindOfClass:[NSNumber class]] &&
            obj.boolValue) {
            [self.fuzzyAllowedPathArray addObject:key];
        }
    }];
    pthread_rwlock_unlock(&_pathLock);
}

- (void)enablePerformanceUpload:(BOOL)enablePerformance {
    self.enablePerformance = enablePerformance;
}

#pragma mark - action
- (BOOL)needSwitchToSubThreadForcelyWitURLString:(NSString *)URLString {
    if (!URLString || ![URLString isKindOfClass:[NSString class]]) {
        NSAssert(NO, @"JATNetworkOpt URLString is not string!!!");
        return NO;
    }
    uint64_t startTS = 0;
    if (self.enablePerformance) {
        startTS = BTDCurrentMachTime();
    }
    NSString *path = [NSURL URLWithString:URLString].path;
    BOOL res = [self p_needSwitchToSubThreadForcelyWithPath:path];
    if (self.enablePerformance && startTS > 0) {
        double costTS = BTDMachTimeToSecs(BTDCurrentMachTime() - startTS) * 1000;
        BDALOG_PROTOCOL_INFO_TAG(@"Jato-iOS", @"check path: %@ allowed switch cost time: %lf", path, costTS);
    }
    
    return res;
}

- (BOOL)p_needSwitchToSubThreadForcelyWithPath:(NSString *)path {
    if (!path || ![path isKindOfClass:[NSString class]]) {
        NSAssert(NO, @"JATNetworkOpt path is not string!!!");
        return NO;
    }
    
    pthread_rwlock_rdlock(&_pathLock);
    BOOL res = [self.allowedPathDict btd_boolValueForKey:path];
    if (!res) {
        for (NSString *searchPath in self.fuzzyAllowedPathArray) {
            if ([path containsString:searchPath]) {
                return res;
            }
        }
    }
    pthread_rwlock_unlock(&_pathLock);
    return res;
}

- (void)execTaskOnSubThread:(void (^)(void))taskBlock {
    if (!taskBlock) {
        return;
    }
    uint64_t startTS = 0;
    if (self.enablePerformance) {
        startTS = BTDCurrentMachTime();
    }
    [self.sendSubThreadQueue addOperationWithBlock:^{
        taskBlock();
        if (self.enablePerformance && startTS > 0) {
            double costTS = BTDMachTimeToSecs(BTDCurrentMachTime() - startTS) * 1000;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.tracker trackerService:JATNetworkOptTaskExecuteWaitCost metric:@{@"cost": @(costTS)}];
         });
    }
    }];
}

#pragma mark - hook method action
- (void)p_hookTTNetworkChriumHTTPRequestBuildJsonMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [TTNetworkManagerChromium btd_swizzleInstanceMethod:@selector(buildJSONHttpTask:params:method:needCommonParams:headerField:requestSerializer:responseSerializer:autoResume:verifyRequest:isCustomizedCookie:callback:callbackWithResponse:dispatch_queue:)
                                                       with:@selector(bdjat_buildJSONHttpTask:params:method:needCommonParams:headerField:requestSerializer:responseSerializer:autoResume:verifyRequest:isCustomizedCookie:callback:callbackWithResponse:dispatch_queue:)];
    });
}

#pragma mark - getter
- (NSMutableDictionary<NSString *,NSNumber *> *)allowedPathDict {
    if (!_allowedPathDict) {
        _allowedPathDict = [NSMutableDictionary dictionary];
    }
    return _allowedPathDict;
}

- (NSMutableArray *)fuzzyAllowedPathArray {
    if (!_fuzzyAllowedPathArray) {
        _fuzzyAllowedPathArray = [NSMutableArray array];
    }
    return _fuzzyAllowedPathArray;
}

- (JATNetowrkOptTracker *)tracker {
    if (!_tracker) {
        _tracker = [[JATNetowrkOptTracker alloc] init];
    }
    return _tracker;
}

@end
