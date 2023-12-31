//
//  UIView+ACCLayerColor.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import "UIView+ACCLayerColor.h"
#import "ACCUIDynamicColor.h"

#import <objc/runtime.h>

@implementation UIView (ACCLayerColor)

- (UIColor *)acc_layerBorderColor
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAcc_layerBorderColor:(UIColor *)color
{
    if (!color) {
        return;
    }
    if ([color isKindOfClass:ACCUIDynamicColor.class]) {
        objc_setAssociatedObject(self, @selector(acc_layerBorderColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.layer.borderColor = color.CGColor;
    }
}

- (UIColor *)acc_layerBackgroundColor
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAcc_layerBackgroundColor:(UIColor *)color
{
    if (!color) {
        return;
    }
    if ([color isKindOfClass:ACCUIDynamicColor.class]) {
        objc_setAssociatedObject(self, @selector(acc_layerBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.layer.backgroundColor = color.CGColor;
    }
}

@end
