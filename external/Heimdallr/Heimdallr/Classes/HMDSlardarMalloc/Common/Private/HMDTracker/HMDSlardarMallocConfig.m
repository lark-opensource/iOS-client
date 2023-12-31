//
//  SlardarMallocConfig.m
//  SlardarMalloc
//
//  Created by bytedance on 2021/10/18.
//

#import "HMDSlardarMallocConfig.h"
#import "HMDSlardarMallocTracker.h"
#import "NSObject+Attributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleSlardarMalloc = @"slardar_malloc";

HMD_MODULE_CONFIG(HMDSlardarMallocConfig)

@implementation HMDSlardarMallocConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
             HMD_ATTRIBUTE_MAP_DEFAULT(fileMaxCapacity, file_max_size, @(200)),
             HMD_ATTRIBUTE_MAP_DEFAULT(remappedTagArray, remapped_tag_array, @""),
             HMD_ATTRIBUTE_MAP_DEFAULT(fileInitialSize, file_initial_size, @(50)),
             HMD_ATTRIBUTE_MAP_DEFAULT(fileGrowStep, file_grow_step, @(50)),
             HMD_ATTRIBUTE_MAP_DEFAULT(mlockSliceCount, mlock_slice_count, @(2)),
             HMD_ATTRIBUTE_MAP_DEFAULT(mlockType, memory_lock_type, @(1)),
             HMD_ATTRIBUTE_MAP_DEFAULT(optimizeType, optimize_type, @(0)),
             HMD_ATTRIBUTE_MAP_DEFAULT(nanoZoneOptimizeSize, nano_optimize_size, @(64)),
             HMD_ATTRIBUTE_MAP_DEFAULT(nanoZoneOptimizeNeedDuration, nano_optimize_need_duration, @(1)),
             HMD_ATTRIBUTE_MAP_DEFAULT(nanoZoneOptimizeNeedMlock, nano_need_mlock, @(0))
             };
}

+ (NSString *)configKey {
    return kHMDModuleSlardarMalloc;
}

- (id<HeimdallrModule>)getModule {
    return [HMDSlardarMallocTracker sharedTracker];
}

- (HMDSlardarMallocOptimizeType)optimizeType {
    return HMDSlardarMallocOptimizeTypeNano;
}

@end
