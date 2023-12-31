//
//  ACCRecordLayoutGuide.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/12.
//

#import "ACCRecordLayoutGuide.h"
#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"

@implementation ACCRecordLayoutGuide

- (UIEdgeInsets)hitTestEdgeInsets
{
    return UIEdgeInsetsMake(-19, -19, -19, -19);
}

- (CGFloat)containerHeight
{
    return CGRectGetHeight(self.containerView.frame);
}

- (CGFloat)containerWidth
{
    return CGRectGetWidth(self.containerView.frame);
}

- (CGFloat)recordButtonWidth
{
    return 80;
}

- (CGFloat)recordButtonHeight
{
    return 80;
}

- (CGFloat)recordButtonBottomOffset
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return -100 - ACC_IPHONE_X_BOTTOM_OFFSET;
    } else {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            CGFloat scale = ACC_SCREEN_WIDTH / 375.0;
            return -122 * scale;
        } else {
            return -50;
        }
    }
}

- (CGFloat)recordButtonCenterY
{
    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    return [self containerHeight] + [self recordButtonBottomOffset] - 0.5 * [self recordButtonHeight] + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0);
}

- (CGFloat)recordButtonSwitchViewHeight
{
    return 40;
}

- (CGFloat)recordButtonSwitchViewBottomOffset
{
    return - ACC_IPHONE_X_BOTTOM_OFFSET - 6;
}

- (CGFloat)recordButtonSwitchViewCenterY
{
    return [self containerHeight] + [self recordButtonSwitchViewBottomOffset] - 0.5 * [self recordButtonSwitchViewHeight];
}

- (CGFloat)sideButtonHeight
{
    return 32;
}

- (CGFloat)sideButtonWidth
{
    return 32;
}

- (CGFloat)bottomCircleButtonHeight
{
    return 34;
}

- (CGFloat)bottomCircleButtonWidth
{
    return 34;
}

- (CGFloat)sideCircleButtonHeight
{
    return 36;
}

- (CGFloat)sideCircleButtonWidth
{
    return 36;
}

- (CGFloat)bottomSideButtonMargin
{
    return 12;
}

- (CGFloat)bottomSideButtonCenterXOffset
{
    return 28;
}

- (CGFloat)bottomSideButtonSwitchViewSpace
{
    return 6;
}

- (CGFloat)sideButtonCenterXOffset
{
    return ([self containerWidth] - [self recordButtonWidth]) / 4;
}

- (CGFloat)sideButtonLabelSpace
{
    return 6;
}

- (CGFloat)deleteButtonWidth
{
    return 40;
}
- (CGFloat)deleteButtonHeight
{
    return 40;
}

- (CGFloat)bottomDeleteButtonHeight
{
    return 44;
}

- (CGFloat)bottomDeleteButtonIconHeight
{
    return 20;
}

- (CGFloat)bottomDeleteButtonIconWidth
{
    return 22;
}

- (CGFloat)bottomDeleteButtonIconTitleSpace
{
    return 4;
}

- (CGFloat)completeButtonWidth
{
    return 40;
}

- (CGFloat)completeButtonHeight;
{
    return 40;
}

- (CGFloat)recordFlowControlEvenSpace
{
    return (([self containerWidth] - [self recordButtonWidth]) * 0.5 - [self deleteButtonWidth] - [self completeButtonWidth]) / 3;
}

- (CGFloat)propPanelHeight
{
    return 80;
}

- (CGFloat)speedControlMargin
{
    return 32.5;
}

- (CGFloat)speedControlHeight
{
    return 36;
}

- (CGFloat)speedControlRecordBottomSpace
{
    return 32; 
}

- (CGFloat)speedControlTop
{
    CGFloat h = [self speedControlHeight];
    CGFloat y = [self recordButtonCenterY] - 0.5 * [self recordButtonHeight] - [self speedControlRecordBottomSpace] - h;
    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        y -= 57 - 32; // new distance - old distance with top of recordButton
    }
    return y;
}

- (CGFloat)propBubbleHeight
{
    return 64;
}

- (CGFloat)propBubbleWidth
{
    return self.containerWidth - 16;
}

- (CGFloat)propTrayViewMargin
{
    return 56;
}

- (CGFloat)propTrayViewHeight
{
    return 64;
}

- (CGFloat)commerceEnterViewHeight
{
    return 33;
}

- (CGFloat)commerceEnterViewBottomSpace
{
    return 24;
}

@end
