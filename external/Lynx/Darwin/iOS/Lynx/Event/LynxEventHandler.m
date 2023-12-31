// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxEventHandler+Internal.h"
#import "LynxLog.h"
#import "LynxTouchHandler+Internal.h"
#import "LynxTouchHandler.h"
#import "LynxUI+Internal.h"
#import "LynxUnitUtils.h"
#import "LynxView+Internal.h"
#import "LynxView.h"
#import "LynxViewInternal.h"
#import "LynxWeakProxy.h"
#import "UIView+Lynx.h"

#pragma mark - LynxEventHandler
@interface LynxEventHandler ()

@property(nonatomic, readwrite) BOOL gestureRecognized;

@end

#pragma mark - CustomGestureRecognizerDelegate
@interface CustomGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler;

@property(weak) LynxEventHandler* eventHandler;

@end

@implementation CustomGestureRecognizerDelegate

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler {
  self = [super init];
  if (self) {
    self.eventHandler = eventHandler;
  }
  return self;
}

@end

#pragma mark - TapGestureRecognizerDelegate
@interface TapGestureRecognizerDelegate : CustomGestureRecognizerDelegate

@end

@implementation TapGestureRecognizerDelegate

// 返回 YES，otherGestureRecognizer 手势失败，gestureRecognizer 才开始执行
// otherGestureRecognizer 为外部的手势时或者长按手势时，otherGestureRecognizers 失败后，tap
// 手势才会执行
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  return self.eventHandler.longPressRecognizer == otherGestureRecognizer;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
       shouldReceiveTouch:(UITouch*)touch {
  UIView* collectionView = nil;

  if ([touch.view isKindOfClass:[UICollectionViewCell class]]) {
    collectionView = touch.view.superview;
  } else if ([touch.view.superview isKindOfClass:[UICollectionViewCell class]]) {
    collectionView = touch.view.superview.superview;
  } else if ([touch.view isKindOfClass:[UICollectionView class]]) {
    collectionView = touch.view;
  }
  if ([collectionView isKindOfClass:[UICollectionView class]]) {
    return !((UICollectionView*)collectionView).isDecelerating;
  }
  return YES;
}

@end

#pragma mark - SimultaneousTapGestureRecognizerDelegate
@interface SimultaneousTapGestureRecognizerDelegate : TapGestureRecognizerDelegate

@end

@implementation SimultaneousTapGestureRecognizerDelegate

// 返回 YES，允许 gestureRecognizer 和 otherGestureRecognizer 同时触发。
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}

@end

#pragma mark - LongPressGestureRecognizerDelegate
@interface LongPressGestureRecognizerDelegate : CustomGestureRecognizerDelegate

@property(nonatomic, readwrite) BOOL disableLongpressAfterScroll;

@end

@implementation LongPressGestureRecognizerDelegate

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler {
  self = [super initWithEventHandler:eventHandler];
  if (self) {
    self.disableLongpressAfterScroll = NO;
  }
  return self;
}

// 返回 NO，不存在任何一种 otherGestureRecognizer 使得 otherGestureRecognizer 失败之后才开始执行
// gestureRecognizer。
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  // If this flag is true, long press gesture will not be recognized after triggering scrolling.
  if (self.disableLongpressAfterScroll) {
    if ([otherGestureRecognizer isKindOfClass:UIPanGestureRecognizer.class] &&
        [otherGestureRecognizer.view isKindOfClass:UIScrollView.class]) {
      if (((UIScrollView*)otherGestureRecognizer.view).isDecelerating) {
        return YES;
      }
    }
  }
  return NO;
}

// 返回 YES，允许 gestureRecognizer 和 otherGestureRecognizer 同时触发。
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  if (otherGestureRecognizer.state == UIGestureRecognizerStateBegan &&
      ![otherGestureRecognizer.view isDescendantOfView:self.eventHandler.rootView]) {
    self.eventHandler.gestureRecognized = YES;
  }
  return YES;
}

