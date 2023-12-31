//
//  HMDMonitorDataManager2.m
//  Heimdallr
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import "HMDMonitorDataManager2.h"
#import "HMDWeakProxy.h"
#import "HMDTTMonitorTracker.h"
#import "HMDHeimdallrConfig.h"
#import "HMDConfigManager.h"
#import "HMDMonitorDataManager+Upload.h"
#import "HMDSessionTracker.h"
#import "HMDDynamicCall.h"
#import "HMDALogProtocol.h"
#import "HMDGeneralAPISettings.h"
#import "HMDCustomEventSetting.h"
#import "HMDTTMonitorUserInfo.h"
#import "HMDInjectedInfo.h"
#import "HMDTTMonitorHelper.h"
#import "HMDTTMonitorUserInfo+Private.h"
#include <stdatomic.h>

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@interface HMDMonitorDataManager2()<HMDNetworkProvider> {
    atomic_flag _needCacheFlag;
}

@property (atomic, strong, readwrite) HMDConfigManager *configManager;
@property (nonatomic, assign, readwrite) BOOL needCache; // 未获取到采样率，需要缓存埋点数据
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) void *configProviderPtr;

@end

@implementation HMDMonitorDataManager2
- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        //后续流程对此有依赖，需提前初始化
        self.injectedInfo = info;
        self.appID = appID;
        
        //通过appID与主App的appID是否相同而不是info是否为空判断是否是独立的sdk monitor
        if (![appID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
            HMDWeakProxy *configProvider = [HMDWeakProxy proxyWithTarget:self];
            _configProviderPtr = (__bridge void *)configProvider;
            [[HMDConfigManager sharedInstance] addProvider:(id<HMDNetworkProvider>)configProvider forAppID:appID];
            self.configManager = [HMDConfigManager sharedInstance];
        } else {
            [self syncConfigManagerIfAvailable];
            if (!self.configManager) {
                self.configManager = [HMDConfigManager sharedInstance];
            }
        }
        [self updateConfig:[self.configManager remoteConfigWithAppID:appID]];
    
        // 不再需要reportPerformanceDataAfterInitializeWithAppID的相关处理
        //
        
        _needCacheFlag._Value = 0;
        self.needCache = [self ifNeedCacheRecords];

        // 这里不再需要HMDPerformanceReportSuccessNotification的通知
        //
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidUpdate:)
                                                     name:HMDConfigManagerDidUpdateNotification
                                                   object:nil];
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDMonitorDataManager initialize with appID : %@, default info : %@, injected info : %@, need cache : %d", appID, [HMDInjectedInfo defaultInfo].appID, info ? info.appID : @"nil", self.needCache);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[HMDConfigManager sharedInstance] removeProvider:self.configProviderPtr forAppID:self.appID];
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDMonitorDataManager dealloc with appID : %@", self.appID);
}

- (void)updateConfig:(HMDHeimdallrConfig *)config {
    [self.configManager setUpdateInterval:(NSTimeInterval)config.apiSettings.fetchAPISetting.fetchInterval withAppID:self.appID];
}

- (HMDHeimdallrConfig *)config {
    return [self.configManager remoteConfigWithAppID:self.appID];
}

- (void)syncConfigManagerIfAvailable {
    HMDConfigManager *heimdallrConfigManager = DC_ET(DC_OB(DC_CL(Heimdallr, shared), configManager), HMDConfigManager);
    if (heimdallrConfigManager != nil && self.configManager != heimdallrConfigManager)
        self.configManager = heimdallrConfigManager;
}

- (BOOL)isMainAppMonitor {
    return [self.appID isEqualToString:[HMDInjectedInfo defaultInfo].appID];
}

- (BOOL)ifNeedCacheRecords {
    NSString *configPath = [self.configManager configPathWithAppID:self.appID];
    if (configPath && [[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        return NO;
    }
    
    HMDALOG_PROTOCOL_WARN_TAG(@"HMDEventTrace", @"HMDMonitorDataManager need cache records with app id : %@", self.appID);
    return YES;
}

#pragma mark - Upload
- (NSDictionary *)reportHeaderParams {
    return [HMDTTMonitorHelper reportHeaderParamsWithInjectedInfo:self.injectedInfo];
}

- (NSDictionary *)reportCommonParams {
    return [self.injectedInfo currentCommonParams];
}

- (BOOL)enableBackgroundUpload {
    return self.injectedInfo.enableBackgroundUpload;
}

#pragma mark - Notification
- (void)configDidUpdate:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        if (appIDs.count && [appIDs containsObject:self.appID]) {
            if (updatedConfigManager != self.configManager) {
                self.configManager = updatedConfigManager;
            }
            
            [self updateConfig:[self.configManager remoteConfigWithAppID:self.appID]];
            
            // 只回调一次
            if (_needCache && !updatedConfigManager.configFromDefaultDictionary) {
                if (!atomic_flag_test_and_set_explicit(&_needCacheFlag, memory_order_relaxed)) {
                    _needCache = NO;
                    if (self.stopCacheBlock) self.stopCacheBlock();
                    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDMonitorDataManager dose not need cache any more with app id : %@", self.appID);
                }
            }
            
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"AppID : %@, service name : %@\nlog type : %@", self.appID, self.config.customEventSetting.allowedServiceTypes, self.config.customEventSetting.allowedLogTypes);
        }
    }
}


@end
