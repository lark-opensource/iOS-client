// Copyright 2019 The Lynx Authors. All rights reserved.

#import <objc/runtime.h>
#import "LynxUITouch+EmulateTouch.h"

@interface UITouch ()
- (void)setIsTap:(BOOL)isTap;
- (void)setGestureView:(UIView *)view;
- (void)_setIsFirstTouchForView:(BOOL)firstTouchForView;
- (void)_setHidEvent:(IOHIDEventRef)event;
@end

@implementation UITouch (emulate_touch)
- (id)initInView:(UIView *)view coordinateX:(double)x coordinateY:(double)y {
  self = [super init];
  if (self != nil) {
    CGPoint _locationInWindow = CGPointMake(x, y);

    [self setWindow:view.window];
    [self setTapCount:1];
    [self _setLocationInWindow:_locationInWindow resetPrevious:YES];

    UIView *target = [view.window hitTest:_locationInWindow withEvent:nil];
    [self setView:target];
    [self setPhase:UITouchPhaseBegan];
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];

    NSOperatingSystemVersion iOS9 = {9, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
        [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS9]) {
      [self lynx_setHidEvent];
    }
  }
  return self;
}

- (void)lynx_changeToPhase:(UITouchPhase)phase {
  [self setPhase:phase];
  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
}

- (void)lynx_setHidEvent {
  IOHIDEventRef event = kif_IOHIDEventWithTouches(@[ self ]);
  [self _setHidEvent:event];
  CFRelease(event);
}

- (void)lynx_setLocationInWindow:(CGPoint)location {
  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
  [self _setLocationInWindow:location resetPrevious:NO];
}

@end
