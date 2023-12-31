// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTouchEvent.h"

NSString *const LynxEventTouchMove = @"touchmove";
NSString *const LynxEventTouchStart = @"touchstart";
NSString *const LynxEventTouchEnd = @"touchend";
NSString *const LynxEventTouchCancel = @"touchcancel";
NSString *const LynxEventTap = @"tap";
NSString *const LynxEventLongPress = @"longpress";
NSString *const LynxEventClick = @"click";

@implementation LynxTouchEvent

- (instancetype)initWithName:(NSString *)name targetTag:(NSInteger)tag {
  self = [[LynxTouchEvent alloc] initWithName:name
                                    targetTag:tag
                                  clientPoint:CGPointZero
                                    pagePoint:CGPointZero
                                    viewPoint:CGPointZero];
  return self;
}

- (instancetype)initWithName:(NSString *)name targetTag:(NSInteger)tag touchPoint:(CGPoint)point {
  return [self initWithName:name targetTag:tag clientPoint:point pagePoint:point viewPoint:point];
}

- (instancetype)initWithName:(NSString *)name
                   targetTag:(NSInteger)tag
                 clientPoint:(CGPoint)clientPoint
                   pagePoint:(CGPoint)pagePoint
                   viewPoint:(CGPoint)viewPoint {
  self = [super initWithName:name targetSign:tag];
  if (self) {
    _point = clientPoint;
    _pagePoint = pagePoint;
    _viewPoint = viewPoint;
  }
  return self;
}

@end
