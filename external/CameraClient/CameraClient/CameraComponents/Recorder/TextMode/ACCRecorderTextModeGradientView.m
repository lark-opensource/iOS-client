//
//  ACCRecorderTextModeGradientView.m
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/22.
//

#import "ACCRecorderTextModeGradientView.h"

@implementation ACCRecorderTextModeGradientView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (void)setColors:(NSArray *)colors
{
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    gradientLayer.colors = colors;
    gradientLayer.startPoint = CGPointMake(1, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
}

- (NSArray *)colors
{
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    return gradientLayer.colors;
}

@end
