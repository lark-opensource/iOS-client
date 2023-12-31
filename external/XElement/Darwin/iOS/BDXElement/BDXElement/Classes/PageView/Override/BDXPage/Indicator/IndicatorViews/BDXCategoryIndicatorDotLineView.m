//
//  BDXCategoryIndicatorDotLineView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/22.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorDotLineView.h"
#import "BDXCategoryFactory.h"
#import "BDXCategoryViewAnimator.h"

@interface BDXCategoryIndicatorDotLineView ()
@property (nonatomic, strong) BDXCategoryViewAnimator *animator;
@end

@implementation BDXCategoryIndicatorDotLineView

#pragma mark - Initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureDefaulteValue];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self configureDefaulteValue];
    }
    return self;
}

- (void)configureDefaulteValue {
    self.indicatorWidth = 10;
    self.indicatorHeight = 10;
    _lineWidth = 50;
}

#pragma mark - BDXCategoryIndicatorProtocol

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat dotWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGFloat dotHeight = [self indicatorHeightValue:model.selectedCellFrame];
    self.backgroundColor = self.indicatorColor;
    self.layer.cornerRadius = [self indicatorHeightValue:model.selectedCellFrame]/2;

    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - dotWidth)/2;
    CGFloat y = self.superview.bounds.size.height - dotHeight - self.verticalMargin;
    if (self.componentPosition == BDXCategoryComponentPosition_Top) {
        y = self.verticalMargin;
    }
    self.frame = CGRectMake(x, y, dotWidth, dotHeight);
}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {
    if (self.animator.isExecuting) {
        [self.animator invalid];
        self.animator = nil;
    }
    CGFloat dotWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGRect rightCellFrame = model.rightCellFrame;
    CGRect leftCellFrame = model.leftCellFrame;
    CGFloat percent = model.percent;
    CGFloat targetX = 0;
    CGFloat targetWidth = dotWidth;
    CGFloat leftWidth = dotWidth;
    CGFloat rightWidth = dotWidth;
    CGFloat leftX = leftCellFrame.origin.x + (leftCellFrame.size.width - leftWidth)/2;
    CGFloat rightX = rightCellFrame.origin.x + (rightCellFrame.size.width - rightWidth)/2;
    CGFloat centerX = leftX + (rightX - leftX - self.lineWidth)/2;

    if (percent <= 0.5) {
        targetX = [BDXCategoryFactory interpolationFrom:leftX to:centerX percent:percent*2];
        targetWidth = [BDXCategoryFactory interpolationFrom:dotWidth to:self.lineWidth percent:percent*2];
    }else {
        targetX = [BDXCategoryFactory interpolationFrom:centerX to:rightX percent:(percent - 0.5)*2];
        targetWidth = [BDXCategoryFactory interpolationFrom:self.lineWidth to:dotWidth percent:(percent - 0.5)*2];
    }

    if (self.isScrollEnabled == YES || (self.isScrollEnabled == NO && percent == 0)) {
        CGRect frame = self.frame;
        frame.origin.x = targetX;
        frame.size.width = targetWidth;
        self.frame = frame;
    }
}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat dotWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - dotWidth)/2;
    CGRect targetIndicatorFrame = self.frame;
    targetIndicatorFrame.origin.x = x;
    if (self.isScrollEnabled) {
        if (self.scrollStyle == BDXCategoryIndicatorScrollStyleSameAsUserScroll && (model.selectedType == BDXCategoryCellSelectedTypeClick | model.selectedType == BDXCategoryCellSelectedTypeCode)) {
            if (self.animator.isExecuting) {
                [self.animator invalid];
                self.animator = nil;
            }
            CGFloat leftX = 0;
            CGFloat rightX = 0;
            BOOL isNeedReversePercent = NO;
            if (self.frame.origin.x > model.selectedCellFrame.origin.x) {
                leftX = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - dotWidth)/2;;
                rightX = self.frame.origin.x;
                isNeedReversePercent = YES;
            }else {
                leftX = self.frame.origin.x;
                rightX = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - dotWidth)/2;
            }
            CGFloat centerX = leftX + (rightX - leftX - self.lineWidth)/2;
            __weak typeof(self) weakSelf = self;
            self.animator = [[BDXCategoryViewAnimator alloc] init];
            self.animator.progressCallback = ^(CGFloat percent) {
                if (isNeedReversePercent) {
                    percent = 1 - percent;
                }
                CGFloat targetX = 0;
                CGFloat targetWidth = 0;
                if (percent <= 0.5) {
                    targetX = [BDXCategoryFactory interpolationFrom:leftX to:centerX percent:percent*2];
                    targetWidth = [BDXCategoryFactory interpolationFrom:dotWidth to:self.lineWidth percent:percent*2];
                }else {
                    targetX = [BDXCategoryFactory interpolationFrom:centerX to:rightX percent:(percent - 0.5)*2];
                    targetWidth = [BDXCategoryFactory interpolationFrom:self.lineWidth to:dotWidth percent:(percent - 0.5)*2];
                }
                CGRect toFrame = weakSelf.frame;
                toFrame.origin.x = targetX;
                toFrame.size.width = targetWidth;
                weakSelf.frame = toFrame;
            };
            [self.animator start];
        }else if (self.scrollStyle == BDXCategoryIndicatorScrollStyleSimple) {
            [UIView animateWithDuration:self.scrollAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.frame = targetIndicatorFrame;
            } completion: nil];
        }
    }else {
        self.frame = targetIndicatorFrame;
    }
}

@end
