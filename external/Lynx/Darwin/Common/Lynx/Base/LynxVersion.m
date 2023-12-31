// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxVersion.h"

@implementation LynxVersion

+ (NSString*)versionString {
// source build will define Lynx_POD_VERSION
// binary build will replace string by .rock-package.yml
#ifndef Lynx_POD_VERSION
#define Lynx_POD_VERSION @"9999_1.4.0"
#endif
  return [Lynx_POD_VERSION substringFromIndex:5];
}
@end
