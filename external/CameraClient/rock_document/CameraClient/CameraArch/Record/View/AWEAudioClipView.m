//
//  AWEAudioClipView.m
//  Aweme
//
//  Created by 郝一鹏 on 2017/5/3.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEAudioClipView.h"
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

ACCContextId(ACCRecordAudioClipContext)

static NSString * const AWEAudioClipStartIndicatorFont = @"awe_audio_clip_start_indicator_font";
static NSString * const AWEAudioClipStartBarViewDrawColor = @"awe.audio.clip.start.barview.draw.color";

@interface AWEAudioClipView ()

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, assign) AWEAudioClipViewStyle style;

@end

@implementation AWEAudioClipView

- (instancetype)initWithStyle:(AWEAudioClipViewStyle)style
{
    if (self = [super initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 250)]) {
        _style = style;
        if (style == AWEAudioClipViewTopStyle) {
            self.acc_height = 270;
        }
        self.userInteractionEnabled = YES;
        [self buildSubviews];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithStyle:AWEAudioClipViewBottomStyle];
}

- (void)buildSubviews {
    [self addSubview:self.audioBarView];

    self.audioBarView.frame = CGRectMake(0, 0, self.acc_width, 98);
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        self.audioBarView.acc_bottom = self.acc_height - 74;
    } else {
        self.audioBarView.acc_bottom = self.acc_height - 20;
    }
    
    [self addSubview:self.audioStartTimeIndicatorBtn];
    [self.audioStartTimeIndicatorBtn sizeToFit];
    self.audioStartTimeIndicatorBtn.acc_left = 20;
    self.audioStartTimeIndicatorBtn.acc_bottom = self.audioBarView.acc_top - 12;
    
    [self addSubview:self.clipMusicDoneBtn];
    self.clipMusicDoneBtn.frame = CGRectMake(0, 0, 54, 32);
    self.clipMusicDoneBtn.acc_right = self.acc_width - 20;

    if (self.style == AWEAudioClipViewTopStyle) {
        self.clipMusicDoneBtn.acc_bottom = self.audioBarView.acc_top - 64;
    } else {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            self.clipMusicDoneBtn.acc_bottom = self.acc_height - 11;
        } else {
            self.clipMusicDoneBtn.acc_bottom = self.audioBarView.acc_top - 70;
        }
    }
    
    [self addSubview:self.tipLabel];
    [self.tipLabel sizeToFit];
    self.tipLabel.acc_centerX = self.acc_width / 2;
    self.tipLabel.acc_centerY = self.clipMusicDoneBtn.acc_centerY;
}

- (void)shouldUseBarView:(BOOL)useBarView
{
    self.audioBarView.hidden = !useBarView;
}

#pragma mark - lazy initalize properties

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [UILabel new];
        _tipLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _tipLabel.textColor = ACCResourceColor(ACCUIColorConstBGContainer4);
        _tipLabel.numberOfLines = 2;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.shadowColor = ACCResourceColor(ACCUIColorConstGradient);
        _tipLabel.shadowOffset = CGSizeMake(0, 1);
        _tipLabel.text =  ACCLocalizedString(@"drag_tip", @"左右拖动声谱以剪取音乐");
    }
    return _tipLabel;
}

- (UIButton *)clipMusicDoneBtn {
    
    if (!_clipMusicDoneBtn) {
        _clipMusicDoneBtn = [UIButton new];
        [_clipMusicDoneBtn setImage:ACCResourceImage(@"icCameraDetermine") forState:UIControlStateNormal];
        _clipMusicDoneBtn.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary) ;
        _clipMusicDoneBtn.layer.cornerRadius = 2;
    }
    return _clipMusicDoneBtn;
}

- (UIButton *)audioStartTimeIndicatorBtn {
    
    if (!_audioStartTimeIndicatorBtn) {
        _audioStartTimeIndicatorBtn = [UIButton new];
        UIImage *backgroundImage = ACCResourceImage(@"bg_camera_sound");
        [_audioStartTimeIndicatorBtn setBackgroundImage:[backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(backgroundImage.size.height / 2 -1, backgroundImage.size.width / 2 - 1, backgroundImage.size.height / 2, backgroundImage.size.width / 2)] forState:UIControlStateNormal];
        _audioStartTimeIndicatorBtn.titleLabel.font = ACCResourceFont(AWEAudioClipStartIndicatorFont);
        _audioStartTimeIndicatorBtn.titleLabel.tintColor = ACCResourceColor(ACCUIColorTextS1);
        [_audioStartTimeIndicatorBtn setTitle: ACCLocalizedCurrentString(@"com_mig_currently_starting_from_0000")  forState:UIControlStateNormal];
        _audioStartTimeIndicatorBtn.titleEdgeInsets = UIEdgeInsetsMake(-4, 8, 0, 8);
    }
    return _audioStartTimeIndicatorBtn;
}

- (AWEScrollBarChartView *)audioBarView
{
    if (!_audioBarView) {
        _audioBarView = [[AWEScrollBarChartView alloc] init];
        _audioBarView.barWidth = 2.0;
        _audioBarView.space = 3.0;
        _audioBarView.minBarHeight = 8.0;
        _audioBarView.maxBarHeight = 100;
        _audioBarView.drawColor = ACCResourceColor(ACCColorPrimary);
        _audioBarView.barDefaultColor = [UIColor whiteColor];
    }
    return _audioBarView;
}

#pragma mark - ACCPanelViewProtocol

- (CGFloat)panelViewHeight
{
    return self.frame.size.height + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (void *)identifier
{
    return ACCRecordAudioClipContext;
}

@end
