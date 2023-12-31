// Copyright 2019 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxIOHIDEvent+KIF.h"

NS_ASSUME_NONNULL_BEGIN

@interface UITouch (KIFAdditionsPrivateHeaders)
- (void)setTapCount:(NSUInteger)tapCount;
- (void)setPhase:(UITouchPhase)touchPhase;
- (void)setTimestamp:(NSTimeInterval)timestamp;
- (void)setWindow:(UIWindow *)window;
- (void)setView:(UIView *)view;
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)resetPrevious;
@end

@interface UITouch (emulate_touch)
- (id)initInView:(UIView *)view coordinateX:(double)x coordinateY:(double)y;
- (void)lynx_changeToPhase:(UITouchPhase)phase;
- (void)lynx_setHidEvent;
- (void)lynx_setLocationInWindow:(CGPoint)location;
@end

NS_ASSUME_NONNULL_END
