//
//  ACCAnimatedButton.m
//  Aweme
//
//  Created by xiangwu on 2017/6/8.
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "ACCAnimatedButton.h"
#import <AVFoundation/AVFoundation.h>

@interface ACCAnimatedButton ()

@property (nonatomic, assign) ACCAnimatedButtonType type;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong, nullable) NSValue *transformBeforeAnimation;

@end

@implementation ACCAnimatedButton

- (instancetype)initWithType:(ACCAnimatedButtonType)type {
    
    return [self initWithFrame:CGRectZero type:type];
}

- (instancetype)initWithFrame:(CGRect)frame type:(ACCAnimatedButtonType)btnType {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.adjustsImageWhenHighlighted = NO;
        _type = btnType;
        _animationDuration = 0.1;
        _highlightedScale = 1.2;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    return [self initWithFrame:frame type:ACCAnimatedButtonTypeScale];
}

- (void)setAudioURL:(NSURL *)audioURL
{
    if (_audioURL != audioURL) {
        _audioURL = audioURL;
        _player = nil;
        if (audioURL) {
            _player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:NULL];
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (self.downgrade) {
        [super setHighlighted:highlighted];
        return;
    }

    BOOL currentState = self.highlighted;
    [super setHighlighted:highlighted];
    if (highlighted) {
        if (!currentState) {
            [self.player play];
        } else {
            return;
        }
        [UIView animateWithDuration:self.animationDuration animations:^{
            switch (self.type) {
                case ACCAnimatedButtonTypeScale: {
                    CGAffineTransform initialTransform = self.transform;
                    if (self.transformBeforeAnimation == nil) {
                        self.transformBeforeAnimation = [NSValue valueWithCGAffineTransform:self.transform];
                    } else {
                        initialTransform = [self.transformBeforeAnimation CGAffineTransformValue];
                    }
                    
                    self.transform = CGAffineTransformConcat(initialTransform, CGAffineTransformMakeScale(self.highlightedScale, self.highlightedScale));
                }
                    break;
                case ACCAnimatedButtonTypeAlpha:
                    self.alpha = 0.75;
                    break;
            }
        } completion:^(BOOL finished) {
            
        }];
    } else {
        if (!currentState) {
            return;
        }
        [UIView animateWithDuration:self.animationDuration animations:^{
            switch (self.type) {
                case ACCAnimatedButtonTypeScale: {
                    CGAffineTransform transform = CGAffineTransformIdentity;
                    if (self.transformBeforeAnimation != nil) {
                        transform = [self.transformBeforeAnimation CGAffineTransformValue];
                    }
                    self.transform = transform;
                }
                    break;
                case ACCAnimatedButtonTypeAlpha:
                    self.alpha = 1.0;
                    break;
            }
        } completion:^(BOOL finished) {
            self.transformBeforeAnimation = nil;
        }];
    }
}

@end
