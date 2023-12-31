//
//  AWEScrollStringButton.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/14.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <objc/runtime.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "AWEScrollStringButton.h"
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIButton+ACCAdditions.h>

static const CGFloat kSpacingInFrontOfContentLabel = 4;
static const CGFloat kSpacingBehindContentLabel = 14;
static const CGFloat kSpacingAlongsideCloseButton = 6;

@interface AWEScrollStringButton () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) AWEScrollStringLabel *label;
@property (nonatomic, strong) UIView *blurView;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *closeBackgroundView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) CGFloat maxButtonWidth;

@end

@implementation AWEScrollStringButton

@synthesize shouldAnimate = _shouldAnimate;
@synthesize enableConstantSpeed = _enableConstantSpeed;
@synthesize buttonWidth = _buttonWidth;
@synthesize acc_enabled = _acc_enabled;
@synthesize enableImageRotation = _enableImageRotation;
@synthesize isDisableStyle = _isDisableStyle;
@synthesize acc_hitTestEdgeInsets = _acc_hitTestEdgeInsets;
@synthesize hasMusic = _hasMusic;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.acc_enabled = YES;
        if (ACCConfigBool(kConfigBoolEnableYValueOfRecordAndEditPageUIAdjustment)) {
            self.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, 0, -20, 0);
        } else {
            self.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-8, 0, -8, 0);
        }
        
        [self setupUI];
    }
    return self;
}

-  (void)setupUI
{
    UIView *blur = [UIView new];
    blur.layer.cornerRadius = 16;
    blur.layer.masksToBounds = YES;
    blur.backgroundColor = [self getBackgroundColor];
    [self addSubview:blur];
    ACCMasMaker(blur, {
        make.left.right.centerY.equalTo(self);
        make.height.equalTo(@32);
    });
    self.blurView = blur;

    [self.blurView addSubview:self.maskView];
    self.maskView.hidden = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.maskView.hidden = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.maskView.hidden = YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.maskView.hidden = YES;
}

- (void)configWithImage:(UIImage *)image title:(NSString *)title hasMusic:(BOOL)hasMusic
{
    CGFloat maxWidth = MIN(300, CGRectGetWidth([UIScreen mainScreen].bounds) - 128);
    [self configWithImage:image title:title hasMusic:hasMusic maxButtonWidth:maxWidth];
}

- (void)configWithImage:(UIImage *)image title:(NSString *)title hasMusic:(BOOL)hasMusic maxButtonWidth:(CGFloat)maxButtonWidth {
    self.hasMusic = hasMusic;
    self.maxButtonWidth = maxButtonWidth;
    CGFloat extra = 12; // extra width for corner radius

    self.clipsToBounds = YES;
    self.imageView.image = image;
    _imageView.frame = CGRectMake(extra, (self.frame.size.height - image.size.height) / 2.0, image.size.width, image.size.height);
    [self addSubview:_imageView];
    [self insertSubview:_imageView belowSubview:self.maskView];

    
    CGFloat widthWithoutContentLabel = 0;
    CGFloat minButtonWidth = 0;
    if (self.closeButton.alpha == 0) {
        minButtonWidth = 116;
        widthWithoutContentLabel = extra + image.size.width + kSpacingInFrontOfContentLabel + extra;
    } else {
        CGFloat closeButtonWidth = kSpacingAlongsideCloseButton + CGRectGetWidth(self.closeButton.frame) + kSpacingAlongsideCloseButton;
        minButtonWidth = 160;
        widthWithoutContentLabel = extra + image.size.width + kSpacingInFrontOfContentLabel + kSpacingBehindContentLabel + closeButtonWidth;
    }
    CGFloat minContentLabelWidth = minButtonWidth - widthWithoutContentLabel;
    CGFloat maxContentLabelWidth = maxButtonWidth - widthWithoutContentLabel;
    
    [self.label configWithTitle:title titleColor:ACCResourceColor(ACCUIColorConstTextInverse)
                       fontSize:[ACCFont() getAdaptiveFontSize:13]
                         isBold:YES
               minimumItemWidth:self.shouldAnimate ? minContentLabelWidth : 0];
    self.title = title;
    _label.accessibilityLabel = title;
    _label.accessibilityTraits = UIAccessibilityTraitButton;
    self.label.labelWidth = MIN(maxContentLabelWidth, self.label.labelWidth);
    
    self.label.frame = CGRectMake(extra + image.size.width + kSpacingInFrontOfContentLabel, 0, self.label.labelWidth, self.frame.size.height);
    [self addSubview:self.label];
    [self insertSubview:self.label belowSubview:self.maskView];
    [self.label updateSubviewsLayout];
    [self addSubview:self.closeBackgroundView];
    [self addSubview:self.separatorView];
    [self addSubview:self.closeButton];
    self.buttonWidth = self.label.labelWidth + widthWithoutContentLabel;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorView.center = CGPointMake(CGRectGetMaxX(self.label.frame) + kSpacingBehindContentLabel + CGRectGetWidth(self.separatorView.frame) / 2, CGRectGetHeight(self.bounds)/2);
    if (self.closeButton.alpha != 0) {
        self.maskView.frame = CGRectMake(0, 0, CGRectGetMinX(self.separatorView.frame), CGRectGetHeight(self.maskView.superview.bounds));
        self.closeBackgroundView.frame = CGRectMake(CGRectGetMaxX(self.separatorView.frame),
                                                    CGRectGetMinY(self.blurView.frame),
                                                    CGRectGetMaxX(self.bounds) - CGRectGetMaxX(self.separatorView.frame),
                                                    CGRectGetHeight(self.blurView.frame));
    } else {
        self.maskView.frame = self.maskView.superview.bounds;
    }
    self.closeButton.center = CGPointMake(CGRectGetMinX(self.separatorView.frame) + kSpacingAlongsideCloseButton + CGRectGetWidth(self.closeButton.frame)/2, self.blurView.center.y);
    self.closeBackgroundView.layer.mask.frame = CGRectMake(-16, 0, CGRectGetWidth(self.closeBackgroundView.bounds) + 16, 32);
}

