// Copyright 2023 The Lynx Authors. All rights reserved.

#import "DebugRouterUtil.h"
#import "DebugRouterLog.h"
@implementation DebugRouterUtil
+ (NSData *)dictToJson:(NSMutableDictionary<NSString *, id> *)dict {
  if (dict == nil) {
    return nil;
  }
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                     options:kNilOptions
                                                       error:&error];
  if (jsonData == nil) {
    LLogError(@"DebugRouterUtil: toJsonString error: %@",
              [error localizedFailureReason]);
  }
  return jsonData;
}
@end
