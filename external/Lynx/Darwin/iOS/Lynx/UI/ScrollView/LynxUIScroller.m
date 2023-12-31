// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIScroller.h"
#import <objc/runtime.h>
#import "LynxComponentRegistry.h"
#import "LynxLayoutStyle.h"
#import "LynxPropsProcessor.h"
#import "LynxUI+Fluency.h"
#import "LynxUI+Internal.h"
#import "LynxUIMethodProcessor.h"
#import "LynxWeakProxy.h"

#import "LynxBounceView.h"
#import "LynxImpressionView.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#import "LynxUICollection.h"
#import "LynxView.h"
#import "UIScrollView+LynxFadingEdge.h"

#import "LynxGlobalObserver.h"
#import "LynxScrollView.h"
#import "UIScrollView+Nested.h"

NSString *const LynxEventScroll = @"scroll";
NSString *const LynxEventScrollEnd = @"scrollend";
NSString *const LynxEventScrollToUpper = @"scrolltoupper";
NSString *const LynxEventScrollToLower = @"scrolltolower";
NSString *const LynxEventContentSizeChange = @"contentsizechanged";
const NSInteger kScrollToLowerThreshold = 1;
const NSInteger kInvalidBounceDistance = -1;

@interface LynxUIScrollerProxy : NSObject
@property(nonatomic, weak) LynxUIScroller *scroller;
@property(nonatomic, assign) CGFloat rate;
@property(nonatomic, assign) BOOL enableScrollY;

- (instancetype)initWithScroller:(LynxUIScroller *)scroller
                            rate:(CGFloat)rate
                   enableScrollY:(BOOL)enableScrollY;
- (void)displayLinkAction;
@end

// to mock native flick
@interface FlickParameter : NSObject
@end

@implementation FlickParameter {
  float _duration;
  float _delta;
}

- (id)initFlick:(float)initvelocity
    decelerationRate:(float)decelerationRate
           threshold:(float)threshold
    oppositeBoundary:(float)oppositeBoundary
    positiveBoundary:(float)positiveBoundary {
  self = [super init];
  if (fabs(initvelocity) < 1e-3) {
    _duration = 0;
    _delta = 0;
    return self;
  }
  float dCoeff = 1000 * logf(decelerationRate);
  _duration = logf(-dCoeff * threshold / fabs(initvelocity)) / dCoeff;
  _delta = -initvelocity / dCoeff;
  // Boundary check
  if (_delta > positiveBoundary || _delta < oppositeBoundary) {
    _delta = initvelocity > 0 ? positiveBoundary : oppositeBoundary;
    _duration = logf(dCoeff * _delta / initvelocity + 1.) / logf(decelerationRate) * 0.001;
  }
  return self;
}

- (float)delta {
  return _delta;
}

- (void)setContentOffset:(UIScrollView *)scrollView destination:(CGPoint)offset {
  if (scrollView == nil || _duration < 1e-3) {
    return;
  }
  [scrollView layoutIfNeeded];
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:self->_duration
                          delay:0.
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^(void) {
                       [scrollView setContentOffset:offset];
                     }
                     completion:NULL];
  });
}
@end

@interface UIScrollView (Impression) <LynxImpressionParentView>

@end

@implementation UIScrollView (Impression)

