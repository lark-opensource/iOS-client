//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxFoldViewLight.h"
#import "BDXLynxFoldViewHeaderLight.h"
#import "BDXLynxFoldViewSlotLight.h"
#import "BDXLynxFoldViewToolBarLight.h"
#import "UIScrollView+FoldView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/UIView+Lynx.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxGlobalObserver.h>

@protocol BDXLynxFoldViewLightProtocol <NSObject>

- (void)foldViewDidScroll:(UIScrollView *)scrollView;

@end
// todo pixel to 1dp

@interface LynxFoldView () <UIScrollViewDelegate>
@property (nonatomic, assign) CGFloat threshold;
@property (nonatomic, weak) id<BDXLynxFoldViewLightProtocol> uiDelegate;
@property (nonatomic, weak) LynxUI *potentialRootScrollableLynxUI;
@property (nonatomic, weak) UIScrollView *nestedScrollView;
@property (nonatomic, assign) BOOL allowNestScrollViewBounces;
@property (nonatomic, weak) UIView *tabbarView;
@property (nonatomic, weak) UIView *slotDragView;
@property (nonatomic, assign) CGFloat expandHeight;
@property (nonatomic, assign) BOOL duringKVO;
@property (nonatomic, assign) BOOL duringDidScroll;
@property (nonatomic, assign) CGFloat limitedContentOffsetY;
@property (nonatomic, assign) CGFloat nestLimitedContentOffsetY;
@property (nonatomic, assign) BOOL scrollAttached; // if YES, scroll like normal foldview. if NO, means self is not fold && nest_scrollview is not at top
@property (nonatomic, assign) BOOL forceScrollDetach;
@property (nonatomic, assign) CGFloat scrollViewFilter;
@property (nonatomic, strong) NSArray<NSString *> *excludeScrollViewNames;
@end

@implementation LynxFoldView
// todo contentoffset with insets

- (instancetype)init {
  if (self = [super init]) {
    self.alwaysBounceVertical = YES;
    self.alwaysBounceHorizontal = NO;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.delegate = self;
    self.scrollsToTop = NO;
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.threshold = 1.0 / [UIScreen mainScreen].scale;
  }
  return self;
}

- (BOOL)checkNestedScrollView:(UIScrollView *)scrollview {
  if ([self checkBlockList:scrollview]) {
    return NO;
  }
  if ([self checkAllowList:scrollview]) {
    return YES;
  }
  return [self checkVisibleVerticalScrollView:scrollview];
}

- (BOOL)checkVisibleVerticalScrollView:(UIScrollView *)scrollview {
  if (![scrollview isKindOfClass:UIScrollView.class]) {
    return NO;
  }
  if (scrollview.alwaysBounceHorizontal || scrollview.contentSize.width > scrollview.bounds.size.width) {
    return NO;
  }
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  NSString *name = [scrollview respondsToSelector:@selector(name)] ? [scrollview performSelector:@selector(name)] : nil;
#pragma clang diagnostic pop
  if (name) {
    for (NSString *exclude in self.excludeScrollViewNames) {
      if ([name isEqualToString:exclude]) {
        return NO;
      }
    }
  }
  
  // Test if the scroll view is visible in fold view by checking the center point
  BOOL scrollViewVisibleInFoldView = NO;
  CGFloat centerX = [scrollview convertPoint:CGPointMake(scrollview.bounds.size.width / 2.0, 0) toView:self].x;
  if (centerX >= 0 && centerX <= self.bounds.size.width) {
    scrollViewVisibleInFoldView = YES;
  }
  
  if (scrollViewVisibleInFoldView && (scrollview.frame.size.height >= (self.contentSize.height - self.expandHeight) * self.scrollViewFilter)) {
    return YES;
  }
  return NO;
}

