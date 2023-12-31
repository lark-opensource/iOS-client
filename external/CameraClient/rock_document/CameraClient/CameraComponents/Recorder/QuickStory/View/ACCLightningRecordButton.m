//
//  ACCLightningRecordButton.m
//  RecordButton
//
//  Created by shaohua on 2020/8/2.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

#import "ACCLightningRecordButton.h"
#import "ACCLightningRecordBlurView.h"
#import "ACCLightningRecordWhiteView.h"
#import "ACCLightningRecordLongtailView.h"
#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>

static const CGFloat kDiameter = 76;
const CGFloat KlongTailRecordDurationCycle = 15.0; // 一圈15s
const NSTimeInterval kACCRecordAnimateDuration = 0.3;

@interface ACCLightningRecordButton ()

@property (nonatomic, strong) NSMutableArray<id<ACCLightningRecordAnimatable>> *animatables;
@property (nonatomic, strong) ACCLightningRecordBlurView *blurView;
@property (nonatomic, strong) ACCLightningRecordWhiteView *whiteView;
@property (nonatomic, strong) UIImageView *lightningView;
@property (nonatomic, strong) UIImageView *boomerangView;
@property (nonatomic, strong) UIImageView *audioRecordView;
@property (nonatomic, strong) ACCLightningRecordLongtailView *longtailView;
@property (nonatomic, assign) float progress;

@end

@implementation ACCLightningRecordButton

@synthesize state = _state;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectMake(0, 0, kDiameter, kDiameter)]) {
        _animatables = [NSMutableArray array];

        CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);

        ACCLightningRecordBlurView *blurView = [ACCLightningRecordBlurView new];
        blurView.center = center;
        [self addSubview:blurView];
        [_animatables acc_addObject:blurView];
        _blurView = blurView;

        ACCLightningRecordRingView *ringView = [ACCLightningRecordRingView new];
        ringView.center = center;
        [self addSubview:ringView];
        [_animatables acc_addObject:ringView];
        _ringView = ringView;

        ACCLightningRecordWhiteView *whiteView = [ACCLightningRecordWhiteView new];
        whiteView.center = center;
        [self addSubview:whiteView];
        [_animatables acc_addObject:whiteView];
        _whiteView = whiteView;

        _redView = [ACCLightningRecordRedView new];
        _redView.center = center;
        [self addSubview:_redView];
        [_animatables acc_addObject:_redView];
        
        _longtailView = [ACCLightningRecordLongtailView new];
        _longtailView.center = center;
        [self addSubview:_longtailView];
        [_animatables acc_addObject:_longtailView];

        _lightningView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _lightningView.image = ACCResourceImage(@"icon_lightning");
        _lightningView.center = CGPointMake(kDiameter / 2, kDiameter / 2);
        _lightningView.hidden = YES;
        [self addSubview:_lightningView];
        
        _boomerangView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_boomerang")];
        _boomerangView.center = CGPointMake(kDiameter / 2, kDiameter / 2);
        _boomerangView.hidden = YES;
        [self addSubview:_boomerangView];
        
        _audioRecordView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _audioRecordView.image = ACCResourceImage(@"ic_submode_audio_mirco");
        _audioRecordView.center = CGPointMake(kDiameter / 2, kDiameter / 2);
        _audioRecordView.hidden = YES;
        [self addSubview:_audioRecordView];
        
        _alienationView = [ACCLightningRecordAlienationView new];
        _alienationView.center = center;
        [self addSubview:_alienationView];
        [_animatables acc_addObject:_alienationView];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(kDiameter, kDiameter);
}

- (void)setRecordMode:(ACCRecordMode *)recordMode
{
    [_animatables enumerateObjectsUsingBlock:^(id<ACCLightningRecordAnimatable>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.recordMode = recordMode;
    }];
    _recordMode = recordMode;
}

- (void)setState:(ACCRecordButtonState)state
{
    [_animatables enumerateObjectsUsingBlock:^(id<ACCLightningRecordAnimatable> obj, NSUInteger idx, BOOL *stop) {
        obj.state = state;
    }];
    _state = state;

    self.audioRecordView.hidden = !(state == ACCRecordButtonBegin && self.showMicroView);
    self.lightningView.hidden = !(state == ACCRecordButtonBegin && self.showLightningView);
    
    if (self.recordMode.buttonType == AWEVideoRecordButtonTypeLivePhoto && state == ACCRecordButtonBegin) {
        self.boomerangView.hidden = NO;
    } else {
        self.boomerangView.hidden = YES;
    }
    if (self.switchModelSubject) {
        [self.switchModelSubject sendNext:@(state)];
    }
}

- (void)setShowMicroView:(BOOL)showMicroView{
    _showMicroView = showMicroView;
    self.audioRecordView.hidden = !(self.state == ACCRecordButtonBegin && showMicroView);
}

- (void)setShowLightningView:(BOOL)showLightningView {
    _showLightningView = showLightningView;

    self.lightningView.hidden = !(self.state == ACCRecordButtonBegin && showLightningView);
}

- (void)hideCenterView
{
    self.redView.hidden = YES;
}

- (void)hideCenterViewWhenRecording:(BOOL)hide
{
    self.redView.hideWhenRecording = hide;
}

#pragma mark - AWEVideoProgressViewProtocol

- (void)setReshootTimeFrom:(NSTimeInterval)startTime to:(NSTimeInterval)endTime totalDuration:(NSTimeInterval)totalDuration {
    // normalize
    startTime = MIN(startTime, totalDuration) / totalDuration;
    endTime = MIN(endTime, totalDuration) / totalDuration;
    self.reshootMode = YES;
    self.state = ACCRecordButtonPaused;
    [self.ringView addRangeIndicatorWithStart:startTime end:endTime];
}

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated
{
    if (self.recordMode.modeId == ACCRecordModeLivePhoto) {
        animated = YES;
    }
    
    if (self.recordMode.isStoryStyleMode && ACCConfigBool(kConfigBool_longtail_shoot_animation)) {
        [self.longtailView setProgress:self.maxDuration / KlongTailRecordDurationCycle * progress animated:animated];
    } else {
        [self.ringView setProgress:progress animated:animated];
    }
    self.progress = progress;
}

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled standardDuration:(double)standardDuration maxDuration:(double)maxDuration
{
    // ignore
}

- (void)updateViewWithTimeSegments:(nonnull NSArray *)segments totalTime:(CGFloat)totalTime
{
    // 过滤掉 0 的输入
    segments = [segments acc_filter:^BOOL(NSNumber *obj) {
        return obj.floatValue != 0;
    }];

    // 删除最后一个 segment 时，reset
    if (!self.reshootMode && segments.count == 0 && self.progress == 0 && self.state == ACCRecordButtonPaused) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kACCRecordAnimateDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 异步等待期间，状态可能发生了变化
            if (self.progress == 0 && self.state == ACCRecordButtonPaused) {
                self.state = ACCRecordButtonBegin;
            }
        });
    }

    // normalize to 0.0-1.0
    NSMutableArray *mapped = [NSMutableArray array];
    [segments enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        if (totalTime != 0) {
            [mapped addObject:@(obj.floatValue / totalTime)];
        }
    }];

    self.ringView.marks = mapped;
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return @"拍摄";
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
