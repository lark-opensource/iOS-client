//
//  AWEAudioWaveformSliderView.h
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEAudioWaveformView.h"
#import "ACCCountDownModel.h"

extern CGFloat kAWEAudioWaveformBackgroundHeight;
extern CGFloat kAWEAudioWaveformBackgroundLeftMargin;

@class AWEAudioWaveformSliderView;
@class AWECountDownBarChartView;

@protocol AWEAudioWaveformSliderViewDelegate <NSObject>

@optional
- (void)audioWaveformSliderViewTouchBegin;
- (void)audioWaveformSliderViewTouchMoved;
- (void)audioWaveformSliderView:(AWEAudioWaveformSliderView *)sliderView touchEnd:(CGFloat)percent;

@end

@interface AWEAudioWaveformSliderView : UIView

@property (nonatomic, weak) id<AWEAudioWaveformSliderViewDelegate> delegate;
@property (nonatomic, strong, readonly) AWEAudioWaveformView *waveformView;
@property (nonatomic, strong, readonly) UIView *nomuiscWaveformView;//没有音乐时的波形图
@property (nonatomic, strong, readonly) AWECountDownBarChartView *waveBarView; // 音乐柱状波形图
@property (nonatomic, copy) void(^updateMusicBlock)(void);
@property (nonatomic, assign) BOOL usingBarView;

@property (nonatomic, strong) ACCCountDownModel *countDownModel;

- (void)updateWaveUIWithVolumes:(NSArray *)volumes;
- (void)updateRightLabelWithMaxDuration:(CGFloat)maxDuration;
- (void)moveControlViewByCodeWithPercent:(CGFloat)percent;
- (CGFloat)waveBarCountForFullWidth;

@end
