//
//  ACCScreenSimulatedTorchView.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Bing on 2021/6/20.
//

#import "ACCScreenSimulatedTorchView.h"

@interface ACCScreenSimulatedTorchView ()

@property (nonatomic, assign) CGFloat originalBrightness;

@end

@implementation ACCScreenSimulatedTorchView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        self.originalBrightness = [UIScreen mainScreen].brightness;
    }
    return self;
}

- (void)turnOn
{
    self.hidden = NO;
    [UIScreen mainScreen].brightness = 1.0;
}

- (void)turnOff
{
    [UIScreen mainScreen].brightness = self.originalBrightness;
    self.hidden = YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if(hitView == self){
        return nil;
    }
    return hitView;
}

@end
