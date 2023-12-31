// Copyright 2022 The VMSDK Authors. All rights reserved.

#import "VmsdkVersion.h"

@implementation VmsdkVersion

+ (NSString*)versionString {
// source build will define VMSDK_POD_VERSION
// binary build will replace string by .rock-package.yml
#ifndef VMSDK_POD_VERSION
#define VMSDK_POD_VERSION @"9999_1.7.0"
#endif
  return [VMSDK_POD_VERSION substringFromIndex:5];
}
@end
