//
//  WCMemoryStatConfig.m
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import "MMMemoryStatConfig.h"
#include <mach/mach.h>

@implementation MMMemoryStatConfig

+ (MMMemoryStatConfig *)defaultConfiguration {
    MMMemoryStatConfig *config = [[MMMemoryStatConfig alloc] init];
    config.skipMinMallocSize = (int)vm_page_size;
    config.skipMaxStackDepth = 8;
    config.dumpCallStacks = 1;
    return config;
}

@end

