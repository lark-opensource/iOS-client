//
//  HMDConfigManager.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import "HMDConfigManager.h"
#include "pthread_extended.h"
#import "HeimdallrUtilities.h"
#import "HMDInjectedInfo+Upload.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "HMDUserDefaults.h"
#import "HMDHeimdallrConfig+Legacy.h"
#include <stdatomic.h>
#import "HMDALogProtocol.h"
#import "HMDMacro.h"
#import "HMDConfigHelper.h"
#if RANGERSAPM
#import "RangersAPMConfigFetchResource.h"
#import "RangersAPMConfigDataProcessor.h"
#import "RangersAPMConfigHostProvider.h"
#else
#import "HMDConfigFetchResource.h"
#import "HMDConfigDataProcessor.h"
#import "HMDConfigHostProvider.h"
#endif
#import "HMDConfigStore.h"
#import "HMDConfigFetcher.h"

NSNotificationName const HMDConfigManagerDidUpdateNotification = @"HMDConfigManagerDidUpdateConfig";
NSString * const HMDConfigManagerDidUpdateAppIDKey = @"HMDConfigManagerDidUpdateAppIDKey";
NSString * const HMDConfigManagerDidUpdateConfigKey = @"HMDConfigManagerDidUpdateConfigKey";
NSString * const HMDConfigFilePathSuffix = @"_v3_config.json";

@interface HMDConfigManager () <HMDConfigDataProcessDelegate, HMDConfigDataProcessDataSource, HMDConfigHostProviderDataSource>

@property (nonatomic, strong) HMDConfigStore *store;
@property (nonatomic, strong) id<HMDConfigFetchResource> fetchResource;
@property (nonatomic, strong) HMDConfigFetcher *fetcher;
@property (nonatomic, strong) id<HMDConfigDataProcess> dataProcessor;
@property (nonatomic, strong) id<HMDConfigHostProvider> provider;

@end

@implementation HMDConfigManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HMDConfigManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[HMDConfigManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _store = [[HMDConfigStore alloc] init];
#if RANGERSAPM
        _dataProcessor = [[RangersAPMConfigDataProcessor alloc] init];
        _provider = [[RangersAPMConfigHostProvider alloc] init];
        _fetchResource = [[RangersAPMConfigFetchResource alloc] initWithStore:_store dataProcessor:_dataProcessor hostProvider:_provider];
#else
        _dataProcessor = [[HMDConfigDataProcessor alloc] init];
        _provider = [[HMDConfigHostProvider alloc] init];
        _fetchResource = [[HMDConfigFetchResource alloc] initWithStore:_store dataProcessor:_dataProcessor hostProvider:_provider];
#endif
        _dataProcessor.delegate = self;
        _dataProcessor.dataSource = self;
        _provider.dataSource = self;
        _fetcher = [[HMDConfigFetcher alloc] init];
        _fetcher.delegate = _fetchResource;
        _fetcher.dataSource = _fetchResource;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupAsyncWithDefaultInfo:(BOOL)defaultInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (defaultInfo) {
            HMDInjectedInfo *info = [HMDInjectedInfo defaultInfo];
            [self.store setAppID:info.appID];
            [self addProvider:info forAppID:info.appID];
        } else {
            [self startFetchSettings:NO];
        }
    });
}

- (void)addProvider:(id<HMDNetworkProvider>)provider forAppID:(NSString *)appID {
    BOOL success = [self.store addProvider:provider forAppID:appID];
    if (!success) {
        return;
    }
    
    BOOL isHost = [self.store isHostAppID:appID];
    if (isHost) {
        [self startFetchSettings:YES];
    } else {
        [self _maybeFetchSDKRemoteConfig:appID];
    }
}

- (void)removeProvider:(void *)providerPtr forAppID:(NSString *)appID {
    [self.store removeProvider:providerPtr forAppID:appID];
}

- (void)startFetchSettings:(BOOL)force {
    static atomic_flag once = ATOMIC_FLAG_INIT;
    if (!atomic_flag_test_and_set_explicit(&once, memory_order_relaxed)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkSchedule)
                                                     name:kHMDNetworkScheduleNotification
                                                   object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _asyncFetchRemoteConfigImmediately:force];
            if (hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"[startFetchSettings:] force : %d", force);
            }
        });
    }
}

- (void)_maybeFetchSDKRemoteConfig:(NSString *)sdkAid {
    if (!self.store.firstFetchingCompleted) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"[_maybeFetchSDKRemoteConfig:] SDK aid : %@ before module setting up", sdkAid);
        }
        return;
    }
    NSString *sdkConfigHeaderKey = [HMDConfigHelper configHeaderKeyForAppID:sdkAid];
    if (![[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:sdkConfigHeaderKey]) {
        [self _asyncFetchRemoteConfigImmediately:YES];
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"HMDConfigManager", @"[_maybeFetchSDKRemoteConfig:] SDK aid : %@ fetch setting again", sdkAid);
        }
    } else {
        id<HMDNetworkProvider> provider = [self.store providerForAppID:sdkAid];
        if (provider) {
            NSDictionary *headerInfo = [HMDConfigHelper requestHeaderFromProvider:provider];
            if (headerInfo) {
                [[HMDUserDefaults standardUserDefaults] setObject:headerInfo forKey:sdkConfigHeaderKey];
            }
        }
    }
}

