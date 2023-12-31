//
//  BDXLynxSwiperView.m
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxViewCurrentIndexHelper.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUICollection.h>
#import <Lynx/LynxGlobalObserver.h>
#import "LynxUI+BDXLynx.h"
#import <objc/runtime.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXLynxSwiperView.h"
#import "BDXLynxSwiperPageView.h"
#import "BDXLynxSwiperSlideControl.h"
#import "BDXLynxSwpierCell.h"
#import "BDXLynxSwiperCollectionView.h"

@protocol BDXLynxSwiperDelegate <NSObject>

@optional
- (BOOL)isDirectionRTL;
- (void)didChange:(NSDictionary *)info;
- (void)didTransition:(NSDictionary *)info;
- (void)didScrollStart:(NSDictionary *)info;
- (void)didScrollEnd:(NSDictionary *)info;

@end

NSString *const BDXSwiperItemID = @"BDXLynxSwiperCell";

@interface BDXLynxSwiperView () <BDXLynxSwiperPageViewDataSource, BDXLynxSwiperPageViewDelegate>

@property (nonatomic, strong) BDXLynxSwiperSlideControl *pageControl;
@property (nonatomic, weak) id<BDXLynxSwiperDelegate> delegate;

@property (nonatomic, strong) UILabel *pagingLabel;
@property (nonatomic, assign) BOOL compatible;
@property (nonatomic, assign) BOOL enableBounces;


@end

@implementation BDXLynxSwiperView

- (instancetype)init
{
    if (self = [super init]) {
        [self setBackgroundColor:[UIColor clearColor]];
        self.isHorizonCenter = YES;
        self.vertical = NO;
        self.isAutoPlay = NO;
        self.isInfiniteLoop = YES;
        self.itemWidthScale = 1.0;
        self.itemHeightScale = 1.0;
        self.itemWidthScale = 1.0;
        self.autoScrollInterval = 1.0;
        self.smoothScroll = YES;
        self.nextMargin = 0.0;
        self.previousMargin = 0.0;
        self.itemSpacing = 0.0;
        self.maxXScale = 1.0;
        self.minXScale = 0.8;
        self.maxYScale = 1.0;
        self.minYScale = 0.8;
        self.normTranslationFactor = 0.0;
        self.compatible = YES;
        self.currentIndex = -1;
    }
    return self;
}

- (void)setupControl {
    
    [self addPagerView];
    [self addPageControl];
    [self.pagerView addSubview:self.pagingLabel];
}

- (void)updateControl
{
    [self setupFrame];
}

- (void)setDatas:(NSArray *)datas
{
    _datas = datas;
    [self loadData];
    [self updateControl];
    [self.pagerView setNeedUpdateLayout];
}

- (void)updateStyle
{
    [self checkCompatible];
    [self switchLayoutFrameWithType:self.layoutType];
    [self sliderValueChangeWithType:self.layoutType];
    [self changeStyleWithType:self.layoutType];
    [self loadData];
}

- (void)checkCompatible {
  if (self.compatible) {
    self.previousMargin = self.itemSpacing + self.previousMarginCompatible;
    self.nextMargin = self.itemSpacing + self.nextMarginCompatible;
  }
}

- (void)setLayoutType:(BDXLynxSwiperTransformLayoutType)layoutType
{
    _layoutType = layoutType;
    [self updateStyle];
}

- (void)addPagerView {
    
    [self addSubview:self.pagerView];
}

- (void)addPageControl {
    [self.pagerView addSubview:self.pageControl];
}

- (void)setupFrame {
    self.pagerView.frame = self.bounds;
    self.pageControl.frame = CGRectMake(0, CGRectGetHeight(self.pagerView.frame) - 20, CGRectGetWidth(self.pagerView.frame), 15);
    self.pagingLabel.frame = CGRectMake(10, CGRectGetHeight(self.pagerView.frame) - 25, 20, 13);
}

- (void)loadData {
    _pageControl.numberOfPages = _datas.count;
    [_pagerView reloadData:_datas];
}

#pragma mark - BDXLynxSwiperPageViewDataSource

- (NSInteger)numberOfItemsInPagerView:(BDXLynxSwiperPageView *)pageView
{
    return _datas.count;
}

- (UICollectionViewCell *)pagerView:(BDXLynxSwiperPageView *)pagerView cellForItemAtIndex:(NSInteger)index
{
    BDXLynxSwpierCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:BDXSwiperItemID forIndex:index];

    LynxUI *ui = self.datas[index];
    for (UIView *view in [[cell contentView] subviews]) {
        if (view != ui.view) {
            [view removeFromSuperview];
        }
    }
    cell.ui = ui;
    ui.view.frame = cell.bounds;
    if (ui.view.superview != cell.contentView) {
        [ui.view removeFromSuperview];
        [cell addContent:ui.view];
    }
    // Call applyEffect to handle complex background and borders. Automatically deal with transform.
    [ui.backgroundManager applyEffect];
    [cell.ui resetAnimation];
    [cell.ui restartAnimation];
    return cell;
}

- (UIView *)pagerView:(BDXLynxSwiperPageView *)pagerView viewForItemAtIndex:(NSInteger)index {
  if (index >= 0 && index < self.datas.count) {
    LynxUI *ui = self.datas[index];
    return ui.view;
  }
  return nil;
}

