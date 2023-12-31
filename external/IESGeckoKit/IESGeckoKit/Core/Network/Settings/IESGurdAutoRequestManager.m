//
//  IESGurdAutoRequestManager.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/23.
//

#import "IESGurdAutoRequestManager.h"

#import "IESGeckoKit.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoAPI.h"
#import "IESGurdKitUtil.h"
#import "IESGurdAutoRequest.h"
#import "IESGurdResourceManager+MultiAccessKey.h"
#import "IESGurdPollingManager.h"

@interface IESGurdAutoRequestManager ()

@property (nonatomic, copy) NSArray<IESGurdSettingsRequestInfo *> *requestInfosArray;

@property (nonatomic, strong) NSTimer *autoRequestTimer;

@end

@implementation IESGurdAutoRequestManager

+ (instancetype)sharedManager
{
    static IESGurdAutoRequestManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleRequestMeta:(IESGurdSettingsRequestMeta *)requestMeta
{
    [self handleRequestConfig:requestMeta];
    [self registerAccessKeysArray:requestMeta.accessKeysArray];
    [self handleRequestInfosArray:requestMeta.requestInfosArray];
    [self handlePollingInfosDictionary:requestMeta.pollingInfosDictionary];
}

#pragma mark - Private

- (void)handleRequestConfig:(IESGurdSettingsRequestMeta *)requestMeta
{
    if (IESGurdKit.enable) {
        IESGurdKit.enable = requestMeta.isRequestEnabled;
    }
    if (IESGurdKit.isPollingEnabled) {
        IESGurdKit.pollingEnabled = requestMeta.isPollingEnabled;
    }
    if (IESGurdKit.isThrottleEnabled) {
        IESGurdKit.throttleEnabled = requestMeta.isFrequenceControlEnable;
    }
}

- (void)registerAccessKeysArray:(NSArray<NSString *> *)accessKeysArray
{
    [accessKeysArray enumerateObjectsUsingBlock:^(NSString *accessKey, NSUInteger idx, BOOL *stop) {
        [IESGurdKit registerAccessKey:accessKey];
    }];
}

- (void)handleRequestInfosArray:(NSArray<IESGurdSettingsRequestInfo *> *)requestInfosArray
{
    if (requestInfosArray.count == 0) {
        return;
    }
    if (self.requestInfosArray) {
        [self invalidateTimer];
        // 如果不是冷启第一次更新，则把过期的请求丢弃
        NSInteger currentDelay = [[NSDate date] timeIntervalSince1970] - [IESGurdKit setupTimestamp];
        NSMutableArray<IESGurdSettingsRequestInfo *> *filteredArray = [NSMutableArray array];
        [requestInfosArray enumerateObjectsUsingBlock:^(IESGurdSettingsRequestInfo *requestInfo, NSUInteger idx, BOOL *stop) {
            if (requestInfo.delay > currentDelay) {
                [filteredArray addObject:requestInfo];
            }
        }];
        requestInfosArray = [filteredArray copy];
    }
    self.requestInfosArray = requestInfosArray;
    
    [self registerNotificationOnce];
    
    [self handleAutoRequest];
}

- (void)handlePollingInfosDictionary:(NSDictionary<NSString *, IESGurdSettingsPollingInfo *> *)pollingInfosDictionary
{
    if (pollingInfosDictionary.count == 0) {
        return;
    }
    NSArray<NSNumber *> *priorities = @[ @(IESGurdPollingPriorityLevel1),
                                         @(IESGurdPollingPriorityLevel2),
                                         @(IESGurdPollingPriorityLevel3) ];
    NSMutableDictionary<NSNumber *, NSNumber *> *pollingIntervalsDictionary = [NSMutableDictionary dictionary];
    [priorities enumerateObjectsUsingBlock:^(NSNumber *priorityKey, NSUInteger idx, BOOL * _Nonnull stop) {
        IESGurdPollingPriority priority = priorityKey.integerValue;
        
        NSString *priorityString = IESGurdPollingPriorityString(priority);
        IESGurdSettingsPollingInfo *pollingInfo = pollingInfosDictionary[priorityString];
        if (!pollingInfo) {
            return;
        }
        
        pollingIntervalsDictionary[priorityKey] = @(pollingInfo.interval);
        
        [pollingInfo.paramsInfosArray enumerateObjectsUsingBlock:^(NSString *accessKey, NSUInteger idx, BOOL *stop) {
            IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
            params.accessKey = accessKey;
            params.groupName = priorityString;
            params.pollingPriority = priority;
            [IESGurdPollingManager addPollingConfigWithParams:params];
        }];
    }];
    [IESGurdPollingManager updatePollingIntervals:[pollingIntervalsDictionary copy]];
}

- (void)registerNotificationOnce
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(invalidateTimer)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    });
}