- (BOOL)checkAllowList:(UIScrollView *)scrollview {
  for (Class cls in @[NSClassFromString(@"LynxUICollectionView"), NSClassFromString(@"LynxScrollView")]) {
    if ([scrollview isKindOfClass:cls] && [self checkVisibleVerticalScrollView:scrollview]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)checkBlockList:(UIScrollView *)scrollview {
  for (Class cls in @[NSClassFromString(@"BDXLynxViewPager"), NSClassFromString(@"BDXLynxSwiperView")]) {
    if ([scrollview isKindOfClass:cls]) {
      return YES;
    }
  }
  return NO;
}

- (UIScrollView *)nestedScrollView {
  if (!_nestedScrollView) {
    UIScrollView *potentialScrollableView = (UIScrollView *)self.potentialRootScrollableLynxUI.view;
    if ([self checkNestedScrollView:potentialScrollableView]) {
      _nestedScrollView = potentialScrollableView;
    } else if ([self.potentialRootScrollableLynxUI isKindOfClass:NSClassFromString(@"BDXLynxViewPagerLight")]) {
      _nestedScrollView = [self findNestedScrollView:potentialScrollableView.subviews.firstObject.subviews];
    } else {
      _nestedScrollView = [self findNestedScrollView:potentialScrollableView.subviews];
    }
    __weak typeof(self) weakSelf = self;
    [_nestedScrollView foldview_addObserverBlockForKeyPath:@"contentOffset" block:^(__weak id  _Nonnull obj, id  _Nonnull oldVal, id  _Nonnull newVal) {
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf observeValue:newVal ofObject:obj];
    }];
//    [_nestedScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    self.limitedContentOffsetY = self.contentOffset.y;
    self.nestLimitedContentOffsetY = _nestedScrollView.contentOffset.y;
    if (!_nestedScrollView) {
      self.scrollAttached = YES;
    } else if (!self.scrollAttached) {
      // check if attached (nest_scrollview at top, or, self folded)
      self.scrollAttached = [self checkAttached];
    }
  }
  return _nestedScrollView;
}

- (BOOL)isFold {
  return ABS(self.contentOffset.y - self.expandHeight) < self.threshold;
}

- (BOOL)isFullyExpand {
  return self.contentOffset.y <= 0;
}



- (BOOL)checkAttached {
  return (self.nestedScrollView.contentOffset.y <= self.threshold) || [self isFold];
}




#pragma mark - KVO

- (void)observeValue:(id)value ofObject:(id)object {
  if (self.forceScrollDetach) {
    return;
  }
  if (!self.duringKVO && object == _nestedScrollView) {
    self.duringKVO = YES;
    CGPoint contentOffset = [value CGPointValue];
    CGFloat originY = contentOffset.y;
    // check if reattached
    if (!self.scrollAttached) {
      self.scrollAttached = [self checkAttached];
    }
    
    // Take the scrollview's padding into account. On iOS, if a ScrollView has top-padding, the top of it will be -contentInset.top
    CGFloat topMost = _nestedScrollView ? -_nestedScrollView.contentInset.top : 0;
    
    // if attached and not fold, stick nest_scrollview to top
    if (self.scrollAttached) {
      if (![self isFold]) {
        // if fully expand, allow bounces if needed, else, sticy to 0 (or inset.top, created by refreshview)
        if ([self isFullyExpand]){
          contentOffset.y = MIN(topMost, self.allowNestScrollViewBounces ? contentOffset.y : topMost);
        } else {
          contentOffset.y = self.allowNestScrollViewBounces ? -self.nestedScrollView.contentInset.top : topMost;
        }
        // only if contentOffset is actually changed, cause it may break bounces anim
        if (contentOffset.y != originY) {
          [self.nestedScrollView setContentOffset:contentOffset];
        }
      }
    }
    
    // do not allow bounces if not fully expand
    if (![self isFullyExpand] && contentOffset.y < topMost) {
        contentOffset.y = topMost;
        [self.nestedScrollView setContentOffset:contentOffset];
    }
    
    // if not attached, make sure nest_scrollview can not scroll to upper
    if (!self.scrollAttached) {
      if (contentOffset.y > self.nestLimitedContentOffsetY) {
        contentOffset.y = self.nestLimitedContentOffsetY;
        [self.nestedScrollView setContentOffset:contentOffset];
      } else {
        self.nestLimitedContentOffsetY = contentOffset.y;
      }
    }
    
    self.duringKVO = NO;
  }
}


- (void)clearNestedScrollView {
  [_nestedScrollView foldview_removeObserverBlocksForKeyPath:@"contentOffset"];
//  [_nestedScrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
  _nestedScrollView = nil;
  self.nestLimitedContentOffsetY = 0;
  self.scrollAttached = NO;
}

- (UIScrollView *)findNestedScrollView:(NSArray<__kindof UIView *> *)subviews {
  NSArray<UIView *> *reverseSubview = [[subviews reverseObjectEnumerator] allObjects];

  // BFS
  for (UIView *child in reverseSubview) {
    if ([self checkNestedScrollView:(UIScrollView *)child]) {
      return (UIScrollView *)child;
    }
  }
  
  for (UIView *child in reverseSubview) {
    UIScrollView *ret = [self findNestedScrollView:child.subviews];
    if (ret) {
      return ret;
    }
  }
  
  return nil;
}

/**
 * Make sure that the `contentOffset` will not larger than the expandHeight
 */
- (void)adjustContentOffset {
  BOOL isDetached = self.forceScrollDetach;
  if (!isDetached) {
    self.forceScrollDetach = YES;
  }
  
  if (self.contentOffset.y > self.expandHeight) {
    [self setContentOffset:CGPointMake(self.contentOffset.x, self.expandHeight)];
    self.limitedContentOffsetY = self.expandHeight;
  }
  
  if (!isDetached) {
    self.forceScrollDetach = NO;
  }
}

- (void)dealloc {
  [self clearNestedScrollView];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self nestedScrollView];
    // Notify layout did finish.
    [((BDXLynxFoldViewLight *)_uiDelegate).context.observer notifyScroll:nil];
}

