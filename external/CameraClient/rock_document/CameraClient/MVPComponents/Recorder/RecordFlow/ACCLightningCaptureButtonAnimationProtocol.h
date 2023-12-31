//
//  ACCLigntht.h
//  CameraClient
//
//  Created by limeng on 2021/5/25.
//

#ifndef ACCLigntht_h
#define ACCLigntht_h

#import <UIKit/UIKit.h>
#import "AWECaptureButtonAnimationView.h"
#import <CreationKitArch/ACCRecordMode.h>

@protocol ACCCaptureButtonAnimationViewDelegate <AWECaptureButtonAnimationViewDelegate>

@optional

/// 录制按钮由点按模式变为长按模式
- (void)animationViewDidSwitchToHoldSubtype;
/// 录制按钮点按触发
- (void)animationViewDidReceiveTap;
/// 是否允许点击拍照
- (BOOL)canTakePhotoWithTap;

/// YES: Tap to record NO: tap take Photo
/// YES: 点击录像 NO: 点击拍照
- (BOOL)isTapAndHoldToRecordCase;

@end

@protocol ACCLightningCaptureButtonAnimationProtocol <ACCCaptureButtonAnimationProtocol>

// 重写ACCCaptureButtonAnimationProtocol中的delegate类型
@property (nonatomic, weak) id<ACCCaptureButtonAnimationViewDelegate> delegate;

- (void)updateAnimatedRecordButtonCenter:(CGPoint)center;

@optional
#pragma mark 执行 touchesBegan 任务
- (void)executeTouchesBeganTask;
#pragma mark 执行 touchesEnd 任务
- (void)executeTouchesEndTask;

@end

#endif /* ACCLigntht_h */
