//
//  AWEFlashModeSwitchButton.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/2/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <TTVideoEditor/VERecorder.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <CreativeKit/ACCAnimatedButton.h>
@interface AWEFlashModeSwitchButton : ACCAnimatedButton

@property (nonatomic, assign) IESCameraFlashMode currentFlashMode;

- (void)switchFlashMode:(IESCameraFlashMode)flashMode;

@end