- (void)setExpandHeight:(CGFloat)expandHeight {
  _expandHeight = expandHeight;
  [self setContentOffset:self.contentOffset];
}

// handle LynxFoldView's contentOffset
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Notify x-foldview-ng did scroll.
    [((BDXLynxFoldViewLight *)_uiDelegate).context.observer notifyScroll:nil];
  if (self.forceScrollDetach) {
    [self.uiDelegate foldViewDidScroll:scrollView];
    return;
  }
  if (self.duringDidScroll) {
    return;
  }
  self.duringDidScroll = YES;
  CGPoint contentOffset = scrollView.contentOffset;
  
  // foldview can not scroll beyound expandHeight
  if (contentOffset.y > self.expandHeight) {
    contentOffset = CGPointMake(contentOffset.x, self.expandHeight);
    [self setContentOffset:contentOffset];
  }
  
  // if attached && nest_scrollview is not at top, stick fold header; if not, do not allow self to scroll lower
  if (self.scrollAttached) {
    if (self.nestedScrollView && self.nestedScrollView.contentOffset.y > self.threshold) {
      contentOffset = CGPointMake(contentOffset.x, self.expandHeight);
      [self setContentOffset:contentOffset];
    }
  } else {
    if (contentOffset.y < self.limitedContentOffsetY) {
      contentOffset = CGPointMake(contentOffset.x, self.limitedContentOffsetY);
      [self setContentOffset:contentOffset];
    } else {
      self.limitedContentOffsetY = contentOffset.y;
    }
  }
  
  [self.uiDelegate foldViewDidScroll:scrollView];
  self.duringDidScroll = NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (self.tabbarView && CGRectContainsPoint(self.tabbarView.bounds, [gestureRecognizer locationInView:self.tabbarView])) {
    return NO;
  }
  if (self.slotDragView && CGRectContainsPoint(self.slotDragView.bounds, [gestureRecognizer locationInView:self.slotDragView])) {
    return NO;
  }
  
  // If `allowNestScrollViewBounces`, and the foldview is at top, return NO to let the nest scroll-view to responds to the DOWN gesture.
  if ([gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class] && [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self].y > 0 && self.allowNestScrollViewBounces && [self isFullyExpand] && !self.bounces) {
    return NO;
  }
  
  return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  UIView *currentScrollingList = self.nestedScrollView;
  return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]
  && ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]
      && otherGestureRecognizer.view == currentScrollingList);
}


@end