- (void)setShouldManualExposure:(BOOL)shouldManualExposure {
  objc_setAssociatedObject(self, @selector(shouldManualExposure), @(shouldManualExposure),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)shouldManualExposure {
  return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

@implementation LynxUIScroller {
  BOOL _enableScrollY;
  BOOL _enableScrollEvent;
  BOOL _enableScrollEndEvent;
  BOOL _enableScrollToUpperEvent;
  BOOL _enableScrollToLowerEvent;
  BOOL _hasReachBottom;
  BOOL _hasReachTop;
  CGFloat _preScrollTop;
  CGFloat _preScrollLeft;
  CADisplayLink *_displayLink;
  NSMutableArray *_scrollerDelegates;
  NSInteger _upperThreshold;
  NSInteger _lowerThreshold;
  // for impression view
  CGFloat _sensitivity;
  BOOL _forceImpression;
  CGPoint _lastScrollPoint;

  HoverPosition hoverPosition;
  CGFloat _triggerBounceEventDistance;
  CGFloat _fadingEdge;
  BOOL _nestedUpdated;
  LynxBounceView *_upperBounceView;
  LynxBounceView *_lowerBounceView;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("scroll-view")
#else
LYNX_REGISTER_UI("scroll-view")
#endif

static Class<LynxScrollViewUIDelegate> kUIDelegate = nil;
+ (Class<LynxScrollViewUIDelegate>)UIDelegate {
  return kUIDelegate;
}

+ (void)setUIDelegate:(Class<LynxScrollViewUIDelegate>)UIDelegate {
  kUIDelegate = UIDelegate;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _enableScrollY = NO;
    _enableScrollToUpperEvent = NO;
    _enableScrollToLowerEvent = NO;
    _hasReachBottom = NO;
    _hasReachTop = NO;
    _preScrollTop = 0;
    _preScrollLeft = 0;
    _enableSticky = NO;
    _scrollerDelegates = [NSMutableArray new];
    _lowerThreshold = 0;
    _upperThreshold = 0;
    // for impression view
    _sensitivity = 4.f;
    _forceImpression = NO;
    _lastScrollPoint = CGPointMake(INFINITY, INFINITY);
    _nestedUpdated = NO;
  }
  return self;
}

- (UIView *)createView {
  LynxScrollView *scrollView = [LynxScrollView new];
  scrollView.autoresizesSubviews = NO;
  scrollView.clipsToBounds = YES;
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.showsHorizontalScrollIndicator = NO;
  scrollView.scrollEnabled = YES;
  scrollView.delegate = self;
  scrollView.enableNested = NO;
  scrollView.scrollY = NO;
  if (@available(iOS 11.0, *)) {
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }

  scrollView.shouldManualExposure = YES;
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(lynxImpressionWillManualExposureNotification:)
             name:LynxImpressionWillManualExposureNotification
           object:nil];

  return scrollView;
}

- (void)adjustContentOffsetForRTL:(CGFloat)prevXOffset {
  // for update, the content offset should be reset to old position instead of edge.
  if (!_enableScrollY && self.isRtl) {
    float lengthToShift = self.view.contentSize.width - self.view.frame.size.width;
    id scrollDelegate = self.view.delegate;
    self.view.delegate = nil;
    [[self view]
        setContentOffset:CGPointMake(lengthToShift - prevXOffset, self.view.contentOffset.y)
                animated:NO];
    self.view.delegate = scrollDelegate;
  }
}

- (void)propsDidUpdate {
  [super propsDidUpdate];
}

- (void)layoutDidFinished {
  [self updateContentSize];
  if (_enableSticky) {
    [self onScrollSticky:self.view.contentOffset.x withOffsetY:self.view.contentOffset.y];
  }
  _lastScrollPoint = CGPointMake(INFINITY, INFINITY);
  [self triggerSubviewsImpression];
  if (_bounceUIArray && _bounceUIArray.count > 0) {
    [self autoAddBounceView];
  }
}

- (void)onNodeReady {
  [super onNodeReady];

  [self.view updateFadingEdgeWithSize:_fadingEdge horizontal:!self.enableScrollY];
  [(UIScrollView *)self.view updateChildren];
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
  if ([child isKindOfClass:LynxBounceView.class]) {
    LynxBounceView *bounceChild = (LynxBounceView *)child;
    [self.bounceUIArray addObject:bounceChild];
    if (bounceChild.direction == LynxBounceViewDirectionTop ||
        bounceChild.direction == LynxBounceViewDirectionLeft) {
      _upperBounceView = bounceChild;
    } else {
      _lowerBounceView = bounceChild;
    }
  }

  [super insertChild:child atIndex:index];
}

- (void)applyRTL:(BOOL)rtl {
  ((LynxScrollView *)self.view).isRTL = rtl;
}

- (void)updateContentSize {
  float contentWidth = 0;
  float contentHeight = 0;
  if (!_enableScrollY) {
    for (LynxUI *child in self.children) {
      if (![child isKindOfClass:LynxBounceView.class]) {
        contentWidth = MAX(contentWidth, child.updatedFrame.size.width +
                                             child.updatedFrame.origin.x + child.margin.right);
      }
    }
    contentWidth += self.padding.right;
    contentHeight = self.frame.size.height - self.padding.bottom - self.padding.top;
  } else {
    for (LynxUI *child in self.children) {
      if (![child isKindOfClass:LynxBounceView.class]) {
        contentHeight = MAX(contentHeight, child.updatedFrame.size.height +
                                               child.updatedFrame.origin.y + child.margin.bottom);
      }
    }
    contentHeight += self.padding.bottom;
    contentWidth = self.frame.size.width - self.padding.left - self.padding.right;
  }

  if ([self view].contentSize.width != contentWidth ||
      [self view].contentSize.height != contentHeight) {
    CGFloat prevXOffset =
        self.view.contentSize.width - self.view.contentOffset.x - self.view.frame.size.width;
    [self view].contentSize = CGSizeMake(contentWidth, contentHeight);
    [self adjustContentOffsetForRTL:MAX(prevXOffset, -self.view.contentInset.right)];
    [self contentSizeDidChanged];
  }
}

- (CGPoint)contentOffset {
  return self.view.contentOffset;
}

- (BOOL)isScrollContainer {
  return YES;
}

- (void)resetContentOffset {
  if (self.enableScrollY) {
    self.view.contentOffset = CGPointMake(self.view.contentOffset.x, -self.view.contentInset.top);
  } else {
    if (self.isRtl) {
      self.view.contentOffset =
          CGPointMake(MAX(self.view.contentSize.width - self.view.frame.size.width +
                              self.view.contentInset.right,
                          -self.view.contentInset.right),
                      self.view.contentOffset.y);
    } else {
      self.view.contentOffset =
          CGPointMake(-self.view.contentInset.left, self.view.contentOffset.y);
    }
  }
}

- (void)setScrollY:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  _enableScrollY = value;
  self.view.scrollY = value;
  [self updateContentSize];
}

- (void)setScrollX:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  _enableScrollY = !value;
  self.view.scrollY = !value;
  [self updateContentSize];
}

- (void)setScrollYReverse:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  _enableScrollY = value;
  [self updateContentSize];
  CGFloat offsetY = self.view.contentOffset.y;
  if (value) {
    offsetY = self.view.contentSize.height - self.view.frame.size.height;
  }
  [[self view] setContentOffset:CGPointMake(self.view.contentOffset.x, offsetY) animated:NO];
}

- (void)setScrollXReverse:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  _enableScrollY = !value;
  [self updateContentSize];
  CGFloat offsetX = self.view.contentOffset.x;
  if (value) {
    offsetX = self.view.contentSize.width - self.view.frame.size.width;
  }
  [[self view] setContentOffset:CGPointMake(offsetX, self.view.contentOffset.y) animated:NO];
}

- (void)setEnableNested:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  self.view.enableNested = value;
}

- (void)setScrollLeft:(int)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = 0;
  }
  [[self view] setContentOffset:CGPointMake(value, self.view.contentOffset.y) animated:NO];
}

- (void)setScrollTop:(int)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = 0;
  }
  [[self view] setContentOffset:CGPointMake(self.view.contentOffset.x, value) animated:NO];
}

- (void)setScrollToIndex:(int)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = 0;
  }
  NSInteger index = value;
  if ([self view].subviews.count == 0 || index < 0) {
    return;
  }
  if (index > 0 && (NSUInteger)index < [self.children count]) {
    LynxUI *target = [self.children objectAtIndex:index];
    CGFloat offset = _enableScrollY ? target.view.frame.origin.y : target.view.frame.origin.x;
    if (_enableScrollY) {
      [[self view] setContentOffset:CGPointMake(0., offset) animated:false];
    } else {
      [[self view] setContentOffset:CGPointMake(offset, 0.) animated:false];
    }
  }
}

- (void)setEnableScrollMonitor:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  _enableScrollMonitor = value;
}

- (void)setScrollMonitorTag:(NSString *)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = nil;
  }
  _scrollMonitorTagName = value;
}

- (void)setScrollBarEnable:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  self.view.showsVerticalScrollIndicator = value;
  self.view.showsHorizontalScrollIndicator = value;
}

- (void)setBounces:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = YES;
  }
  self.view.bounces = value;
}

