//
//  AWEEditGradientView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEEditGradientView.h"

@implementation AWEEditGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame topColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor
{
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        gradientLayer.locations = @[@0, @1];
        gradientLayer.colors = @[(__bridge id)topColor.CGColor,
                                 (__bridge id)bottomColor.CGColor];
        
        self.alpha = 0.3;
    }
    return self;
}

- (instancetype)initLeftTop2RightBottomWithColors:(NSArray *)colors
{
    if (self = [super init]) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.startPoint = CGPointMake(1, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        gradientLayer.locations = @[@0, @1];
        gradientLayer.colors = colors;
    }
    return self;
}

- (CAGradientLayer *)gradientLayer
{
    return (CAGradientLayer *)self.layer;
}

@end
