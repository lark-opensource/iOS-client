//
//  AWERecognitionModeSwitchButton.h
//  AWEStudio
//
//  Created by yanjianbo on 2021/06/01.
//  Copyright © 2021年 bytedance. All rights reserved
//

#import <TTVideoEditor/VERecorder.h>
#import <CreativeKit/ACCAnimatedButton.h>

@interface AWERecognitionModeSwitchButton : ACCAnimatedButton

@property (nonatomic, assign) BOOL isOn;
@property (nonatomic,   weak) UIView *bubble;

- (void)toggle;

@end