- (void)setEnableScroll:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = YES;
  }
  self.view.scrollEnabled = value;
}

- (void)setFadingEdge:(NSString *)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = nil;
  }

  _fadingEdge = (NSInteger)[self toPtWithUnitValue:value fontSize:0];
}

- (NSMutableArray<LynxBounceView *> *)bounceUIArray {
  if (!_bounceUIArray) {
    _bounceUIArray = [NSMutableArray array];
  }
  return _bounceUIArray;
}

- (void)addScrollerDelegate:(id<LynxUIScrollerDelegate>)delegate {
  LynxWeakProxy *proxy = [LynxWeakProxy proxyWithTarget:delegate];
  [_scrollerDelegates addObject:proxy];
}

- (void)removeScrollerDelegate:(id<LynxUIScrollerDelegate>)delegate {
  for (LynxWeakProxy *proxy in _scrollerDelegates) {
    if (proxy.target == delegate) {
      [_scrollerDelegates removeObject:proxy];
      break;
    }
  }
}

- (void)setUpperThreshold:(NSInteger)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = 0;
  }
  _upperThreshold = value;
}

- (void)setLowerThreshold:(NSInteger)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = 0;
  }
  _lowerThreshold = value;
}

- (CGPoint)getHitTestPoint:(CGPoint)inPoint {
  return CGPointMake(
      self.view.contentOffset.x + inPoint.x - self.getTransationX - self.frame.origin.x,
      self.view.contentOffset.y + inPoint.y - self.getTransationY - self.frame.origin.y);
}

- (void)eventDidSet {
  [super eventDidSet];
  _enableScrollToLowerEvent = NO;
  _enableScrollToUpperEvent = NO;
  _enableScrollEvent = NO;
  _enableScrollEndEvent = NO;
  if ([self.eventSet objectForKey:LynxEventScrollToLower]) {
    _enableScrollToLowerEvent = YES;
  }
  if ([self.eventSet objectForKey:LynxEventScrollToUpper]) {
    _enableScrollToUpperEvent = YES;
  }
  if ([self.eventSet objectForKey:LynxEventScroll]) {
    _enableScrollEvent = YES;
  }
  if ([self.eventSet objectForKey:LynxEventScrollEnd]) {
    _enableScrollEndEvent = YES;
  }
}
- (void)onScrollSticky:(CGFloat)offsetX withOffsetY:(CGFloat)offsetY {
  for (NSUInteger index = 0; index < self.children.count; index++) {
    LynxUI *ui = self.children[index];
    [ui checkStickyOnParentScroll:offsetX withOffsetY:offsetY];
  }
}

