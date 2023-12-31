//
//  HMDGPUUsage.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/7/23.
//

#import "HMDGPUUsage.h"
#include <dlfcn.h>
#import "NSString+HDMUtility.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"

#define GPU_UTILI_KEY(key, value) static NSString *const GPU##key##Key = @ #value;
GPU_UTILI_KEY(DeviceUtilization, Device Utilization %)

typedef char name_t[128];

@interface HMDGPUUsage ()

@property (nonatomic, strong) NSDictionary *_utilizationInfo;

@end

@implementation HMDGPUUsage

+ (NSDictionary *)utilizeDictionaryWithErrorType:(HMDGPUUsageErrorType *)errorType {
#if TARGET_OS_IOS
    mach_port_t iterator;
    NSDictionary *dlsymDict = nil;
    static mach_port_t (*test_HMDGetMatchingService)(mach_port_t master, CFDictionaryRef matching CF_RELEASES_ARGUMENT, mach_port_t * it);
    static mach_port_t *test_kHMDPortDefault;
    static CFMutableDictionaryRef (*test_HMDNameMatching)(const char *name);
    static mach_port_t (*test_HMDFindIteratorNext)(mach_port_t it);
    static kern_return_t (*test_HMDEntryGetSubIterator)(mach_port_t entry, const name_t plane, mach_port_t *it);
    static kern_return_t (*test_HMDObjectRelease)(mach_port_t object);
    static kern_return_t (*test_HMDEntryCreateProperties)(
        mach_port_t entry, CFMutableDictionaryRef * properties, CFAllocatorRef allocator, uint32_t options);
    static NSString *serviceName = @"IOService";

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *methodGetMatchingService = @"IOServiceGetMatchingServices";
        test_HMDGetMatchingService = (mach_port_t (*)(mach_port_t master, CFDictionaryRef matching CF_RELEASES_ARGUMENT, mach_port_t * it))dlsym(RTLD_NEXT, methodGetMatchingService.UTF8String);

        NSString *methodPortDefault = @"kIOMasterPortDefault";
        test_kHMDPortDefault = dlsym(RTLD_NEXT, methodPortDefault.UTF8String);

        NSString *methodNameMatching = @"IOServiceNameMatching";
        test_HMDNameMatching = (CFMutableDictionaryRef (*)(const char *name))dlsym(RTLD_NEXT, methodNameMatching.UTF8String);

        NSString *methodIteratorNext = @"IOIteratorNext";
        test_HMDFindIteratorNext = (mach_port_t (*)(mach_port_t it))dlsym(RTLD_NEXT, methodIteratorNext.UTF8String);

        NSString *MethodGetSubIterator = @"IORegistryEntryGetChildIterator";
        test_HMDEntryGetSubIterator = (kern_return_t (*)(mach_port_t entry, const name_t plane, mach_port_t *it))dlsym(RTLD_NEXT, MethodGetSubIterator.UTF8String);
        

        NSString *methodCreateProperties = @"IORegistryEntryCreateCFProperties";
        test_HMDEntryCreateProperties = (kern_return_t (*)(mach_port_t entry, CFMutableDictionaryRef * properties, CFAllocatorRef allocator, uint32_t options))dlsym(RTLD_NEXT, methodCreateProperties.UTF8String);
        

        NSString *MethodObjRelease = @"IOObjectRelease";
        test_HMDObjectRelease = (kern_return_t (*)(mach_port_t object))dlsym(RTLD_NEXT, MethodObjRelease.UTF8String);
    });


    if (!test_HMDGetMatchingService ||
        !test_kHMDPortDefault ||
        !test_HMDNameMatching ||
        !test_HMDFindIteratorNext ||
        !test_HMDEntryGetSubIterator ||
        !test_HMDEntryCreateProperties ||
        !test_HMDObjectRelease ||
        dlerror() != NULL) {
        *errorType = HMDGPUUsageErrorFuncUnAvailable;
        return nil;
    }

    if (!serviceName) { return nil; }
    if (test_HMDGetMatchingService(*test_kHMDPortDefault, test_HMDNameMatching("sgx"), &iterator) == 0) {
                for (mach_port_t regEntry = test_HMDFindIteratorNext(iterator); regEntry; regEntry = test_HMDFindIteratorNext(iterator)) {

            mach_port_t innerIterator;
                    if (test_HMDEntryGetSubIterator(regEntry, serviceName.UTF8String, &innerIterator) == 0) {

                for (mach_port_t gpuEntry = test_HMDFindIteratorNext(innerIterator); gpuEntry; gpuEntry = test_HMDFindIteratorNext(innerIterator)) {
                    CFMutableDictionaryRef serviceDictionary;
                    if (test_HMDEntryCreateProperties(gpuEntry, &serviceDictionary, kCFAllocatorDefault, kNilOptions) != 0) {
                        test_HMDObjectRelease(gpuEntry);
                    } else {
                        dlsymDict = ((__bridge NSDictionary *) serviceDictionary)[@"PerformanceStatistics"];

                        CFRelease(serviceDictionary);
                        test_HMDObjectRelease(gpuEntry);
                        break;
                    }
                }
                test_HMDObjectRelease(innerIterator);
                test_HMDObjectRelease(regEntry);
                break;
            }
            test_HMDObjectRelease(regEntry);
        }
        test_HMDObjectRelease(iterator);
    }
    return dlsymDict;
#else
    *errorType = HMDGPUUsageErrorTargetNotIOS;
    return nil;
#endif
}

+ (double)gpuUsage {
    return [self gpuUsageWithError:nil];
}

+ (double)gpuUsageWithError:(NSError *__autoreleasing  _Nullable *)error {
    HMDGPUUsageErrorType errorType = HMDGPUUsageErrorNoError;
    NSDictionary *usageDict = [self utilizeDictionaryWithErrorType:&errorType];
    __autoreleasing NSError *GPUError = nil;
    if (!error) {
        error = &GPUError;
    }
    // 执行读取的过程中出现错误
    if (errorType > HMDGPUUsageErrorNoError) {
        *error = [NSError errorWithDomain:@"HMDGPUUsageError: function null or target not iOS" code:errorType userInfo:nil];
        return 0.00;
    }

    // 返回的字典为空 或者 不是不对
    if (!usageDict || ![usageDict isKindOfClass:[NSDictionary class]]) {
        *error = [NSError errorWithDomain:@"HMDGPUUsageError: return dict is nil or not NSDictionary" code:HMDGPUUsageErrorDictNilOrTypeError userInfo:nil];
        return 0.00;
    }

    id usageInfo = [usageDict valueForKey:GPUDeviceUtilizationKey];
    if (usageInfo == nil) { // 读取 Key 对应的内容为 nil
        *error = [NSError errorWithDomain:@"HMDGPUUsageError: the dict return value is nil" code:HMDGPUUsageErrorGPUKeyNil userInfo:nil];
        return  0.00;
    }
    if ([usageInfo isKindOfClass:[NSNumber class]]) {
        return [usageInfo doubleValue] / 100.0;
    }
    if ([usageInfo isKindOfClass:[NSString class]]) {
        return [usageInfo doubleValue] / 100.0;
    }
    // 校验类型不正确
    *error = [NSError errorWithDomain:@"HMDGPUUsageError: the dict return value can not traform double" code:HMDGPUUsageErrorGPUKeyReturnTypeError userInfo:nil];
    return 0.00;
}

@end
