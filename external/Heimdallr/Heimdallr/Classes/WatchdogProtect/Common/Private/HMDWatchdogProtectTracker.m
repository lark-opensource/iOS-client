//
//  HMDWatchdogProtectTracker.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDWatchdogProtectTracker.h"
#import "HMDExceptionReporter.h"
#import "HMDWatchdogProtectManager.h"
#import "HMDWatchdogProtectRecord.h"
#import "HMDWatchdogProtectConfig.h"
#import "HMDStoreCondition.h"
#import "HMDDynamicCall.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDExcludeModule.h"
#import "HMDDebugRealConfig.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDUserExceptionTracker.h"
#import "HMDWatchdogProtectDetectProtocol.h"
#import "HMDThreadBacktrace.h"
#import "HMDWatchdogProtectDefine.h"
#import "HMDMemoryUsage.h"
#import "HMDDiskUsage.h"
#import "HMDInjectedInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDWatchdogProtectManager+Private.h"

static NSUInteger const kHMDWatchdogProtectUploadLimitCount = 5;

@interface HMDWatchdogProtectTracker ()<HMDWatchdogProtectDetectProtocol, HMDExceptionReporterDataProvider>
@property(nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;
@end

@implementation HMDWatchdogProtectTracker

SHAREDTRACKER(HMDWatchdogProtectTracker)

#pragma mark - HeimdallrModule

- (void)start {
    [super start];
    HMDWatchdogProtectConfig *config = (__kindof HMDWatchdogProtectConfig *)self.config;
    HMDWatchdogProtectManager *manager = [HMDWatchdogProtectManager sharedInstance];
    manager.delegate = self;
    manager.timeoutInterval = config.timeoutInterval;
    manager.launchThreshold = config.launchThreshold;
    [manager setDynamicProtectOnMainThread:config.dynamicProtect onAnyThread:config.dynamicProtectAnyThread];
    [self updateTypeList:config.typeList];
}

- (void)stop {
    [super stop];
    HMDWatchdogProtectManager *manager = [HMDWatchdogProtectManager sharedInstance];
    manager.UIPasteboardProtect = NO;
    manager.UIApplicationProtect = NO;
    manager.YYCacheProtect = NO;
    manager.NSUserDefaultProtect = NO;
    [manager setDynamicProtectOnMainThread:@[] onAnyThread:@[]];
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDWatchdogProtectRecord class];
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return NO;
}

- (void)updateConfig:(HMDWatchdogProtectConfig *)config {
    [super updateConfig:config];
    HMDWatchdogProtectManager *manager = [HMDWatchdogProtectManager sharedInstance];
    manager.timeoutInterval = config.timeoutInterval;
    manager.launchThreshold = config.launchThreshold;
    if (self.isRunning) {
        [manager setDynamicProtectOnMainThread:config.dynamicProtect onAnyThread:config.dynamicProtectAnyThread];
        [self updateTypeList:config.typeList];
    }
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [super cleanupWithConfig:cleanConfig];
}

#pragma mark - HMDUIFrozenDetectProtocol

- (void)didProtectWatchdogWithCapture:(HMDWPCapture *)capture {
    self.detected = YES;
    HMDWatchdogProtectManager *manager = [HMDWatchdogProtectManager sharedInstance];
    NSArray <HMDThreadBacktrace *>* backtraces = capture.backtraces;
    if (backtraces && [backtraces isKindOfClass:[NSArray class]] && backtraces.count > 0) {
        NSMutableDictionary *custom = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *filter = [[NSMutableDictionary alloc] init];
        [custom removeObjectForKey:kHMDWPKeyBacktrace];
        [custom setValue:@(capture.timeoutInterval) forKey:kHMDWPKeyTimeoutInterval];
        [custom setValue:@(capture.blockTimeInterval) forKey:kHMDWPKeyBlockTime];
        [custom setValue:@(capture.timestamp) forKey:kHMDWPKeyTimestamp];
        [custom setValue:@(capture.inAppTime) forKey:kHMDWPKeyIsLaunchCrash];
        [custom setValue:@((capture.inAppTime<=manager.launchThreshold)?YES:NO) forKey:kHMDWPKeyIsLaunchCrash];
        NSString *dynamicProtectSettings = manager.currentProtectedMethodDescription;

        NSDictionary *settings = @{
            @"timeout_interval" : @(manager.timeoutInterval),
            @"launch_threshold" : @(manager.launchThreshold),
            @"UIPasteboardProtect": @(manager.UIPasteboardProtect),
            @"UIApplicationProtect": @(manager.UIApplicationProtect),
            @"YYCacheProtect": @(manager.YYCacheProtect),
            @"NSUserDefaultProtect": @(manager.NSUserDefaultProtect),
            @"dynamic_protect": dynamicProtectSettings ?: @"",
        };
        [custom setValue:settings forKey:kHMDWPKeySettings];
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        [custom setValue:@(memoryBytes.appMemory/HMD_MB) forKey:kHMDWPKeyMemoryUsage];
        [custom setValue:@(memoryBytes.availabelMemory/HMD_MB) forKey:kHMDWPKeyFreeMemoryUsage];
        [custom setValue:@([HMDDiskUsage getFreeDisk300MBlockSize]) forKey:kHMDWPKeyFreeDiskBlock];

        [custom setValue:[HMDInjectedInfo defaultInfo].business ?: @"unknown" forKey:kHMDWPKeyBusiness];
        [custom setValue:[HMDNetworkHelper connectTypeName] forKey:kHMDWPKeyNetwork];
        [custom setValue:[HMDTracker getLastSceneIfAvailable] forKey:kHMDWPKeylastScene];
        [custom setValue:[HMDTracker getOperationTraceIfAvailable] forKey:kHMDWPKeyOperationTrace];
        if(capture.mainThread) {
            // custom 只支持 string
            [custom setValue:@"1" forKey:kHMDWPKeyHappenOnMainThread];
        } else {
            [custom setValue:@"0" forKey:kHMDWPKeyHappenOnMainThread];
        }
        
        switch (capture.type) {
            case HMDWPCaptureExceptionTypeWarning:
            {
                [filter setValue:@"warn" forKey:kHMDWPKeyExceptionType];
                break;
            }
            case HMDWPCaptureExceptionTypeError:
            {
                [filter setValue:@"error" forKey:kHMDWPKeyExceptionType];
                break;
            }
            default:{
                [filter setValue:@"none" forKey:kHMDWPKeyExceptionType];
                break;
            }
        }
        if(capture.mainThread) {
            // filter 只支持 string
            [filter setValue:@"1" forKey:kHMDWPKeyHappenOnMainThread];
        } else {
            [filter setValue:@"0" forKey:kHMDWPKeyHappenOnMainThread];
        }
        
        [filter setValue:capture.protectType forKey:kHMDWPKeyProtectType];
        [filter setValue:capture.protectSelector forKey:kHMDWPKeyProtectSelector];
        [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"HMDWatchdogProtect" backtracesArray:backtraces customParams:[custom copy] filters:filter callback:^(NSError * _Nullable error) {
            if (error) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDWP] upload user exception failed with error %@", error);
            }
        }];
        