@interface BDXLynxFoldViewLight () <BDXLynxFoldViewLightProtocol>
@property (nonatomic, assign) CGFloat scrollViewFilter;
@property (nonatomic, assign) BOOL shouldInvalidateLayout;
@property (nonatomic, strong) LynxFoldView *foldview;
@property (nonatomic, weak) BDXLynxFoldViewToolBarLight *toolbar;
@property (nonatomic, weak) BDXLynxFoldViewHeaderLight *header;
@property (nonatomic, weak) BDXLynxFoldViewSlotLight *slot;
@property (nonatomic, assign) CGFloat preOffset;
@property (nonatomic, assign) CGFloat granularity;
@property (nonatomic, assign) BOOL forceDetachScroll;
@property (nonatomic, strong) NSArray<NSString *> *excludeLynxUINames;
@property (nonatomic, assign) CGFloat topPaddingForNative;
@end


@implementation BDXLynxFoldViewLight

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-ng")
#else
LYNX_REGISTER_UI("x-foldview-ng")
#endif


- (instancetype)init {
  if (self = [super init]) {
    _scrollViewFilter = 0.5;
    _granularity = 0.01;
  }
  return self;
}


#pragma mark - LynxUI

- (UIView *)createView {
  self.foldview = [[LynxFoldView alloc] init];
  self.foldview.uiDelegate = self;
  UIView *view = [[UIView alloc] init];
  [view addSubview:self.foldview];
  return view;
}


- (void)updateFrame:(CGRect)frame
        withPadding:(UIEdgeInsets)padding
             border:(UIEdgeInsets)border
             margin:(UIEdgeInsets)margin
withLayoutAnimation:(BOOL)with {
  [super updateFrame:frame withPadding:padding border:border margin:margin withLayoutAnimation:with];
  [self.foldview setFrame:self.view.bounds];
  self.shouldInvalidateLayout = YES;
}


- (void)layoutDidFinished {
  [super layoutDidFinished];
}

