//
//  AWEAudioWaveformContainerView.h
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AWEAudioWaveformSliderView.h"
#import <CreationKitArch/ACCStudioDefines.h>
#import "ACCCountDownModel.h"

extern CGFloat kAWEAudioWaveformBackgroundHeight;
extern CGFloat kAWEAudioWaveformBackgroundLeftMargin;

@interface AWEAudioWaveformContainerView : UIView

@property (nonatomic, copy) void(^updateMusicBlock)(void);
@property (nonatomic, assign) BOOL usingBarView;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

- (instancetype)initWithFrame:(CGRect)frame model:(ACCCountDownModel *)model;

- (void)showNoMusicWaveformView:(BOOL)isShown;
- (void)updateWaveBarWithVolumes:(NSArray *)volumes;
- (void)updateHasRecordedLocation:(CGFloat)hasRecordedLocation;
- (void)updatePlayingLocation:(CGFloat)playingLocation;
- (void)updateBottomRightLableWithMaxDuration:(CGFloat)maxDuration;
- (void)updateToBePlayedLocation:(CGFloat)tobePlayedLocation;
- (void)setDelegateForSliderView:(id<AWEAudioWaveformSliderViewDelegate>)delegate;
- (CGFloat)waveBarCountForFullWidth;
- (void)setSelectedButtonWithDelayMode:(AWEDelayRecordMode)mode;

@end
