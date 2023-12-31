// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxUICollection.h"
#import "LynxCollectionDataSource.h"
#import "LynxCollectionInvalidationContext.h"
#import "LynxCollectionViewCell.h"
#import "LynxCollectionViewLayout.h"
#import "LynxComponentRegistry.h"
#import "LynxGlobalObserver.h"
#import "LynxListAppearEventEmitter.h"
#import "LynxListDebug.h"
#import "LynxListScrollEventEmitter.h"
#import "LynxUI+Internal.h"
#import "LynxUICollection+Delegate.h"
#import "LynxUICollection+Internal.h"
#import "LynxUIListInspector.h"
#import "LynxWeakProxy.h"

#import "UIScrollView+Nested.h"

static const CGFloat LynxUICollectionCompareLayoutUpdateEpsilon = 0.001;
static const NSTimeInterval LynxUICollectionCellUpdateAnimationDefaultTime = 1.;

@interface LynxUICollectionView : UICollectionView
@property(nonatomic, weak) LynxListScrollEventEmitter *scrollEventEmitter;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL disableAnimationDuringLayout;
@property(nonatomic, assign) BOOL disableFixingUnexpectedScroll;
@property(nonatomic) LynxBounceForbiddenDirection bounceForbiddenDirection;
@end

@implementation LynxUICollectionView

// We overwrite this method to circumvent an iOS bug found on iPhone 12 Pro.
// For more details, visit https://developer.apple.com/forums/thread/663861.
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath
               atScrollPosition:(UICollectionViewScrollPosition)scrollPosition
                       animated:(BOOL)animated {
  if (animated) {
    self.scrollEventEmitter.helper.scrollState = LynxListScrollStateScrolling;
  }
  BOOL savedPagingEnabled = self.pagingEnabled;
  self.pagingEnabled = NO;
  [super scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
  self.pagingEnabled = savedPagingEnabled;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
  if (animated) {
    self.scrollEventEmitter.helper.scrollState = LynxListScrollStateScrolling;
  }
  [super setContentOffset:contentOffset animated:self.disableAnimationDuringLayout ? NO : animated];
}

- (void)setContentOffset:(CGPoint)contentOffset {
  // TODO(fangzhou.fz): should consider RTL here.
  if (_bounceForbiddenDirection == LynxForbiddenLower) {
    contentOffset =
        CGPointMake(MIN(self.contentSize.width - self.bounds.size.width, contentOffset.x),
                    MIN(self.contentSize.height - self.bounds.size.height, contentOffset.y));
  } else if (_bounceForbiddenDirection == LynxForbiddenUpper) {
    contentOffset = CGPointMake(MAX(-self.contentInset.left, contentOffset.x),
                                MAX(-self.contentInset.top, contentOffset.y));
  }
  [super setContentOffset:contentOffset];
}

- (void)layoutSubviews {
  if (((LynxUICollection *)self.delegate).dataSource.ignoreLoadCell) {
    return;
  }
  // On iOS 16.0, UIKit may invoke `setContentOffset:animated:` with `YES` inside `layoutSubview`,
  // make it to `NO` to avoid unnecessary animation.
  if (@available(iOS 16.0, *)) {
    if (!self.disableFixingUnexpectedScroll) {
      self.disableAnimationDuringLayout = YES;
    }
  }
  [super layoutSubviews];
  self.disableAnimationDuringLayout = NO;
  [self.scrollEventEmitter helperSendScrollEvent:self];
  // Notify layout did finish.
  [((LynxUICollection *)self.delegate).context.observer notifyLayout:nil];
}

- (BOOL)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UISwipeGestureRecognizer *)otherGestureRecognizer {
  if (nil != self.parentScrollView &&
      [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] && self.enableNested) {
    return YES;
  }
  return NO;
}

@end

@interface LynxUICollection () <LynxUIListInspector>
@property(nonatomic, assign) BOOL shouldUpdateDataSource;
@end

@implementation LynxUICollection {
  NSMutableArray *_listDelegates;
}
#pragma mark - LynxUI LifeCycle & Utils

