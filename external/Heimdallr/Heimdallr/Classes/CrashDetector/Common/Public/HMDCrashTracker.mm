//
//  HMDCrashTracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#include <atomic>
#include <execinfo.h>

#if SIMPLIFYEXTENSION
#import "HMDInjectedInfo.h"
#else
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "HMDExcludeModule.h"
#import "HMDCrashlogProcessor.h"
#if RANGERSAPM
#import "RangersAPMURLSettings.h"
#import "HMDConfigManager.h"
#endif /* RANGERSAPM */
#import "HMDCommonAPISetting.h"
#endif /* SIMPLIFYEXTENSION */

#if RANGERSAPM
#import "HMDInjectedInfo.h"
#import "RangersCrashDynamicDataProvider.h"
#import "HMDCrashExtraDynamicData_ToB.h"
#endif /* RANGERSAPM */

#if RANGERSAPM
#import "RangersAPMCrashURLHostProvider.h"
#else
#import "HMDCrashURLHostProvider.h"
#endif /* RANGERSAPM */

#import "HMDMacro.h"
#import "HMDCrashTracker.h"
#import "HMDALogProtocol.h"
#import "HMDCrashConfig.h"
#import "HeimdallrUtilities.h"
#import "hmd_queue_name_offset.h"
#import "HMDInfo+AppInfo.h"
#import "HMDDynamicCall.h"
#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"
#import "HMDCrashDynamicDataProvider.h"
#include "hmd_crash_safe_tool.h"
#include "HMDCrashAsyncStackTrace.h"
#include "HMDCrashKitSwitch.h"
#include "hmd_cpp_exception.hpp"
#import "UIApplication+HMDUtility.h"
#import "HMDCrashAppGroupURL.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDMonitorService.h"

#if !SIMPLIFYEXTENSION
#import "HMDCrashLoadSync_LowLevel.h"
#endif

static NSString *const kAssertMainThreadTransactionsConfig       = @"kAssertMainThreadTransactionsConfig";
static NSString *const kHMDCrashTrackFinishDetectionNotification = @"HMDCrashTrackFinishDetectionNotification";

#if SIMPLIFYEXTENSION
@interface HMDCrashTracker()
@property (atomic, strong, readwrite) HMDCrashConfig *config;
@property (atomic, assign, readwrite) BOOL isRunning;
#else
@interface HMDCrashTracker() <HMDExcludeModule, HMDCrashKitDelegate>
#endif

@property (nonatomic, strong) HMDCrashDynamicDataProvider *dynamicDataProvider;

// Exclude Module
@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;

// Report Block
@property(atomic, copy) NSArray *reportBlocks;
@property(atomic, copy) NSArray *notDetectBlocks;

@end

@implementation HMDCrashTracker {
    BOOL _crashKitFinishedSetup;
}

#if !SIMPLIFYEXTENSION

+ (void)load {
    if ([self isSetAssertMainThreadTransactions])
    {
        setenv("CA_ASSERT_MAIN_THREAD_TRANSACTIONS", "1", 1);
    } else {
        unsetenv("CA_ASSERT_MAIN_THREAD_TRANSACTIONS");
    }
}

#endif

+ (instancetype)sharedTracker {
    static HMDCrashTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDCrashTracker alloc] init];
    });
    return sharedTracker;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
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
- (void)crashKitDidDetectCrashForLastTime:(HMDCrashReportInfo *)crashReport {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self notifyCrashProcessComplete];
        
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
        record.crashLog = crashReport.crashLog;
        [self didDetectOneCrashRecord:record];
    });
}

- (void)crashKitDidNotDetectCrashForLastTime {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self notifyCrashProcessComplete];
        
        [self didNotDetectCrashRecord];
    });
}
#endif

- (void)writeLogIfCrashHappened {
    BOOL lastTimeCrash = HMDSharedCrashKit.lastTimeCrash;
    if(!lastTimeCrash) return;
    
    NSString *reasonStr = @"Application crash";
    NSDictionary *category = @{@"reason":reasonStr};
    [HMDMonitorService trackService:@"hmd_app_relaunch_reason" metrics:nil dimension:category extra:nil];
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[Crash] application relaunch reason: %@", reasonStr);
}

- (void)notifyCrashProcessComplete {
    BOOL lastTimeCrash = HMDSharedCrashKit.lastTimeCrash;
    self.detected = lastTimeCrash;
    self.finishDetection = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDCrashTrackFinishDetectionNotification
                                                        object:self
                                                      userInfo:nil];
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
    // [1] preparation before crash start
    #if !SIMPLIFYEXTENSION
    [super start];
    #else
    self.isRunning = YES;
    #endif

    if ([UIApplication hmd_isAppExtension] && ![self detectAppExtensionCrashAvailable])
        return;

    // [2] start crash detection once
    [self startCrashDetection_once];

    // [3] switch option
    [self updateCrashRelatedTool];
}

