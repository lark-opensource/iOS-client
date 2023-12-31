//
//  HMDMemoryGraphConfig.m
//  Pods
//
//  Created by fengyadong on 2020/02/21.
//

#import "HMDMemoryGraphConfig.h"
#import "HMDMemoryGraphGenerator.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleMemoryGraph = @"memory_graph";

HMD_MODULE_CONFIG(HMDMemoryGraphConfig)

@implementation HMDMemoryGraphConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(manualMemoryWarning, manual_memory_warning, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(checkInterval, check_interval, @(5.0), @(5.0))
        HMD_ATTR_MAP_DEFAULT(dangerThresholdMB, danger_threshold_mb, @(1024), @(1024))
        HMD_ATTR_MAP_DEFAULT(growingStepMB, growing_step_mb, @(200), @(200))
        HMD_ATTR_MAP_DEFAULT(devicePerformanceLevelThreshold, device_performance_level_threshold, @(2), @(2))
        HMD_ATTR_MAP_DEFAULT(minGenerateMinuteInterval, min_generate_minute_interval, @(20), @(20))
        HMD_ATTR_MAP_DEFAULT(maxTimesPerDay, max_times_per_day, @(10), @(10))
        HMD_ATTR_MAP_DEFAULT(minRemainingMemoryMB, min_remaining_memory_mb, @(100), @(100))
        HMD_ATTR_MAP_DEFAULT(maxFileSizeMB, max_file_size_mb, @(250), @(250))
        HMD_ATTR_MAP_DEFAULT(maxPreparedFolderSizeMB, max_prepared_folder_size_mb, @(500), @(500))
        HMD_ATTR_MAP_DEFAULT(enableCPPSymbolicate, enable_cpp_symbolicate, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(timeOutInterval, timeOut_interval, @(8), @(8))
        HMD_ATTR_MAP_DEFAULT(enableLeakNodeCalibration, enable_leak_node_calibration, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(calculateSlardarMallocMemory, calculate_slardar_malloc_memory, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(memorySurgeThresholdMB, memory_surge_threshold_mb, @(300), @(300))
        HMD_ATTR_MAP_DEFAULT(enableCFInstanceSymbolicate, enable_cf_instance_symbolicate, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableCircularReferenceDetect, enable_circular_reference_detect, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleMemoryGraph;
}

- (id<HeimdallrModule>)getModule {
    return [HMDMemoryGraphGenerator sharedGenerator];
}

- (BOOL)isValid {
    BOOL result = self.dangerThresholdMB > 0 && self.growingStepMB > 0 && self.checkInterval > 0 && self.minGenerateMinuteInterval > 0 && self.maxTimesPerDay > 0;
    return result;
}

- (BOOL)canStartTaskIndependentOfStart {
    return YES;
}

@end
