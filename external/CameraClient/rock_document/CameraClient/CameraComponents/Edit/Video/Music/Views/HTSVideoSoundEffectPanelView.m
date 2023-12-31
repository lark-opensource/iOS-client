//
//  LiveBGMControlPanelWindow.m
//  LiveStreaming
//
//  Created by wangguan.02 on 16/5/17.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "HTSVideoSoundEffectPanelView.h"
#import <CreationKitInfra/AWESlider.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import "ACCMusicPanelViewModel.h"

HTSAudioVolume const HTSAudioVolumeDefault = {1.f, 1.f};

static NSString * const HTSVideoSoundEffectPanelLabelColor = @"acc_sound_effect_panel_label_color";

@interface HTSVideoSoundEffectPanelView () <AWESliderDelegate>

@property (nonatomic, weak) AWESlider *bgmSlider;
@property (nonatomic, strong) UILabel *bgmLabel;
@property (nonatomic, weak) AWESlider *voiceSlider;
@property (nonatomic, strong) UILabel *voiceLabe;

// for music panel style
@property (nonatomic, weak) id<HTSVideoSoundEffectPanelViewActionDelegate> actionDelegate;
@property (nonatomic, assign) BOOL isAdjustForMusicPanel;

@end

@implementation HTSVideoSoundEffectPanelView

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, 180)];
}

- (instancetype)initWithFrame:(CGRect)frame useBlurBackground:(BOOL)useBlurBackground
{
    self = [super initWithFrame:frame];
    
    if (useBlurBackground) {
        [self acc_addBlurEffect];
    } else {
        self.backgroundColor = ACCResourceColor(ACCUIColorBGContainer3);
    }

    UILabel *voiceLabel = [[UILabel alloc] initWithFrame:CGRectMake(32, 44, 30, 30)];
    voiceLabel.text =  ACCLocalizedString(@"man_voice", @"原声");
    [voiceLabel setTextColor:ACCResourceColor(HTSVideoSoundEffectPanelLabelColor)];
    [voiceLabel setFont:[ACCFont() systemFontOfSize:12]];
    [voiceLabel sizeToFit];
    [self addSubview:voiceLabel];
    self.voiceLabe = voiceLabel;
    
    UILabel *bgmLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(voiceLabel.frame), CGRectGetMaxY(voiceLabel.frame) + 46,
                                              voiceLabel.frame.size.width, voiceLabel.frame.size.height)];
    bgmLabel.text = ACCLocalizedCurrentString(@"av_music");
    [bgmLabel setTextColor:ACCResourceColor(HTSVideoSoundEffectPanelLabelColor)];
    [bgmLabel setFont:[ACCFont() systemFontOfSize:12]];
    [bgmLabel sizeToFit];
    [self addSubview:bgmLabel];
    self.bgmLabel = bgmLabel;

    CGFloat labelMaxX = MAX(CGRectGetMaxX(voiceLabel.frame), CGRectGetMaxX(bgmLabel.frame));
    
    AWESlider *voiceSlider = [[AWESlider alloc]
                             initWithFrame:CGRectMake(labelMaxX + 20, CGRectGetMinY(voiceLabel.frame),
                                                      self.frame.size.width - labelMaxX - 20 - 36,
                                                      voiceLabel.frame.size.height)];
       
    voiceSlider.showIndicatorLabel = YES;
    voiceSlider.delegate = self;
    voiceSlider.minimumValue = 0.0;
    voiceSlider.maximumValue = 2.0;
    @weakify(voiceSlider);
    voiceSlider.valueDisplayBlock = ^NSString *{
        @strongify(voiceSlider);
        if (voiceSlider.value < 0.01) {
            voiceSlider.accessibilityValue = @"0";
            return @"0";
        }
        voiceSlider.accessibilityValue = [NSString stringWithFormat:@"百分之%.0f", voiceSlider.value * 100];
        return [NSString stringWithFormat:@"%.0f%%", voiceSlider.value * 100];
    };
    voiceSlider.value = HTSAudioVolumeDefault.voiceVolume;
    voiceSlider.minimumTrackTintColor = ACCResourceColor(ACCColorPrimary);
    voiceSlider.maximumTrackTintColor = ACCResourceColor(ACCColorConstTextInverse5);
    [voiceSlider addTarget:self
                    action:@selector(sliderValueChanged:)
          forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventValueChanged];
    [voiceSlider addTarget:self action:@selector(sliderValueDidFinishChange:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    voiceSlider.isAccessibilityElement = YES;
    voiceSlider.indicatorLabel.isAccessibilityElement = NO;
    voiceSlider.accessibilityLabel = @"原声音量";
    
    self.voiceSlider = voiceSlider;
    [self addSubview:self.voiceSlider];
    
    
    [voiceLabel.KVOController observe:voiceSlider
                              keyPath:FBKVOKeyPath(voiceSlider.hidden)
                              options:NSKeyValueObservingOptionNew
                                block:^(UIView *_Nullable observer, UIView *_Nonnull object,
                                        NSDictionary<NSString *, id> *_Nonnull change) {
                                    observer.hidden = object.isHidden;
                                }];
    
    AWESlider *bgmSlider = [[AWESlider alloc] initWithFrame:CGRectMake(labelMaxX + 20, CGRectGetMinY(bgmLabel.frame),
                                               voiceSlider.frame.size.width, voiceSlider.frame.size.height)];

    bgmSlider.showIndicatorLabel = YES;
    bgmSlider.delegate = self;
    bgmSlider.minimumValue = 0.0;
    bgmSlider.maximumValue = 2.0;
    @weakify(bgmSlider);
    bgmSlider.valueDisplayBlock = ^NSString *{
        @strongify(bgmSlider);
        if (bgmSlider.value < 0.01) {
            bgmSlider.accessibilityValue = @"0";
            return @"0";
        }
        bgmSlider.accessibilityValue = [NSString stringWithFormat:@"百分之%.0f", bgmSlider.value * 100];
        return [NSString stringWithFormat:@"%.0f%%", bgmSlider.value * 100];
    };
    bgmSlider.value = HTSAudioVolumeDefault.musicVolume;
    bgmSlider.minimumTrackTintColor = ACCResourceColor(ACCColorPrimary);
    bgmSlider.maximumTrackTintColor = ACCResourceColor(ACCColorConstTextInverse5);
    [bgmSlider addTarget:self
                  action:@selector(sliderValueChanged:)
        forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventValueChanged];
    [bgmSlider addTarget:self action:@selector(sliderValueDidFinishChange:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    bgmSlider.isAccessibilityElement = YES;
    bgmSlider.indicatorLabel.isAccessibilityElement = NO;
    bgmSlider.accessibilityLabel = @"配乐音量";
    
    self.bgmSlider = bgmSlider;
    [self addSubview:self.bgmSlider];
    
    [bgmLabel.KVOController observe:bgmSlider
                            keyPath:FBKVOKeyPath(bgmSlider.hidden)
                            options:NSKeyValueObservingOptionNew
                              block:^(UIView *_Nullable observer, UIView *_Nonnull object,
                                      NSDictionary<NSString *, id> *_Nonnull change) {
                                  observer.hidden = object.isHidden;
                              }];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame useBlurBackground:YES];
    if (self) {
    }
    return self;
}

- (void)setVoiceLabelTitle:(NSString *)title
{
    self.voiceLabe.text = title;
    [self.voiceLabe sizeToFit];
}
- (void)setBGMLabelTitle:(NSString *)title
{
    self.bgmLabel.text = title;
    [self.bgmLabel sizeToFit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.isAdjustForMusicPanel) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        CGSize radiusSize = CGSizeZero;
        layer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                           byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                 cornerRadii:radiusSize].CGPath;
        self.layer.mask = layer;
    }
}

