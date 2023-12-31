//
//  HMDGWPASanMonitor.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/9/16.
//

#ifdef RANGERSAPM
#import <HMDGWPASanToB/HMDGWPASanManager.h>
#else
#import <HMDGWPASan/HMDGWPASanManager.h>
#endif

#import <stdint.h>
#import <inttypes.h>
#import <stdatomic.h>

#import "HMDMacro.h"
#import "HMDDiskUsage.h"
#import "HMDDynamicCall.h"
#import "HMDMemoryUsage.h"
#import "HMDMacroManager.h"
#import "HMDALogProtocol.h"
#import "HMDGWPASanConfig.h"
#import "HMDGWPASanMonitor.h"
#import "HMDCrashKitSwitch.h"
#import "HMDMallocHookHelper.h"

#define GWPASanGB UINT64_C(40000000) // 1024^3 1G

static void replaceZoneFunc(malloc_zone_t * _Nonnull mallocZone);

//static NSString * _Nonnull mmapFilePath(void);

#pragma mark - Shared Instance

@implementation HMDGWPASanMonitor {
    atomic_bool _initStarted;
}

+ (instancetype)sharedMonitor {
    static HMDGWPASanMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[HMDGWPASanMonitor alloc] init];
    });
    return monitor;
}

- (instancetype)init {
    if(self = [super init]) {
        atomic_init(&_initStarted, false);
    }
    return self;
}

- (void)start {
    [super start];
    
    bool expected = false;
    if(!atomic_compare_exchange_strong(&_initStarted, &expected, true))
        return;
    
    if(![self supportGWPAsan])
        return;
    
    HMDGWPASanConfig *config = (HMDGWPASanConfig *)self.config;
    
    HMDGWPAsanOption *option = HMDGWPAsanOption.alloc.init;
    
    option.replaceZone = replaceZoneFunc;
    option.sampleRate = config.SampleRate;
    option.useNewAsan = config.useNewGWPAsan;
    
    uint32_t maxAllocation = config.MaxSimultaneousAllocations;
    
    uint32_t debugAllocLimit = 0;
    BOOL canOpenDebug = config.isOpenDebugMode;
    
    if (canOpenDebug) {
        canOpenDebug = [self canOpenDebugMode:&debugAllocLimit];
    }
    
    if (canOpenDebug) {
        uint32_t debugAlloc = config.MaxMapAllocationsDebugMode;
        maxAllocation = MIN(debugAllocLimit, debugAlloc);
    }
    
    option.debugMode = canOpenDebug;
    option.maxAllocation = maxAllocation;
    
    DEBUG_LOG("[GWPAsan] maxAlloc %#" PRIx32 ", debugMode %s, sampleRate %#"
              PRIx32, maxAllocation, canOpenDebug ? "yes" : "no", config.SampleRate);
    
    [HMDGWPASanManager startWithOption:option];
    
    if(!HMDGWPASanManager.starting) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"GWPAsan start failed");
    }
}

- (BOOL)canOpenDebugMode:(uint32_t * _Nonnull)debugAllocationLimit {
    
    DEBUG_ASSERT(debugAllocationLimit != NULL);
    if(debugAllocationLimit == NULL) DEBUG_RETURN(NO);
    
    debugAllocationLimit[0] = 0;
    
    uint64_t freeDiskSpace = [HMDDiskUsage getFreeDiskSpace];
    
    if(freeDiskSpace < 10 * GWPASanGB) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"GWPAsan launch failed, free "
                                  "disk space %#" PRIx64 " is less than 10GB",
                                  freeDiskSpace);
        return NO;
    }
    
    uint64_t totalMemory = hmd_getTotalMemoryBytes();
    
    if(totalMemory < GWPASanGB) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"GWPAsan launch failed, total "
                                  "memory %#" PRIx64 " is less than 1GB", 
                                  totalMemory);
        return NO;
    }
    
    uint32_t maxAlloc = 32 * 1024;  // cost 524 MB
    
    if(totalMemory > 2 * GWPASanGB) {
        maxAlloc =  48 * 1024;      // cost 786 MB
    }
    
    if(totalMemory > 3 * GWPASanGB) {
        maxAlloc = 128 * 1024;      // cost 2GB  (disk space will double)
    }
    
    debugAllocationLimit[0] = maxAlloc;
    
    return YES;
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    
    HMDGWPASanConfig *asanConfig = (HMDGWPASanConfig *)config;
    
    BOOL coredumpIfAsan = asanConfig.coredumpIfAsan;
    if(coredumpIfAsan) {
        
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            DC_OB(DC_CL(HMDCDGenerator, sharedGenerator), prepareCoreDump);
        }
        
        hmd_crash_switch_update(HMDCrashSwitchCoreDumpIfAsan, true);
    } else {
        hmd_crash_switch_update(HMDCrashSwitchCoreDumpIfAsan, false);
    }
}

- (BOOL)supportGWPAsan {
    
    if(@available(iOS 10, *)) {
        // Do nothing
    }
    else {
        return false;
    }
    
    if(HMD_IS_ADDRESS_SANITIZER)
        return false;
    
    // arm64 真机
#if (defined(__arm64__) && defined(TARGET_OS_IPHONE))
    return true;
#endif
    
    return false;
}

#pragma mark - HeimdallrModule

- (BOOL)needSyncStart {
    return NO;
}

@end

static void replaceZoneFunc(malloc_zone_t * _Nonnull mallocZone) {
    manageHookWithMallocZone(mallocZone,
                             HMDMallocHookPriorityHigh,
                             HMDMallocHookTypePartialReplace);
}

//static NSString * _Nonnull mmapFilePath(void) {
//    NSString *tmpPath, *directory, *filePath;
//    
//    tmpPath = NSTemporaryDirectory();
//    directory = [tmpPath stringByAppendingPathComponent:@"GWPASanTmp"];
//    filePath = [directory stringByAppendingPathComponent:@"GWPASanMemoryFile"];
//    
//    return filePath;
//}
