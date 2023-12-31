//
//  HMDCrashKit.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"
#include <stdatomic.h>

#import "HMDMacro.h"

#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Path.h"
#import "HMDCrashDirectory+Private.h"
#import "HMDCrashEnviroment.h"
#import "HMDCrashDetect.h"
#if !SIMPLIFYEXTENSION
#import "HMDCrashlogProcessor.h"
#import "HMDCrashUploader.h"
#import "HMDCrashEventLogger.h"
#endif
#import "HMDCrashSDKLog.h"
#include "HMDCompactUnwind.hpp"
#import "HMDCrashDynamicData.h"
#import "HMDObjcRuntime.h"
#import <objc/runtime.h>
#import "HMDCrashRegionFile.h"
#import "HMDCrashContentAnalyze.h"
#import "HMDCrashKitSwitch.h"
#include "HMDCrashHeader.h"
#import "HMDInjectedInfo.h"
#import "hmd_thread_backtrace.h"

void WEAK_FUNC HMDCoreDump_triggerUpload(void) {}

@interface HMDCrashKit ()

@property (nonatomic,strong) NSDictionary *extraMetaData;
#if !SIMPLIFYEXTENSION
@property (nonatomic,strong) id<HMDCrashUploader> uploader;
#endif
@property(nonatomic, copy) NSString *commitID;
@property(nonatomic, copy) NSString *sdkVersion;
@property (nonatomic,assign) BOOL needEncrypt;
@property (nonatomic,assign) NSTimeInterval launchCrashThreshold;
@property (nonatomic,assign) BOOL lastTimeCrash;
@property(nonatomic, weak) id networkProvider;
@property (nonatomic,strong) dispatch_queue_t dynamicDataQueue;
@property (nonatomic, readwrite) NSUInteger lastCrashUsedVM;
@property (nonatomic, readwrite) NSUInteger lastCrashTotalVM;

@end

@implementation HMDCrashKit

+ (instancetype)sharedInstance {
    static HMDCrashKit *kit;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kit = [[HMDCrashKit alloc] init];
    });
    return kit;
}

- (instancetype)init {
    if (self = [super init]) {
        self.dynamicDataQueue = dispatch_queue_create("com.hmd.dynamic.data.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setup {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    DEBUG_ACTION([self.class DEBUG_launchTime]);
    
    hmd_init_objc_metaclass();
    
    hmdbt_init_app_main_addr();
            
    [HMDCrashDirectory setup]; //setup all directory
    
    BOOL launchCrash = [HMDCrashDirectory checkAndMarkLaunchState];
    
    [HMDCrashEnviroment setup]; // setup fd and metadata
    
    HMDCrashStartDetect();
    
    if (hmd_crash_switch_state(HMDCrashSwitchContentAnalysis)) {
        HMDInitWriteContentTypes(HMDObjCClassTypeArray | HMDObjCClassTypeDictionary | HMDObjCClassTypeString);
    }
    
    self.lastTimeCrash = HMDCrashDirectory.lastTimeCrash;
    
#if !SIMPLIFYEXTENSION
    BOOL lastTimeCrash = self.lastTimeCrash;
    void(^processCrashlog)(void) = ^{
        HMDCrashlogProcessor *processor = [[HMDCrashlogProcessor alloc] init];
        
        processor.needEncrypt = self.needEncrypt;
        processor.launchCrashThreshold = self.launchCrashThreshold;
        [processor startProcess:lastTimeCrash];
        
        self.uploader = [HMDCrashUploader uploaderWithPath:HMDCrashDirectory.preparedDirectory];
        
        HMDCrashReportInfo *crashReport;
        if ((crashReport = processor.crashReport) != nil) {
            
            self.lastCrashUsedVM = crashReport.usedVM;
            self.lastCrashTotalVM = crashReport.totalVM;
            [self.uploader setLastCrashTimestamp:processor.crashReport.time];
        }
        if (![HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
            [self.uploader uploadCrashLogIfNeeded:YES];
        }
        
        // Always give outer the information about last time (whether crash or not)
        if (lastTimeCrash) {
            if ([self.delegate respondsToSelector:@selector(crashKitDidDetectCrashForLastTime:)]) {
                [self.delegate crashKitDidDetectCrashForLastTime:crashReport];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(crashKitDidNotDetectCrashForLastTime)]) {
                [self.delegate crashKitDidNotDetectCrashForLastTime];
            }
        }
        
        HMDCoreDump_triggerUpload();
    };
    
    if (launchCrash || HMDCrashDirectory.urgent) {
        processCrashlog();
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            processCrashlog();
        });
    }
#endif
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [HMDCrashDirectory removeLaunchState];
    });
    SDKLog("HMDCrashKit setup finished");
    
    
    DEBUG_ACTION([self.class DEBUG_displayLaunchTime]);
}

#if !SIMPLIFYEXTENSION
- (void)requestCrashUpload:(BOOL)needSync {
    [self.uploader uploadCrashLogIfNeeded:NO];
}
#endif

+ (void)setExtraMetaData:(NSDictionary *)extraMetaData
{
    [HMDCrashKit sharedInstance].extraMetaData = extraMetaData;
}

+ (NSDictionary *)extraMetaData
{
    return [HMDCrashKit sharedInstance].extraMetaData;
}

#pragma mark description

#ifdef DEBUG

NSTimeInterval HMD_XNUSystemCall_timeSince1970(void);
static NSTimeInterval launchTime;

+ (void)DEBUG_launchTime {
    launchTime = HMD_XNUSystemCall_timeSince1970();
}

+ (void)DEBUG_displayLaunchTime {
    HMDLog(@"[%@] LaunchTime: %.2f ms", NSStringFromClass(self), (HMD_XNUSystemCall_timeSince1970() - launchTime) * 1000);
}
#endif

#pragma mark dynamic data

- (void)setDynamicValue:(NSString *)value key:(NSString *)key {
    if (key == nil) {
        return;
    }
    dispatch_async(self.dynamicDataQueue, ^{
        hmd_crash_init_dynamic_data();
        hmd_crash_store_dynamic_data(key.UTF8String, value.UTF8String);
    });
}

- (void)syncDynamicValue:(NSString *)value key:(NSString *)key {
    if (key == nil) {
        return;
    }
    dispatch_sync(self.dynamicDataQueue, ^{
        hmd_crash_init_dynamic_data();
        hmd_crash_store_dynamic_data(key.UTF8String, value.UTF8String);
    });
}

- (void)removeDynamicValue:(NSString *)key {
    if (key == nil) {
        return;
    }
    dispatch_async(self.dynamicDataQueue, ^{
        hmd_crash_init_dynamic_data();
        hmd_crash_remove_dynamic_data(key.UTF8String);
    });
}

@end
