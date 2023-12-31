//
//  ACCPropIndicatorView.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//

#import "ACCPropIndicatorView.h"
#import <CreativeKit/UIFont+ACC.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCMBCircularProgressBarView.h"

@interface ACCPropIndicatorView()
@property (nonatomic, strong) CALayer *ringLayer;
@property (nonatomic, strong) UIView *tipsView;
@property (nonatomic, strong) ACCMBCircularProgressBarView *progressView;

@end

@implementation ACCPropIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tipsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
        _tipsView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self addSubview:_tipsView];
        _tipsView.layer.cornerRadius = 32;
        _tipsView.layer.masksToBounds = YES;

        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 2;
        label.font = [UIFont acc_pingFangMedium:17];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse);
        label.text = @"点击\n拍摄";
        label.textAlignment = NSTextAlignmentCenter;
        [label sizeToFit];
        label.center = CGPointMake(_tipsView.acc_width / 2.f, _tipsView.acc_height / 2.f);
        self.captureLabel = label;
        [_tipsView addSubview:label];
        
        [self.layer addSublayer:self.ringLayer];
    }
    return self;
}

- (ACCMBCircularProgressBarView *)progressView
{
    if (!_progressView){
        _progressView = [[ACCMBCircularProgressBarView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        _progressView.backgroundColor = UIColor.clearColor;
        _progressView.emptyLineWidth = 3;
        _progressView.emptyLineColor = [UIColor.whiteColor colorWithAlphaComponent:0.6];
        _progressView.emptyLineStrokeColor = _progressView.emptyLineColor;
        _progressView.showValueString = NO;
        _progressView.progressCapType = kCGLineCapRound;
        _progressView.progressColor = UIColor.whiteColor;
        _progressView.progressStrokeColor = _progressView.progressColor;
        _progressView.progressAngle = 100;
        _progressView.progressRotationAngle = 50;
        _progressView.progressLineWidth = 3;
        _progressView.maxValue = 1;
        [self addSubview:_progressView];
    }
    return _progressView;
}


- (void)showProgress:(BOOL)show progress:(CGFloat)value
{
    [self showProgress:show progress:value animated:YES]; // default animated 应该是 NO，但原来的逻辑写的YES，保留吧。
}

- (void)showProgress:(BOOL)show progress:(CGFloat)value animated:(BOOL)animated
{
    [self showProgress:show animated:animated];
    self.progressView.value = value;
}

- (void)showProgress:(BOOL)showProgress animated:(BOOL)animated
{
    if (animated) {
        if (showProgress && self.showProgress) {
            return;
        }
        if (!showProgress && !self.showProgress) {
            return;
        }
        CGFloat endAlpha = showProgress ? 1.0 : 0;
        if (showProgress && !self.showProgress) {
            self.showProgress = showProgress;
            self.progressView.alpha = 0;
        }
        [self.progressView.layer removeAllAnimations];
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = endAlpha;
        } completion:^(BOOL finished) {
            if (finished) {
                self.showProgress = showProgress;
            }
        }];
    } else {
        self.showProgress = showProgress;
    }
}

- (void)setShowProgress:(BOOL)showProgress
{
    self.progressView.hidden = !showProgress;
}

- (BOOL)showProgress
{
    return !self.progressView.hidden;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.ringLayer.mask = [self ringMaskLayer];
    self.ringLayer.frame = self.bounds;
    CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
    _tipsView.center = center;
    _progressView.center = center;
    
}

- (void)setRingTintColor:(UIColor *)tintColor
{
    _ringTintColor = tintColor;
    self.ringLayer.backgroundColor = tintColor.CGColor;
}

- (CALayer *)ringLayer {
    if (_ringLayer == nil) {
        _ringLayer = [CALayer layer];
        _ringLayer.frame = self.bounds;
        _ringLayer.backgroundColor = self.ringTintColor.CGColor;
    }
    return _ringLayer;
}

- (CAShapeLayer *)ringMaskLayer
{
    CGFloat radius = self.bounds.size.width * 0.5;
    if (self.ringBandWidth <= 0 || self.ringBandWidth >= radius) {
        return nil;
    }
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    CGFloat innerRadius = radius - self.ringBandWidth;
    CGRect innerFrame = CGRectMake(self.ringBandWidth, self.ringBandWidth, innerRadius * 2, innerRadius * 2);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithOvalInRect:innerFrame].bezierPathByReversingPath;
    [outerPath appendPath:innerPath];
    maskLayer.path = outerPath.CGPath;
    return maskLayer;
}


@end
