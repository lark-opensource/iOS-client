//
//  BDXCategoryIndicatorBallView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/21.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorBallView.h"
#import "BDXCategoryFactory.h"

@interface BDXCategoryIndicatorBallView ()
@property (nonatomic, strong) UIView *smallBall;
@property (nonatomic, strong) UIView *bigBall;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@end

@implementation BDXCategoryIndicatorBallView

#pragma mark - Initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureIndicatorBall];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self configureIndicatorBall];
    }
    return self;
}

- (void)configureIndicatorBall {
    self.indicatorWidth = 15;
    self.indicatorHeight = 15;
    _ballScrollOffsetX = 20;

    _smallBall = [[UIView alloc] init];
    [self addSubview:self.smallBall];

    _bigBall = [[UIView alloc] init];
    [self addSubview:self.bigBall];

    _shapeLayer = [CAShapeLayer layer];
    [self.layer addSublayer:self.shapeLayer];
}

#pragma mark - BDXCategoryIndicatorProtocol

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat ballWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGFloat ballHeight = [self indicatorHeightValue:model.selectedCellFrame];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shapeLayer.fillColor = self.indicatorColor.CGColor;
    [CATransaction commit];
    
    self.smallBall.backgroundColor = self.indicatorColor;
    self.smallBall.layer.cornerRadius = ballHeight/2;
    self.bigBall.backgroundColor = self.indicatorColor;
    self.bigBall.layer.cornerRadius = ballHeight/2;

    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - ballWidth)/2;
    CGFloat y = self.superview.bounds.size.height - ballHeight - self.verticalMargin;
    if (self.componentPosition == BDXCategoryComponentPosition_Top) {
        y = self.verticalMargin;
    }
    self.smallBall.frame = CGRectMake(x, y, ballWidth, ballHeight);
    self.bigBall.frame = CGRectMake(x, y, ballWidth, ballHeight);
}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat ballWidth = [self indicatorWidthValue:model.leftCellFrame];
    CGFloat ballHeight = [self indicatorHeightValue:model.leftCellFrame];
    CGRect rightCellFrame = model.rightCellFrame;
    CGRect leftCellFrame = model.leftCellFrame;
    CGFloat percent = model.percent;
    CGFloat targetXOfBigBall = 0;
    CGFloat targetXOfSmallBall = leftCellFrame.origin.x + (leftCellFrame.size.width - ballWidth)/2;
    CGFloat targetWidthOfSmallBall = ballWidth;

    if (percent == 0) {
        targetXOfBigBall = leftCellFrame.origin.x + (leftCellFrame.size.width - ballWidth)/2.0;
        targetXOfSmallBall = leftCellFrame.origin.x + (leftCellFrame.size.width - targetWidthOfSmallBall)/2.0;
    }else {
        CGFloat leftX = leftCellFrame.origin.x + (leftCellFrame.size.width - ballWidth)/2;
        CGFloat rightX = rightCellFrame.origin.x + (rightCellFrame.size.width - ballWidth)/2;

        if (percent <= 0.5) {
            targetXOfBigBall = [BDXCategoryFactory interpolationFrom:leftX to:(rightX - self.ballScrollOffsetX) percent:percent*2];
            targetWidthOfSmallBall = [BDXCategoryFactory interpolationFrom:ballWidth to:ballWidth/2 percent:percent*2];
        }else {
            targetXOfBigBall = [BDXCategoryFactory interpolationFrom:(rightX - self.ballScrollOffsetX) to:rightX percent:(percent - 0.5)*2];
            targetWidthOfSmallBall = [BDXCategoryFactory interpolationFrom:ballWidth/2 to:0 percent:(percent - 0.5)*2];
            targetXOfSmallBall = [BDXCategoryFactory interpolationFrom:leftX to:rightX percent:(percent - 0.5)*2];
        }
    }

    if (self.isScrollEnabled == YES || (self.isScrollEnabled == NO && percent == 0)) {
        CGRect bigBallFrame = self.bigBall.frame;
        bigBallFrame.origin.x = targetXOfBigBall;
        self.bigBall.frame = bigBallFrame;
        self.bigBall.layer.cornerRadius = bigBallFrame.size.height/2;

        CGFloat targetYOfSmallBall = self.superview.bounds.size.height - ballHeight/2 - targetWidthOfSmallBall/2 - self.verticalMargin;
        if (self.componentPosition == BDXCategoryComponentPosition_Top) {
            targetYOfSmallBall = ballHeight/2 - targetWidthOfSmallBall/2 + self.verticalMargin;
        }
        self.smallBall.frame = CGRectMake(targetXOfSmallBall, targetYOfSmallBall, targetWidthOfSmallBall, targetWidthOfSmallBall);
        self.smallBall.layer.cornerRadius = targetWidthOfSmallBall/2;

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.shapeLayer.path = [self getBezierPathWithSmallCir:self.smallBall andBigCir:self.bigBall].CGPath;
        [CATransaction commit];
    }
}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    CGFloat ballWidth = [self indicatorWidthValue:model.selectedCellFrame];
    CGFloat ballHeight = [self indicatorHeightValue:model.selectedCellFrame];
    CGFloat x = model.selectedCellFrame.origin.x + (model.selectedCellFrame.size.width - ballWidth)/2;
    CGFloat y = self.superview.bounds.size.height - ballHeight - self.verticalMargin;
    if (self.componentPosition == BDXCategoryComponentPosition_Top) {
        y = self.verticalMargin;
    }
    CGRect toFrame = CGRectMake(x, y, ballWidth, ballHeight);

    if (self.isScrollEnabled) {
        [UIView animateWithDuration:self.scrollAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.smallBall.frame = toFrame;
            self.bigBall.frame = toFrame;
            self.smallBall.layer.cornerRadius = ballHeight/2;
            self.bigBall.layer.cornerRadius = ballHeight/2;
        } completion:^(BOOL finished) {

        }];
    }else {
        self.smallBall.frame = toFrame;
        self.bigBall.frame = toFrame;
        self.smallBall.layer.cornerRadius = ballHeight/2;
        self.bigBall.layer.cornerRadius = ballHeight/2;
    }
}

