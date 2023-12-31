// Copyright 2023 The Lynx Authors. All rights reserved.

@interface DebugRouterUtil : NSObject
+ (nullable NSData *)dictToJson:
    (nonnull NSMutableDictionary<NSString *, id> *)dict;
@end
