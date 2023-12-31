//
//  HMDMemoryUsage.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/25.
//

#include <stdint.h>

extern uint64_t HMD_MEMORY_GB;
extern uint64_t HMD_MEMORY_MB;
extern uint64_t HMD_MEMORY_KB;

typedef struct {
    u_int64_t appMemory;//app占用内存
    u_int64_t usedMemory;//设备占用内存
    u_int64_t totalMemory;//设备总内存
    u_int64_t availabelMemory;//设备可用内存
}hmd_MemoryBytes;

typedef struct {
    hmd_MemoryBytes memoryBytes;
    u_int64_t virtualMemory;            //app虚拟内存
    u_int64_t totalVirtualMemory;       //可用的虚拟内存总量
    u_int64_t reserved;                //预留
}hmd_MemoryBytesExtend;

// 合规整改，统一剩余内存与内存容量上报key
#define HMD_Free_Memory_Key @"m_zoom_free"
#define HMD_Total_Memory_Key @"m_zoom_all"
#define HMD_Free_Memory_Percent_key @"m_zoom_percent"

#ifdef __cplusplus
extern "C" {
#endif

    /*
     * 异步信号安全，修改时请慎重
     */
/// WARNING:系统API"host_statistics64"在iOS11系统上会卡1s左右，iOS11主线程单次runloop请勿频繁调用
    extern hmd_MemoryBytes hmd_getMemoryBytes(void);
/// 增加了虚拟内存的用量
    extern hmd_MemoryBytesExtend hmd_getMemoryBytesExtend(void);
/// 主线程单次runloop只获取一次Memory，有缓存，runloop任务结束时调用比较准确，结合上面的方法针对不同需求进行调用
    extern hmd_MemoryBytes hmd_getMemoryBytesPerRunloop(void);
    
/// 包含slardar内存分配器的物理内存，该内存不会被计入app内存中，但是包含了app的数据
    extern hmd_MemoryBytes hmd_getMemoryBytesWithSlardarMallocMemory(void);

/// slardar内存分配器分配的mmap内存，该内存不会被计入app内存中，但是包含了app的数据
    extern uint64_t hmd_getSlardarMallocMemory(void);

    extern u_int64_t hmd_getAppMemoryBytes(void);

    void hmd_setTotalMemoryBytes(uint64_t physical_memory);
    u_int64_t hmd_getTotalMemoryBytes(void);

    u_int64_t hmd_getAppMemoryPeak(void);

    /// 获取设备总内存范围
    int hmd_getTotalMemorySizeLevel(void);
    /// 内存映射关系转换
    /// @param memoryByte 内存
    u_int64_t hmd_calculateMemorySizeLevel(u_int64_t memoryByte);
    u_int64_t hmd_caculateMemorySizeLevel(u_int64_t memoryByte) __attribute__((deprecated("please use hmd_calculateMemorySizeLevel")));

/// app footprint limit, unit byte
    extern uint64_t hmd_getDeviceMemoryLimit(void);

#ifdef __cplusplus
}
#endif
