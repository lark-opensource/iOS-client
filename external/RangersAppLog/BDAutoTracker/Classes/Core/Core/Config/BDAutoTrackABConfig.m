//
//  BDAutoTrackABConfig.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//

#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackTimer.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackParamters.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackDeviceHelper.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"

static NSString *const kBDAutoTrackExposedVids          = @"kBDAutoTrackExposedVids";      // Array
static NSString *const kBDAutoTrackALinkABVersions      = @"kBDAutoTrackALinkABVersions";  // Stirng
static NSString *const kBDAutoTrackABTestRawDataCache   = @"kBDAutoTrackABTestRawDataCache";  // Dict


static NSString *const kBDAutoTrackABTestVid    = @"vid";
static NSString *const kBDAutoTrackABTestValue  = @"val";

@interface BDAutoTrackABConfig () {
    
    dispatch_queue_t abtestingQueue;
    void *onABTestingQueueTag;
    
    BOOL started;
    
    NSArray *externalVids;
    
    NSArray *alinkVids;
    
    NSMutableSet *exposedVids;
    
    NSString *current_ssid;
    
    NSInteger fetchIndex;
}

/// abtest接口下发的原始数据
@property (nonatomic, copy) NSDictionary *currentRawData;
@property (nonatomic, strong) BDAutoTrackDefaults *defaults;

@property (nonatomic, assign) NSTimeInterval manualPullInterval;
@property (nonatomic, assign) NSTimeInterval lastManualPullTime;

@property (nonatomic, copy) NSString *moduleId;

@end

@implementation BDAutoTrackABConfig

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameABTest;
        
        NSString *name = [NSString stringWithFormat:@"volcengine.tracker.abtest.%@",appID];
        abtestingQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
        onABTestingQueueTag = &onABTestingQueueTag;
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(abtestingQueue, onABTestingQueueTag, nonNullUnusedPointer, NULL);
        
        
        self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteConfigDidUpdate:) name:BDAutoTrackRemoteConfigDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceRegisterDidUpdate:) name:BDAutoTrackNotificationRegisterSuccess object:nil];
        
        self->externalVids = nil;
        self->alinkVids = nil;
        self->exposedVids = [NSMutableSet set];
        
        self.moduleId = [NSString stringWithFormat:@"ABTesting-%@",appID];
        
        self->fetchIndex = 0;
        
        self.manualPullInterval = 10.0f;
    }
    
    return self;
}

- (BOOL)testerEnabled
{
    return self.localTesterEnabled && self.remoteTesterEnabled;
}

- (NSString *)moduleName
{
    return @"ABTesting";
}

- (void)start
{
    [self sync:^{
        NSArray *exposedVids = [self.defaults arrayValueForKey:kBDAutoTrackExposedVids] ?: @[];
        [self->exposedVids addObjectsFromArray:exposedVids];
        NSString *alinkABVersions = [self.defaults stringValueForKey:kBDAutoTrackALinkABVersions];
        if (alinkABVersions.length > 0) {
            self->alinkVids = [alinkABVersions componentsSeparatedByString:@","];
        }
        self.currentRawData = [self.defaults dictionaryValueForKey:kBDAutoTrackABTestRawDataCache] ?: @{} ;
    }];
    [self resume];
}

- (void)resume
{
    [self scheduleIntervalFetch];
    [self syncEventParameter];
}

- (void)suspend
{
    [self unscheduleIntervalFetch];
    [self syncEventParameter];
}

- (void)scheduleIntervalFetch
{
    __weak typeof(self) weak_self = self;
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:self.moduleId];
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:self.moduleId
                                                         timeInterval:self.fetchInterval
                                                                queue:nil
                                                              repeats:YES
                                                               action:^{
        typeof(weak_self) strong_self = weak_self;
        if (!strong_self) {
            return;
        }
        RL_DEBUG(strong_self.tracker, [strong_self moduleName], @"Trigger fetch because the scheduled task");
        [strong_self fetchABTesting:10 manually:NO completion:^(BOOL success, NSError * _Nullable error) {
        }];
    }];
}

