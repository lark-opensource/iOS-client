//
//  AWEReactMicrophoneButton.m
//  AWEStudio
//
//  Created by lixingdong on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEReactMicrophoneButton.h"
#import "AWECameraContainerIconManager.h"
#import <CreativeKit/ACCLanguageProtocol.h>

@interface AWEReactMicrophoneButton()

@property (nonatomic, assign, readwrite) BOOL isMuted;
@property (nonatomic, assign, readwrite) BOOL isLockedDisable;
@property (nonatomic, assign, readwrite) BOOL mementoMuted;

@end

@implementation AWEReactMicrophoneButton

- (void)mutedMicrophone:(BOOL)isMuted
{
    self.isMuted = isMuted;
    UIImage *image = [AWECameraContainerIconManager reactMicButtonSelectedImage];
    if (isMuted) {
        image = [AWECameraContainerIconManager reactMicButtonNormalImage];
    }
    
    [self setImage:image forState:UIControlStateNormal];
    [self setImage:image forState:UIControlStateSelected];
}

- (void)lockButtonDisable:(BOOL)disable shouldShow:(BOOL)show
{
    self.isLockedDisable = disable;
    if (!show) {
        self.alpha = 0;
    } else {
        if (disable) {
            self.alpha = 0.34;
        } else {
            self.alpha = 1.0;
        }
    }
}

- (void)setMemento:(BOOL)muted
{
    self.mementoMuted = muted;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"%@%@", ACCLocalizedCurrentString(@"microphone"), self.isMuted ? @"已关闭" : @"已开启"];
}

@end
