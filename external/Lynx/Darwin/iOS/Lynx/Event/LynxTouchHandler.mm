// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTouchHandler.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "LynxTouchHandler+Internal.h"

#import "LynxEventEmitter.h"
#import "LynxEventHandler+Internal.h"
#import "LynxLog.h"
#import "LynxTouchEvent.h"
#import "LynxUI+Internal.h"
#import "LynxUI.h"
#import "LynxWeakProxy.h"

#include <deque>

@interface LynxTouchHandler () <UIGestureRecognizerDelegate>
@end

@implementation LynxTouchHandler {
  __weak LynxEventHandler* _eventHandler;
  std::deque<__weak id<LynxEventTarget>> deque_;
  CGPoint _preTouchPoint;
  CGPoint _downPoint;
  BOOL _touchMoved;
  BOOL _touchBegin;
  BOOL _touchEndOrCancel;
  BOOL _touchOutSide;
  BOOL _gestureRecognized;
  BOOL _enableTouchRefactor;
  BOOL _enableEndGestureAtLastFingerUp;
  BOOL _enableTouchPseudo;
  NSMutableSet<UITouch*>* _touches;
  UIEvent* _event;
}

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler {
  if (self = [super init]) {
    _eventHandler = eventHandler;
    deque_ = std::deque<__weak id<LynxEventTarget>>();
    _touchDeque = [[NSMutableArray alloc] init];
    self.cancelsTouchesInView = NO;
    self.delaysTouchesBegan = NO;
    self.delaysTouchesEnded = NO;
    self.delegate = self;
    _preTouchPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
    _downPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
    _touchMoved = NO;
    _touchBegin = NO;
    // After manual testing, the default value on iOS is close to 45.
    _tapSlop = 45;
    _touchEndOrCancel = NO;
    _touches = [NSMutableSet set];
    _event = nil;
    _target = nil;
    _preTarget = nil;
    _enableTouchPseudo = NO;
    _enableTouchRefactor = NO;
    _enableEndGestureAtLastFingerUp = NO;
  }
  return self;
}

- (void)onGestureRecognized {
  _gestureRecognized = YES;
}

- (void)setEnableTouchRefactor:(BOOL)enable {
  _enableTouchRefactor = enable;
}

- (void)setEnableEndGestureAtLastFingerUp:(BOOL)enable {
  _enableEndGestureAtLastFingerUp = enable;
}

- (void)setEnableTouchPseudo:(BOOL)enable {
  // When disable fiber arch, setHasTouchPseudo will be exec twice.
  // Normally, it will exec setHasTouchPseudo in onPageConfigDecoded first.
  // In case not following this order in the future and exec setHasTouchPseudo in updateEventInfo
  // first, let _enableTouchPseudo = _enableTouchPseudo || enable;
  _enableTouchPseudo = _enableTouchPseudo || enable;
}

- (void)initTouchEnv {
  _touchBegin = YES;
  _touchMoved = NO;
  _tapSlop = 45;
  _touchOutSide = NO;
  _touchEndOrCancel = NO;
  _gestureRecognized = NO;
  [_eventHandler resetEventEnv];
  [_touchDeque removeAllObjects];
}

- (void)initClickEnv {
  for (auto& target : deque_) {
    [target offResponseChain];
  }
  deque_.clear();
  if (_eventHandler == nil || _eventHandler.touchRecognizer == nil) {
    _touchOutSide = YES;
    return;
  }
  id<LynxEventTarget> ui = _eventHandler.touchTarget;
  while (ui != nil) {
    deque_.push_front(ui);
    ui = ui.parentTarget;
  }
  for (int i = static_cast<int>(deque_.size() - 1); i >= 0; --i) {
    id<LynxEventTarget> ui = deque_[i];
    if (ui == nil) {
      deque_.clear();
      break;
    } else if (ui.eventSet == nil || [ui.eventSet objectForKey:LynxEventClick] == nil) {
      deque_.pop_back();
    } else {
      break;
    }
  }
  for (auto& target : deque_) {
    [target onResponseChain];
  }
  if (deque_.empty()) {
    _touchOutSide = YES;
  } else {
    _touchOutSide = NO;
  }
}

