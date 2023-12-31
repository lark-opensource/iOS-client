//
//  HMDMemoryUsage.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/25.
//

#import "HMDMemoryUsage.h"
#import <TargetConditionals.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <mach/mach_types.h>
#import <mach/vm_statistics.h>
#import <sys/param.h>
#import <stdbool.h>
#import <assert.h>
#import <sys/utsname.h>
#import <stdatomic.h>
#import <sys/sysctl.h>
#import "pthread_extended.h"

#if defined(__LP64__)

#define HMD_HOST_STATISTICS_DATA_T vm_statistics64_data_t
#define HMD_HOST_VM_INFO_COUNT HOST_VM_INFO64_COUNT
#define HMD_HOST_STATISTICS host_statistics64
#define HMD_HOST_INFO_T host_info64_t
#define HMD_VM_INFO HOST_VM_INFO64

#else

#define HMD_HOST_STATISTICS_DATA_T vm_statistics_data_t
#define HMD_HOST_VM_INFO_COUNT HOST_VM_INFO_COUNT
#define HMD_HOST_STATISTICS host_statistics
#define HMD_HOST_INFO_T host_info_t
#define HMD_VM_INFO HOST_VM_INFO

#endif

/// app footprint limit , unit MB
uint64_t hmd_obtainPresetMemoryLimitMBForDeviceModel(const char *deviceModel);
u_int64_t hmd_getTotalMemoryBytes(void);

uint64_t HMD_MEMORY_GB = 1024 * 1024 * 1024;
uint64_t HMD_MEMORY_MB = 1024 * 1024;
uint64_t HMD_MEMORY_KB = 1024;

// 标识符,单次runloop只获取一次内存
static _Atomic(bool) _runloopFlag = false;

static _Atomic(uint64_t) _physical_memory = 0;

static _Atomic(uint64_t) _physical_footprint_peak;

static _Atomic(uint64_t) _physical_footprint_limit;

static _Atomic(uint64_t) _virtual_memory_limit;

//HMD_HOST_STATISTICS() will block on multithread invoke on ios11
static pthread_mutex_t _memoryUsageLockForIOS11;

static bool hmd_isIOS11(void) {
    static bool HMD_isIOS11 = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 12.0, *)) {
            // great or equal to ios12
        }else if (@available(iOS 11.0, *)) {
            // ios 11.0 ..< ios12
            HMD_isIOS11 = true;
            mutex_init_normal(_memoryUsageLockForIOS11);
        }else {
            // ..< ios 11
        }
    });
    return HMD_isIOS11;
}

int hmd_calculateMemorySizeLevel(u_int64_t memoryByte) {
    int memorySizeLevel = (int)ceil(memoryByte/(HMD_MEMORY_MB*30.0));
    return memorySizeLevel;
}

int hmd_caculateMemorySizeLevel(u_int64_t memoryByte) {
    return hmd_calculateMemorySizeLevel(memoryByte);
}

static void hmd_memory_addRunloopObserver() {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAfterWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        _runloopFlag = false;
    });
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

void hmd_setRunloopFlag(bool flag) {
    atomic_store_explicit(&_runloopFlag, flag, memory_order_release);
}

bool hmd_getRunloopFlag(void) {
    bool totalMemory = atomic_load_explicit(&_runloopFlag,memory_order_acquire);
    return totalMemory;
}

void hmd_setVirtualMemoryLimit(uint64_t virtual_memory_limit) {
    atomic_store_explicit(&_virtual_memory_limit, virtual_memory_limit, memory_order_release);
}

uint64_t hmd_getVirtualMemoryLimit(void) {
    uint64_t virtualMemoryLimit = atomic_load_explicit(&_virtual_memory_limit,memory_order_acquire);
    return virtualMemoryLimit;
}

void hmd_setDeviceMemoryLimit(u_int64_t memory_limit) {
    atomic_store_explicit(&_physical_footprint_limit,memory_limit,memory_order_release);
}

uint64_t hmd_getDeviceMemoryLimit(void) {
    uint64_t memory_limit = atomic_load_explicit(&_physical_footprint_limit,memory_order_acquire);
    if (memory_limit == 0) {
        hmd_getMemoryBytesExtend();
        uint64_t memory_limit = atomic_load_explicit(&_physical_footprint_limit,memory_order_acquire);
        if (memory_limit == 0) {
            struct utsname systemInfo;
            if(uname(&systemInfo) == 0) {
                memory_limit = hmd_obtainPresetMemoryLimitMBForDeviceModel(systemInfo.machine)*HMD_MEMORY_MB;
            }else {
                memory_limit = hmd_getTotalMemoryBytes()/2;
            }
            hmd_setDeviceMemoryLimit(memory_limit);
        }
    }
    return memory_limit;
}

