//
//  SlardarMallocTracker.m
//  SlardarMalloc
//
//  Created by bytedance on 2021/10/18.
//

#import "HMDSlardarMallocTracker.h"
#import "HMDSlardarMallocConfig.h"
#import "HMDMacro.h"
#import "Heimdallr+ModuleCallback.h"
#import "HMDALogProtocol.h"
#import "HMDServiceContext.h"
#import "HMDSlardarMallocOptimizeConfig.h"

static const char* HMDSlardarMallocMMapIdentifier = "slardar_vm_map";
static bool matrix_started = false;
static bool memory_graph_started = false;
static NSString *const HMDMatrixIdentifier = @"matrix";
static NSString *const HMDMemoryGraphIdentifier = @"memory_graph";

typedef NS_ENUM(NSUInteger, SlardarMallocStatus) {
    SlardarMallocStatusDefault,
    SlardarMallocStatusStarted,
    SlardarMallocStatusStoped,
};

#ifdef __cplusplus
extern "C" {
#endif
// matrix
__attribute__ ((weak)) bool slardar_vm_alloc_start(HMDMMapAllocatorConfig config) {
    HMDLog(@"weak function slardar_vm_alloc_start");
    return true;
}
__attribute__ ((weak)) void slardar_vm_alloc_stop() {}
__attribute__ ((weak)) HMDNanoOptimizeResult hmd_nano_zone_optimize_invoke(hmd_nanozone_optimize_config config, uint64_t* duration) {
    HMDLog(@"weak function hmd_nano_zone_optimize_invoke");
    return HMDNanoOptimizeResultDefault;}

#ifdef __cplusplus
} // extern "C"
#endif

static SlardarMallocStatus slardar_malloc_status = SlardarMallocStatusDefault;

static void module_callback(id<HeimdallrModule>  _Nullable hmdModule, BOOL isWorking, HMDModuleConfig* config) {
    
    NSString* moduleName = [hmdModule moduleName];
    if ([moduleName isEqualToString:HMDMatrixIdentifier]) {
        matrix_started = isWorking;
    }
    if ([moduleName isEqualToString:HMDMemoryGraphIdentifier]) {
        memory_graph_started = isWorking;
    }
    
    if (!matrix_started && !memory_graph_started) {
        if (slardar_malloc_status == SlardarMallocStatusStarted) {
            return;
        }
        slardar_malloc_status = SlardarMallocStatusStarted;
        
        HMDSlardarMallocConfig *hmdConfig = (HMDSlardarMallocConfig*)config;
#ifdef HMDBytestDefine
        hmdConfig.remappedTagArray = @"2,3,7,12";
        MemoryAllocatorConfig config = {0};
        config.identifier = HMDSlardarMallocMMapIdentifier;
        config.file_grow_step = 25*HMD_MB;
        config.file_max_size = 200*HMD_MB;
        config.file_initial_size = 25*HMD_MB;
        config.page_aligned = true;
        config.mlockType = HMDMMapMlockTypeDynamicLock;
        config.mlock_slice_count = 1;
        config.remapped_tag_array = strdup((const char*)hmdConfig.remappedTagArray.UTF8String);
        config.need_internal_mutex_lock = true;
#else
        MemoryAllocatorConfig config = {0};
        config.identifier = HMDSlardarMallocMMapIdentifier;
        config.file_grow_step = hmdConfig.fileGrowStep*HMD_MB;
        config.file_max_size = hmdConfig.fileMaxCapacity*HMD_MB;
        config.file_initial_size = hmdConfig.fileInitialSize*HMD_MB;
        config.page_aligned = true;
        config.mlockType = (HMDMMapMlockType)hmdConfig.mlockType;
        config.mlock_slice_count = hmdConfig.mlockSliceCount;
        config.need_internal_mutex_lock = true;
        config.remapped_tag_array = strdup((const char*)hmdConfig.remappedTagArray.UTF8String);
#endif
        CLANG_DIAGNOSTIC_PUSH
        CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
        bool res = slardar_vm_alloc_start(config);
        CLANG_DIAGNOSTIC_POP
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"SlardarMalloc started %@", res?@"success":@"fail");
    }else {
        if (slardar_malloc_status == SlardarMallocStatusStoped) {
            return;
        }
        slardar_malloc_status = SlardarMallocStatusStoped;
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"SlardarMalloc stopped because module %@ is working", moduleName);
        slardar_vm_alloc_stop();
    }
}

static NSString* nano_optimize_result_desc(HMDNanoOptimizeResult result) {
    NSString* desc = @"default";
    switch (result) {
        case HMDNanoOptimizeResultSuccess:
            desc = @"success";
            break;
        case HMDNanoOptimizeResultMmapFail:
            desc = @"mmap fail";
            break;
        case HMDNanoOptimizeResultRemapFail:
            desc = @"remap fail";
            break;
        case HMDNanoOptimizeResultMemcmpFail:
            desc = @"memcmp fail";
            break;
        case HMDNanoOptimizeResultFileOperateFail:
            desc = @"file operate fail";
            break;
        case HMDNanoOptimizeResultNanoVersionNotMatch:
            desc = @"nano zone version match fail";
            break;
        default:
            break;
    }
    return desc;
}

@implementation HMDSlardarMallocTracker {
    BOOL _isInitSlardarMalloc;
}

SHAREDTRACKER(HMDSlardarMallocTracker)

- (void)start {
    [super start];
    
    if (_isInitSlardarMalloc == YES) {
        return;
    }
    _isInitSlardarMalloc = YES;
    
    HMDSlardarMallocConfig *config = (HMDSlardarMallocConfig*)self.config;
    if (config.optimizeType == HMDSlardarMallocOptimizeTypeNano) {
        uint64_t suspend_duration = 0;
        HMDNanoOptimizeResult res = hmd_nano_zone_optimize_invoke({config.nanoZoneOptimizeSize, static_cast<bool>(config.nanoZoneOptimizeNeedMlock)}, config.nanoZoneOptimizeNeedDuration?(&suspend_duration):NULL);
        HMDLog(@"HMDSlardarMalloc nanozone optimize start %@, suspend duration = %lld ms", nano_optimize_result_desc(res), suspend_duration);
        id<HMDTTMonitorServiceProtocol> ttMonitor = hmd_get_heimdallr_ttmonitor();
        NSDictionary *metric = nil;
        if (config.nanoZoneOptimizeNeedDuration) {
            metric = @{@"duration":@(suspend_duration)};
        }
        [ttMonitor hmdTrackService:@"hmd_nanozone_optimize_start" metric:metric category:@{@"result":nano_optimize_result_desc(res)} extra:nil];
    }else if (config.optimizeType == HMDSlardarMallocOptimizeTypeScalable) {
        [self.heimdallr addObserverForModule:HMDMatrixIdentifier usingBlock:^(id<HeimdallrModule>  _Nullable hmdModule, BOOL isWorking) {
            module_callback(hmdModule, isWorking, self.config);
        }];
        [self.heimdallr addObserverForModule:HMDMemoryGraphIdentifier usingBlock:^(id<HeimdallrModule>  _Nullable hmdModule, BOOL isWorking) {
            module_callback(hmdModule, isWorking, self.config);
        }];
    }
}

@end