- (void)resetTouchEnv {
  _touchBegin = NO;
  _touchMoved = NO;
  _tapSlop = 45;
  _touchEndOrCancel = YES;
  _gestureRecognized = NO;
  [_touches removeAllObjects];
  _event = nil;
  _preTarget = _target;
  _target = nil;
}

- (void)dispatchEvent:(NSString*)eventName
             toTarget:(id<LynxEventTarget>)target
                touch:(UITouch*)touch {
  CGPoint windowLocation = [touch locationInView:touch.window];
  CGPoint clientPoint = [touch.window convertPoint:windowLocation toView:_eventHandler.rootView];
  CGPoint targetViewPoint = clientPoint;
  if ([_target isKindOfClass:[LynxUI class]]) {
    LynxUI* ui = (LynxUI*)_target;
    targetViewPoint = [touch locationInView:ui.view];
  }

  [self dispatchEvent:eventName
             toTarget:target
                phase:touch.phase
          clientPoint:clientPoint
            pagePoint:clientPoint
            viewPoint:targetViewPoint];
}

- (void)dispatchEvent:(NSString*)eventName
             toTarget:(id<LynxEventTarget>)target
                phase:(UITouchPhase)phase
          clientPoint:(CGPoint)clientPoint
            pagePoint:(CGPoint)pagePoint
            viewPoint:(CGPoint)viewPoint {
  LynxTouchEvent* event = [[LynxTouchEvent alloc] initWithName:eventName
                                                     targetTag:target.signature
                                                   clientPoint:clientPoint
                                                     pagePoint:pagePoint
                                                     viewPoint:viewPoint];
  [_eventHandler.eventEmitter dispatchTouchEvent:event target:target];
  if (eventName == LynxEventTouchStart) {
    _preTouchPoint = clientPoint;
    _downPoint = clientPoint;
  } else if (eventName == LynxEventTouchEnd || eventName == LynxEventTouchCancel) {
    _preTouchPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
  }
}

// OnTouchesBegan, generate event target response chain. And traversed the event target response
// chain to make the target's touch state pseudo-class take effect.
- (void)onTouchesBegan {
  id<LynxEventTarget> target = _target;
  // TODO(songshourui.null): for fiber Arch, need to set enableTouchPseudo YES by default
  if (target == nil) {
    return;
  }
  while (target != nil) {
    [_touchDeque addObject:[LynxWeakProxy proxyWithTarget:target]];
    [target onPseudoStatusFrom:LynxTouchPseudoStateNone changedTo:LynxTouchPseudoStateActive];
    if (_enableTouchPseudo) {
      [_eventHandler.eventEmitter onPseudoStatusChanged:(int32_t)target.signature
                                          fromPreStatus:(int32_t)LynxTouchPseudoStateNone
                                        toCurrentStatus:(int32_t)LynxTouchPseudoStateActive];
    }
    if (![target enableTouchPseudoPropagation]) {
      break;
    }
    target = [target parentTarget];
  }
  _touchDeque = [[[_touchDeque reverseObjectEnumerator] allObjects] mutableCopy];
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  LLogInfo(@"Lynxview LynxTouchHandler touchesBegan %p: ", _eventHandler.rootView);

  if (self.state == UIGestureRecognizerStatePossible) {
    self.state = UIGestureRecognizerStateBegan;
  } else if (self.state == UIGestureRecognizerStateBegan) {
    self.state = UIGestureRecognizerStateChanged;
  }
  if (_eventHandler.touchTarget == nil) {
    return;
  }

  if ([_touches count] != 0) {
    [self deactivatePseudoState:LynxTouchPseudoStateActive];
    // now the method only dispatch multiple touch event to canvas view.
    [_target dispatchTouch:LynxEventTouchStart touches:touches withEvent:event];
    return;
  }
  _target = _eventHandler.touchTarget;

  [self initTouchEnv];
  [self initClickEnv];
  [_eventHandler resetEventEnv];
  for (UITouch* touch in touches) {
    [_touches addObject:touch];
    [self dispatchEvent:LynxEventTouchStart toTarget:_target touch:touch];
  }
  _event = event;
  [_target dispatchTouch:LynxEventTouchStart touches:touches withEvent:event];
  [self onTouchesBegan];
}

