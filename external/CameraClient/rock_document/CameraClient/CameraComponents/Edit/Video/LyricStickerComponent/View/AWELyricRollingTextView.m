//
//  AWELyricRollingTextView.m
//  RollingTextViewDemo
//
//  Created by 赖霄冰 on 2019/1/9.
//  Copyright © 2019 赖霄冰. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWELyricRollingTextView.h"
#import "AWELyricPattern.h"
#import "AWEMusicSelectItem.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <Masonry/View+MASAdditions.h>

static CGFloat const kRollingTextLabelPadding = 0.0f;

@interface AWELyricRollingTextView()
@property (nonatomic, strong) UIView *rollingContainerView;
@property (nonatomic, strong) UILabel *rollingTextLabel;

@property (nonatomic, assign) CGFloat distance;
@property (nonatomic, copy) NSString *rollingText;
@property (nonatomic, strong) UIColor *rollingTextColor;
@property (nonatomic, strong) UIFont *rollingTextFont;
@property (nonatomic, assign) NSInteger currentIndex;
@end

@implementation AWELyricRollingTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)configureWithFont:(UIFont *)font textColor:(UIColor *)textColor
{
    self.rollingText = @"";
    self.rollingTextFont = font;
    self.rollingTextColor = textColor;
    [self p_clearSubviews];
    [self p_createRollingContainerView];
}

- (void)updateWithRollingText:(NSString *)text {
    NSAssert(self.rollingText &&
             self.rollingTextFont &&
             self.rollingTextColor, @"调用此方法前请先调用 - (void)configureWithFont:方法！");
    self.rollingText = text;
    [self p_clearSubviews];
    [self p_createRollingContainerView];
}

- (void)p_clearSubviews {
    [self.rollingContainerView.layer removeAllAnimations];
    [self.rollingTextLabel removeFromSuperview];
    [self.rollingContainerView removeFromSuperview];
    self.rollingContainerView = nil;
}

- (void)p_createRollingContainerView {
    _rollingContainerView = [[UIView alloc] init];
    _rollingContainerView.backgroundColor = [UIColor clearColor];
    _rollingContainerView.userInteractionEnabled = NO;
    [self addSubview:_rollingContainerView];
    [self.rollingContainerView addSubview:self.rollingTextLabel];
    self.rollingTextLabel.text = self.rollingText;
    [self.rollingTextLabel sizeToFit];
    CGFloat width = self.rollingTextLabel.frame.size.width + 2 * kRollingTextLabelPadding;
    self.rollingContainerView.frame = CGRectMake(0, 0, width, self.frame.size.height);
    ACCMasMaker(self.rollingTextLabel, {
        make.left.equalTo(self.rollingContainerView).offset(kRollingTextLabelPadding);
        make.centerY.equalTo(self.rollingContainerView);
    });
    self.distance = ![self p_shouldRolling] ? 0.f : (width - self.frame.size.width);
}

- (BOOL)p_shouldRolling {
    return self.rollingTextLabel.frame.size.width > self.frame.size.width;
}

- (UILabel *)p_createRollingLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.font = self.rollingTextFont;
    label.textColor = self.rollingTextColor;
    label.text = self.rollingText;
    [label sizeToFit];
    label.userInteractionEnabled = NO;
    return label;
}

#pragma mark - Animations
- (void)startAnimatingWithDuration:(NSTimeInterval)duration
{
    [self p_startRollingTextWithDuration:duration andDelay:0];
}

- (void)startAnimatingWithDuration:(NSTimeInterval)duration andDelay:(NSTimeInterval)delay {
    [self p_startRollingTextWithDuration:duration andDelay:delay];
}

