//
//  BDXLynxSwiperPageView.m
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import "BDXLynxSwiperPageView.h"
#import <ByteDanceKit/BTDWeakProxy.h>
#import "BDXLynxSwiperCollectionView.h"

NS_INLINE BOOL BDXLynxSwiperEqualIndexSection(BDXLynxSwiperIndexSection indexSection1,BDXLynxSwiperIndexSection indexSection2) {
    return indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section;
}

NS_INLINE BDXLynxSwiperIndexSection BDXSwiperSetIndexSection(NSInteger index, NSInteger section) {
    BDXLynxSwiperIndexSection indexSection;
    indexSection.index = index;
    indexSection.section = section;
    return indexSection;
}

@interface BDXLynxSwiperPageView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BDXLynxSwiperTransformLayoutDelegate> {
    struct {
        unsigned int pagerViewDidScroll   :1;
        unsigned int didScrollFromIndexToNewIndex   :1;
        unsigned int initializeTransformAttributes   :1;
        unsigned int applyTransformToAttributes   :1;
    }_delegateFlags;
    struct {
        unsigned int cellForItemAtIndex   :1;
        unsigned int layoutForPagerView   :1;
    }_dataSourceFlags;
  BOOL _isInfiniteLoop;
}

// UI
@property (nonatomic, weak) BDXLynxSwiperCollectionView *collectionView;
@property (nonatomic, strong) BDXLynxSwiperViewLayout *layout;
@property (nonatomic, strong) NSTimer *timer;

// Data
@property (nonatomic, assign) NSInteger numberOfItems;

@property (nonatomic, assign) NSInteger dequeueSection;
@property (nonatomic, assign) BDXLynxSwiperIndexSection beginDragIndexSection;
@property (nonatomic, assign) BDXLynxSwiperIndexSection dragTargetIndexSection;
@property (nonatomic, assign) BDXLynxSwiperIndexSection prevIndexSection;
@property (nonatomic, assign) BDXLynxSwiperIndexSection originalIndexSection;
@property (nonatomic, assign) NSInteger firstScrollIndex;

@property (nonatomic, assign) BOOL needClearLayout;
@property (nonatomic, assign) BOOL didReloadData;
@property (nonatomic, assign) BOOL didLayout;
@property (nonatomic, assign) BOOL needResetIndex;
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, assign) BOOL needCheckBind;
// We need a property to record the actual `index` of the UI, at the mode of `BDXLynxSwiperBindChangeWithUI`
@property (nonatomic, assign) NSInteger currentIndexWithUI;

@end

#define kPagerViewMaxSectionCount 200
#define kPagerViewMinSectionCount 18

@implementation BDXLynxSwiperPageView

#pragma mark - life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureProperty];
        [self addCollectionView];
      _currentIndexWithUI = -1;
    }
    return self;
}


- (void)setIsInfiniteLoop:(BOOL)isInfiniteLoop {
  if (_isInfiniteLoop != isInfiniteLoop) {
    CGFloat offset = [self calculateOffsetAtIndexSection:_indexSection];
    CGFloat delta = 0;
    
    delta = self.layout.vertical ? _collectionView.contentOffset.y - offset : _collectionView.contentOffset.x - offset;
    
    _isInfiniteLoop = isInfiniteLoop;
    [self setNeedClearLayout];
    [self clearLayout];
    [self updateLayout];
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    [_collectionView reloadData];
    
    [self scrollToItemAtIndexSection:BDXSwiperSetIndexSection(_indexSection.index, self.isInfiniteLoop ? kPagerViewMaxSectionCount/3 : 0) animate:NO];
    CGPoint targetOffset =  self.layout.vertical ? CGPointMake(_collectionView.contentOffset.x, _collectionView.contentOffset.y + delta)  : CGPointMake(_collectionView.contentOffset.x + delta, _collectionView.contentOffset.y);
    [_collectionView setContentOffset:targetOffset];
    
    if (_dragTargetIndexSection.index != -1) {
      [self scrollToItemAtIndexSection:BDXSwiperSetIndexSection(_dragTargetIndexSection.index, self.isInfiniteLoop ? kPagerViewMaxSectionCount/3 : 0) animate:YES];
    }
  }
}

- (BOOL)isInfiniteLoop {
  if (self.numberOfItems <= 1) {
    return NO;
  } else {
    return _isInfiniteLoop;
  }
}

- (void)configureProperty {
    _needResetIndex = NO;
    _didReloadData = NO;
    _didLayout = NO;
    _autoScrollInterval = 0;
    _isInfiniteLoop = YES;
    _dragTargetIndexSection.index = -1;
    _dragTargetIndexSection.section = -1;
    _beginDragIndexSection.index = 0;
    _beginDragIndexSection.section = 0;
    _indexSection.index = -1;
    _indexSection.section = -1;
    _firstScrollIndex = -1;
}

- (void)switchToNonFlipLayout {
    BDXLynxSwiperTransformLayoutNonFlip *layoutNonFlip = [[BDXLynxSwiperTransformLayoutNonFlip alloc] init];
    [layoutNonFlip setDelegate:_delegateFlags.applyTransformToAttributes ? self : nil];
    _collectionView.collectionViewLayout = layoutNonFlip;
}

