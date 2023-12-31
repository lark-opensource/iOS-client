//
//  HMDConfigFetcher.m
//  Heimdallr
//
//  Created by Nickyo on 2023/5/17.
//

#import "HMDConfigFetcher.h"
#import "HMDGCD.h"
#import "HMDMacro.h"
#import "HMDNetworkManager.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "NSDictionary+HMDSafe.h"
#import <TTReachability/TTReachability.h>
#import "HMDALogProtocol.h"
#import "HMDWeakProxy.h"

@implementation HMDConfigFetchRequest

@end

@interface HMDConfigFetcher ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) BOOL needFetchRequest;
/// 正在获取的请求数
@property (nonatomic, assign) NSInteger isFetchingRequestCount;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *retryMap;

@property (nonatomic, assign) BOOL successFetchConfig;

@property (nonatomic, weak) NSTimer *updateTimer;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *updateIntervalMap;
@property (nonatomic, assign) NSTimeInterval currentTimerInterval;

@end

@implementation HMDConfigFetcher

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.updateTimer isValid]) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.queue = dispatch_queue_create("com.heimdallr.HMDConfigManager", DISPATCH_QUEUE_SERIAL);
        self.successFetchConfig = NO;
        self.retryMap = [NSMutableDictionary dictionaryWithCapacity:2];
        self.updateIntervalMap = [NSMutableDictionary dictionaryWithCapacity:5];
        self.currentTimerInterval = -1;
    }
    return self;
}

- (void)asyncFetchRemoteConfig:(BOOL)force {
    @weakify(self);
    hmd_safe_dispatch_async(self.queue, ^{
        @strongify(self);
        [self _fetchRemoteConfig:force];
    });
}

- (void)_fetchRemoteConfig:(BOOL)force {
    if ([[HMDInjectedInfo defaultInfo].disableNetworkRequest boolValue]) {
        return;
    }
    if (!force && self.dataSource && ![self.dataSource checkConfigIsOutOfDate]) {
        return;
    }
    
    if (self.isFetchingRequestCount > 0) {
        [self setNeedFetchRequest];
        return;
    }
    
    NSArray<NSString *> *appIDList = [self.dataSource fetchRequestAppIDList];
    if (HMDIsEmptyArray(appIDList)) {
        return;
    }
    for (NSString *appID in appIDList) {
        if (HMDIsEmptyString(appID)) {
            continue;
        }
        HMDConfigFetchRequest *fetchRequest = [self.dataSource fetchRequestForAppID:appID atIndex:[self _retryIndexForAppID:appID]];
        if (fetchRequest == nil) {
            continue;
        }
        HMDNetworkReqModel *request = fetchRequest.request;
        id penetrateParams = fetchRequest.penetrateParams;
        self.isFetchingRequestCount++;
        
        @weakify(self);
        [[HMDNetworkManager sharedInstance] asyncRequestWithModel:request callback:^(NSError *error, id jsonObj) {
            @strongify(self);
            hmd_safe_dispatch_async(self.queue, ^{
                @strongify(self);
                self.isFetchingRequestCount--;
                if (!error && [jsonObj isKindOfClass:[NSDictionary class]]) {
                    @try {
                        BOOL success = [self.delegate configFetcher:self finishRequestSuccess:jsonObj penetrateParams:penetrateParams forAppID:appID];
                        if (success) {
                            self.successFetchConfig = YES;
                            [self _resetRetryIndexForAppID:appID];
                        }
                    } @catch (NSException *exception) {
                        [self _retryFetchRemoteConfig:force forAppID:appID];
                    }
                } else {
                    [self _retryFetchRemoteConfig:force forAppID:appID];
                }
            });
        }];
    }
}

