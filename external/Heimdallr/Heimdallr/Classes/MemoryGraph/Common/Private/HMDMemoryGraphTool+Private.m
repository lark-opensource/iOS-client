//
//  HMDMemoryGraphTool+Private.m
//  Pods
//
//  Created by kilroy on 2020/6/11.
//

#include "HMDMemoryGraphTool+Private.h"
#include "HMDOOMLockingDetector.h"

NSString *kHMDMemoryGraphZipFileExtension = @"zip";
NSString *kHMDMemoryGraphEnvFileExtension = @"env";
NSString *kHMDMemoryGrapthEnvFileExtension = @"env";
NSString *kHMDMemoryGrapthZipFileExtension = @"zip";

bool isMemoryGraphEnvSafe(void) {
    return !HMDOOMLockingDetector_isOOMLocking();
}
