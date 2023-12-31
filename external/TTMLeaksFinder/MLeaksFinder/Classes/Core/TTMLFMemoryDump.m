//
//  MLFMemoryDump.m
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/4/10.
//

#import "TTMLFMemoryDump.h"
#import "TTMLFHeapEnumerator.h"
//#import <Heimdallr/HMDTTMonitor.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <mach/mach.h>
#import "sys/utsname.h"

static const int bytesPerMByte = 1024 * 1024;

@implementation TTMLFMemoryDump

+ (u_int64_t)getAppMemoryBytesAfterIOS9 {
    u_int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte;
}

+ (u_int64_t)getAppMemoryBytesBeforIOS9 {
    int64_t memoryUsageInByte = 0;
    struct task_basic_info taskBasicInfo;
    mach_msg_type_number_t size = sizeof(taskBasicInfo);
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t) &taskBasicInfo, &size);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) taskBasicInfo.resident_size;
    }
    return memoryUsageInByte;
}

+ (u_int64_t)getAppMemoryBytes {
    if (@available(iOS 9.0, *)) {
        return [self getAppMemoryBytesAfterIOS9];
    } else {
        return [self getAppMemoryBytesBeforIOS9];
    }
}

+ (NSString *)machineModel {
    static NSString *machineModel = nil;
    if (!machineModel) {
        struct utsname systemInfo;
        uname(&systemInfo);
        machineModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    }
    return machineModel;
}

+ (NSInteger)deviceMemoryLimit {
    NSString *machineModel = [self machineModel];
    
    // 5、5s、6、6p
    if ([machineModel isEqualToString:@"iPhone5,1"])    return 650;
    if ([machineModel isEqualToString:@"iPhone5,2"])    return 650;
    if ([machineModel isEqualToString:@"iPhone5,3"])    return 650;
    if ([machineModel isEqualToString:@"iPhone5,4"])    return 650;
    if ([machineModel isEqualToString:@"iPhone6,1"])    return 650;
    if ([machineModel isEqualToString:@"iPhone6,2"])    return 650;
    if ([machineModel isEqualToString:@"iPhone7,1"])    return 650;
    if ([machineModel isEqualToString:@"iPhone7,2"])    return 650;
    // 6s、6sp、se
    if ([machineModel isEqualToString:@"iPhone8,1"])    return 1400;
    if ([machineModel isEqualToString:@"iPhone8,2"])    return 1400;
    if ([machineModel isEqualToString:@"iPhone8,4"])    return 1400;
    // 7
    if ([machineModel isEqualToString:@"iPhone9,1"])    return 1400;
    if ([machineModel isEqualToString:@"iPhone9,3"])    return 1400;
    // x
    if ([machineModel isEqualToString:@"iPhone10,3"])   return 1400;
    if ([machineModel isEqualToString:@"iPhone10,6"])   return 1400;
    // 7p
    if ([machineModel isEqualToString:@"iPhone9,2"])    return 2048;
    if ([machineModel isEqualToString:@"iPhone9,4"])    return 2048;
    // 8
    if ([machineModel isEqualToString:@"iPhone10,1"])   return 1400;
    if ([machineModel isEqualToString:@"iPhone10,4"])   return 1400;
    // 8p
    if ([machineModel isEqualToString:@"iPhone10,2"])   return 2048;
    if ([machineModel isEqualToString:@"iPhone10,5"])   return 2048;
    
    return 650;
}