@end

#pragma mark - PanGestureRecognizerDelegate
@interface PanGestureRecognizerDelegate : CustomGestureRecognizerDelegate

@property(nonatomic, readonly) NSArray<LynxWeakProxy*>* gestures;

@end

@implementation PanGestureRecognizerDelegate {
  NSMutableDictionary<NSString*, LynxWeakProxy*>* _innerGestures;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
  return YES;
}

- (instancetype)initWithEventHandler:(LynxEventHandler*)eventHandler {
  self = [super initWithEventHandler:eventHandler];
  if (self) {
    _innerGestures = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (NSArray<LynxWeakProxy*>*)gestures {
  return [_innerGestures allValues];
}

// 返回 YES，otherGestureRecognizer 手势失败，gestureRecognizer 才开始执行
- (BOOL)gestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  return NO;
}

// 返回 YES，gestureRecognizer 手势失败，otherGestureRecognizer 才开始执行
- (BOOL)gestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  if (![gestureRecognizer.view isEqual:otherGestureRecognizer.view]) {
    [_innerGestures setValue:[LynxWeakProxy proxyWithTarget:otherGestureRecognizer]
                      forKey:[@(otherGestureRecognizer.hash) stringValue]];
    return YES;
  }
  return NO;
}

// 返回 YES，允许 gestureRecognizer 和 otherGestureRecognizer 同时触发。
- (BOOL)gestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  if ([gestureRecognizer.view isEqual:otherGestureRecognizer.view]) {
    return YES;
  }
  if (gestureRecognizer.state == UIGestureRecognizerStatePossible ||
      gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    return YES;
  }
  return NO;
}

@end

#pragma mark - LynxEventHandler
@implementation LynxEventHandler {
  __weak LynxUIOwner* _uiOwner;
  __weak LynxUI* _rootUI;
  __weak id<LynxEventTarget> _touchTarget;
  CGPoint _longPressPoint;
  CustomGestureRecognizerDelegate* _tapDelegate;
  LongPressGestureRecognizerDelegate* _longPressDelegate;
  UIPanGestureRecognizer* _panGestureRecognizer;
  PanGestureRecognizerDelegate* _panGestureDelegate;
  float range_;
  NSMutableSet* _set;
}

- (void)dealloc {
  _touchRecognizer.target = nil;
  _touchRecognizer.preTarget = nil;
}

- (instancetype)initWithRootView:(UIView*)rootView {
  return [self initWithRootView:rootView withRootUI:nil];
}

- (instancetype)initWithRootView:(UIView*)rootView withRootUI:(LynxUI*)rootUI {
  self = [super init];
  if (self) {
    _rootView = rootView;
    _rootUI = rootUI;
    _touchRecognizer = [[LynxTouchHandler alloc] initWithEventHandler:self];
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(dispatchTapEvent:)];
    _longPressRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(dispatchLongPressEvent:)];

    _tapDelegate = [[TapGestureRecognizerDelegate alloc] initWithEventHandler:self];
    _longPressDelegate = [[LongPressGestureRecognizerDelegate alloc] initWithEventHandler:self];

    _tapRecognizer.delegate = _tapDelegate;
    _tapRecognizer.cancelsTouchesInView = YES;
    _longPressRecognizer.delegate = _longPressDelegate;
    _longPressRecognizer.cancelsTouchesInView = YES;

    [_rootView addGestureRecognizer:_tapRecognizer];
    [_rootView addGestureRecognizer:_longPressRecognizer];
    [_rootView addGestureRecognizer:_touchRecognizer];

    // Defaul value is nil. If LynxUI has consume-slide-event prop, init _panGestureRecognizer and
    // _panGestureDelegate.
    _panGestureRecognizer = nil;
    _panGestureDelegate = nil;

    _longPressPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
    range_ = 50;
    self.gestureRecognized = NO;
    _set = [NSMutableSet set];
  }
  return self;
}

