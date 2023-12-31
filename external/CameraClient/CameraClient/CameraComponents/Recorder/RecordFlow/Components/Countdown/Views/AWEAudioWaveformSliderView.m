//
//  AWEAudioWaveformSliderView.m
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEAudioWaveformSliderView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWECountDownBarChartView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>

typedef enum : NSUInteger {
    AWEAudioWaveformSliderViewTouchTypeBegin,
    AWEAudioWaveformSliderViewTouchTypeMoved,
    AWEAudioWaveformSliderViewTouchTypeEnd,
} AWEAudioWaveformSliderViewTouchType;

static const CGFloat kAWEAudioWaveformLabelCenterY = -11.5;

@interface AWEAudioWaveformSliderView ()

@property (nonatomic, assign) CGFloat positionPercent;//记录位置百分比
@property (nonatomic, assign) CGFloat maxDuration;//记录总时间

@property (nonatomic, strong) AWEAudioWaveformView *waveformView;//有音乐时波形图
@property (nonatomic, strong) UIView *nomuiscWaveformView;//没有音乐时的波形图
@property (nonatomic, strong) AWECountDownBarChartView *waveBarView; // 音乐柱状波形图
@property (nonatomic, strong) UIImageView *nomuiscWaveformUpImageView;
@property (nonatomic, strong) UIImageView *nomuiscWaveformDownImageView;

@property (nonatomic, strong) UIImageView *controlView;
@property (nonatomic, strong) UIView *selectedView;
@property (nonatomic, strong) UILabel *bottomLeftLabel;
@property (nonatomic, strong) UILabel *bottomRightLabel;
@property (nonatomic, strong) UILabel *bottomMiddleLabel;

@end

@implementation AWEAudioWaveformSliderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.positionPercent = 1.0;
        [self addSubview:self.waveformView];
        [self addSubview:self.waveBarView];
        [self addSubview:self.nomuiscWaveformView];
        [self addSubview:self.bottomLeftLabel];
        [self addSubview:self.bottomMiddleLabel];
        [self addSubview:self.bottomRightLabel];
        [self addSubview:self.controlView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat selfHeight = CGRectGetHeight(self.frame);
    CGFloat selfWidth = CGRectGetWidth(self.frame);
    
    CGFloat topMargin = 0;
    CGFloat leftMargin = 0;
    
    CGFloat colorBarHeight = selfHeight - 2 * topMargin;
    CGFloat colorBarWidth = selfWidth - 2 * leftMargin;
    
    self.waveformView.frame = CGRectMake(leftMargin, topMargin, colorBarWidth, colorBarHeight);
    self.waveBarView.frame = CGRectMake(leftMargin, topMargin, colorBarWidth, colorBarHeight);
    
    self.nomuiscWaveformView.frame = self.waveformView.frame;
    self.nomuiscWaveformUpImageView.frame = CGRectMake(0, CGRectGetMidY(self.nomuiscWaveformView.frame) - self.nomuiscWaveformUpImageView.acc_height, self.nomuiscWaveformView.acc_width, self.nomuiscWaveformUpImageView.acc_height);
    self.nomuiscWaveformDownImageView.frame = CGRectMake(0, CGRectGetMidY(self.nomuiscWaveformView.frame), self.nomuiscWaveformView.acc_width, self.nomuiscWaveformDownImageView.acc_height);
    
    self.controlView.frame = CGRectMake(0, 0, 13, 64);
    self.controlView.center = CGPointMake(leftMargin + colorBarWidth * self.positionPercent, CGRectGetHeight(self.frame) / 2);
    self.bottomLeftLabel.center = CGPointMake(self.waveformView.acc_left, kAWEAudioWaveformLabelCenterY);
}

#pragma mark - public
- (void)updateWaveUIWithVolumes:(NSArray *)volumes
{
    if (volumes.count == 0) {
        self.waveBarView.hidden = YES;
        self.nomuiscWaveformView.hidden = NO;
    } else {
        self.waveBarView.hidden = NO;
        self.nomuiscWaveformView.hidden = YES;
        [self.waveBarView updateBarWithHeights:volumes];
    }
}

//代码移动控制条
- (void)moveControlViewByCodeWithPercent:(CGFloat)percent
{
    if (percent > 1) {
        percent = 1;
    }
    self.positionPercent = percent;
    if (self.usingBarView) {
        self.waveBarView.countDownLocation = self.positionPercent;
    } else {
        self.waveformView.toBePlayedLocation = self.positionPercent;
    }
    self.countDownModel.toBePlayedLocation = self.positionPercent;
    self.controlView.center = CGPointMake(self.positionPercent * self.acc_width, CGRectGetMidY(self.bounds));
    [self updateMiddleLableWithCenterX:percent * self.acc_width];
    self.bottomMiddleLabel.hidden = YES;
    self.bottomRightLabel.hidden = NO;
}

