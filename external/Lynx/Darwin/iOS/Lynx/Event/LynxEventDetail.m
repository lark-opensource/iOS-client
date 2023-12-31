//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxEventDetail.h"
#import <Foundation/Foundation.h>

@implementation LynxEventDetail

@synthesize targetPoint = _targetPoint;

- (instancetype)initWithEvent:(enum EVENT_TYPE)type name:(NSString*)name lynxView:(LynxView*)view {
  self = [super init];
  if (self) {
    // eventname and lynxView will be used for external, do not change.
    _eventName = name;
    _lynxView = view;
    _eventType = type;
  }
  return self;
}

- (void)setTargetPoint:(CGPoint)targetPoint {
  _targetPoint = targetPoint;
}

- (CGPoint)targetPoint {
  if (_eventType != TOUCH_EVENT) {
    // Event type error, return (0, 0)
    return CGPointZero;
  }
  return _targetPoint;
}

@end
