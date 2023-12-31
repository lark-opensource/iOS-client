//
//  HMDProtectNano.c
//  Pods
//
//  Created by 白昆仑 on 2020/5/26.
//

#import "HMDProtectNano.h"
#import <stdatomic.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import "HMDALogProtocol.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+SystemInfo.h"

bool HMD_Protect_toggle_Nano_protection(void) {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        if([HMDInfo defaultInfo].cpuType != CPU_TYPE_ARM64) {
            HMDALOG_PROTOCOL_INFO_TAG(@"[Heimdallr][Protect][NanoCrash]", @"Cpu Type is not arm64");
            return false;
        }
        
        NSString *version = [HMDInfo defaultInfo].systemVersion;
        NSComparisonResult rst = [version compare:@"10.0" options:NSNumericSearch];
        if (rst == NSOrderedAscending) {
            HMDALOG_PROTOCOL_INFO_TAG(@"[Heimdallr][Protect][NanoCrash]", @"Current OS Version(%s) < 10.0", version.UTF8String);
            return false;
        }
        
        rst = [version compare:@"10.3" options:NSNumericSearch];
        if (rst != NSOrderedAscending) {
            HMDALOG_PROTOCOL_INFO_TAG(@"[Heimdallr][Protect][NanoCrash]", @"Current OS Version(%s) >= 10.3", version.UTF8String);
            return false;
        }
        
        vm_size_t allocation_size = 1024 * 1024;
        vm_address_t startAddress = (vm_address_t)0x170000000;
        vm_size_t total_alloc_vm_mem = 0;
        while (startAddress < (vm_address_t)0x180000000) {
            kern_return_t kr = vm_allocate(mach_task_self(), &startAddress, allocation_size, false);
            if (kr == KERN_SUCCESS) {
                total_alloc_vm_mem += allocation_size;
            }
            
            startAddress += allocation_size;
        }

        vm_size_t nano_space = 0x10000000;
        double percent = 100 * (double)total_alloc_vm_mem / (double)nano_space;
        HMDALOG_PROTOCOL_INFO_TAG(@"[Heimdallr][Protect][NanoCrash]", @"Allocate 0x%lX(%.2f%%) virtual memory", total_alloc_vm_mem, percent);
        return true;
    }
    
    return false;
}

