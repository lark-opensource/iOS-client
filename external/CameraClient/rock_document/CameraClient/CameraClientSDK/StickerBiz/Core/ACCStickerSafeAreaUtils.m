//
//  ACCStickerSafeAreaUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/8/16.
//

#import "ACCStickerSafeAreaUtils.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCStickerSafeAreaView.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIDevice+ACCHardware.h>

@implementation ACCStickerSafeAreaUtils

+ (UIEdgeInsets)safeAreaInsetsWithPlayerFrame:(CGRect)playerFrame containerFrame:(CGRect)containerFrame
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    CGFloat playerWidth = CGRectGetWidth(playerFrame), playerHeight = CGRectGetHeight(playerFrame);
    CGFloat containerWidth = CGRectGetWidth(containerFrame), containerHeight = CGRectGetHeight(containerFrame);
    
    CGFloat wGap = 0.f;
    // adaption for mask horizontally
    if (playerWidth > 0 && playerHeight > 0 && containerWidth > playerWidth) {
        wGap = (containerWidth - playerWidth) / 2;
    }
    insets.left = 20 + wGap;
    insets.right = containerWidth - (56 + wGap + ACCStickerContainerSafeAreaLineWidth);
    
    CGFloat bottomOffset = -200;
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            bottomOffset = - ACC_IPHONE_X_BOTTOM_OFFSET - 73 - 130;
            if ([UIDevice acc_isIPhoneXsMax]) {
                bottomOffset = - ACC_IPHONE_X_BOTTOM_OFFSET - 85 - 130;
            }
        }
    }
    insets.bottom = containerHeight + bottomOffset;

    CGFloat topOffset = 48;
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            topOffset = 64;
        }
    }
    insets.top = ACC_STATUS_BAR_NORMAL_HEIGHT + topOffset + ACCStickerContainerSafeAreaLineWidth;
    
    return insets;
}

@end