- (void)attachLynxView:(LynxView*)rootView {
  _rootView = rootView;
  [_rootView addGestureRecognizer:_tapRecognizer];
  [_rootView addGestureRecognizer:_longPressRecognizer];
  [_rootView addGestureRecognizer:_touchRecognizer];
  if (_panGestureRecognizer != nil) {
    [_rootView addGestureRecognizer:_panGestureRecognizer];
  }
}

- (LynxCustomEvent*)generateGestureEvent:(UIGestureRecognizer*)sender
                                withName:(NSString*)name
                                      ui:(id<LynxEventTarget>)ui {
  CGPoint pagePoint = [sender locationInView:_rootView];
  NSDictionary* detail = @{
    @"x" : [NSNumber numberWithFloat:pagePoint.x],
    @"y" : [NSNumber numberWithFloat:pagePoint.y]
  };
  LynxCustomEvent* gestureEventInfo = [[LynxDetailEvent alloc] initWithName:name
                                                                 targetSign:ui.signature
                                                                     detail:detail];
  return gestureEventInfo;
}

- (BOOL)touchUI:(id<LynxEventTarget>)ui isDescendantOfUI:(id<LynxEventTarget>)pre {
  if (_touchTarget.signature == pre.signature) {
    return YES;
  }
  BOOL res = NO;
  if (ui == nil || pre == nil) {
    return res;
  }
  id<LynxEventTarget> parent = ui;
  while (parent != nil && parent != parent.parentTarget) {
    if (parent == pre) {
      res = YES;
      break;
    }
    parent = parent.parentTarget;
  }
  return res;
}

- (void)dispatchTapEvent:(UITapGestureRecognizer*)sender {
  LLogInfo(@"Lynxview LynxEventHandler dispatchTapEvent %p: ", self.rootView);

  CGPoint windowLocation = [sender locationInView:sender.view];
  CGPoint clientPoint = [sender.view convertPoint:windowLocation toView:_rootView];
  if ([self touchUI:[self hitTestInner:clientPoint withEvent:nil]
          isDescendantOfUI:_touchRecognizer.preTarget]) {
    CGPoint viewPoint = clientPoint;
    if ([self.touchRecognizer.preTarget isKindOfClass:[LynxUI class]]) {
      LynxUI* ui = (LynxUI*)self.touchRecognizer.preTarget;
      viewPoint = [sender locationInView:ui.view];
    }
    LynxTouchEvent* event =
        [[LynxTouchEvent alloc] initWithName:LynxEventTap
                                   targetTag:_touchRecognizer.preTarget.signature
                                 clientPoint:clientPoint
                                   pagePoint:clientPoint
                                   viewPoint:viewPoint];
    [_eventEmitter dispatchTouchEvent:event target:_touchRecognizer.preTarget];
  }
}