// OnTouchesMove, the touched event target may change. Disable the touch pseudo class for
// targets not on the response chain.
- (void)onTouchesMoveWithTarget:(id<LynxEventTarget>)target {
  if (target == nil || [_touchDeque count] == 0) {
    return;
  }
  id<LynxEventTarget> newTarget = target;
  NSMutableArray<id<LynxEventTarget>>* queue = [[NSMutableArray alloc] init];

  while (newTarget != nil) {
    [queue addObject:newTarget];
    if (![newTarget enableTouchPseudoPropagation]) {
      break;
    }
    newTarget = newTarget.parentTarget;
  }
  queue = [[[queue reverseObjectEnumerator] allObjects] mutableCopy];

  NSInteger index = -1;
  for (NSInteger i = 0; i < (NSInteger)[_touchDeque count] && i < (NSInteger)[queue count]; ++i) {
    id<LynxEventTarget> preTarget = _touchDeque[i].target;
    id<LynxEventTarget> nowTarget = queue[i];
    if (preTarget.signature != nowTarget.signature) {
      break;
    }
    index = i;
  }

  for (NSInteger i = (NSInteger)[_touchDeque count] - 1; i >= index + 1; --i) {
    id<LynxEventTarget> ui = _touchDeque[i].target;
    [ui onPseudoStatusFrom:LynxTouchPseudoStateActive changedTo:LynxTouchPseudoStateNone];
    if (_enableTouchPseudo) {
      [_eventHandler.eventEmitter onPseudoStatusChanged:(int32_t)ui.signature
                                          fromPreStatus:(int32_t)LynxTouchPseudoStateActive
                                        toCurrentStatus:(int32_t)LynxTouchPseudoStateNone];
    }
    [_touchDeque removeLastObject];
  }
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  LLogInfo(@"Lynxview LynxTouchHandler touchesMoved %p: ", _eventHandler.rootView);

  self.state = UIGestureRecognizerStateChanged;
  if (_target == nil) {
    return;
  }
  for (UITouch* touch in touches) {
    if (![_touches containsObject:touch]) {
      continue;
    }
    CGPoint windowLocation = [touch locationInView:touch.window];
    CGPoint point = [touch.window convertPoint:windowLocation toView:_eventHandler.rootView];
    if (point.x != _preTouchPoint.x || point.y != _preTouchPoint.y) {
      [self dispatchEvent:LynxEventTouchMove toTarget:_target touch:touch];
      _touchOutSide = _gestureRecognized || _touchOutSide;
      if ([_touchDeque count] >= 0 || !_touchOutSide) {
        id<LynxEventTarget> target = [_eventHandler hitTestInner:point withEvent:event];
        _touchOutSide = [self onTouchMove:point withEvent:event withTarget:target];
        if (_gestureRecognized || ![_eventHandler canRespondTapOrClickEvent:_target] ||
            _touchMoved) {
          [self deactivatePseudoState:LynxTouchPseudoStateActive];
        }
      }
    }
    _preTouchPoint = point;
  }
  [_target dispatchTouch:LynxEventTouchMove touches:touches withEvent:event];
}

// OnTouchEndOrCancel, the touched event target may change. Disable the touch pseudo class for all
// targets.
- (void)onTouchEndOrCancel {
  [self deactivatePseudoState:LynxTouchPseudoStateAll];
}