- (void)resetButtonClicked:(id)sender
{
    NSString *voiceKey = NSStringFromSelector(@selector(voiceVolume));
    [self willChangeValueForKey:voiceKey];
    [self.voiceSlider setValue:HTSAudioVolumeDefault.voiceVolume];
    [self didChangeValueForKey:voiceKey];
    NSString *bgmKey = NSStringFromSelector(@selector(musicVolume));
    [self willChangeValueForKey:bgmKey];
    [self.bgmSlider setValue:HTSAudioVolumeDefault.musicVolume];
    [self didChangeValueForKey:bgmKey];
}

static CGFloat lastVoiceVolume;
static CGFloat lastMusicVolume;
- (void)sliderValueChanged:(id)sender
{
    UISlider *control = (UISlider *)sender;
    
    if (@available(iOS 10.0, *)) {
        BOOL repeat = (control == self.voiceSlider && ACC_FLOAT_EQUAL_TO(control.value, lastVoiceVolume)) || (control == self.bgmSlider && ACC_FLOAT_EQUAL_TO(control.value, lastMusicVolume));
        if (!repeat && (ACC_FLOAT_EQUAL_TO(control.value, control.maximumValue) || ACC_FLOAT_EQUAL_TO(control.value, control.minimumValue))) {
            UISelectionFeedbackGenerator *selectionFeedBackGenerator = [[UISelectionFeedbackGenerator alloc] init];
            [selectionFeedBackGenerator prepare];
            [selectionFeedBackGenerator selectionChanged];
        }
    }
    
    if (control == self.voiceSlider) {
        NSString *voiceKey = NSStringFromSelector(@selector(voiceVolume));
        [self willChangeValueForKey:voiceKey];
        [self didChangeValueForKey:voiceKey];
        lastVoiceVolume = control.value;
    } else if (control == self.bgmSlider) {
        NSString *bgmKey = NSStringFromSelector(@selector(musicVolume));
        [self willChangeValueForKey:bgmKey];
        [self didChangeValueForKey:bgmKey];
        lastMusicVolume = control.value;
    }
}