- (void)startAnimation
{
    if (self.shouldAnimate) {
        if (self.enableConstantSpeed) {
            [self.label startAnimationWithSpeed:20];
        } else {
            [self.label startAnimation];
        }
    }
}

- (void)stopAnimation
{
    [self.label stopAnimation];
}

- (void)showCloseButton
{
    self.closeButton.alpha = 1;
    self.separatorView.alpha = 1;
    self.closeButton.isAccessibilityElement = YES;
    [self configWithImage:self.imageView.image title:self.title hasMusic:self.hasMusic maxButtonWidth:self.maxButtonWidth];
}

- (void)hideCloseButton
{
    self.closeButton.alpha = 0;
    self.separatorView.alpha = 0;
    self.closeButton.isAccessibilityElement = NO;
    [self configWithImage:self.imageView.image title:self.title hasMusic:self.hasMusic maxButtonWidth:self.maxButtonWidth];
}

- (void)setIsDisableStyle:(BOOL)isDisableStyle
{
    _isDisableStyle = isDisableStyle;
    self.alpha = isDisableStyle ? 0.5f:1.f;
    self.maskView.alpha = isDisableStyle ? 0.f:1.f;
}

- (void)closeButtonDidTouchDown:(UIButton *)button
{
    [UIView animateWithDuration:0.2 animations:^{
        self.closeBackgroundView.alpha = 1;
    }];
}

- (void)closeButtonDidTouchUp:(UIButton *)button
{
    [UIView animateWithDuration:0.2 animations:^{
        self.closeBackgroundView.alpha = 0;
    }];
}

#pragma mark - getter

- (void)showLabelShadow
{
    [self.label showShadowWithOffset:CGSizeMake(0, 1) color:ACCResourceColor(ACCUIColorConstLinePrimary) radius:2];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
         _imageView.isAccessibilityElement = NO;
    }
    return _imageView;
}

- (AWEScrollStringLabel *)label {
    if (!_label) {
        _label = [[AWEScrollStringLabel alloc] init];
        [self.label configWithLoopContainerViewHeight:16];
        [_label showShadowWithOffset:CGSizeMake(0, 1) color:ACCResourceColor(ACCUIColorConstLinePrimary) radius:2];
        _label.accessibilityLabel = _label.leftLabel.text;
        _label.isAccessibilityElement = YES;
    }
    return _label;
}

- (UIView *)separatorView
{
    if (!_separatorView) {
        _separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 32)];
        _separatorView.backgroundColor = ACCResourceColor(ACCColorConstTextInverse5);
        _separatorView.layer.cornerRadius = 0.5;
        _separatorView.alpha = 0;
    }
    return _separatorView;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [_closeButton setImage:ACCResourceImage(@"record_entrance_opt_close") forState:UIControlStateNormal];
        _closeButton.alpha = 0;
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchDown:) forControlEvents:UIControlEventTouchDragInside];
        
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchUp:) forControlEvents:UIControlEventTouchDragOutside];
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_closeButton addTarget:self action:@selector(closeButtonDidTouchUp:) forControlEvents:UIControlEventTouchCancel];
    }
    return _closeButton;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = ACCResourceColor(ACCColorSDTertiary);
    }
    return _maskView;
}