//        NSString *reason = @"卡死保护";
//        NSDictionary *category = @{@"reason":reason};
//        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:, @"hmd_app_relaunch_reason", nil, category, nil);
//        BDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDWP] application relaunch reason: %@", reason);
    }
}

#pragma mark - HMDExceptionReporterDelegate

- (NSArray *)pendingNormalExceptionData {
    return nil;
}

- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    return nil;
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    return;
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (!isSuccess) {
        return;
    }
    
    if (_andConditions) {
        [[Heimdallr shared].database deleteObjectsFromTable:[self tableName]
                                              andConditions:_andConditions
                                               orConditions:nil
                                                      limit:kHMDWatchdogProtectUploadLimitCount];
    }
}

#pragma mark - Private

- (NSString *)tableName {
    return [[self storeClass] tableName];
}

- (void)updateTypeList:(NSArray<NSString *>*)typeList {
    HMDWatchdogProtectManager *manager = [HMDWatchdogProtectManager sharedInstance];
    NSDictionary *localTypes = [manager getLocalTypes];
    
    if ([localTypes valueForKey:HMDWPUIPasteboardKey]) {
        if ([localTypes hmd_boolForKey:HMDWPUIPasteboardKey]) {
            manager.UIPasteboardProtect = YES;
        }
        else {
            manager.UIPasteboardProtect = NO;
        }
    }
    else {
        if ([typeList containsObject:HMDWPUIPasteboardKey]) {
            manager.UIPasteboardProtect = YES;
        }
        else {
            manager.UIPasteboardProtect = NO;
        }
    }
    
    if ([localTypes valueForKey:HMDWPUIApplicationKey]) {
        if ([localTypes hmd_boolForKey:HMDWPUIApplicationKey]) {
            manager.UIApplicationProtect = YES;
        }
        else {
            manager.UIApplicationProtect = NO;
        }
    }
    else {
        if ([typeList containsObject:HMDWPUIApplicationKey]) {
            manager.UIApplicationProtect = YES;
        }
        else {
            manager.UIApplicationProtect = NO;
        }
    }
    
    if ([localTypes valueForKey:HMDWPYYCacheKey]) {
        if ([localTypes hmd_boolForKey:HMDWPYYCacheKey]) {
            manager.YYCacheProtect = YES;
        }
        else {
            manager.YYCacheProtect = NO;
        }
    }
    else {
        if ([typeList containsObject:HMDWPYYCacheKey]) {
            manager.YYCacheProtect = YES;
        }
        else {
            manager.YYCacheProtect = NO;
        }
    }
    
    if ([localTypes valueForKey:HMDWPNSUserDefaultKey]) {
        if ([localTypes hmd_boolForKey:HMDWPNSUserDefaultKey]) {
            manager.NSUserDefaultProtect = YES;
        }
        else {
            manager.NSUserDefaultProtect = NO;
        }
    }
    else {
        if ([typeList containsObject:HMDWPNSUserDefaultKey]) {
            manager.NSUserDefaultProtect = YES;
        }
        else {
            manager.NSUserDefaultProtect = NO;
        }
    }
}

@end
