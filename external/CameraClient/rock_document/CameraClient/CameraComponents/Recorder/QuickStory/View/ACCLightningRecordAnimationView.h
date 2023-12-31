//
//  ACCLightningRecordAnimationView.h
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 8/6/20.
//

#import "ACCLightningRecordButton.h"
#import <CameraClient/ACCLightningCaptureButtonAnimationProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCLightningRecordAnimationViewConfig : NSObject

@property (nonatomic, strong) UIColor *idleCenterColor;
@property (nonatomic, strong) UIColor *recordingProgressColor;

@end

@interface ACCLightningRecordAnimationView : UIView <ACCLightningCaptureButtonAnimationProtocol>

@property (nonatomic, strong, readonly) ACCRecordMode *recordMode;

@property (nonatomic, assign, readonly) AWERecordModeMixSubtype mixSubtype;

@property (nonatomic, strong) ACCLightningRecordButton *animatedRecordButton;

@property (nonatomic, strong) ACCLightningRecordAnimationViewConfig *config;

- (void)stopWithIgnoreProgress:(BOOL)ignoreProgress;

@end

NS_ASSUME_NONNULL_END
