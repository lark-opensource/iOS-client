// Copyright 2020 The Lynx Authors. All rights reserved.
#include "LynxHelium.h"
// clang-format off
#import <TTHelium/HeliumApp.h>
// clang-format on

@implementation LynxHeliumCanvas
- (UIView *_Nullable)createView {
  return [[LynxHeliumCanvasView alloc] init];
}
@end

@implementation LynxHeliumCanvasView
@end

@implementation LynxHeliumConfig
+ (void)setOnErrorCallback:(LynxHeliumErrorCallback _Nullable)callback {
}
+ (void)addWeakErrorHandler:(id<LynxHeliumErrorHandlerProtocol> _Nonnull)handler {
}
+ (void)removeWeakErrorHandler:(id<LynxHeliumErrorHandlerProtocol> _Nonnull)handler {
}
+ (void)setForceEnableCanvas {
}
+ (void)setForceEnableAutoDestroyHelium {
}
+ (void)setSmashUrlFallback:(NSString *_Nullable)url autoCheckSettings:(bool)autoCheckSettings {
}
@end

@interface LynxHeliumHelper : NSObject
@property(nonatomic) HeliumApp *app;
@end

@implementation LynxHeliumHelper
- (void)invalidate {
  [_app invalidate];
}
@end