- (void)finishLayoutOperation {
  [super finishLayoutOperation];
  
  if (!self.header || !self.slot) {
    @throw [NSException exceptionWithName:@"x-foldview-ng" reason:@"header-ng and slot-ng must be set" userInfo:nil];
  }
  
  NSUInteger headerIndex = [self.children indexOfObject:self.header];
  NSUInteger slotIndex = [self.children indexOfObject:self.slot];
  NSUInteger headerViewIndex = [[self.foldview subviews] indexOfObject:self.header.view];
  NSUInteger slotViewIndex = [[self.foldview subviews] indexOfObject:self.slot.view];
  if ((headerIndex - slotIndex) * (headerViewIndex - slotViewIndex) <= 0) {
    [self.header.view removeFromSuperview];
    [self.slot.view removeFromSuperview];
    if (headerIndex < slotIndex) {
      [self.foldview addSubview:self.header.view];
      [self.foldview addSubview:self.slot.view];
    } else {
      [self.foldview addSubview:self.slot.view];
      [self.foldview addSubview:self.header.view];
    }
    self.shouldInvalidateLayout = YES;
  }
  
  // clear refs
  [self clearRefs];
  self.foldview.scrollViewFilter = self.scrollViewFilter;
  
  // clear nestedScrollView because children may be changed
  NSMutableArray<LynxComponent  *> *reverseChildren = [[[self.slot.children reverseObjectEnumerator] allObjects] mutableCopy];
  self.foldview.potentialRootScrollableLynxUI = [self findPotentialRootScrollableLynxUI:(NSMutableArray<LynxComponent  *> *)reverseChildren];
  if ([self.foldview.potentialRootScrollableLynxUI isKindOfClass:NSClassFromString(@"BDXLynxViewPagerLight")]) {
    [self bindViewPagerRecursively:self.foldview.potentialRootScrollableLynxUI depth:3];
    // try to set tabbarpro in slot or in slotDrag
    [self setupTabbarPro:self.slot.tabbarPro.view withViewPager:self.foldview.potentialRootScrollableLynxUI];
    [self setupTabbarPro:self.slot.slotDrag.tabbarPro.view withViewPager:self.foldview.potentialRootScrollableLynxUI];
  }
  
  [self setupSlotDrag];
  
  // finishLayoutOperation is called behind header updateFrame
  if (self.header.headerHeightChanged || self.toolbar.toolbarHeightChanged) {
    self.header.headerHeightChanged = NO;
    self.toolbar.toolbarHeightChanged = NO;
    self.shouldInvalidateLayout = YES;
  }
  
  if (self.shouldInvalidateLayout) {
    self.shouldInvalidateLayout = NO;
    self.header.view.frame = CGRectMake(CGRectGetMinX(self.header.view.frame), 0, CGRectGetWidth(self.header.view.frame), CGRectGetHeight(self.header.view.frame));
    self.slot.view.frame = CGRectMake(CGRectGetMinX(self.slot.view.frame), CGRectGetHeight(self.header.view.frame), CGRectGetWidth(self.slot.view.frame), CGRectGetHeight(self.slot.view.frame));
    self.toolbar.view.frame = CGRectMake(CGRectGetMinX(self.toolbar.view.frame), 0, CGRectGetWidth(self.toolbar.view.frame), CGRectGetHeight(self.toolbar.view.frame));
    
    // do not allow header.height < toolbar.height
    self.foldview.expandHeight = MAX(0, self.header.view.bounds.size.height - self.toolbar.view.bounds.size.height);
    
    // set contentSize at last, which depends on expandHeight
    self.foldview.contentSize = CGSizeMake(self.view.bounds.size.width, self.header.view.bounds.size.height + self.slot.view.bounds.size.height);
  
    // If expandHeight is changed, let LynxFoldView scrolls to reasonable offset
    [self.foldview adjustContentOffset];
  }
  
  // rebind scrollview && ensure contentOffset
  [self.foldview nestedScrollView];
  if (self.foldview.contentOffset.y > self.foldview.expandHeight) {
    [self.foldview setContentOffset:CGPointMake(self.foldview.contentOffset.x, self.foldview.expandHeight)];
  }
  
  
  UIEdgeInsets inset = self.foldview.contentInset;
  if (inset.top != self.topPaddingForNative) {
    inset.top = self.topPaddingForNative;
    self.foldview.contentInset = inset;
    self.foldview.contentOffset = CGPointMake(0, -self.topPaddingForNative);
  }
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
  [super insertChild:child atIndex:index];
  if ([child isKindOfClass:BDXLynxFoldViewHeaderLight.class]) {
    self.header = (BDXLynxFoldViewHeaderLight *)child;
    [self.header.view removeFromSuperview];
    [self.foldview addSubview:self.header.view];
    self.shouldInvalidateLayout = YES;
  } else if ([child isKindOfClass:BDXLynxFoldViewSlotLight.class]) {
    self.slot = (BDXLynxFoldViewSlotLight *)child;
    [self.slot.view removeFromSuperview];
    [self.foldview addSubview:self.slot.view];
    self.shouldInvalidateLayout = YES;
  } else if ([child isKindOfClass:BDXLynxFoldViewToolBarLight.class]) {
    self.toolbar = (BDXLynxFoldViewToolBarLight *)child;
    [self.view bringSubviewToFront:self.toolbar.view];
    self.shouldInvalidateLayout = YES;
  } else {
    @throw [NSException exceptionWithName:@"x-foldview-ng" reason:@"foldview-ng only support header-ng or slot-ng as its children" userInfo:nil];
  }
}

- (void)removeChild:(LynxUI *)child atIndex:(NSInteger)index {
  [super removeChild:child atIndex:index];
  if ([child isKindOfClass:BDXLynxFoldViewHeaderLight.class]) {
    self.header = nil;
    self.shouldInvalidateLayout = YES;
  } else if ([child isKindOfClass:BDXLynxFoldViewSlotLight.class]) {
    self.slot = nil;
    self.shouldInvalidateLayout = YES;
  }
}