- (void)addCollectionView {
  
    BDXLynxSwiperTransformLayout *layout = [[BDXLynxSwiperTransformLayout alloc] init];
    BDXLynxSwiperCollectionView *collectionView = [[BDXLynxSwiperCollectionView alloc]initWithFrame:self.bounds collectionViewLayout:layout];
  collectionView.touchBehavior = LynxScrollViewTouchBehaviorStop;
  collectionView.scrollEnableFromLynx = YES;
  collectionView.scrollsToTop = NO;
  if (UIAccessibilityIsVoiceOverRunning()) {
    CGPoint (^accessibilityHookBlock)(UIScrollView *scrollView, CGPoint originalOffset) = ^(UIScrollView *scrollView, CGPoint originalOffset) {
      // return current contentOffset to disable any scroll actions invoked by UIAccessibility 
      return scrollView.contentOffset;
    };
    // for aweme only, depends on AWEListKit
    // the private method `-_accessibilityOffsetForOpaqueElementDirection:` will be hooked with awelistkit_customAccessibilityOffsetBlock
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([collectionView respondsToSelector:@selector(setAwelistkit_customAccessibilityOffsetBlock:)]) {
      [collectionView performSelector:@selector(setAwelistkit_customAccessibilityOffsetBlock:) withObject:[accessibilityHookBlock copy]];
    }
#pragma clang diagnostic pop
  }
  if (@available(iOS 11.0, *)) {
  collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  if (@available(iOS 13.0, *)) {
  collectionView.automaticallyAdjustsScrollIndicatorInsets = NO;
  }
    layout.delegate = _delegateFlags.applyTransformToAttributes ? self : nil;;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.clipsToBounds = NO;
    collectionView.pagingEnabled = NO;
    collectionView.decelerationRate = 1-0.0076;
    if ([collectionView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
        if (@available(iOS 10.0, *)) {
            collectionView.prefetchingEnabled = NO;
        } else {
            // Fallback on earlier versions
        }
    }
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) {
        [self removeTimer];
    }else {
        [self removeTimer];
        if (_autoScrollInterval > 0) {
            [self addTimer];
        }
    }
}

- (void)removeFromSuperview
{
    [self removeTimer];
    [super removeFromSuperview];
}

#pragma mark - timer

- (void)addTimer {
    if (_timer || _autoScrollInterval <= 0) {
        return;
    }
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    if (!_timer) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFired:(NSTimer *)timer {
    if (!self.superview || !self.window || _numberOfItems == 0 || self.tracking || ((BDXLynxSwiperCollectionView *)(self.collectionView)).duringCustomScroll) {
        return;
    }
  
  // do not scroll if number of items <= 1
  if (self.numberOfItems <= 1) {
    return;
  }
  
  // if just do nothing if reach end without infinite loop
  if (!self.isInfiniteLoop && self.curIndex == (self.numberOfItems - 1)) {
    return;
  }
    if (self.layout.vertical) {
        [self scrollToNearlyIndexAtDirection:BDPLynxSwiperScrollDirectionBottom animate:self.smoothScroll];
    } else {
      [self scrollToNearlyIndexAtDirection:BDXLynxSwiperScrollDirectionRight animate:self.smoothScroll];
    }
}

#pragma mark - getter

- (BDXLynxSwiperViewLayout *)layout {
    if (!_layout) {
        if (_dataSourceFlags.layoutForPagerView) {
            _layout = [_dataSource layoutForPagerView:self];
            _layout.isInfiniteLoop = self.isInfiniteLoop;
        }
        if (_layout.itemSize.width <= 0 || _layout.itemSize.height <= 0) {
            _layout = nil;
        }
    }
    return _layout;
}

- (NSInteger)curIndex {
    return _indexSection.index;
}

- (CGPoint)contentOffset {
    return _collectionView.contentOffset;
}

- (BOOL)tracking {
    return _collectionView.tracking;
}

- (BOOL)dragging {
    return _collectionView.dragging;
}

- (BOOL)decelerating {
    return _collectionView.decelerating;
}

- (UIView *)backgroundView {
    return _collectionView.backgroundView;
}

- (__kindof UICollectionViewCell *)curIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

- (NSArray<__kindof UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

- (NSArray *)visibleIndexs {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [indexs addObject:@(indexPath.item)];
    }
    return [indexs copy];
}

#pragma mark - setter

- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    [self removeTimer];
    if (autoScrollInterval > 0 && self.superview) {
        [self addTimer];
    }
}

- (void)setDelegate:(id<BDXLynxSwiperPageViewDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.pagerViewDidScroll = [delegate respondsToSelector:@selector(pagerViewDidScroll:)];
    _delegateFlags.didScrollFromIndexToNewIndex = [delegate respondsToSelector:@selector(pagerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)];
    if (self.collectionView && self.collectionView.collectionViewLayout) {
        ((BDXLynxSwiperTransformLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    }
}

- (void)setDataSource:(id<BDXLynxSwiperPageViewDataSource>)dataSource {
    _dataSource = dataSource;
    _dataSourceFlags.cellForItemAtIndex = [dataSource respondsToSelector:@selector(pagerView:cellForItemAtIndex:)];
    _dataSourceFlags.layoutForPagerView = [dataSource respondsToSelector:@selector(layoutForPagerView:)];
}

#pragma mark - public

- (void)reloadData:(NSArray *)dataArrays {
    _didReloadData = YES;
    _needResetIndex = YES;
    [self setNeedClearLayout];
    [self clearLayout];
    [self updateData];
}

// not clear layout
- (void)updateData {
    [self updateLayout];
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    [_collectionView reloadData];
  [_collectionView.collectionViewLayout invalidateLayout];
    if (!_didLayout && !CGRectIsEmpty(self.collectionView.frame) && _indexSection.index < 0) {
        _didLayout = YES;
    }
    BOOL needResetIndex = _needResetIndex && _reloadDataNeedResetIndex;
    _needResetIndex = NO;
    if (needResetIndex) {
        [self removeTimer];
    }
    [self resetPagerViewAtIndex:(_indexSection.index < 0 && !CGRectIsEmpty(self.collectionView.frame)) || needResetIndex ? 0 :_indexSection.index];
    if (needResetIndex) {
        [self addTimer];
    }
}


- (void)scrollToNearlyIndexAtDirection:(BDXLynxSwiperScrollDirection)direction animate:(BOOL)animate {
    BDXLynxSwiperIndexSection indexSection = [self nearlyIndexPathAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
  [self scrollToItemAtIndex:index animate:animate force:NO];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate force:(BOOL)force {
    if (!force && _dragTargetIndexSection.index == index) {
      return;
    }
  if (self.bindChangeType == BDXLynxSwiperBindChangeWithUI && index == _indexSection.index && self.isScrolling) {
    return;
  }
    if (!_didLayout && _didReloadData) {
        _firstScrollIndex = -1;
    }else {
        _firstScrollIndex = index;
    }
    if (!self.isInfiniteLoop) {
        [self scrollToItemAtIndexSection:BDXSwiperSetIndexSection(index, 0) animate:animate];
        return;
    }

    NSInteger offset = index - _indexSection.index;
    NSInteger signedOffset = _numberOfItems / 2.0 > ABS(offset) ? offset : offset > 0 ? offset - _numberOfItems : _numberOfItems + offset;
    if (self.layout.vertical) {
        [self scrollToItemAtIndexSection:[self nearlyIndexPathForIndexSection:self.indexSection
                                                                    direction:signedOffset >= 0 ? BDPLynxSwiperScrollDirectionBottom : BDPLynxSwiperScrollDirectionTop
                                                                       offset:ABS(signedOffset)]
                                 animate:animate];
    } else {
        [self scrollToItemAtIndexSection:[self nearlyIndexPathForIndexSection:self.indexSection
                                                                    direction:signedOffset >= 0 ? BDXLynxSwiperScrollDirectionRight : BDXLynxSwiperScrollDirectionLeft
                                                                       offset:ABS(signedOffset)]
                                 animate:animate];
    }
    
}

- (void)scrollToItemAnimatedAtIndex:(NSInteger)index direction:(BDXLynxSwiperScrollDirection)direction {
  [self scrollToItemAnimatedAtIndex:index direction:direction force:NO];
}

- (void)scrollToItemAnimatedAtIndex:(NSInteger)index direction:(BDXLynxSwiperScrollDirection)direction force:(BOOL)force {
  if (!force && _dragTargetIndexSection.index == index) {
    return;
  }
  if (!_didLayout && _didReloadData) {
    _firstScrollIndex = -1;
  }else {
    _firstScrollIndex = index;
  }
  // if not infinite, scroll as usual
  if (!self.isInfiniteLoop) {
    [self scrollToItemAtIndexSection:BDXSwiperSetIndexSection(index, 0) animate:YES];
    return;
  }
  
  NSInteger offset = index - _indexSection.index;
  
  if (index > _indexSection.index) {
    if (direction == BDXLynxSwiperScrollDirectionLeft || direction == BDPLynxSwiperScrollDirectionTop) {
      offset = _indexSection.index + _numberOfItems - index;
    }
  } else if (index < _indexSection.index) {
    if (direction == BDXLynxSwiperScrollDirectionRight || direction == BDPLynxSwiperScrollDirectionBottom) {
      offset = index + _numberOfItems - _indexSection.index;
    }
  }
  
  [self scrollToItemAtIndexSection:[self nearlyIndexPathForIndexSection:self.indexSection
                                                              direction:direction
                                                                 offset:ABS(offset)]
                           animate:YES];
  
}



- (void)scrollToItemAtIndexSection:(BDXLynxSwiperIndexSection)indexSection animate:(BOOL)animate {
    if (_numberOfItems <= 0 || ![self isValidIndexSection:indexSection]) {
        //NSLog(@"scrollToItemAtIndex: item indexSection is invalid!");
        return;
    }
    
    if (animate && [_delegate respondsToSelector:@selector(pagerViewWillBeginScrollingAnimation:)]) {
        [_delegate pagerViewWillBeginScrollingAnimation:self];
    }
    CGFloat offset = [self calculateOffsetAtIndexSection:indexSection];
    CGFloat adjustOffset = [self adjustOffset:offset];
  if (adjustOffset != offset && _didLayout) {
    offset = adjustOffset;
    indexSection = [self calculateIndexSectionWithOffset:offset];
  }
    // 前端手动 setCurrent 之后禁用交互，防止tap事件打断scrollview滑动。
    if (animate && fabs(offset - _collectionView.contentOffset.x) > 10) {
        _collectionView.userInteractionEnabled = NO;
      __weak typeof(self) weakSelf = self;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        // if setState happens during scroll-anim, scrollViewDidEndScrollingAnimation: may not be called, so we reset userInteractionEnabled to YES after animation (default duration is 250ms)
          weakSelf.collectionView.userInteractionEnabled = YES;
      });
    } else {
        _collectionView.userInteractionEnabled = YES;
    }
    if (!animate) {
        if (self.layout.vertical) {
            [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, offset) animated:animate];
        } else {
            [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
        }
        _prevIndexSection = _indexSection;
        _indexSection = indexSection;
    } else {
        if (self.layout.vertical) {
            [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, offset) animated:animate];
        } else {
            [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
        }
    }
    // 第一次渲染不触发bindchange回调
    if (_didLayout && !self.smoothScroll && !(_prevIndexSection.index == -1 && _prevIndexSection.section == -1)) {
        [self scrollViewDidEndScrollingAnimation:_collectionView];
    }
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_dequeueSection]];
    return cell;
}

#pragma mark - configure layout

- (void)updateLayout {
    if (!self.layout) {
        return;
    }
    self.layout.isInfiniteLoop = self.isInfiniteLoop;
    ((BDXLynxSwiperTransformLayout *)_collectionView.collectionViewLayout).layout = self.layout;
}

- (void)setLayoutType:(BDXLynxSwiperTransformLayoutType)layoutType
{
    _layoutType = layoutType;
    self.layout.layoutType = layoutType;
}

- (void)clearLayout {
    if (_needClearLayout) {
        _layout = nil;
        _needClearLayout = NO;
    }
}

- (void)setNeedClearLayout {
    _needClearLayout = YES;
}

- (void)setNeedUpdateLayout {
    if (!self.layout) {
        return;
    }
    
    [self clearLayout];
    [self updateLayout];
    [_collectionView.collectionViewLayout invalidateLayout];
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 :_indexSection.index];
}

