//
//  HMDSDKConfigInfo.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2019/11/29.
//

#import "HMDSDKMonitorDataManager.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDPerformanceReporter.h"
#import "HMDConfigManager.h"
#import "HMDRecordStore.h"
#import "HMDTTMonitorUserInfo.h"
#import "HMDWeakProxy.h"
#import "Heimdallr.h"
#import "HeimdallrModule.h"
#include "pthread_extended.h"
#import "HMDALogProtocol.h"
#import "HMDTTMonitor.h"
#import "Heimdallr+ModuleCallback.h"
#import "HMDModuleConfig.h"
#import "HMDMonitorDataManager.h"
#import "HMDTTMonitor+Private.h"

#import "HMDDynamicCall.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString *const kHMDSDKMonitorNetworkMoudleName = @"network";

@interface HMDSDKMonitorDataManager ()

@property (nonatomic, strong) HMDPerformanceReporter *reporter;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, assign) BOOL isUploading;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<HeimdallrModule>> *sdkRemoteModules;
@property (nonatomic, strong) id<NSObject> networkModuleObserver;

@end

@implementation HMDSDKMonitorDataManager {
    pthread_rwlock_t _remoteModuleLock;
}

- (instancetype)initSDKMonitorDataManagerWithSDKAid:(NSString *)sdkAid injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_remoteModuleLock, NULL);

        self.sdkAid = sdkAid;
        self.hostAid = info.hostAppID;
        self.ttMonitorUserInfo = info;

        self.ttMonitor = [[HMDTTMonitor alloc] initMonitorWithAppID:sdkAid injectedInfo:info];
        self.store = [HMDRecordStore shared];

        [self setupReportPerformanceManagersIfNeed];
        [self observeHeimdallrModules];
        [self updateConfigManagerAndReprotWithConfig:[[HMDConfigManager sharedInstance] remoteConfigWithAppID:sdkAid]];
        self.sdkRemoteModules = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidUpdate:)
                                                     name:HMDConfigManagerDidUpdateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (self.networkModuleObserver) {
            [[Heimdallr shared] removeObserver:self.networkModuleObserver];
        }
    } @catch (NSException *exception) {

    }
}
#pragma mark --- sdk 监控模块控制
- (void)observeHeimdallrModules {
    __weak typeof(self) weakSelf = self;
    self.networkModuleObserver = [[Heimdallr shared] addObserverForModule:kHMDSDKMonitorNetworkMoudleName usingBlock:^(id<HeimdallrModule>  _Nullable module, BOOL isWorking) {
        __strong typeof(self) strongSelf = weakSelf;
        if ([[module moduleName] isEqualToString:kHMDSDKMonitorNetworkMoudleName]) {
            if (isWorking) {
                [strongSelf addMoudleToRemoteDict:module]; // 如果是来自宿主的, moudle 初始化控制权应该在宿主手中 这里只做 module集合的增删
            } else {
                [strongSelf removeModuleFromRemoteDict:module];
            }
        }
    }];
}

- (void)updateMoudleSetupWithConfig:(HMDHeimdallrConfig *)config {
    if([Heimdallr shared].enableWorking) { return;}; // 如果有宿主 以宿主为准
    NSArray *moduleConfigs = config.activeModulesMap.allValues;
    BOOL hasNetModule = NO;
    // https://bytedance.feishu.cn/wiki/wikcni7JKLa4UWu8l0wVCbZlkfS
    // 这里主要是为了在 Heimdallr 没启动时开启网络监控
    for (HMDModuleConfig *moduleConfig in moduleConfigs) {
        if([[moduleConfig.class configKey] isEqualToString:kHMDSDKMonitorNetworkMoudleName]) {
            id<HeimdallrModule> module = [self moduleWithConfig:moduleConfig];
            [self setupModule:module];
            hasNetModule = YES;
            break;
        }
    }

    pthread_rwlock_rdlock(&_remoteModuleLock);
    id<HeimdallrModule> remoteHasNetModule = [self.sdkRemoteModules objectForKey:kHMDSDKMonitorNetworkMoudleName];
    pthread_rwlock_unlock(&_remoteModuleLock);
    if (!hasNetModule && remoteHasNetModule != nil) {
        [self stopModule:remoteHasNetModule];
    }
}

- (id<HeimdallrModule>)moduleWithConfig:(HMDModuleConfig *)config
{
    id<HeimdallrModule> module = [config getModule];
    if ([module respondsToSelector:@selector(updateConfig:)] && module.config != config) {
        [module updateConfig:config];
    }
    return module;
}

- (void)addMoudleToRemoteDict:(id<HeimdallrModule>)module {
    pthread_rwlock_rdlock(&_remoteModuleLock);
    BOOL hasModule = [self.sdkRemoteModules objectForKey:[module moduleName]] != nil;
    pthread_rwlock_unlock(&_remoteModuleLock);
    if (!hasModule) {
       pthread_rwlock_wrlock(&_remoteModuleLock);
       [self.sdkRemoteModules setValue:module forKey:[module moduleName]];
       pthread_rwlock_unlock(&_remoteModuleLock);
    }
}

