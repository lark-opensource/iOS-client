//
//  ACCCircleItemCell.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/8.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import "ACCCircleItemCell.h"
#import "ACCMBCircularProgressBarView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacrosTool.h>

@interface ACCCircleItemCell()
@property (nonatomic, strong) UIView *circleContentView;
@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) CALayer *shadowLayer;
@property (nonatomic, strong) UIVisualEffectView *effectView;
@end

@implementation ACCCircleItemCell
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (CAShapeLayer *)shadowMaskLayer
{
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, -self.shadowRadius * 1.5, -self.shadowRadius * 1.5)];
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:self.bounds].bezierPathByReversingPath];
    maskLayer.path = path.CGPath;
    maskLayer.fillColor = UIColor.whiteColor.CGColor;
    return maskLayer;
}

- (void)setupUI
{
    self.clipsToBounds = NO;
    // shadow
    self.shadowLayer = [CALayer layer];
    self.shadowLayer.frame = self.bounds;
    self.shadowLayer.shadowRadius = self.shadowRadius;
    self.shadowLayer.shadowColor = ACCResourceColor(ACCUIColorConstSDInverse).CGColor;
    self.shadowLayer.shadowOpacity = 1.0;
    self.shadowLayer.shadowOffset = CGSizeZero;
    [self.contentView.layer addSublayer:self.shadowLayer];
    
    // content view container
    self.circleContentView = [[UIView alloc] initWithFrame:self.bounds];
    [self.contentView addSubview:self.circleContentView];
    self.circleContentView.backgroundColor = self.placeholderColor;
    self.circleContentView.clipsToBounds = YES;
    self.circleContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // background view
    self.background = [[UIView alloc] initWithFrame:self.bounds];
    self.background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.background.backgroundColor = self.placeholderColor;
    self.background.layer.borderColor = self.borderColor.CGColor;
    self.background.layer.borderWidth = self.borderWidth;
    
    // add blur effect to background view
    UIBlurEffectStyle style = UIBlurEffectStyleLight;
    if (@available(iOS 13.0, *)) {
        style = UIBlurEffectStyleSystemUltraThinMaterialLight;
    }
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _effectView = effectView;
    [self.background addSubview:effectView];
    effectView.frame = self.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.circleContentView addSubview:self.background];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    self.background.backgroundColor = self.placeholderColor;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    _shadowRadius = shadowRadius;
    self.shadowLayer.shadowRadius = shadowRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.background.layer.borderWidth = self.borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.background.layer.borderColor = self.borderColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat radius = self.bounds.size.width * 0.5;
    self.circleContentView.layer.cornerRadius = radius;
    self.background.layer.cornerRadius = radius;
    
    self.shadowLayer.frame = self.bounds;
    self.shadowLayer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    self.shadowLayer.mask = [self shadowMaskLayer];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.effectView.hidden = NO;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityHint
{
    return @"双击应用";
}

- (NSString *)accessibilityLabel
{
    if (!ACC_isEmptyString(self.name)) {
        return self.name;
    }
    return [NSString stringWithFormat:@"道具%@", @(self.indexPath.row+1)];
}

@end


@interface ACCCircleImageItemCell()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *overlayImageView;
@property (nonatomic, strong) UIImageView *overlay;
@end

@implementation ACCCircleImageItemCell

- (void)setupUI
{
    [super setupUI];
    _imageRatio = 1;
    // image view
    self.imageView = [[UIImageView alloc] init];
    self.imageView.center = CGPointMake(self.circleContentView.acc_width / 2.f, self.circleContentView.acc_height / 2.f);
    [self.circleContentView addSubview:self.imageView];
    
    // overlay
    self.overlay = [[UIImageView alloc] initWithFrame:self.bounds];
    self.overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.circleContentView addSubview:self.overlay];
    
    self.overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.overlayImageView.center = CGPointMake(self.circleContentView.acc_width / 2.f, self.circleContentView.acc_height / 2.f);
    [self.circleContentView addSubview:self.overlayImageView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.center = CGPointMake(self.circleContentView.acc_width / 2.f, self.circleContentView.acc_height / 2.f);
    if (self.useRatioImage) {
        self.imageView.bounds = CGRectMake(0, 0, self.acc_width * self.imageRatio, self.acc_height * self.imageRatio);
    }
    self.overlayImageView.center = CGPointMake(self.circleContentView.acc_width / 2.f, self.circleContentView.acc_height / 2.f);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    self.overlayImageView.image = nil;
    self.overlay.backgroundColor = UIColor.clearColor;
}

@end

@implementation ACCCircleHomeItemCell

@end

@interface ACCCircleResourceItemCell()
@property (nonatomic, strong) ACCMBCircularProgressBarView *progressView;
@end

@implementation ACCCircleResourceItemCell

@dynamic showProgress;

- (void)setupUI
{
    [super setupUI];
    // progress view
    self.progressView = [[ACCMBCircularProgressBarView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.progressView.center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
    self.progressView.backgroundColor = UIColor.clearColor;
    self.progressView.emptyLineWidth = 3;
    self.progressView.emptyLineColor = [UIColor.whiteColor colorWithAlphaComponent:0.5];
    self.progressView.showValueString = NO;
    self.progressView.progressCapType = kCGLineCapRound;
    self.progressView.progressColor = [UIColor.whiteColor colorWithAlphaComponent:0.9];
    self.progressView.progressAngle = 100;
    self.progressView.progressRotationAngle = 50;
    self.progressView.progressStrokeColor = self.progressView.progressColor;
    self.progressView.progressLineWidth = 3;
    self.progressView.maxValue = 1;
    [self.circleContentView addSubview:self.progressView];
    self.showProgress = NO;
    self.progress = 0;
    self.imageScale = 1;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    self.progressView.value = progress;
}

- (void)setShowProgress:(BOOL)showProgress animated:(BOOL)animated
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
            self.overlay.alpha = 0;
        }
        [self.progressView.layer removeAllAnimations];
        [self.overlay.layer removeAllAnimations];
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = endAlpha;
            self.overlay.alpha = endAlpha;
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
    self.overlay.hidden = !showProgress;
}

- (BOOL)showProgress
{
    return !self.progressView.hidden;
}

- (void)setImageScale:(CGFloat)imageScale
{
    _imageScale = imageScale;
    self.imageView.frame = [self imageViewFrame];
}

- (CGRect)imageViewFrame
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat sw = w * self.imageScale;
    CGFloat sh = h * self.imageScale;
    return CGRectMake(0.5 * (w - sw), 0.5 * (h - sh), sw, sh);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = [self imageViewFrame];
    self.progressView.center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.showProgress = NO;
    self.progress = 0;
    self.imageScale = 1;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
