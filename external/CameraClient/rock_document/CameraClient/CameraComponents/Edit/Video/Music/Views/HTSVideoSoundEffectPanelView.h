//
//  LiveBGMControlPanelWindow.h
//  LiveStreaming
//
//  Created by wangguan.02 on 16/5/17.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

struct _HTSAudioVolume {
    float musicVolume;
    float voiceVolume;
};
typedef struct _HTSAudioVolume HTSAudioVolume;
extern HTSAudioVolume const HTSAudioVolumeDefault;



@class HTSVideoSoundEffectPanelView;
@protocol HTSVideoSoundEffectPanelViewDelegate <NSObject>

- (void)htsVideoSoundEffectPanelView:(HTSVideoSoundEffectPanelView *)panelView sliderValueDidFinishChangeFromVoiceSlider:(BOOL)fromVoiceSlider;

@end

@protocol HTSVideoSoundEffectPanelViewActionDelegate <NSObject>

- (BOOL)enableMusicPanelVertical;
- (BOOL)enableCheckbox;

@optional
- (void)volumeViewBackButtonTapped;
- (void)bgmSliderDidFinishSlidingWithValue:(float)value;
- (void)voiceSliderDidFinishSlidingWithValue:(float)value;

@end

@interface HTSVideoSoundEffectPanelView : UIView

- (instancetype)initWithFrame:(CGRect)frame useBlurBackground:(BOOL)useBlurBackground;

- (void)setVoiceLabelTitle:(NSString *)title;
- (void)setBGMLabelTitle:(NSString *)title;

- (void)close;
- (void)show;

// 面板优化需求，调整UI
- (void)adjustForMusicSelectPanelOptimizationWithDelegate:(id<HTSVideoSoundEffectPanelViewActionDelegate>)delegate;


/**
 *  KVOable
 */
@property (nonatomic) float voiceVolume;
@property (nonatomic) float musicVolume;
@property (nonatomic, weak, readonly) UISlider *bgmSlider;
@property (nonatomic, weak, readonly) UISlider *voiceSlider;
@property (nonatomic, weak) id<HTSVideoSoundEffectPanelViewDelegate> delegate;

@property (nonatomic, assign) BOOL userControlVoiceDisable; // 用户控制原声的voiceSlider是否可用
@property (nonatomic, assign) BOOL preconditionVoiceDisable; // 外部前置条件控制原声voiceSlider是否可用

@property (nonatomic, assign) BOOL preconditionBgmMusicDisable; // 外部前置条件控制配乐bgmSlider是否可用

@end
