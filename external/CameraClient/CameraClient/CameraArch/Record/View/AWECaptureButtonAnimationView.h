//
//  AWECaptureButtonAnimationView.h
//  Aweme
//
//  Created by Liu Bing on 11/28/16.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEAnimatedRecordButton.h>
#import <CreationKitArch/ACCRecordMode.h>
#import <CreationKitArch/AWESwitchRecordModelDefine.h>

@protocol ACCCaptureButtonAnimationProtocol;

@protocol AWECaptureButtonAnimationViewDelegate <NSObject>
- (BOOL)animationShouldBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)animationDidBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)animationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)animationDidMoved:(CGPoint)touchPoint;
@optional
- (void)touchBeginWithAnimationDisabled:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (BOOL)shouldRespondsToAnimationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView;

- (void)switchToHoldSubtype;

@end

@protocol ACCCaptureButtonAnimationProtocol<NSObject>
@property (nonatomic, strong, readonly) ACCRecordMode *recordMode;
@property (nonatomic, assign) BOOL isCountdowning;
@property (nonatomic, assign, readonly) AWERecordModeMixSubtype mixSubtype;
@property (nonatomic, copy) void (^trackRecordVideoEventBlock)(void);
@property (nonatomic, weak) id<AWECaptureButtonAnimationViewDelegate> delegate;
@property (nonatomic, assign) BOOL forbidUserPause;
@property (nonatomic, assign) BOOL supportGestureWhenHidden;

- (void)switchToMode:(ACCRecordMode *)recordMode;
- (void)switchToMode:(ACCRecordMode *)recordMode force:(BOOL)force;
- (void)startCountdownMode;
- (void)endCountdownModeIfNeed;
- (void)stop;
@optional
@property (nonatomic, assign) BOOL animationEnabled;

#pragma mark 执行 touchesBegan 任务
- (void)executeTouchesBeganTask;
#pragma mark 执行 touchesEnd 任务
- (void)executeTouchesEndTask;

- (void)startLoadingAnimation;
- (void)stopLoadingAnimation;

@end

@interface AWECaptureButtonAnimationView : UIView <ACCCaptureButtonAnimationProtocol>

@property (nonatomic, weak) UIButton *captureButton;
@property (nonatomic, weak) UIButton *captureShowTipButton; // This button is used for positioning, because the position of the capturebutton will change with the movement of the finger, while the position of the captureshowtip button will not change
@property (nonatomic, strong) AWEAnimatedRecordButton *animatedRecordButton;
- (void)updateAnimatedRecordButtonCenter:(CGPoint)center;

@end