- (void)dispatchLongPressEvent:(UILongPressGestureRecognizer*)sender {
  LLogInfo(@"Lynxview LynxEventHandler dispatchLongPressEvent %p: ", self.rootView);

  if (_touchTarget == nil) {
    return;
  }
  CGPoint windowLocation = [sender locationInView:sender.view];
  CGPoint clientPoint = [sender.view convertPoint:windowLocation toView:_rootView];
  CGPoint viewPoint = clientPoint;
  if ([self.touchRecognizer.preTarget isKindOfClass:[LynxUI class]]) {
    LynxUI* ui = (LynxUI*)self.touchRecognizer.preTarget;
    viewPoint = [sender locationInView:ui.view];
  }

  if (sender.state == UIGestureRecognizerStateBegan) {
    LynxTouchEvent* event = [[LynxTouchEvent alloc] initWithName:LynxEventLongPress
                                                       targetTag:_touchTarget.signature
                                                     clientPoint:clientPoint
                                                       pagePoint:clientPoint
                                                       viewPoint:viewPoint];
    if (![_eventEmitter dispatchTouchEvent:event target:_touchTarget]) {
      _longPressPoint = clientPoint;
      self.gestureRecognized = NO;
      [self resetEventEnv];
    }
    if ([_rootView isKindOfClass:[LynxView class]]) {
      [((LynxView*)_rootView) onLongPress];
    }
    _touchRecognizer.tapSlop = range_;
  } else if (sender.state == UIGestureRecognizerStateChanged) {
    if (_longPressPoint.x != -FLT_MAX && _longPressPoint.y != -FLT_MAX) {
      if (fabs(clientPoint.x - _longPressPoint.x) > range_ ||
          fabs(clientPoint.y - _longPressPoint.y) > range_) {
        _longPressPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
      }
    }
  } else if (sender.state == UIGestureRecognizerStateEnded) {
    if (_longPressPoint.x != -FLT_MAX && _longPressPoint.y != -FLT_MAX && !self.gestureRecognized &&
        [self canRespondTapOrClickEvent:_touchTarget] &&
        [self touchUI:[self hitTestInner:clientPoint withEvent:nil]
            isDescendantOfUI:_touchRecognizer.preTarget]) {
      LynxTouchEvent* event =
          [[LynxTouchEvent alloc] initWithName:LynxEventTap
                                     targetTag:_touchRecognizer.preTarget.signature
                                   clientPoint:clientPoint
                                     pagePoint:clientPoint
                                     viewPoint:viewPoint];
      [_eventEmitter dispatchTouchEvent:event target:_touchRecognizer.preTarget];
      _longPressPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
    }
  } else if (sender.state == UIGestureRecognizerStateCancelled ||
             sender.state == UIGestureRecognizerStateFailed) {
    _longPressPoint = CGPointMake(-FLT_MAX, -FLT_MAX);
    self.gestureRecognized = NO;
    [self resetEventEnv];
  }
}

// Only when a LynxUI has "consume-slide-event" property, needCheckConsumeSlideEvent could be
// executed. Otherwise, needCheckConsumeSlideEvent will not be executed, which causes the
// UIPanGestureRecognizer will not be added to the LynxView, consistent with the previous behavior,
// to avoid breaking changes.
- (void)needCheckConsumeSlideEvent {
  if (_panGestureRecognizer && _panGestureDelegate) {
    return;
  }

  // Init gesture
  _panGestureRecognizer =
      [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dispatchPanEvent:)];
  // Init delegate
  _panGestureDelegate = [[PanGestureRecognizerDelegate alloc] initWithEventHandler:self];
  _panGestureRecognizer.delegate = _panGestureDelegate;
  _panGestureRecognizer.cancelsTouchesInView = self.tapRecognizer.cancelsTouchesInView;
  [_rootView addGestureRecognizer:_panGestureRecognizer];
}

- (BOOL)consumeSlideEvents:(CGFloat)angle {
  id<LynxEventTarget> target = _touchTarget;
  while (target != nil && target != target.parentTarget) {
    if ([target consumeSlideEvent:angle]) {
      return YES;
    }
    target = target.parentTarget;
  }
  return NO;
}

- (void)dispatchPanEvent:(UIPanGestureRecognizer*)sender {
  // Calculate the distance and angle of finger movement.
  CGFloat distanceX = [sender translationInView:sender.view].x;
  CGFloat distanceY = [sender translationInView:sender.view].y;

  // To avoid the dead zone in angle calculation during the initial stage of finger movement, when
  // distanceX and distanceY are small, return true first to make LynxView consume the event. When
  // the finger moves beyond a certain threshold, calculate the angle to determine whether to
  // consume the slide event.
  CGFloat threshold = 10;
  if (fabs(distanceX) <= threshold && fabs(distanceY) <= threshold) {
    return;
  }

  // Use atan2(y, x) * 180 / PI to calculate the angle.
  CGFloat semicircleAngle = 180;
  CGFloat angle = atan2(distanceY, distanceX) * semicircleAngle / M_PI;
  if ([self consumeSlideEvents:angle]) {
    [((PanGestureRecognizerDelegate*)sender.delegate).gestures
        enumerateObjectsUsingBlock:^(LynxWeakProxy* _Nonnull obj, NSUInteger idx,
                                     BOOL* _Nonnull stop) {
          ((UIGestureRecognizer*)obj).state = UIGestureRecognizerStateFailed;
        }];
    return;
  }
  sender.state = UIGestureRecognizerStateFailed;
}

