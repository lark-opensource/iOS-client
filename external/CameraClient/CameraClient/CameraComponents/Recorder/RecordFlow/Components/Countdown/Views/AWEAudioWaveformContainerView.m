//
//  AWEAudioWaveformContainerView.m
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEAudioWaveformContainerView.h"
#import "AWECountDownBarChartView.h"
#import "AWEDelayRecordCoverView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

CGFloat kAWEAudioWaveformBackgroundHeight = 56;
CGFloat kAWEAudioWaveformBackgroundLeftMargin = 16;
CGFloat kAWESwitchButtonWidth = 44;
CGFloat kAWESwitchButtonHeight = 28;

@interface AWEAudioWaveformContainerView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *buttonContainerView;
@property (nonatomic, strong) AWEAudioWaveformSliderView *waveformSliderView;
@property (nonatomic, strong) AWEDelayRecordCoverView *coverView;
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, assign) CGFloat assetStartLocation;
@property (nonatomic, assign) CGFloat assetEndLocation;

@end

@implementation AWEAudioWaveformContainerView

- (instancetype)initWithFrame:(CGRect)frame model:(ACCCountDownModel *)model
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.layer addSublayer:self.backgroundLayer];
        [self addSubview:self.titleLabel];
        [self addSubview:self.waveformSliderView];
        self.waveformSliderView.countDownModel = model;
        [self.waveformSliderView addSubview:self.coverView];
        [self addSubviews];
    }
    return self;
}

- (void)addButtonCornerMaskFor:(UIView *)view
{
    view.layer.cornerRadius = kAWESwitchButtonHeight / 2;
    view.clipsToBounds = YES;
}

- (void)addSubviews
{
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.mas_left).offset(16);
        make.top.equalTo(self.mas_top).offset(18);
    });

    [self addSubview:self.buttonContainerView];
    [self addButtonCornerMaskFor:self.buttonContainerView];
    ACCMasMaker(self.buttonContainerView, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-16);
        make.size.equalTo(@(CGSizeMake(kAWESwitchButtonWidth * 2, kAWESwitchButtonHeight)));
    });
    
    self.leftButton.layer.cornerRadius = kAWESwitchButtonHeight / 2;
    self.leftButton.clipsToBounds = YES;
//    self.leftButton.layer.mask = [self maskLayerWithButtonBounds:CGRectMake(0, 0, kAWESwitchButtonWidth, kAWESwitchButtonHeight) direction:ACCButtonDirectionLeft];
    [self addSubview:self.leftButton];
    [self addButtonCornerMaskFor:self.leftButton];
    ACCMasMaker(self.leftButton, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self.rightButton).offset(-kAWESwitchButtonWidth);
        make.size.equalTo(@(CGSizeMake(kAWESwitchButtonWidth, kAWESwitchButtonHeight)));
    });

    self.rightButton.layer.cornerRadius = kAWESwitchButtonHeight / 2;
//    self.rightButton.layer.mask = [self maskLayerWithButtonBounds:CGRectMake(0, 0, kAWESwitchButtonWidth, kAWESwitchButtonHeight) direction:ACCButtonDirectionRight];
    [self addSubview:self.rightButton];
    [self addButtonCornerMaskFor:self.rightButton];
    ACCMasMaker(self.rightButton, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-16);
        make.size.equalTo(@(CGSizeMake(kAWESwitchButtonWidth, kAWESwitchButtonHeight)));
    });
    
}

- (CGFloat)waveBarCountForFullWidth
{
    return [self.waveformSliderView waveBarCountForFullWidth];
}

- (void)showNoMusicWaveformView:(BOOL)isShown
{
    self.waveformSliderView.nomuiscWaveformView.hidden = !isShown;
}

- (void)updateWaveBarWithVolumes:(NSArray *)volumes
{
    [self.waveformSliderView updateWaveUIWithVolumes:volumes];
}

- (void)updateHasRecordedLocation:(CGFloat)hasRecordedLocation
{
    if (isnan(hasRecordedLocation)) {
        return;
    }
    if (self.usingBarView) {
        self.waveformSliderView.waveBarView.hasRecordedLocation = hasRecordedLocation;
        self.waveformSliderView.waveBarView.time = hasRecordedLocation;
    } else {
        self.waveformSliderView.waveformView.hasRecordedLocation = hasRecordedLocation;
        self.waveformSliderView.waveformView.playingLocation = hasRecordedLocation;
        [self.waveformSliderView.waveformView setNeedsDisplay];
    }
    self.coverView.frame = CGRectMake(0, 0, (ACC_SCREEN_WIDTH - 2 * kAWEAudioWaveformBackgroundLeftMargin) * hasRecordedLocation, kAWEAudioWaveformBackgroundHeight);
}

- (void)updatePlayingLocation:(CGFloat)playingLocation
{
    if (self.usingBarView) {
        self.waveformSliderView.waveBarView.time = playingLocation;
    } else {
        self.waveformSliderView.waveformView.playingLocation = playingLocation;
        [self.waveformSliderView.waveformView setNeedsDisplay];
    }
}

- (void)updateBottomRightLableWithMaxDuration:(CGFloat)maxDuration
{
    [self.waveformSliderView updateRightLabelWithMaxDuration:maxDuration];
}

- (void)updateToBePlayedLocation:(CGFloat)tobePlayedLocation
{
    [self.waveformSliderView moveControlViewByCodeWithPercent:tobePlayedLocation];
}

- (void)setDelegateForSliderView:(id)delegate
{
    self.waveformSliderView.delegate = delegate;
}

