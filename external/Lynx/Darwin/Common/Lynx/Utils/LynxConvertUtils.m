// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxConvertUtils.h"

@implementation LynxConvertUtils
+ (NSString *)convertToJsonData:(NSDictionary *)dict {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
  NSString *jsonString;
  if (!jsonData) {
    NSLog(@"%@", error);
  } else {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return jsonString;
}

@end