- (void)unscheduleIntervalFetch
{
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:self.moduleId];
}

#pragma mark property
- (NSString *)allExposedABVersions
{
    __block NSString *vids;
    [self sync:^{
        NSMutableSet *versions = [NSMutableSet new];
        //Tester
        if (self.testerEnabled) {
            [versions addObjectsFromArray:self->exposedVids.allObjects];
        }
        //ALink
        [versions addObjectsFromArray:[self->alinkVids copy]];
        //Extenrnal
        [versions addObjectsFromArray:[self->externalVids copy]];
        vids = [versions.allObjects componentsJoinedByString:@","];
    }];
    return vids;
}

- (void)clearAll
{
    [self async:^{
        self->alinkVids = nil;
        self->externalVids = nil;
        [self updateABConfigWithRawData:nil source:BDAutoTrackNotificationDataSourceLocalCache postNotification:NO];
    }];
}

- (void)syncEventParameter
{
    [[BDAutoTrack trackWithAppID:self.appID].eventGenerator addEventParameter:@{kBDAutoTrackABSDKVersion:[self allExposedABVersions] ?: @""}];
}


#pragma mark - Tester

- (NSString *)testerABVersions
{
    if (!self.testerEnabled) {
        return nil;
    }
    __block NSString *version;
    [self sync:^{
        version = [self->exposedVids.allObjects componentsJoinedByString:@","];
    }];
    return version;
}


- (void)initTesterABConfig
{
    if (!self.testerEnabled) {
        return;
    }
    NSArray *exposedVids = [self.defaults arrayValueForKey:kBDAutoTrackExposedVids] ?: @[];
    [self->exposedVids addObjectsFromArray:exposedVids];
    NSString *alinkABVersions = [self.defaults stringValueForKey:kBDAutoTrackALinkABVersions];
    if (alinkABVersions.length > 0) {
        self->alinkVids = [alinkABVersions componentsSeparatedByString:@","];
    }
    self.currentRawData = [self.defaults dictionaryValueForKey:kBDAutoTrackABTestRawDataCache] ?: @{} ;
    
    if (self.currentRawData.count > 0) {
        [self postABTestNotification:BDAutoTrackNotificationDataSourceLocalCache];
    }
}


- (void)updateABConfigWithRawData:(NSDictionary<NSString *, NSDictionary *> *)rawData
                           source:(NSString *)source
                 postNotification:(BOOL)postNoti {
    [self async:^{
        NSUInteger oldCount = self->exposedVids.count;
        self.currentRawData = rawData;

        NSMutableSet<NSString *> *allVids = [NSMutableSet new];
        [rawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            if (vid) {
                [allVids addObject:vid];
            }
        }];

        NSMutableSet<NSString *> *exposedVids = [NSMutableSet new];
        [self->exposedVids enumerateObjectsUsingBlock:^(NSString *vid, BOOL *stop) {
            if ([allVids containsObject:vid]) {
                [exposedVids addObject:vid];
            }
        }];

        [self.defaults setValue:rawData forKey:kBDAutoTrackABTestRawDataCache];
        [self.defaults setValue:exposedVids.allObjects forKey:kBDAutoTrackExposedVids];
        [self.defaults saveDataToFile];
        self->exposedVids = exposedVids;
        
        if (postNoti) {
            [self postABTestNotification:source];
            NSUInteger updateCount = exposedVids.count;
            if (oldCount != updateCount) {
                [self postChangedNotification];
            }
        }
        [self syncEventParameter];
    }];
}

