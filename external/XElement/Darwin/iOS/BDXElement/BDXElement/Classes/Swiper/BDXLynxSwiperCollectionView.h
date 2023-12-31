// Copyright 2021 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import <Lynx/UIScrollView+Lynx.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxSwiperCollectionView : UICollectionView

@property (nonatomic, assign) CGFloat customDuration;

@property (nonatomic, assign) BOOL duringCustomScroll;

@property (nonatomic, assign) LynxScrollViewTouchBehavior touchBehavior;

- (void)setContentOffset:(CGPoint)contentOffset
            withDuration:(CGFloat)duration
            interception:(_Nullable UIScrollViewLynxProgressInterception)interception;

- (void)decelerateToContentOffset:(CGPoint)contentOffset
                         duration:(double)duration;
- (void)addBouncesView:(UIView *)beginView and:(UIView *)endView;
@end

NS_ASSUME_NONNULL_END
