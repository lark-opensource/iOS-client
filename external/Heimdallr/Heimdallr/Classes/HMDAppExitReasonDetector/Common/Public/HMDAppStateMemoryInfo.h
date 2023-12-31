//
//  HMDAppStateMemoryInfo.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/2/8.
//

#ifndef HMDAppStateMemoryInfo_h
#define HMDAppStateMemoryInfo_h

typedef struct {
    double updateTime;
    uint64_t appMemory;//app占用内存
    uint64_t usedMemory;//设备占用内存
    uint64_t totalMemory;//设备总内存
    uint64_t availableMemory;//设备可用内存
    uint64_t appMemoryPeak;//app最大占用内存
    uint64_t totalVirtualMemory; //app总虚拟内存
    uint64_t usedVirtualMemory; //app占用的虚拟内存
} HMDOOMAppStateMemoryInfo;

#endif /* HMDAppStateMemoryInfo_h */
