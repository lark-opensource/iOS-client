//
//  HMDInfo+DeviceInfo.m
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo+DeviceInfo.h"
#include <sys/sysctl.h>
#import <sys/utsname.h>
#import "HMDALogProtocol.h"
#import "HMDDeviceTool.h"
#include "HeimdallrUtilities.h"

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
    char * _Nullable arch = hmd_cpu_arch(self.cpuType, self.cpuSubType, false);
    NSString *cpuType;
    if (arch) cpuType = [NSString stringWithUTF8String:arch];
    return cpuType;
}

- (int)cpuType {
  return hmd_kssysctl_int32ForName("hw.cputype");
}

- (int)cpuSubType {
  return hmd_kssysctl_int32ForName("hw.cpusubtype");
}

+ (NSString *)CPUArchForMajor:(cpu_type_t)majorCode minor:(cpu_subtype_t)minorCode {
    char *arch = hmd_cpu_arch(majorCode, minorCode, false);
    NSString *cpuType;
    if(arch != NULL) cpuType = [NSString stringWithUTF8String:arch];
    return cpuType;
}

- (NSString *)currentLanguage {
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
}

- (NSString *)currentRegion {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
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
