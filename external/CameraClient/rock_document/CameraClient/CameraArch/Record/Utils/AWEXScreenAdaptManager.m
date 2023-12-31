//
//  AWEXScreenAdaptManager.m
//  Pods
//
//  Created by li xingdong on 2019/3/15.
//

#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCConfigKeyDefines.h>

NS_INLINE CGRect FrameForFullDisplay() {
    return CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - 49 - ACC_SafeAreaInsets.bottom);
}

@implementation AWEXScreenAdaptManager

+ (BOOL)needAdaptScreen
{
    return ([UIDevice acc_isNotchedScreen] || [UIDevice acc_isIPhoneXsMax]);
}

+ (CGRect)standPlayerFrame
{
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        if (ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay) {
            return FrameForFullDisplay();
        }

        CGFloat ratio = 16.0 / 9.0;
        CGFloat width = ACC_SCREEN_WIDTH;

        // ratio + 0.0005 (3位精度) 是为了处理四舍五入的问题，导致编辑页画幅的圆角变成直角
        CGFloat height = (ratio + 0.0005) * width;
        return CGRectMake(0, ACC_SafeAreaInsets.top, width , height);
    } else {
        return CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
    }
}

+ (CGRect)customFullFrame
{
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        if (ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay) {
            return FrameForFullDisplay();
        }
        const CGFloat top = ACC_STATUS_BAR_NORMAL_HEIGHT - 6.0;
        return CGRectMake(0, top, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - top - ACC_IPHONE_X_BOTTOM_OFFSET);
    } else {
        return CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
    }
}

+ (CAShapeLayer *)maskLayerWithPlayerFrame:(CGRect)playerFrame
{
    CAShapeLayer *layer = nil;
    if ([AWEXScreenAdaptManager needAdaptScreen] &&
        ACC_FLOAT_EQUAL_TO([AWEXScreenAdaptManager standPlayerFrame].size.height, playerFrame.size.height) &&
        ACC_FLOAT_LESS_THAN([AWEXScreenAdaptManager standPlayerFrame].size.width, playerFrame.size.width)) {
        layer = [CAShapeLayer layer];
        
        CGRect rect = CGRectMake((playerFrame.size.width - [AWEXScreenAdaptManager standPlayerFrame].size.width) / 2.0, 0, [AWEXScreenAdaptManager standPlayerFrame].size.width, [AWEXScreenAdaptManager standPlayerFrame].size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(12.0, 12.0)];
        layer.path = path.CGPath;
    }
    
    return layer;
}

+ (BOOL)aspectFillForRatio:(CGSize)ratio isVR:(BOOL)isVR
{
    if (isVR) {
        return NO;
    }
    
    if (ratio.height == 0.0) {
        return YES;
    }
    
    CGFloat rate = ratio.width / ratio.height;
    if (isinf(rate) || isnan(rate)) {
        return YES;
    }
    
    if (rate > 9.2 / 16.) {
        return NO;
    }
    
    static BOOL isAspectFillScreen = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat rate = screenSize.width / screenSize.height;
        
        if (rate > 0.75) {
            isAspectFillScreen = NO;
        } else if ((0.75 - rate) < (rate - 9./16)) {
            isAspectFillScreen = NO;
        }
    });
    
    return isAspectFillScreen;
}

@end
