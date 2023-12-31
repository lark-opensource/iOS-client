// Copyright 2019 The Lynx Authors. All rights reserved.

#import "BDXLynxInlineEventTarget.h"

#import <YYText/YYTextInput.h>

@implementation BDXLynxTextInfo

- (instancetype)initWithShadowNode:(LynxShadowNode*)node {
    self = [super init];
    if (self) {
      _sign = node.sign;
      _parentSign = node.parent.sign;
      _ignoreFocus = node.ignoreFocus;
      _enableTouchPseudoPropagation = node.enableTouchPseudoPropagation;
      _eventThrough = node.eventThrough;
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
@end

@implementation BDXLynxEventTargetSpan {
  NSInteger _sign;
  NSArray* _rects;
  BOOL _ignoreFocus;
  BOOL _enableTouchPseudoPropagation;
  __weak id<LynxEventTarget> _parent;
  enum LynxEventPropStatus _eventThrough;
  NSDictionary<NSString*, LynxEventSpec*>* _eventSet;
  int32_t _pseudoStatus;
}

- (instancetype)initWithInfo:(BDXLynxTextInfo*)info withRects:(NSArray*)rects {
  self = [super init];
  if (self) {
    _ignoreFocus = info.ignoreFocus;
    _enableTouchPseudoPropagation = info.enableTouchPseudoPropagation;
    _sign = info.sign;
    _rects = rects;
    _parent = nil;
    _eventThrough = info.eventThrough;
    _eventSet = info.eventSet;
  }
  return self;
}

- (NSInteger)signature {
  return _sign;
}


- (void)setParentEventTarget:(id<LynxEventTarget>)parent {
  _parent = parent;
}

- (nullable id<LynxEventTarget>)parentTarget {
  return _parent;
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  return self;
}

- (BOOL)containsPoint:(CGPoint)point {
  if (_rects == nil || _rects.count == 0) {
    return NO;
  }
  for (id rect in _rects) {
      if ([rect isKindOfClass:[YYTextSelectionRect class]]) {
          YYTextSelectionRect* yyRect = (YYTextSelectionRect*)rect;
          if (CGRectContainsPoint(yyRect.rect, point)) {
              return YES;
          }
      }
  }
  return NO;
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

- (BOOL)enableTouchPseudoPropagation {
  return _enableTouchPseudoPropagation;
}

- (void)onPseudoStatusFrom:(int32_t)preStatus changedTo:(int32_t)currentStatus {
  _pseudoStatus = currentStatus;
}

- (int32_t)pseudoStatus {
  return _pseudoStatus;
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
  if (parent != nil && parent != self) {
    return [parent eventThrough];
  }
  return false;
}

- (BOOL)dispatchTouch:(NSString* const)touchType
              touches:(NSSet<UITouch*>*)touches
            withEvent:(UIEvent*)event {
  return NO;
}

- (BOOL)dispatchEvent:(LynxEventDetail*)event {
  return NO;
}

- (void)onResponseChain {}

- (void)offResponseChain {}

- (BOOL)isOnResponseChain { return NO; }

@end
