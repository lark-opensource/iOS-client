// Copyright 2021 The Lynx Authors. All rights reserved.
#import "BDXLynxSwiperCollectionView.h"

@interface BDXLynxSwiperCollectionView () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView * bounceBeginView;
@property (nonatomic, weak) UIView * bounceEndView;
@end



@implementation BDXLynxSwiperCollectionView


- (void)addBouncesView:(UIView *)beginView and:(UIView *)endView {
  // we need bounce view at both upper and lower, consist with Android 
  if (beginView && endView) {
    self.bounceBeginView = beginView;
    self.bounceEndView = endView;;
    [self addSubview:beginView];
    [self addSubview:endView];
  } else {
    [self.bounceBeginView removeFromSuperview];
    [self.bounceEndView removeFromSuperview];
    self.bounceBeginView = nil;
    self.bounceEndView = nil;
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  // adjust bounce view's frame
  CGSize size = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathWithIndex:0]].size;
  self.bounceBeginView.frame = CGRectMake(-size.width, 0, size.width, size.height);
  self.bounceEndView.frame = CGRectMake(self.collectionViewLayout.collectionViewContentSize.width, 0, size.width, size.height);
}
 
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UILayoutContainerView")]) {
        if ((otherGestureRecognizer.state == UIGestureRecognizerStateBegan || otherGestureRecognizer.state == UIGestureRecognizerStatePossible) && self.contentOffset.x <= 0 && self.bounces == NO) {
            return YES;
        }
    }
    return NO;
}

- (void)setContentOffset:(CGPoint)contentOffset {
  [super setContentOffset:contentOffset];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
  if (self.customDuration != 0 && animated) {
    [self setContentOffset:contentOffset withDuration:self.customDuration interception:^CGPoint(double timeProgress, double distProgress, CGPoint contentOffset) {
      return contentOffset;
    }];
  } else {
    [super setContentOffset:contentOffset animated:animated];
  }
}

- (void)setContentOffset:(CGPoint)contentOffset
            withDuration:(CGFloat)duration
            interception:(_Nullable UIScrollViewLynxProgressInterception)interception {
  self.duringCustomScroll = YES;
  __weak __typeof(self) weakSelf = self;
  [self setContentOffset:contentOffset behavior:self.touchBehavior duration:duration / 1000.0 interval:0 progress:interception complete:^BOOL(BOOL scrollEnabledAtStart) {
    weakSelf.duringCustomScroll = NO;
    [weakSelf.delegate scrollViewDidEndScrollingAnimation:weakSelf];
    return weakSelf.scrollEnableFromLynx;
  }];

}


- (void)decelerateToContentOffset:(CGPoint)contentOffset
                         duration:(double)duration {
  __weak __typeof(self) weakSelf = self;
  self.duringCustomScroll = YES;
  [self scrollToTargetContentOffset:contentOffset behavior:self.touchBehavior duration:duration / 1000.0 interval:0 complete:^BOOL(BOOL scrollEnabledAtStart) {
    weakSelf.duringCustomScroll = NO;
    [weakSelf.delegate scrollViewDidEndScrollingAnimation:weakSelf];
    return weakSelf.scrollEnableFromLynx;
  }];
}

@end
