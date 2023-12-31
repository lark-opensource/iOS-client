//
//  HMDCrashKit.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashKit.h"
#include <stdatomic.h>

#include "HMDCrashDebugAssert.h"

#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Private.h"
#import "HMDCrashEnviroment.h"
#import "HMDCrashDetect.h"
#import "HMDCrashImages.h"
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

void WEAK_FUNC zipAndUploadCoreDump(void) {}

@interface HMDCrashKit ()

@property (nonatomic,strong) NSDictionary *extraMetaData;
#if !SIMPLIFYEXTENSION
@property (nonatomic,strong) HMDCrashUploader *uploader;
#endif
@property(nonatomic, copy) NSString *commitID;
@property(nonatomic, copy) NSString *sdkVersion;
@property (nonatomic,assign) BOOL needEncrypt;
@property (nonatomic,assign) NSTimeInterval launchCrashThreshold;
@property (nonatomic,assign) BOOL lastTimeCrash;
@property(nonatomic, weak) id networkProvider;
@property (nonatomic,strong) dispatch_queue_t dynamicDataQueue;

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
    DEBUG_ACTION([self.class DEBUG_launchTime]);
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        
        hmd_async_enable_compact_unwind();
        
        hmd_init_objc_metaclass();
        
        hmdbt_init_app_main_addr();
                
        [HMDCrashDirectory setup]; //setup all directory
        
        BOOL launchCrash = [HMDCrashDirectory checkAndMarkLaunchState];
        
        [HMDCrashEnviroment setup]; // setup fd and metadata
        setImageFD(HMDCrashEnviroment.image_fd);
        
        HMDCrashStartDetect();
        
        if (hmd_crash_switch_state(HMDCrashSwitchContentAnalysis)) {
            HMDInitWriteContentTypes(HMDObjCClassTypeArray | HMDObjCClassTypeDictionary | HMDObjCClassTypeString);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (!hmd_crash_switch_state(HMDCrashSwitchWriteImageOnCrash)) {
                setupWithFD();
                SDKLog("binary images setup finish");
            }
            hmdcrash_init_filename();
        });
        
        BOOL crashed = HMDCrashDirectory.lastTimeCrash;
        self.lastTimeCrash = crashed;
#if !SIMPLIFYEXTENSION
        void(^processCrashlog)(void) = ^{
            HMDCrashlogProcessor *processor = [[HMDCrashlogProcessor alloc] init];
            processor.needEncrypt = self.needEncrypt;
            processor.launchCrashThreshold = self.launchCrashThreshold;
            [processor startProcess:crashed];
            
            self.uploader = [[HMDCrashUploader alloc] initWithPath:HMDCrashDirectory.preparedDirectory];
            if (processor.crashReport) {
                [self.uploader setLastCrashTimestamp:processor.crashReport.time];
            }
            if (![HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
                [self.uploader uploadCrashLogIfNeeded];
            }
            
            // Always give outer the information about last time (whether crash or not)
            if (crashed) {
                HMDCrashReportInfo *crashReport = processor.crashReport;
                if ([self.delegate respondsToSelector:@selector(crashKitDidDetectCrashForLastTime:)]) {
                    [self.delegate crashKitDidDetectCrashForLastTime:crashReport];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(crashKitDidNotDetectCrashForLastTime)]) {
                    [self.delegate crashKitDidNotDetectCrashForLastTime];
                }
            }
            
            zipAndUploadCoreDump();
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
    }
    DEBUG_ACTION([self.class DEBUG_displayInformation]);
}

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
+ (void)DEBUG_displayInformation {
    HMDLog(@"[%@] LaunchTime: %fms",NSStringFromClass(self),(HMD_XNUSystemCall_timeSince1970() - launchTime)*1000);
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
