//
//  CAKAnimatedButton.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import "CAKAnimatedButton.h"
#import <AVFoundation/AVFoundation.h>

@interface CAKAnimatedButton ()

@property (nonatomic, assign) CAKAnimatedButtonType type;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong, nullable) NSValue *transformBeforeAnimation;

@end

@implementation CAKAnimatedButton

- (instancetype)initWithType:(CAKAnimatedButtonType)type {
    
    return [self initWithFrame:CGRectZero type:type];
}

- (instancetype)initWithFrame:(CGRect)frame type:(CAKAnimatedButtonType)btnType {
    
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
    
    return [self initWithFrame:frame type:CAKAnimatedButtonTypeScale];
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
        if (currentState != highlighted) {
            [self.player play];
        }
        [UIView animateWithDuration:self.animationDuration animations:^{
            switch (self.type) {
                case CAKAnimatedButtonTypeScale: {
                    CGAffineTransform initialTransform = self.transform;
                    if (self.transformBeforeAnimation == nil) {
                        self.transformBeforeAnimation = [NSValue valueWithCGAffineTransform:self.transform];
                    } else {
                        initialTransform = [self.transformBeforeAnimation CGAffineTransformValue];
                    }
                    
                    self.transform = CGAffineTransformConcat(initialTransform, CGAffineTransformMakeScale(self.highlightedScale, self.highlightedScale));
                }
                    break;
                case CAKAnimatedButtonTypeAlpha:
                    self.alpha = 0.75;
                    break;
            }
        } completion:^(BOOL finished) {
        }];
    } else {
        [UIView animateWithDuration:self.animationDuration animations:^{
            switch (self.type) {
                case CAKAnimatedButtonTypeScale: {
                    CGAffineTransform transform = CGAffineTransformIdentity;
                    if (self.transformBeforeAnimation != nil) {
                        transform = [self.transformBeforeAnimation CGAffineTransformValue];
                    }
                    self.transform = transform;
                }
                    break;
                case CAKAnimatedButtonTypeAlpha:
                    self.alpha = 1.0;
                    break;
            }
        } completion:^(BOOL finished) {
            self.transformBeforeAnimation = nil;
        }];
    }
}


@end
