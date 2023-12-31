// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDLConfig.h"
#import "BDLSDKManager.h"
#import "LynxEnv.h"

#define BDLConfigBase64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]

@implementation BDLConfig

- (NSDictionary*)defaultConfigDict {
  /// GECKO_DOMAIN
  NSString *key = BDLConfigBase64Decode(@"R0VDS09fRE9NQUlO");
  /// gecko-sg.tiktokv.com
  NSString *value = BDLConfigBase64Decode(@"Z2Vja28tc2cudGlrdG9rdi5jb20=");
  return @{@"SETTINGS_DOMAIN" : @"", key : value };
}

@end
