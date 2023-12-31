//
//  HMDCrashConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDANRConfig.h"
#import "HMDANRTracker.h"
#import "NSObject+HMDAttributes.h"
#import "HMDModuleConfig+StartWeight.h"
#import "HMDANRMonitor.h"
#import "hmd_section_data_utility.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDANRTracker2.h"

NSString *const kHMDModuleANRTracker = @"lag";

HMD_MODULE_CONFIG(HMDANRConfig)

@implementation HMDANRConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(timeoutInterval, timeout_interval, @(HMDANRDefaultTimeoutInterval), @(HMDANRDefaultTimeoutInterval))
        HMD_ATTR_MAP(maxUploadCount, max_upload_count)
        HMD_ATTR_MAP_DEFAULT(enableSample, enable_sample, @(HMDANRDefaultEnableSample), @(HMDANRDefaultEnableSample))
        HMD_ATTR_MAP_DEFAULT(sampleInterval, sample_interval, @(HMDANRDefaultSampleInterval), @(HMDANRDefaultSampleInterval))
        HMD_ATTR_MAP_DEFAULT(sampleTimeoutInterval, sample_timeout_interval, @(HMDANRDefaultSampleTimeoutInterval), @(HMDANRDefaultSampleTimeoutInterval))
        HMD_ATTR_MAP_DEFAULT(ignoreBackground, ignore_background, @(HMDANRDefaultIgnoreBackground), @(HMDANRDefaultIgnoreBackground))
        HMD_ATTR_MAP_DEFAULT(ignoreDuplicate, ignore_duplicate, @(HMDANRDefaultIgnoreDuplicate), @(HMDANRDefaultIgnoreDuplicate))
        HMD_ATTR_MAP_DEFAULT(ignoreBacktrace, ignore_backtrace, @(HMDANRDefaultIgnoreBacktrace), @(HMDANRDefaultIgnoreBacktrace))
        HMD_ATTR_MAP_DEFAULT(suspend, threads_suspend, @(HMDANRDefaultSuspend), @(HMDANRDefaultSuspend))
        HMD_ATTR_MAP_DEFAULT(launchThreshold, launch_threshold, @(HMDANRDefaultLaunchInterval), @(HMDANRDefaultLaunchInterval))
        HMD_ATTR_MAP_DEFAULT(maxContinuousReportTimes, max_continuous_report_times, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(enableRunloopMonitorV2, enable_runloop_monitor_v2, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(runloopMonitorThreadSleepInterval, runloop_monitor_thread_sleep_interval, @(50), @(50))
    };
}

+ (NSString *)configKey {
    return kHMDModuleANRTracker;
}

- (id<HeimdallrModule>)getModule {
    return hermas_enabled() ? [HMDANRTracker2 sharedTracker] : [HMDANRTracker sharedTracker];
}

- (BOOL)isValid {
    return self.timeoutInterval > 0;
}

- (BOOL)canStart {
    //由于性能问题，开启和上传绑定到一起
    return self.enableOpen && self.enableUpload;
}

- (HMDModuleStartWeight)startWeight {
    return HMDLagModuleStartWeight;
}

@end