- (void)setUpdateMusicBlock:(void (^)(void))updateMusicBlock
{
    self.waveformSliderView.updateMusicBlock = updateMusicBlock;
}

- (void)setUsingBarView:(BOOL)usingBarView
{
    _usingBarView = usingBarView;
    self.waveformSliderView.usingBarView = usingBarView;
}

#pragma mark - getter

- (CAShapeLayer *)maskLayerWithButtonBounds:(CGRect)bounds direction:(ACCButtonDirection)direction
{
    UIBezierPath *maskPath;
    CGFloat cornerRadius = bounds.size.height/2;
    switch (direction) {
        case ACCButtonDirectionLeft:
            maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft) cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
            break;
        case ACCButtonDirectionRight:
            maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:(UIRectCornerTopRight | UIRectCornerBottomRight) cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    }
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    return maskLayer;
}

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.backgroundColor = [UIColor clearColor];
        [_leftButton setTitle:@"3s" forState:UIControlStateNormal];
        _leftButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:[ACCFont() getAdaptiveFontSize:13]];
        _leftButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, 0, -20, 0);
        [_leftButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.34] forState:UIControlStateNormal];
        _leftButton.isAccessibilityElement = YES;
        _leftButton.accessibilityLabel = @"三秒";
        _leftButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.backgroundColor = [UIColor clearColor];
        [_rightButton setTitle:@"10s" forState:UIControlStateNormal];
        _rightButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:[ACCFont() getAdaptiveFontSize:13]];
        _rightButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, 0, -20, 0);
        [_rightButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.34] forState:UIControlStateNormal];
        _rightButton.isAccessibilityElement = YES;
        _rightButton.accessibilityLabel = @"十秒";
        _rightButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _rightButton;
}

- (AWEDelayRecordCoverView *)coverView
{
    if (!_coverView) {
        _coverView = [[AWEDelayRecordCoverView alloc] init];
    }
    return _coverView;
}

- (UIView *)buttonContainerView
{
    if (!_buttonContainerView) {
        _buttonContainerView = [UIView new];
        _buttonContainerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    }
    return _buttonContainerView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightSemibold];
        _titleLabel.text = ACCLocalizedString(@"count_down_title", @"拖动选择暂停位置");
        _titleLabel.isAccessibilityElement = YES;
        _titleLabel.accessibilityLabel = @"拖动选择暂停位置";
        _titleLabel.accessibilityTraits = UIAccessibilityTraitStaticText;
    }
    return _titleLabel;
}

- (AWEAudioWaveformSliderView *)waveformSliderView
{
    if (!_waveformSliderView) {
        _waveformSliderView = [[AWEAudioWaveformSliderView alloc] init];
        _waveformSliderView.userInteractionEnabled = YES;
    }
    return _waveformSliderView;
}

- (CAShapeLayer *)backgroundLayer
{
    if (!_backgroundLayer) {
        _backgroundLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH - 2 * kAWEAudioWaveformBackgroundLeftMargin, kAWEAudioWaveformBackgroundHeight) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(2, 2)];
        _backgroundLayer.path = path.CGPath;
        _backgroundLayer.fillColor = ACCResourceColor(ACCUIColorConstTextTertiary3).CGColor;
    }
    return _backgroundLayer;
}

#pragma mark - set selected button

- (void)setSelectedButtonWithDelayMode:(AWEDelayRecordMode)mode
{
    switch (mode) {
        case AWEDelayRecordMode3S:
            self.leftButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
            [self.leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.leftButton.accessibilityLabel = @"三秒已选中";
            self.rightButton.accessibilityLabel = @"十秒未选中";
            break;
        case AWEDelayRecordMode10S:
            [self.rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.rightButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
            self.rightButton.accessibilityLabel = @"十秒已选中";
            self.leftButton.accessibilityLabel = @"三秒未选中";
        case AWEDelayRecordModeDefault:
            break;
    }
}

- (void)updateButtonLayout
{
    self.leftButton.layer.mask = [self maskLayerWithButtonBounds:CGRectMake(0, 0, kAWESwitchButtonWidth, kAWESwitchButtonHeight) direction:ACCButtonDirectionLeft];
    ACCMasReMaker(self.leftButton, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self.rightButton).offset(-kAWESwitchButtonWidth);
        make.size.equalTo(@(CGSizeMake(kAWESwitchButtonWidth, kAWESwitchButtonHeight)));
    });
    self.rightButton.layer.mask = [self maskLayerWithButtonBounds:CGRectMake(0, 0, kAWESwitchButtonWidth, kAWESwitchButtonHeight) direction:ACCButtonDirectionRight];
    ACCMasReMaker(self.rightButton, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-16);
        make.size.equalTo(@(CGSizeMake(kAWESwitchButtonWidth, kAWESwitchButtonHeight)));
    });
}

#pragma mark - layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.titleLabel sizeToFit];
    
    CGFloat space = self.leftButton.frame.origin.x - (self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width);
    if (space <= 8) {
        kAWESwitchButtonWidth = 32;
        [self updateButtonLayout];
    } else {
        kAWESwitchButtonWidth = 44;
        [self updateButtonLayout];
    }
    
    self.waveformSliderView.frame = CGRectMake(kAWEAudioWaveformBackgroundLeftMargin, 75, ACC_SCREEN_WIDTH - 2 * kAWEAudioWaveformBackgroundLeftMargin, kAWEAudioWaveformBackgroundHeight);
    self.backgroundLayer.frame = self.waveformSliderView.frame;
}
@end