- (void)updateUiOwner:(LynxUIOwner*)owner eventEmitter:(LynxEventEmitter*)eventEmitter {
  _uiOwner = owner;
  _eventEmitter = eventEmitter;
}

// should be called when touch target has been found, will not change _touchTarget
- (id<LynxEventTarget>)hitTestInner:(CGPoint)point withEvent:(UIEvent*)event {
  if (_rootUI == nil) {
    _rootUI = (LynxUI*)_uiOwner.rootUI;
  }
  return [_rootUI hitTest:point withEvent:event];
}

// should be called when looking for the target for the first time, touchTarget will be recorded
- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  if (_rootUI == nil) {
    _rootUI = (LynxUI*)_uiOwner.rootUI;
  }
  _touchTarget = [self hitTestInner:point withEvent:event];
  return _touchTarget;
}

- (void)onGestureRecognized {
  self.gestureRecognized = YES;
  if (_touchRecognizer != nil) {
    [_touchRecognizer onGestureRecognized];
  }
}

- (void)onGestureRecognizedByEventTarget:(id<LynxEventTarget>)ui {
  if (_set != nil) {
    [_set addObject:@(ui.signature)];
  }
}

- (void)resetEventEnv {
  [_set removeAllObjects];
}

- (BOOL)canRespondTapOrClickEvent:(id<LynxEventTarget>)ui {
  if (ui == nil) {
    return NO;
  }
  if (_set == nil || [_set count] == 0) {
    return YES;
  }
  BOOL res = YES;
  id<LynxEventTarget> parent = ui;
  while (parent != nil && parent.parentTarget != parent) {
    if ([_set containsObject:@(parent.signature)]) {
      res = NO;
      break;
    }
    parent = parent.parentTarget;
  }
  return res;
}

- (id<LynxEventTarget>)touchTarget {
  return _touchTarget;
}

- (void)setEnableViewReceiveTouch:(BOOL)enable {
  if (enable) {
    _tapRecognizer.cancelsTouchesInView = NO;
    _longPressRecognizer.cancelsTouchesInView = NO;
    _panGestureRecognizer.cancelsTouchesInView = NO;
    if (_panGestureRecognizer != nil) {
      _panGestureRecognizer.cancelsTouchesInView = NO;
    }
  }
}

- (void)setDisableLongpressAfterScroll:(bool)value {
  _longPressDelegate.disableLongpressAfterScroll = value;
}

// issue: #7022, In some scenarios, users want the LynxTap gesture and the outer tap gesture to be
// triggered at the same time. So add the enableSimultaneousTap configuration. When
// enableSimultaneousTap is set, LynxTap gestures and outer tap gestures can be triggered at the
// same time.
- (void)setEnableSimultaneousTap:(BOOL)enable {
  if (enable) {
    _tapDelegate = [[SimultaneousTapGestureRecognizerDelegate alloc] initWithEventHandler:self];
    _tapRecognizer.delegate = _tapDelegate;
  }
}

- (void)setTapSlop:(NSString*)tapSlop {
  range_ = [LynxUnitUtils toPtFromUnitValue:tapSlop
                               rootFontSize:0
                                curFontSize:0
                                  rootWidth:0
                                 rootHeight:0
                              withDefaultPt:0];
}

- (void)setLongPressDuration:(int32_t)value {
  // If long press duration < 0, do not set this negative value.
  if (value < 0) {
    return;
  }
  NSTimeInterval duration = value / 1000.0;
  ((UILongPressGestureRecognizer*)_longPressRecognizer).minimumPressDuration = duration;
}

@end
