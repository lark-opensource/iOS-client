//
//  HMDCrashProcessState.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashProcessState.h"
#import <mach/mach_init.h>

@implementation HMDCrashProcessState

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
        
    if ([dict hmd_hasKey:@"free_bytes"]) {
        self.freeBytes = [dict hmd_unsignedIntegerForKey:@"free_bytes"];
        self.appUsedBytes = [dict hmd_unsignedIntegerForKey:@"app_used_bytes"];
        self.totalBytes = [dict hmd_unsignedIntegerForKey:@"total_bytes"];
        self.usedBytes = [dict hmd_unsignedIntegerForKey:@"used_bytes"];
        self.usedVirtualMemory = [dict hmd_unsignedIntegerForKey:@"used_virtual_memory"];
        self.totalVirtualMemory = [dict hmd_unsignedIntegerForKey:@"total_virtual_memory"];
    } else {
        //兼容旧版本数据，之后会删掉
        NSUInteger free = [dict hmd_unsignedIntegerForKey:@"free"];
        NSUInteger footprint = [dict hmd_unsignedIntegerForKey:@"footprint"];
        self.freeBytes = free * vm_kernel_page_size;
        self.appUsedBytes = footprint;
    }
}

@end