+ (BOOL)isSystemClass:(Class)cls {
    // 目前采用是否在同一个image里来判断是否是自定义类
    static void *p_current_image_class_min_address;
    static void *p_current_image_class_max_address;
    static void *p_NSObject_class_address;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //只处理自定义的类
        p_NSObject_class_address = (__bridge void *)objc_getClass("NSObject");
        const char *image_name = class_getImageName(objc_getClass("MLFMemoryDump"));//暂时用这个类名
        unsigned int class_count = 0;
        const char **class_names = objc_copyClassNamesForImage(image_name, &class_count);
        p_current_image_class_min_address = (__bridge void *)(objc_getClass(class_names[0]));
        p_current_image_class_max_address = (__bridge void *)objc_getClass(class_names[class_count - 1]);
        free(class_names);
    });
    void *class_address = (__bridge void *)cls;
    while (class_address != p_NSObject_class_address && class_address != NULL) {
        // 在当前 image 或者 dylib 里
        if (class_address >= p_current_image_class_min_address && class_address <= p_current_image_class_max_address) {
            return NO;
        }
        
        class_address = (__bridge void *)class_getSuperclass((__bridge Class)class_address);
    }
    return YES;
}

+ (NSDictionary<NSString*,NSNumber*>*)instanceCountsWithIgnoreSystem:(BOOL)ignore {
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    CFMutableDictionaryRef mutableCountsForClasses = CFDictionaryCreateMutable(NULL, classCount, NULL, NULL);
    for (unsigned int i = 0; i < classCount; i++) {
        CFDictionarySetValue(mutableCountsForClasses, (__bridge const void *)classes[i], (const void *)0);
    }
    
    // Enumerate all objects on the heap to build the counts of instances for each class.
    [TTMLFHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if (!ignore || ![self isSystemClass:actualClass]) {
            NSUInteger instanceCount = (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)actualClass);
            instanceCount++;
            CFDictionarySetValue(mutableCountsForClasses, (__bridge const void *)actualClass, (const void *)instanceCount);
        }
    }];
    
    // Convert our CF primitive dictionary into a nicer mapping of class name strings to counts that we will use as the table's model.
    NSMutableDictionary *mutableCountsForClassNames = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < classCount; i++) {
        Class class = classes[i];
        NSUInteger instanceCount = (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)(class));
        if (instanceCount > 0) {
            NSString *className = @(class_getName(class));
            [mutableCountsForClassNames setObject:@(instanceCount) forKey:className];
        }
    }
    free(classes);
    return [mutableCountsForClassNames copy];
}

#pragma mark - public
+ (NSDictionary<NSString*,NSNumber*>*)instanceCountsForClassNames {
    return [self instanceCountsWithIgnoreSystem:NO];
}

+ (void)enableMemoryDumpWithInterval:(NSTimeInterval)interval
                               limit:(NSInteger)countLimit
                        ignoreSystem:(BOOL)ignore {
    
    //TODO：添加开关
    
    interval = MAX(interval, 60);
    if ([self getAppMemoryBytes] > [self deviceMemoryLimit] * bytesPerMByte / 3 * 2) {
        // FLEX 放在主线程做的dump
        NSDictionary *instanceCounts = [self instanceCountsWithIgnoreSystem:ignore];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray *classNames = instanceCounts.allKeys;
            NSArray *filteredClassNames = [classNames sortedArrayUsingComparator:^NSComparisonResult(NSString *className1, NSString *className2) {
                NSNumber *count1 = instanceCounts[className1];
                NSNumber *count2 = instanceCounts[className2];
                // Reversed for descending counts.
                return [count2 compare:count1];
            }];
            NSInteger uploadCount = MIN(countLimit, filteredClassNames.count);
            NSMutableDictionary *filteredCounts = [NSMutableDictionary dictionary];
            for (NSInteger i = 0; i < uploadCount; ++i) {
                NSString *className = filteredClassNames[i];
                [filteredCounts setObject:[instanceCounts objectForKey:className] ?: @(0)
                                   forKey:className];
            }
//            [[HMDTTMonitor defaultManager] hmdTrackService:@"memory_leaks_oom_threshold"
//                                                    metric:nil
//                                                  category:nil
//                                                     extra:filteredCounts];
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self enableMemoryDumpWithInterval:interval limit:countLimit ignoreSystem:ignore];
    });
}

@end