- (void)_retryFetchRemoteConfig:(BOOL)force forAppID:(NSString *)appID {
    self.successFetchConfig = NO;
    NSUInteger retryIndex = [self _increaseRetryIndexForAppID:appID];
    NSUInteger maxRetryCount = [self.dataSource maxRetryCountForAppID:appID];
    // 重试多次仍未成功拉取配置，则监听网络状态，待网络连通后再进行请求
    if (retryIndex >= maxRetryCount) {
        [self _resetRetryIndexForAppID:appID];
        @weakify(self);
        hmd_safe_dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(networkChanged:)
                                                         name:TTReachabilityChangedNotification
                                                       object:nil];
        });
        return;
    }
    
    [self asyncFetchRemoteConfig:force];
}

- (void)networkChanged:(NSNotification *)notification {
    if (self.successFetchConfig) {
        return;
    }
    if ([TTReachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
        return;
    }
    // 尝试重新拉取配置
    [self asyncFetchRemoteConfig:YES];
    
    @weakify(self);
    hmd_safe_dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TTReachabilityChangedNotification object:nil];
    });
    
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"[networkChanged:]");
    }
}

#pragma mark - Delay Fetch Request

- (void)setNeedFetchRequest {
    if (self.needFetchRequest) {
        return;
    }
    self.needFetchRequest = YES;
    @weakify(self);
    hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), self.queue, ^{
        @strongify(self);
        if (self.needFetchRequest) {
            self.needFetchRequest = NO;
            [self _fetchRemoteConfig:NO];
        }
    });
}

#pragma mark - Retry

- (NSUInteger)_retryIndexForAppID:(NSString *)appID {
    return [self.retryMap hmd_unsignedIntegerForKey:appID];
}

- (NSUInteger)_increaseRetryIndexForAppID:(NSString *)appID {
    NSUInteger index = [self _retryIndexForAppID:appID] + 1;
    [self.retryMap hmd_setObject:[NSNumber numberWithUnsignedInteger:index] forKey:appID];
    return index;
}

- (NSUInteger)_resetRetryIndexForAppID:(NSString *)appID {
    [self.retryMap hmd_setObject:[NSNumber numberWithUnsignedInteger:0] forKey:appID];
    return 0;
}

#pragma mark - Update Timer

- (void)setAutoUpdateInterval:(NSTimeInterval)timeInterval forAppID:(NSString *)appID {
    if (timeInterval < 0 || HMDIsEmptyString(appID)) {
        return;
    }
    
    @weakify(self);
    hmd_safe_dispatch_async(self.queue, ^{
        @strongify(self);
        [self _setUpdateInterval:timeInterval forAppID:appID];
        NSTimeInterval minInterval = [self _minimumUpdateInterval:timeInterval];
        if (minInterval == self.currentTimerInterval) {
            return;
        }
        [self _setupUpdateTimer:minInterval];
    });
}

- (void)_setupUpdateTimer:(NSTimeInterval)timeInterval {
    if (timeInterval <= 0) {
        return;
    }
    NSTimer *preTimer = self.updateTimer;
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval
                                             target:[HMDWeakProxy proxyWithTarget:self]
                                           selector:@selector(autoUpdateConfig:)
                                           userInfo:nil
                                            repeats:YES];
    self.updateTimer = timer;
    hmd_safe_dispatch_async(dispatch_get_main_queue(), ^{
        [preTimer invalidate];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

- (void)autoUpdateConfig:(NSTimer *)sender {
    [self asyncFetchRemoteConfig:NO];
}

- (void)_setUpdateInterval:(NSTimeInterval)timeInterval forAppID:(NSString *)appID {
    [self.updateIntervalMap hmd_setObject:[NSNumber numberWithDouble:timeInterval] forKey:appID];
}

- (NSTimeInterval)_minimumUpdateInterval:(NSTimeInterval)currentInterval {
    NSTimeInterval minInterval = currentInterval;
    for (NSNumber *interval in self.updateIntervalMap.allValues) {
        if (interval.doubleValue < minInterval) {
            minInterval = interval.doubleValue;
        }
    }
    return minInterval;
}

@end
