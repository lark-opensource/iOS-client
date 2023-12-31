// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxDevtoolFrameCapturer.h"

@interface LynxFrameViewTrace : LynxDevtoolFrameCapturer <FrameCapturerDelegate>

+ (instancetype)shareInstance;
- (intptr_t)getFrameViewTracePlugin;

@end