#pragma mark - pager index

- (BOOL)isValidIndexSection:(BDXLynxSwiperIndexSection)indexSection {
    return indexSection.index >= 0 && indexSection.index < _numberOfItems && indexSection.section >= 0 && indexSection.section < kPagerViewMaxSectionCount;
}

- (BDXLynxSwiperIndexSection)nearlyIndexPathAtDirection:(BDXLynxSwiperScrollDirection)direction {
    return [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
}

- (BDXLynxSwiperIndexSection)nearlyIndexPathForIndexSection:(BDXLynxSwiperIndexSection)indexSection
                                                  direction:(BDXLynxSwiperScrollDirection)direction {
    return [self nearlyIndexPathForIndexSection:indexSection
                                      direction:direction
                                         offset:1];
}

- (BDXLynxSwiperIndexSection)nearlyIndexPathForIndexSection:(BDXLynxSwiperIndexSection)indexSection
                                                  direction:(BDXLynxSwiperScrollDirection)direction
                                                     offset:(NSInteger)offset {
    if (indexSection.index < 0 || indexSection.index >= _numberOfItems) {
        return indexSection;
    }
    
    if (!self.isInfiniteLoop) {
        if ((direction == BDXLynxSwiperScrollDirectionRight || direction == BDPLynxSwiperScrollDirectionBottom)
            && indexSection.index >= _numberOfItems - offset) {
            return indexSection;
        } else if (direction == BDXLynxSwiperScrollDirectionRight || direction == BDPLynxSwiperScrollDirectionBottom) {
            return BDXSwiperSetIndexSection(indexSection.index + offset, 0);
        }
        
        else if (indexSection.index == 0 && BDPLynxSwiperScrollDirectionTop) {
            return BDXSwiperSetIndexSection(0, 0);
        } else if (direction == BDPLynxSwiperScrollDirectionTop) {
            return BDXSwiperSetIndexSection(indexSection.index - offset, 0);
        }
        
        if (indexSection.index < offset) {
            return _autoScrollInterval > 0 ? BDXSwiperSetIndexSection(_numberOfItems - 1, 0) : indexSection;
        }
        return BDXSwiperSetIndexSection(indexSection.index - offset, 0);
    }
    
    if (direction == BDXLynxSwiperScrollDirectionRight || direction == BDPLynxSwiperScrollDirectionBottom) {
        if (indexSection.index < _numberOfItems - offset) {
            return BDXSwiperSetIndexSection(indexSection.index + offset, indexSection.section);
        }
        if (indexSection.section >= kPagerViewMaxSectionCount - 1) {
            return BDXSwiperSetIndexSection(indexSection.index, kPagerViewMaxSectionCount - 1);
        }
        return BDXSwiperSetIndexSection((indexSection.index + offset) % _numberOfItems,
                indexSection.section + (NSUInteger)((indexSection.index + offset) / _numberOfItems));
    }
    
    if (indexSection.index >= offset) {
        return BDXSwiperSetIndexSection(indexSection.index - offset, indexSection.section);
    }
    if (indexSection.section <= 0) {
        return BDXSwiperSetIndexSection(indexSection.index, 0);
    }
    return BDXSwiperSetIndexSection(((indexSection.index - offset) % _numberOfItems + _numberOfItems) % _numberOfItems,
            indexSection.section + (NSInteger)((indexSection.index - offset) / _numberOfItems) - 1);
}

- (BDXLynxSwiperIndexSection)calculateIndexSectionWithOffset:(CGFloat)offset {
    if (_numberOfItems <= 0) {
        return BDXSwiperSetIndexSection(0, 0);
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat edge;
    CGFloat size;
    CGFloat middleOffset;
    CGFloat itemSize;
    if (self.layout.vertical) {
        edge = self.isInfiniteLoop ? _layout.sectionInset.top : _layout.onlyOneSectionInset.top;
        size = CGRectGetHeight(_collectionView.frame);
//        middleOffset = offset + size/2;
        itemSize = layout.itemSize.height + layout.minimumLineSpacing;
      middleOffset = offset + itemSize / 2;
    } else {
        edge = self.isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
        size = CGRectGetWidth(_collectionView.frame);
//        middleOffset = offset + size/2;
        itemSize = layout.itemSize.width + layout.minimumInteritemSpacing;
      middleOffset = offset + edge + itemSize / 2;
    }
    
    if (self.layoutType == BDXLynxSwiperTransformLayoutMultiplePages) {
        size = layout.itemSize.width;
        middleOffset = offset + edge + itemSize/2;
    }
    
    NSInteger curIndex = 0;
    NSInteger curSection = 0;
    if (middleOffset - edge >= 0) {
        NSInteger itemIndex;
        if (self.layout.vertical) {
            itemIndex = (NSInteger)((middleOffset - edge + layout.minimumLineSpacing / 2) / itemSize);
        } else {
            itemIndex = (NSInteger)((middleOffset - edge + layout.minimumInteritemSpacing / 2) / itemSize);
        }
        if (itemIndex < 0) {
            itemIndex = 0;
        }else if (itemIndex >= _numberOfItems*kPagerViewMaxSectionCount) {
            itemIndex = _numberOfItems*kPagerViewMaxSectionCount-1;
        }
        curIndex = (!self.isInfiniteLoop && itemIndex >= _numberOfItems) ? _numberOfItems - 1 : itemIndex%_numberOfItems;
        curSection = itemIndex/_numberOfItems;
    }
    return BDXSwiperSetIndexSection(curIndex, curSection);
}

- (CGFloat)calculateOffsetAtIndexSection:(BDXLynxSwiperIndexSection)indexSection {
    if (_numberOfItems == 0) {
        return 0;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    UIEdgeInsets edge = self.isInfiniteLoop ? _layout.sectionInset : _layout.onlyOneSectionInset;
    CGFloat leftEdge = self.layout.vertical ? edge.top : edge.left;
    CGFloat size = self.layout.vertical ? CGRectGetHeight(_collectionView.frame) : CGRectGetWidth(_collectionView.frame);
    CGFloat itemSize = self.layout.vertical ? (layout.itemSize.height + layout.minimumLineSpacing) : (layout.itemSize.width + layout.minimumInteritemSpacing);
    CGFloat offset = 0;
    if (self.layout.vertical) {
        if (!_layout.itemVerticalCenter) {
            offset = itemSize * (indexSection.index + indexSection.section*_numberOfItems);
        } else {
            offset = leftEdge + itemSize * (indexSection.index + indexSection.section*_numberOfItems) - layout.minimumLineSpacing/2 - (size - itemSize)/2;
        }
    } else {
        if (self.layoutType == BDXLynxSwiperTransformLayoutMultiplePages) {
            offset = itemSize * (indexSection.index + indexSection.section*_numberOfItems);
        } else if (!_layout.itemHorizontalCenter) {
            offset = itemSize * (indexSection.index + indexSection.section*_numberOfItems);
        } else {
            offset = leftEdge + itemSize * (indexSection.index + indexSection.section*_numberOfItems) - layout.minimumInteritemSpacing/2 - (size - itemSize)/2;;
        }
    }
    return MAX(offset, 0);
}


- (CGFloat)adjustOffset:(CGFloat)offset {
  if (self.isInfiniteLoop) {
    return offset;
  }
  if (self.layout.vertical) {
    CGFloat targetOffset = MAX(-_collectionView.contentInset.top,
                               MIN(offset, _collectionView.collectionViewLayout.collectionViewContentSize.height - _collectionView.frame.size.height +
                                   _collectionView.contentInset.bottom));
    return targetOffset;
  } else {
    CGFloat targetOffset = MAX(-_collectionView.contentInset.left,
                               MIN(offset, _collectionView.collectionViewLayout.collectionViewContentSize.width - _collectionView.frame.size.width +
                                   _collectionView.contentInset.right));
    return targetOffset;
  }
}

- (void)resetPagerViewAtIndex:(NSInteger)index {
    if (_didLayout && _firstScrollIndex >= 0) {
        index = _firstScrollIndex;
        _firstScrollIndex = -1;
    }
    if (index < 0) {
        return;
    }
    if (index >= _numberOfItems) {
        index = 0;
    }
    [self scrollToItemAtIndexSection:BDXSwiperSetIndexSection(index, self.isInfiniteLoop ? kPagerViewMaxSectionCount/3 : 0) animate:NO];
    if (!self.isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

- (void)recyclePagerViewIfNeed {
    if (!self.isInfiniteLoop) {
        return;
    }
    if (_indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount || _indexSection.section < kPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.isInfiniteLoop ? kPagerViewMaxSectionCount : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    return _numberOfItems;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _dequeueSection = indexPath.section;
    if (_dataSourceFlags.cellForItemAtIndex) {
       return [_dataSource pagerView:self cellForItemAtIndex:indexPath.row];
    }
    NSAssert(NO, @"pagerView cellForItemAtIndex: is nil!");
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  if (self.keepItemView) {
    // attach view to window, to make global exposure work
    UIView *endDisplayingView = cell.contentView.subviews.firstObject;
    [collectionView addSubview:endDisplayingView];
    endDisplayingView.frame = cell.frame;
  }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!self.isInfiniteLoop) {
        return _layout.onlyOneSectionInset;
    }
    if (section == 0 ) {
        return _layout.firstSectionInset;
    }else if (section == kPagerViewMaxSectionCount -1) {
        return _layout.lastSectionInset;
    }
    return _layout.middleSectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndex:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndex:indexPath.item];
    }
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndexSection:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndexSection:BDXSwiperSetIndexSection(indexPath.item, indexPath.section)];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(notifyScrollViewDidScroll)]) {
        [_delegate notifyScrollViewDidScroll];
    }
    
    if (!_didLayout) {
        return;
    }
  if (_currentIndexWithUI == -1) {
    // initialization
    _currentIndexWithUI = _indexSection.index;
  }
    if (!self.isScrolling && _indexSection.index >= 0) {
        self.isScrolling = true;
        if ([_delegate respondsToSelector:@selector(pagerView:didStartScrollFromIndex:)]) {
            [_delegate pagerView:self didStartScrollFromIndex:_indexSection.index];
        }
    }
    CGFloat direction = self.layout.vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x;
    BDXLynxSwiperIndexSection newIndexSection =  [self calculateIndexSectionWithOffset:direction];
    if (_numberOfItems <= 0 || ![self isValidIndexSection:newIndexSection]) {
        return;
    }
    if (!BDXLynxSwiperEqualIndexSection(_indexSection, newIndexSection)) {
        if (![self isValidIndexSection:_indexSection]) {
            _originalIndexSection = newIndexSection;
        }
        _prevIndexSection = _indexSection;
        _indexSection = newIndexSection;
      _needCheckBind = YES;
    }
  if (self.bindChangeType == BDXLynxSwiperBindChangeWithUI && !BDXLynxSwiperEqualIndexSection(_indexSection, _prevIndexSection) && _needCheckBind) {
    
    BOOL startToEnd = YES;
    if (self.layout.vertical) {
      startToEnd = _indexSection.index > _prevIndexSection.index;
    } else {
      if (self.layout.isRTL) {
        startToEnd = _indexSection.index < _prevIndexSection.index;
      } else {
        startToEnd = _indexSection.index > _prevIndexSection.index;
      }
    }
    
    if (self.isInfiniteLoop) {
      if (_numberOfItems == ABS(_prevIndexSection.index - _indexSection.index) + 1) {
        startToEnd = !startToEnd;
      }
    }
    
    CGFloat nextOffset = [self calculateOffsetAtIndexSection:_indexSection];

    
    if (startToEnd) {
      if ((self.layout.vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x) >= nextOffset) {
        [_delegate pagerView:self
          didScrollFromIndex:_prevIndexSection.index
                     toIndex:_indexSection.index];
        // update the `_currentIndexWithUI` if the `indexSection` is updated at the mode of `BDXLynxSwiperBindChangeWithUI`
        _currentIndexWithUI = _indexSection.index;
        _needCheckBind = NO;
      }
    } else {
      if ((self.layout.vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x) <= nextOffset) {
        [_delegate pagerView:self
          didScrollFromIndex:_prevIndexSection.index
                     toIndex:_indexSection.index];
        // update the `_currentIndexWithUI` if the `indexSection` is updated at the mode of `BDXLynxSwiperBindChangeWithUI`
        _currentIndexWithUI = _indexSection.index;
        _needCheckBind = NO;
      }
    }
  }

    if (_delegateFlags.pagerViewDidScroll) {
        [_delegate pagerViewDidScroll:self];
    }
    
    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:fromIndex:)]) {
      if (self.bindChangeType == BDXLynxSwiperBindChangeWithUI) {
        [_delegate scrollViewDidScroll:scrollView fromIndex:_currentIndexWithUI];
      } else {
        [_delegate scrollViewDidScroll:scrollView fromIndex:_indexSection.index];
      }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoScrollInterval > 0) {
        [self removeTimer];
    }
  CGFloat customDuration = ((BDXLynxSwiperCollectionView *)(self.collectionView)).customDuration;
  if (customDuration) {
    [((BDXLynxSwiperCollectionView *)(self.collectionView)) stopScroll];
  }
    CGFloat direction = 0.0;
    if (self.layout.vertical) {
        direction = scrollView.contentOffset.y;
    } else {
        direction = scrollView.contentOffset.x;
    }

    _beginDragIndexSection = [self calculateIndexSectionWithOffset:direction];
    if (!self.isScrolling && _beginDragIndexSection.index >= 0) {
        self.isScrolling = true;
        if ([_delegate respondsToSelector:@selector(pagerView:didStartScrollFromIndex:)]) {
            [_delegate pagerView:self didStartScrollFromIndex:_beginDragIndexSection.index];
        }
    }
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDragging:)]) {
        [_delegate pagerViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat directionVelocity = self.layout.vertical ? velocity.y : velocity.x;
  
  CGFloat customDuration = ((BDXLynxSwiperCollectionView *)(self.collectionView)).customDuration;
  BDXLynxSwiperCollectionView *swiperView = (BDXLynxSwiperCollectionView *)(self.collectionView);
    if (fabs(directionVelocity) < 0.35 || !BDXLynxSwiperEqualIndexSection(_beginDragIndexSection, _indexSection)) {
        if (self.layoutType == BDXLynxSwiperTransformLayoutMultiplePages) {
            targetContentOffset->x = [self calculateOffsetAtIndexSection:[self calculateIndexSectionWithOffset:targetContentOffset->x]];
            _dragTargetIndexSection = _indexSection;
        } else {
        CGFloat offset = [self calculateOffsetAtIndexSection:_indexSection];
        CGFloat adjustOffset = [self adjustOffset:offset];
        if (adjustOffset != offset) {
          offset = adjustOffset;
          _dragTargetIndexSection = [self calculateIndexSectionWithOffset:offset];
        } else {
          _dragTargetIndexSection = _indexSection;
        }
        
        if (self.layout.vertical) {
          targetContentOffset->y = offset;
          if (customDuration != 0) {
            [swiperView decelerateToContentOffset:*targetContentOffset
                                         duration:customDuration * MIN(1, ABS(self.collectionView.contentOffset.y - targetContentOffset->y) / self.collectionView.bounds.size.height)];
            targetContentOffset->y = scrollView.contentOffset.y;
          }
        } else {
          targetContentOffset->x = offset;
          if (customDuration != 0) {
            [swiperView decelerateToContentOffset:*targetContentOffset
                                         duration:customDuration * MIN(1, ABS(self.collectionView.contentOffset.x - targetContentOffset->x) / self.collectionView.bounds.size.width)];
            targetContentOffset->x = scrollView.contentOffset.x;
          }
        }
      }
      return;
    }
    BDXLynxSwiperScrollDirection direction = BDXLynxSwiperScrollDirectionRight;
    if (self.layout.vertical) {
        direction = BDPLynxSwiperScrollDirectionBottom;
        if ((scrollView.contentOffset.y < 0 && targetContentOffset->y <= 0) || (targetContentOffset->y < scrollView.contentOffset.y && scrollView.contentOffset.y < scrollView.contentSize.height - scrollView.frame.size.height)) {
            direction = BDPLynxSwiperScrollDirectionTop;
        }
    } else {
        if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
            direction = BDXLynxSwiperScrollDirectionLeft;
        }
    }
    
  if (self.layout.vertical) {
    BDXLynxSwiperIndexSection indexSection = targetContentOffset->y == scrollView.contentOffset.y ? _indexSection : [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    CGFloat offset = [self calculateOffsetAtIndexSection:indexSection];
    CGFloat adjustOffset = [self adjustOffset:offset];
    if (adjustOffset != offset) {
      offset = adjustOffset;
      [self calculateIndexSectionWithOffset:offset];
    } else {
      _dragTargetIndexSection = indexSection;
    }
    targetContentOffset->y = offset;
    if (customDuration != 0) {
      [swiperView decelerateToContentOffset:*targetContentOffset
                                   duration:customDuration * MIN(1, ABS(self.collectionView.contentOffset.y - targetContentOffset->y) / self.collectionView.bounds.size.height)];
      targetContentOffset->y = scrollView.contentOffset.y;
    }
  } else {
    BDXLynxSwiperIndexSection indexSection = targetContentOffset->x == scrollView.contentOffset.x ? _indexSection : [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    CGFloat offset = [self calculateOffsetAtIndexSection:indexSection];
    CGFloat adjustOffset = [self adjustOffset:offset];
    if (adjustOffset != offset) {
      offset = adjustOffset;
      //TODO(moonface.xmf) _indexSection maybe not accurate if a lot of items can be displayed in viewport simultaneous
      BDXLynxSwiperIndexSection targetIndexSection = indexSection;
      while (YES) {
        BDXLynxSwiperIndexSection preIndexSection = targetIndexSection;
        preIndexSection.index--;
        if (preIndexSection.index < 0) {
          break;
        }
        if ([self calculateOffsetAtIndexSection:preIndexSection] < offset) {
          break;
        }
        targetIndexSection = preIndexSection;
      }
      _dragTargetIndexSection = targetIndexSection;
    } else {
      _dragTargetIndexSection = indexSection;
    }
    targetContentOffset->x = offset;
    if (customDuration != 0) {
      [swiperView decelerateToContentOffset:*targetContentOffset
                                   duration:customDuration * MIN(1, ABS(self.collectionView.contentOffset.x - targetContentOffset->x) / self.collectionView.bounds.size.width)];
      targetContentOffset->x = scrollView.contentOffset.x;
    }
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_autoScrollInterval > 0) {
        [self addTimer];
    }
    _firstScrollIndex = _dragTargetIndexSection.index;
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDragging:willDecelerate:)]) {
        [_delegate pagerViewDidEndDragging:self willDecelerate:decelerate];
    }
    if (self.bindChangeType == BDXLynxSwiperBindChangeAfterDrag && _delegateFlags.didScrollFromIndexToNewIndex && !BDXLynxSwiperEqualIndexSection(_dragTargetIndexSection, _beginDragIndexSection)) {
        [_delegate pagerView:self
          didScrollFromIndex:_beginDragIndexSection.index
                     toIndex:_dragTargetIndexSection.index];
    }
  
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDecelerating:)]) {
        [_delegate pagerViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isScrolling = false;
    if ([_delegate respondsToSelector:@selector(pagerView:didEndScrollToIndex:)]) {
        [_delegate pagerView:self didEndScrollToIndex:_indexSection.index];
    }
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDecelerating:)]) {
        [_delegate pagerViewDidEndDecelerating:self];
    }
    _dragTargetIndexSection.index = -1;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    scrollView.userInteractionEnabled = YES;
    self.isScrolling = false;
    if ([_delegate respondsToSelector:@selector(pagerView:didEndScrollToIndex:)]) {
        [_delegate pagerView:self didEndScrollToIndex:_indexSection.index];
    }
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndScrollingAnimation:)]) {
        [_delegate pagerViewDidEndScrollingAnimation:self];
    }
    CGFloat offset = [self calculateOffsetAtIndexSection:_indexSection];
    CGFloat direction = 0.0;
    if (self.layout.vertical) {
        direction = scrollView.contentOffset.y;
    } else {
        direction = scrollView.contentOffset.x;
    }
  
    if (fabs(roundf(offset) - roundf(scrollView.contentOffset.x)) > 1) {
        return;
    }
  
  if (self.bindChangeType == BDXLynxSwiperBindChangeAfterDrag &&_delegateFlags.didScrollFromIndexToNewIndex && !BDXLynxSwiperEqualIndexSection(_indexSection, _prevIndexSection)) {
      [_delegate pagerView:self
        didScrollFromIndex:_prevIndexSection.index
                   toIndex:_indexSection.index];
  }
  _dragTargetIndexSection.index = -1;
}

