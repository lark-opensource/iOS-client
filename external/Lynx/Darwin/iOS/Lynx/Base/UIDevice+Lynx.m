// Copyright 2019 The Lynx Authors. All rights reserved.

#import <sys/utsname.h>
#import "UIDevice+Lynx.h"

@implementation UIDevice (Lynx)

+ (BOOL)lynx_isIPhoneX {
  static BOOL isIPhoneX = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* platform = [NSString stringWithCString:systemInfo.machine
                                            encoding:NSUTF8StringEncoding];
    isIPhoneX = [platform isEqualToString:@"iPhone12,1"];
  });
  return isIPhoneX;
}

@end