// change all targets from active to none
- (void)deactivatePseudoState:(int32_t)state {
  for (LynxWeakProxy* proxy : _touchDeque) {
    id<LynxEventTarget> ui = proxy.target;
    if (!ui) {
      continue;
    }
    if (_enableTouchPseudo) {
      [_eventHandler.eventEmitter onPseudoStatusChanged:(int32_t)ui.signature
                                          fromPreStatus:ui.pseudoStatus
                                        toCurrentStatus:ui.pseudoStatus & ~state];
    }
    [ui onPseudoStatusFrom:ui.pseudoStatus changedTo:ui.pseudoStatus & ~state];
  }
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  LLogInfo(@"Lynxview LynxTouchHandler touchesEnded %p: ", _eventHandler.rootView);

  if ([self isAllTouchesAreCancelledOrEnded:event.allTouches]) {
    self.state = UIGestureRecognizerStateEnded;
  } else if ([self hasAnyTouchesChanged:event.allTouches]) {
    self.state = UIGestureRecognizerStateChanged;
  }
  for (UITouch* touch in touches) {
    if (![_touches containsObject:touch]) {
      continue;
    }
    if (_target != nil) {
      [self dispatchEvent:LynxEventTouchEnd toTarget:_target touch:touch];
      [self sendClickEvent:touch];
    }
    [_touches removeObject:touch];
  }
  if (_target != nil) {
    [_target dispatchTouch:LynxEventTouchEnd touches:touches withEvent:event];
  } else if (_preTarget != nil) {
    // now the method only dispatch multiple touch event to canvas view, it only works when
    // all the touches are in a canvas view.
    [_preTarget dispatchTouch:LynxEventTouchEnd touches:touches withEvent:event];
  }
  [self onTouchEndOrCancel];
  if ([_touches count] == 0) {
    if (_enableEndGestureAtLastFingerUp) {
      self.state = UIGestureRecognizerStateEnded;
    }
    [self resetTouchEnv];
  }
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  LLogInfo(@"Lynxview LynxTouchHandler touchesCancelled %p: ", _eventHandler.rootView);

  if ([self isAllTouchesAreCancelledOrEnded:event.allTouches]) {
    self.state = UIGestureRecognizerStateCancelled;
  } else if ([self hasAnyTouchesChanged:event.allTouches]) {
    self.state = UIGestureRecognizerStateChanged;
  }
  for (UITouch* touch in touches) {
    if (![_touches containsObject:touch]) {
      continue;
    }
    if (_target != nil) {
      [self dispatchEvent:LynxEventTouchCancel toTarget:_target touch:touch];
    }
    [_touches removeObject:touch];
  }
  if (_target != nil) {
    [_target dispatchTouch:LynxEventTouchCancel touches:touches withEvent:event];
  }
  [self onTouchEndOrCancel];
  if ([_touches count] == 0) {
    if (_enableEndGestureAtLastFingerUp) {
      self.state = UIGestureRecognizerStateCancelled;
    }
    [self resetTouchEnv];
  }
}

- (void)sendClickEvent:(UITouch*)touch {
  if (deque_.empty()) {
    return;
  }
  for (size_t i = 0; i < deque_.size(); ++i) {
    id<LynxEventTarget> target = deque_[i];
    if (![target isKindOfClass:[LynxUI class]]) {
      continue;
    }
    LynxUI* ui = (LynxUI*)target;
    if (ui != nil && ui.view != nil && [ui.view isKindOfClass:[UIScrollView class]]) {
      UIScrollView* view = (UIScrollView*)ui.view;
      if (view.decelerating) {
        return;
      }
    }
  }

  id<LynxEventTarget> ui = deque_.back();
  if (ui == nil) {
    return;
  }

  // TODO(songshourui.null): opt me
  // now there is a bad case that when
  //  scroll-view.contentOffset.y + scrollView.frame.size.height >
  //  scrollView.contentSize.height + scrollView.contentSize.height.contentInset.bottom or
  //  scroll-view.contentOffset.x + scrollView.frame.size.width >
  //  scrollView.contentSize.width + scrollView.contentSize.height.contentInset.right,
  // click event will be triggered. For this bad case, there is currently no good solution.
  if (_touchBegin == YES && _touchEndOrCancel == NO && _touchOutSide == NO && ui != nil &&
      _gestureRecognized == NO && [_eventHandler canRespondTapOrClickEvent:ui]) {
    // TODO check can send click event or not
    [self dispatchEvent:LynxEventClick toTarget:ui touch:touch];
  }
}

