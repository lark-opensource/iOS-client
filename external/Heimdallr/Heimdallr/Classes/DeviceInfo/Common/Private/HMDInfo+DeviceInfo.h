//
//  HMDInfo+DeviceInfo.h
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo.h"
#include "HMDPublicMacro.h"

typedef NS_ENUM(NSUInteger, HMDDevicePerformanceLevel) {
    HMDDevicePerformanceLevelPoorest = 0,//iPhone5（含）以下 RAM<=512MB
    HMDDevicePerformanceLevelPoor,//iPhone6（含）以下 RAM<=1G
    HMDDevicePerformanceLevelMedium,//iPhoneX（含）以下 2G=<RAM<=3G
    HMDDevicePerformanceLevelHigh,//iPhoneXS（含）及以上 4G=<RAM<6G
    HMDDevicePerformanceLevelHighest,//最新版iPadPro（含）及以上 RAM>=6G
};

@interface HMDInfo (DeviceInfo)

@property (nonatomic, assign, readonly) NSTimeInterval bootTime;
@property (nonatomic, strong, readonly, nullable) NSString *deviceName;
@property (nonatomic, strong, readonly, nullable) NSString *decivceModel;
@property (nonatomic, strong, readonly, nullable) NSString *machineModel;
@property (nonatomic, strong, readonly, nullable) NSString *cpuArchitecture;
@property (nonatomic, assign, readonly) int cpuType;
@property (nonatomic, assign, readonly) int cpuSubType;
@property (nonatomic, strong, readonly, nullable) NSString *currentLanguage;
@property (nonatomic, strong, readonly, nullable) NSString *currentRegion;
@property (nonatomic, strong, readonly, nullable) NSString *resolutionString;
@property (nonatomic, strong, readonly, nullable) NSString *countryCode;//国家编码
@property (nonatomic, assign, readonly) HMDDevicePerformanceLevel devicePerformaceLevel;
@property (nonatomic, assign, readonly) BOOL isMacARM;

+ (NSString * _Nullable)CPUArchForMajor:(cpu_type_t)majorCode minor:(cpu_subtype_t)minorCode;

@end
