// Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

@interface LynxFrameTraceService : NSObject
+ (instancetype)shareInstance;
- (void)initializeService;
- (void)FPSTrace:(const uint64_t)startTime withEndTime:(const uint64_t)endTime;
- (void)screenshot:(NSString *)snapshot;
@end
