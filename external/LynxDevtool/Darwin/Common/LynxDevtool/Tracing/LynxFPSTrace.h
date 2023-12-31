// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

@interface LynxFPSTrace : NSObject
+ (instancetype)shareInstance;
- (intptr_t)getFPSTracePlugin;
- (void)startFPSTrace;
- (void)stopFPSTrace;
@end
