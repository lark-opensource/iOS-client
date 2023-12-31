//
//  AWECameraContainerIconManager.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2019/1/8.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "AWECameraContainerIconManager.h"
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation AWECameraContainerIconManager

+ (UIImage *)selectMusicButtonNormalImage
{
    return ACCResourceImage(@"icon_camera_sounds");
}

+ (UIImage *)selectMusicButtonLoadingImage
{
    return ACCResourceImage(@"iconMusicLoading_ai");
}

+ (UIImage *)selectMusicButtonSelectedImage
{
    return ACCResourceImage(@"icon_camera_sounds");
}

+ (UIImage *)duetLayoutButtonImage
{
    return ACCResourceImage(@"duet_layout_left_right");
}

+ (UIImage *)beautyButtonNormalImage
{
    return ACCResourceImage(@"iconBeautyOff2New");
}

+ (UIImage *)beautyButtonSelectedImage
{
    return ACCResourceImage(@"iconBeautyOn2New");
}

+ (UIImage *)modernBeautyButtonImage
{
    return ACCResourceImage(@"iconCameraBeautyNew");
}

+ (UIImage *)delayStartButtonImageWithMode:(AWEDelayRecordMode)mode
{
    NSString *imageName = (mode == AWEDelayRecordMode3S ? @"icon_camera_timer_3s" : @"icon_camera_timer_10s");
    return ACCResourceImage(imageName);
}

+ (UIImage *)moreButtonImage
{
    return ACCResourceImage(@"iconCameraMore");
}

+ (UIImage *)flashButtonAutoImage
{
    return ACCResourceImage(@"icon_camera_flash_auto");
}

+ (UIImage *)flashButtonOnImage
{
    return ACCResourceImage(@"icon_camera_flash_on");
}

+ (UIImage *)flashButtonOffImage
{
    return ACCResourceImage(@"icon_camera_flash_off");
}

+ (UIImage *)reactMicButtonNormalImage
{
    return ACCResourceImage(@"icon_edit_mic_off");
}

+ (UIImage *)reactMicButtonSelectedImage
{
    return ACCResourceImage(@"icon_edit_mic_on");
}

@end
