//
//  HMDCrashTracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDCrashTracker.h"
#if SIMPLIFYEXTENSION
#import "HMDInjectedInfo.h"
#else
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "HMDExcludeModule.h"
#import "HMDCrashlogProcessor.h"
#import "HMDModuleNetworkManager.h"
#import "HMDDefaultURLSettings.h"
#import "HMDCommonAPISetting.h"
#endif
#import "HMDALogProtocol.h"
#import "HMDCrashConfig.h"
#import "HeimdallrUtilities.h"
#import "hmd_queue_name_offset.h"
#import "HMDInfo+AppInfo.h"

#import "HMDDynamicCall.h"
//#define LOG_IN_CRASH_TARCKER

#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"
#import "HMDCrashDynamicDataProvider.h"


#include "hmd_crash_safe_tool.h"
#include <execinfo.h>

#include "HMDCrashAsyncStackTrace.h"
#include "HMDCrashKitSwitch.h"
#include "hmd_cpp_exception.hpp"

#import "UIApplication+HMDUtility.h"
#import "HMDCrashAppGroupURL.h"
#import "HMDServiceContext.h"

static NSString *const kHMDCrashTrackFinishDetectionNotification = @"HMDCrashTrackFinishDetectionNotification";

#if !SIMPLIFYEXTENSION
#define kAssertMainThreadTransactionsConfig @"kAssertMainThreadTransactionsConfig"
#endif


#if SIMPLIFYEXTENSION
@interface HMDCrashTracker() <HMDCrashKitDelegate>
@property (atomic, strong, readwrite) HMDCrashConfig *config;
#else
@interface HMDCrashTracker() <HMDExcludeModule,HMDCrashKitDelegate,HMDModuleNetworkProvider>
#endif

@property (nonatomic, strong) HMDCrashDynamicDataProvider *dynamicDataProvider;

// Exclude Module
@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;
@property (atomic, copy) NSArray *reportBlocks;
@property (atomic, copy) NSArray *notDetectBlocks;

@end

@implementation HMDCrashTracker

#if !SIMPLIFYEXTENSION

+ (void)load {
    if ([self isSetAssertMainThreadTransactions])
    {
        setenv("CA_ASSERT_MAIN_THREAD_TRANSACTIONS", "1", 1);
    }
}

#endif

#if SIMPLIFYEXTENSION
+ (instancetype)sharedTracker {
    static HMDCrashTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDCrashTracker alloc] init];
    });
    return sharedTracker;
}
#else
SHAREDTRACKER(HMDCrashTracker)
#endif

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _reportBlocks = [NSArray array];
        _notDetectBlocks = [NSArray array];
#if !SIMPLIFYEXTENSION
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigNotification:) name:HMDConfigManagerDidUpdateNotification object:nil];
#endif
    }
    return self;
}

- (NSString *)crashPath {
    if (!_crashPath) {
        _crashPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"crash"];
    }
    return _crashPath;
}

#if !SIMPLIFYEXTENSION
- (void)crashKitDidDetectCrashForLastTime:(HMDCrashReportInfo *)crashReport
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        HMDCrashRecord *record = [[HMDCrashRecord alloc] init];
        record.memoryUsage = crashReport.memoryUsage;
        record.freeMemoryUsage = crashReport.freeMemoryUsage;
        record.freeMemoryPercent = crashReport.freeMemoryPercent;
        record.freeDiskUsage = crashReport.freeDiskUsage;
        record.isLaunchCrash = crashReport.isLaunchCrash;
        record.isBackground = crashReport.isBackground;
        record.customParams = crashReport.customParams;
        record.access = crashReport.access;
        record.lastScene = crashReport.lastScene;
        record.business = crashReport.business;
        record.filters = crashReport.filters;
        record.crashShortVersion = crashReport.appVersion;
        record.crashBuildVersion = crashReport.bundleVersion;
        record.crashExceptionName = crashReport.name;
        record.crashReason = crashReport.reason;
        record.crashType = (HMDCrashRecordType)crashReport.crashType;
        record.operationTrace = crashReport.operationTrace;
        record.timestamp = crashReport.time;
        record.sessionID = crashReport.sessionID;
        record.netQualityType = crashReport.networkQuality;
        [self didDetectOneCrashRecord:record];
    });
}

- (void)crashKitDidNotDetectCrashForLastTime
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self didNotDetectCrashRecord];
    });
}
#endif

- (void)notifyCrashDetect
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL lastTimeCrash = HMDSharedCrashKit.lastTimeCrash;
        self.detected = lastTimeCrash;
        self.finishDetection = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDCrashTrackFinishDetectionNotification
                                                            object:self
                                                          userInfo:nil];
        if(lastTimeCrash) {
            NSString *reasonStr = @"Application crash";
            NSDictionary *category = @{@"reason":reasonStr};
            id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_heimdallr_ttmonitor();
            [ttmonitor hmdTrackService:@"hmd_app_relaunch_reason" metric:nil category:category extra:nil];
            
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[Crash] application relaunch reason: %@", reasonStr);
        }
    });

}

