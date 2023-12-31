//
//  BDXCategoryIndicatorLineView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorLineView.h"
#import "BDXCategoryFactory.h"
#import "BDXCategoryViewDefines.h"
#import "BDXCategoryViewAnimator.h"

@interface BDXCategoryIndicatorLineView ()
@property (nonatomic, strong) BDXCategoryViewAnimator *animator;
@end

@implementation BDXCategoryIndicatorLineView

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
    _lineStyle = BDXCategoryIndicatorLineStyle_Normal;
    _lineScrollOffsetX = 10;
    self.indicatorHeight = 3;
}

#pragma mark - BDXCategoryIndicatorProtocol

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {
    self.backgroundColor = self.indicatorColor;
    self.layer.cornerRadius = [self indicatorCornerRadiusValue:model.selectedCellFrame];

    CGFloat selectedLineWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - selectedLineWidth)/2;
    CGFloat y = self.superview.bounds.size.height - [self indicatorHeightValue:model.selectedCellFrame] - self.verticalMargin;
    if (self.componentPosition == BDXCategoryComponentPosition_Top) {
        y = self.verticalMargin;
    }
    self.frame = CGRectMake(x, y, selectedLineWidth, [self indicatorHeightValue:model.selectedCellFrame]);
}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {
    if (self.animator.isExecuting) {
        [self.animator invalid];
        self.animator = nil;
    }
    CGRect rightCellFrame = model.rightCellFrame;
    CGRect leftCellFrame = model.leftCellFrame;
    CGFloat percent = model.percent;
    CGFloat targetX = leftCellFrame.origin.x;
    CGFloat targetWidth = [self indicatorWidthValue:leftCellFrame];

    CGFloat leftWidth = targetWidth;
    CGFloat rightWidth = [self indicatorWidthValue:rightCellFrame];
    CGFloat leftX = leftCellFrame.origin.x + (leftCellFrame.size.width - leftWidth)/2;
    CGFloat rightX = rightCellFrame.origin.x + (rightCellFrame.size.width - rightWidth)/2;

    if (self.lineStyle == BDXCategoryIndicatorLineStyle_Normal) {
        targetX = [BDXCategoryFactory interpolationFrom:leftX to:rightX percent:percent];
        if (self.indicatorWidth == BDXCategoryViewAutomaticDimension) {
            targetWidth = [BDXCategoryFactory interpolationFrom:leftWidth to:rightWidth percent:percent];
        }
    }else if (self.lineStyle == BDXCategoryIndicatorLineStyle_Lengthen) {
        CGFloat maxWidth = rightX - leftX + rightWidth;

        if (percent <= 0.5) {
            targetX = leftX;
            targetWidth = [BDXCategoryFactory interpolationFrom:leftWidth to:maxWidth percent:percent*2];
        }else {
            targetX = [BDXCategoryFactory interpolationFrom:leftX to:rightX percent:(percent - 0.5)*2];
            targetWidth = [BDXCategoryFactory interpolationFrom:maxWidth to:rightWidth percent:(percent - 0.5)*2];
        }
    }else if (self.lineStyle == BDXCategoryIndicatorLineStyle_LengthenOffset) {

        CGFloat offsetX = self.lineScrollOffsetX;
        CGFloat maxWidth = rightX - leftX + rightWidth - offsetX*2;
        if (percent <= 0.5) {
            targetX = [BDXCategoryFactory interpolationFrom:leftX to:leftX + offsetX percent:percent*2];;
            targetWidth = [BDXCategoryFactory interpolationFrom:leftWidth to:maxWidth percent:percent*2];
        }else {
            targetX = [BDXCategoryFactory interpolationFrom:(leftX + offsetX) to:rightX percent:(percent - 0.5)*2];
            targetWidth = [BDXCategoryFactory interpolationFrom:maxWidth to:rightWidth percent:(percent - 0.5)*2];
        }
    }

    if (self.isScrollEnabled == YES || (self.isScrollEnabled == NO && percent == 0)) {
        CGRect frame = self.frame;
        frame.origin.x = targetX;
        frame.size.width = targetWidth;
        self.frame = frame;
    }
}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    CGRect targetIndicatorFrame = self.frame;
    CGFloat targetIndicatorWidth = [self indicatorWidthValue:model.selectedCellFrame];
    targetIndicatorFrame.origin.x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - targetIndicatorWidth)/2.0;
    targetIndicatorFrame.size.width = targetIndicatorWidth;
    if (self.isScrollEnabled) {
        if (self.scrollStyle == BDXCategoryIndicatorScrollStyleSameAsUserScroll && (model.selectedType == BDXCategoryCellSelectedTypeClick | model.selectedType == BDXCategoryCellSelectedTypeCode)) {
            if (self.animator.isExecuting) {
                [self.animator invalid];
                self.animator = nil;
            }
            CGFloat leftX = 0;
            CGFloat rightX = 0;
            CGFloat leftWidth = 0;
            CGFloat rightWidth = 0;
            BOOL isNeedReversePercent = NO;
            if (self.frame.origin.x > model.selectedCellFrame.origin.x) {
                leftWidth = [self indicatorWidthValue:model.selectedCellFrame];
                rightWidth = self.frame.size.width;
                leftX = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - leftWidth)/2;;
                rightX = self.frame.origin.x;
                isNeedReversePercent = YES;
            }else {
                leftWidth = self.frame.size.width;
                rightWidth = [self indicatorWidthValue:model.selectedCellFrame];
                leftX = self.frame.origin.x;
                rightX = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - rightWidth)/2;
            }
            __weak typeof(self) weakSelf = self;
            if (self.lineStyle == BDXCategoryIndicatorLineStyle_Normal) {
                [UIView animateWithDuration:self.scrollAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.frame = targetIndicatorFrame;
                } completion: nil];
            }else if (self.lineStyle == BDXCategoryIndicatorLineStyle_Lengthen) {
                CGFloat maxWidth = rightX - leftX + rightWidth;

                self.animator = [[BDXCategoryViewAnimator alloc] init];
                self.animator.progressCallback = ^(CGFloat percent) {
                    if (isNeedReversePercent) {
                        percent = 1 - percent;
                    }
                    CGFloat targetX = 0;
                    CGFloat targetWidth = 0;
                    if (percent <= 0.5) {
                        targetX = leftX;
                        targetWidth = [BDXCategoryFactory interpolationFrom:leftWidth to:maxWidth percent:percent*2];
                    }else {
                        targetX = [BDXCategoryFactory interpolationFrom:leftX to:rightX percent:(percent - 0.5)*2];
                        targetWidth = [BDXCategoryFactory interpolationFrom:maxWidth to:rightWidth percent:(percent - 0.5)*2];
                    }
                    CGRect toFrame = weakSelf.frame;
                    toFrame.origin.x = targetX;
                    toFrame.size.width = targetWidth;
                    weakSelf.frame = toFrame;
                };
                [self.animator start];
            }else if (self.lineStyle == BDXCategoryIndicatorLineStyle_LengthenOffset) {

                CGFloat offsetX = self.lineScrollOffsetX;
                CGFloat maxWidth = rightX - leftX + rightWidth - offsetX*2;
                self.animator = [[BDXCategoryViewAnimator alloc] init];
                self.animator.progressCallback = ^(CGFloat percent) {
                    if (isNeedReversePercent) {
                        percent = 1 - percent;
                    }
                    CGFloat targetX = 0;
                    CGFloat targetWidth = 0;
                    if (percent <= 0.5) {
                        targetX = [BDXCategoryFactory interpolationFrom:leftX to:leftX + offsetX percent:percent*2];;
                        targetWidth = [BDXCategoryFactory interpolationFrom:leftWidth to:maxWidth percent:percent*2];
                    }else {
                        targetX = [BDXCategoryFactory interpolationFrom:(leftX + offsetX) to:rightX percent:(percent - 0.5)*2];
                        targetWidth = [BDXCategoryFactory interpolationFrom:maxWidth to:rightWidth percent:(percent - 0.5)*2];
                    }
                    CGRect toFrame = weakSelf.frame;
                    toFrame.origin.x = targetX;
                    toFrame.size.width = targetWidth;
                    weakSelf.frame = toFrame;
                };
                [self.animator start];
            }
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
