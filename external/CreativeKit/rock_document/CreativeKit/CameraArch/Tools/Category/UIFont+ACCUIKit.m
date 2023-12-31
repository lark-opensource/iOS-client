//
//  UIFont+ACCUIKit.m
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/8/28.
//
#import <objc/runtime.h>
#import "UIFont+ACCUIKit.h"

static BOOL enableAutomicLineSpacing = NO;

@implementation UIFont (ACCUIKit)

+ (void)accui_setEnableAutomaticLineSpacing:(BOOL)enableLineSpacing
{
    enableAutomicLineSpacing = enableLineSpacing;
}

+ (UIFont *)accui_fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    UIFont *font = [self fontWithName:fontName size:fontSize];
    [font setAccui_lineHeightFromFontSize:fontSize];
    return font;
}

+ (NSInteger)accui_standardFontSizeForSize:(CGFloat)fontSize
{
    if (fontSize >= 36) {
        return 36;
    } else if (fontSize >= 32) {
        return 32;
    } else if (fontSize >= 28) {
        return 28;
    } else if (fontSize >= 24) {
        return 24;
    } else if (fontSize >= 20) {
        return 20;
    } else if (fontSize >= 17) {
        return 17;
    } else if (fontSize >= 15) {
        return 15;
    } else if (fontSize >= 14) {
        return 14;
    } else if (fontSize >= 13) {
        return 13;
    } else if (fontSize >= 12) {
        return 12;
    } else if (fontSize >= 11) {
        return 11;
    } else {
        return 10;
    }
}

- (void)setAccui_lineSpacing:(CGFloat)accui_lineSpacing
{
    objc_setAssociatedObject(self, @selector(accui_lineSpacing), @(accui_lineSpacing), OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)accui_lineSpacing
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setAccui_lineHeightFromFontSize:(NSInteger)fontSize
{
    if (!enableAutomicLineSpacing) {
        return;
    }
    switch (fontSize) {
        case 20:
            self.accui_lineSpacing = 24 - self.lineHeight;
            break;
        case 17:
            self.accui_lineSpacing = 20 - self.lineHeight;
            break;
        case 15:
            self.accui_lineSpacing = 18 - self.lineHeight;
            break;
        case 14:
            self.accui_lineSpacing = 17 - self.lineHeight;
            break;
        case 13:
            self.accui_lineSpacing = 16 - self.lineHeight;
            break;
        case 12:
            self.accui_lineSpacing = 15 - self.lineHeight;
            break;
            
        default:
            break;
    }
}

@end