- (BDXLynxSwiperViewLayout *)layoutForPagerView:(BDXLynxSwiperPageView *)pageView {
    BDXLynxSwiperViewLayout *layout = [[BDXLynxSwiperViewLayout alloc] init];
    layout.layoutType = self.layoutType;
    layout.vertical = self.vertical;
    if (self.layoutType == BDXLynxSwiperTransformLayoutNormal) {
        layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame) , CGRectGetHeight(pageView.frame));
    } else if (self.layoutType == BDXLynxSwiperTransformLayoutLinear) {
        layout.layoutType = BDXLynxSwiperTransformLayoutNormal;
        layout.itemHorizontalCenter = NO;
        layout.itemVerticalCenter = NO;
        if (layout.vertical) {
            layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame), CGRectGetHeight(pageView.frame) * 0.8);
          if (self.itemHeight) {
            layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame), self.itemHeight);
          }
        } else {
            layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame) * 0.8, CGRectGetHeight(pageView.frame));
          if (self.itemWidth) {
            layout.itemSize = CGSizeMake(self.itemWidth, CGRectGetHeight(pageView.frame));
          }
        }
    } else if (self.layoutType == BDXLynxSwiperTransformLayoutCoverflow ||
               self.layoutType == BDXLynxSwiperTransformLayoutFlatCoverflow) {
        CGFloat prev = self.previousMargin;
        CGFloat next = self.nextMargin;
        if (self.previousMargin == 0.0 && self.nextMargin == 0.0 && self.itemSpacing == 0.0) {
            if (layout.vertical) {
                layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame), CGRectGetHeight(pageView.frame) * 0.6);
            } else {
                layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame) * 0.6, CGRectGetHeight(pageView.frame));
            }
        } else {
            if (layout.vertical) {
                layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame), CGRectGetHeight(pageView.frame) - prev - next);
            } else {
                layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame) - prev - next, CGRectGetHeight(pageView.frame));
            }
        }
        
        self.pageControl.frame = CGRectMake(0, CGRectGetHeight(self.pagerView.frame) - 20 - CGRectGetHeight(pageView.frame) * 0.1, CGRectGetWidth(self.pagerView.frame), 15);
        
        if (self.vertical) {
            UIEdgeInsets sectionInset = layout.sectionInset;
            layout.itemVerticalCenter = self.previousMargin == 0.0 && self.nextMargin == 0.0;
            sectionInset.top = self.previousMargin;
            sectionInset.bottom = self.nextMargin;
          if (self.previousMargin == 0.0 && self.nextMargin == 0.0 && self.itemSpacing == 0.0) {
            sectionInset.top = sectionInset.bottom = CGRectGetHeight(pageView.frame) * 0.2;
          }
            layout.sectionInset = sectionInset;
        } else {
            UIEdgeInsets sectionInset = layout.sectionInset;
            layout.itemHorizontalCenter = self.previousMargin == 0.0 && self.nextMargin == 0.0;
            sectionInset.left = self.previousMargin;
            sectionInset.right = self.nextMargin;
          if (self.previousMargin == 0.0 && self.nextMargin == 0.0 && self.itemSpacing == 0.0) {
            sectionInset.left = sectionInset.right = CGRectGetWidth(pageView.frame) * 0.2;
          }
            layout.sectionInset = sectionInset;
          
        }
    } else if (self.layoutType == BDXLynxSwiperTransformLayoutMultiplePages) {
        CGFloat height = self.itemHeight != 0 ? self.itemHeight : self.pagerView.bounds.size.height;
        layout.itemSize = CGSizeMake(self.itemWidth, height);
        layout.startMargin = self.startMargin;
        layout.endMargin = self.endMargin;
        layout.itemVerticalCenter = YES;
    } else if (self.layoutType == BDXLynxSwiperTransformLayoutCarry) {
        CGFloat prev = self.previousMargin;
        CGFloat next = self.nextMargin;
        layout.layoutType = BDXLynxSwiperTransformLayoutCarry;
        if (layout.vertical) {
            layout.itemVerticalCenter = YES;
            layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame), CGRectGetHeight(pageView.frame) - prev - next);
        } else {
            layout.itemHorizontalCenter = YES;
            layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame) - prev - next, CGRectGetHeight(pageView.frame));
        }
      
      if (self.vertical) {
          UIEdgeInsets sectionInset = layout.sectionInset;
          layout.itemVerticalCenter = self.previousMargin == 0.0 && self.nextMargin == 0.0;
          sectionInset.top = self.previousMargin;
          sectionInset.bottom = self.nextMargin;
          layout.sectionInset = sectionInset;
      } else {
          UIEdgeInsets sectionInset = layout.sectionInset;
          layout.itemHorizontalCenter = self.previousMargin == 0.0 && self.nextMargin == 0.0;
          sectionInset.left = self.previousMargin;
          sectionInset.right = self.nextMargin;
          layout.sectionInset = sectionInset;
      }
        
        layout.maxXScale = self.maxXScale;
        layout.minXScale = self.minXScale;
        layout.maxYScale = self.maxYScale;
        layout.minYScale = self.minYScale;
        layout.normTranslationFactor = self.normTranslationFactor;
    }
    layout.itemSpacing = self.itemSpacing;
    if ([self.delegate respondsToSelector:@selector(isDirectionRTL)]) {
        BOOL isRTL = [self.delegate isDirectionRTL];
        layout.isRTL = isRTL;
        _pageControl.isRTL = isRTL;
    }
    return layout;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView fromIndex:(NSInteger)fromIndex
{
    if ([self.delegate respondsToSelector:@selector(didTransition:)]) {
        CGFloat offset = fmod(scrollView.contentOffset.x, scrollView.bounds.size.width);
        CGFloat signedOffset = offset < 0 ? offset + scrollView.bounds.size.width : offset;
        CGFloat percent = signedOffset / scrollView.bounds.size.width;
        NSDictionary *detail = @{
          @"current" : @(fromIndex),
          @"dx" : @(scrollView.contentOffset.x) ?: @(0),
          @"dy" : @(scrollView.contentOffset.y) ?: @(0),
          @"positionOffset": @(percent),
          @"isDragged" : @(scrollView.tracking ? YES : NO),
        };
        [self.delegate didTransition:detail];
    }
}

