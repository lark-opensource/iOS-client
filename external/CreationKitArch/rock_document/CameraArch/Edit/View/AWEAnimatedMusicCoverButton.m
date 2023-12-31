//
//  AWEAnimatedMusicCoverButton.m
//  Aweme
//
//  Created by Bing Liu on 04/12/2017.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWEAnimatedMusicCoverButton.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface AWEAnimatedMusicCoverButton ()

@property (nonatomic ,strong) CALayer *loadingIcon;

@end

@implementation AWEAnimatedMusicCoverButton

- (UIImageView *)ownerImageView
{
    if (!_ownerImageView) {
        _ownerImageView = [UIImageView new];
        _ownerImageView.clipsToBounds = YES;
        _ownerImageView.layer.cornerRadius = self.ownerImageWidth ? self.ownerImageWidth / 2.0f : 21.0f / 2;
        
        if (self) {
            [self addSubview:_ownerImageView];
            
            ACCMasMaker(_ownerImageView, {
                make.width.height.equalTo(@(self.ownerImageWidth ?: 21));
                make.center.equalTo(self);
            });
        }
    }
    return _ownerImageView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self p_refreshLoadingIconPos];
}

- (void)refreshWithMusic:(id<ACCMusicModelProtocol>)music defaultAvatarURL:(NSArray *)URLList
{    
    [self setImage:self.defaultCover
                  forState:UIControlStateNormal];
    
    if (music.ownerNickname || music.musicName) {
        if (music.ownerNickname) {
            [ACCWebImage() imageView:self.ownerImageView setImageWithURLArray:music.mediumURL.URLList];
        } else {
            [ACCWebImage() button:self setImageWithURLArray:music.mediumURL.URLList forState:UIControlStateNormal placeholder:self.defaultCover completion:nil];
            self.ownerImageView.image = nil;
        }
    } else {
        [ACCWebImage() imageView:self.ownerImageView setImageWithURLArray:URLList];
    }
}

- (void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading == isLoading) {
        return;
    }
    _isLoading = isLoading;
    if (_isLoading) {
        [self.layer addSublayer:self.loadingIcon];
    } else {
        [self.loadingIcon removeFromSuperlayer];
    }
}

- (void)setLoadingIconCenterOffset:(CGPoint)loadingIconCenterOffset
{
    _loadingIconCenterOffset = loadingIconCenterOffset;
    [self p_refreshLoadingIconPos];
}

- (void)p_refreshLoadingIconPos
{
    if (self.isLoading) {
        CGFloat x = CGRectGetMidX(self.imageView.frame) ?: 16;
        CGFloat y = CGRectGetMidX(self.imageView.frame) ?: 16;
        self.loadingIcon.position = CGPointMake(x + self.loadingIconCenterOffset.x, y + self.loadingIconCenterOffset.y);
    }
}

- (CALayer *)loadingIcon
{
    if (!_loadingIcon) {
        _loadingIcon = [CALayer layer];
        _loadingIcon.bounds = CGRectMake(0, 0, 12, 12);
        _loadingIcon.contentsGravity = kCAGravityResizeAspectFill;
        _loadingIcon.contents = (id)ACCResourceImage(@"edit_music_loading").CGImage;
        NSMutableArray* keyFrameValues = [NSMutableArray array];
        [keyFrameValues addObject:[NSNumber numberWithFloat:0.01]];
        [keyFrameValues addObject:[NSNumber numberWithFloat:M_PI]];
        [keyFrameValues addObject:[NSNumber numberWithFloat:M_PI*2 - 0.001]];

        CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        animation.repeatCount = CGFLOAT_MAX;
        [animation setValues:keyFrameValues];
        [animation setValueFunction:[CAValueFunction functionWithName: kCAValueFunctionRotateZ]];// kCAValueFunctionRotateZ]]
        [animation setDuration:0.9];
        [_loadingIcon addAnimation:animation forKey:nil];
    }
    return _loadingIcon;
}

@end