- (id<LynxEventTarget>)hitTest:(CGPoint)oriPoint withEvent:(UIEvent*)event {
  
  if (self.context.enableEventRefactor) {
    LynxUI *hit = (LynxUI *)[super hitTest:oriPoint withEvent:event];
    return hit;
  }
  
  LynxUI* guard = nil;
  NSMutableArray<LynxUI *> *array = [[NSMutableArray alloc] init];
  if (self.toolbar) {
    [array addObject:self.toolbar];
  }
  [array addObject:self.header];
  [array addObject:self.slot];

  {
    for (LynxUI* child in array) {
      CGPoint point = [self.view convertPoint:oriPoint toView:child.view];
      if (![child shouldHitTest:point withEvent:event] || [child.view isHidden]) {
        continue;
      }
      BOOL contain = CGRectContainsPoint(child.view.bounds, point);
      if (contain) {
        if (child.isOnResponseChain) {
          guard = child;
          break;
        }
        if (guard == nil || guard.getTransationZ < child.getTransationZ) {
          guard = child;
        }
      }
    }
    oriPoint = [self.view convertPoint:oriPoint toView:guard.view];
  }
  
  if (guard == nil) {
    // no new result
    return self;
  }
  return [guard hitTest:oriPoint withEvent:event];
}

- (BOOL)isScrollContainer {
  return YES;
}



#pragma mark - LYNX_PROPS

LYNX_PROP_SETTER("bounces", setBounces, BOOL) {
  self.foldview.bounces = value;
}


LYNX_PROP_SETTER("allow-vertical-bounce", allowVerticalBounce, BOOL) {
  [self setBounces:value requestReset:requestReset];
}

LYNX_PROP_SETTER("granularity", granularity, CGFloat) {
    self.granularity = value;
}

LYNX_PROP_SETTER("scroll-bar-enable",  scrollBarEnable , BOOL) {
  self.foldview.showsVerticalScrollIndicator = value;
  self.foldview.showsHorizontalScrollIndicator = value;
}

LYNX_PROP_SETTER("refresh-mode", refreshMode, NSString *) {
  self.foldview.allowNestScrollViewBounces = [value isEqualToString:@"page"];
}

LYNX_PROP_SETTER("scroll-enable",  scrollEnable , BOOL) {
  self.foldview.scrollEnabled = value;
}

LYNX_PROP_SETTER("ios-force-scroll-detach", setForceDetach, BOOL) {
  self.forceDetachScroll = value;
  self.foldview.forceScrollDetach = value;
}

LYNX_PROP_SETTER("ios-scroll-view-filter", setScrollFilter, NSNumber *) {
  self.scrollViewFilter = [value floatValue];
}

LYNX_PROP_SETTER("ios-scroll-exclude", setScrollExclude, NSString *) {
  self.excludeLynxUINames = [value componentsSeparatedByString:@","];
  self.foldview.excludeScrollViewNames = self.excludeLynxUINames;
}

/**
 * @name: ios-top-padding-for-native
 * @description: We need to leave some space for the native container at the top of the foldview, under some certain circumstances. And we can not use css padding because it will change the layout inside the foldview. So, we just set the native property of `contentInset` to make it work.
 * @note: None
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.8
 * @resolveVersion: None
**/
LYNX_PROP_SETTER("ios-top-padding-for-native", setTopPadding, NSString *) {
  self.topPaddingForNative = [self toPtWithUnitValue:value fontSize:0];
}




#pragma mark - LYNX_UI_METHOD

LYNX_UI_METHOD(setFoldExpanded) {
  CGFloat offset = [LynxUnitUtils toPtFromUnitValue:[params objectForKey:@"offset"]];
  BOOL smooth = [params objectForKey:@"smooth"] ? [[params objectForKey:@"smooth"] boolValue] : YES;
  offset = MAX(MIN(offset, self.foldview.expandHeight), 0);
  
  self.foldview.forceScrollDetach = YES;
  
  [self.foldview setContentOffset:CGPointMake(self.foldview.contentOffset.x, offset) animated:smooth];
  
  if (callback) {
    if (!smooth) {
      self.foldview.forceScrollDetach = self.forceDetachScroll;
      [self.foldview clearNestedScrollView];
      [self.foldview nestedScrollView];
      callback(kUIMethodSuccess, nil);
    } else {
      // for simplicity, callback after 300ms
      __weak typeof(self) weakSelf = self;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
                     dispatch_get_main_queue(), ^{
        weakSelf.foldview.forceScrollDetach = weakSelf.forceDetachScroll;
        [weakSelf.foldview clearNestedScrollView];
        [weakSelf.foldview nestedScrollView];
        callback(kUIMethodSuccess, nil);
      });
    }
  } else {
    self.foldview.forceScrollDetach = self.forceDetachScroll;
    [self.foldview clearNestedScrollView];
    [self.foldview nestedScrollView];
  }
}

