//
//  UIButton+ACCAdditions.m
//  CameraClient
//
//  Created by lxp on 2019/11/17.
//

#import "UIButton+ACCAdditions.h"
#import <CreativeKit/ACCMacros.h>
#import "NSObject+ACCSwizzle.h"
#import <objc/runtime.h>

static NSString * const ACCUIButtonBorderColorKey = @"ACCUIButtonBorderColorKey";
static NSString * const ACCUIButtonAlphaKey = @"ACCUIButtonAlphaKey";
static NSString * const ACCUIButtonAlphaTransitionTimeKey = @"ACCUIButtonAlphaTransitionTimeKey";

@implementation UIButton (CameraClient)

+ (void)load
{
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(pointInside:withEvent:) targetSelector:@selector(acc_pointInside:withEvent:)];
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(setHighlighted:) targetSelector:@selector(acc_setHighlighted:)];
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(setAlpha:) targetSelector:@selector(acc_setAlpha:)];
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(setSelected:) targetSelector:@selector(acc_setSelected:)];
}

@dynamic tap_block;
static NSString *tap_blockKey = @"tap_blockKey";

- (void)acc_centerTitleAndImageWithSpacing:(CGFloat)spacing
{
    CGFloat insetAmount = spacing / 2.0;
    self.imageEdgeInsets = UIEdgeInsetsMake(0, -insetAmount, 0, insetAmount);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, insetAmount, 0, -insetAmount);
    self.contentEdgeInsets = UIEdgeInsetsMake(0, insetAmount, 0, insetAmount);
}

- (void)acc_centerTitleAndImageWithSpacing:(CGFloat)spacing contentEdgeInsets:(UIEdgeInsets)contentEdgeInsets
{
    CGFloat insetAmount = spacing / 2.0;
    self.imageEdgeInsets = UIEdgeInsetsMake(0, -insetAmount, 0, insetAmount);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, insetAmount, 0, -insetAmount);

    contentEdgeInsets.left += insetAmount;
    contentEdgeInsets.right += insetAmount;
    self.contentEdgeInsets = contentEdgeInsets;
}

-(void)acc_centerButtonAndImageWithSpacing:(CGFloat)spacing
{

    self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;

    CGSize buttonSize = self.frame.size;

    CGSize imageSize = self.imageView.frame.size;
    CGSize labelSize = self.titleLabel.frame.size;

    self.imageEdgeInsets = UIEdgeInsetsMake(ceil((buttonSize.height - imageSize.height - labelSize.height) / 2),
                                            (buttonSize.width - imageSize.width) / 2,
                                            0,
                                            0);
    self.titleEdgeInsets = UIEdgeInsetsMake(ceil(buttonSize.height - imageSize.height - labelSize.height) / 2 + imageSize.height + spacing,
                                            -(imageSize.width),
                                            0,0);
}

- (void)setAcc_hitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets
{
    NSValue *value = [NSValue valueWithUIEdgeInsets:hitTestEdgeInsets];
    objc_setAssociatedObject(self, @selector(acc_hitTestEdgeInsets), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)acc_hitTestEdgeInsets
{
    NSValue *value = objc_getAssociatedObject(self, @selector(acc_hitTestEdgeInsets));
    if (value) {
        return [value UIEdgeInsetsValue];
    } else {
        return UIEdgeInsetsZero;
    }
}

- (BOOL)acc_pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    UIEdgeInsets hitTestEdgeInsets = self.acc_hitTestEdgeInsets;
    if (UIEdgeInsetsEqualToEdgeInsets(hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden || !self.alpha) {
        return [self acc_pointInside:point withEvent:event];
    }
    CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

- (void)setAcc_disableBlock:(void (^)(void))acc_disableBlock
{
    objc_setAssociatedObject(self, @selector(acc_disableBlock), acc_disableBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(void))acc_disableBlock
{
    return objc_getAssociatedObject(self, @selector(acc_disableBlock));
}

+ (UIImage *)acc_imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);

    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    //
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)acc_setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    UIImage *imageFromColor = [UIButton acc_imageWithColor:color];
    //
    [self setBackgroundImage:imageFromColor forState:state];
}

