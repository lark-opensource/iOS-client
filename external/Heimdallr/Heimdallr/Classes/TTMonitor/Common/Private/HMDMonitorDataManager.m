//
//  HMDMonitorDataManager.m
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/25.
//

#import "HMDMonitorDataManager.h"
#import "HMDWeakProxy.h"
#import "HMDTTMonitorTracker.h"
#import "HMDRecordStore.h"
#import "HMDStoreIMP.h"
#import "HMDHeimdallrConfig.h"
#import "HMDConfigManager.h"
#import "HMDMonitorDataManager+Upload.h"
#import "HMDSessionTracker.h"
#import "HMDDynamicCall.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDALogProtocol.h"
#import "HMDGeneralAPISettings.h"
#import "HMDCustomEventSetting.h"
#import "HMDInjectedInfo.h"
#import "HMDTTMonitorUserInfo.h"
#include <stdatomic.h>
#include "HMDMacro.h"
#import "Heimdallr.h"

#if TARGET_OS_SIMULATOR || DEBUG
static const NSInteger kHMDDBDevastateLevel_DFT = 500;
#endif

@interface HMDMonitorDataManager() {
    atomic_flag _needCacheFlag;
}

@property (atomic, strong, readwrite) HMDPerformanceReporter *reporter;
@property (atomic, strong, readwrite) HMDConfigManager *configManager;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, assign) BOOL isUploading;
@property (nonatomic, assign, readwrite) BOOL needCache; // 未获取到采样率，需要缓存埋点数据
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign)void *configProviderPtr;

@end

@implementation HMDMonitorDataManager
- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        //后续流程对此有依赖，需提前初始化
        self.injectedInfo = info;
        self.appID = appID;
        self.store = [HMDRecordStore shared];
        
        //通过appID与主App的appID是否相同而不是info是否为空判断是否是独立的sdk monitor
        if (![appID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
            HMDWeakProxy *configProvider = [HMDWeakProxy proxyWithTarget:self];
            _configProviderPtr = (__bridge void *)configProvider;
            [[HMDConfigManager sharedInstance] addProvider:(id<HMDNetworkProvider>)configProvider forAppID:appID];
            self.configManager = [HMDConfigManager sharedInstance];
            self.reporter = [[HMDPerformanceReporter alloc] initWithProvider:(id<HMDNetworkProvider>)[HMDWeakProxy proxyWithTarget:self]];
#if RANGERSAPM
            self.reporter.sdkAid = appID;
#endif
            [[HMDPerformanceReporterManager sharedInstance] addReporter:self.reporter withAppID:appID];
#if TARGET_OS_SIMULATOR || DEBUG
            // DMT在模拟器和debug环境下，不开启Heimdallr但是会使用SDKMonitor，由此会造成db过大
            [self recordDatabaseSizeAndDevastateIfNeeded];
#endif
        } else {
            [self syncConfigManagerIfAvailable];
            if (!self.configManager) {
                self.configManager = [HMDConfigManager sharedInstance];
            }
            
            [self syncReporterIfAvailable];
            if (!self.reporter) {
                self.reporter = [[HMDPerformanceReporter alloc] initWithProvider:(id<HMDNetworkProvider>)[HMDInjectedInfo defaultInfo]];
                [[HMDPerformanceReporterManager sharedInstance] addReporter:self.reporter withAppID:appID];
            }
        }
        
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf updateConfig:[strongSelf.configManager remoteConfigWithAppID:appID]];
            [[HMDPerformanceReporterManager sharedInstance] reportPerformanceDataAfterInitializeWithAppID:appID block:NULL];
        });
        _needCacheFlag._Value = 0;
        self.needCache = [self ifNeedCacheRecords];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(performanceReportSuccessed:)
                                                     name:HMDPerformanceReportSuccessNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidUpdate:)
                                                     name:HMDConfigManagerDidUpdateNotification
                                                   object:nil];
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDMonitorDataManager initialize with appID : %@, default info : %@, injected info : %@, need cache : %d", appID, [HMDInjectedInfo defaultInfo].appID, info ? info.appID : @"nil", self.needCache);
    }
    return self;
}

#if TARGET_OS_SIMULATOR || DEBUG
- (void)recordDatabaseSizeAndDevastateIfNeeded {
    if([Heimdallr shared].enableWorking) {
        return;
    }
    long fileSize = [self.store dbFileSize];
    if (fileSize > kHMDDBDevastateLevel_DFT * HMD_MB) {
        [self.store devastateDatabase];
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"HMDMonitorDataManager devastate the database which is %f MB, larger than threshold:%ld MB", fileSize / (float)HMD_MB, kHMDDBDevastateLevel_DFT);
        }
    }
}
#endif

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[HMDConfigManager sharedInstance] removeProvider:self.configProviderPtr forAppID:self.appID];
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDMonitorDataManager dealloc with appID : %@", self.appID);
}

- (void)updateConfig:(HMDHeimdallrConfig *)config {
    [self.configManager setUpdateInterval:(NSTimeInterval)config.apiSettings.fetchAPISetting.fetchInterval withAppID:self.appID];
    [self.reporter updateConfig:config];
}

- (HMDHeimdallrConfig *)config {
    return [self.configManager remoteConfigWithAppID:self.appID];
}

- (void)syncReporterIfAvailable {
    HMDPerformanceReporter *heimdallrReporter = DC_IS(DC_OB(DC_CL(Heimdallr, shared), reporter), HMDPerformanceReporter);
    if (heimdallrReporter != nil && self.reporter != heimdallrReporter) {
        NSArray *previousModules = [self.reporter allReportingModules];
        self.reporter = heimdallrReporter;
        //如果切换时候旧的reporter的模块没添加到新的中就漏了那个模块的上报
        for (id module in previousModules) {
            [[HMDPerformanceReporterManager sharedInstance] addReportModule:module withAppID:[HMDInjectedInfo defaultInfo].appID];
        }
    }
}

- (void)syncConfigManagerIfAvailable {
    HMDConfigManager *heimdallrConfigManager = DC_IS(DC_OB(DC_CL(Heimdallr, shared), configManager), HMDConfigManager);
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
            
            if ([self isMainAppMonitor]) {
                [self syncReporterIfAvailable];
            }
            
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

- (void)performanceReportSuccessed:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSArray.class]) {
        NSArray *reporterArray = (NSArray *)notification.object;
        if ([reporterArray containsObject:self.reporter]) {
            [self.configManager asyncFetchRemoteConfig:NO];
        }
    }
}

@end
