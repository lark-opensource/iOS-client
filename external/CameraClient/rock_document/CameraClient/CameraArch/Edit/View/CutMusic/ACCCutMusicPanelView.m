//
//  ACCCutMusicPanelView.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/9/16.
//

#import "ACCCutMusicPanelView.h"
#import "ACCCutMusicBarChartView.h"
#import "ACCButton.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCCutMusicPanelView ()

@property (nonatomic, assign) ACCCutMusicPanelViewStyle style;
@property (nonatomic, assign) CGFloat canShootOrVideoMaxDuration; // 拍摄页：最长可拍摄时长；编辑页：视频时长

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *clickToDismissPanelView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) ACCButton *cancelButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ACCButton *confirmButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) ACCCutMusicBarChartView *barChartView;
@property (nonatomic, strong) UIButton *selectSuggestButton;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *musicLoopLabel;
@property (nonatomic, strong) UISwitch *musicLoopSwitch;
@property (nonatomic, strong) NSArray<NSNumber *> *originVolumnsArray;

@end

@implementation ACCCutMusicPanelView

- (instancetype)initWithStyle:(ACCCutMusicPanelViewStyle)style
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.userInteractionEnabled = YES;
        UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:nil];
        [self addGestureRecognizer:ges]; // 禁止下拉手势
        _style = style;
        [self p_setupUI];
    }
    return self;
}

- (void)showPanelAnimatedInView:(UIView *)containerView withCompletion:(dispatch_block_t)completion
{
    [containerView addSubview:self.maskView];
    ACCMasMaker(self.maskView, {
        make.edges.equalTo(containerView);
    });
    
    [containerView addSubview:self];
    ACCMasMaker(self, {
        make.left.right.height.equalTo(containerView);
        make.top.equalTo(containerView).offset([self p_panelHeight]);
    });
    [containerView layoutIfNeeded];

    ACCMasUpdate(self, {
        make.top.equalTo(containerView);
    });
    
    [UIView animateWithDuration:0.15f animations:^{
        self.maskView.alpha = 1.f;
        [containerView layoutIfNeeded];
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completion);
    }];

    [containerView addSubview:self.clickToDismissPanelView];
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:nil];
    [self.clickToDismissPanelView addGestureRecognizer:ges]; // 禁止下拉手势
    ACCMasMaker(self.clickToDismissPanelView, {
        make.left.top.right.equalTo(self);
        make.height.equalTo(@(self.frame.size.height - [self p_panelHeight]));
    });
}

- (void)dismissPanelAnimatedWithCompletion:(dispatch_block_t)completion
{
    ACCMasUpdate(self, {
        make.top.equalTo(self.superview).offset([self p_panelHeight]);
    });
    [UIView animateWithDuration:0.15f animations:^{
        self.maskView.alpha = 0.f;
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.maskView removeFromSuperview];
        [self.clickToDismissPanelView removeFromSuperview];
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)updateTimestamp:(CGFloat)time
{
    [self.barChartView updateTimestamp:time];
}

- (void)updateStartTimeIndicator
{
    HTSAudioRange range = self.currentRange;
    NSInteger seconds = (NSInteger)range.location % 60;
    NSInteger minutes = range.location / 60;
    NSString *startTime = [NSString stringWithFormat:@"%ld:%02zd", (long)minutes, seconds];
    NSString *totalTimeStr = [NSString stringWithFormat:@"%ld:%02ld", (long)self.barChartView.totalDuration / 60, (long)self.barChartView.totalDuration % 60];
    NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", startTime, totalTimeStr];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:timeStr];
    
    UIColor *tColor = self.style == ACCCutMusicPanelViewStyleLight ? ACCResourceColor(ACCColorTextReverse4) : ACCResourceColor(ACCColorConstTextInverse5);
    UIColor *hColor = self.style == ACCCutMusicPanelViewStyleLight ? ACCResourceColor(ACCColorTextReverse) : ACCResourceColor(ACCUIColorConstTextInverse2);
    
    [attributedStr addAttributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12], NSForegroundColorAttributeName : tColor}
                           range:NSMakeRange(0, timeStr.length)];
    [attributedStr addAttributes:@{NSForegroundColorAttributeName : hColor}
                           range:NSMakeRange(0, [timeStr rangeOfString:@"/"].location)];
    [self.timeLabel setAttributedText:attributedStr];
}