- (void)acc_setAlpha:(CGFloat)alpha forState:(UIControlState)state
{
    NSMutableDictionary *alphaSettings = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaKey));
    if (!alphaSettings) {
        alphaSettings = [NSMutableDictionary new];
    }
    [alphaSettings setObject:@(alpha) forKey:@(state)];
    objc_setAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaKey), alphaSettings, OBJC_ASSOCIATION_RETAIN);

    if (state == UIControlStateNormal) {
        [self acc_setAlpha: alpha];
    }
}

- (void)acc_setAlpha:(CGFloat)alpha {
    NSNumber *currentKey = self.isSelected ? @(UIControlStateSelected) : (self.isHighlighted ? @(UIControlStateHighlighted) : @(UIControlStateNormal));
    NSMutableDictionary <NSNumber *, NSNumber *> *alphaSettings = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaKey));
    if (alphaSettings && alphaSettings[currentKey]) {
        if (self.acc_alphaTransitionTime == 0) {
            [self acc_setAlpha:alphaSettings[currentKey].floatValue];
        } else {
            [UIView animateWithDuration:self.acc_alphaTransitionTime animations:^{
                [self acc_setAlpha:alphaSettings[currentKey].floatValue];
            }];
        }
    }else {
        [self acc_setAlpha:alpha];
    }
}

- (void)acc_setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    NSMutableDictionary *borderColors = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonBorderColorKey));
    if (!borderColors) {
        borderColors = [NSMutableDictionary new];
    }
    if (color) {
        [borderColors setObject:color forKey:@(state)];
    } else {
        [borderColors removeObjectForKey:@(state)];
    }
    objc_setAssociatedObject(self, (__bridge const void *)(ACCUIButtonBorderColorKey), borderColors, OBJC_ASSOCIATION_RETAIN);

    if (state == UIControlStateNormal) {
        self.layer.borderColor = color.CGColor;
    }
}

- (void)acc_setAlphaTransitionTime:(NSTimeInterval)time
{
    objc_setAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaTransitionTimeKey), @(time), OBJC_ASSOCIATION_RETAIN);
}

- (NSTimeInterval)acc_alphaTransitionTime
{
    NSNumber *time = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaTransitionTimeKey));
    if (time != nil) {
        return time.floatValue;
    }
    return 0;
}
    
- (void)setTap_block:(ACCUIButtonTapBlock)tap_block
{
    objc_setAssociatedObject(self, &tap_blockKey, tap_block, OBJC_ASSOCIATION_COPY);
    [self addTarget:self action:@selector(accTap_invokeTouchUpInsideBlock:) forControlEvents:UIControlEventTouchUpInside];
}

- (ACCUIButtonTapBlock)tap_block
{
    return objc_getAssociatedObject(self, &tap_blockKey);
}

- (void)accTap_invokeTouchUpInsideBlock:(id)sender
{
    ACCBLOCK_INVOKE(self.tap_block);
}

- (void)acc_setSelected:(BOOL)selected
{
    [self acc_setSelected:selected];
    [self acc_updateState];
}

- (void)acc_setHighlighted:(BOOL)highlighted
{
    [self acc_setHighlighted:highlighted];
    [self acc_updateState];
}

- (void)acc_updateState
{
    NSNumber *currentKey = self.isSelected ? @(UIControlStateSelected) : (self.isHighlighted ? @(UIControlStateHighlighted) : @(UIControlStateNormal));

    NSMutableDictionary <NSNumber *, UIColor *> *borderColors = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonBorderColorKey));
    if (borderColors && borderColors[currentKey]) {
        self.layer.borderColor = borderColors[currentKey].CGColor;
    }

    NSMutableDictionary <NSNumber *, NSNumber *> *alphaSettings = objc_getAssociatedObject(self, (__bridge const void *)(ACCUIButtonAlphaKey));
    if (alphaSettings && alphaSettings[currentKey]) {
        if (self.acc_alphaTransitionTime == 0) {
            [self acc_setAlpha:alphaSettings[currentKey].floatValue];
        } else {
            [UIView animateWithDuration:self.acc_alphaTransitionTime animations:^{
                [self acc_setAlpha:alphaSettings[currentKey].floatValue];
            }];
        }
    }
}

@end