- (void)sliderValueDidFinishChange:(UISlider *)slider
{
    if (slider == self.voiceSlider) {
        if ([self.delegate respondsToSelector:@selector(htsVideoSoundEffectPanelView:sliderValueDidFinishChangeFromVoiceSlider:)]) {
            [self.delegate htsVideoSoundEffectPanelView:self sliderValueDidFinishChangeFromVoiceSlider:YES];
        }
    } else if (slider == self.bgmSlider) {
        if ([self.delegate respondsToSelector:@selector(htsVideoSoundEffectPanelView:sliderValueDidFinishChangeFromVoiceSlider:)]) {
            [self.delegate htsVideoSoundEffectPanelView:self sliderValueDidFinishChangeFromVoiceSlider:NO];
        }
    }
}

- (void)close
{
    [UIView animateWithDuration:0.2
        animations:^{
          [self setFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, 180)];
        }
        completion:^(BOOL finished) {
          [self removeFromSuperview];
        }];
}

- (void)show
{
    [UIView animateWithDuration:0.3
                     animations:^{
                       [self setFrame:CGRectMake(0, ACC_SCREEN_HEIGHT - 180, ACC_SCREEN_WIDTH, 180)];
                     }];
}

- (float)musicVolume
{
    return self.bgmSlider.value;
}

- (void)setMusicVolume:(float)musicVolume
{
    self.bgmSlider.value = musicVolume;
}

- (float)voiceVolume
{
    return self.voiceSlider.value;
}

- (void)setVoiceVolume:(float)voiceVolume
{
    self.voiceSlider.value = voiceVolume;
}

#pragma mark - kvo

- (void)setPreconditionVoiceDisable:(BOOL)preconditionVoiceDisable {
    _preconditionVoiceDisable = preconditionVoiceDisable;
    
    if (_preconditionVoiceDisable || self.userControlVoiceDisable) {
        self.voiceSlider.enabled = NO;
        if (self.isAdjustForMusicPanel) {
            self.voiceLabe.textColor = ACCResourceColor(ACCColorTextReverse4);
        }
    } else {
        self.voiceSlider.enabled = YES;
        if (self.isAdjustForMusicPanel) {
            self.voiceLabe.textColor = ACCResourceColor(ACCColorTextReverse);
        }
    }
}

- (void)setUserControlVoiceDisable:(BOOL)userControlVoiceDisable {
    _userControlVoiceDisable = userControlVoiceDisable;
    if (_userControlVoiceDisable || self.preconditionVoiceDisable) {
        self.voiceSlider.enabled = NO;
        if (self.isAdjustForMusicPanel) {
            self.voiceLabe.textColor = ACCResourceColor(ACCColorTextReverse4);
        }
    } else {
        self.voiceSlider.enabled = YES;
        if (self.isAdjustForMusicPanel) {
            self.voiceLabe.textColor = ACCResourceColor(ACCColorTextReverse);
        }
    }
}

- (void)setPreconditionBgmMusicDisable:(BOOL)preconditionMusicDisable {
    _preconditionBgmMusicDisable = preconditionMusicDisable;
    if (_preconditionBgmMusicDisable) {
        self.bgmSlider.enabled = NO;
        if (self.isAdjustForMusicPanel) {
            self.bgmLabel.textColor = ACCResourceColor(ACCColorTextReverse4);
        }
    } else {
        self.bgmSlider.enabled = YES;
        if (self.isAdjustForMusicPanel) {
            self.bgmLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        }
    }
}

#pragma mark - music panel