- (void)notifyScrollViewDidScroll {
    // Notify x-swiper did scroll.
    [((BDXLynxUISwiper *)_delegate).context.observer notifyScroll:nil];
}

- (void)pagerView:(BDXLynxSwiperPageView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSInteger externalToIndex = toIndex % (NSInteger)_datas.count;
    if (externalToIndex < 0) {
        externalToIndex = externalToIndex + _datas.count;
    }
    _pageControl.currentPage = externalToIndex;
    self.pagingLabel.text = [NSString stringWithFormat:@"%ld/%lu", (long)(externalToIndex + 1), (unsigned long)_datas.count];
    if ([self.delegate respondsToSelector:@selector(didChange:)]) {
        NSDictionary *detail = @{@"current" : @(externalToIndex), @"source" : @""};
        [self.delegate didChange:detail];
    }
}

- (void)pagerView:(BDXLynxSwiperPageView *)pageView didStartScrollFromIndex:(NSInteger)fromIndex
{
    if ([self.delegate respondsToSelector:@selector(didScrollStart:)]) {
        [self.delegate didScrollStart:@{
          @"current": @(fromIndex),
          @"dx" : @(pageView.contentOffset.x) ?: @(0),
          @"dy" : @(pageView.contentOffset.y) ?: @(0),
          @"isDragged" : @(pageView.tracking ? YES : NO)
        }];
    }
}

- (void)pagerView:(BDXLynxSwiperPageView *)pageView didEndScrollToIndex:(NSInteger)toIndex
{
    if ([self.delegate respondsToSelector:@selector(didScrollEnd:)]) {
        [self.delegate didScrollEnd:@{@"current": @(toIndex)}];
    }
}

#pragma mark - action

- (void)switchLayoutFrameWithType:(BDXLynxSwiperTransformLayoutType)type
{
    _pagerView.layoutType = type;
    _pagerView.layout.vertical = self.vertical;
    if (type == BDXLynxSwiperTransformLayoutNormal) {
        self.pagerView.isInfiniteLoop = self.isInfiniteLoop;
        self.pagerView.autoScrollInterval = self.isAutoPlay ? (self.autoScrollInterval ?: 0) : 0;
        self.pagerView.layout.itemVerticalCenter = NO;
        [self.pagerView updateData];
    } else if (type == BDXLynxSwiperTransformLayoutLinear) {
        self.pagerView.autoScrollInterval = self.isAutoPlay ? (self.autoScrollInterval ?: 0) : 0;
        self.pagerView.layout.itemVerticalCenter = NO;
        self.pagerView.layout.itemHorizontalCenter = NO;
    } else if (type == BDXLynxSwiperTransformLayoutFlatCoverflow) {
        self.pagerView.autoScrollInterval = self.isAutoPlay ? (self.autoScrollInterval ?: 0) : 0;
        self.pagerView.layout.itemVerticalCenter = NO;
        self.pagerView.layout.itemHorizontalCenter = YES;
    } else if (type == BDXLynxSwiperTransformLayoutCoverflow) {
        self.pagerView.layout.itemHorizontalCenter = YES;
//        self.pagerView.layout.itemVerticalCenter = NO;
        [UIView animateWithDuration:0.3 animations:^{
            [self.pagerView setNeedUpdateLayout];
        }];
    } else if (type == BDXLynxSwiperTransformLayoutMultiplePages) {
        self.pagerView.layout.itemVerticalCenter = YES;
        self.pagerView.layout.itemHorizontalCenter = NO;
    } else if (type == BDXLynxSwiperTransformLayoutCarry) {
        self.pagerView.isInfiniteLoop = self.isInfiniteLoop;
        self.pagerView.autoScrollInterval = self.isAutoPlay ? (self.autoScrollInterval ?: 0) : 0;
        self.pagerView.layout.itemHorizontalCenter = YES;
        self.pagerView.layout.itemVerticalCenter = NO;
    }
}

