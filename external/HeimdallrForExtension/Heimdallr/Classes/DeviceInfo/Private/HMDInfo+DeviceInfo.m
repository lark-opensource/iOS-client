//
//  HMDInfo+DeviceInfo.m
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo+DeviceInfo.h"
#import <sys/utsname.h>
#include <net/if.h>
#include <net/if_dl.h>
#include "HMDDeviceTool.h"
#include <sys/sysctl.h>
#import "HMDALogProtocol.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDDeviceTool.h"
#import "HMDCompactUnwind.hpp"
#include "HMDEnvCheck.h"
#include "HeimdallrUtilities.h"

#define HMD_DEVICE_DANGEROUS_MEMORY_LIMIT 50

#define CPU_SUBTYPE_ARM64E              ((cpu_subtype_t) 2)

@implementation HMDInfo (DeviceInfo)

- (NSTimeInterval)bootTime {
    struct timeval value = {0};
    size_t size = sizeof(value);
    sysctlbyname("kern.boottime", &value, &size, NULL, 0);
    return value.tv_sec;
}

- (NSString *)deviceName {
  return [UIDevice currentDevice].name;
}

- (NSString *)machineModel {
    return [HMDInfo machineModel];
}

+ (NSString *)machineModel {
    static NSString *machineModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (HeimdallrUtilities.isiOSAppOnMac){
            machineModel = HeimdallrUtilities.modelIdentifier;
        }else{
            struct utsname systemInfo;
            if(uname(&systemInfo) == 0)
                machineModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
            else {
                machineModel = @"unkown";
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[Heimdallr machineModel] uname failed to get system information, err %d", errno);
            }
        }
    });
    return machineModel;
}

- (NSString *)decivceModel {
    NSString *machineModel = [self machineModel];
    return machineModel;
}


- (NSString *)cpuArchitecture {
    char *arch = hmd_cpu_arch(self.cpuType, self.cpuSubType);
    NSString *cpuType = [NSString stringWithUTF8String:arch];
    if (arch) {
        free(arch);
        arch = NULL;
    }
    return cpuType;
}

- (int)cpuType {
  return hmd_kssysctl_int32ForName("hw.cputype");
}

- (int)cpuSubType {
  return hmd_kssysctl_int32ForName("hw.cpusubtype");
}

+ (NSString *)CPUArchForMajor:(cpu_type_t)majorCode minor:(cpu_subtype_t)minorCode
{
    char *arch = hmd_cpu_arch(majorCode, minorCode);
    NSString *cpuType = [NSString stringWithUTF8String:arch];
    if (arch) {
        free(arch);
        arch = NULL;
    }
    return cpuType;
}

- (NSString *)currentLanguage {
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
}

- (NSString *)currentRegion {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

- (BOOL)isEnvAbnormal {
    static BOOL hmd_is_jailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bool is_mac = [HeimdallrUtilities isiOSAppOnMac] ? true : false;
        hmd_is_jailBroken = !hmd_env_regular_check(is_mac);
        if (!hmd_is_jailBroken) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                hmd_is_jailBroken = !hmd_env_image_check();
            });
        }
    });
    
    return hmd_is_jailBroken;
}

- (CGSize)resolution {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float scale = [[UIScreen mainScreen] scale];
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    return resolution;
}


- (NSString *)resolutionString {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    if ([env objectForKey:@"XCTestBundlePath"]) {
        // if the environment is XCTest, we will return "xctest_fake_size"
        return @"xctest_fake_size";
    } else {
        CGSize resolution = [self resolution];
        return [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
    }
}

- (NSString *)countryCode {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

//api取到的容量比实际RAM容量略小https://stackoverflow.com/questions/43706883/ios-difference-between-actual-ram-and-processinfo-processinfo-physicalmemory-sta
- (HMDDevicePerformanceLevel)devicePerformaceLevel {
    static NSUInteger level = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned long long devicePysicalMemory = [NSProcessInfo processInfo].physicalMemory;
        if(devicePysicalMemory < 512L * 1024L * 1024L) {
            level = HMDDevicePerformanceLevelPoorest;
        } else if (devicePysicalMemory < 1024L * 1024L * 1024L) {
            level = HMDDevicePerformanceLevelPoor;
        } else if (devicePysicalMemory < 3L * 1024L * 1024L * 1024L) {
            level = HMDDevicePerformanceLevelMedium;
        } else if (devicePysicalMemory < 5L * 1024L * 1024L * 1024L) {
            level = HMDDevicePerformanceLevelHigh;
        } else {
            level =HMDDevicePerformanceLevelHighest;
        }
    });
    
    return level;
}

-(BOOL)isMacARM{
    return HeimdallrUtilities.isiOSAppOnMac;
}

@end

char *hmd_system_cpu_arch(void) {
    int cpuType = hmd_kssysctl_int32ForName("hw.cputype");
    int cpuSubType = hmd_kssysctl_int32ForName("hw.cpusubtype");
    return hmd_cpu_arch(cpuType, cpuSubType);
}

char *hmd_cpu_arch(cpu_type_t majorCode, cpu_subtype_t minorCode) {
    minorCode = minorCode & ~CPU_SUBTYPE_MASK;
    switch(majorCode) {
        case CPU_TYPE_ARM: {
            switch (minorCode) {
                case CPU_SUBTYPE_ARM_V6:
                    return strdup("armv6");
                case CPU_SUBTYPE_ARM_V7:
                    return strdup("armv7");
                case CPU_SUBTYPE_ARM_V7F:
                    return strdup("armv7f");
                case CPU_SUBTYPE_ARM_V7K:
                    return strdup("armv7k");
                #ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S:
                    return strdup("armv7s");
                #endif
          }
          return strdup("arm");
        }
    #ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64: {
            switch (minorCode) {
                #ifdef CPU_SUBTYPE_ARM64E
                case CPU_SUBTYPE_ARM64E:
                    return strdup("arm64e");
                #endif
                #ifdef CPU_SUBTYPE_ARM64_ALL
                case CPU_SUBTYPE_ARM64_ALL:
                    return strdup("arm64");
                #endif
                #ifdef CPU_SUBTYPE_ARM64_V8
                    case CPU_SUBTYPE_ARM64_V8:
                        return strdup("arm64v8");
                #endif
                default:
                    return strdup("arm64");
          }
        }
    #endif
        case CPU_TYPE_X86:
            return strdup("i386");
        case CPU_TYPE_X86_64:
            return strdup("x86_64");
    }
    
    char *arch = (char *)calloc(100, sizeof(char));
    if(arch == NULL) {
        perror("calloc: ");
        return NULL;
    }
    snprintf(arch, 100, "unknown(%d,%d)", majorCode, minorCode);
    return arch;
}
