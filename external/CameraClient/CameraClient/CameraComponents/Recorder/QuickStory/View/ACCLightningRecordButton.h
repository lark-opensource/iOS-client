//
//  ACCLightningRecordButton.h
//  RecordButton
//
//  Created by shaohua on 2020/8/2.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCLightningRecordAnimatable.h"
#import "ACCLightningRecordRingView.h"
#import "ACCLightningRecordBlurView.h"
#import "AWEStudioVideoProgressView.h"
#import "ACCLightningRecordRedView.h"
#import "ACCLightningRecordWhiteView.h"
#import "ACCLightningRecordAlienationView.h"

#import <CreationKitArch/AWEAnimatedRecordButton.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCLightningRecordButton : UIView <ACCLightningRecordAnimatable, AWEVideoProgressViewProtocol, AWEVideoProgressReshootProtocol>

@property (nonatomic, strong) ACCLightningRecordRingView *ringView;
@property (nonatomic, strong) ACCLightningRecordRedView *redView;
@property (nonatomic, strong) ACCLightningRecordAlienationView *alienationView;
@property (nonatomic, assign) BOOL showLightningView;
@property (nonatomic, assign) BOOL showMicroView;
@property (nonatomic, assign) BOOL reshootMode;
@property (nonatomic, strong) ACCRecordMode *recordMode;
@property (nonatomic, assign) AWERecordModeMixSubtype mixSubtype;
@property (nonatomic, assign) CGFloat maxDuration;
@property (nonatomic, weak) RACSubject<NSNumber *> *switchModelSubject;

- (void)hideCenterView;
- (void)hideCenterViewWhenRecording:(BOOL)hide; // 录制中不显示红色小方块

@end

NS_ASSUME_NONNULL_END
