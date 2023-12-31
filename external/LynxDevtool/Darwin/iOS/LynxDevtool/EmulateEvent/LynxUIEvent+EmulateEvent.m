// Copyright 2019 The Lynx Authors. All rights reserved.

#import <objc/runtime.h>
#import "LynxUIEvent+EmulateEvent.h"

@implementation UIEvent (emulate_event)
- (void)setEventWithTouch:(NSArray *)touches {
  IOHIDEventRef event = kif_IOHIDEventWithTouches(touches);
  CFRelease(event);
}
@end
