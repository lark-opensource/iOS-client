//
//  MODBeautyComponentConfig.m
//  CameraClient
//
//  Created by haoyipeng on 2022/1/10.
//  Copyright © 2022 chengfei xiao. All rights reserved.
//

#import "MODBeautyComponentConfig.h"
#import <CreationKitComponents/ACCBeautyManager.h>

@implementation MODBeautyComponentConfig

- (BOOL)enableSetBeautySwitchButton {
    return NO;
}

- (BOOL)useBeautySwitch {
    return NO;
}

- (BOOL)needSetBeautyButtonImage {
    return NO;
}

- (BOOL)canAddTargetForModernBeautyButton {
    return YES;
}

- (NSString *)beautyIconName {
    return @"icon_camera_beauty";
}

- (BOOL)availableFilterBeautyWithCategoryWrapper:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    return YES;
}

- (BOOL)enableClearAllBeautyEffects {
    return YES;
}

- (BOOL)useSavedValue {
    return NO;
}

#pragma mark - TT 美颜配置，抖音未使用，ignore temporarily
- (BOOL)needConfigAllBeautifyInfo {
    return NO;
}

- (BOOL)shouldReturnABBeautyValue {
    return YES;
}

- (BOOL)canHandleApplyStickerExtralCase {
    return YES;
}

- (BOOL)canApplyBeautify {
    return NO;
}

- (BOOL)canApplyBeautySmoothType {
    return NO;
}

- (BOOL)shouldAddBeautyParams {
    return YES;
}

// replace condition `!ACC_IS_IN_MUSICALLY_REGION`
- (BOOL)shouldDisableBeautifyForSticker {
    return NO;
}

- (NSString *)beautyPanelName
{
    return @"beauty";
}

@end