- (BOOL)onTouchMove:(CGPoint)point
          withEvent:(UIEvent*)event
         withTarget:(id<LynxEventTarget>)target {
  if ((point.x - _downPoint.x) * (point.x - _downPoint.x) +
          (point.y - _downPoint.y) * (point.y - _downPoint.y) >
      _tapSlop * _tapSlop) {
    _touchMoved = YES;
  }
  if (_eventHandler == nil || deque_.empty() || target == nil) {
    return YES;
  }
  id<LynxEventTarget> newui = target;
  std::deque<id<LynxEventTarget>> deque;
  while (newui != nil && newui.parentTarget != newui) {
    deque.push_front(newui);
    newui = newui.parentTarget;
  }
  if (deque.size() < deque_.size()) {
    return YES;
  }
  for (size_t i = 0; i < deque_.size(); ++i) {
    id<LynxEventTarget> ui = deque_[i];
    if (ui == nil || ui.signature != deque[i].signature) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isDescendantOfLynxView:(UIGestureRecognizer*)gesture {
  return [gesture.view isDescendantOfView:_eventHandler.rootView];
}

- (BOOL)blockNativeEvent:(UIGestureRecognizer*)gestureRecognizer {
  id<LynxEventTarget> target = _eventHandler.touchTarget;
  BOOL res = NO;
  while (target != nil) {
    if ([target isKindOfClass:[LynxUI class]]) {
      LynxUI* ui = (LynxUI*)target;
      if ([ui blockNativeEvent:gestureRecognizer]) {
        res = YES;
        break;
      }
    }
    target = target.parentTarget;
  }
  return res;
}

- (BOOL)enableSimultaneousTouch {
  id<LynxEventTarget> target = _eventHandler.touchTarget;
  BOOL res = NO;
  while (target != nil) {
    if ([target isKindOfClass:[LynxUI class]]) {
      LynxUI* ui = (LynxUI*)target;
      if (ui.enableSimultaneousTouch) {
        res = YES;
        break;
      }
    }
    target = target.parentTarget;
  }
  return res;
}

// It is necessary to override this function to return "No" to ensure that the current gesture will
// not prevent other gestures.
- (BOOL)canPreventGestureRecognizer:(__unused UIGestureRecognizer*)preventedGestureRecognizer {
  return NO;
}

// Override this function to return "YES" if it is a LynxView gesture or an internal LynxView
// gesture, indicating that it will not be prevented by these gestures. Otherwise, return "YES" to
// indicate that it can be prevented by external gestures.
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer*)preventingGestureRecognizer {
  return ![preventingGestureRecognizer.view isDescendantOfView:_eventHandler.rootView];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  // _enableTouchRefactor's default value is false. If this flag is true, the external gesture
  // which's state is possible or began will not cancel the Lynx iOS touch gesture see issue:#7920.
  if (_enableTouchRefactor && (otherGestureRecognizer.state == UIGestureRecognizerStatePossible ||
                               otherGestureRecognizer.state == UIGestureRecognizerStateBegan)) {
    return YES;
  }

  if ([self enableSimultaneousTouch]) {
    return YES;
  }

  auto res = ![self isDescendantOfLynxView:otherGestureRecognizer];
  if (res == YES && _touchBegin == YES && _touchEndOrCancel == NO) {
    CGPoint windowLocation = [otherGestureRecognizer locationInView:otherGestureRecognizer.view];
    CGPoint clientPoint = [otherGestureRecognizer.view convertPoint:windowLocation
                                                             toView:_eventHandler.rootView];
    CGPoint viewPoint = [otherGestureRecognizer locationInView:gestureRecognizer.view];

    [self dispatchEvent:LynxEventTouchCancel
               toTarget:_eventHandler.touchTarget
                  phase:UITouchPhaseCancelled
            clientPoint:clientPoint
              pagePoint:clientPoint
              viewPoint:viewPoint];
    [_target dispatchTouch:LynxEventTouchCancel touches:_touches withEvent:_event];
    [self onTouchEndOrCancel];
    [self resetTouchEnv];
  }
  return !res;
}

// 返回 YES，otherGestureRecognizer 手势失败，gestureRecognizer 才开始执行
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  if ([self isDescendantOfLynxView:otherGestureRecognizer]) {
    return NO;
  } else {
    if ([self blockNativeEvent:gestureRecognizer]) {
      return NO;
    } else {
      return YES;
    }
  }
}

// 返回 YES，gestureRecognizer 手势失败，otherGestureRecognizer 才开始执行
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  if ([self isDescendantOfLynxView:otherGestureRecognizer]) {
    return NO;
  } else {
    if ([self blockNativeEvent:gestureRecognizer]) {
      return YES;
    } else {
      return NO;
    }
  }
}

- (BOOL)isAllTouchesAreCancelledOrEnded:(NSSet<UITouch*>*)touches {
  for (UITouch* touch in touches) {
    if (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved ||
        touch.phase == UITouchPhaseStationary) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)hasAnyTouchesChanged:(NSSet<UITouch*>*)touches {
  for (UITouch* touch in touches) {
    if (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved) {
      return YES;
    }
  }
  return NO;
}

@end