- (void)updateClipInfoWithCutDuration:(CGFloat)cutDuration totalDuration:(CGFloat)totalDuration
{
    self.canShootOrVideoMaxDuration = cutDuration;
    self.barChartView.cutDuration = cutDuration;
    self.barChartView.totalDuration = totalDuration;
}

- (void)updateClipInfoWithVolumns:(NSArray<NSNumber *> *)volumns
                    startLocation:(CGFloat)startLocation
                  enableMusicLoop:(BOOL)enableMusicLoop
{
    self.originVolumnsArray = [volumns copy];
    [self p_configPropertyForBarChartView];
    self.musicLoopSwitch.on = self.shouldShowMusicLoopComponent && enableMusicLoop;
    [self p_didChangeMusicLoopSwitchStatus:self.musicLoopSwitch.on startLocation:startLocation];
}

- (void)updateStartLocation:(CGFloat)startLocation
{
    [self updateStartLocation:startLocation animated:NO];
}

- (void)updateStartLocation:(CGFloat)startLocation animated:(BOOL)animated
{
    [self.barChartView setRangeStart:startLocation animated:animated];
}

- (void)updateTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)showSuggestView:(BOOL)show
{
    self.selectSuggestButton.hidden = !show;
}

- (void)selecteSuggestView:(BOOL)select
{
    self.selectSuggestButton.selected = select;
}

#pragma mark - Actions

- (void)p_didClickCancelButton:(id)sender
{
    ACCBLOCK_INVOKE(self.cancelBlock);
    [self dismissPanelAnimatedWithCompletion:nil];
    [self.barChartView resetParameters];
}

- (void)p_didClickConfirmButton:(id)sender
{
    ACCBLOCK_INVOKE(self.confirmBlock);
    [self dismissPanelAnimatedWithCompletion:nil];
}

- (void)p_didClickSelectedSuggestButton:(id)sender
{
    BOOL selected = !self.selectSuggestButton.selected;
    ACCBLOCK_INVOKE(self.suggestBlock, selected);
    self.selectSuggestButton.selected = selected;
}

- (void)p_didChangeSwitchValue:(UISwitch *)sender
{
    self.musicLoopSwitch.on = sender.on;
    [self p_didChangeMusicLoopSwitchStatus:self.musicLoopSwitch.on startLocation:-1];
    [self trackAfterClickMusicLoopSwitch:self.musicLoopSwitch.on];
}

- (void)p_didChangeMusicLoopSwitchStatus:(BOOL)currentLoopIsOn startLocation:(CGFloat)startLocation
{
    if (self.shouldShowMusicLoopComponent && currentLoopIsOn) {
        [self.barChartView resetContentOffsetToZero];
        [self p_updateBarHeightsBasedOnShootAndMusicDuration:startLocation];
    } else {
        [self.barChartView updateBarWithHeights:self.originVolumnsArray];
    }
    if (self.shouldShowMusicLoopComponent && !currentLoopIsOn) {
        [self.barChartView resetContentOffsetBeforeLoop];
    }

    if (startLocation >= 0) {
        [self.barChartView setRangeStart:startLocation];
    }
    [self updateStartTimeIndicator];
    [self p_updateHintLabelTitle];
    self.barChartView.chartViewScrollEnabled = !currentLoopIsOn;

    if (self.style == ACCCutMusicPanelViewStyleLight) {
        ACCBLOCK_INVOKE(self.replayMusicBlock);
    } else {
        if (currentLoopIsOn) {
            ACCBLOCK_INVOKE(self.setLoopMusicForEditPageBlock, self.barChartView.currentRange, ceil(self.videoMusicShootRatio));
        } else {
            ACCBLOCK_INVOKE(self.setLoopMusicForEditPageBlock, self.barChartView.currentRange, -1);
        }
    }
}

