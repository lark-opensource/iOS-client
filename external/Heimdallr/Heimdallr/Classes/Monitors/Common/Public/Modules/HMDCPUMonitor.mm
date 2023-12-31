//
//  HMDCPUMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDSessionTracker.h"
#import "HMDCPUMonitor.h"
#import "HMDMonitor+Private.h"
#import <mach/mach.h>
#import "HMDMonitorRecord+DBStore.h"
#import "HMDCPUMonitorRecord.h"
#import "HMDPerformanceReporter.h"
#import "hmd_section_data_utility.h"
#import "HMDAsyncThread.h"
#import "NSDictionary+HMDSafe.h"
#import "NSObject+HMDAttributes.h"
#import "HMDDynamicCall.h"
#include <float.h>
#import "HMDCPUTimeDetector.h"
#import "HMDCPUUtilties.h"

typedef struct hmd_app_cpu_usage {
    long user_time;        /* user run time */
    long system_time;    /* system run time */
    float cpu_usage;        /* cpu usage percentage */
}hmd_app_cpu_usage;

NSString *const kHMDModuleCPUMonitor = @"cpu";

HMD_MODULE_CONFIG(HMDCPUMonitorConfig)

@implementation HMDCPUMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableThreadCPU, enable_thread_cpu, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleCPUMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDCPUMonitor sharedMonitor];
}

@end

@interface HMDCPUMonitor ()
{
    
}
@end
@implementation HMDCPUMonitor
SHAREDMONITOR(HMDCPUMonitor)

- (Class<HMDRecordStoreObject>)storeClass
{
    return [HMDCPUMonitorRecord class];
}

- (void)start {
    [super start];
    [[HMDCPUTimeDetector sharedDetector] start];
}

- (void)stop {
    [super stop];
    [[HMDCPUTimeDetector sharedDetector] stop];
}

- (HMDMonitorRecord *)refresh
{
    if(!self.isRunning) {
        return nil;
    }
    HMDCPUMonitorRecord *record = [self cpuUsageInfoWithoutAPPUsage];
    NSMutableDictionary *threadInfo = [NSMutableDictionary dictionary];
    BOOL enableThread = NO;
    if ([self.config isKindOfClass:[HMDCPUMonitorConfig class]]) {
        enableThread = ((HMDCPUMonitorConfig *)self.config).enableThreadCPU;
    }
    hmd_app_cpu_usage cpu_usage = [self appCpuInfoWithTheadInfo:threadInfo threadRecord:enableThread];
    record.appUsage = cpu_usage.cpu_usage;
    if (enableThread) {
        record.threadDict = [threadInfo copy];
        HMDCPUMonitorRecord *threadRecord = [record copy];
        threadRecord.service = @"cpu_thread";
        [self.curve pushRecord:threadRecord];
    }

    [self.curve pushRecord:record];

    return record;
}

- (HMDCPUMonitorRecord *)cpuUsageInfoWithoutAPPUsage {
    return [[self class] cpuUsageInfoWithCustomScene:self.customSceneStr];
}

- (hmd_app_cpu_usage)appCpuInfoWithTheadInfo:(NSMutableDictionary *)threadInfo threadRecord:(BOOL)enableThreadCPU;
{
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_basic_info_t basic_info_th;
    hmd_app_cpu_usage app_cpu_usage = {};
    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return app_cpu_usage;
    }

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    // for each thread
    for (int idx = 0; idx < (int)thread_count; idx++) {
        thread_info_count = THREAD_INFO_MAX;
        thread_t thread_mach_port = thread_list[idx];
        kr = thread_info(thread_mach_port, THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return app_cpu_usage;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            app_cpu_usage.user_time += basic_info_th->user_time.seconds;
            app_cpu_usage.system_time += basic_info_th->system_time.seconds;
            float thread_cpu_usage = basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
            app_cpu_usage.cpu_usage += thread_cpu_usage;

            if (enableThreadCPU) {
                char cThreadName[256] = {0};
                hmdthread_getName(thread_mach_port, cThreadName, sizeof(cThreadName));
                if (strlen(cThreadName) > 0 && strcmp(cThreadName, "null") != 0) {
                    NSString *threadNameStr = [NSString stringWithUTF8String:cThreadName];
                    [threadInfo hmd_setObject:@(thread_cpu_usage) forKey:threadNameStr];
                }
            }
        }
    }

    for(size_t index = 0; index < thread_count; index++)
        mach_port_deallocate(mach_task_self(), thread_list[index]);
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    NSAssert(kr == KERN_SUCCESS,@"The return value is illegal!");
    return app_cpu_usage;
}

