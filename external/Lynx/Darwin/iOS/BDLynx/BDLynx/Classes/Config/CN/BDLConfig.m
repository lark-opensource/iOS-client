// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDLConfig.h"
#import "BDLSDKManager.h"
#import "LynxEnv.h"

#define BDLBase64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]

@implementation BDLConfig

- (NSDictionary*)defaultConfigDict {
  /// GECKO_DOMAIN
  NSString *key = BDLBase64Decode(@"R0VDS09fRE9NQUlO");
  /// gecko.snssdk.com
  NSString *value = BDLBase64Decode(@"Z2Vja28uc25zc2RrLmNvbQ==");
  return @{@"SETTINGS_DOMAIN" : @"is.snssdk.com", key : value};
}

@end