// startLocation 若为 -1，则为手动设置循环的情况，直接取 currentRange 的 location 即可
- (void)p_updateBarHeightsBasedOnShootAndMusicDuration:(CGFloat)startLocation
{
    NSMutableArray *copyVloumnsArray = [NSMutableArray array];
    NSMutableArray *newVolumnsArray = [NSMutableArray array];
    NSMutableArray *finalVolumnsArray = [NSMutableArray array];

    // 确定复制哪一段波形数据
    CGFloat initStartLocation = self.barChartView.currentRange.location;
    if (ACC_FLOAT_EQUAL_ZERO(initStartLocation) && ACC_FLOAT_GREATER_THAN(initStartLocation, self.musicDuration) && startLocation > 0) {
        initStartLocation = startLocation;
    }

    NSUInteger beginLocation = 0;
    NSUInteger endLocation = self.barChartView.firstLoopEndLocation;
    if (!ACC_FLOAT_EQUAL_ZERO(self.musicDuration)) {
        beginLocation = initStartLocation * [self.originVolumnsArray count] / self.musicDuration;
        endLocation += beginLocation;
    }
    if (self.musicMusicShootRatio > 1 && endLocation < [self.originVolumnsArray count]) {
        for (int i = (int)beginLocation; i < endLocation + 1; i++) {
            [copyVloumnsArray acc_addObject:self.originVolumnsArray[i]];
        }
    } else {
        copyVloumnsArray = [self.originVolumnsArray mutableCopy];
    }

    // 复制波形数据
    NSUInteger completeCopyTime = floor(self.videoMusicShootRatio);
    for (int i = 0; i < completeCopyTime; i++) {
        [newVolumnsArray addObjectsFromArray:copyVloumnsArray];
    }
    CGFloat lastTimeCopyRatio = self.videoMusicShootRatio - completeCopyTime;
    NSUInteger lastCopyTime = floor([copyVloumnsArray count] * lastTimeCopyRatio);
    for (int i = 0; i < lastCopyTime; i++) {
        [newVolumnsArray acc_addObject:copyVloumnsArray[i]];
    }

    // 判断是否大于最大可显示音柱数
    NSUInteger maxBarCount = [ACCCutMusicBarChartView barCountWithFullWidth] + 1;
    if ([newVolumnsArray count] > maxBarCount) {
        for (int i = 0; i < maxBarCount; i++) {
            [finalVolumnsArray acc_addObject:newVolumnsArray[i]];
        }
    } else {
        finalVolumnsArray = newVolumnsArray;
    }

    [self.barChartView updateBarWithHeights:[finalVolumnsArray copy]];
}

- (void)p_configPropertyForBarChartView
{
    self.barChartView.shouldShowMusicLoopComponent = self.shouldShowMusicLoopComponent;
    self.barChartView.videoMusicRatio = self.videoMusicRatio;
    self.barChartView.videoMusicShootRatio = self.videoMusicShootRatio;
    self.barChartView.musicMusicShootRatio = self.musicMusicShootRatio;
    self.barChartView.musicShootDuration = self.musicShootDuration;
    @weakify(self);
    self.barChartView.isMusicLoopOpenBlock = ^BOOL{
        @strongify(self);
        return [self isMusicLoopOpen];
    };

    if (!ACC_FLOAT_EQUAL_ZERO(self.musicMusicShootRatio)) {
        self.barChartView.firstLoopEndLocation = ([self.originVolumnsArray count] - 1) / self.musicMusicShootRatio;
    } else {
        self.barChartView.firstLoopEndLocation = 0;
    }
}

#pragma mark - UI

- (void)p_setupUI
{
    [self addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.left.bottom.right.equalTo(self);
        make.height.equalTo(@([self p_panelHeight]));
    });
    
    [self.contentView addSubview:self.cancelButton];
    ACCMasMaker(self.cancelButton, {
        make.left.equalTo(self.contentView).offset(16);
        make.top.equalTo(self.contentView).offset(14);
        make.size.equalTo(@(CGSizeMake(24, 24)));
    });
    
    [self.contentView addSubview:self.confirmButton];
    ACCMasMaker(self.confirmButton, {
        make.top.equalTo(self.cancelButton);
        make.right.equalTo(self.contentView).offset(-16);
        make.size.equalTo(@(CGSizeMake(24, 24)));
    });
    
    [self.contentView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.cancelButton);
        make.left.greaterThanOrEqualTo(self.cancelButton.mas_right).offset(20);
        make.right.lessThanOrEqualTo(self.confirmButton.mas_left).offset(-20);
    });
    
    [self.contentView addSubview:self.timeLabel];
    ACCMasMaker(self.timeLabel, {
        make.left.equalTo(self.cancelButton);
        make.top.equalTo(self.cancelButton.mas_bottom).offset(21);
    });
    
    [self.contentView addSubview:self.barChartView];
    ACCMasMaker(self.barChartView, {
        make.left.right.equalTo(self.contentView);
        make.top.equalTo(self.timeLabel.mas_bottom).offset(8);
        make.height.equalTo(@([ACCCutMusicBarChartView chartViewHeight]));
    });
    
    [self.contentView addSubview:self.selectSuggestButton];
    ACCMasMaker(self.selectSuggestButton, {
        make.centerY.equalTo(self.timeLabel);
        make.right.equalTo(self.confirmButton);
    });
    
    [self.contentView addSubview:self.hintLabel];
    ACCMasMaker(self.hintLabel, {
        make.top.equalTo(self.barChartView.mas_bottom).offset(25);
        make.left.equalTo(self.cancelButton);
    });

    [self.contentView addSubview:self.musicLoopSwitch];
    ACCMasMaker(self.musicLoopSwitch, {
        make.centerY.equalTo(self.hintLabel);
        make.right.equalTo(self.confirmButton);
    });

    [self.contentView addSubview:self.musicLoopLabel];
    ACCMasMaker(self.musicLoopLabel, {
        make.centerY.equalTo(self.musicLoopSwitch);
        make.right.equalTo(self.musicLoopSwitch.mas_left).offset(-5);
        make.width.equalTo(@82);
        make.height.equalTo(@15);
    });
    
    self.maskView.alpha = 0;
    self.selectSuggestButton.selected = NO;
}