#pragma mark - BDXLynxFoldViewLightProtocol

- (void)foldViewDidScroll:(UIScrollView *)scrollView {
  CGFloat offset = scrollView.contentOffset.y;
  CGFloat height = self.foldview.expandHeight;
  if (ABS(offset - self.preOffset) >= height * self.granularity ||
      (offset != self.preOffset &&
        (offset == 0 || ABS(offset - height) < DBL_EPSILON))) {
    [self.context.eventEmitter sendCustomEvent:
     [[LynxDetailEvent alloc] initWithName:@"offset"
                                targetSign:[self sign]
                                    detail:@{
      @"offset" : @(offset),
      @"height" : @(height)
     }]];
    self.preOffset = offset;
  }
}

#pragma mark - BDXLynxViewPagerLightDelegate


- (void)didIndexChanged:(NSUInteger)index {
  [self.foldview clearNestedScrollView];
  [self.foldview nestedScrollView];
}


#pragma mark - Internal

- (void)bindViewPagerRecursively:(LynxUI *)currentUI depth:(NSInteger)depth {
  if ([currentUI isKindOfClass:NSClassFromString(@"BDXLynxViewPagerLight")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [currentUI performSelector:@selector(setPagerDelegate:) withObject:self];
#pragma clang diagnostic pop
  }
  if (depth == 0) {
    return;
  }
  for (LynxUI *child in currentUI.children) {
    [self bindViewPagerRecursively:child depth:depth - 1];
  }
}

// for tabbar pro
- (void)setupTabbarPro:(BDXCategoryBaseView *)tabbarProView withViewPager:(LynxUI *)viewpagerUI {
  tabbarProView.forceObserveContentOffset = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  tabbarProView.contentScrollViewClickTransitionAnimationEnabled = ![[viewpagerUI performSelector:@selector(disablePageChangeAnim)] boolValue];
  UIScrollView *scrollview = [viewpagerUI performSelector:@selector(viewpager)];
#pragma clang diagnostic pop
  if ([scrollview isKindOfClass:UIScrollView.class]) {
    tabbarProView.contentScrollView = scrollview;
  }
}

// for slot drag
- (void)setupSlotDrag {
  self.foldview.slotDragView = self.slot.slotDrag.forbidMovable ? self.slot.slotDrag.view : nil;
}

- (void)clearRefs {
  BDXCategoryBaseView *tabbarProView = self.slot.tabbarPro.view;
  tabbarProView.contentScrollView = nil;
  
  self.foldview.tabbarView = nil;

  [self.foldview clearNestedScrollView];
}

- (LynxUI *)findPotentialRootScrollableLynxUI:(NSMutableArray<LynxComponent *> *)children {
  // BFS
  for (LynxComponent *child in children) {
    if ([self checkScrollable:child]) {
      return (LynxUI *)child;
    }
  }
  
  for (LynxComponent *child in children) {
    LynxUI *ret = [self findPotentialRootScrollableLynxUI:child.children];
    if (ret) {
      return ret;
    }
  }
  
  return nil;
}

- (BOOL)checkScrollable:(LynxComponent *)component {
  LynxUI *lynxUI = (LynxUI *)component;
  
  for (NSString *exclude in self.excludeLynxUINames) {
    if ([exclude isEqualToString:lynxUI.name]) {
      return NO;
    }
  }
  
  if ([lynxUI isKindOfClass:LynxUI.class]) {
    if ([lynxUI isKindOfClass:NSClassFromString(@"BDXLynxViewPagerLight")]) {
      return YES;
    } else if ([lynxUI isKindOfClass:NSClassFromString(@"LynxUICollection")] ||
               [lynxUI isKindOfClass:NSClassFromString(@"AbsLynxUIScroller")] ||
               [lynxUI.view isKindOfClass:UIScrollView.class]) {
      // try to filter horizontal scrollView
      if (lynxUI.view.frame.size.height >= self.slot.view.frame.size.height * self.scrollViewFilter) {
        return YES;
      }
    }
  }
  return NO;
}
@end
