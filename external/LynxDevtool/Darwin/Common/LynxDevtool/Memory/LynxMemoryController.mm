//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxMemoryController.h"

#if OS_IOS
#import <DebugRouter/DebugRouter.h>
#import <Lynx/LynxLog.h>
#elif OS_OSX
#import <DebugRouterMacOS/DebugRouter.h>
#import <LynxMacOS/LynxLog.h>
#endif

@implementation LynxMemoryController

+ (instancetype)shareInstance {
  static LynxMemoryController* instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)uploadImageInfo:(NSDictionary*)data {
  static NSString* method = @"Memory.uploadImageInfo";
  static NSString* type = @"CDP";
  if (data == nil) {
    LLogWarn(@"LynxMemoryController uploadImageInfo warning: data is nil");
    return;
  }
  NSDictionary* param = [[NSMutableDictionary alloc] initWithDictionary:@{@"data" : data}];
  NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
  msg[@"params"] = param;
  msg[@"method"] = method;
  if ([NSJSONSerialization isValidJSONObject:msg]) {
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:nil];
    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[DebugRouter instance] sendDataAsync:jsonStr WithType:type ForSession:-1];
  }
}

- (void)startMemoryTracing {
  [[LynxMemoryListener shareInstance] addMemoryReporter:self];
}

- (void)stopMemoryTracing {
  [[LynxMemoryListener shareInstance] removeMemoryReporter:self];
}
@end