#pragma mark - BDXLynxSwiperTransformLayoutDelegate

- (void)pagerViewTransformLayout:(BDXLynxSwiperTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate pagerView:self initializeTransformAttributes:attributes];
    }
}

- (void)pagerViewTransformLayout:(BDXLynxSwiperTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.applyTransformToAttributes) {
        [_delegate pagerView:self applyTransformToAttributes:attributes];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL needUpdateLayout = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds;
    if ((_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData)) {
        _didLayout = YES;
        [self setNeedUpdateLayout];
    }
  if (self.keepItemView) {
    __weak __typeof(self) weakSelf = self;
    // need to do the checks after UICollectionView being reloaded, so dispatch to next runloop
    dispatch_async(dispatch_get_main_queue(), ^{
      for (NSUInteger i=0; i<[weakSelf.dataSource numberOfItemsInPagerView:weakSelf]; i++) {
        UIView *itemView = [weakSelf.dataSource pagerView:weakSelf viewForItemAtIndex:i];
        // attach view to window, to make global exposure work
        if (!itemView.window) {
          [weakSelf.collectionView addSubview:itemView];
          UICollectionViewLayoutAttributes *attr = [weakSelf.collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
          itemView.frame = attr.frame;
        }
      }
    });
  }
}

- (void)dealloc {
    ((BDXLynxSwiperTransformLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

@end


