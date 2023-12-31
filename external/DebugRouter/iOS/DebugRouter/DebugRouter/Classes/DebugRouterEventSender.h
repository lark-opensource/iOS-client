// Copyright 2023 The Lynx Authors. All rights reserved.

#import "DebugRouterMessageHandleResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface DebugRouterEventSender : NSObject
+ (void)send:(NSString *)method with:(DebugRouterMessageHandleResult *)result;
@end

NS_ASSUME_NONNULL_END
