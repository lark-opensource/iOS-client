//
//  AWERecognitionModeSwitchButton.m
//  AWEStudio
//
//  Created by yanjianbo on 2021/06/01.
//  Copyright © 2021年 bytedance. All rights reserved.
//

#import "AWERecognitionModeSwitchButton.h"
#import "ACCRecognitionConfig.h"
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation AWERecognitionModeSwitchButton

- (instancetype)initWithType:(ACCAnimatedButtonType)btnType
{
    self = [super initWithType:btnType];
    if (self) {
        [self setImage:ACCResourceImage(@"icon_camera_recognition_on") forState:UIControlStateNormal];
    }
    return self;
}

- (void)setIsOn:(BOOL)isOn{
    _isOn = isOn;
    [self setImage:self.currentIcon forState:UIControlStateNormal];
}


- (UIImage *)currentIcon
{
    NSString *iconName;
    if ([ACCRecognitionConfig onlySupportCategory]){
        iconName = self.isOn ? @"icon_category_recognition_on": @"icon_category_recognition_off";
    }else{
        iconName = self.isOn ? @"icon_camera_recognition_on": @"icon_camera_recognition_off";
    }

    return ACCResourceImage(iconName);
}

- (void)toggle
{
    self.isOn = !self.isOn;
}
@end