/// 通知。userInfo里提供服务器返回的原始数据。
- (void)postABTestNotification:(NSString *)source {
    if (!self.testerEnabled) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *userInfo = @{kBDAutoTrackNotificationAppID: self.appID,
                                   kBDAutoTrackNotificationData:bd_trueDeepCopyOfDictionary(self.currentRawData),
                                   kBDAutoTrackNotificationDataSource:source?:@""
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationABTestSuccess
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

/// Impl of `ABTestConfigValueForKey: defaultValue:`
- (id)getConfig:(NSString *)key defaultValue:(id)defaultValue {
    if (!self.testerEnabled) {
        RL_DEBUG(self.tracker, [self moduleName], @"Trigger experiment API %@ -> %@ [source: default] (Function disable)", key, defaultValue);
        return defaultValue;
    }
    __block id value = nil;
    __block BOOL cacheExists = NO;
    [self sync:^{
        NSDictionary *config = [self.currentRawData vetyped_dictionaryForKey:key];
        if ([config isKindOfClass:[NSDictionary class]]) {
            config = bd_trueDeepCopyOfDictionary(config);
            
            cacheExists = YES;
            value = [config objectForKey:kBDAutoTrackABTestValue] ?: defaultValue;
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            
            if (vid.length > 0) {
                // 触发`feature变体使用事件`, 立即上报
                BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
                NSDictionary *params = @{
                    @"ab_sdk_version": vid
                };
                // 用户访问的事件还没有曝光过，将它曝光
                if (![self->exposedVids containsObject:vid]) {
                    [self->exposedVids addObject:vid];    // 添加到曝光
                    [self syncEventParameter];
                    // 将 self.exposedVids 存入缓存
                    [self.defaults setValue:self->exposedVids.allObjects forKey:kBDAutoTrackExposedVids];
                    [self.defaults saveDataToFile];
                    
                    // 发送通知
                    [self postChangedNotification];
                }
                [track eventV3:@"abtest_exposure" params:params];
            }
        }
    }];
    if (value) {
        RL_DEBUG(self.tracker, [self moduleName], @"Trigger experiment API %@ -> %@ [source: remote]", key, value);
        return value;
    }
    if (cacheExists) {
        RL_DEBUG(self.tracker, [self moduleName], @"Trigger experiment API %@ -> %@ [source: default] (%@)", key, defaultValue, @"The experimental key does not exist in the cache.");
    } else {
        RL_DEBUG(self.tracker, [self moduleName], @"Trigger experiment API %@ -> %@ [source: default] (%@)", key, defaultValue, @"There is currently no experimental data returned by the server.");
    }
    
    return defaultValue;
}

/// 发送 BDAutoTrackNotificationABTestVidsChanged 通知
- (void)postChangedNotification {
    if (!self.testerEnabled) {
        return;
    }
    NSString *vids = [self->exposedVids.allObjects componentsJoinedByString:@","];
    NSString *appID = [self.appID mutableCopy];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:appID forKey:kBDAutoTrackNotificationAppID];
    [userInfo setValue:vids forKey:kBDAutoTrackNotificationABTestVids];
    
    BDAutoTrackLocalConfigService *settings = self.tracker.localConfig;
    NSString *external = [settings.externalVids.allObjects componentsJoinedByString:@","];
    [userInfo setValue:external forKey:kBDAutoTrackNotificationABTestExternalVids];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationABTestVidsChanged
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (NSDictionary *)allABTestConfigs {
    NSMutableDictionary *configs = [NSMutableDictionary new];

    [self sync:^{
        NSDictionary *currentRawData = bd_trueDeepCopyOfDictionary(self.currentRawData);
        [currentRawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            id value = [config objectForKey:kBDAutoTrackABTestValue];
            [configs setValue:value forKey:key];
        }];
    }];

    return configs;
}

- (NSDictionary *)allABTestConfigs2 {
    return bd_trueDeepCopyOfDictionary(self.currentRawData);
}

- (NSString *)allABVersions {
    NSMutableSet<NSString *> *allVids = [NSMutableSet new];

    [self sync:^{
        [self.currentRawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            if (vid) {
                [allVids addObject:vid];
            }
        }];
    }];

    if (allVids.count < 1) {
        return nil;
    }

    return [allVids.allObjects componentsJoinedByString:@","];
}



