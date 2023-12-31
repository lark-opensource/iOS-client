//
//  HMDGPUUsage.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/7/23.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HMDGPUUsageErrorType) {
    HMDGPUUsageErrorNoError = 1000,
    HMDGPUUsageErrorTargetNotIOS ,
    HMDGPUUsageErrorFuncUnAvailable,
    HMDGPUUsageErrorDictNilOrTypeError,
    HMDGPUUsageErrorGPUKeyNil,
    HMDGPUUsageErrorGPUKeyReturnTypeError,
};



@interface HMDGPUUsage : NSObject

+ (double)gpuUsage;

+ (double)gpuUsageWithError:(NSError * _Nullable * _Nullable)error;

@end