- (void)pauseAnimating
{
    CFTimeInterval pausedTime = [self.rollingContainerView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.rollingContainerView.layer.speed = 0.0;
    self.rollingContainerView.layer.timeOffset = pausedTime;
}

- (void)resumeAnimating
{
    CFTimeInterval pausedTime = [self.rollingContainerView.layer timeOffset];
    self.rollingContainerView.layer.speed = 1.0;
    self.rollingContainerView.layer.timeOffset = 0.0;
    self.rollingContainerView.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.rollingContainerView.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.rollingContainerView.layer.beginTime = timeSincePause;
}

- (void)stopAnimatingWithCompletion:(void (^)(void))completion
{
    [self.rollingContainerView.layer removeAllAnimations];
    ACCBLOCK_INVOKE(completion);
}

- (void)p_startRollingTextWithDuration:(NSTimeInterval)duration andDelay:(NSTimeInterval)delay
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.duration = duration;
    animation.fromValue = @(0);
    animation.toValue = @(-self.distance);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = 1;
    animation.beginTime = CACurrentMediaTime() + delay;
    self.rollingContainerView.layer.speed = 1.0;
    [self.rollingContainerView.layer addAnimation:animation forKey:nil];
}

- (UILabel *)rollingTextLabel {
    if (!_rollingTextLabel) {
        _rollingTextLabel = [self p_createRollingLabel];
    }
    return _rollingTextLabel;
}

- (void)updateWithSelectedMusic:(AWEMusicSelectItem *)item timePassed:(NSTimeInterval)timePassed
{
    if (item.musicModel.lyricType == ACCMusicLyricTypeTXT) {
        if (ACC_FLOAT_EQUAL_ZERO(timePassed)) {
            [self updateWithRollingText:item.lyrics.firstObject.lyricText];
            [self startAnimatingWithDuration:item.songTimeLength];
            
            AWELogToolInfo(AWELogToolTagEdit, @"timepass:%.2f lyricText:%@",timePassed,item.lyrics.firstObject.lyricText);
        }
    } else if (item.musicModel.lyricType == ACCMusicLyricTypeJSON) {
        CGFloat realTime = item.startTime + timePassed;
        if (ACC_FLOAT_EQUAL_ZERO(timePassed)) {
            self.currentIndex = item.startLyricIndex;
            if (item.lyrics.count > self.currentIndex) {
                [self updateWithRollingText:item.lyrics[self.currentIndex].lyricText];
                [self startAnimatingWithDuration:3.0f];
                
                AWELogToolInfo(AWELogToolTagEdit, @"timepass:%.2f lyricText:%@",timePassed,item.lyrics[self.currentIndex].lyricText);
            }
        } else {
            if (self.currentIndex <  item.lyrics.count - 1) {
                if (ACC_FLOAT_GREATER_THAN(realTime, item.lyrics[self.currentIndex + 1].timestamp)) {
                    // 切换片段逻辑在这
                    self.currentIndex += 1;
                    
                    AWELyricPattern *current = [item.lyrics acc_objectAtIndex:self.currentIndex];
                    AWELyricPattern *next = self.currentIndex <  item.lyrics.count - 1 ? [item.lyrics acc_objectAtIndex:self.currentIndex+1] : nil;
                    
                    if (current) {
                        [self updateWithRollingText:current.lyricText];
                        AWELogToolInfo(AWELogToolTagEdit, @"timepass:%.2f lyricText:%@",timePassed,current.lyricText);
                        
                        CGFloat distance = self.distance;
                        NSTimeInterval interval = next ? next.timestamp - current.timestamp : item.songTimeLength - current.timestamp;
                        if (ACC_FLOAT_GREATER_THAN(distance, 0)) {
                            // 这0.75s是为了歌词滑动到结束后停留一段时间，增加体验
                            interval -= .75;
                        }
                        CGFloat defaultSpeed = 32.f;
                        NSTimeInterval theoryDuration = distance / defaultSpeed;
                        NSTimeInterval actualDuration = ACC_FLOAT_GREATER_THAN(theoryDuration, interval) ? interval : theoryDuration;
                        NSTimeInterval delay = ACC_FLOAT_EQUAL_TO(actualDuration, interval) ? 0 : interval - actualDuration;
                        
                        [self startAnimatingWithDuration:actualDuration andDelay:delay];
                    }
                }
            }
        }
    }
}

- (void)resetWithNewStartIndex:(NSInteger)idx
{
    self.currentIndex = idx;
}

@end