#pragma mark HeimdallrModule
- (void)updateConfig:(HMDModuleConfig *)config
{
    [super updateConfig:config];
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityCPUMonitor;
}

- (void)enterCustomSceneWithUniq:(NSString *_Nonnull)scene {
    [self enterCustomScene:scene];
}

- (void)leaveCustomSceneWithUniq:(NSString *_Nonnull)scene {
    [self leaveCustomScene:scene];
}

#pragma mark class method

+ (nonnull HMDCPUMonitorRecord *)cpuUsageInfo {
    // device
    HMDCPUMonitorRecord *record = [self cpuUsageInfoWithCustomScene:nil];
    // app
    record.appUsage = hmdCPUUsageFromThread()/100.0f;
    return record;
}

+ (HMDCPUMonitorRecord *)cpuUsageInfoWithCustomScene:(NSString *)customScene {
    mach_msg_type_number_t  count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t kr;
    static host_cpu_load_info_data_t pre_cpu_load_info;
    host_cpu_load_info_data_t cpu_load_info;

    mach_port_t host_port = mach_host_self();
    kr = host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load_info, &count);
    mach_port_deallocate(mach_task_self(), host_port);
    if (kr != KERN_SUCCESS) {
        return nil;
    }

    natural_t user_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_USER] - pre_cpu_load_info.cpu_ticks[CPU_STATE_USER];
    natural_t system_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM] - pre_cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_IDLE] - pre_cpu_load_info.cpu_ticks[CPU_STATE_IDLE];
    natural_t nice_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_NICE] - pre_cpu_load_info.cpu_ticks[CPU_STATE_NICE];

    pre_cpu_load_info = cpu_load_info;

    natural_t total_cpu = user_cpu_differ + system_cpu_differ + idle_cpu_differ + nice_cpu_differ;

    HMDMonitorRecordValue userUsage = 0;
    if (user_cpu_differ > 0 && total_cpu > 0) {
        userUsage = user_cpu_differ/(HMDMonitorRecordValue)total_cpu;
    }
    HMDMonitorRecordValue systemUsage = 0;
    if (system_cpu_differ > 0 && total_cpu > 0) {
        systemUsage = system_cpu_differ/(HMDMonitorRecordValue)total_cpu;
    }
    HMDMonitorRecordValue idle = 0;
    if (idle_cpu_differ > 0 && total_cpu > 0) {
        idle = idle_cpu_differ/(HMDMonitorRecordValue)total_cpu;
    }
    HMDMonitorRecordValue niceUsage = 0;
    if (nice_cpu_differ > 0 && total_cpu > 0) {
        niceUsage = nice_cpu_differ/(HMDMonitorRecordValue)total_cpu;
    }
    HMDMonitorRecordValue total = userUsage + systemUsage + niceUsage;

    HMDCPUMonitorRecord *record = [HMDCPUMonitorRecord newRecord];
    record.service = @"cpu";
    record.userUsage = userUsage;
    record.systemUsage = systemUsage;
    record.idle = idle;
    record.nice = niceUsage;
    record.totalUsage = total;
    record.customScene = customScene;
    record.isBackground = [HMDSessionTracker currentSession].backgroundStatus;
    
    return record;
}

@end