#pragma mark - ALink
- (void)setAlinkABVersions:(NSString *)alinkABVersions
{
    NSString *vids = [alinkABVersions copy];
    [self async:^{
        if (vids.length == 0 ) {
            self->alinkVids = nil;
        } else {
            self->alinkVids = [vids componentsSeparatedByString:@","];
        }
        [self syncEventParameter];
        [self.defaults setValue:vids forKey:kBDAutoTrackALinkABVersions];
        [self.defaults saveDataToFile];
        
    }];
}

- (NSString *)alinkABVersions
{
    __block NSString *version;
    [self sync:^{
        version = [self->alinkVids componentsJoinedByString:@","];
    }];
    return version;
}

#pragma mark - External vids

- (void)setExternalVersions:(NSString *)externalVersions
{
    NSString *vids = [externalVersions copy];
    [self async:^{
        if (vids.length == 0 ) {
            self->externalVids = nil;
        } else {
            self->externalVids = [vids componentsSeparatedByString:@","];
        }
        [self syncEventParameter];
    }];
}

- (NSString *)externalVersions
{
    __block NSString *version;
    [self sync:^{
        version = [self->externalVids componentsJoinedByString:@","];
    }];
    return version;
}



#pragma mark - thread control

- (void)async:(dispatch_block_t)block
{
    if (dispatch_get_specific(onABTestingQueueTag))
        block();
    else
        dispatch_async(abtestingQueue, block);
}

- (void)sync:(dispatch_block_t)block
{
    if (dispatch_get_specific(onABTestingQueueTag))
        block();
    else
        dispatch_sync(abtestingQueue, block);
}


#pragma mark - Request

- (void)onRemoteConfigDidUpdate:(NSNotification *)noti
{
    NSString *appId = [noti.userInfo objectForKey:kBDAutoTrackNotificationAppID];
    if ([self.tracker.appID isEqualToString:appId]) {
        BDAutoTrackRemoteSettingService *settings = (BDAutoTrackRemoteSettingService *)bd_standardServices(BDAutoTrackServiceNameRemote,self.appID);
        if (self.remoteTesterEnabled != settings.abTestEnabled) {
            self.remoteTesterEnabled = settings.abTestEnabled;
            if (![self testerEnabled]) {
                [self suspend];
            } else {
                [self resume];
            }
        }
        if (self.fetchInterval != settings.abFetchInterval) {
            self.fetchInterval = settings.abFetchInterval;
            if ([self testerEnabled]) {
                [self scheduleIntervalFetch];
            }
        }
//        RL_DEBUG(self.tracker, [self moduleName], @"Trigger fetch because remote config did update");
//        [self fetchABTesting:10 manually:NO completion:^(BOOL success, NSError * _Nullable error) {
//        }];
    }
}

- (void)onDeviceRegisterDidUpdate:(NSNotification *)noti
{
    NSString *appId = [noti.userInfo objectForKey:kBDAutoTrackNotificationAppID];
    if ([self.tracker.appID isEqualToString:appId]
        && [BDAutoTrackNotificationDataSourceServer isEqualToString:([noti.userInfo objectForKey:kBDAutoTrackNotificationDataSource] ?: @"")]) {
        RL_DEBUG(self.tracker, [self moduleName], @"Trigger fetch because device register did update");
        [self fetchABTesting:10 manually:NO completion:^(BOOL success, NSError * _Nullable error) {
        }];
    }
}

- (void)fetchABTestingManually:(NSTimeInterval)timeout
            completion:(void (^)(BOOL success, NSError * _Nullable error))completionHandler
{
    RL_DEBUG(self.tracker, [self moduleName], @"Trigger fetch because manually call the API");
    [self fetchABTesting:timeout manually:YES completion:completionHandler];
    
}

- (NSError *)internalErrorWithMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:@"VETrackerTesterError" code:0 userInfo:@{
        NSLocalizedDescriptionKey:message ?:@""
    }];
    return error;
}


- (void)fetchABTesting:(NSTimeInterval)timeout
              manually:(BOOL)manually
            completion:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;
            
