// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxEventTargetSpan.h"

@implementation LynxEventTargetSpan {
  NSInteger _sign;
  BOOL _ignoreFocus;
  BOOL _enableTouchPseudoPropagation;
  enum LynxEventPropStatus _eventThrough;
  CGRect _frame;
  __weak id<LynxEventTarget> _parent;
  NSDictionary<NSString*, LynxEventSpec*>* _eventSet;
  int32_t _pseudoStatus;
}

- (instancetype)initWithShadowNode:(LynxShadowNode*)node frame:(CGRect)frame {
  self = [super init];
  if (self) {
    _ignoreFocus = node.ignoreFocus;
    _eventThrough = node.eventThrough;
    _enableTouchPseudoPropagation = node.enableTouchPseudoPropagation;
    _sign = node.sign;
    _frame = frame;
    _parent = nil;
    // Copy node.eventSet to _eventSet to avoid synchronization problem.
    // This is a shallow copy, since node.eventSet may change, but node.eventSet's items will not
    // change.
    if (node.eventSet != nil) {
      _eventSet = [[NSDictionary alloc] initWithDictionary:node.eventSet copyItems:NO];
    } else {
      _eventSet = nil;
    }
  }
  return self;
}

- (NSInteger)signature {
  return _sign;
}

- (int32_t)pseudoStatus {
  return _pseudoStatus;
}

- (void)setParentEventTarget:(id<LynxEventTarget>)parent {
  _parent = parent;
}

- (nullable id<LynxEventTarget>)parentTarget {
  __strong id<LynxEventTarget> parent = _parent;
  return parent;
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  return self;
}

- (BOOL)containsPoint:(CGPoint)point {
  return CGRectContainsPoint(_frame, point);
}

- (nullable NSDictionary<NSString*, LynxEventSpec*>*)eventSet {
  return _eventSet;
}

- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event {
  return YES;
}

- (BOOL)ignoreFocus {
  return _ignoreFocus;
}

// TODO(songshourui.null): return NO now, will refactor in future.
- (BOOL)consumeSlideEvent:(CGFloat)angle {
  return NO;
}

// TODO(songshourui.null): return NO now, will refactor in future.
- (BOOL)blockNativeEvent:(UIGestureRecognizer*)gestureRecognizer {
  return NO;
}

- (BOOL)eventThrough {
  // If _eventThrough == Enable, return true. If _eventThrough == Disable, return false.
  // If _eventThrough == Undefined && parent not nil, return parent._eventThrough.
  if (_eventThrough == kLynxEventPropEnable) {
    return true;
  } else if (_eventThrough == kLynxEventPropDisable) {
    return false;
  }

  id<LynxEventTarget> parent = [self parentTarget];
  if (parent != nil) {
    return [parent eventThrough];
  }
  return false;
}

- (BOOL)enableTouchPseudoPropagation {
  return YES;
}

- (void)onPseudoStatusFrom:(int32_t)preStatus changedTo:(int32_t)currentStatus {
  _pseudoStatus = currentStatus;
}

- (BOOL)dispatchTouch:(NSString* const)touchType
              touches:(NSSet<UITouch*>*)touches
            withEvent:(UIEvent*)event {
  return NO;
}

- (BOOL)dispatchEvent:(LynxEventDetail*)event {
  return NO;
}

- (void)onResponseChain {
}

- (void)offResponseChain {
}

- (BOOL)isOnResponseChain {
  return NO;
}

@end