- (void)p_configMusicLoopComponentStatus:(BOOL)canOpenMusicLoop
{
    self.musicLoopSwitch.hidden = !canOpenMusicLoop;
    self.musicLoopLabel.hidden = !canOpenMusicLoop;
}

- (void)p_updateHintLabelTitle
{
    if ([self isInMusicLoopExperiment]) {
        if (self.shouldShowMusicLoopComponent) {
            if ([self isMusicLoopOpen]) {
                if (self.style == ACCCutMusicPanelViewStyleLight) {
                    self.hintLabel.text = [NSString stringWithFormat:@"最长可拍摄%.0f秒", self.canShootOrVideoMaxDuration];
                } else {
                    self.hintLabel.text = [NSString stringWithFormat:@"音频可播放%.0f秒", self.canShootOrVideoMaxDuration];
                }
            } else {
                self.hintLabel.text = [NSString stringWithFormat:@"该音频最多可选取%.0f秒", self.musicShootDuration];
            }
        } else if (!self.shouldShowMusicLoopComponent && self.isForbidLoopForLongVideo) {
            self.hintLabel.text = [NSString stringWithFormat:@"该音频最多可选取%.0f秒", self.musicShootDuration];
        } else {
            self.hintLabel.text = [NSString stringWithFormat:@"已选取%.0f秒音频", self.canShootOrVideoMaxDuration];
        }
    } else {
        self.hintLabel.text = ACCLocalizedString(@"drag_tip", @"左右拖动声谱以剪取音乐");
    }
}

- (CGFloat)p_panelHeight
{
    return 208 + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (void)trackAfterClickMusicLoopSwitch:(BOOL)currentIsOn
{
    ACCBLOCK_INVOKE(self.trackAfterClickMusicLoopSwitchBlock, currentIsOn);
}

#pragma mark - Setters

- (void)setShouldShowMusicLoopComponent:(BOOL)shouldShowMusicLoopComponent
{
    _shouldShowMusicLoopComponent = shouldShowMusicLoopComponent;
    [self p_configMusicLoopComponentStatus:self.shouldShowMusicLoopComponent];
    self.barChartView.chartViewScrollEnabled = YES;
}

#pragma mark - Getters

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        }
    }
    return _maskView;
}

- (UIView *)clickToDismissPanelView
{
    if (!_clickToDismissPanelView) {
        _clickToDismissPanelView = [[UIView alloc] init];
        _clickToDismissPanelView.backgroundColor = [UIColor clearColor];
        [_clickToDismissPanelView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_didClickCancelButton:)];
    }
    return _clickToDismissPanelView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _contentView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        } else { 
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            [_contentView addSubview:effectView];
            ACCMasMaker(effectView, {
                make.edges.equalTo(_contentView);
            });
            _contentView.clipsToBounds = YES;
        }
        
        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self p_panelHeight])
                                                    byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                          cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self p_panelHeight]);
        maskLayer.path = path.CGPath;
        _contentView.layer.mask = maskLayer;
    }
    return _contentView;
}