+ (NSDictionary * _Nonnull)defaultConfigurationDictionary {
    return @{
        @"general": @{
            @"cleanup": @{}
        }
    };
}

- (HMDHeimdallrConfig *)remoteConfigWithAppID:(NSString *)appID {
    HMDHeimdallrConfig *result = [self.store configForAppID:appID];
    
    if(result == nil) {
        result = [[HMDHeimdallrConfig alloc] initWithAppId:appID defaultConfig:[HMDConfigManager defaultConfigurationDictionary]];
        DEBUG_ASSERT(result != nil);
        
        qos_class_t oldQos = qos_class_self();
        BOOL needRecover = NO;
        
        // 临时提升线程优先级
        if (_enablePriorityInversionProtection && oldQos < QOS_CLASS_USER_INTERACTIVE) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"Heimadallr promote the priority of write thread (remoteConfigWithAppID)");
            int ret = pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
            needRecover = (ret == 0);
        }
        
        self.store.configFromDefaultDictionary = result.isDefault;
        [self.store setDefaultConfig:result forAppID:appID];
        
        // 恢复线程优先级
        if (_enablePriorityInversionProtection && needRecover) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"Heimadallr resume the priority of write thread (remoteConfigWithAppID)");
            pthread_set_qos_class_self_np(oldQos, 0);
        }
    }
    
    return result;
}

- (void)setUpdateInterval:(NSTimeInterval)timeInterval withAppID:(NSString *)appID {
    [self.fetcher setAutoUpdateInterval:timeInterval forAppID:appID];
}

- (void)asyncFetchRemoteConfig:(BOOL)force {
    if (!self.store.firstFetchingCompleted) {
        return;
    }
    [self _asyncFetchRemoteConfigImmediately:force];
}

- (void)_asyncFetchRemoteConfigImmediately:(BOOL)force {
    [self.fetcher asyncFetchRemoteConfig:force];
}

#pragma mark - Notification
- (void)networkSchedule {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _asyncFetchRemoteConfigImmediately:YES];
    });
}

#pragma mark - HMDConfigDataProcessDelegate

- (void)dataProcessorFinishProcessResponseData:(id<HMDConfigDataProcess>)dataProcessor configs:(NSDictionary<NSString *,HMDHeimdallrConfig *> *)configs updateAppIDs:(NSArray<NSString *> *)updateAppIDs {
    NSString *lastTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    [self.store setLastTimestamp:lastTime forAppIDList:updateAppIDs];
    [self _dealResponseFinishWithConfigs:configs updateAppIDs:updateAppIDs];
}

- (void)_dealResponseFinishWithConfigs:(NSDictionary<NSString *,HMDHeimdallrConfig *> *)configs updateAppIDs:(NSArray<NSString *> *)updateAppIDs {
    if (configs.count <= 0) {
        return;
    }
    
    [self.store setRemoteConfigs:configs];
    
    // 解决首次启动app，由于有本地默认配置，导致无法更新的问题
    if (self.store.configFromDefaultDictionary) {
        self.store.configFromDefaultDictionary = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HMDConfigManagerDidUpdateNotification
                                                        object:@{HMDConfigManagerDidUpdateAppIDKey:updateAppIDs.copy,
                                                                 HMDConfigManagerDidUpdateConfigKey:self}];
    if (self.shouldForceRefreshConfigOnce) {
        self.shouldForceRefreshConfigOnce = NO;
    }
#if !RANGERSAPM
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"[processResponseData:] success: %@", updateAppIDs);
    }
#endif
}

#pragma mark - HMDConfigDataProcessDataSource

- (BOOL)needForceRefreshSettings:(NSString *)appID {
    NSString *configPath = [self configPathWithAppID:appID];
    BOOL isConfigExist = [[NSFileManager defaultManager] fileExistsAtPath:configPath];
    return !isConfigExist || self.shouldForceRefreshConfigOnce;
}

- (NSString *)configPathWithAppID:(NSString *)appID {
    NSString *fileName = [NSString stringWithFormat:@"%@%@", appID, HMDConfigFilePathSuffix];
    return [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:fileName];
}

#pragma mark - HMDConfigHostProviderDataSource

- (HMDHeimdallrConfig *)mainConfig {
    return self.store.majorConfig;
}

- (NSString *)standardizeHost:(NSString *)host {
    // 检查两个业务方容易在后面错误跟着的Path
    NSArray<NSString *> *suffixList = @[@"/monitor/appmonitor/v2/settings", @"/monitor/collect/"];
    for (NSString *suffix in suffixList) {
        if ([host hasSuffix:suffix]) {
            NSAssert(NO, @"Heimdallr [HMDCongfigManager fetchRemoteConfig] Error: the host of heimdallr setting request is illegal, the host contain path %@, it is needless", suffix);
            host = [host substringToIndex:(host.length - suffix.length)];
            break;
        }
    }
    return [host copy];
}

#pragma mark - Getter & Setter

- (BOOL)configFromDefaultDictionary {
    return self.store.configFromDefaultDictionary;
}

- (BOOL)firstFetchingCompleted {
    return self.store.firstFetchingCompleted;
}

- (NSString *)appID {
    return self.store.hostAppID;
}

@end
