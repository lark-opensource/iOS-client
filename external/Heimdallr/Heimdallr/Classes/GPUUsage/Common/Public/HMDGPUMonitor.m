//
//  HMDGPUMonitor.m
//  Heimdallr-8bda3036
//
//  Created by bytedance on 2022/7/25.
//

#import "HMDGPUMonitor.h"
#import "hmd_section_data_utility.h"
#import "HMDMonitor+Private.h"
#import "HMDGPUUsage.h"
#import "HMDCPUUtilties.h"
#import "HMDUITrackerTool.h"
#import "HMDDynamicCall.h"
#import "HMDServiceContext.h"

NSString *const kHMDModuleGPUMonitor = @"gpu";

HMD_MODULE_CONFIG(HMDGPUMonitorConfig)

@implementation HMDGPUMonitorConfig

+ (NSString *)configKey {
    return kHMDModuleGPUMonitor;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDGPUMonitor sharedMonitor];
}

@end

@interface HMDGPUMonitor ()

@property(nonatomic, assign) BOOL stopRecordGPU;

@end

@implementation HMDGPUMonitor

SHAREDMONITOR(HMDGPUMonitor)

- (HMDMonitorRecord *)refresh
{
    if(!self.isRunning) {
        return nil;
    }
    
    // 暂时通过事件埋点上报功耗相关指标
    [self recordProcessingUnitUsage];
    
    return nil;
}

- (void)recordProcessingUnitUsage {
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    NSUInteger processorCount = [[NSProcessInfo processInfo] processorCount];
    double appCPUUsage = hmdCPUUsageFromThread() / 100.f;
    double avgCPUUsage = appCPUUsage / processorCount;
    
    double gpuUsage = 0;
    if (!self.stopRecordGPU) {
        NSError *error = nil;
        gpuUsage = [HMDGPUUsage gpuUsageWithError:&error];
        if (error && error.code != HMDGPUUsageErrorNoError) {
            self.stopRecordGPU = YES;
        }
    }

    NSInteger thermalState;
    if (@available(iOS 11, *)) {
        thermalState = [[NSProcessInfo processInfo] thermalState];
    } else {
        thermalState = -1;
    }
    
    BOOL isLowPowerModel;
    if (@available(iOS 9.0, *)) {
        isLowPowerModel = [[NSProcessInfo processInfo] isLowPowerModeEnabled];
    } else {
        isLowPowerModel = NO;
    }
    
    id<HMDUITrackerManagerSceneProtocol> monitor = hmd_get_uitracker_manager();
    NSString *scene = [monitor scene];
    NSTimeInterval end = NSProcessInfo.processInfo.systemUptime;

    NSMutableDictionary *metric = [NSMutableDictionary new];
    [metric setValue:@(appCPUUsage) forKey:@"total_cpu_usage_rate"];
    [metric setValue:@(avgCPUUsage) forKey:@"avg_cpu_usage_rate"];
    [metric setValue:@(gpuUsage) forKey:@"gpu_usage_rate"];
    [metric setValue:@((end - start) * 1000) forKey:@"sampling_time"];
    NSMutableDictionary *category = [NSMutableDictionary new];
    [category setValue:@(processorCount) forKey:@"cpu_core_num"];
    [category setValue:@(thermalState) forKey:@"thermal_state"];
    [category setValue:@(isLowPowerModel) forKey:@"is_low_power_mode"];
    [category setValue:scene forKey:@"scene"];
    
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hmdTrackService:@"processing_unit_usage" metric:metric category:category extra:nil];
    
}

#pragma mark HeimdallrModule
- (void)updateConfig:(HMDModuleConfig *)config
{
    [super updateConfig:config];
}

@end