- (instancetype)init {
  self = [super init];
  if (self) {
    _listDelegates = [NSMutableArray new];
    self.noRecursiveLayout = YES;
    self.forceReloadData = YES;
    self.listNativeStateCache = [[NSMutableDictionary alloc] init];
    self.verticalOrientation = LynxListOrientationNone;
  }
  return self;
}

- (UIView *)createView {
  self.layout = [[LynxCollectionViewLayout alloc] init];
  LynxUICollectionView *collectionView = [[LynxUICollectionView alloc] initWithFrame:CGRectZero
                                                                collectionViewLayout:self.layout];
  collectionView.clipsToBounds = YES;
  collectionView.backgroundColor = [UIColor clearColor];
  collectionView.allowsSelection = NO;
  collectionView.alwaysBounceVertical = YES;
  collectionView.showsVerticalScrollIndicator = YES;
  collectionView.enableNested = NO;
  collectionView.scrollY = YES;
  if (@available(iOS 10.0, *)) {
    collectionView.prefetchingEnabled = NO;
  }
  if (@available(iOS 11, *)) {
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  return collectionView;
}

- (void)dealloc {
  [self.appearEventCourier invalidate];
}

- (void)setSign:(NSInteger)sign {
  [super setSign:sign];
  self.appearEventCourier =
      [[LynxListAppearEventEmitter alloc] initWithEmitter:self.context.eventEmitter];
  self.appearEventCourier.listUI = self;
  self.scrollEventEmitter = [[LynxListScrollEventEmitter alloc] initWithLynxUI:self];
  self.scrollEventEmitter.delegate = self;
  ((LynxUICollectionView *)(self.view)).scrollEventEmitter = self.scrollEventEmitter;
  _dataSource = [[LynxCollectionDataSource alloc] initWithLynxUICollection:self];
  self.view.delegate = self;
  self.view.dataSource = _dataSource;
  self.scroll = [[LynxCollectionScroll alloc] init];
  self.layout.scroll = self.scroll;
}

- (void)setEnableNested:(BOOL)value requestReset:(BOOL)requestReset {
  if (requestReset) {
    value = NO;
  }
  if ([self.view respondsToSelector:@selector(enableNested)]) {
    ((UICollectionView *)self.view).enableNested = value;
  }
}

- (BOOL)isScrollContainer {
  return YES;
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (self.context.enableEventRefactor) {
    // if the zIndex of CollectionViewCells are assigned according to their index
    // we then use containsPoints to test each cell form the max zIndex to the min zIndex.
    NSArray<NSIndexPath *> *visibleIndexPaths = self.view.indexPathsForVisibleItems;
    NSArray<NSIndexPath *> *visibleIndexPathsSortedByZIndexReversely =
        [visibleIndexPaths sortedArrayUsingComparator:^NSComparisonResult(
                               NSIndexPath *_Nonnull lhs, NSIndexPath *_Nonnull rhs) {
          UICollectionViewLayoutAttributes *lhsAttributes =
              [self.view layoutAttributesForItemAtIndexPath:lhs];
          UICollectionViewLayoutAttributes *rhsAttributes =
              [self.view layoutAttributesForItemAtIndexPath:rhs];
          if (lhsAttributes.zIndex < rhsAttributes.zIndex) {
            return NSOrderedDescending;
          } else {
            return NSOrderedAscending;
          }
          return NSOrderedSame;
        }];

    for (NSIndexPath *indexPath in visibleIndexPathsSortedByZIndexReversely) {
      LynxCollectionViewCell *cell =
          (LynxCollectionViewCell *)[self.view cellForItemAtIndexPath:indexPath];
      CGPoint pointInCell = [cell.ui.view convertPoint:point fromView:self.view];
      if ([cell.ui containsPoint:pointInCell inHitTestFrame:cell.contentView.bounds]) {
        return [cell.ui hitTest:pointInCell withEvent:event];
      }
    }
    return self;
  } else {
    NSIndexPath *path = [self.view indexPathForItemAtPoint:point];
    LynxCollectionViewCell *cell =
        (LynxCollectionViewCell *)[self.view cellForItemAtIndexPath:path];
    if (cell == nil) return self;
    point = CGPointMake(point.x - cell.frame.origin.x, point.y - cell.frame.origin.y);
    return [cell.ui hitTest:point withEvent:event];
  }
}

#pragma mark - ContentOffset
- (CGPoint)contentOffset {
  return self.view.contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset {
  CGFloat y = MAX(-self.view.contentInset.top,
                  MIN(contentOffset.y, self.view.contentSize.height - self.view.frame.size.height +
                                           self.view.contentInset.bottom));

  CGFloat x = MAX(-self.view.contentInset.left,
                  MIN(contentOffset.x, self.view.contentSize.width - self.view.frame.size.width +
                                           self.view.contentInset.right));

  self.view.contentOffset = CGPointMake(x, y);
}

#pragma mark - Update

- (void)propsDidUpdate {
  [super propsDidUpdate];

  ((LynxUICollectionView *)(self.view)).name = self.name;
  if (self.noRecursiveLayout) {
    self.shouldUpdateDataSource = YES;
    // apply at finishLayoutOperation instead
  } else {
    if (self.isNewArch) {
      if (self.listNoDiffInfo) {
        [self updateListActionInfo:self.listNoDiffInfo];
        self.listNoDiffInfo = nil;
      } else {
        [self loadListInfo:self.diffResultFromTasm components:self.curComponents];
        self.diffResultFromTasm = nil;
      }
    }
    [self setInitialScrollIndexIfNeeded];
    if (![self isNeedRenderComponents]) {
      [self.context
          reportError:[LynxError
                          lynxErrorWithCode:LynxErrorCodeMultiThreadNotSupportList
                                description:@"multi thread strategy can not be used for List !!!"]];
      return;
    }
    [_dataSource apply];
  }
}

- (void)setInitialScrollIndexIfNeeded {
  if (self.numberOfColumns == 1 && self.initialScrollIndex > 0) {
    self.scroll.initialScrollIndex = self.initialScrollIndex;

    // check if initialScrollIndex is set
    if (self.scroll.initialScrollIndex == self.initialScrollIndex) {
      LynxCollectionInvalidationContext *context =
          [[LynxCollectionInvalidationContext alloc] initWithInitialScrollIndexSet];
      [self.view.collectionViewLayout invalidateLayoutWithContext:context];
    }
    self.initialScrollIndex = 0;
  }
}

- (void)layoutDidFinished {
  // if self.noRecursiveLayout, apply at finishLayoutOperation instead
  if (!self.noRecursiveLayout) {
    if (![self isNeedRenderComponents]) {
      [self.context
          reportError:[LynxError
                          lynxErrorWithCode:LynxErrorCodeMultiThreadNotSupportList
                                description:@"multi thread strategy can not be used for List !!!"]];
      return;
    }
    [_dataSource applyFirstTime];
  }
}

- (void)onNodeReady {
  [super onNodeReady];
  // apply dataSource here, after propsDidUpdate and updateFrame opeartion, to avoid recursive
  // layout during batchUpdate
  [self setInitialScrollIndexIfNeeded];
  if (self.noRecursiveLayout && self.shouldUpdateDataSource) {
    self.shouldUpdateDataSource = NO;
    [self updateDataSource];
  }
  [(UIScrollView *)self.view updateChildren];
}

- (void)setBounceForbiddenDirection:(LynxBounceForbiddenDirection)forbiddenDirection {
  _bounceForbiddenDirection = forbiddenDirection;
  ((LynxUICollectionView *)self.view).bounceForbiddenDirection = forbiddenDirection;
}

- (void)updateDataSource {
  if (![self isNeedRenderComponents]) {
    [self.context
        reportError:[LynxError
                        lynxErrorWithCode:LynxErrorCodeMultiThreadNotSupportList
                              description:@"multi thread strategy can not be used for List !!!"]];
    return;
  }
  if (self.isNewArch) {
    if (self.listNoDiffInfo) {
      [self updateListActionInfo:self.listNoDiffInfo];
      self.listNoDiffInfo = nil;
    } else {
      [self loadListInfo:self.diffResultFromTasm components:self.curComponents];
      self.diffResultFromTasm = nil;
    }
  }
  if (![_dataSource applyFirstTime]) {
    [_dataSource apply];
  }
}

/** return true，only on two situations
 (1) the thread strategy is async, the list is new architecture and enableAsyncList is true;
 (2) the thread strategy is not async;
 */
- (BOOL)isNeedRenderComponents {
  if ([self isAsync]) {
    return (self.isNewArch) ? self.enableAsyncList : NO;
  }
  return YES;
}

#pragma mark - LynxUI Frame Updates
// layout invalidation responds to changes in paddings
- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
                 margin:(UIEdgeInsets)margin
    withLayoutAnimation:(BOOL)with {
  [super updateFrame:frame
              withPadding:padding
                   border:border
                   margin:margin
      withLayoutAnimation:with];
  if (self.verticalOrientation == LynxListOrientationHorizontal) {
    self.view.contentInset = UIEdgeInsetsMake(0, padding.left, 0, padding.right);
  } else {
    self.view.contentInset = UIEdgeInsetsMake(padding.top, 0, padding.bottom, 0);
  }
  LynxCollectionInvalidationContext *context = [[LynxCollectionInvalidationContext alloc]
      initWithInsetChanging:UIEdgeInsetsMake(padding.top, padding.left, padding.bottom,
                                             padding.right)];
  [self.view.collectionViewLayout invalidateLayoutWithContext:context];
  [self.scroll initialScrollCollectionViewIfNeeded:self.layout];
}

// layout invalidation responds to change in frame
- (void)frameDidChange {
  [super frameDidChange];
  LynxCollectionInvalidationContext *context =
      [[LynxCollectionInvalidationContext alloc] initWithBoundsChanging:self.view.frame];
  [self.view.collectionViewLayout invalidateLayoutWithContext:context];
}

#pragma mark - LynxUIComponentLayoutObserver

- (void)onAsyncComponentLayoutUpdated:(nonnull LynxUIComponent *)component
                          operationID:(int64_t)operationID {
  if ([self isAsync]) {
    [[self.view visibleCells]
        enumerateObjectsUsingBlock:^(__kindof LynxCollectionViewCell *_Nonnull cell, NSUInteger idx,
                                     BOOL *_Nonnull stop) {
          if (operationID == cell.operationID) {
            if (cell.ui != component) {
              // recycle original ui if needed
              LynxUI *oriUI = cell.ui;
              if (oriUI) {
                [cell removeLynxUI];
                [self asyncRecycleLynxUI:oriUI];
              }
              [cell addLynxUI:component];
              [self.appearEventCourier onCellAppear:cell.ui
                                        atIndexPath:[self.view indexPathForCell:cell]];
            }
            [self invalidateLayoutAtIndexPath:[self.view indexPathForCell:cell]
                                    newBounds:component.updatedFrame];
            return;
          }
        }];
    return;
  }
}

- (void)onComponentLayoutUpdated:(LynxUIComponent *)component {
  UIView *cellView = component.view.superview.superview;
  if (![cellView isKindOfClass:[LynxCollectionViewCell class]]) {
    return;
  }

  LynxCollectionViewCell *cell = (LynxCollectionViewCell *)cellView;
  NSIndexPath *indexPath = cell.updateToPath;
  if (indexPath == nil) {
    indexPath = [self.view indexPathForCell:cell];
  }
  if (indexPath != nil && (NSUInteger)indexPath.row < [self count]) {
    LYNX_LIST_DEBUG_LOG(@" at %@, delta height: %@", @(indexPath.row),
                        @(component.updatedFrame.size.height - cell.bounds.size.height));
    typeof(self) __weak weakSelf = self;
    CGRect updateFrame = cell.ui.updatedFrame;

    CGFloat uiHeight = self.layout.enableAlignHeight ? ceil(component.updatedFrame.size.height)
                                                     : component.updatedFrame.size.height;
    CGFloat uiWidth = self.layout.enableAlignHeight ? ceil(component.updatedFrame.size.width)
                                                    : component.updatedFrame.size.width;
    BOOL heightDidChange =
        (fabs(uiHeight - cell.bounds.size.height) > LynxUICollectionCompareLayoutUpdateEpsilon ||
         fabs(component.updatedFrame.size.width - cell.bounds.size.width) >
             LynxUICollectionCompareLayoutUpdateEpsilon);
    BOOL widthDidChange =
        (fabs(uiWidth - cell.bounds.size.width) > LynxUICollectionCompareLayoutUpdateEpsilon ||
         fabs(component.updatedFrame.size.height - cell.bounds.size.height) >
             LynxUICollectionCompareLayoutUpdateEpsilon);
    BOOL boundsDidChange = heightDidChange || widthDidChange;

    if (boundsDidChange && self.enableUpdateAnimation) {
      // animate component layout changes only when
      // (difference on width / height must be greater than LayoutUpdateEpsilon) ==> the component
      // layout did change
      // (!cell.loading) ==> the layout changing is not stem from a
      // `collectionView:cellForItemAtIndexPath:` , which needs not to be animated because it is not
      // yet on the screen now. (self.enableUpdateAnimation) ==> animation is enabled
      LynxCollectionViewLayout *collectionViewLayout =
          (LynxCollectionViewLayout *)self.view.collectionViewLayout;
      [collectionViewLayout prepareForCellLayoutUpdate];
      NSTimeInterval totalAnimationTime = LynxUICollectionCellUpdateAnimationDefaultTime;
      [CATransaction begin];
      {
        if (self.cellUpdateAnimationType == LynxCollectionCellUpdateAnimationTypeFadeIn) {
          [CATransaction setAnimationDuration:totalAnimationTime];
          cell.contentView.alpha = 0.;
          [UIView animateWithDuration:totalAnimationTime
                                delay:0.
                              options:UIViewAnimationOptionAllowAnimatedContent |
                                      UIViewAnimationOptionTransitionCrossDissolve
                           animations:^{
                             cell.contentView.alpha = 1.;
                           }
                           completion:nil];
        }

        [UIView animateWithDuration:totalAnimationTime
                         animations:^(void) {
                           typeof(weakSelf) strongSelf = weakSelf;
                           [strongSelf invalidateLayoutAtIndexPath:indexPath newBounds:updateFrame];
                         }];
        cell.ui.view.frame = CGRectMake(0., 0., component.updatedFrame.size.width,
                                        component.updatedFrame.size.height);
      }
      [CATransaction commit];
    } else {
      if (boundsDidChange && !cell.loading) {
        // invalidate the layout if the cell is not `loading`, which means this method
        // is not called during the call of `collectionView:cellForItemAtIndexPath:`
        // if the cell is `loading`, i.e., the method is called during the
        // `collectionView:cellForItemAtIndexPath:`, we do not need to invalidate the layout
        // explicitly here. This is because the layout will be invalidated by the subsequent
        // self-sizing procedures. (preferredLayoutAttributesFittingAttributes: -->
        // shouldInvalidateLayoutForPreferredLayoutAttributes: -->
        // invalidationContextForPreferredLayoutAttributes:)
        [self invalidateLayoutAtIndexPath:indexPath newBounds:updateFrame];
      }
      [cell adjustComponentFrame];
    }
  }
}

- (void)invalidateLayoutAtIndexPath:(NSIndexPath *)indexPath newBounds:(CGRect)bounds {
  UICollectionViewLayoutInvalidationContext *context;
  if (self.fixedContentOffset) {
    context =
        [[LynxCollectionInvalidationContext alloc] initWithSelfSizingCellAtIndexPath:indexPath
                                                                              bounds:bounds
                                                                      collectionView:self.view];
  } else {
    context = [[LynxCollectionInvalidationContext alloc] initWithUpdateAtIndexPath:indexPath
                                                                            bounds:bounds];
  }
  [self.view.collectionViewLayout invalidateLayoutWithContext:context];
}

- (void)setDisableFixingUnexpectedScroll:(BOOL)disableFixingUnexpectedScroll {
  ((LynxUICollectionView *)self.view).disableFixingUnexpectedScroll = disableFixingUnexpectedScroll;
}

#pragma mark - LynxUIListInspector

- (double)getCellOffsetByIndex:(int)index {
  double res = 0;
  NSArray *indexPathes = self.view.indexPathsForVisibleItems;
  for (NSIndexPath *path in indexPathes) {
    LynxCollectionViewCell *cell =
        (LynxCollectionViewCell *)[self.view cellForItemAtIndexPath:path];
    if (cell.ui.sign == index) {
      NSIndexPath *indexPath = [self.view indexPathForCell:cell];
      UICollectionViewLayoutAttributes *theAttributes =
          [self.view layoutAttributesForItemAtIndexPath:indexPath];
      CGRect cellFrameInSuperview = [self.view convertRect:theAttributes.frame
                                                    toView:self.context.rootView];
      res = cellFrameInSuperview.origin.y;
      break;
    }
  }
  return res;
}

#pragma mark - Helper
- (void)performBatchUpdates:(void(NS_NOESCAPE ^)(void))updates
                 completion:(void (^)(BOOL))completion
                   animated:(BOOL)animated {
  if (self.fixedContentOffset) {
    // mark contentOffset context, to make sure UI stable after batchUpdate
    [self markContentOffsetContext];
  }
  if (animated) {
    [self.view performBatchUpdates:updates completion:completion];
  } else {
    [UIView performWithoutAnimation:^{
      LYNX_LIST_DEBUG_LOG(@"will perfromBatchUpdates");
      [self.view performBatchUpdates:updates completion:completion];
      LYNX_LIST_DEBUG_LOG(@"did perfromBatchUpdates");
    }];
  }
  if (self.fixedContentOffset) {
    [self clearContentOffsetContex];
  }
}

- (void)markContentOffsetContext {
  // find out top cell in visible cells, and it's offset of screen correspondly
  // reset them at targetContentOffsetForProposedContentOffset

  __block CGFloat minCurrnetOffsetY = CGFLOAT_MAX;
  __block NSIndexPath *targetIndexPath = nil;
  [[self.view indexPathsForVisibleItems]
      enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect frame =
            [self.view.collectionViewLayout layoutAttributesForItemAtIndexPath:obj].frame;
        if (frame.origin.y < minCurrnetOffsetY) {
          minCurrnetOffsetY = frame.origin.y;
          targetIndexPath = obj;
        }
      }];

  CGFloat offsetDelta = minCurrnetOffsetY - self.view.contentOffset.y;

  LynxCollectionViewLayout *layout = (LynxCollectionViewLayout *)self.view.collectionViewLayout;
  layout.targetIndexPathAfterBatchUpdate = targetIndexPath;
  layout.targetOffsetDeltaAfterBatchUpdate = offsetDelta;
}

- (void)clearContentOffsetContex {
  LynxCollectionViewLayout *layout = (LynxCollectionViewLayout *)self.view.collectionViewLayout;

  if (layout.targetIndexPathAfterBatchUpdate) {
    UICollectionViewLayoutAttributes *attr =
        [layout layoutAttributesForItemAtIndexPath:layout.targetIndexPathAfterBatchUpdate];
    CGFloat targetOffsetY = attr.frame.origin.y - layout.targetOffsetDeltaAfterBatchUpdate;
    CGPoint target = CGPointMake(self.view.contentOffset.x, targetOffsetY);
    [self.view setContentOffset:target];
  }

  layout.targetIndexPathAfterBatchUpdate = nil;
  layout.targetOffsetDeltaAfterBatchUpdate = 0;
}

#pragma mark - LynxUIListScrollEvent
- (void)addListDelegate:(id<LynxUIListDelegate>)delegate {
  LynxWeakProxy *proxy = [LynxWeakProxy proxyWithTarget:delegate];
  [_listDelegates addObject:proxy];
}

- (void)removeListDelegate:(id<LynxUIListDelegate>)delegate {
  for (LynxWeakProxy *proxy in _listDelegates) {
    if (proxy.target == delegate) {
      [_listDelegates removeObject:proxy];
      break;
    }
  }
}

- (BOOL)notifyParent {
  return YES;
}

@end
