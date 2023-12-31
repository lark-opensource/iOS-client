// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxCollectionDataSource.h"
#import "LynxCollectionViewCell.h"
#import "LynxCollectionViewLayout.h"
#import "LynxGlobalObserver.h"
#import "LynxListAppearEventEmitter.h"
#import "LynxListDebug.h"
#import "LynxListScrollEventEmitter.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#import "LynxUI+Fluency.h"
#import "LynxUICollection+Delegate.h"
#import "LynxUICollection+Internal.h"
#import "LynxUIListDelegate.h"
#import "LynxUIMethodProcessor.h"
#import "UIScrollView+Lynx.h"

@implementation LynxUICollection (Delegate)

NSString *const kLynxEventUICollectionLayoutComplete = @"layoutcomplete";

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
  LynxCollectionViewCell *uiCell = (LynxCollectionViewCell *)cell;
  LYNX_LIST_DEBUG_LOG(@"row: %@", @(indexPath.row));
#if LYNX_LIST_DEBUG_LABEL
  uiCell.label.text = [NSString stringWithFormat:@"%@, %@", @(indexPath.row), cell.reuseIdentifier];
#endif
  [self.appearEventCourier onCellAppear:uiCell.ui atIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView
    didEndDisplayingCell:(UICollectionViewCell *)cell
      forItemAtIndexPath:(NSIndexPath *)indexPath {
  LynxCollectionViewCell *uiCell = (LynxCollectionViewCell *)cell;
  [self.appearEventCourier onCellDisappear:uiCell.ui atIndexPath:indexPath];
  if (self.isNewArch) {
    if ([self isAsync]) {
      LynxUI *lynxUI = [uiCell removeLynxUI];
      [self asyncRecycleLynxUI:lynxUI];
    } else {
      // recycled the lynxUI on this cell.
      LynxUI *lynxUI = [uiCell removeLynxUI];
      [self recycleLynxUI:lynxUI];
    }
  }
}

#pragma mark - LynxUIEvents

- (void)eventDidSet {
  [super eventDidSet];
  self.scrollEventEmitter.enableScrollEvent = NO;
  self.scrollEventEmitter.enableScrollToLowerEvent = NO;
  self.scrollEventEmitter.enableScrollToUpperEvent = NO;

  if ([self.eventSet objectForKey:kLynxEventScroll]) {
    self.scrollEventEmitter.enableScrollEvent = YES;
  }
  if ([self.eventSet objectForKey:kLynxEventScrollToLower]) {
    self.scrollEventEmitter.enableScrollToLowerEvent = YES;
  }
  if ([self.eventSet objectForKey:kLynxEventScrollToUpper]) {
    self.scrollEventEmitter.enableScrollToUpperEvent = YES;
  }

  if ([self.eventSet objectForKey:kLynxEventUICollectionLayoutComplete]) {
    self.needsLayoutCompleteEvent = YES;
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // Notify list did scroll.
  [self.context.observer notifyScroll:nil];
  if ([scrollView isKindOfClass:UICollectionView.class]) {
    [self.scroll collectionViewDidScroll:(UICollectionView *)scrollView];
  }
  [self.scrollEventEmitter scrollViewDidScroll:scrollView];
  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector(scrollerDidScroll:)]];

  for (id<LynxUIListDelegate> delegate in self.listDelegates) {
    if ([delegate respondsToSelector:@selector(listDidScroll:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxUIListDelegate::listDidScroll");
      [delegate listDidScroll:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.scrollEventEmitter.helper.scrollState = LynxListScrollStateDargging;

  if ([scrollView isKindOfClass:UICollectionView.class]) {
    [self.scroll collectionViewWillBeginDragging:(UICollectionView *)scrollView];
  }
  [self.scrollEventEmitter scrollViewWillBeginDragging:scrollView];
  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector(scrollerWillBeginDragging:)]];

  for (id<LynxUIListDelegate> delegate in self.listDelegates) {
    if ([delegate respondsToSelector:@selector(listWillBeginDragging:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxUIListDelegate::listWillBeginDragging");
      [delegate listWillBeginDragging:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  self.scrollEventEmitter.helper.scrollState = LynxListScrollStateNone;

  [self.scrollEventEmitter scrollViewDidEndDragging:scrollView willDecelerate:decelerate];

  LynxScrollInfo *info = [self infoWithScrollView:scrollView
                                         selector:@selector(scrollerDidEndDragging:
                                                                    willDecelerate:)];
  info.decelerate = decelerate;
  [self postFluencyEventWithInfo:info];

  for (id<LynxUIListDelegate> delegate in self.listDelegates) {
    if ([delegate respondsToSelector:@selector(listDidEndDragging:willDecelerate:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIListDelegate::scrollerDidEndDragging");
      [delegate listDidEndDragging:scrollView willDecelerate:decelerate];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  self.scrollEventEmitter.helper.scrollState = LynxListScrollStateNone;

  [self.scrollEventEmitter scrollViewDidEndDecelerating:scrollView];

  [self
      postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                               selector:@selector(scrollViewDidEndDecelerating:)]];
  for (id<LynxUIListDelegate> delegate in self.listDelegates) {
    if ([delegate respondsToSelector:@selector(listDidEndDecelerating:)]) {
      LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                         @"LynxUIListDelegate::listDidEndDecelerating");
      [delegate listDidEndDecelerating:scrollView];
      LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
    }
  }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  self.scrollEventEmitter.helper.scrollState = LynxListScrollStateScrolling;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self postFluencyEventWithInfo:[self infoWithScrollView:scrollView
                                                 selector:@selector
                                                 (scrollerDidEndScrollingAnimation:)]];

  self.scrollEventEmitter.helper.scrollState = LynxListScrollStateNone;
  if ([scrollView isKindOfClass:UICollectionView.class]) {
    [self.scroll collectionViewDidEndScrollingAnimation:(UICollectionView *)scrollView];
  }
}

#pragma mark - LynxListScrollEventEmitterDelegate

- (BOOL)shouldForceSendLowerThresholdEvent {
  NSInteger lastVisibleCellPosition;
  NSInteger firstVisibleCellPosition;
  [self visibleCellFirst:&firstVisibleCellPosition Last:&lastVisibleCellPosition];
  return lastVisibleCellPosition >
         ((NSInteger)[self count]) - self.scrollLowerThresholdItemCount - 1;
}

- (BOOL)shouldForceSendUpperThresholdEvent {
  NSInteger lastVisiableCellPosition;
  NSInteger firstVisiableCellPosition;
  [self visibleCellFirst:&firstVisiableCellPosition Last:&lastVisiableCellPosition];
  return firstVisiableCellPosition < self.scrollUpperThresholdItemCount;
}

- (NSArray *)attachedCellsArray {
  if (self.needsVisibleCells) {
    return [self visibleCellArray];
  } else {
    return nil;
  }
}

- (void)visibleCellFirst:(NSInteger *)first Last:(NSInteger *)last {
  NSInteger firstCellPosition = INT_MAX;
  NSInteger lastCellPosition = 0;

  for (LynxCollectionViewCell *cell in self.view.visibleCells) {
    if (cell == nil) {
      continue;
    }
    NSIndexPath *indexPath = [self.view indexPathForCell:cell];
    if (indexPath.row > lastCellPosition) {
      lastCellPosition = indexPath.row;
    }
    if (indexPath.row < firstCellPosition) {
      firstCellPosition = indexPath.row;
    }
  }
  *first = firstCellPosition;
  *last = lastCellPosition;
}

- (NSArray *)visibleCellArray {
  NSMutableArray *attachedCells = [[NSMutableArray alloc] init];

  for (LynxCollectionViewCell *cell in self.view.visibleCells) {
    if (cell == nil) {
      continue;
    }
    NSIndexPath *indexPath = [self.view indexPathForCell:cell];
    CGFloat cellTop = cell.frame.origin.y - self.view.contentOffset.y;
    CGFloat cellLeft = cell.frame.origin.x - self.view.contentOffset.x;
    NSDictionary *cellMsg = @{
      @"id" : cell.ui == nil ? @"" : cell.ui.idSelector,
      @"position" : [NSNumber numberWithInteger:indexPath.row],
      @"top" : [NSNumber numberWithFloat:cellTop],
      @"bottom" : [NSNumber numberWithFloat:cellTop + cell.frame.size.height],
      @"left" : [NSNumber numberWithFloat:cellLeft],
      @"right" : [NSNumber numberWithFloat:cellLeft + cell.frame.size.width],
    };
    [attachedCells addObject:cellMsg];
  }
  [attachedCells sortUsingComparator:^NSComparisonResult(id _Nonnull lhs, id _Nonnull rhs) {
    NSDictionary *lhsCellMsg = (NSDictionary *)lhs;
    NSDictionary *rhsCellMsg = (NSDictionary *)rhs;
    NSInteger lhsPosition = [lhsCellMsg[@"position"] integerValue];
    NSInteger rhsPosition = [rhsCellMsg[@"position"] integerValue];

    if (lhsPosition < rhsPosition) {
      return NSOrderedAscending;
    }

    if (lhsPosition > rhsPosition) {
      return NSOrderedDescending;
    }

    return NSOrderedSame;
  }];
  return attachedCells;
}

LYNX_UI_METHOD(scrollToPosition) {
  NSInteger position = ((NSNumber *)[params objectForKey:@"position"]).intValue;
  __block CGFloat offset = ((NSNumber *)[params objectForKey:@"offset"]).doubleValue;
  BOOL smooth = [[params objectForKey:@"smooth"] boolValue];
  BOOL useScroller = [[params objectForKey:@"useScroller"] boolValue];
  NSString *alignTo = [params objectForKey:@"alignTo"];
  if (position < 0 || (NSUInteger)position >= self.count) {
    LYNX_LIST_DEBUG_LOG(@"invalid position: %@, itemCount: %@", @(position), @(self.count));
    if (callback) {
      callback(kUIMethodParamInvalid, @"position < 0 or position >= data count");
    }
    return;
  }
  LYNX_LIST_DEBUG_LOG(@"position: %@", @(position));

  [self.scroll scrollCollectionView:self.view
                           position:position
                             offset:offset
                            alignTo:alignTo
                             smooth:smooth
                        useScroller:useScroller
                           callback:callback];
}

LYNX_UI_METHOD(autoScroll) {
  if ([[params objectForKey:@"start"] boolValue]) {
    CGFloat rate = [self toPtWithUnitValue:[params objectForKey:@"rate"] fontSize:0];
    NSInteger preferredFramesPerSecond = 1000 / 16;

    // We can not move less than 1/scale pt in every frame, cause contentOffset will align to
    // 1/scale.
    while (ABS(rate / preferredFramesPerSecond) < 1.0 / UIScreen.mainScreen.scale) {
      preferredFramesPerSecond -= 1;
      if (preferredFramesPerSecond == 0) {
        if (callback) {
          callback(kUIMethodMethodNotFound, @"rate is too small to scroll");
        }
        return;
      }
    };

    NSTimeInterval interval = 1.0 / preferredFramesPerSecond;
    rate *= interval;
    LynxScrollViewTouchBehavior behavior = LynxScrollViewTouchBehaviorNone;
    NSString *behaviorStr = [params objectForKey:@"touchBehavior"];
    if ([behaviorStr isEqualToString:@"forbid"]) {
      behavior = LynxScrollViewTouchBehaviorForbid;
    } else if ([behaviorStr isEqualToString:@"pause"]) {
      behavior = LynxScrollViewTouchBehaviorPause;
    } else if ([behaviorStr isEqualToString:@"stop"]) {
      behavior = LynxScrollViewTouchBehaviorStop;
    }

    BOOL autoStop = [([params objectForKey:@"autoStop"] ?: @(YES)) boolValue];

    [self.view autoScrollWithRate:rate
                         behavior:behavior
                         interval:interval
                         autoStop:autoStop
                         vertical:!self.scroll.horizontalLayout];
  } else {
    [self.view stopScroll];
  }
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

LYNX_UI_METHOD(scrollToIndex) {
  NSInteger index = ((NSNumber *)[params objectForKey:@"index"]).intValue;
  UICollectionView *collectionView = self.view;
  LynxCollectionViewLayout *layout =
      (LynxCollectionViewLayout *)collectionView.collectionViewLayout;
  if ([layout isKindOfClass:LynxCollectionViewLayout.class]) {
    layout.needsAdjustContentOffsetForSelfSizingCells = YES;
  }
  UICollectionViewLayoutAttributes *attr = [collectionView.collectionViewLayout
      layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
  CGFloat tragetOffset = MAX(-collectionView.contentInset.top,
                             MIN(attr.frame.origin.y, collectionView.contentSize.height -
                                                          collectionView.bounds.size.height +
                                                          collectionView.contentInset.bottom));
  [collectionView setContentOffset:CGPointMake(collectionView.contentOffset.x, tragetOffset)];
  if (callback) {
    callback(kUIMethodSuccess, @"");
  }
  return;
}

LYNX_UI_METHOD(getVisibleCells) {
  if (callback == nil) {
    return;
  }
  callback(kUIMethodSuccess, [self visibleCellArray]);
}

#pragma mark - Event, layoutcomplete
- (void)sendLayoutCompleteEvent {
  if (!self.needsLayoutCompleteEvent) {
    return;
  }

  NSMutableDictionary *detail = [[NSMutableDictionary alloc] init];

  CGFloat currentTimeInMS = [[NSDate date] timeIntervalSince1970] * 1000;
  NSNumber *currentTick = [NSNumber numberWithDouble:currentTimeInMS];
  detail[@"timestamp"] = currentTick;

  NSUInteger numberOfCells = [self.reuseIdentifiers count];
  NSMutableArray<NSString *> *cellComponentNames = [NSMutableArray new];
  for (NSUInteger i = 0; i < numberOfCells; ++i) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
    [cellComponentNames addObject:[self.reuseIdentifiers[indexPath.item] copy]];
  }

  detail[@"cells"] = cellComponentNames;

  LynxCustomEvent *onLayoutCompletedEvent =
      [[LynxDetailEvent alloc] initWithName:kLynxEventUICollectionLayoutComplete
                                 targetSign:self.sign
                                     detail:detail];
  [self.context.eventEmitter sendCustomEvent:onLayoutCompletedEvent];
}

@end
