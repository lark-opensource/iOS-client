// Copyright 2019 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxEventEmitter.h"
#import "LynxUIOwner.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxEventHandler;

@interface LynxTouchHandler : UIGestureRecognizer

@property(nonatomic, weak) _Nullable id<LynxEventTarget> target;
@property(nonatomic, weak) _Nullable id<LynxEventTarget> preTarget;

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler;

- (void)onGestureRecognized;

@end

NS_ASSUME_NONNULL_END