- (BOOL)detectAppExtensionCrashAvailable{
    static BOOL detectAppExtensionCrash;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        detectAppExtensionCrash = ((HMDCrashConfig *)self.config).enableExtensionDetect;
    });
    return detectAppExtensionCrash;
}

- (void)start {
    if ([UIApplication isAppExtension] && ![self detectAppExtensionCrashAvailable]) {
        return;
    }
#if !SIMPLIFYEXTENSION
    [super start];
#endif
    
    hmdthread_test_queue_name_offset();

#if !SIMPLIFYEXTENSION
    HMDSharedCrashKit.networkProvider = self;
#endif
    HMDSharedCrashKit.commitID = [HMDInfo defaultInfo].commitID;
    HMDSharedCrashKit.sdkVersion = [HMDInfo defaultInfo].sdkVersion;
    HMDSharedCrashKit.delegate = self;
    [HMDSharedCrashKit setup];
    [self notifyCrashDetect];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.dynamicDataProvider = [[HMDCrashDynamicDataProvider alloc] init];
        });
    });
    
    [self updateSIGPIPEState];
}

- (void)updateSIGPIPEState {
    //When a connection closes, by default, your process receives a SIGPIPE signal. If your program does not handle or ignore this signal, your program will quit immediately.reference:https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/CommonPitfalls/CommonPitfalls.html
    if ([HMDInjectedInfo defaultInfo].ignorePIPESignalCrash) {
        signal(SIGPIPE, SIG_IGN);
    }
}

- (void)stop {
#if !SIMPLIFYEXTENSION
    [super stop];
#endif
}

- (BOOL)needSyncStart {
    return YES;
}

#if !SIMPLIFYEXTENSION
- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDCrashRecord class];
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [self.heimdallr cleanupSessionFilesWithConfig:cleanConfig path:self.crashPath];
}
#endif

- (void)updateConfig:(HMDCrashConfig *)config {
#if SIMPLIFYEXTENSION
    self.config = config;
#else
    [super updateConfig:config];
    if (config.crashUploadSetting) {
        HMDSharedCrashKit.needEncrypt = config.crashUploadSetting.enableEncrypt;
    }else{
        HMDSharedCrashKit.needEncrypt = config.allAPISetting.enableEncrypt;
    }    if (![UIApplication isAppExtension]) {
        NSDictionary *configDictionary = [config configDictionary];
        if ([HMDCrashAppGroupURL appGroupCrashSettingsURL]) {
            [configDictionary writeToFile:[HMDCrashAppGroupURL appGroupCrashSettingsURL].resourceSpecifier atomically:YES];
        }
    }
#endif

    HMDSharedCrashKit.launchCrashThreshold = config.launchThreshold;
#if defined(DEBUG)
    hmd_enable_async_stack_trace();
    [[HMDInjectedInfo defaultInfo] setCustomFilterValue:@(1) forKey:@"enable_async_stack_trace"];
    hmd_enable_multiple_async_stack_trace();
    hmd_enable_cpp_exception_backtrace();
    hmd_crash_switch_update(HMDCrashSwitchRegisterAnalysis, true);
    hmd_crash_switch_update(HMDCrashSwitchStackAnalysis, true);
    hmd_crash_switch_update(HMDCrashSwitchVMMap, true);
    hmd_crash_switch_update(HMDCrashSwitchContentAnalysis, true);
    hmd_crash_switch_update(HMDCrashSwitchIgnoreExitByUser, true);
    hmd_crash_switch_update(HMDCrashSwitchWriteImageOnCrash, true);
    hmd_crash_update_stack_trace_count(128*1024/8);
    hmd_crash_switch_update(HMDCrashSwitchExtendFD, true);
    hmd_crash_update_max_vmmap(0);
#else
    if (config.enableAsyncStackTrace) {
        [[HMDInjectedInfo defaultInfo] setCustomFilterValue:@(1) forKey:@"enable_async_stack_trace"];
        hmd_enable_async_stack_trace();
    } else {
        hmd_disable_async_stack_trace();
        [[HMDInjectedInfo defaultInfo] setCustomFilterValue:@(0) forKey:@"enable_async_stack_trace"];
    }
    if (config.enableMultipleAsyncStackTrace) {
        hmd_enable_multiple_async_stack_trace();
    } else {
        hmd_disable_multiple_async_stack_trace();
    }
    if (config.enableCPPBacktrace) {
        hmd_enable_cpp_exception_backtrace();
    } else {
        hmd_disable_cpp_exception_backtrace();
    }
    hmd_crash_switch_update(HMDCrashSwitchRegisterAnalysis, config.enableRegisterAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchStackAnalysis, config.enableStackAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchVMMap, config.enableVMMap?true:false);
    hmd_crash_switch_update(HMDCrashSwitchContentAnalysis, config.enableContentAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchIgnoreExitByUser, config.enableIgnoreExitByUser?true:false);
    hmd_crash_switch_update(HMDCrashSwitchWriteImageOnCrash, config.writeImageOnCrash?true:false);
    hmd_crash_switch_update(HMDCrashSwitchExtendFD, config.extendFD?true:false);
    hmd_crash_update_stack_trace_count((uint32_t)config.maxStackTraceCount);
    hmd_crash_update_max_vmmap(config.maxVmmapCount);
#endif
}