hmd_MemoryBytes hmd_getMemoryBytesPerRunloop(void) {
    static hmd_MemoryBytes memory = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_memory_addRunloopObserver();
    });
    if (!hmd_getRunloopFlag()) {
        memory = hmd_getMemoryBytes();
        hmd_setRunloopFlag(true);
    }
    return memory;
}

/// 虚拟内存可能包含reserved size(0xFC0000000 ~ 0x7000000000) https://github.com/apple/darwin-xnu/blob/main/osfmk/arm64/machine_routines.c 搜索"vm_reserved_regions"
u_int64_t hmd_adjustVirtualMemorySize(uint64_t virtual_used_size) {
#if defined (__arm64__)
    static const mach_vm_address_t reserved_size = MACH_VM_MAX_GPU_CARVEOUT_ADDRESS - MACH_VM_MAX_ADDRESS;
    if (virtual_used_size > reserved_size) {
        virtual_used_size -= reserved_size;
    }
#endif
    return virtual_used_size;
}

hmd_MemoryBytesExtend hmd_getMemoryBytesExtend(void) {
    hmd_MemoryBytesExtend memoryExtend = {0};
    //fill total memory
    memoryExtend.memoryBytes.totalMemory = hmd_getTotalMemoryBytes();
    kern_return_t kr;
    
    //fill task vm info
    task_vm_info_data_t task_vm;
    mach_msg_type_number_t task_vm_count = TASK_VM_INFO_COUNT;
    kr = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &task_vm, &task_vm_count);
    if(kr != KERN_SUCCESS) {
        return memoryExtend;
    }
    memoryExtend.virtualMemory = hmd_adjustVirtualMemorySize(task_vm.virtual_size);
    memoryExtend.memoryBytes.appMemory = task_vm.phys_footprint;
    uint64_t physical_footprint_peak = atomic_load_explicit(&_physical_footprint_peak,memory_order_acquire);
    if (physical_footprint_peak < task_vm.phys_footprint) {
        physical_footprint_peak = task_vm.phys_footprint;
        atomic_store_explicit(&_physical_footprint_peak,
                              physical_footprint_peak,
                              memory_order_release);
    }
    
    //剩余的内存是通过total memory计算的，如果total memory为0，则直接return
    if (memoryExtend.memoryBytes.totalMemory == 0) {
#if DEBUG
        assert(0);
#endif
        return memoryExtend;
    }
    //fill host vm info
    HMD_HOST_STATISTICS_DATA_T host_vm;
    mach_msg_type_number_t host_vm_count = HMD_HOST_VM_INFO_COUNT;
    mach_port_t host_port = mach_host_self();
    if (hmd_isIOS11()) {
        pthread_mutex_lock(&_memoryUsageLockForIOS11);
        kr = HMD_HOST_STATISTICS(host_port, HMD_VM_INFO, (HMD_HOST_INFO_T)&host_vm, &host_vm_count);
        pthread_mutex_unlock(&_memoryUsageLockForIOS11);
    }else {
        kr = HMD_HOST_STATISTICS(host_port, HMD_VM_INFO, (HMD_HOST_INFO_T)&host_vm, &host_vm_count);
    }
    mach_port_deallocate(mach_task_self(), host_port);
    
    if (kr != KERN_SUCCESS) {
        return memoryExtend;
    }
    
    // 由于64位系统memory的计算方式中有32位vm_statistics_data_t不包含的成员，故分开处理
#ifdef __LP64__
    // https://github.com/llvm-mirror/lldb/blob/c77a32de1c24775634181d5890567379a3b201aa/tools/debugserver/source/MacOSX/MachTask.mm 搜索’scanType & eProfileMemory‘
    memoryExtend.memoryBytes.usedMemory = ((memoryExtend.memoryBytes.totalMemory / vm_kernel_page_size) - (host_vm.free_count - host_vm.speculative_count) - host_vm.external_page_count - host_vm.purgeable_count) * vm_kernel_page_size;
#else
    // 部分博客提示在32位用此方法计算，尚未找到有力的官方证明，日后找到补上
    memoryExtend.memoryBytes.usedMemory = (host_vm.active_count + host_vm.wire_count + host_vm.inactive_count) * vm_kernel_page_size;
#endif
    
    uint64_t availableMemory = memoryExtend.memoryBytes.totalMemory - memoryExtend.memoryBytes.usedMemory;
    bool limitBytesRemainingEnable = false;
    
