//
//  AWEDelayRecordCoverView.m
//  Aweme
//
//  Created by 旭旭 on 2017/11/10.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEDelayRecordCoverView.h"
#import <CreativeKit/ACCMacros.h>

@implementation AWEDelayRecordCoverView

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
        shapeLayer.fillColor = ACCUIColorFromRGBA(0xFFFFFF, 0.15).CGColor;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft cornerRadii:CGSizeMake(2, 2)];
    shapeLayer.path = path.CGPath;
}

@end