#if !SIMPLIFYEXTENSION

- (HMDCrashConfig *)crashConfig
{
    if ([self.config isKindOfClass:[HMDCrashConfig class]]) {
        return (HMDCrashConfig *)self.config;
    }
    return nil;
}

- (void)addCrashDetectCallBack:(CrashReportBlock)reportBlock{
    NSMutableArray *mBlocks = [NSMutableArray arrayWithArray:self.reportBlocks];
    if (reportBlock) {
        [mBlocks addObject:reportBlock];
    }
    self.reportBlocks = mBlocks;
}

- (void)addCrashNotDetectCallBack:(CrashReportNotDetectBlock)reportBlock {
    NSMutableArray *mBlocks = [NSMutableArray arrayWithArray:self.notDetectBlocks];
    if (reportBlock) {
        [mBlocks addObject:reportBlock];
    }
    self.notDetectBlocks = mBlocks;
}

- (void)uploadCrashLogImmediately {
}

- (void)receiveConfigNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && updatedConfigManager.appID && [appIDs containsObject:updatedConfigManager.appID]) {
            [self storeAssertMainThreadTransactionsConfig:updatedConfigManager.appID];
        }
    }
}

- (void)storeAssertMainThreadTransactionsConfig:(NSString *)appID
{
    HMDCrashConfig *crashConfig;
    if (appID) {
        HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:appID];
        NSArray *modules = config.activeModulesMap.allValues;
        for (HMDModuleConfig *config in modules) {
            id<HeimdallrModule> module = [config getModule];
            if ([[module moduleName] isEqualToString:kHMDModuleCrashTracker]) {
                crashConfig = (HMDCrashConfig *)config;
                break;
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAssertMainThreadTransactionsConfig];
    if (crashConfig && crashConfig.setAssertMainThreadTransactions) {
        [[NSUserDefaults standardUserDefaults] setBool:crashConfig.setAssertMainThreadTransactions forKey:kAssertMainThreadTransactionsConfig];
    }
}

+ (BOOL)isSetAssertMainThreadTransactions {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAssertMainThreadTransactionsConfig];
}


#pragma mark - uploader delegate

- (void)didDetectOneCrashRecord:(HMDCrashRecord *)record{
    NSArray *blocks = self.reportBlocks;
    for (CrashReportBlock block in blocks) {
        if (block) {
            block(record);
        }
    }
}

- (void)didNotDetectCrashRecord {
    NSArray *blocks = self.notDetectBlocks;
    for (CrashReportNotDetectBlock block in blocks) {
        if (block) {
            block();
        }
    }
}

#pragma mark - Excluded Module protocol

/// Notification object must be things return from excludedModule
- (NSString *)finishDetectionNotification {
    return kHMDCrashTrackFinishDetectionNotification;
}

+ (id<HMDExcludeModule>)excludedModule {
    return [HMDCrashTracker sharedTracker];
}

#pragma mark - network provider

- (BOOL)shouldEncrypt
{
    HMDCrashConfig *config = [self crashConfig];
    if (config.crashUploadSetting) {
        return config.crashUploadSetting.enableEncrypt;
    }
    return config.allAPISetting.enableEncrypt;
}

- (NSArray *)moduleNetworkProviderConfigHosts
{
    HMDCrashConfig *crashConfig = [self crashConfig];
    HMDCommonAPISetting *crashUploadSetting = crashConfig.crashUploadSetting;
    if (crashUploadSetting.hosts.count) {
        return crashUploadSetting.hosts;
    }
    return crashConfig.allAPISetting.hosts;
}

- (NSArray *)moduleNetworkProviderInjectedHosts
{
    NSArray *hosts = nil;
    NSString *host = [HMDInjectedInfo defaultInfo].crashUploadHost;
    if (host.length == 0) {
        host = [HMDInjectedInfo defaultInfo].allUploadHost;
    }
    if (host.length) {
        hosts = @[host];
    }
    return hosts;
}

- (NSArray *)moduleNetworkProviderDefaultHosts
{
    NSString *host = [HMDURLSettings crashUploadDefaultHost];
    if (host.length) {
        return @[host];
    }
    return nil;
}
#endif


@end
