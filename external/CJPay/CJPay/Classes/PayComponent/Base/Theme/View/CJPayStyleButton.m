//
//  CJPayStyleButton.m
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayTracker.h"

@interface CJPayStyleButton ()

@property (nonatomic, assign) BOOL isGradientNormalBackground;
@property (nonatomic, assign) BOOL isGradientDisabledBackground;

@end

@implementation CJPayStyleButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;

        [self p_installDefaultAppearance];
        [self setTitleColor:self.titleColor forState:UIControlStateNormal];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        [CJTracker event:@"wallet_style_button_zero_size" params:@{}];
        return;
    }
    
    CJPayStyleButton *appearance = [CJPayStyleButton appearance];
    if ((appearance.normalBackgroundColorStart == nil
         && appearance.normalBackgroundColorEnd == nil)) {
        [CJTracker event:@"wallet_theme_not_installed" params:@{@"type": @"normalBackground"}];
    }
    if (appearance.disabledBackgroundColorStart == nil
        && appearance.disabledBackgroundColorEnd == nil) {
        [CJTracker event:@"wallet_theme_not_installed" params:@{@"type": @"disabledBackground"}];
    }
    
    if (self.isGradientNormalBackground) {
        [self p_applyGradientStyleWithSize:self.bounds.size
                                startColor:self.normalBackgroundColorStart
                                  endColor:self.normalBackgroundColorEnd
                                  forState:UIControlStateNormal];
        [self p_applyGradientStyleWithSize:self.bounds.size
                                startColor:self.normalBackgroundColorStart
                                  endColor:self.normalBackgroundColorEnd
                                  forState:UIControlStateHighlighted];
        self.isGradientNormalBackground = NO;
    }
    
    
    if (self.isGradientDisabledBackground) {
        [self p_applyGradientStyleWithSize:self.bounds.size
                                startColor:self.disabledBackgroundColorStart
                                  endColor:self.disabledBackgroundColorEnd
                                  forState:UIControlStateDisabled];
        self.isGradientDisabledBackground = NO;
    }

    if (self.layer.cornerRadius > self.frame.size.height/2) { //修复UIButton圆角问题
        self.layer.cornerRadius = self.frame.size.height/2;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha {
    _disabledAlpha = disabledAlpha;
    //待UIAppearance生效，重新赋值给titleLabel.alpha
    self.titleLabel.alpha = self.enabled ? 1 : self.disabledAlpha;
}

- (void)setTitleColor:(UIColor *)titleColor {
    self.titleLabel.textColor = titleColor;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    self.titleLabel.alpha = enabled ? 1 : self.disabledAlpha;
}

- (void)setNormalBackgroundColorStart:(UIColor *)normalBackgroundColorStart {
    if (normalBackgroundColorStart == nil) {
        return;
    }

    _normalBackgroundColorStart = normalBackgroundColorStart;

    [self p_applyNormalBackground];
}

- (void)setNormalBackgroundColorEnd:(UIColor *)normalBackgroundColorEnd {
    if (normalBackgroundColorEnd == nil) {
        return;
    }

    _normalBackgroundColorEnd = normalBackgroundColorEnd;

    [self p_applyNormalBackground];
}

- (void)setDisabledBackgroundColorStart:(UIColor *)disabledBackgroundColorStart {
    if (disabledBackgroundColorStart == nil) {
        return;
    }

    _disabledBackgroundColorStart = disabledBackgroundColorStart;

    [self p_applyDisabledBackground];
}

- (void)setDisabledBackgroundColorEnd:(UIColor *)disabledBackgroundColorEnd {
    if (disabledBackgroundColorEnd == nil) {
        return;
    }

    _disabledBackgroundColorEnd = disabledBackgroundColorEnd;

    [self p_applyDisabledBackground];
}

- (void)p_applyNormalBackground {
    if (self.normalBackgroundColorStart == nil || self.normalBackgroundColorEnd == nil) {
        return;
    }

    if ([self.normalBackgroundColorStart isEqual:self.normalBackgroundColorEnd]) {

        [self p_applySolidColor:self.normalBackgroundColorStart forState:UIControlStateNormal];
        [self p_applySolidColor:self.normalBackgroundColorStart forState:UIControlStateHighlighted];
    } else {
        self.isGradientNormalBackground = YES;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)p_applyDisabledBackground {
    if (self.disabledBackgroundColorStart == nil || self.disabledBackgroundColorEnd == nil) {
        return;
    }

    if ([self.disabledBackgroundColorStart isEqual:self.disabledBackgroundColorEnd]) {
        [self p_applySolidColor:self.disabledBackgroundColorStart forState:UIControlStateDisabled];
    } else {
        self.isGradientDisabledBackground = YES;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)p_applySolidColor:(UIColor *)color
                 forState:(UIControlState)state {

    UIImage *backgroundImage = [UIImage cj_imageWithColor:color];
    [self setBackgroundImage:backgroundImage forState:state];
}

- (void)p_applyGradientStyleWithSize:(CGSize)size
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                            forState:(UIControlState)state {
    if (!startColor || !endColor) {
        return;
    }

    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return;
    }
    
    CGPoint startP = CGPointMake(0, size.height / 2);
    CGPoint endP = CGPointMake(size.width, size.height / 2);
    if (self.isVerticalGradientFilling) {
        startP = CGPointMake(size.width / 2, 0);
        endP = CGPointMake(size.width / 2, size.height);
    }
    UIImage *backgroundImage = [self.class p_imageFromGradientColors:@[startColor, endColor] size:size startPoint:startP endPoint:endP];
    [self setBackgroundImage:backgroundImage forState:state];
}

+ (UIImage *)p_imageFromGradientColors:(NSArray <UIColor *> *)colors size:(CGSize)size startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat locations[2] = {0.0, 1.0};
    NSMutableArray *cgColorArray = [[NSMutableArray alloc] initWithCapacity:colors.count];
    [colors enumerateObjectsUsingBlock:^(UIColor *obj, NSUInteger idx, BOOL *stop) {
        [cgColorArray addObject:(id)obj.CGColor];
    }];
    CFArrayRef cgColorArrayRef = (__bridge CFArrayRef)cgColorArray;

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, cgColorArrayRef, locations);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    return image;
}

- (void)p_installDefaultAppearance {
    UIColor *defaultBackgroundColor = [UIColor cj_fe2c55ff];
    
    CJPayStyleButton *appearance = [CJPayStyleButton appearance];
    if (appearance.normalBackgroundColorStart == nil) {
        self.normalBackgroundColorStart = defaultBackgroundColor;
    }

    if (appearance.normalBackgroundColorEnd == nil) {
        self.normalBackgroundColorEnd = defaultBackgroundColor;
    }
    
    if (appearance.disabledBackgroundColorStart == nil) {
        self.disabledBackgroundColorStart = [defaultBackgroundColor colorWithAlphaComponent:0.5];
    }
    if (appearance.disabledBackgroundColorEnd == nil) {
        self.disabledBackgroundColorEnd = [defaultBackgroundColor colorWithAlphaComponent:0.5];
    }
    
    if (appearance.titleColor == nil) {
        self.titleColor = [UIColor whiteColor];
    }
    
    if (appearance.cornerRadius <= 0) {
        self.cornerRadius = 5;
    }
    
    if (appearance.disabledAlpha <= 0) {
        self.disabledAlpha = 0.5;
    }
}

@end