- (UIView *)closeBackgroundView
{
    if (!_closeBackgroundView) {
        _closeBackgroundView = [[UIView alloc] init];
        _closeBackgroundView.backgroundColor = ACCResourceColor(ACCColorSDTertiary);
        CALayer *shapeLayer = [[CALayer alloc] init];
        shapeLayer.cornerRadius = 16;
        shapeLayer.opaque = NO;
        shapeLayer.masksToBounds = YES;
        shapeLayer.backgroundColor = [UIColor blackColor].CGColor;
        _closeBackgroundView.layer.mask = shapeLayer;
        _closeBackgroundView.alpha = 0;
    }
    return _closeBackgroundView;
}

- (void)addTarget:(id)target action:(SEL)action
{
    for (UIGestureRecognizer *ges in self.gestureRecognizers) {
        [self removeGestureRecognizer:ges];
    }

    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    tapGes.delegate = self;
    [self addGestureRecognizer:tapGes];
}

- (CGFloat)buttonHeight
{
    return MAX(16, self.imageView.acc_height);
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    [super setUserInteractionEnabled:userInteractionEnabled];
    self.imageView.alpha = userInteractionEnabled ? 1.0f : 0.4f;
    self.label.alpha = self.imageView.alpha;
}

- (void)setAcc_enabled:(BOOL)acc_enabled
{
    _acc_enabled = acc_enabled;
    self.imageView.alpha = acc_enabled ? 1.0f : 0.4f;
    self.label.alpha = self.imageView.alpha;
}

- (void)setEnableImageRotation:(BOOL)enableImageRotation
{
    _enableImageRotation = enableImageRotation;
    [self p_updateImageViewRoateAnim];
}

- (void)p_updateImageViewRoateAnim
{
    NSString *animationKey = @"rotateAnim";
    if (_enableImageRotation) {
        if ([self.imageView.layer animationForKey:animationKey]) {
            return;
        }
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.removedOnCompletion = NO;
        NSArray *transforms = @[
            [NSValue valueWithCATransform3D:CATransform3DRotate(CATransform3DIdentity, 0.001, 0, 0, 1)],
            [NSValue valueWithCATransform3D:CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1)],
            [NSValue valueWithCATransform3D:CATransform3DRotate(CATransform3DIdentity, M_PI * 2 - 0.001, 0, 0, 1)],
        ];
        animation.repeatCount = NSIntegerMax;
        animation.values = transforms;
        animation.keyTimes = @[@0,@0.5,@1];
        animation.keyPath = @"transform";
        animation.duration = 0.5;
        [self.imageView.layer addAnimation:animation forKey:animationKey];
    } else {
        [self.imageView.layer removeAnimationForKey:animationKey];
    }
}
#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return @[self.label, self.closeButton];
}

#pragma mark - utils

- (UIColor *)getBackgroundColor
{
    return ACCResourceColor(ACCColorConstBGInverse2);;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    UIEdgeInsets hitTestEdgeInsets = self.acc_hitTestEdgeInsets;
    if (UIEdgeInsetsEqualToEdgeInsets(hitTestEdgeInsets, UIEdgeInsetsZero) || self.hidden || !self.alpha) {
        return [super pointInside:point withEvent:event];
    }
    
    if (ACCConfigBool(kConfigBoolEnableYValueOfRecordAndEditPageUIAdjustment)) {
        CGFloat minHitRegionWidth = 180;
        CGFloat xDelta = MAX(minHitRegionWidth - self.frame.size.width, 0);
        CGFloat minLeftDelta = MIN((-0.5 * xDelta), hitTestEdgeInsets.left);
        CGFloat minRightDelta = MIN((-0.5 * xDelta), hitTestEdgeInsets.right);
        hitTestEdgeInsets = UIEdgeInsetsMake(hitTestEdgeInsets.top, minLeftDelta, hitTestEdgeInsets.bottom, minRightDelta);
        
        if (self.closeButton.alpha != 0) {
            // 有关闭按钮
            CGFloat closeButtonInsetTop = - (self.frame.size.height - self.closeButton.frame.size.height) * 0.5 + hitTestEdgeInsets.top;
            CGFloat closeButtonInsetBottom = - (self.frame.size.height - self.closeButton.frame.size.height) * 0.5 + hitTestEdgeInsets.bottom;
            CGFloat closeButtonInsetRight = - (self.closeBackgroundView.frame.size.width - self.closeButton.frame.size.width) * 0.5 + minRightDelta;
            self.closeButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(closeButtonInsetTop, 0, closeButtonInsetBottom, closeButtonInsetRight);
        }
    }
    
    CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

@end