- (void)sliderValueChangeWithType:(BDXLynxSwiperTransformLayoutType)type
{
    if (type == BDXLynxSwiperTransformLayoutNormal) {
        [_pagerView setNeedUpdateLayout];
    } else if (type == BDXLynxSwiperTransformLayoutLinear || type == BDXLynxSwiperTransformLayoutFlatCoverflow) {
        _pagerView.layout.itemSpacing = self.itemSpacing ?: 0;
        [_pagerView setNeedUpdateLayout];
    } else if (type == BDXLynxSwiperTransformLayoutCoverflow || type == BDXLynxSwiperTransformLayoutFlatCoverflow) {
        [_pagerView setNeedUpdateLayout];
    } else if (type == BDXLynxSwiperTransformLayoutCarry) {
        [_pagerView setNeedUpdateLayout];
    }
}

- (void)changeStyleWithType:(BDXLynxSwiperTransformLayoutType)type
{
    _pagerView.layoutType = type;
    [_pagerView setNeedUpdateLayout];
}

- (BDXLynxSwiperPageView *)pagerView
{
    if (!_pagerView) {
        BDXLynxSwiperPageView *pagerView = [[BDXLynxSwiperPageView alloc] initWithFrame:self.bounds];
        pagerView.isInfiniteLoop = YES;
        pagerView.autoScrollInterval = 2.0;
        pagerView.dataSource = self;
        pagerView.delegate = self;
        
        [pagerView registerClass:[BDXLynxSwpierCell class] forCellWithReuseIdentifier:BDXSwiperItemID];
        _pagerView = pagerView;
    }
    _pagerView.frame = self.bounds;
    return _pagerView;
}

- (BDXLynxSwiperSlideControl *)pageControl
{
    if (!_pageControl) {
        BDXLynxSwiperSlideControl *pageControl = [[BDXLynxSwiperSlideControl alloc] init];
        pageControl.currentPageIndicatorSize = CGSizeMake(5, 5);
        pageControl.pageIndicatorSize = CGSizeMake(5, 5);
        pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        pageControl.pageIndicatorTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _pageControl = pageControl;
    }
    return _pageControl;
}

- (UILabel *)pagingLabel
{
    if (!_pagingLabel) {
        _pagingLabel = [[UILabel alloc] init];
        _pagingLabel.text = @"1/1";
        _pagingLabel.font = [UIFont systemFontOfSize:10];
        _pagingLabel.textAlignment = NSTextAlignmentCenter;
        _pagingLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _pagingLabel.textColor = [UIColor whiteColor];
        _pagingLabel.hidden = YES;
    }
    return _pagingLabel;
}

// setter
- (void)setShowDots:(BOOL)showDots
{
    self.pageControl.hidden = !showDots;
}

- (void)setHidelabel:(BOOL)hidelabel
{
    self.pagingLabel.hidden = hidelabel;
}

- (void)setDotsColor:(NSString *)dotsColor
{
    self.pageControl.pageIndicatorTintColor = [self parseColor:dotsColor];
}

- (void)setActiveDotsColor:(NSString *)activeDotsColor
{
    self.pageControl.currentPageIndicatorTintColor = [self parseColor:activeDotsColor];
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    [self.pagerView scrollToItemAtIndex:currentIndex animate:self.smoothScroll];
}