#if defined(TASK_VM_INFO_REV2_COUNT) && !TARGET_OS_SIMULATOR
    if (task_vm_count >= TASK_VM_INFO_REV2_COUNT) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            hmd_setVirtualMemoryLimit(task_vm.max_address - task_vm.min_address);
        });
    }
    memoryExtend.totalVirtualMemory = hmd_getVirtualMemoryLimit();
#endif
    
#if defined(TASK_VM_INFO_REV4_COUNT) && !TARGET_OS_SIMULATOR
    // 通过task_vm_count来判断limit_bytes_remaining是否有效
    // limit_bytes_remaining 可参考 os_proc_available_memory 解释
    // min(设备可用内存, 单个app进程最大剩余可用内存)
    if (task_vm_count >= TASK_VM_INFO_REV4_COUNT) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            hmd_setDeviceMemoryLimit(task_vm.phys_footprint+task_vm.limit_bytes_remaining);
        });
        availableMemory = MIN(availableMemory, task_vm.limit_bytes_remaining);
        limitBytesRemainingEnable = true;
    }
#endif
    // 通过测出的jetsam单进程内存上限计算可用内存
    if (!limitBytesRemainingEnable) {
        struct utsname systemInfo;
        if(uname(&systemInfo) == 0) {
            uint64_t limit = hmd_obtainPresetMemoryLimitMBForDeviceModel(systemInfo.machine);
            if (limit) {
                uint64_t remaining = limit * HMD_MEMORY_MB - memoryExtend.memoryBytes.appMemory;
                availableMemory = MIN(availableMemory, remaining);
            }
        }
    }
    
    memoryExtend.memoryBytes.availabelMemory = availableMemory;
        
    return memoryExtend;
}

hmd_MemoryBytes hmd_getMemoryBytes(void) {
    hmd_MemoryBytesExtend extend = hmd_getMemoryBytesExtend();
    return extend.memoryBytes;
}

__attribute__ ((weak)) size_t slardar_malloc_physical_memory_usage(void) {
    return 0;
}

uint64_t hmd_getSlardarMallocMemory(void) {
    return slardar_malloc_physical_memory_usage();
}

hmd_MemoryBytes hmd_getMemoryBytesWithSlardarMallocMemory(void) {
    hmd_MemoryBytes bytes = hmd_getMemoryBytes();
    bytes.appMemory += hmd_getSlardarMallocMemory();
    return bytes;
}

u_int64_t hmd_getAppMemoryBytes(void) {
    u_int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte;
}

void hmd_setTotalMemoryBytes(uint64_t physical_memory) {
    atomic_store_explicit(&_physical_memory,physical_memory,memory_order_release);
}

u_int64_t hmd_getTotalMemoryBytes(void) {
    u_int64_t totalMemory = atomic_load_explicit(&_physical_memory,memory_order_acquire);
    if (totalMemory == 0) {
        size_t size = sizeof(totalMemory);
        int mib[2] = {CTL_HW, HW_MEMSIZE};
        if (sysctl(mib, 2, &totalMemory, &size, NULL, 0) == 0) {
            hmd_setTotalMemoryBytes(totalMemory);
        }
    }
    return totalMemory;
}

int hmd_getTotalMemorySizeLevel(void) {
    u_int64_t totalMemory = hmd_getTotalMemoryBytes();
    return hmd_calculateMemorySizeLevel(totalMemory);
}

u_int64_t hmd_getAppMemoryPeak(void) {
    return atomic_load_explicit(&_physical_footprint_peak,memory_order_acquire);
}

