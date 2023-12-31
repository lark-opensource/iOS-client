// Copyright 2021 The Lynx Authors. All rights reserved.

#import "TestBenchTraceProfileHelper.h"
#import <Lynx/LynxTraceController.h>

@interface TestBenchTraceProfileHelper ()

@end

@implementation TestBenchTraceProfileHelper {
  LynxTraceController *_controller;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _controller = [LynxTraceController shareInstance];
  }
  return self;
}

- (void)startTrace {
  if (_controller) {
    [_controller startTracing:@{}];
  }
}

- (void)stopTrace {
  if (_controller) {
    [_controller stopTracing];
  }
}
@end