- (void)sendScrollEvent:(UIScrollView *)scrollView {
  CGFloat height = scrollView.frame.size.height;
  CGFloat contentYoffset = scrollView.contentOffset.y;
  CGFloat distanceYFromBottom = scrollView.contentSize.height - contentYoffset;

  CGFloat width = scrollView.frame.size.width;
  CGFloat contentXoffset = scrollView.contentOffset.x;
  CGFloat distanceXFromBottom = scrollView.contentSize.width - contentXoffset;

  CGFloat scrollTop = scrollView.contentOffset.y;
  CGFloat scrollLeft = scrollView.contentOffset.x;
  CGFloat deltaX = scrollLeft - _preScrollLeft;
  CGFloat deltaY = scrollTop - _preScrollTop;

  if (ABS(deltaX) <= CGFLOAT_EPSILON && ABS(deltaY) <= CGFLOAT_EPSILON) {
    return;
  }

  CGFloat lowerThreshold = MAX(_lowerThreshold, kScrollToLowerThreshold);

  // Rule for ReachToBottom/Top for RTL:
  // RTL.ReachToBottom = LTR.ReachToTop & RTL.ReachToTop = LTR.ReachToBottom

  NSString *eventType = _enableScrollEvent ? LynxEventScroll : nil;
  //  When ScrollToLower is triggered, the following equation should apply:
  //  scrollView.contentSize.height = scrollView.frame.size.height + scrollView.contentOffset.y.
  //  When scroll to bottom, the distanceYFromBottom still little bigger than height. So we use a
  //  threshold to fix it.
  if (_enableScrollToLowerEvent &&
      ((_enableScrollY && (distanceYFromBottom - lowerThreshold) <= height) ||
       (!_enableScrollY && ((!self.isRtl && (distanceXFromBottom - lowerThreshold <= width)) ||
                            (self.isRtl && contentXoffset <= 0))))) {
    if (!_hasReachBottom) {
      eventType = LynxEventScrollToLower;
      if (_enableScrollEvent) {
        [self sendScrollEvent:LynxEventScroll
                    scrollTop:scrollTop
                    scollleft:scrollLeft
                 scrollHeight:scrollView.contentSize.height
                  scrollWidth:scrollView.contentSize.width
                       deltaX:deltaX
                       deltaY:deltaY];
      }
    }
    _hasReachBottom = YES;
  } else {
    _hasReachBottom = NO;
  }

  if (_enableScrollToUpperEvent &&
      ((_enableScrollY && contentYoffset <= 0) ||
       (!_enableScrollY && ((!self.isRtl && contentXoffset <= 0) ||
                            (self.isRtl && (distanceXFromBottom - lowerThreshold <= width)))))) {
    if (!_hasReachTop) {
      eventType = LynxEventScrollToUpper;
      if (_enableScrollEvent) {
        [self sendScrollEvent:LynxEventScroll
                    scrollTop:scrollTop
                    scollleft:scrollLeft
                 scrollHeight:scrollView.contentSize.height
                  scrollWidth:scrollView.contentSize.width
                       deltaX:deltaX
                       deltaY:deltaY];
      }
    }
    _hasReachTop = YES;
  } else {
    _hasReachTop = NO;
  }

  if (eventType) {
    [self sendScrollEvent:eventType
                scrollTop:scrollTop
                scollleft:scrollLeft
             scrollHeight:scrollView.contentSize.height
              scrollWidth:scrollView.contentSize.width
                   deltaX:deltaX
                   deltaY:deltaY];
  }

  _preScrollTop = scrollTop;
  _preScrollLeft = scrollLeft;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // Notify scroll-view did scroll.
  [self.context.observer notifyScroll:nil];
  [self triggerSubviewsImpression];
  if ([self.view respondsToSelector:@selector(triggerNestedScrollView:)]) {
    if (self.view.enableNested && !_nestedUpdated) {
      _nestedUpdated = YES;
      if (!self.view.parentScrollView &&
          (!scrollView.childrenScrollView || scrollView.childrenScrollView.count == 0)) {
        [self.view updateChildren];
      }
    }
  }
  [scrollView triggerNestedScrollView:_enableScrollY];
  CGFloat scrollTop = scrollView.contentOffset.y;
  CGFloat scrollLeft = scrollView.contentOffset.x;
  if (_enableSticky) {
    [self onScrollSticky:scrollLeft withOffsetY:scrollTop];
  }

  [self sendScrollEvent:scrollView];
  [self updateLayerMaskOnFrameChanged];

  if (self.context != nil) {
    [self.context onGestureRecognizedByUI:self];
    [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                   selector:@selector(scrollerDidScroll:)]];
  }

  for (id<LynxUIScrollerDelegate> delegate in _scrollerDelegates) {
    if ([delegate respondsToSelector:@selector(scrollerDidScroll:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxUIScrollerDelegate::scrollerDidScroll");
      [delegate scrollerDidScroll:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
  if (_upperBounceView || _lowerBounceView) {
    [self triggerBounceWhileScroll:scrollView];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self sendScrollEndEvent:scrollView];
  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector(scrollerDidEndDecelerating:)]];
  for (id<LynxUIScrollerDelegate> delegate in _scrollerDelegates) {
    if ([delegate respondsToSelector:@selector(scrollerDidEndDecelerating:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIScrollerDelegate::scrollerDidEndDecelerating");
      [delegate scrollerDidEndDecelerating:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [self sendScrollEvent:scrollView];
  if (_enableScrollEndEvent) {
    if (!decelerate) {
      [self sendScrollEvent:LynxEventScrollEnd
                  scrollTop:scrollView.contentOffset.y
                  scollleft:scrollView.contentOffset.x
               scrollHeight:scrollView.contentSize.height
                scrollWidth:scrollView.contentSize.width
                     deltaX:0
                     deltaY:0];
    }
  }

  LynxScrollInfo *info = [self infoWithScrollView:scrollView
                                         selector:@selector(scrollerDidEndDragging:
                                                                    willDecelerate:)];
  info.decelerate = decelerate;
  [self postFluencyEventWithInfo:info];

  for (id<LynxUIScrollerDelegate> delegate in _scrollerDelegates) {
    if ([delegate respondsToSelector:@selector(scrollerDidEndDragging:willDecelerate:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIScrollerDelegate::scrollerDidEndDragging");
      [delegate scrollerDidEndDragging:scrollView willDecelerate:decelerate];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
  _isTransferring = NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector(scrollerWillBeginDragging:)]];

  for (id<LynxUIScrollerDelegate> delegate in _scrollerDelegates) {
    if ([delegate respondsToSelector:@selector(scrollerWillBeginDragging:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIScrollerDelegate::scrollerWillBeginDragging");
      [delegate scrollerWillBeginDragging:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self sendScrollEndEvent:scrollView];

  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector
                                                 (scrollerDidEndScrollingAnimation:)]];
  for (id<LynxUIScrollerDelegate> delegate in _scrollerDelegates) {
    if ([delegate respondsToSelector:@selector(scrollerDidEndScrollingAnimation:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIScrollerDelegate::scrollerDidEndScrollingAnimation");
      [delegate scrollerDidEndScrollingAnimation:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
    }
  }
}

- (void)scrollInto:(LynxUI *)value
          isSmooth:(BOOL)isSmooth
         blockType:(NSString *)blockType
        inlineType:(NSString *)inlineType {
  CGFloat scrollDistance = 0;
  if (_enableScrollY) {
    if ([@"nearest" isEqualToString:blockType]) {
      return;
    }
    if ([@"center" isEqualToString:blockType]) {
      scrollDistance -= (self.view.frame.size.height - value.view.frame.size.height) / 2;
    } else if ([@"end" isEqualToString:blockType]) {
      scrollDistance -= (self.view.frame.size.height - value.view.frame.size.height);
    }
    while (value != self) {
      scrollDistance += value.view.frame.origin.y;
      value = value.parent;
    }
    scrollDistance =
        MAX(0, MIN(self.view.contentSize.height - self.view.frame.size.height, scrollDistance));
    [self.view setContentOffset:CGPointMake(0, scrollDistance) animated:isSmooth];
  } else {
    if ([@"nearest" isEqualToString:inlineType]) {
      return;
    }
    if ([@"center" isEqualToString:inlineType]) {
      scrollDistance -= (self.view.frame.size.width - value.view.frame.size.width) / 2;
    } else if ([@"end" isEqualToString:inlineType]) {
      scrollDistance -= (self.view.frame.size.width - value.view.frame.size.width);
    }
    while (value != self) {
      scrollDistance += value.view.frame.origin.x;
      value = value.parent;
    }
    scrollDistance =
        MAX(0, MIN(self.view.contentSize.width - self.view.frame.size.width, scrollDistance));
    [self.view setContentOffset:CGPointMake(scrollDistance, 0) animated:isSmooth];
  }
}

- (void)sendScrollEvent:(NSString *)name
              scrollTop:(float)top
              scollleft:(float)left
           scrollHeight:(float)height
            scrollWidth:(float)width
                 deltaX:(float)x
                 deltaY:(float)y {
  NSDictionary *detail = @{
    @"deltaX" : [NSNumber numberWithFloat:x],
    @"deltaY" : [NSNumber numberWithFloat:y],
    @"scrollLeft" : [NSNumber numberWithFloat:left],
    @"scrollTop" : [NSNumber numberWithFloat:top],
    @"scrollHeight" : [NSNumber numberWithFloat:height],
    @"scrollWidth" : [NSNumber numberWithFloat:width]
  };
  LynxCustomEvent *scrollEventInfo = [[LynxDetailEvent alloc] initWithName:name
                                                                targetSign:[self sign]
                                                                    detail:detail];
  [self.context.eventEmitter dispatchCustomEvent:scrollEventInfo];
}

- (void)contentSizeDidChanged {
  NSDictionary *detail = @{
    @"scrollWidth" : @(self.view.contentSize.width),
    @"scrollHeight" : @(self.view.contentSize.height)
  };
  LynxCustomEvent *scrollEventInfo =
      [[LynxDetailEvent alloc] initWithName:LynxEventContentSizeChange
                                 targetSign:[self sign]
                                     detail:detail];
  [self.context.eventEmitter dispatchCustomEvent:scrollEventInfo];
}

- (CGFloat)clampScrollToPosition:(CGFloat)position {
  CGFloat lowerThreshold = 0.;
  CGFloat upperThreshold = CGFLOAT_MAX;
  if (_enableScrollY) {
    upperThreshold =
        MAX(lowerThreshold, [self.view contentSize].height - self.view.frame.size.height);
  } else {
    upperThreshold =
        MAX(lowerThreshold, [self.view contentSize].width - self.view.frame.size.width);
  }

  if (position < lowerThreshold) {
    position = lowerThreshold;
  } else if (position > upperThreshold) {
    position = upperThreshold;
  }

  return position;
}

- (void)sendScrollEndEvent:(UIScrollView *)scrollView {
  if (_enableScrollEndEvent) {
    [self sendScrollEvent:LynxEventScrollEnd
                scrollTop:scrollView.contentOffset.y
                scollleft:scrollView.contentOffset.x
             scrollHeight:scrollView.contentSize.height
              scrollWidth:scrollView.contentSize.width
                   deltaX:0
                   deltaY:0];
  }
}

LYNX_PROPS_GROUP_DECLARE(LYNX_PROP_DECLARE("ios-block-gesture-class", setIosBlockGestureClass,
                                           NSString *),
                         LYNX_PROP_DECLARE("force-can-scroll", setForceCanScroll, BOOL),
                         LYNX_PROP_DECLARE("ios-recognized-view-tag", setForceCanScroll, BOOL))

/**
 * @name: force-can-scroll
 * @description: On iOS, force-can-scroll should be used with ios-block-gesture-class,
 *ios-recognized-view-tag. Can be used alone on Android. scroll-view will consume gesture even when
 *it reaches the bounds，and block all nested scrollable containers，such as pageView component from
 *native、sliding left to return, etc. On iOS, it should also use ios-block-gesture-class to specify
 *the scrollable's className，along with ios-recognized-view-tag to specify the container's tag.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.11
 **/
LYNX_PROP_DEFINE("force-can-scroll", setForceCanScroll, BOOL) {
  if (requestReset) {
    value = NO;
  }
  ((LynxScrollView *)self.view).forceCanScroll = value;
}

/**
 * @name: ios-block-gesture-class
 * @description: iOS only. force-can-scroll should be used with
 *ios-block-gesture-class、ios-recognized-view-tag. Specify the class name of scrollable container
 *that should be blocked by force-can-scroll. Given by container's developer.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.11
 **/
LYNX_PROP_DEFINE("ios-block-gesture-class", setIosBlockGestureClass, NSString *) {
  if (requestReset) {
    value = [NSString string];
  }
  ((LynxScrollView *)self.view).blockGestureClass = NSClassFromString(value);
}

/**
 * @name: ios-recognized-view-tag
 * @description: iOS only. force-can-scroll should be used with
 *ios-block-gesture-class、ios-recognized-view-tag. Specify scrollable container's tag, the UIView's
 *tag. Set and given by container's developer. to fail its gesture
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.11
 **/
LYNX_PROP_DEFINE("ios-recognized-view-tag", setIosRecognizedViewTag, NSInteger) {
  if (requestReset) {
    value = 0;
  }
  ((LynxScrollView *)self.view).recognizedViewTag = value;
}

LYNX_UI_METHOD(scrollTo) {
  NSInteger index = -1;
  CGFloat offset = ((NSNumber *)[params objectForKey:@"offset"]).floatValue;
  if ([params objectForKey:@"index"]) {
    index = ((NSNumber *)[params objectForKey:@"index"]).integerValue;
  }
  BOOL animated = [[params objectForKey:@"smooth"] boolValue];
  UIScrollView *scrollView = [self view];

  if (index >= 0 && (NSUInteger)index < [self.children count]) {
    LynxUI *target = [self.children objectAtIndex:index];
    if (_enableScrollY) {
      offset += target.view.frame.origin.y;
    } else {
      if (self.isRtl) {
        offset = target.view.frame.origin.x + target.view.frame.size.width -
                 self.view.frame.size.width - offset;
      } else {
        offset += target.view.frame.origin.x;
      }
    }
  }
  offset = [self clampScrollToPosition:offset];
  if (_enableScrollY) {
    [scrollView setContentOffset:CGPointMake(0., offset) animated:animated];
  } else {
    [scrollView setContentOffset:CGPointMake(offset, 0.) animated:animated];
  }
  // If animated, triggered after the animation ends.
  if (!animated) {
    [self sendScrollEndEvent:scrollView];
  }
}

LYNX_UI_METHOD(autoScroll) {
  if ([[params objectForKey:@"start"] boolValue]) {
    [self startAutoScrollWithRate:[[params objectForKey:@"rate"] doubleValue] / 60];
  } else {
    [self stopAutoScroll];
  }
}

- (void)startAutoScrollWithRate:(CGFloat)rate {
  // when there is no 'rate' key in the 'params' dictionary, the value is zero.
  if (rate == 0) {
    return;
  }
  LynxUIScrollerProxy *proxy = [[LynxUIScrollerProxy alloc] initWithScroller:self
                                                                        rate:rate
                                                               enableScrollY:_enableScrollY];

  if (_displayLink) {
    [self stopAutoScroll];
  }
  _displayLink = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(displayLinkAction)];
  _displayLink.paused = NO;
  [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAutoScroll {
  if (_displayLink) {
    _displayLink.paused = YES;
    [_displayLink invalidate];
    _displayLink = nil;
  }
}

- (void)dealloc {
  if (_displayLink) {
    _displayLink.paused = YES;
    [_displayLink invalidate];
    _displayLink = nil;
  }
}

// lynx don't detect horizontal and vertical screen here.
- (void)frameDidChange {
  CGPoint contentOffset = [self.view contentOffset];
  [super frameDidChange];
  [self.view setContentOffset:contentOffset];
}

- (float)scrollLeftLimit {
  return [self view] == nil ? 0 : -self.view.contentInset.left;
}

- (float)scrollRightLimit {
  return [self view] == nil ? 0
                            : self.view.contentSize.width - self.view.bounds.size.width +
                                  self.view.contentInset.right;
}

- (float)scrollUpLimit {
  return [self view] == nil ? 0 : -self.view.contentInset.top;
}

- (float)scrollDownLimit {
  return [self view] == nil ? 0
                            : self.view.contentSize.height - self.view.bounds.size.height +
                                  self.view.contentInset.bottom;
}

- (BOOL)canScroll:(ScrollDirection)direction {
  if ([self view] == nil) return NO;
  switch (direction) {
    case SCROLL_LEFT:
      return [self contentOffset].x > [self scrollLeftLimit];
      break;
    case SCROLL_RIGHT:
      return [self contentOffset].x < [self scrollRightLimit];
      break;
    case SCROLL_UP:
      return [self contentOffset].y > [self scrollUpLimit];
      break;
    case SCROLL_DOWN:
      return [self contentOffset].y < [self scrollDownLimit];
      break;
    default:
      break;
  }
  return NO;
};

// private method, for scrollByX and scrollByY
- (void)scroll:(float)delta direction:(ScrollDirection)direction {
  if ([self view] == nil) return;
  CGPoint offset = [self contentOffset];
  if (direction == SCROLL_LEFT || direction == SCROLL_RIGHT) {
    offset.x += delta;
    offset.x = MAX(offset.x, [self scrollLeftLimit]);
    offset.x = MIN(offset.x, [self scrollRightLimit]);
  } else {
    offset.y += delta;
    offset.y = MAX(offset.y, [self scrollUpLimit]);
    offset.y = MIN(offset.y, [self scrollDownLimit]);
  }
  [[self view] setContentOffset:offset];
}

- (void)scrollByX:(float)delta {
  [self scroll:delta direction:SCROLL_LEFT];
}

- (void)scrollByY:(float)delta {
  [self scroll:delta direction:SCROLL_UP];
}

// private method, for flickX and flickY
- (void)flick:(float)velocity direction:(ScrollDirection)direction {
  if (self.view == nil || fabs(velocity) < 1e-3) return;
  bool isHorizontal = direction == SCROLL_LEFT || direction == SCROLL_RIGHT;
  CGPoint offset = [self contentOffset];
  float oppositeBoundary =
      isHorizontal ? [self scrollLeftLimit] - offset.x : [self scrollUpLimit] - offset.y;
  float positiveBoundary =
      isHorizontal ? [self scrollRightLimit] - offset.x : [self scrollDownLimit] - offset.y;
  __strong FlickParameter *flicker =
      [[FlickParameter alloc] initFlick:velocity
                       decelerationRate:self.view.decelerationRate
                              threshold:0.5 / [[UIScreen mainScreen] scale]
                       oppositeBoundary:oppositeBoundary
                       positiveBoundary:positiveBoundary];
  if (isHorizontal) {
    offset.x += [flicker delta];
  } else {
    offset.y += [flicker delta];
  }
  [flicker setContentOffset:self.view destination:offset];
}

- (void)flickX:(float)velocity {
  [self flick:velocity direction:SCROLL_LEFT];
}

- (void)flickY:(float)velocity {
  [self flick:velocity direction:SCROLL_UP];
}

#pragma mark - impression

- (void)lynxImpressionWillManualExposureNotification:(NSNotification *)noti {
  if (![self.context.rootView isKindOfClass:LynxView.class]) {
    return;
  }

  if ([noti.userInfo[LynxImpressionStatusNotificationKey] isEqualToString:@"show"]) {
    _forceImpression = [noti.userInfo[LynxImpressionForceImpressionBoolKey] boolValue];
    [self triggerSubviewsImpression];
  } else if ([noti.userInfo[LynxImpressionStatusNotificationKey] isEqualToString:@"hide"]) {
    [self triggerSubviewsExit];
  }
}

- (void)triggerSubviewsExit {
  _lastScrollPoint = CGPointMake(INFINITY, INFINITY);
  [self.view.subviews enumerateObjectsUsingBlock:^(__kindof LynxInnerImpressionView *_Nonnull obj,
                                                   NSUInteger idx, BOOL *_Nonnull stop) {
    if (![obj isKindOfClass:LynxInnerImpressionView.class]) {
      return;
    }

    [obj exit];
  }];
}

- (void)triggerSubviewsImpression {
  // When _forceImpression is True, check if the rootView is on the screen.
  // When _forceImpression is False, check if the self (aka. the current scrollView) is on the
  // screen.

  CGRect objRect = CGRectZero;
  if (_forceImpression) {
    objRect = [self.context.rootView convertRect:self.context.rootView.bounds toView:nil];
  } else {
    objRect = [self.view convertRect:self.view.bounds toView:nil];
  }

  CGRect intersectionRect = CGRectIntersection(self.view.window.bounds, objRect);

  if ((intersectionRect.size.height * intersectionRect.size.width == 0 || self.view.hidden) &&
      !_forceImpression) {
    return;
  }

  CGPoint contentOffset = self.view.contentOffset;

  if (fabs(_lastScrollPoint.x - contentOffset.x) > _sensitivity ||
      fabs(_lastScrollPoint.y - contentOffset.y) > _sensitivity) {
    _lastScrollPoint = self.view.contentOffset;

    // 进行递归检查，避免多个 x-scroll-view 嵌套的时候，
    // 某个外层 scroll-view 滚动的时候 x-impression-view 无法 impression
    [self.children
        enumerateObjectsUsingBlock:^(LynxUI *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          if ([obj isKindOfClass:LynxUIScroller.class]) {
            [(LynxUIScroller *)obj triggerSubviewsImpression];
          }
        }];

    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof LynxInnerImpressionView *_Nonnull obj,
                                                     NSUInteger idx, BOOL *_Nonnull stop) {
      if (![obj isKindOfClass:LynxInnerImpressionView.class]) {
        return;
      }

      CGRect objRect = [self.view convertRect:obj.frame fromView:self.view];
      CGRect intersectionRect = CGRectIntersection(self.view.bounds, objRect);

      CGFloat intersectionArea = intersectionRect.size.height * intersectionRect.size.width;
      if (intersectionArea == 0) {
        [obj exit];
      } else {
        CGFloat impressionArea =
            CGRectGetHeight(obj.bounds) * CGRectGetWidth(obj.bounds) * obj.impressionPercent;
        if (intersectionArea >= impressionArea) {
          [obj impression];
        } else {
          [obj exit];
        }
      }
    }];
  }
}

#pragma mark bounceView

- (void)autoAddBounceView {
  if (_bounceUIArray && _bounceUIArray.count > 0) {
    [_bounceUIArray enumerateObjectsUsingBlock:^(LynxBounceView *_Nonnull obj, NSUInteger idx,
                                                 BOOL *_Nonnull stop) {
      LynxBounceView *bounceUI = obj;
      UIView *bounceView = bounceUI.view;
      LynxBounceViewDirection bounceDirection = bounceUI.direction;
      float bounceSpace = bounceUI.space;

      CGFloat bounceHeight =
          CGRectGetHeight(bounceView.bounds) ?: CGRectGetHeight(self.view.bounds);
      CGFloat bounceWidth = CGRectGetWidth(bounceView.bounds) ?: CGRectGetWidth(self.view.bounds);

      switch (bounceDirection) {
        case LynxBounceViewDirectionRight: {
          if (!self.isRtl) {
            bounceView.frame =
                (CGRect){{MAX([self view].contentSize.width, CGRectGetWidth([self view].bounds)) +
                              bounceSpace,
                          self.padding.top},
                         {bounceWidth, bounceHeight}};
          } else {
            bounceView.frame = (CGRect){{-(bounceWidth + bounceSpace), self.padding.top},
                                        {bounceWidth, bounceHeight}};
            bounceUI.direction = LynxBounceViewDirectionLeft;
          }
        } break;

        case LynxBounceViewDirectionLeft: {
          if (!self.isRtl) {
            bounceView.frame = (CGRect){{-(bounceWidth + bounceSpace), self.padding.top},
                                        {bounceWidth, bounceHeight}};
          } else {
            bounceView.frame =
                (CGRect){{MAX([self view].contentSize.width, CGRectGetWidth([self view].bounds)) +
                              bounceSpace,
                          self.padding.top},
                         {bounceWidth, bounceHeight}};
            bounceUI.direction = LynxBounceViewDirectionRight;
          }

        } break;

        case LynxBounceViewDirectionTop: {
          bounceView.frame = (CGRect){{self.padding.left, -(bounceHeight + bounceSpace)},
                                      {bounceWidth, bounceHeight}};
        } break;

        case LynxBounceViewDirectionBottom: {
          bounceView.frame = (CGRect){{self.padding.left, MAX([self view].contentSize.height,
                                                              CGRectGetHeight([self view].bounds)) +
                                                              bounceSpace},
                                      {bounceWidth, bounceHeight}};
        } break;
      }

      [self.view addSubview:bounceView];
    }];
  }

  if (self.isRtl) {
    if (_upperBounceView || _lowerBounceView) {
      // In RTL, bounce-view will be the first cell of the scroll-view.
      // We need to update each ChildrenFrame.
      // In short, child.frame.origin.x -= width of bounceView.frame.
      [self adjustChildrenFrameToMaskBounceViewInRtl];
    }
    // In RTL, we need bounce-view info to calculate the content size of the scroll-view.
    // Hence [super layoutDidFinished] should be called after bounce-view logic.
    [super layoutDidFinished];
  }
}

- (void)scrollToBounces:(CGFloat)bounceDistance
            inDirection:(NSString *)direction
           withDistance:(CGFloat)eventDistance {
  if (!_bounceUIArray || _bounceUIArray.count == 0) {
    return;
  }

  NSDictionary *detail = @{
    @"direction" : direction ?: @"",
    @"triggerDistance" : [NSNumber numberWithFloat:eventDistance],
    @"bounceDistance" : [NSNumber numberWithFloat:bounceDistance]
  };
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"scrolltobounce"
                                                      targetSign:[self sign]
                                                          detail:detail];
  [self.context.eventEmitter sendCustomEvent:event];
}

- (void)triggerBounceWhileScroll:(UIScrollView *_Nonnull)scrollView {
  __block CGFloat upperBounceDistance = kInvalidBounceDistance;
  __block CGFloat lowerBounceDistance = kInvalidBounceDistance;
  [_bounceUIArray enumerateObjectsUsingBlock:^(LynxBounceView *_Nonnull obj, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
    switch (obj.direction) {
      case LynxBounceViewDirectionTop: {
        upperBounceDistance = obj.triggerBounceEventDistance;
      } break;
      case LynxBounceViewDirectionBottom: {
        lowerBounceDistance = obj.triggerBounceEventDistance;
      } break;
      case LynxBounceViewDirectionLeft: {
        upperBounceDistance = obj.triggerBounceEventDistance;
      } break;
      case LynxBounceViewDirectionRight: {
        lowerBounceDistance = obj.triggerBounceEventDistance;
      } break;
    }
  }];
  // If the contentOffset hit maxW/maxY, it means this scrollView hit the content border and start
  // to scroll bounce-view.
  if (!_enableScrollY) {
    CGFloat maxX = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame);
    if (maxX < 0) {
      maxX = 0;
    }
    // isTransferring and isDragging are used to avoid multiple callbacks when users slide back and
    // forth. isTransferring has to be set to false in endDragging.
    if (_isTransferring || self.view.isDragging) {
      return;
    }
    if (lowerBounceDistance != kInvalidBounceDistance) {
      if (scrollView.contentOffset.x >= maxX + lowerBounceDistance) {
        _isTransferring = YES;
        [self scrollToBounces:scrollView.contentOffset.x - maxX
                  inDirection:@"right"
                 withDistance:lowerBounceDistance];
      }
    }
    if (upperBounceDistance != kInvalidBounceDistance) {
      if (scrollView.contentOffset.x <= -upperBounceDistance) {
        _isTransferring = YES;
        [self scrollToBounces:scrollView.contentOffset.x
                  inDirection:@"left"
                 withDistance:upperBounceDistance];
      }
    }
  } else {
    if (_isTransferring || self.view.isDragging) {
      return;
    }
    CGFloat maxY = scrollView.contentSize.height - CGRectGetHeight(scrollView.frame);
    if (maxY < 0) {
      maxY = 0;
    }
    if (lowerBounceDistance != kInvalidBounceDistance) {
      if (scrollView.contentOffset.y >= maxY + lowerBounceDistance) {
        _isTransferring = YES;
        [self scrollToBounces:scrollView.contentOffset.y - maxY
                  inDirection:@"bottom"
                 withDistance:lowerBounceDistance];
      }
    }
    if (upperBounceDistance != kInvalidBounceDistance) {
      if (scrollView.contentOffset.y <= -upperBounceDistance) {
        _isTransferring = YES;
        [self scrollToBounces:scrollView.contentOffset.y
                  inDirection:@"top"
                 withDistance:upperBounceDistance];
      }
    }
  }
}

- (void)adjustChildrenFrameToMaskBounceViewInRtl {
  if (_enableScrollY) {
    float minHeight = INFINITY;
    for (LynxUI *child in self.children) {
      minHeight = MIN(minHeight, child.frame.origin.y);
    }
    // this if is true when the children upper space was occupied by bounceView
    // adjust heights to make sure views will cover bounceView
    if (_enableScrollY && _upperBounceView != nil &&
        minHeight == _upperBounceView.frame.size.height) {
      for (LynxUI *child in self.children) {
        [child updateFrame:(CGRect) {
          {child.frame.origin.x, child.frame.origin.y - minHeight}, {
            child.frame.size.width, child.frame.size.height
          }
        }
                    withPadding:child.padding
                         border:child.border
                         margin:child.margin
            withLayoutAnimation:NO];
      }
    }
  } else {
    float minWidth = INFINITY;
    for (LynxUI *child in self.children) {
      minWidth = MIN(minWidth, child.frame.origin.x);
    }
    // the same as height, but left space was occupied, so shift left.
    if (!_enableScrollY && _upperBounceView != nil &&
        minWidth == _upperBounceView.frame.size.width) {
      for (LynxUI *child in self.children) {
        [child updateFrame:(CGRect) {
          {child.frame.origin.x - minWidth, child.frame.origin.y}, {
            child.frame.size.width, child.frame.size.height
          }
        }
                    withPadding:child.padding
                         border:child.border
                         margin:child.margin
            withLayoutAnimation:NO];
      }
    }
  }
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  [super onListCellPrepareForReuse:itemKey withList:list];
  // restore contentOffset
  if (itemKey) {
    NSString *cacheKey = [NSString stringWithFormat:@"%@_scrollview_%@", itemKey, self.idSelector];
    if (list.listNativeStateCache[cacheKey]) {
      CGPoint offset = [list.listNativeStateCache[cacheKey] CGPointValue];
      [self.view setContentOffset:offset];
    }
  }
}

- (void)onListCellDisappear:(NSString *)itemKey
                      exist:(BOOL)isExist
                   withList:(LynxUICollection *)list {
  [super onListCellDisappear:itemKey exist:isExist withList:list];
  // store current contentOffset
  if (itemKey) {
    NSString *cacheKey = [NSString stringWithFormat:@"%@_scrollview_%@", itemKey, self.idSelector];
    if (isExist) {
      list.listNativeStateCache[cacheKey] = @(self.view.contentOffset);
    } else {
      [list.listNativeStateCache removeObjectForKey:cacheKey];
    }
  }
}

@end

@implementation LynxUIScrollerProxy

- (instancetype)initWithScroller:(LynxUIScroller *)scroller
                            rate:(CGFloat)rate
                   enableScrollY:(BOOL)enableScrollY {
  self = [super init];
  if (self) {
    self.scroller = scroller;
    self.rate = rate;
    self.enableScrollY = enableScrollY;
  }
  return self;
}

- (void)displayLinkAction {
  if (self.scroller) {
    if (self.enableScrollY) {
      if (self.scroller.view.bounds.size.height + self.scroller.view.contentOffset.y + self.rate >=
          self.scroller.view.contentSize.height) {
        self.rate = self.scroller.view.contentSize.height - self.scroller.view.contentOffset.y -
                    self.scroller.view.bounds.size.height;
        [self.scroller stopAutoScroll];
      }
      CGRect bounds = CGRectMake(
          self.scroller.view.contentOffset.x, self.scroller.view.contentOffset.y + self.rate,
          self.scroller.view.bounds.size.width, self.scroller.view.bounds.size.height);
      CGFloat prevY = self.scroller.view.bounds.origin.y;
      [self.scroller.view setBounds:bounds];
      if (self.scroller.view.bounds.origin.y != prevY) {
        [self.scroller scrollViewDidScroll:self.scroller.view];
      }
    } else {
      if (self.scroller.isRtl) {
        // Scroll to left and stop at the left edge.
        if (self.scroller.view.contentOffset.x - self.rate < 0) {
          self.rate = 0;
          [self.scroller stopAutoScroll];
        }
        CGRect bounds = CGRectMake(
            self.scroller.view.contentOffset.x - self.rate, self.scroller.view.contentOffset.y,
            self.scroller.view.bounds.size.width, self.scroller.view.bounds.size.height);
        CGFloat prevX = self.scroller.view.bounds.origin.x;
        [self.scroller.view setBounds:bounds];
        if (self.scroller.view.bounds.origin.x != prevX) {
          [self.scroller scrollViewDidScroll:self.scroller.view];
        }
      } else {
        // Scroll to right and stop at the right edge.
        if (self.scroller.view.bounds.size.width + self.scroller.view.contentOffset.x + self.rate >=
            self.scroller.view.contentSize.width) {
          self.rate = self.scroller.view.contentSize.width - self.scroller.view.contentOffset.x -
                      self.scroller.view.bounds.size.width;
          [self.scroller stopAutoScroll];
        }
        CGRect bounds = CGRectMake(
            self.scroller.view.contentOffset.x + self.rate, self.scroller.view.contentOffset.y,
            self.scroller.view.bounds.size.width, self.scroller.view.bounds.size.height);
        CGFloat prevX = self.scroller.view.bounds.origin.x;
        [self.scroller.view setBounds:bounds];
        if (self.scroller.view.bounds.origin.x != prevX) {
          [self.scroller scrollViewDidScroll:self.scroller.view];
        }
      }
    }
  }
}

@end
