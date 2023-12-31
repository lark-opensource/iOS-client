//
//  AWEFlashModeSwitchButton.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/2/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEFlashModeSwitchButton.h"
#import "AWECameraContainerIconManager.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation AWEFlashModeSwitchButton

- (instancetype)initWithType:(ACCAnimatedButtonType)btnType
{
    self = [super initWithType:btnType];
    if (self) {
        _currentFlashMode = IESCameraFlashModeOff;
        [self setImage:ACCResourceImage(@"icon_camera_flash_off") forState:UIControlStateNormal];
    }
    return self;
}

- (void)switchFlashMode:(IESCameraFlashMode)flashMode
{
    self.currentFlashMode = flashMode;
    [self setImage:[self iconImageForFlashMode:flashMode] forState:UIControlStateNormal];
}

- (UIImage *)iconImageForFlashMode:(IESCameraFlashMode)flashMode
{
    return [self flashModeIconImageMap][@(flashMode)];
}

- (NSDictionary<NSNumber *, UIImage *> *)flashModeIconImageMap
{
    return @{
             @(IESCameraFlashModeOff)  :  [AWECameraContainerIconManager flashButtonOffImage],
             @(IESCameraFlashModeOn)   :  [AWECameraContainerIconManager flashButtonOnImage] ,
             @(IESCameraFlashModeAuto) :  [AWECameraContainerIconManager flashButtonAutoImage],
             };
}


- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    NSString *status = (self.currentFlashMode == IESCameraFlashModeOn) ? @"已开启" : @"已关闭";
    return [NSString stringWithFormat:@"%@%@", ACCLocalizedCurrentString(@"flash"), status];
}

@end
