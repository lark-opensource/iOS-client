//Copyright © 2021 Bytedance. All rights reserved.

#import "AWEScrollStringFadeLabel.h"


@interface AWEScrollStringFadeLabel()

@property (nonatomic, strong) CAGradientLayer *fadeLayer;
@property (nonatomic, assign) CGFloat fadeLayerWidth;

@end


@implementation AWEScrollStringFadeLabel

-(instancetype) initWithHeight:(CGFloat)height fadeLayerWidth:(CGFloat)width{
    self = [super initWithHeight:height type:AWEScrollStringLabelTypeDefault];
    if (self){
        self.fadeLayerWidth = width;
        self.layer.mask = self.fadeLayer;
        self.fadeLayer.frame = CGRectMake(0, 0, width, height);
    }
    return self;
}


#pragma mark - Getters

-(CAGradientLayer *)fadeLayer{
    if (!_fadeLayer){
        _fadeLayer = [[CAGradientLayer alloc] init];
        self.fadeLayer.backgroundColor = UIColor.clearColor.CGColor;
        CGPoint startPoint = CGPointZero, endPoint = CGPointZero;
        startPoint = CGPointMake(0, 0.5);
        endPoint = CGPointMake(1, 0.5);
        CGFloat fadeInRatio = (self.fadeLayerWidth == 0.f) ? 0.f : 6.f / self.fadeLayerWidth;
        _fadeLayer.startPoint = startPoint;
        _fadeLayer.endPoint = endPoint;
        _fadeLayer.locations = @[@(0), @(fadeInRatio), @(1 - fadeInRatio)];
    }
    
    return _fadeLayer;
}


#pragma mark - Fade Layer Helpers
- (void)updateFadeLayerColorWithCurrent:(BOOL)isCurrent {
    CGColorRef leftColor = isCurrent ? [UIColor colorWithWhite:1 alpha:0].CGColor : UIColor.whiteColor.CGColor;
    if (self.shouldScroll){
        self.fadeLayer.colors = @[(__bridge id)leftColor,
                             (__bridge id)UIColor.whiteColor.CGColor,
                             (__bridge id)UIColor.whiteColor.CGColor,
                             (__bridge id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    }

}





@end