//更新底部的时间
- (void)updateMiddleLableWithCenterX:(CGFloat)centerX
{
    self.bottomMiddleLabel.hidden = NO;
    
    NSString *formatString = self.positionPercent == 1 ? @"%.0fs" : @"%.1fs";
    self.bottomMiddleLabel.text = [NSString stringWithFormat:formatString, self.positionPercent * self.maxDuration];
    [self.bottomMiddleLabel sizeToFit];
    
    self.bottomMiddleLabel.center = CGPointMake(centerX, kAWEAudioWaveformLabelCenterY);
    if (CGRectIntersectsRect(self.bottomMiddleLabel.frame, self.bottomRightLabel.frame)) {
        self.bottomRightLabel.hidden = YES;
    } else {
        self.bottomRightLabel.hidden = NO;
    }
    if (CGRectIntersectsRect(self.bottomMiddleLabel.frame, self.bottomLeftLabel.frame)) {
        self.bottomLeftLabel.hidden = YES;
    } else {
        self.bottomLeftLabel.hidden = NO;
    }
}

- (CGFloat)waveBarCountForFullWidth
{
    return [self.waveBarView barCountForFullWidth];
}

- (void)setUpdateMusicBlock:(void (^)(void))updateMusicBlock
{
    self.waveBarView.updateMusicBlock = updateMusicBlock;
}

- (void)setUsingBarView:(BOOL)usingBarView
{
    _usingBarView = usingBarView;
    self.waveBarView.hidden = !usingBarView;
    self.waveformView.hidden = usingBarView;
}

#pragma mark - touch event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self moveControlView:touches type:AWEAudioWaveformSliderViewTouchTypeBegin];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self moveControlView:touches type:AWEAudioWaveformSliderViewTouchTypeMoved];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self moveControlView:touches type:AWEAudioWaveformSliderViewTouchTypeEnd];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint handlePoint = point;
    UIView *targetView = self.usingBarView ? self.waveBarView : self.waveformView;
    CGRect largerRect = CGRectInset(targetView.bounds, -20, -20);
    
    if (CGRectContainsPoint(largerRect, handlePoint)) {//认为选中了controlView
        if (self.alpha > 0.01 && self.hidden == NO) {
            self.selectedView = self.controlView;
            return self;
        } else {
            self.selectedView = nil;
            return nil;
        }
    } else {//没有选中controlView
        self.selectedView = nil;
        return nil;
    }
}

#pragma mark -

- (void)updateRightLabelWithMaxDuration:(CGFloat)maxDuration
{
    self.maxDuration = maxDuration;
    NSString *text = [NSString stringWithFormat:@"%.0fs", maxDuration];
    if ([self.bottomRightLabel.text isEqualToString:text]) {
        return;
    }
    self.bottomRightLabel.text = text;
    [self.bottomRightLabel sizeToFit];
    self.bottomRightLabel.center = CGPointMake(self.waveformView.acc_right, kAWEAudioWaveformLabelCenterY);
}

- (void)moveControlView:(NSSet<UITouch *> *)touches type:(AWEAudioWaveformSliderViewTouchType)type
{
    if (self.selectedView) {
        CGFloat septime = 0.1;//0.1s
        CGFloat sepMargin = (septime / self.maxDuration) * self.acc_width;

        CGPoint location = [[touches anyObject] locationInView:self];
        CGPoint handlePoint = CGPointMake(location.x, CGRectGetHeight(self.bounds) / 2);
        CGFloat width = CGRectGetWidth(self.bounds);
        
        if (self.usingBarView) {
            if (handlePoint.x < self.waveBarView.hasRecordedLocation * width + sepMargin) {
                handlePoint.x = self.waveBarView.hasRecordedLocation * width + sepMargin;
            } else if (handlePoint.x > width) {
                handlePoint.x = width;
            }
        } else {
            if (handlePoint.x < self.waveformView.hasRecordedLocation * width + sepMargin) {
                handlePoint.x = self.waveformView.hasRecordedLocation * width + sepMargin;
            } else if (handlePoint.x > width) {
                handlePoint.x = width;
            }
        }

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.controlView.center = handlePoint;
        [CATransaction commit];
        self.positionPercent = handlePoint.x / CGRectGetWidth(self.bounds);
        switch (type) {
            case AWEAudioWaveformSliderViewTouchTypeBegin:
                if ([self.delegate respondsToSelector:@selector(audioWaveformSliderViewTouchBegin)]) {
                    [self.delegate audioWaveformSliderViewTouchBegin];
                }
                break;
            case AWEAudioWaveformSliderViewTouchTypeMoved:
                if ([self.delegate respondsToSelector:@selector(audioWaveformSliderViewTouchMoved)]) {
                    [self.delegate audioWaveformSliderViewTouchMoved];
                }
                break;
            case AWEAudioWaveformSliderViewTouchTypeEnd:
                if ([self.delegate respondsToSelector:@selector(audioWaveformSliderView:touchEnd:)]) {
                    [self.delegate audioWaveformSliderView:self touchEnd:self.positionPercent];
                }
                break;
        }
        
        [self updateMiddleLableWithCenterX:handlePoint.x];

        self.countDownModel.toBePlayedLocation = self.positionPercent;
        if (self.usingBarView) {
            self.waveBarView.countDownLocation = self.positionPercent;
        } else {
            self.waveformView.toBePlayedLocation = self.positionPercent;
            [self.waveformView setNeedsDisplay];
        }
    }
}