- (ACCButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [[ACCButton alloc] init];
        _cancelButton.selectedAlpha = 0.75;
        [_cancelButton addTarget:self action:@selector(p_didClickCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            [_cancelButton setImage:ACCResourceImage(@"icon_edit_bar_cancel_dark") forState:UIControlStateNormal];
        } else {
            [_cancelButton setImage:ACCResourceImage(@"icon_edit_bar_cancel_light") forState:UIControlStateNormal];
        }
        _cancelButton.isAccessibilityElement = YES;
        _cancelButton.accessibilityLabel = @"取消";
        _cancelButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _cancelButton;;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:15];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        } else {
            _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        }
    }
    return _titleLabel;
}

- (ACCButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[ACCButton alloc] init];
        _confirmButton.selectedAlpha = 0.75;
        [_confirmButton addTarget:self action:@selector(p_didClickConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            [_confirmButton setImage:ACCResourceImage(@"icon_edit_bar_done_dark") forState:UIControlStateNormal];
        } else {
            [_confirmButton setImage:ACCResourceImage(@"icon_edit_bar_done_light") forState:UIControlStateNormal];
        }
        _confirmButton.isAccessibilityElement = YES;
        _confirmButton.accessibilityLabel = @"保存";
        _confirmButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _confirmButton;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
    }
    return _timeLabel;
}

- (ACCCutMusicBarChartView *)barChartView
{
    if (!_barChartView) {
        _barChartView = [[ACCCutMusicBarChartView alloc] initWithStyle:self.style];
    }
    return _barChartView;
}

- (UIButton *)selectSuggestButton
{
    if (!_selectSuggestButton) {
        _selectSuggestButton = [[UIButton alloc] init];
        _selectSuggestButton.titleLabel.font = [ACCFont() systemFontOfSize:13];
        _selectSuggestButton.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, -3);
        _selectSuggestButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [_selectSuggestButton setTitle:ACCLocalizedString(@"edit_sound_recommend", @"推荐片段") forState:UIControlStateNormal];
        [_selectSuggestButton setImage:ACCResourceImage(@"icon_box_checked") forState:UIControlStateSelected];
        [_selectSuggestButton addTarget:self action:@selector(p_didClickSelectedSuggestButton:) forControlEvents:UIControlEventTouchUpInside];
        [_selectSuggestButton setImage:[ACCResourceImage(@"icon_box_unchecked") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            [_selectSuggestButton setTintColor:ACCResourceColor(ACCColorLineReverse2)];
            [_selectSuggestButton setTitleColor:ACCResourceColor(ACCColorTextReverse3) forState:UIControlStateNormal];
        } else {
            [_selectSuggestButton setTintColor:ACCResourceColor(ACCColorLineTertiary)];
            [_selectSuggestButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse4) forState:UIControlStateNormal];
        }
    }
    return _selectSuggestButton;
}

- (UILabel *)musicLoopLabel
{
    if (!_musicLoopLabel) {
        _musicLoopLabel = [[UILabel alloc] init];
        _musicLoopLabel.text = @"循环播放";
        _musicLoopLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        _musicLoopLabel.textAlignment = NSTextAlignmentRight;
        _musicLoopLabel.hidden = YES;
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _musicLoopLabel.textColor = ACCResourceColor(ACCColorTextReverse2);
        } else {
            _musicLoopLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        }
    }
    return _musicLoopLabel;
}

- (UISwitch *)musicLoopSwitch
{
    if (!_musicLoopSwitch) {
        _musicLoopSwitch = [[UISwitch alloc] init];
        _musicLoopSwitch.transform = CGAffineTransformMakeScale(0.8, 0.8);
        _musicLoopSwitch.hidden = YES;
        [_musicLoopSwitch addTarget:self action:@selector(p_didChangeSwitchValue:) forControlEvents:UIControlEventValueChanged];
    }
    return _musicLoopSwitch;
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.font = [ACCFont() systemFontOfSize:12];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _hintLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        } else {
            _hintLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        }
    }
    return _hintLabel;
}

- (HTSAudioRange)currentRange
{
    return self.barChartView.currentRange;
}

- (CGFloat)currentTime
{
    return self.barChartView.currentTime;
}

- (BOOL)isMusicLoopOpen
{
    return self.musicLoopSwitch.on;
}

- (BOOL)isInMusicLoopExperiment
{
    return ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff;
}

@end