// 辅助计算availableMemory
uint64_t hmd_obtainPresetMemoryLimitMBForDeviceModel(const char *deviceModel) {
    //苹果发布设备型号，时间，架构:https://www.innerfence.com/howto/apple-ios-devices-dates-versions-instruction-sets
    //参考https://stackoverflow.com/questions/5887248/ios-app-maximum-memory-budget
    static uint64_t memoryLimit = 0;
    uint64_t physical_memory = hmd_getTotalMemoryBytes();
    
    if (memoryLimit) return memoryLimit;
    if (deviceModel == NULL) {
        //单进程内存限制取默认取50%的设备内存比较保险
        memoryLimit = (uint64_t)(.5f * physical_memory / HMD_MEMORY_MB);
        return memoryLimit;
    }
    
    //iPhone
    if (strcmp(deviceModel,"iPhone3,1") == 0 || strcmp(deviceModel,"iPhone3,2") == 0 || strcmp(deviceModel,"iPhone3,3") == 0) {
        memoryLimit = 325;
    } else if (strcmp(deviceModel,"iPhone4,1") == 0) {
        memoryLimit = 286;
    } else if (strcmp(deviceModel,"iPhone5,1") == 0 || strcmp(deviceModel,"iPhone5,2") == 0) {
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPhone5,3") == 0 || strcmp(deviceModel,"iPhone5,4") == 0) {
#warning There's no iPhone5C data on stackoverflow
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPhone6,1") == 0 || strcmp(deviceModel,"iPhone6,2") == 0) {
        memoryLimit = 646;
    } else if (strcmp(deviceModel,"iPhone7,2") == 0) {
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPhone7,1") == 0) {
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPhone8,1") == 0) {
        memoryLimit = 1396;
    } else if (strcmp(deviceModel,"iPhone8,2") == 0) {
        memoryLimit = 1392;
    } else if (strcmp(deviceModel,"iPhone8,4") == 0) {
        memoryLimit = 1395;
    } else if (strcmp(deviceModel,"iPhone9,1") == 0 || strcmp(deviceModel,"iPhone9,3") == 0) {
        memoryLimit = 1395;
    } else if (strcmp(deviceModel,"iPhone9,2") == 0 || strcmp(deviceModel,"iPhone9,4") == 0) {
        memoryLimit = 2040;
    } else if (strcmp(deviceModel,"iPhone10,1") == 0 || strcmp(deviceModel,"iPhone10,4") == 0) {
        memoryLimit = 1364;
    } else if (strcmp(deviceModel,"iPhone10,2") == 0 || strcmp(deviceModel,"iPhone10,5") == 0) {
#warning There's no iPhone8Plus data on stackoverflow
        memoryLimit = 1364;
    } else if (strcmp(deviceModel,"iPhone10,3") == 0 || strcmp(deviceModel,"iPhone10,6") == 0) {
        memoryLimit = 1392;
    } else if (strcmp(deviceModel,"iPhone11,8") == 0) {
        memoryLimit = 1792;
    } else if (strcmp(deviceModel,"iPhone11,2") == 0) {
        memoryLimit = 2040;
    } else if (strcmp(deviceModel,"iPhone11,4") == 0 || strcmp(deviceModel,"iPhone11,6") == 0) {
        memoryLimit = 2039;
    } else if (strcmp(deviceModel,"iPhone12,1") == 0) {
        memoryLimit = 2068;
    } else if (strcmp(deviceModel,"iPhone12,3") == 0) {
#warning There's no iPhone11Pro data on stackoverflow
        memoryLimit = 2068;
    } else if (strcmp(deviceModel,"iPhone12,5") == 0) {
        memoryLimit = 2067;
    } else if (strcmp(deviceModel,"iPhone13,1") == 0) {
        memoryLimit = 2098;
    } else if (strcmp(deviceModel,"iPhone13,2") == 0) {
        memoryLimit = 2098;
    } else if (strcmp(deviceModel,"iPhone13,3") == 0) {
        memoryLimit = 2867; //2868/5737
    } else if (strcmp(deviceModel,"iPhone13,4") == 0) {
        memoryLimit = 2867;
    } else if (strcmp(deviceModel, "iPhone14,2") == 0) { // iPhone13 pro
        memoryLimit = 2990;
    } else if (strcmp(deviceModel,"iPad1,1") == 0) {//iPad below
        memoryLimit = 127;
    } else if (strcmp(deviceModel,"iPad2,1") == 0 || strcmp(deviceModel,"iPad2,2") == 0 || strcmp(deviceModel,"iPad2,3") == 0 || strcmp(deviceModel,"iPad2,4") == 0) {
        memoryLimit = 275;
    } else if (strcmp(deviceModel,"iPad2,5") == 0 || strcmp(deviceModel,"iPad2,6") == 0 || strcmp(deviceModel,"iPad2,7") == 0) {
        memoryLimit = 297;
    } else if (strcmp(deviceModel,"iPad3,1") == 0 || strcmp(deviceModel,"iPad3,2") == 0 || strcmp(deviceModel,"iPad3,3") == 0) {
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPad3,4") == 0 || strcmp(deviceModel,"iPad3,5") == 0 || strcmp(deviceModel,"iPad3,6") == 0) {
        memoryLimit = 585;
    } else if (strcmp(deviceModel,"iPad4,1") == 0 || strcmp(deviceModel,"iPad4,2") == 0 || strcmp(deviceModel,"iPad4,3") == 0) {
        memoryLimit = 697;
    } else if (strcmp(deviceModel,"iPad4,4") == 0 || strcmp(deviceModel,"iPad4,5") == 0 || strcmp(deviceModel,"iPad4,6") == 0) {
        memoryLimit = 696;
    } else if (strcmp(deviceModel,"iPad4,7") == 0 || strcmp(deviceModel,"iPad4,8") == 0 || strcmp(deviceModel,"iPad4,9") == 0) {
#warning There's no iPad Mini 3 data on stackoverflow
        memoryLimit = 696;
    } else if (strcmp(deviceModel,"iPad5,1") == 0 || strcmp(deviceModel,"iPad5,2") == 0) {
#warning There's no iPad Mini 4 data on stackoverflow. The total physical memory of the device is 2GB https://arstechnica.com/gadgets/2015/09/ipad-mini-4-performance-preview-a-1-5ghz-apple-a8-with-2gb-of-ram/
        memoryLimit = 1383;
    } else if (strcmp(deviceModel,"iPad5,3") == 0 || strcmp(deviceModel,"iPad5,4") == 0) {
        memoryLimit = 1383;
    } else if (strcmp(deviceModel,"iPad6,3") == 0 || strcmp(deviceModel,"iPad6,4") == 0) {
        memoryLimit = 1395;
    } else if (strcmp(deviceModel,"iPad6,7") == 0 || strcmp(deviceModel,"iPad6,8") == 0) {
        memoryLimit = 3058;
    } else if (strcmp(deviceModel,"iPad6,11") == 0 || strcmp(deviceModel,"iPad6,12") == 0) {
#warning There's no iPad 5 data on stackoverflow
        memoryLimit = 1383;
    } else if (strcmp(deviceModel,"iPad7,1") == 0 || strcmp(deviceModel,"iPad7,2") == 0) {
        memoryLimit = 3057;
    } else if (strcmp(deviceModel,"iPad7,3") == 0 || strcmp(deviceModel,"iPad7,4") == 0) {
        memoryLimit = 3057;
    } else if (strcmp(deviceModel,"iPad7,5") == 0 || strcmp(deviceModel,"iPad7,6") == 0) {
#warning There's no iPad 6 data on stackoverflow
        memoryLimit = 1383;
    } else if (strcmp(deviceModel,"iPad7,11") == 0 || strcmp(deviceModel,"iPad7,12") == 0) {
        memoryLimit = 1844;
    } else if (strcmp(deviceModel,"iPad8,1") == 0 || strcmp(deviceModel,"iPad8,2") == 0 || strcmp(deviceModel,"iPad8,3") == 0 || strcmp(deviceModel,"iPad8,4") == 0) {
        memoryLimit = 2858;
    } else if (strcmp(deviceModel,"iPad8,5") == 0 || strcmp(deviceModel,"iPad8,6") == 0 || strcmp(deviceModel,"iPad8,7") == 0 || strcmp(deviceModel,"iPad8,8") == 0) {
        memoryLimit = 4598;
    } else if (strcmp(deviceModel,"iPad11,1") == 0 || strcmp(deviceModel,"iPad11,2") == 0) {
#warning There's no iPad Mini 5 data on stackoverflow
        memoryLimit = 2040;
    } else if (strcmp(deviceModel,"iPad11,3") == 0 || strcmp(deviceModel,"iPad11,4") == 0) {
#warning There's no iPad Air 3 data on stackoverflow
        memoryLimit = 2040;//iPod below
    } else if (strcmp(deviceModel,"iPod1,1") == 0) {
#warning There's no iPod Touch 1 data on stackoverflow
        memoryLimit = 64;
    } else if (strcmp(deviceModel,"iPod2,1") == 0) {
#warning There's no iPod Touch 2 data on stackoverflow
        memoryLimit = 64;
    } else if (strcmp(deviceModel,"iPod3,1") == 0) {
#warning There's no iPod Touch 3 data on stackoverflow
        memoryLimit = 128;
    } else if (strcmp(deviceModel,"iPod4,1") == 0) {
        memoryLimit = 130;
    } else if (strcmp(deviceModel,"iPod5,1") == 0) {
        memoryLimit = 286;
    }
    else if (strcmp(deviceModel,"iPod7,1") == 0) {
#warning There's no iPod Touch 6 data on stackoverflow
        memoryLimit = 645;
    } else if (strcmp(deviceModel,"iPod9,1") == 0) {
#warning There's no iPod Touch 7 data on stackoverflow
        memoryLimit = 1396;
    }
    else {
        memoryLimit = (uint64_t)(.5f * physical_memory/HMD_MEMORY_MB);
    }
    
    return memoryLimit;
}
