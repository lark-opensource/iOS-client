//
//  HMDWatchDogConfig
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDWatchDogConfig.h"
#import "HMDWatchDogTracker.h"
#import "NSObject+HMDAttributes.h"
#import "HMDModuleConfig+StartWeight.h"
#import "HMDWatchDog.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleWatchDogKey = @"watch_dog";

HMD_MODULE_CONFIG(HMDWatchDogConfig)

@implementation HMDWatchDogConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT2(timeoutInterval, timeout_duration, @(HMDWatchDogDefaultTimeoutInterval), watchdog_timeout_duration, @(HMDWatchDogDefaultTimeoutInterval))
        HMD_ATTR_MAP_DEFAULT2(sampleInterval, accuracy, @(HMDWatchDogDefaultSampleInterval), watchdog_accuracy, @(HMDWatchDogDefaultSampleInterval))
        HMD_ATTR_MAP_DEFAULT2(lastThreadsCount, last_threads_count, @(HMDWatchdogDefaultLastThreadsCount), watchdog_last_threads_count, @(HMDWatchdogDefaultLastThreadsCount))
        HMD_ATTR_MAP_DEFAULT(launchCrashThreshold, launch_crash_threshold, @(HMDWatchDogDefaultLaunchCrashThreshold), @(HMDWatchDogDefaultLaunchCrashThreshold))
        HMD_ATTR_MAP_DEFAULT2(suspend, threads_suspend, @(HMDWatchDogDefaultSuspend), watchdog_threads_suspend, @(HMDWatchDogDefaultSuspend))
        HMD_ATTR_MAP_DEFAULT2(ignoreBackground, ignore_background, @(HMDWatchDogDefaultIgnoreBackground), watchdog_ignore_background, @(HMDWatchDogDefaultIgnoreBackground))
        HMD_ATTR_MAP_DEFAULT(uploadAlog, upload_alog, @(HMDWatchDogDefaultUploadAlog), @(HMDWatchDogDefaultUploadAlog))
        HMD_ATTR_MAP_DEFAULT(uploadMemoryLog, upload_memory_log, @(HMDWatchDogDefaultUploadMemoryLog), @(HMDWatchDogDefaultUploadMemoryLog))
        HMD_ATTR_MAP_DEFAULT(raiseMainThreadPriority, raise_main_thread_priority, @(HMDWatchDogDefaultRaiseMainThreadPriority), @(HMDWatchDogDefaultRaiseMainThreadPriority))
        HMD_ATTR_MAP_DEFAULT(raiseMainThreadPriorityInterval, raise_main_thread_priority_interval, @(HMDWatchdogDefaultRaiseMainThreadPriorityInterval), @(HMDWatchdogDefaultRaiseMainThreadPriorityInterval))
        HMD_ATTR_MAP_DEFAULT_TOB(alogCrashBeforeTime, alog_crash_before_time, @(300))
        HMD_ATTR_MAP_TOB(currentAppID, currentAid)
        HMD_ATTR_MAP_DEFAULT_TOB(ignoreTerminating, enable_ignore_exit, @(NO))
        HMD_ATTR_MAP_DEFAULT(enableRunloopMonitorV2, enable_runloop_monitor_v2, @(HMDWatchDogEnableRunloopMonitorV2), @(HMDWatchDogEnableRunloopMonitorV2))
        HMD_ATTR_MAP_DEFAULT(runloopMonitorThreadSleepInterval, runloop_monitor_thread_sleep_interval, @(HMDWatchDogRunloopMonitorThreadSleepInterval), @(HMDWatchDogRunloopMonitorThreadSleepInterval))
        HMD_ATTR_MAP_DEFAULT(enableMonitorCompleteRunloop, enable_monitor_complete_runloop, @(HMDWatchDogDefaultEnableMonitorCompleteRunloop), @(HMDWatchDogDefaultEnableMonitorCompleteRunloop))
    };
}

+ (NSString *)configKey {
    return kHMDModuleWatchDogKey;
}

- (id<HeimdallrModule>)getModule {
    return [HMDWatchDogTracker sharedTracker];
}


- (BOOL)isValid {
    return self.timeoutInterval > 0;
}

- (BOOL)enableUpload {
    //只要出现问题就上报
    return YES;
}

- (HMDModuleStartWeight)startWeight {
    return HMDWatchDogModuleStartWeight;
}

@end