- (void)appWillEnterForeground
{
    if (IESGurdKit.enable) {
        [self setupTimerIfNeeded];
    }
}

static id kGurdEnableObserver = nil;
- (void)handleAutoRequest
{
    if (IESGurdKit.enable) {
        [self autoRequestIfNeeded];
        return;
    }
    
    kGurdEnableObserver = [[NSNotificationCenter defaultCenter] addObserverForName:IESGurdKitDidSetEnableGurdNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [[NSNotificationCenter defaultCenter] removeObserver:kGurdEnableObserver];
        kGurdEnableObserver = nil;
        
        [self autoRequestIfNeeded];
    }];
}

- (void)autoRequestIfNeeded
{
    NSInteger currentDelay = [[NSDate date] timeIntervalSince1970] - [IESGurdKit setupTimestamp];
    __block NSMutableArray<IESGurdSettingsRequestInfo *> *requestInfosArray = nil;
    __block IESGurdAutoRequest *autoRequest = nil;
    
    [self.requestInfosArray enumerateObjectsUsingBlock:^(IESGurdSettingsRequestInfo *requestInfo, NSUInteger idx, BOOL *stop) {
        if (requestInfo.delay > currentDelay) {
            return;
        }
        
        if (!requestInfosArray) {
            requestInfosArray = [self.requestInfosArray mutableCopy];
        }
        [requestInfosArray removeObject:requestInfo];
        
        if (!autoRequest) {
            autoRequest = [[IESGurdAutoRequest alloc] init];
        } 
        [autoRequest updateConfigWithParamsInfosArray:requestInfo.paramsInfosArray];
    }];
    
    if (requestInfosArray != nil) {
        self.requestInfosArray = [requestInfosArray copy];
    }
    if (autoRequest != nil) {
        [IESGurdResourceManager fetchConfigWithURLString:[IESGurdAPI packagesInfo]
                                  multiAccessKeysRequest:autoRequest];
    }
    
    if (self.requestInfosArray.count > 0) {
        [self setupTimerIfNeeded];
    }
}

#pragma mark - Private - Timer

- (void)setupTimerIfNeeded
{
    @synchronized (self) {
        if (self.autoRequestTimer) {
            return;
        }
        IESGurdSettingsRequestInfo *requestInfo = self.requestInfosArray.firstObject;
        if (!requestInfo) {
            return;
        }
        NSInteger interval = MAX([IESGurdKit setupTimestamp] + requestInfo.delay - [[NSDate date] timeIntervalSince1970], 0);
        self.autoRequestTimer = [NSTimer timerWithTimeInterval:interval
                                                        target:self
                                                      selector:@selector(autoRequestTimerFired)
                                                      userInfo:nil
                                                       repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.autoRequestTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)invalidateTimer
{
    @synchronized (self) {
        if (self.autoRequestTimer) {
            [self.autoRequestTimer invalidate];
            self.autoRequestTimer = nil;
        }
    }
}

- (void)autoRequestTimerFired
{
    @synchronized (self) {
        self.autoRequestTimer = nil;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self autoRequestIfNeeded];
    });
}

@end
