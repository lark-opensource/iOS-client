// Copyright 2019 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxIOHIDEvent+KIF.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIEvent (KIFAdditionsPrivateHeaders)
- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)arg2;
- (void)_clearTouches;
- (void)_setTimestamp:(NSTimeInterval)timestamp;
@end

@interface UIApplication (KIFAdditionsPrivate)
- (UIEvent *)_touchesEvent;
@end

@interface UIEvent (emulate_event)
- (void)setEventWithTouch:(NSArray *)touches;
@end

NS_ASSUME_NONNULL_END