- (UIBezierPath *)getBezierPathWithSmallCir:(UIView *)smallCir andBigCir:(UIView *)bigCir{

    if (bigCir.frame.size.width < smallCir.frame.size.width) {
        UIView *view = bigCir;
        bigCir = smallCir;
        smallCir = view;
    }

    CGFloat d = self.bigBall.center.x - self.smallBall.center.x;
    if (d == 0) {
        return nil;
    }
    CGFloat x1 = smallCir.center.x;
    CGFloat y1 = smallCir.center.y;
    CGFloat r1 = smallCir.bounds.size.width/2;

    CGFloat x2 = bigCir.center.x;
    CGFloat y2 = bigCir.center.y;
    CGFloat r2 = bigCir.bounds.size.width/2;

    CGFloat sinA = (y2 - y1)/d;
    CGFloat cosA = (x2 - x1)/d;

    CGPoint pointA = CGPointMake(x1 - sinA*r1, y1 + cosA * r1);
    CGPoint pointB = CGPointMake(x1 + sinA*r1, y1 - cosA * r1);
    CGPoint pointC = CGPointMake(x2 + sinA*r2, y2 - cosA * r2);
    CGPoint pointD = CGPointMake(x2 - sinA*r2, y2 + cosA * r2);

    CGPoint pointO = CGPointMake(pointA.x + d / 2 * cosA , pointA.y + d / 2 * sinA);
    CGPoint pointP =  CGPointMake(pointB.x + d / 2 * cosA , pointB.y + d / 2 * sinA);

    UIBezierPath *path =[UIBezierPath bezierPath];
    [path moveToPoint:pointA];
    [path addLineToPoint:pointB];
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    [path addLineToPoint:pointD];
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    return path;
}

@end