- (void)setCurrentIndexWithoutAnimation:(NSInteger)currentIndex
{
    [self.pagerView scrollToItemAtIndex:currentIndex animate:NO];
  self.pageControl.currentPage = currentIndex;
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval
{
    _autoScrollInterval = autoScrollInterval;
    self.pagerView.autoScrollInterval = self.isAutoPlay ? (autoScrollInterval ?: 0) : 0;
}

- (void)setIsCircle:(BOOL)isCircle
{
    self.isInfiniteLoop = isCircle;
    self.pagerView.isInfiniteLoop = isCircle;
}

- (void)setAnimationDuration:(CGFloat)animationDuration
{
  ((BDXLynxSwiperCollectionView *)(self.pagerView.collectionView)).customDuration = animationDuration;
}

- (void)setIsTouchable:(BOOL)isTouchable
{
    self.pagerView.collectionView.scrollEnabled = isTouchable;
  ((BDXLynxSwiperCollectionView *)(self.pagerView.collectionView)).scrollEnableFromLynx = isTouchable;
}

- (void)setSmoothScroll:(BOOL)smoothScroll
{
    _smoothScroll = smoothScroll;
    self.pagerView.smoothScroll = smoothScroll;
}

- (void)setBounces:(BOOL)bounces {
  _bounces = bounces;
  self.pagerView.collectionView.bounces = bounces;
  if (bounces) {
    self.pagerView.collectionView.alwaysBounceHorizontal = !self.vertical;
    self.pagerView.collectionView.alwaysBounceVertical = self.vertical;
  } else {
    self.pagerView.collectionView.alwaysBounceHorizontal = NO;
    self.pagerView.collectionView.alwaysBounceVertical = NO;
  }
}

- (void)setIsAutoPlay:(BOOL)isAutoPlay
{
    _isAutoPlay = isAutoPlay;
    if (!_isAutoPlay) {
        self.pagerView.autoScrollInterval = 0;
    } else {
        self.pagerView.autoScrollInterval = _autoScrollInterval;
    }
}

- (UIColor *)parseColor:(NSString *)colorStr {
  colorStr = [colorStr stringByReplacingOccurrencesOfString:@" " withString:@""];
  if ([colorStr hasPrefix:@"0x"]) {
    return [UIColor btd_colorWithHexString:colorStr];
  } else if ([colorStr hasPrefix:@"rgb"]) {
    NSUInteger begin = [colorStr rangeOfString:@"("].location;
    NSUInteger end = [colorStr rangeOfString:@")"].location;
    if (begin != NSNotFound && end != NSNotFound && end > begin) {
      begin = begin + 1;
      end = end - 1;
      colorStr = [colorStr substringWithRange:NSMakeRange(begin, end - begin + 1)];
      NSArray<NSString *> *rgba = [colorStr componentsSeparatedByString:@","];
      
      if (rgba.count == 3) {
        return [UIColor colorWithRed:[rgba[0] floatValue] / 255.0f green:[rgba[1] floatValue] / 255.0f blue:[rgba[2] floatValue] / 255.0f alpha:1.0f];
      } else if (rgba.count == 4) {
        return [UIColor colorWithRed:[rgba[0] floatValue] / 255.0f green:[rgba[1] floatValue] / 255.0f blue:[rgba[2] floatValue] / 255.0f alpha:[rgba[3] floatValue]];
      } else {
        return nil;
      }
    }
    
  }
  return nil;
}



@end

@interface BDXLynxUISwiper () <BDXLynxSwiperDelegate, LynxViewCurrentIndexHelper>

@property(nonatomic, strong, nonnull) NSMutableArray<LynxUI *> *swiperItems;
@property (nonatomic, assign) BOOL hasDataChanged;
@property (nonatomic, assign) BOOL hasFrameChanged;
@property (nonatomic, assign) BOOL hasLayoutChanged;
@property (nonatomic, assign) BOOL needReLayout;
@property (nonatomic, assign) BOOL needResetCurIndex;
@property (nonatomic, assign) BOOL disappeared;
@property (nonatomic, assign) BOOL enableBounces;
@property (nonatomic, assign) CGFloat bouncesBeginThreshold;
@property (nonatomic, assign) CGFloat bouncesEndThreshold;
@property (nonatomic, assign) CGFloat preContentOffsetX;
@property (nonatomic, assign) NSTimeInterval lastTransitionTime;
@property (nonatomic, assign) NSTimeInterval transitionThrottle;
@end

@implementation BDXLynxUISwiper

- (instancetype)init {
    self = [super init];
    if (self) {
        _swiperItems = [[NSMutableArray alloc] init];
        _smoothScroll = YES;
      _needReLayout = YES;
      _needResetCurIndex = YES;
      _bouncesBeginThreshold = -1;
      _bouncesEndThreshold = -1;
    }
    return self;
}

- (UIView *)createView {
    BDXLynxSwiperView *view = [[BDXLynxSwiperView alloc] init];
//    view.isInfiniteLoop = NO;
    view.delegate = self;
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    [view setupControl];
//    view.itemSpacing = 0;
    return view;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    [_swiperItems insertObject:(LynxUI *)child atIndex:index];
    _hasDataChanged = YES;
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    [_swiperItems removeObjectAtIndex:index];
    [[self view] setDatas:_swiperItems];
    _hasDataChanged = YES;
}

- (BOOL)hasCustomLayout {
    return YES;
}

- (BOOL)isScrollContainer {
    return YES;
}

- (void)frameDidChange {
    [super frameDidChange];
    _hasFrameChanged = YES;
    self.view.pagerView.frame = self.view.bounds;
}

- (void)propsDidUpdate {
  [super propsDidUpdate];
  if (self.hasLayoutChanged) {
    self.view.layoutType = self.layoutType;
    self.hasLayoutChanged = NO;
  }
  
  if (self.needReLayout) {
    self.needReLayout = NO;
    [self.view updateStyle];
    self.view.isCircle = _isCircle;
  }
  
  if (self.needResetCurIndex) {
    self.needResetCurIndex = NO;
    if (self.currentIndexId != nil) {
      [self.children enumerateObjectsUsingBlock:^(LynxUI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:self.currentIndexId]) {
          *stop = YES;
          self.currentIndex = idx;
        }
      }];
    }
    if (self.currentIndex >= 0 && self.currentIndex < self.view.datas.count) {
        [self.view setCurrentIndex:self.currentIndex];
    }
  }
  
}

- (void)layoutDidFinished
{
    if (self.hasLayoutChanged) {
        self.view.layoutType = self.layoutType;
        self.hasLayoutChanged = NO;
    }
    if (_hasFrameChanged || _hasDataChanged) {
      NSMutableArray *data = [_swiperItems mutableCopy];
      LynxUI *bouncesBegin;
      LynxUI *bouncesEnd;
      if (_enableBounces) {
        bouncesBegin = data.firstObject;
        bouncesEnd = data.lastObject;
        [data removeObjectAtIndex:0];
        [data removeLastObject];
      } else {
        
      }
        [[self view] setDatas:data];
      [(BDXLynxSwiperCollectionView *)([self view].pagerView.collectionView) addBouncesView:bouncesBegin.view and:bouncesEnd.view];
        _hasFrameChanged = NO;
        _hasDataChanged = NO;
      // reset index without anim, because hasDataChanged will be set after propsDidUpdate
      
      if (self.currentIndexId != nil) {
        [self.children enumerateObjectsUsingBlock:^(LynxUI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          if ([obj.name isEqualToString:self.currentIndexId]) {
            *stop = YES;
            self.currentIndex = idx;
          }
        }];
      }
      
        if (self.currentIndex != [self.view currentIndex]
            && self.currentIndex >= 0
            && self.currentIndex < self.view.datas.count) {
            [self.view setCurrentIndexWithoutAnimation:self.currentIndex];
        }
    }
}