{
    NSUInteger currentIndex = (++fetchIndex);
    BDAutoTrackLocalConfigService *settings = self.tracker.localConfig;
    NSDictionary *context = @{
        @"index":@(currentIndex),
        @"user_unique_id":settings.syncUserUniqueID ?: @""
    };
    
    RL_INFO(self.tracker, [self moduleName], @"[%d] fetch API call for UUID:%@", currentIndex, settings.syncUserUniqueID);
    __block NSError *error;
    if (![self testerEnabled]) {
        error = [self internalErrorWithMessage:@"Function disabled"];
        RL_WARN(self.tracker, [self moduleName], @"[%d] fetch terminate due to %@",currentIndex, error.localizedDescription);
        if (completionHandler) {
            completionHandler(NO, error);
        }
        return;
    }
    
    BDAutoTrackNetworkRequestConfig *config = [BDAutoTrackNetworkRequestConfig new];
    if (timeout > 0) {
        config.timeout = timeout;
    }
    config.retry = 2;
    
    
   
    [self async:^{
        
        if (manually) {
            long long now = CACurrentMediaTime();
            if (now - self.lastManualPullTime < self.manualPullInterval) {
                error = [self internalErrorWithMessage:@"Fetch manually too often"];
                RL_WARN(self.tracker, [self moduleName], @"[%d] fetch terminate due to %@",currentIndex, error.localizedDescription);
                if (completionHandler) {
                    completionHandler(NO, error);
                }
                return;
            }
            self.lastManualPullTime = now;
        }
        
        void (^handler)(BOOL success, NSError * _Nullable error) = [completionHandler copy];
        __weak typeof(self) weak_self = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            typeof(weak_self) strong_self = weak_self;
            if (!strong_self) {
                return;
            }
            [strong_self _syncRequestABTesting:config
                                    context:context
                                    completion:^(BOOL success, NSError * _Nullable error) {
                
                if (!success) {
                    RL_ERROR(self.tracker, [self moduleName], @"[%d] fetch failure due to %@", currentIndex, error.localizedDescription);
                } else {
                    RL_INFO(self.tracker, [self moduleName], @"[%d] fetch successfully", currentIndex);
                }
                if (handler) {
                    handler(success, error);
                }
            }];
            
        });
    }];
    
}
                

- (void)_syncRequestABTesting:(BDAutoTrackNetworkRequestConfig *)config
                      context:(id)context
                   completion:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;
{
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *parameter = [NSMutableDictionary new];
    if (tracker.networkManager.encryptor.encryption) {
        [tracker.networkManager.encryptor addIV:parameter];
    }
    
    //get parameters
    __block BOOL success = NO;
    __block NSError *networkError;
    [tracker.networkManager sync:BDAutoTrackRequestURLABTest method:@"POST" header:@{} parameter:parameter config:config completion:^BOOL(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *idvalue = [context objectForKey:@"user_unique_id"];
        NSUInteger index = [[context objectForKey:@"index"] integerValue];
        
        networkError = error;
        NSDictionary *dict;
        if (self.tracker.networkManager.encryptor.encryption) {
            dict = [self.tracker.networkManager.encryptor decryptResponse:data];
        }
        if (dict == nil) {
            dict = applog_JSONDictionanryForData(data);
        }
        
        RL_DEBUG(tracker, [self moduleName], @"[%d] fetch response data: %@", index, dict);
        if (dict && bd_isResponseMessageSuccess(dict)) {
            
            BDAutoTrackLocalConfigService *settings = self.tracker.localConfig;
            if ([idvalue isEqualToString:(settings.syncUserUniqueID ?: @"")]) {
                NSDictionary *rawData = [dict vetyped_dictionaryForKey:@"data"];
                [self updateABConfigWithRawData:rawData source:BDAutoTrackNotificationDataSourceServer postNotification:YES];
                
            } else {
                RL_WARN(tracker, [self moduleName], @"[%d] fetch Ignore the change because the ID does not match the current one", index);
            }
            success = YES;
        }
        return success;
    }];
    if (completionHandler) {
        completionHandler(success, networkError);
    }
    
}



@end
