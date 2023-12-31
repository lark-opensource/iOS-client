//
//  ACCCutSamePlayerControlView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/2.
//

#import "ACCCutSamePlayerControlView.h"
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface ACCCutSamePlayerControlView ()

@property (nonatomic, strong) UIImageView *playImageView;

@end

@implementation ACCCutSamePlayerControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _playImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _playImageView.image = ACCResourceImage(@"iconBigplaymusic");
        _playImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _playImageView.contentMode = UIViewContentModeCenter;
        _playImageView.alpha = 0.0;
        [self addSubview:_playImageView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAction:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)onTapAction:(UITapGestureRecognizer *)tap
{
    if (self.tapAction) {
        self.tapAction();
    }
}

#pragma mark - Public API
- (void)setEnablePauseIcon:(BOOL)enablePauseIcon
{
    self.playImageView.hidden = !enablePauseIcon;
}

- (BOOL)enablePauseIcon
{
    return !self.playImageView.hidden;
}

- (void)showPauseWithAnimated:(BOOL)animated
{
    dispatch_block_t animations = ^{
        self.playImageView.transform = CGAffineTransformIdentity;
        self.playImageView.alpha = 1.0;
    };
    
    if (animated) {
        self.playImageView.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.15 animations:animations];
    } else {
        animations();
    }
}

- (void)hidePauseWithAnimated:(BOOL)animated
{
    dispatch_block_t animations = ^{
        self.playImageView.transform = CGAffineTransformIdentity;
        self.playImageView.alpha = 0.0;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.1 animations:animations];
    } else {
        animations();
    }
}

@end