-(int)getCurrentIndex {
  return (int)[self.view.pagerView curIndex];
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("swiper")
#else
LYNX_REGISTER_UI("swiper")
#endif

LYNX_PROP_SETTER("ios-bind-change-type", bindChangeType, NSUInteger)
{
  self.view.pagerView.bindChangeType = value;
}


LYNX_PROP_SETTER("indicator-dots", showDots, BOOL)
{
    _showDots = value;
    self.view.showDots = value;
}

LYNX_PROP_SETTER("indicator-color", dotsColor, NSString *)
{
    _dotsColor = value;
    self.view.dotsColor = value;
}

LYNX_PROP_SETTER("indicator-active-color", activeDotsColor, NSString *)
{
    _activeDotsColor = value;
    self.view.activeDotsColor = value;
}

LYNX_PROP_SETTER("mode", swiperMode, NSString *)
{
    if ([value isEqualToString:@"normal"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutNormal) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutNormal;
        self.view.layoutType = BDXLynxSwiperTransformLayoutNormal;
    } else if ([value isEqualToString:@"carousel"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutLinear) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutLinear;
        self.view.layoutType = BDXLynxSwiperTransformLayoutLinear;
        // 暂时使用 20rpx 作为 itemspacing 对于 carousel 模式，后续可以考虑提供动态的 item-spacing，需要和 Android 对齐
//        self.view.itemSpacing = [LynxUnitUtils toPtFromUnitValue:@"20rpx" withDefaultPt:0];
    } else if ([value isEqualToString:@"coverflow"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutCoverflow) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutCoverflow;
        self.view.layoutType = BDXLynxSwiperTransformLayoutCoverflow;
        // 暂时使用 40rpx 作为 itemspacing 对于 coverflow 模式，后续可以考虑提供动态的 item-spacing，需要和 Android 对齐
//        self.view.itemSpacing = [LynxUnitUtils toPtFromUnitValue:@"40rpx" withDefaultPt:0];
    } else if ([value isEqualToString:@"flat-coverflow"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutFlatCoverflow) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutFlatCoverflow;
        self.view.layoutType = BDXLynxSwiperTransformLayoutFlatCoverflow;
    } else if ([value isEqualToString:@"multi-pages"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutMultiplePages) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutMultiplePages;
        self.view.layoutType = BDXLynxSwiperTransformLayoutMultiplePages;
    } else if ([value isEqualToString:@"carry"]) {
        if (self.layoutType != BDXLynxSwiperTransformLayoutCarry) {
            _hasLayoutChanged = YES;
          self.needResetCurIndex = YES;
        }
        self.layoutType = BDXLynxSwiperTransformLayoutCarry;
        self.view.layoutType = BDXLynxSwiperTransformLayoutCarry;
    }
}

/**
 * @name: should-ignore-reverse-in-rtl
 * @description: When system language is Arabic but APP language is English, the rtl mode should not open
 * @note: only ios
 * @category: temporary
 * @standardAction: offline
 * @supportVersion: 2.7
**/
LYNX_PROP_SETTER("should-ignore-reverse-in-rtl", setShouldIgnoreReverseInRTL, BOOL){
    [self.view.pagerView switchToNonFlipLayout];
}

LYNX_PROP_SETTER("item-width", itemWidth, NSString *)
{
  _itemWidth = [self toPtWithUnitValue:value fontSize:0];
    self.view.itemWidth = _itemWidth;
    self.needReLayout = YES;
    self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("item-height", itemHeight, NSString *)
{
  _itemHeight = [self toPtWithUnitValue:value fontSize:0];
    self.view.itemHeight = _itemHeight;
    self.needReLayout = YES;
    self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("start-margin", startMargin, NSString *)
{
  _startMargin = [self toPtWithUnitValue:value fontSize:0];
    self.view.startMargin = _startMargin;
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("end-margin", endMargin, NSString *)
{
  _endMargin = [self toPtWithUnitValue:value fontSize:0];
    self.view.endMargin = _endMargin;
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("autoplay", isAutoPlay, BOOL)
{
    _isAutoPlay = value;
    self.view.isAutoPlay = value;
}

LYNX_PROP_SETTER("hidelabel", hidelabel, BOOL)
{
    _hidelabel = value;
    self.view.hidelabel = value;
}

LYNX_PROP_SETTER("current", currentIndex, NSInteger)
{
    // 支持超出index范围的赋值
    if (value < 0 && self.view.datas.count) {
        value = value - floor((double)value / self.view.datas.count) * self.view.datas.count;
    } else if (self.view.datas.count) {
        value = value % self.view.datas.count;
    }
    _currentIndex = value;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("current-item-id", currentIndexId, NSString *)
{
  _currentIndexId = value;
  self.view.currentIndexId = value;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("interval", autoScrollInterval, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        _autoScrollInterval = [value doubleValue] / 1000;
        self.view.autoScrollInterval = _autoScrollInterval;
    }
}

LYNX_PROP_SETTER("display-multiple-items", maxMultiItems, NSNumber *)
{
    if ([value integerValue] >= 0) {
        _maxMultiItems = [value integerValue];
        self.view.maxMultiItems = [value doubleValue];
    }
}

LYNX_PROP_SETTER("duration", animationDuration, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        _animationDuration = [value doubleValue];
        self.view.animationDuration = [value doubleValue];
    }
}

LYNX_PROP_SETTER("circular", isCircle, BOOL)
{
  if (_isCircle != value) {
    self.needReLayout = YES;
  }
    _isCircle = value;
}

LYNX_PROP_SETTER("touchable", isTouchable, BOOL)
{
    _isTouchable = value;
    self.view.isTouchable = value;
}


LYNX_PROP_SETTER("page-margin", pageMargin, NSString *)
{
  _itemSpacing = (NSInteger)[self toPtWithUnitValue:value fontSize:0];
    if (_itemSpacing < 0 || _itemSpacing > [UIScreen mainScreen].bounds.size.width) {
        _itemSpacing = 0;
    }
    self.view.itemSpacing = _itemSpacing;
    [self.view updateStyle];
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("previous-margin", previousMargin, NSString *)
{
  _previousMargin = (NSInteger)[self toPtWithUnitValue:value fontSize:0];
    if (_previousMargin < 0 || _previousMargin > [UIScreen mainScreen].bounds.size.width) {
        _previousMargin = 0;
    }
  
    self.view.previousMargin = _previousMargin;
  self.view.previousMarginCompatible = _previousMargin;
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("next-margin", nextMargin, NSString *)
{
  _nextMargin = (NSInteger)[self toPtWithUnitValue:value fontSize:0];
    if (_nextMargin < 0 || _nextMargin > [UIScreen mainScreen].bounds.size.width) {
        _nextMargin = 0;
    }
    self.view.nextMargin = _nextMargin;
  self.view.nextMarginCompatible = _nextMargin;
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("smooth-scroll", smoothScroll, BOOL)
{
    _smoothScroll = value;
    self.view.smoothScroll = value;
}

LYNX_PROP_SETTER("bounces", bounces, BOOL)
{
    _bounces = value;
    self.view.bounces = value;
}

LYNX_PROP_SETTER("enable-bounce", enabhleBounces, BOOL)
{
  _enableBounces = value;
  self.needReLayout = YES;
  self.needResetCurIndex = YES;
  self.hasDataChanged = YES;
}

LYNX_PROP_SETTER("bounce-begin-threshold", bouncesBeginThreshold, NSNumber *) {
  _bouncesBeginThreshold = MIN(1, MAX(0, [value floatValue]));
}

LYNX_PROP_SETTER("bounce-end-threshold", bouncesEndThreshold, NSNumber *) {
  _bouncesEndThreshold = MIN(1, MAX(0, [value floatValue]));
}




LYNX_PROP_SETTER("max-x-scale", maxXScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        self.view.maxXScale = [value doubleValue];
      self.needReLayout = YES;
    }
}

LYNX_PROP_SETTER("min-x-scale", minXScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        self.view.minXScale = [value doubleValue];
      self.needReLayout = YES;
    }
}

LYNX_PROP_SETTER("max-y-scale", maxYScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        self.view.maxYScale = [value doubleValue];
      self.needReLayout = YES;
    }
}

LYNX_PROP_SETTER("min-y-scale", minYScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        self.view.minYScale = [value doubleValue];
        self.needReLayout = YES;
    }
}

LYNX_PROP_SETTER("vertical", vertical, BOOL)
{
    self.vertical = value;
    self.view.vertical = value;
    if (self.bounces) {
      self.view.pagerView.collectionView.alwaysBounceHorizontal = !self.vertical;
      self.view.pagerView.collectionView.alwaysBounceVertical = self.vertical;
    } else {
      self.view.pagerView.collectionView.alwaysBounceHorizontal = NO;
      self.view.pagerView.collectionView.alwaysBounceVertical = NO;
    }
    self.needReLayout = YES;
    self.needResetCurIndex = YES;
}

LYNX_PROP_SETTER("norm-translation-factor", normTranslationFactor, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        self.view.normTranslationFactor = [value doubleValue];
        self.needReLayout = YES;
        self.needResetCurIndex = YES;
    }
}


LYNX_PROP_SETTER("ios-compatible", markCompatible, BOOL)
{
  self.view.compatible = value;
}

LYNX_PROP_SETTER("keep-item-view", markKeepItemView, BOOL)
{
  self.view.pagerView.keepItemView = value;
}


LYNX_PROP_SETTER("transition-throttle", transitionThrottle, NSNumber *)
{
  double throttle = [value doubleValue];
  if (throttle > 0) {
    _transitionThrottle = throttle / 1000.0;
  }
}

LYNX_UI_METHOD(scrollTo) {
  NSUInteger index = ((NSNumber*)[params objectForKey:@"index"]).unsignedIntegerValue;
  NSString *direction = [params objectForKey:@"direction"];
  BOOL smooth = [params objectForKey:@"smooth"] ? [[params objectForKey:@"smooth"] boolValue] : YES;
  BOOL force = [[params objectForKey:@"force"] boolValue];
  BDXLynxSwiperScrollDirection direct = self.vertical ? BDPLynxSwiperScrollDirectionBottom : ([self isRtl] ? BDXLynxSwiperScrollDirectionLeft : BDXLynxSwiperScrollDirectionRight);
  if ([direction isEqualToString:@"begin"]){
    direct = self.vertical ? BDPLynxSwiperScrollDirectionTop : ([self isRtl] ? BDXLynxSwiperScrollDirectionRight : BDXLynxSwiperScrollDirectionLeft);
  }
  if (smooth) {
    [self.view.pagerView scrollToItemAnimatedAtIndex:index direction:direct force:force];
  } else {
    [self.view.pagerView scrollToItemAtIndex:index animate:NO  force:force];
  }
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}


- (void)didChange:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didTransition:(NSDictionary *)info {
  NSTimeInterval current = CACurrentMediaTime();
  NSTimeInterval diff = current - self.lastTransitionTime;
  if (diff <= self.transitionThrottle) {
    return;
  }
  self.lastTransitionTime = current;
  
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"transition" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
  
    [self checkBounces];
    
    if (self.context != nil) {
      [self.context onGestureRecognizedByUI:self];
    }
  
}

- (void)checkBounces {
  CGFloat offset = self.view.pagerView.collectionView.contentOffset.x;
  if (self.enableBounces) {
    if (self.bouncesBeginThreshold != -1) {
      CGFloat threshold = -(self.view.pagerView.layout.itemSize.width + self.itemSpacing) * self.bouncesBeginThreshold;
      if (self.preContentOffsetX > threshold && offset <= threshold) {
        [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"scrolltobounce" targetSign:[self sign] detail:@{
          @"isToBegin" : @(YES)
        }]];
      }
    }
    if (self.bouncesEndThreshold != -1) {
      CGFloat threshold  = self.view.pagerView.collectionView.collectionViewLayout.collectionViewContentSize.width - self.view.pagerView.collectionView.frame.size.width + (self.view.pagerView.layout.itemSize.width + self.itemSpacing) * self.bouncesEndThreshold;
      if (self.preContentOffsetX < threshold && offset >= threshold) {
        [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"scrolltobounce" targetSign:[self sign] detail:@{
          @"isToEnd" : @(YES)
        }]];
      }
    }
  }
  self.preContentOffsetX = offset;
}

- (void)didScrollStart:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"scrollstart" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didScrollEnd:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"scrollend" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (BOOL)isDirectionRTL {
    return [self isRtl];
}


- (void)onListCellAppear:(NSString *)itemKey withList:(LynxUICollection *)list {
  [super onListCellAppear:itemKey withList:list];
  self.disappeared = NO;
  if (_isAutoPlay && !self.view.isAutoPlay) {
    self.view.isAutoPlay = YES;
  }
}

- (void)onListCellDisappear:(NSString *)itemKey exist:(BOOL)isExist withList:(LynxUICollection *)list {
  [super onListCellDisappear:itemKey exist:isExist withList:list ];
  self.disappeared = YES;
  if (_isAutoPlay) {
    self.view.isAutoPlay = NO;
  }
  // store swiper index
  if (itemKey) {
    NSString *cacheKey = [NSString stringWithFormat:@"%@_swiper_%@", itemKey, self.idSelector];
    if (isExist) {
      list.listNativeStateCache[cacheKey] = @(self.view.pagerView.curIndex);
    } else {
      [list.listNativeStateCache removeObjectForKey:cacheKey];
    }
  }
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  [super onListCellPrepareForReuse:itemKey withList:list];
  self.disappeared = NO;
  if (_isAutoPlay && !self.view.isAutoPlay) {
    self.view.isAutoPlay = YES;
  }
  // restore swiper index
  if (itemKey) {
    NSString *cacheKey = [NSString stringWithFormat:@"%@_swiper_%@", itemKey, self.idSelector];
    [self.view setCurrentIndexWithoutAnimation:[list.listNativeStateCache[cacheKey] integerValue]];
  }
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("ios-enable-user-interaction-during-fling", setIosEnableUserInteractionDuringFling, BOOL))

/**
 * @name: ios-enable-user-interaction-during-fling
 * @description: Enable user interaction while the swiper is fling
 * @category: temporary
 * @standardAction: offline
 * @supportVersion: 2.10
 * @resolveVersion: 2.11
**/
LYNX_PROP_DEFINE("ios-enable-user-interaction-during-fling", setIosEnableUserInteractionDuringFling, BOOL) {
    ((BDXLynxSwiperCollectionView *)(self.view.pagerView.collectionView)).touchBehavior = value ? LynxScrollViewTouchBehaviorStop : LynxScrollViewTouchBehaviorForbid;
}

@end