- (void)stop {
    #if !SIMPLIFYEXTENSION
    [super stop];
    #else
    self.isRunning = NO;
    #endif
}

- (void)startCrashDetection_once {
    DEBUG_ASSERT(self.isRunning);
    
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(onceToken.test_and_set()) return;

    #if !SIMPLIFYEXTENSION
    HMDSharedCrashKit.networkProvider = self;
    #endif

    HMDSharedCrashKit.commitID = [HMDInfo defaultInfo].commitID;
    HMDSharedCrashKit.sdkVersion = [HMDInfo defaultInfo].sdkVersion;
    HMDSharedCrashKit.delegate = self;
    [HMDSharedCrashKit setup];
    
    __atomic_store_n(&_crashKitFinishedSetup, YES, __ATOMIC_RELEASE);

    hmdthread_test_queue_name_offset();

    [self writeLogIfCrashHappened];
    
    [self updateSIGPIPEState];
    
    #if !SIMPLIFYEXTENSION
    HMDCrashLoadSync_trackerCallback();
    #endif

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dynamicDataProvider = [[HMDCrashDynamicDataProvider alloc] init];
    });
}

- (void)updateCrashRelatedTool {
    DEBUG_ASSERT(self.isRunning);

    HMDCrashConfig *config = (HMDCrashConfig *)self.config;

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
}

- (void)updateSIGPIPEState {
    //When a connection closes, by default, your process receives a SIGPIPE signal. If your program does not handle or ignore this signal, your program will quit immediately.reference:https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/CommonPitfalls/CommonPitfalls.html
    if ([HMDInjectedInfo defaultInfo].ignorePIPESignalCrash) {
        signal(SIGPIPE, SIG_IGN);
    }
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
    }    if (![UIApplication hmd_isAppExtension]) {
        NSDictionary *configDictionary = [config configDictionary];
        if ([HMDCrashAppGroupURL appGroupCrashSettingsURL]) {
            [configDictionary writeToFile:[HMDCrashAppGroupURL appGroupCrashSettingsURL].resourceSpecifier atomically:YES];
        }
    }
#endif

    HMDSharedCrashKit.launchCrashThreshold = config.launchThreshold;

    #if DEBUG
    config.enableAsyncStackTrace = YES;
    config.enableMultipleAsyncStackTrace = YES;
    config.enableCPPBacktrace = YES;
    config.enableRegisterAnalysis = YES;
    config.enableStackAnalysis = YES;
    config.enableVMMap = YES;
    config.enableContentAnalysis = YES;
    config.enableIgnoreExitByUser = YES;
    config.writeImageOnCrash = YES;
    config.extendFD = YES;
    config.maxStackTraceCount = 128*1024/8;
    config.maxVmmapCount = 0;
    #endif

    hmd_crash_switch_update(HMDCrashSwitchRegisterAnalysis, config.enableRegisterAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchStackAnalysis, config.enableStackAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchVMMap, config.enableVMMap?true:false);
    hmd_crash_switch_update(HMDCrashSwitchContentAnalysis, config.enableContentAnalysis?true:false);
    hmd_crash_switch_update(HMDCrashSwitchIgnoreExitByUser, config.enableIgnoreExitByUser?true:false);
    // hmd_crash_switch_update(HMDCrashSwitchWriteImageOnCrash, config.writeImageOnCrash?true:false);
    hmd_crash_switch_update(HMDCrashSwitchExtendFD, config.extendFD?true:false);
    hmd_crash_update_stack_trace_count((uint32_t)config.maxStackTraceCount);
    hmd_crash_update_max_vmmap(config.maxVmmapCount);

    if(!self.isRunning) return;

    [self updateCrashRelatedTool];
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

#if !SIMPLIFYEXTENSION
- (void)uploadCrashLogImmediately {
    [self uploadCrashLogImmediately:nil];
}

- (BOOL)uploadCrashLogImmediately:(NSError * __autoreleasing _Nullable * _Nullable)error {
    BOOL finished = __atomic_load_n(&_crashKitFinishedSetup, __ATOMIC_ACQUIRE);
    if(unlikely(!finished)) {
        if(error == NULL) return NO;
        
        NSError *theReasonWhy;
        theReasonWhy = [NSError errorWithDomain:@"HMDCrashTracker"
                                           code:0
                                       userInfo:@{NSLocalizedDescriptionKey:@"CrashTracker is not started"}];
        
        error[0] = theReasonWhy;
        return NO;
    }
    
    [HMDCrashKit.sharedInstance requestCrashUpload:NO];
    return YES;
}
#endif

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

#endif

@end
