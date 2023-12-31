//
//  ACCLoadingAndVolumeView.m
//  Aweme
//
//  Created by hanxu on 2017/2/27.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCLoadingAndVolumeView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>

typedef NS_ENUM(NSInteger, ACCVideoPlayInfoViewStatus) {
    ACCVideoPlayInfoViewStatusNone,
    ACCVideoPlayInfoViewStatusLoading,
    ACCVideoPlayInfoViewStatusVolume,
    ACCVideoPlayInfoViewStatusProgress,
};

@interface ACCLoadingAndVolumeView ()

@property (nonatomic, assign) BOOL showVolume;
@property (nonatomic, assign) ACCVideoPlayInfoViewStatus status;

@property (nonatomic ,assign) CGFloat lastVolume;
/**
 * 底部阴影view
 */
@property (nonatomic, strong) UIView *bottomView;

/**
 * 缓冲动画view
 */
@property (nonatomic, strong) UIView *animationView;

/**
 * 音量控制view
 */
@property (nonatomic, strong) UIView *volumeView;

/**
 * 播放进度view
 */
@property (nonatomic, strong) UIView *progressView;

@end

@implementation ACCLoadingAndVolumeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.isLoading = NO;
        self.backgroundColor = [UIColor clearColor];
        
        self.bottomView = [[UIView alloc] init];
        self.bottomView.backgroundColor = [UIColor clearColor];
        
        self.animationView = [[UIView alloc] init];
        self.animationView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        
        self.volumeView = [[UIView alloc] init];
        self.volumeView.backgroundColor = ACCResourceColor(ACCUIColorSecondary);
        
        self.progressView = [[UIView alloc] init];
        self.progressView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        
        self.bottomView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        self.animationView.frame = CGRectMake(frame.size.width * 0.5, 0, 1, frame.size.height);
        self.volumeView.frame = CGRectMake(0, 0, 1, frame.size.height);
        self.progressView.frame = CGRectMake(0, 0, 0, frame.size.height);
        
        [self addSubview:self.bottomView];
        [self addSubview:self.animationView];
        [self addSubview:self.volumeView];
        [self addSubview:self.progressView];
        
        self.status = ACCVideoPlayInfoViewStatusNone;
        
        self.showProgress = YES;
    }
    return self;
}

- (void)updateStatus
{
    if (self.showVolume) {
        self.status = ACCVideoPlayInfoViewStatusVolume;
    } else if (self.isLoading) {
        self.status = ACCVideoPlayInfoViewStatusLoading;
    } else if (self.showProgress) {
        self.status = ACCVideoPlayInfoViewStatusProgress;
    } else {
        self.status = ACCVideoPlayInfoViewStatusNone;
    }
}

- (void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading != isLoading) {
        _isLoading = isLoading;
        if (!isLoading) {
            [self hideAndEndAnimation];
        }
        
        [self updateStatus];
    }
}

- (void)setShowProgress:(BOOL)showProgress
{
    if (_showProgress != showProgress) {
        _showProgress = showProgress;
        [self updateStatus];
    }
}

- (void)setShowVolume:(BOOL)showVolume
{
    if (_showVolume != showVolume) {
        _showVolume = showVolume;
        [self updateStatus];
    }
}

- (void)setStatus:(ACCVideoPlayInfoViewStatus)status
{
    if (_status == status) {
        return;
    }
    ACCVideoPlayInfoViewStatus lastStatus = _status;
    _status = status;
    
    switch (status) {
        case ACCVideoPlayInfoViewStatusNone:
        {
            [self hideAndEndAnimation];
        }
            break;
        case ACCVideoPlayInfoViewStatusLoading:
        {
            self.hidden = NO;
            self.volumeView.hidden = YES;
            self.progressView.hidden = YES;
            self.animationView.hidden = NO;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.status == ACCVideoPlayInfoViewStatusLoading) {
                    [self beginCenterToSideAnimation];
                }
            });
        }
            break;
        case ACCVideoPlayInfoViewStatusVolume:
        {
            self.hidden = NO;
            self.progressView.hidden = YES;
            self.animationView.hidden = YES;
            self.volumeView.hidden = NO;
        }
            break;
        case ACCVideoPlayInfoViewStatusProgress:
        {
            self.hidden = NO;
            self.alpha = 1;

            self.progressView.hidden = NO;
            self.animationView.hidden = YES;
            self.volumeView.hidden = YES;
            [self.bottomView.layer removeAllAnimations];
            self.bottomView.alpha = 1;
            
            [UIView animateWithDuration:0.15 animations:^{
                self.progressView.alpha = 1.0;
            } completion:nil];
        }
            break;
        default:
            break;
    }
    
    if (lastStatus == ACCVideoPlayInfoViewStatusProgress) {
        [UIView animateWithDuration:0.15 animations:^{
            self.progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progressView.hidden = YES;
        }];
    }
}

- (void)hideAndEndAnimation
{
    self.hidden = YES;
    [self.animationView.layer removeAllAnimations];
    [self.bottomView.layer removeAllAnimations];
    [self.volumeView.layer removeAllAnimations];
    [self.progressView.layer removeAllAnimations];
}

- (void)beginCenterToSideAnimation
{
    [self.animationView.layer removeAllAnimations];
    [self.bottomView.layer removeAllAnimations];
    self.alpha = 1;
    self.bottomView.alpha = 0;
    
    self.isLoading = YES;

    self.animationView.alpha = 0;
    self.animationView.frame = CGRectMake(self.bounds.size.width * 0.5, 0, 1, self.bounds.size.height);
    
    [UIView animateWithDuration:0.2 animations:^{
        self.bottomView.alpha = 1;
    } completion:^(BOOL finished) {

        CAKeyframeAnimation *alphaAnim = [CAKeyframeAnimation animation];
        alphaAnim.duration = 0.5;
        alphaAnim.keyPath = @"opacity";
        alphaAnim.values = @[@(0),@(1),@(0)];
        alphaAnim.keyTimes = @[@(0),@(0.6),@(1)];
        alphaAnim.repeatCount = MAXFLOAT;
        alphaAnim.removedOnCompletion = NO;
        
        CABasicAnimation *widthAnim = [CABasicAnimation animationWithKeyPath:@"bounds.size.width"];
        widthAnim.duration = 0.5;
        widthAnim.fromValue = 0;
        widthAnim.toValue = @(self.frame.size.width);
        widthAnim.repeatCount = MAXFLOAT;
        widthAnim.removedOnCompletion = NO;

        [self.animationView.layer addAnimation:alphaAnim forKey:nil];
        [self.animationView.layer addAnimation:widthAnim forKey:nil];
    }];
}

- (void)setVolume:(CGFloat)volume
{
    self.showVolume = YES;

    self.lastVolume = volume;
    
    [self.layer removeAllAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_dismiss) object:nil];

    [self.bottomView.layer removeAllAnimations];
    self.alpha = 1;
    self.volumeView.alpha = 1;
    self.bottomView.alpha = 1;
    CGRect rect = CGRectMake(0, 0, volume * self.frame.size.width, self.animationView.frame.size.height);
    [UIView animateWithDuration:0.2 animations:^{
        self.volumeView.frame = rect;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(_dismiss) withObject:nil afterDelay:0.4];
    }];
}

- (void)_dismiss
{
    [UIView animateWithDuration:0.4 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.showVolume = NO;
        }
    }];
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    
    if (self.status != ACCVideoPlayInfoViewStatusProgress) {
        return;
    }

    self.progressView.frame = CGRectMake(0, 0, progress * self.frame.size.width, self.animationView.frame.size.height);
}

@end