- (void)adjustForMusicSelectPanelOptimizationWithDelegate:(id<HTSVideoSoundEffectPanelViewActionDelegate>)delegate {
   BOOL enableMusicPanelVertical = [delegate enableMusicPanelVertical];
   BOOL enableCheckbox = [delegate enableCheckbox];
    if (!enableMusicPanelVertical && !enableCheckbox) {
        CGFloat offsetY = 8.f;
        _voiceLabe.frame = CGRectOffset(_voiceLabe.frame, 0, offsetY);
        _voiceSlider.frame = CGRectOffset(_voiceSlider.frame, 0, offsetY);
        _bgmLabel.frame = CGRectOffset(_bgmLabel.frame, 0, offsetY);
        _bgmSlider.frame = CGRectOffset(_bgmSlider.frame, 0, offsetY);
    }  else if (!enableMusicPanelVertical && enableCheckbox) {
        //  线上音乐面板，只增加配乐/原声check box
        self.actionDelegate = delegate;
        [self configMusicPanelWithDarkBackground:YES];
        CGFloat voiceY = 80.5;
        CGFloat bgmY = 153.5;
        if (ACC_IPHONE_X_BOTTOM_OFFSET == 0) {
            voiceY -= 18;
            bgmY -= 18;
        }
        _voiceLabe.frame = CGRectMake(30, voiceY, 30, 30);
        _bgmLabel.frame = CGRectMake(30, bgmY, 30, 30);
        _voiceSlider.frame = CGRectMake(76, voiceY, ACC_SCREEN_WIDTH - 76 - 30, 30);
        _bgmSlider.frame = CGRectMake(76, bgmY, ACC_SCREEN_WIDTH - 76 - 30, 30);
       
    } else if (enableMusicPanelVertical) {
        // 新音乐面板
        self.actionDelegate = delegate;
        self.isAdjustForMusicPanel = YES;
        [self configMusicPanelWithDarkBackground:NO];
        CGFloat voiceY = 94.5;
        CGFloat bgmY = 171.5;
        if (ACC_IPHONE_X_BOTTOM_OFFSET == 0) {
            voiceY -= 18;
            bgmY -= 18;
        }
        _voiceLabe.frame = CGRectMake(24, voiceY, 30, 30);
        _bgmLabel.frame = CGRectMake(24, bgmY, 30, 30);
        _voiceSlider.frame = CGRectMake(70, voiceY, ACC_SCREEN_WIDTH - 70 - 36, 30);
        _bgmSlider.frame = CGRectMake(70, bgmY, ACC_SCREEN_WIDTH - 70 - 36, 30);
    }
}

- (void)configMusicPanelWithDarkBackground:(BOOL)isDarkBackground {
    UIColor *labelColor, *minimumTrackTintColor, *maximumTrackTintColor, *progressIndicatorColor;
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 6, 56, 48)];
    [button addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.isAccessibilityElement = YES;
    button.accessibilityLabel = @"返回";
    button.accessibilityTraits = YES;
    [self addSubview:button];
    
    if (isDarkBackground) {
        self.backgroundColor = [UIColor clearColor];
        labelColor = ACCResourceColor(ACCColorConstTextInverse);
        minimumTrackTintColor = ACCResourceColor(ACCColorPrimary);
        maximumTrackTintColor = ACCResourceColor(ACCColorConstTextInverse5);
        progressIndicatorColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [button setImage:ACCResourceImage(@"icon_segment_bigback") forState:UIControlStateNormal];
    } else {
        self.backgroundColor = [UIColor clearColor];
        labelColor = ACCResourceColor(ACCColorTextReverse);
        minimumTrackTintColor = ACCResourceColor(ACCColorPrimary);
        maximumTrackTintColor = ACCResourceColor(ACCUIColorConstLinePrimary2);
        progressIndicatorColor = ACCResourceColor(ACCUIColorConstTextTertiary);

        UIImage *backImage = [ACCResourceImage(@"icon_segment_bigback") acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse)];
        [button setImage:backImage forState:UIControlStateNormal];
    }
    
    _voiceLabe.textColor = labelColor;
    _voiceLabe.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
    _voiceLabe.textAlignment = NSTextAlignmentLeft;
    
    _bgmLabel.textColor = labelColor;
    _bgmLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
    _bgmLabel.textAlignment = NSTextAlignmentLeft;
    
    _voiceSlider.maximumTrackTintColor  = maximumTrackTintColor;
    _voiceSlider.minimumTrackTintColor = minimumTrackTintColor;
    _voiceSlider.indicatorLabel.textColor = progressIndicatorColor;
    _voiceSlider.indicatorLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium];
    
    _bgmSlider.maximumTrackTintColor = maximumTrackTintColor;
    _bgmSlider.minimumTrackTintColor = minimumTrackTintColor;
    _bgmSlider.indicatorLabel.textColor = progressIndicatorColor;
    _bgmSlider.indicatorLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium];
}

#pragma mark - action

- (void)backButtonTapped:(UIButton *)sender {
    if ([self.actionDelegate respondsToSelector:@selector(volumeViewBackButtonTapped)]) {
        [self.actionDelegate volumeViewBackButtonTapped];
    }
}

#pragma mark - AWESliderDelegate

- (void)slider:(AWESlider *)slider valueDidChanged:(float)value {}

- (void)slider:(AWESlider *)slider didFinishSlidingWithValue:(float)value {
    if (slider == self.bgmSlider && [self.actionDelegate respondsToSelector:@selector(bgmSliderDidFinishSlidingWithValue:)]) {
        [self.actionDelegate bgmSliderDidFinishSlidingWithValue:value];
    } else if (slider == self.voiceSlider && [self.actionDelegate respondsToSelector:@selector(voiceSliderDidFinishSlidingWithValue:)]) {
        [self.actionDelegate voiceSliderDidFinishSlidingWithValue:value];
    }
}

@end
