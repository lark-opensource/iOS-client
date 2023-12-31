//
//  BDXCategoryIndicatorImageView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorImageView.h"
#import "BDXCategoryFactory.h"

@implementation BDXCategoryIndicatorImageView

#pragma mark - Initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupIndicatorImageView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupIndicatorImageView];
    }
    return self;
}

- (void)setupIndicatorImageView {
    _indicatorImageViewSize = CGSizeMake(30, 20);
    _indicatorImageViewRollEnabled = NO;

    _indicatorImageView = [[UIImageView alloc] init];
    self.indicatorImageView.frame = CGRectMake(0, 0, self.indicatorImageViewSize.width, self.indicatorImageViewSize.height);
    self.indicatorImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.indicatorImageView];
}

#pragma mark - Custom Accessors

- (void)setIndicatorImageViewSize:(CGSize)indicatorImageViewSize {
    _indicatorImageViewSize = indicatorImageViewSize;

    self.indicatorImageView.frame = CGRectMake(0, 0, self.indicatorImageViewSize.width, self.indicatorImageViewSize.height);
}

#pragma mark - BDXCategoryIndicatorProtocol

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - self.indicatorImageViewSize.width)/2;
    CGFloat y = self.superview.bounds.size.height - self.indicatorImageViewSize.height - self.verticalMargin;
    if (self.componentPosition == BDXCategoryComponentPosition_Top) {
        y = self.verticalMargin;
    }
    self.frame = CGRectMake(x, y, self.indicatorImageViewSize.width, self.indicatorImageViewSize.height);
}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {
    CGRect rightCellFrame = model.rightCellFrame;
    CGRect leftCellFrame = model.leftCellFrame;
    CGFloat percent = model.percent;
    CGFloat targetWidth = self.indicatorImageViewSize.width;
    CGFloat targetX = 0;

    if (percent == 0) {
        targetX = leftCellFrame.origin.x + (leftCellFrame.size.width - targetWidth)/2.0;
    }else {
        CGFloat leftX = leftCellFrame.origin.x + (leftCellFrame.size.width - targetWidth)/2;
        CGFloat rightX = rightCellFrame.origin.x + (rightCellFrame.size.width - targetWidth)/2;
        targetX = [BDXCategoryFactory interpolationFrom:leftX to:rightX percent:percent];
    }

    if (self.isScrollEnabled == YES || (self.isScrollEnabled == NO && percent == 0)) {
        CGRect frame = self.frame;
        frame.origin.x = targetX;
        self.frame = frame;
        
        if (self.indicatorImageViewRollEnabled) {
            self.indicatorImageView.transform = CGAffineTransformMakeRotation(M_PI*2*percent);
        }
    }
}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    CGRect toFrame = self.frame;
    toFrame.origin.x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - self.indicatorImageViewSize.width)/2;
    if (self.isScrollEnabled) {
        [UIView animateWithDuration:self.scrollAnimationDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.frame = toFrame;
        } completion:^(BOOL finished) {
        }];
        if (self.indicatorImageViewRollEnabled && (model.selectedType == BDXCategoryCellSelectedTypeCode || model.selectedType == BDXCategoryCellSelectedTypeClick)) {
            [self.indicatorImageView.layer removeAnimationForKey:@"rotate"];
            CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            if (model.selectedIndex > model.lastSelectedIndex) {
                rotateAnimation.fromValue = @(0);
                rotateAnimation.toValue = @(M_PI*2);
            }else {
                rotateAnimation.fromValue = @(M_PI*2);
                rotateAnimation.toValue = @(0);
            }
            rotateAnimation.fillMode = kCAFillModeBackwards;
            rotateAnimation.removedOnCompletion = YES;
            rotateAnimation.duration = 0.25;
            [self.indicatorImageView.layer addAnimation:rotateAnimation forKey:@"rotate"];
        }
    }else {
        self.frame = toFrame;
    }
}


@end
