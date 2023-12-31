//
//  UIScrollView+Lynx.m
//  Lynx
//
//  Copyright 2022 The Lynx Authors. All rights reserved.
//

#import <objc/runtime.h>
#import "LynxWeakProxy.h"
#import "UIScrollView+Lynx.h"

@interface LynxCustomScroll : NSObject

@property(readonly, nonatomic, weak) UIScrollView *scrollView;
@property(readonly, nonatomic, strong) CADisplayLink *displayLink;
@property(readonly, nonatomic, assign) NSTimeInterval duration;
@property(readonly, nonatomic, assign) CGPoint start;
@property(readonly, nonatomic, assign) CGPoint dist;
@property(readonly, nonatomic, assign) NSTimeInterval beginTime;
@property(readonly, nonatomic, copy) UIScrollViewLynxCompletion completeBlock;
@property(readonly, nonatomic, copy) UIScrollViewLynxProgressInterception interception;
@property(readonly, nonatomic, copy) UIScrollViewLynxTimingFunction timingFunction;
@property(nonatomic, assign) BOOL originalScrollEnabled;
@property(nonatomic, assign) CGFloat autoScrollRate;
@property(nonatomic, assign) BOOL isAutoScrollVertical;
@property(nonatomic, assign) BOOL isAutoScrollAutoStop;
@property(nonatomic, assign) LynxScrollViewTouchBehavior scrollBehavior;
@end