- (void)removeModuleFromRemoteDict:(id<HeimdallrModule>)module {
    pthread_rwlock_rdlock(&_remoteModuleLock);
    BOOL hasModule = [self.sdkRemoteModules objectForKey:[module moduleName]] != nil;
    pthread_rwlock_unlock(&_remoteModuleLock);
    if (hasModule) {
       pthread_rwlock_wrlock(&_remoteModuleLock);
       NSString *stopModuleName = [module moduleName];
       if (stopModuleName) {
           [self.sdkRemoteModules removeObjectForKey:stopModuleName];
       }
       pthread_rwlock_unlock(&_remoteModuleLock);
    }
}

- (void)stopModule:(id<HeimdallrModule>)module
{
    if (module && module.isRunning) {
        [module stop];
        
        if (!hermas_enabled()) {
            if ([module respondsToSelector:@selector(performanceDataSource)] && [module performanceDataSource]) {
                [[HMDPerformanceReporterManager sharedInstance] removeReportModule:(id)module withAppID:self.sdkAid];
            }
        }
        
        pthread_rwlock_wrlock(&_remoteModuleLock);
        NSString *stopModuleName = [module moduleName];
        if (stopModuleName) {
            [self.sdkRemoteModules removeObjectForKey:stopModuleName];
        }
        pthread_rwlock_unlock(&_remoteModuleLock);
    }
}

- (void)setupModule:(id<HeimdallrModule>)module
{
    pthread_rwlock_rdlock(&_remoteModuleLock);
    BOOL hasModule = [self.sdkRemoteModules objectForKey:[module moduleName]] != nil;
    pthread_rwlock_unlock(&_remoteModuleLock);
    if (!hasModule) {
        NSTimeInterval moduleStart = 0;
        if (hmd_log_enable()) {
            moduleStart = [[NSDate date] timeIntervalSince1970] * 1000;
        }

        if([module respondsToSelector:@selector(setupWithHeimdallr:)] && !module.heimdallr) {
            [module setupWithHeimdallr:[Heimdallr shared]];
        }

        if (!hermas_enabled()) {
            if ([module respondsToSelector:@selector(performanceDataSource)] && [module performanceDataSource]) {
                [[HMDPerformanceReporterManager sharedInstance] addReportModule:(id)module withAppID:self.sdkAid];
            }
        }
        
        if (!module.isRunning) {
            [module start];
        }

        pthread_rwlock_wrlock(&_remoteModuleLock);
        [self.sdkRemoteModules setValue:module forKey:[module moduleName]];
        pthread_rwlock_unlock(&_remoteModuleLock);

        if (hmd_log_enable()) {
            NSTimeInterval moduleEnd = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *duration = [NSString stringWithFormat:@"Heimdallr SDKMonitor module %@ load time:%f ms",NSStringFromClass([module class]), moduleEnd - moduleStart];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@", duration);
        }
    }
}

#pragma mark --- 上报
- (void)setupReportPerformanceManagersIfNeed {
    // 重构逻辑下，没有reporter的概念了，所以这里直接返回
    if (hermas_enabled()) return;
    
    HMDMonitorDataManager *dataManager = self.ttMonitor.dataManager;
    if (dataManager.reporter) {
        self.reporter = dataManager.reporter;
        self.reporter.isSDKReporter = YES;
        self.reporter.sdkAid = self.sdkAid;
    } else {
        self.reporter = [[HMDPerformanceReporter alloc] initWithProvider:(id<HMDNetworkProvider>)[HMDWeakProxy proxyWithTarget:self]];
        self.reporter.isSDKReporter = YES;
        self.reporter.sdkAid = self.sdkAid;
        [[HMDPerformanceReporterManager sharedInstance] addReporter:self.reporter withAppID:self.sdkAid];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[HMDPerformanceReporterManager sharedInstance] reportPerformanceDataAfterInitializeWithAppID:self.sdkAid block:NULL];
        });
    }
}

#pragma mark --- sdk监控配置

//  收到通知 更新配置
- (void)configDidUpdate:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        if (appIDs.count && [appIDs containsObject:self.sdkAid]) {
            // 如果配置 appId 相等; 更新配置
            [self updateConfigManagerAndReprotWithConfig:[[HMDConfigManager sharedInstance] remoteConfigWithAppID:self.sdkAid]];
        }
    }
}

// 更新 report 的配置
- (void)updateConfigManagerAndReprotWithConfig:(HMDHeimdallrConfig *)config {
    if (!hermas_enabled()) {
        [self.reporter updateConfig:config];
    }
    [self updateMoudleSetupWithConfig:config];
}

@end