#pragma mark - getter

- (AWEAudioWaveformView *)waveformView
{
    if (_waveformView == nil) {
        _waveformView = [[AWEAudioWaveformView alloc] init];
    }
    return _waveformView;
}

- (AWECountDownBarChartView *)waveBarView
{
    if (_waveBarView == nil) {
        _waveBarView = [[AWECountDownBarChartView alloc] init];
        _waveBarView.barWidth = 2.0;
        _waveBarView.space = 2.0;
        _waveBarView.maxBarHeight = 48.0;
        _waveBarView.minBarHeight = 4.0;
    }
    return _waveBarView;
}

- (UIImageView *)controlView
{
    if (_controlView == nil) {
        _controlView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"imgTiao")];
        _controlView.userInteractionEnabled = NO;
        _controlView.isAccessibilityElement = NO;
    }
    return _controlView;
}

- (UILabel *)bottomLeftLabel
{
    if (!_bottomLeftLabel) {
        _bottomLeftLabel = [[UILabel alloc] init];
        _bottomLeftLabel.text = @"0s";
        _bottomLeftLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightSemibold];
        _bottomLeftLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary3);
        [_bottomLeftLabel sizeToFit];
    }
    return _bottomLeftLabel;
}

- (UILabel *)bottomRightLabel
{
    if (!_bottomRightLabel) {
        _bottomRightLabel = [[UILabel alloc] init];
        _bottomRightLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightSemibold];
        _bottomRightLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary3);
    }
    return _bottomRightLabel;
}

- (UILabel *)bottomMiddleLabel
{
    if (!_bottomMiddleLabel) {
        _bottomMiddleLabel = [[UILabel alloc] init];
        _bottomMiddleLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightSemibold];
        _bottomMiddleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    }
    return _bottomMiddleLabel;
}

- (UIView *)nomuiscWaveformView
{
    if (!_nomuiscWaveformView) {
        _nomuiscWaveformView = [[UIView alloc] init];
        _nomuiscWaveformUpImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"img_nomusictracks")];
        _nomuiscWaveformDownImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"img_nomusictracks")];
        _nomuiscWaveformDownImageView.transform = CGAffineTransformMakeScale(1, -1);
        [_nomuiscWaveformView addSubview:_nomuiscWaveformUpImageView];
        [_nomuiscWaveformView addSubview:_nomuiscWaveformDownImageView];
    }
    return _nomuiscWaveformView;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement
{
    self.positionPercent = MIN(1.0, self.positionPercent + 0.1);
    [self hanldePositionPercentChanged];
}

- (void)accessibilityDecrement
{
    self.positionPercent = MAX(0.f, self.positionPercent - 0.1);
    [self hanldePositionPercentChanged];
}

- (NSString *)accessibilityLabel
{
    return @"调整暂停位置";
}

- (void)hanldePositionPercentChanged
{
    CGPoint handlePoint = self.controlView.center;
    handlePoint.x = self.positionPercent * CGRectGetWidth(self.bounds);
    self.controlView.center = handlePoint;
    
    if ([self.delegate respondsToSelector:@selector(audioWaveformSliderView:touchEnd:)]) {
        [self.delegate audioWaveformSliderView:self touchEnd:self.positionPercent];
    }
    [self updateMiddleLableWithCenterX:handlePoint.x];

    self.countDownModel.toBePlayedLocation = self.positionPercent;
    if (self.usingBarView) {
        self.waveBarView.countDownLocation = self.positionPercent;
    } else {
        self.waveformView.toBePlayedLocation = self.positionPercent;
        [self.waveformView setNeedsDisplay];
    }
    [ACCAccessibility() postAccessibilityNotification:UIAccessibilityAnnouncementNotification argument:[NSString stringWithFormat:@"调整暂停位置至%.1f秒", self.positionPercent * self.maxDuration]];
}

@end
