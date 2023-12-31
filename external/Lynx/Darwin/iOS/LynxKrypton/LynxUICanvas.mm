// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxUICanvas.h"
#import "LynxCanvasView.h"
#import "LynxComponentRegistry.h"
#import "LynxEnv.h"
#import "LynxPropsProcessor.h"
#import "LynxServiceTrailProtocol.h"
#import "LynxUI+Internal.h"
#import "LynxUIMethodProcessor.h"

@implementation LynxUICanvas {
  NSString *_id;
  BOOL _freed;
  BOOL _isOffScreen;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("canvas-ng")
#else
LYNX_REGISTER_UI("canvas-ng")
#endif

- (LynxCanvasView *)createView {
  LynxCanvasView *view = [[LynxCanvasView alloc] init];
  view.opaque = NO;
  view.ui = self;
  view.multipleTouchEnabled = YES;

  return view;
}

- (void)setName:(NSString *_Nonnull)name {
  [super setName:name];

  [self.view setId:name];
}

- (void)frameDidChange {
  [super frameDidChange];

  [self.view frameDidChange];
}

- (bool)dispatchTouch:(NSString *const)touchType
              touches:(NSSet<UITouch *> *)touches
            withEvent:(UIEvent *)event {
  return [self.view dispatchTouch:touchType touches:touches withEvent:event];
}

- (void)freeMemoryCache {
  if (_isOffScreen && [self enableMemoryOptimize]) {
    _freed = YES;
    [self.view freeCanvasMemory];
  }
}

- (void)targetOnScreen {
  if (_freed && [self enableMemoryOptimize]) {
    _isOffScreen = NO;
    _freed = NO;
    [self.view restoreCanvasView];
  }
}

- (void)targetOffScreen {
  _isOffScreen = YES;
  // release image memory caches when current lynxview entering into
  // background stack, trail for libra abtest, default close
  if ([self enableMemoryOptimize]) {
    [self freeMemoryCache];
  }
}

- (BOOL)enableMemoryOptimize {
  return [LynxEnv getBoolExperimentSettings:LynxTrailFreeCanvasMemoryForce];
}

@end