@implementation LynxCustomScroll

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
  if (self = [super init]) {
    _scrollView = scrollView;
    _displayLink = [CADisplayLink displayLinkWithTarget:[LynxWeakProxy proxyWithTarget:self]
                                               selector:@selector(tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
  }
  return self;
}

- (void)startAutoScroll:(NSTimeInterval)interval
               behavior:(LynxScrollViewTouchBehavior)behavior
                   rate:(CGFloat)rate
               autoStop:(BOOL)autoStop
               vertical:(BOOL)isVertical
               complete:(_Nullable UIScrollViewLynxCompletion)callback {
  if (!_displayLink.paused) {
    // if last scroll is not finished, reset scrollEnabled to original value
    self.scrollView.scrollEnabled = _originalScrollEnabled;
  }
  _originalScrollEnabled = self.scrollView.scrollEnabled;
  self.autoScrollRate = rate;
  self.isAutoScrollVertical = isVertical;
  self.isAutoScrollAutoStop = autoStop;
  self.scrollBehavior = behavior;
  if (behavior == LynxScrollViewTouchBehaviorForbid) {
    self.scrollView.scrollEnabled = NO;
  }
  if (@available(iOS 10.0, *)) {
    _displayLink.preferredFramesPerSecond = interval ? (1.0 / interval) : 0;
  } else if (@available(iOS 3.1, *)) {
    _displayLink.frameInterval = interval ? (interval / 0.016f) : 1;
  }
  _displayLink.paused = NO;
}

- (void)startWithDuration:(NSTimeInterval)duration
                 behavior:(LynxScrollViewTouchBehavior)behavior
                 interval:(NSTimeInterval)interval
                    start:(CGPoint)start
                      end:(CGPoint)end
           timingFunction:(_Nullable UIScrollViewLynxTimingFunction)timingFunction
                 progress:(_Nullable UIScrollViewLynxProgressInterception)interception
                 complete:(_Nullable UIScrollViewLynxCompletion)callback {
  if (!_displayLink.paused) {
    // if last scroll is not finished, reset scrollEnabled to original value
    self.scrollView.scrollEnabled = _originalScrollEnabled;
  }
  if (!CGPointEqualToPoint(start, end)) {
    _originalScrollEnabled = self.scrollView.scrollEnabled;

    switch (behavior) {
      case LynxScrollViewTouchBehaviorForbid:
        self.scrollView.scrollEnabled = NO;
        break;
      default:
        break;
    }
    _completeBlock = callback;
    _interception = interception;
    _timingFunction = timingFunction;
    _duration = duration;
    _beginTime = CFAbsoluteTimeGetCurrent();
    _start = start;
    _dist = CGPointMake(end.x - start.x, end.y - start.y);
    _scrollBehavior = behavior;
    if (@available(iOS 10.0, *)) {
      _displayLink.preferredFramesPerSecond = interval ? (1.0 / interval) : 0;
    } else if (@available(iOS 3.1, *)) {
      _displayLink.frameInterval = interval ? (interval / 0.016f) : 1;
    }

    _displayLink.paused = NO;
  } else if (callback) {
    callback(self.scrollView.scrollEnabled);
  }
}

- (void)tick:(CADisplayLink *)displayLink {
  if (self.autoScrollRate) {
    [self autoScrollTick];
    return;
  }

  switch (self.scrollBehavior) {
    case LynxScrollViewTouchBehaviorForbid:
      break;
    default:
      if (self.scrollView.tracking) {
        [self stop];
        return;
      }
  }

  double timeProgress = MIN(1.0, (CFAbsoluteTimeGetCurrent() - _beginTime) / _duration);
  //  NSLog(@"lynx scroll progress %@", @(timeProgress));
  //  NSLog(@"lynx scroll duration %@", @(displayLink.duration));
  //  NSLog(@"lynx scroll timestamp %@ %@", @(displayLink.timestamp * 1000),
  //        @(CFAbsoluteTimeGetCurrent()));

  double progress =
      _timingFunction ? _timingFunction(timeProgress) : [self easeInEaseOut:timeProgress];

  CGFloat x = _start.x + _dist.x * progress;
  CGFloat y = _start.y + _dist.y * progress;

  CGPoint targetOffset = CGPointMake(x, y);

  if (_interception) {
    targetOffset = _interception(timeProgress, progress, targetOffset);
  }

  [self.scrollView setContentOffset:targetOffset];

  if (progress >= 1.0) {
    [self stop];
  }
}

- (void)autoScrollTick {
  switch (self.scrollBehavior) {
    case LynxScrollViewTouchBehaviorPause:
      if (self.scrollView.tracking) {
        return;
      }
      break;
    case LynxScrollViewTouchBehaviorStop:
      if (self.scrollView.tracking) {
        [self stop];
        return;
      }
      break;
    case LynxScrollViewTouchBehaviorNone:
    case LynxScrollViewTouchBehaviorForbid:
      break;
  }

  BOOL reachToTheBounds = NO;

  CGPoint targetContentOffset = self.scrollView.contentOffset;
  if (self.isAutoScrollVertical) {
    targetContentOffset.y += self.autoScrollRate;

    // don not scroll beyond bounce
    CGFloat lower = self.scrollView.contentSize.height - self.scrollView.frame.size.height +
                    self.scrollView.contentInset.bottom;
    CGFloat upper = -self.scrollView.contentInset.top;
    if (targetContentOffset.y <= upper) {
      targetContentOffset.y = upper;
      reachToTheBounds = YES;
    } else if (targetContentOffset.y >= lower) {
      targetContentOffset.y = lower;
      reachToTheBounds = YES;
    }
  } else {
    targetContentOffset.x += self.autoScrollRate;
    // don not scroll beyond bounce

    CGFloat lower = self.scrollView.contentSize.width - self.scrollView.frame.size.width +
                    self.scrollView.contentInset.right;
    CGFloat upper = -self.scrollView.contentInset.left;

    if (targetContentOffset.x <= upper) {
      targetContentOffset.x = upper;
      reachToTheBounds = YES;
    } else if (targetContentOffset.x >= lower) {
      targetContentOffset.x = lower;
      reachToTheBounds = YES;
    }
  }

  [self.scrollView setContentOffset:targetContentOffset];

  if (reachToTheBounds && self.isAutoScrollAutoStop) {
    [self stop];
  }
}

- (void)stop {
  if (!_displayLink.paused) {
    BOOL willScrollEnabled = _originalScrollEnabled;
    if (_completeBlock) {
      willScrollEnabled = _completeBlock(willScrollEnabled);
    }
    _completeBlock = nil;
    _interception = nil;
    _timingFunction = nil;
    switch (_scrollBehavior) {
      case LynxScrollViewTouchBehaviorForbid:
        self.scrollView.scrollEnabled = willScrollEnabled;
        break;
      default:
        break;
    }
    _displayLink.paused = YES;
    [_displayLink invalidate];
  }
}

- (double)easeInEaseOut:(double)p {
  if (p < 0.2) {
    return 2 * p * p;
  } else if (p > 0.8) {
    return (-2 * p * p) + (4 * p) - 1;
  } else {
    return 0.08 + (p - 0.2) * 1.4;
  }
}

- (void)dealloc {
  [self stop];
}

@end

@implementation UIScrollView (Lynx)

- (LynxCustomScroll *)lynxCustomScroll {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setLynxCustomScroll:(LynxCustomScroll *)customScroll {
  objc_setAssociatedObject(self, @selector(lynxCustomScroll), customScroll,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setContentOffset:(CGPoint)contentOffset
                behavior:(LynxScrollViewTouchBehavior)behavior
                duration:(NSTimeInterval)duration
                interval:(NSTimeInterval)interval
                progress:(_Nullable UIScrollViewLynxProgressInterception)interception
                complete:(_Nullable UIScrollViewLynxCompletion)callback {
  [[self lynxCustomScroll] stop];

  [self setLynxCustomScroll:[[LynxCustomScroll alloc] initWithScrollView:self]];

  [[self lynxCustomScroll] startWithDuration:duration
                                    behavior:behavior
                                    interval:interval
                                       start:self.contentOffset
                                         end:contentOffset
                              timingFunction:nil
                                    progress:interception
                                    complete:callback];
}

- (void)autoScrollWithRate:(CGFloat)rate
                  behavior:(LynxScrollViewTouchBehavior)behavior
                  interval:(NSTimeInterval)interval
                  autoStop:(BOOL)autoStop
                  vertical:(BOOL)isVertical {
  [[self lynxCustomScroll] stop];

  [self setLynxCustomScroll:[[LynxCustomScroll alloc] initWithScrollView:self]];

  [[self lynxCustomScroll] startAutoScroll:interval
                                  behavior:behavior
                                      rate:rate
                                  autoStop:autoStop
                                  vertical:isVertical
                                  complete:nil];
}

- (void)scrollToTargetContentOffset:(CGPoint)contentOffset
                           behavior:(LynxScrollViewTouchBehavior)behavior
                           duration:(NSTimeInterval)duration
                           interval:(NSTimeInterval)interval
                           complete:(_Nullable UIScrollViewLynxCompletion)callback {
  [[self lynxCustomScroll] stop];

  [self setLynxCustomScroll:[[LynxCustomScroll alloc] initWithScrollView:self]];

  [[self lynxCustomScroll] startWithDuration:duration
                                    behavior:behavior
                                    interval:interval
                                       start:self.contentOffset
                                         end:contentOffset
                              timingFunction:^double(double input) {
                                // ease out
                                return 1 - pow(1 - input, 4);
                              }
                                    progress:nil
                                    complete:callback];
}

- (void)stopScroll {
  [[self lynxCustomScroll] stop];
}

- (void)setScrollEnableFromLynx:(BOOL)value {
  objc_setAssociatedObject(self, @selector(scrollEnableFromLynx), @(value),
                           OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)scrollEnableFromLynx {
  return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
