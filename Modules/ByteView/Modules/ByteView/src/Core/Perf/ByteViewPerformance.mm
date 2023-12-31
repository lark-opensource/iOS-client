//
//  ByteViewPerformance.c
//  ByteView
//
//  Created by liujianlong on 2021/6/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#include "ByteViewPerformance.h"
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <os/proc.h>
#include "thread_cpu_usage.hpp"

static int64_t memory_used_app() {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (kernelReturn == KERN_SUCCESS) {
        return vmInfo.phys_footprint;
    } else {
        return -1;
    }
}

static int64_t memory_used_system() {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = HOST_VM_INFO_COUNT;
    vm_size_t pagesize = 0;
    vm_statistics_data_t vm_stat;

    if (host_page_size(host_port, &pagesize) != KERN_SUCCESS) {
        return -1;
    }
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        return -1;
    }
    return pagesize * (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count);
}

static int64_t memory_available_used() {
    if (@available(iOS 13.0, *)) {
        return os_proc_available_memory();
    } else {
        return -1;
    }
}

ByteViewMemoryUsage byteview_current_memory_usage(void) {
    ByteViewMemoryUsage usage;
    usage.appUsageBytes = memory_used_app();
    usage.systemUsageBytes = memory_used_system();
    usage.availableUsageBytes = memory_available_used();
    return usage;
}

@implementation ByteViewThreadCPUUsage

- (instancetype)initWithID:(uint64_t)threadID
                     index:(int)index
                  bizScope:(ByteViewThreadBizScope)bizScope
                      name:(NSString*)name
                 queueName:(NSString *)queueName
                     usage:(float)usage {
    if (self = [super init]) {
        _threadID = threadID;
        _index = index;
        _threadName = name;
        _queueName = queueName;
        _cpuUsage = usage;
        _bizScope = bizScope;
    }
    return self;
}

+ (float)appCPU {
    return byteview::ThreadCPUUsage::GetAppCPU();
}

+ (NSArray<ByteViewThreadCPUUsage *> *)threadCPUUsagesTopN:(NSInteger)topN
                                           threadThreshold:(CGFloat)threadThreshold
                                                    rtcCPU:(CGFloat *)rtcCPU
                                                    appCPU:(CGFloat *)appCPU {
    std::vector<byteview::ThreadCPUUsage> usages;
    float appCPUUsage = 0;
    float rtcCPUUsage = -1.0;
    std::tie(usages, appCPUUsage, rtcCPUUsage) = byteview::ThreadCPUUsage::GetThreadUsages((int)topN);
    NSMutableArray<ByteViewThreadCPUUsage *> *bUsages = [[NSMutableArray alloc] initWithCapacity:usages.size()];
    for (auto& usage : usages) {
        if (usage.cpu_usage < threadThreshold) break;
        ByteViewThreadCPUUsage *bUsage = [[ByteViewThreadCPUUsage alloc] initWithID:usage.thread_id
                                                                              index:usage.index
                                                                           bizScope: usage.biz_scope
                                                                               name:[NSString stringWithCString:usage.thread_name.c_str() encoding:NSUTF8StringEncoding]
                                                                          queueName:[NSString stringWithCString:usage.queue_name.c_str() encoding:NSUTF8StringEncoding]
                                                                              usage:usage.cpu_usage];
        [bUsages addObject:bUsage];
    }
    if (appCPU != NULL) {
      *appCPU = appCPUUsage;
    }
    if (rtcCPU != NULL) {
        *rtcCPU = rtcCPUUsage;
    }
    return bUsages;
}

@end
