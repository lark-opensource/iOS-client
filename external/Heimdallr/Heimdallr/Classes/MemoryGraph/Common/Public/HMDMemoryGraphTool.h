//
//  HMDMemoryGraphTool.h
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/24.
//

#ifndef HMDMemoryGraphTool_h
#define HMDMemoryGraphTool_h

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdbool.h>

extern NSString * _Nonnull kHMDMemoryGraphZipFileExtension;
extern NSString * _Nonnull kHMDMemoryGraphEnvFileExtension;
extern NSString * _Nonnull kHMDMemoryGrapthEnvFileExtension __attribute__((deprecated("please use kHMDMemoryGraphEnvFileExtension")));
extern NSString * _Nonnull kHMDMemoryGrapthZipFileExtension __attribute__((deprecated("please use kHMDMemoryGraphZipFileExtension")));

typedef NS_ENUM(NSInteger, HMDMemoryGraphErrorType) {
    HMDMemoryGraphErrorTypeGraphZipError = 1000,
    HMDMemoryGraphErrorTypeGraphZipFileMissing,
    HMDMemoryGraphErrorTypeEnvFileInvalidMissing,
    HMDMemoryGraphErrorTypeHitServerLimit,
    HMDMemoryGraphErrorTypeEnvUploadFail,
    HMDMemoryGraphErrorTypeNoMemorySpace,
    HMDMemoryGraphErrorTypeNoDiskSpace,
    HMDMemoryGraphErrorTypeDeviceNotSupported
};
typedef void(^ _Nullable HMDMemoryGraphFinishBlock)(NSError * _Nullable);



#endif /* HMDMemoryGraphTool_h */
