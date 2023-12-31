// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxEmulateTouchHelper.h"
#import <Lynx/LynxTouchEvent.h>
#include <string>
#import "LynxDevtool/LynxInspectorOwner.h"
#import "LynxDevtool/LynxUIEvent+EmulateEvent.h"
#import "LynxDevtool/LynxUITouch+EmulateTouch.h"

#pragma mark - LynxEmulateTouchHelper
@implementation LynxEmulateTouchHelper {
  __weak LynxView* _lynxView;
  __weak LynxInspectorOwner* _owner;

  Boolean _mouseWheelFlag;
  CGPoint _last;
  UITouch* _touch;
  UIEvent* _event;
  dispatch_block_t _task;

  float last_x_;
  float last_y_;
  int delta_scale_;
}

- (nonnull instancetype)initWithLynxView:(LynxView*)view withOwner:(LynxInspectorOwner*)owner {
  _lynxView = view;
  _owner = owner;
  _mouseWheelFlag = NO;
  delta_scale_ = 5;
  return self;
}

+ (void)emulateTouch:(NSDictionary*)dict {
  static NSString* kUIEvent = @"UIEvent";
  static NSString* kTimeStamp = @"timestamp";
  static NSString* kAllTouches = @"allTouches";
  static NSString* kUniqueID = @"uniqueID";
  static NSString* kTouchPhase = @"phase";
  static NSString* kTapCount = @"tapCount";
  static NSString* kLocationInLynxViewX = @"locationInLynxViewX";
  static NSString* kLocationInLynxViewY = @"locationInLynxViewY";
  static NSString* kLynxView = @"LynxView";
  static NSMutableDictionary<NSString*, UITouch*>* uidDict = [NSMutableDictionary new];

  NSDictionary* event = [dict objectForKey:kUIEvent];
  if (event == nil) {
    return;
  }

  LynxView* lynxView = [dict objectForKey:kLynxView];
  if (lynxView == nil) {
    return;
  }

  // remove old touch
  UIEvent* event_obj = [[UIApplication sharedApplication] _touchesEvent];
  [event_obj _clearTouches];
  NSTimeInterval timeStamp = [[event objectForKey:kTimeStamp] doubleValue];
  [event_obj _setTimestamp:timeStamp];

  // add new touch or keep old touch
  NSArray* ary = [event objectForKey:kAllTouches];
  NSMutableDictionary<NSString*, UITouch*>* newUidDict = [NSMutableDictionary new];
  [ary enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
    NSString* uniqueID = [NSString
        stringWithFormat:@"%@,%@", [obj objectForKey:kUniqueID], [@(lynxView.hash) stringValue]];
    NSTimeInterval t = [[obj objectForKey:kTimeStamp] doubleValue];
    NSInteger phase = [[obj objectForKey:kTouchPhase] integerValue];
    NSUInteger tapCount = [[obj objectForKey:kTapCount] unsignedIntegerValue];
    double x = [[obj objectForKey:kLocationInLynxViewX] doubleValue];
    double y = [[obj objectForKey:kLocationInLynxViewY] doubleValue];
    CGPoint viewPoint = CGPointMake(x, y);
    CGPoint windowPoint = [lynxView convertPoint:viewPoint toView:lynxView.window];
    UITouch* touch = [uidDict objectForKey:uniqueID];
    if (touch == nil) {
      touch = [[UITouch alloc] initInView:lynxView
                              coordinateX:windowPoint.x
                              coordinateY:windowPoint.y];
    } else {
      [touch setWindow:lynxView.window];
      [touch _setLocationInWindow:windowPoint resetPrevious:NO];
      UIView* target = [lynxView.window hitTest:windowPoint withEvent:nil];
      [touch setView:target];
    }
    [touch setTimestamp:t];
    [touch setPhase:UITouchPhase(phase)];
    [touch setTapCount:tapCount];
    [event_obj _addTouch:touch forDelayedDelivery:NO];
    [newUidDict setObject:touch forKey:uniqueID];
  }];

  // record touch in event
  [uidDict removeAllObjects];
  uidDict = newUidDict;

  [[UIApplication sharedApplication] sendEvent:event_obj];
}

- (void)emulateTouch:(nonnull NSString*)type
         coordinateX:(int)x
         coordinateY:(int)y
              button:(nonnull NSString*)button
              deltaX:(CGFloat)dx
              deltaY:(CGFloat)dy
           modifiers:(int)modifiers
          clickCount:(int)click_count {
  if (_lynxView == nil) {
    return;
  }
  UIView* view = _lynxView;

  if ([type isEqualToString:@"mousePressed"]) {
    _touch = [[UITouch alloc] initInView:view coordinateX:x coordinateY:y];
    _event = [self eventWithTouch:_touch];

    [[UIApplication sharedApplication] sendEvent:_event];
  } else if ([type isEqualToString:@"mouseMoved"]) {
    [_touch lynx_changeToPhase:UITouchPhaseMoved];
    CGPoint location = CGPointMake(x, y);
    [_touch lynx_setLocationInWindow:location];

    [[UIApplication sharedApplication] sendEvent:_event];
  } else if ([type isEqualToString:@"mouseReleased"]) {
    [_touch lynx_changeToPhase:UITouchPhaseEnded];
    CGPoint location = CGPointMake(x, y);
    [_touch lynx_setLocationInWindow:location];

    [[UIApplication sharedApplication] sendEvent:_event];
  } else if ([type isEqualToString:@"mouseWheel"]) {
    if (_task) {
      dispatch_block_cancel(_task);
    }

    if (!_mouseWheelFlag) {
      _mouseWheelFlag = YES;

      _touch = [[UITouch alloc] initInView:view coordinateX:(x)coordinateY:(y)];
      _event = [self eventWithTouch:_touch];
      _last.x = x;
      _last.y = y;

      [[UIApplication sharedApplication] sendEvent:_event];
    }
    _last.x += dx / delta_scale_;
    _last.y += dy / delta_scale_;
    [_touch lynx_changeToPhase:UITouchPhaseMoved];
    [_touch lynx_setLocationInWindow:_last];

    [[UIApplication sharedApplication] sendEvent:_event];

    _task = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{
      [self stopMouseWheel];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), _task);
  } else if ([type isEqualToString:LynxEventTouchStart] ||
             [type isEqualToString:LynxEventTouchMove] ||
             [type isEqualToString:LynxEventTouchEnd] ||
             [type isEqualToString:LynxEventTouchCancel] || [type isEqualToString:LynxEventTap] ||
             [type isEqualToString:LynxEventLongPress] || [type isEqualToString:LynxEventClick]) {
    if (_owner) {
      [_owner sendTouchEvent:type sign:[button intValue] x:x y:y];
    }
  }
}

- (UIEvent*)eventWithTouch:(UITouch*)touch {
  NSArray* touches = touch ? @[ touch ] : nil;
  UIEvent* event = [[UIApplication sharedApplication] _touchesEvent];

  [event _clearTouches];
  [event setEventWithTouch:touches];

  for (UITouch* aTouch in touches) {
    [event _addTouch:aTouch forDelayedDelivery:NO];
  }

  return event;
}

- (void)stopMouseWheel {
  if (_mouseWheelFlag && _touch.phase == UITouchPhaseMoved) {
    _mouseWheelFlag = NO;
    [_touch lynx_changeToPhase:UITouchPhaseEnded];
    [_touch lynx_setLocationInWindow:_last];
    [[UIApplication sharedApplication] sendEvent:_event];
  }
  _task = nil;
}

- (void)attachLynxView:(nonnull LynxView*)lynxView {
  _lynxView = lynxView;
}

@end
