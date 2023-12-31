//
//  ACCPerformanceUtilsProtocol.h
//  CreativeKit-Pods-Aweme
//
//  Created by liumiao on 2020/8/5.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPerformanceUtilsProtocol <NSObject>

// get current application or system cup usaged, eg: 82.5
// this is some error happend when the return value is -1
+ (CGFloat)acc_applicationCPUUsage;
+ (CGFloat)acc_systemCPUUsage;
// get iphone total memory size
// get iphone current used memory size
// get iphone current free memory size
// get application current free memory size
// this is some error happend when the return value is -1, the return value unit is MB
+ (u_int64_t)acc_totalPhysicalMemory;
+ (u_int64_t)acc_usedMemory;
+ (u_int64_t)acc_applicationUsedMemory;
+ (u_int64_t)acc_availabeMemory;
// get iphone disk space size
// get iphone current used disk space size
// get iphone current free disk space size
// this is some error happend when the return value is -1, the return value unit is MB
+ (u_int64_t)acc_totalDiskSpace;
+ (u_int64_t)acc_usedDiskSpace;
+ (u_int64_t)acc_availabelDiskSpace;
// Get the Screen Brightness
+ (NSInteger)acc_screenBrightness;

@end

FOUNDATION_STATIC_INLINE Class<ACCPerformanceUtilsProtocol> ACCPerformanceUtils() {
    id<ACCPerformanceUtilsProtocol> performance = [ACCBaseServiceProvider() resolveObject:@protocol(ACCPerformanceUtilsProtocol)];
    return [performance class];
}

NS_ASSUME_NONNULL_END
