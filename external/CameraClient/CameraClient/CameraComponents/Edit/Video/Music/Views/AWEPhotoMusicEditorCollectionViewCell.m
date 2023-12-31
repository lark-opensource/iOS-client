//
//  AWEPhotoMusicEditorCollectionViewCell.m
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/21.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEPhotoMusicEditorCollectionViewCell.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCMainServiceProtocol.h"

@interface AWEPhotoMusicEditorCollectionViewCell()

@property (nonatomic, strong) UIImageView *downloadIcon;
@property (nonatomic, strong) UIImageView *loadingIcon;
@property (nonatomic, assign) AWEPhotoMovieMusicStatus downloadStatus;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *recommendedImageView;
@property (nonatomic, copy) NSString *orignalText;

@end

@implementation AWEPhotoMusicEditorCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.musicItemView addSubview:self.recommendedImageView];
        [self.contentView addSubview:self.musicItemView];
        [self.contentView addSubview:self.downloadIcon];
        [self.contentView addSubview:self.loadingIcon];
        [self.contentView addSubview:self.titleLabel];
        self.titleLabelColor = ACCResourceColor(ACCUIColorTextTertiary);
    
        ACCMasMaker(self.musicItemView, {
            make.top.equalTo(self.contentView);
            make.centerX.equalTo(self.contentView);
            make.width.height.equalTo(@57);
        });
        
        ACCMasMaker(self.downloadIcon, {
            make.right.equalTo(self.musicItemView.mas_right).offset(-4);
            make.bottom.equalTo(self.musicItemView.mas_bottom).offset(-4);
            make.width.height.equalTo(@15);
        });
        
        ACCMasMaker(self.loadingIcon, {
            make.right.equalTo(self.musicItemView.mas_right).offset(-4);
            make.bottom.equalTo(self.musicItemView.mas_bottom).offset(-4);
            make.width.height.equalTo(@15);
        });
        
        ACCMasMaker(self.titleLabel, {
            make.left.equalTo(self.contentView.mas_left);
            make.right.equalTo(self.contentView.mas_right);
            make.top.equalTo(self.musicItemView.mas_bottom).offset(4);
            make.height.equalTo(@15);
        });
        
        ACCMasMaker(self.recommendedImageView, {
            make.left.equalTo(@(3));
            make.top.equalTo(@(4.1));
            make.right.bottom.equalTo(@(-3));
        });
    }
    return self;
}

#pragma mark - Getters
- (AWEPhotoMovieMusicItemView *)musicItemView
{
    if (!_musicItemView) {
        _musicItemView = [[AWEPhotoMovieMusicItemView alloc] initWithImageSize:CGSizeMake(49, 49)];
        _musicItemView.userInteractionEnabled = NO;
    }
    return _musicItemView;
}

- (UIImageView *)downloadIcon
{
    if (!_downloadIcon) {
        _downloadIcon = [[UIImageView alloc] init];
        _downloadIcon.image = ACCResourceImage(@"iconDownloadMusic");
    }
    return _downloadIcon;
}

- (UIImageView *)loadingIcon
{
    if (!_loadingIcon) {
        _loadingIcon = [[UIImageView alloc] init];
        _loadingIcon.image = ACCResourceImage(@"iconDownloadingMusic");
    }
    return _loadingIcon;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:11];
        _titleLabel.textColor = self.titleLabelColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)recommendedImageView
{
    if (!_recommendedImageView) {
        _recommendedImageView = [[UIImageView alloc] init];
        _recommendedImageView.image = ACCResourceImage(@"icon_mv_recommended_old");
        _recommendedImageView.hidden = YES;
    }
    return _recommendedImageView;
}

#pragma mark - Setters
- (void)setUseBigLoadingIcon:(BOOL)useBigLoadingIcon
{
    _useBigLoadingIcon = useBigLoadingIcon;
    if (useBigLoadingIcon) {
        self.loadingIcon.image = ACCResourceImage(@"iconMusicLoading_ai");
        ACCMasReMaker(self.loadingIcon, {
            make.center.equalTo(self.musicItemView);
            make.width.height.equalTo(@16);
        });
    } else {
        self.loadingIcon.image = ACCResourceImage(@"iconDownloadingMusic");
        ACCMasReMaker(self.loadingIcon, {
            make.right.equalTo(self.musicItemView.mas_right).offset(-4);
            make.bottom.equalTo(self.musicItemView.mas_bottom).offset(-4);
            make.width.height.equalTo(@15);
        });
    }
}

- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList
{
    [self.musicItemView setMusicThumbnailURLList:thumbnailURLList];
}

- (void)setMusicThumbnailImage:(UIImage *)image
{
    [self.musicItemView setImage:image];
}

- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder
{
    [self.musicItemView setMusicThumbnailURLList:thumbnailURLList placeholder:placeholder];
}

- (void)setDownloadStatus:(AWEPhotoMovieMusicStatus)downloadStatus
{
    _downloadStatus = downloadStatus;
    [self p_updateAppearance];
}

- (void)setIsRecommended:(BOOL)isRecommended
{
    self.recommendedImageView.hidden = !isRecommended;
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCMainServiceProtocol) isPersonalRecommendSwitchOn]) {
        self.recommendedImageView.hidden = YES;
    }
}

- (void)setIsCurrent:(BOOL)isCurrent
            animated:(BOOL)animated
{
    acc_dispatch_main_async_safe(^{
        [self setIsCurrent:isCurrent animated:animated completion:nil];
    });
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    if (animated == NO) {
        [self.musicItemView setSelected:isCurrent];
        self.titleLabel.textColor = isCurrent ? ACCResourceColor(ACCColorPrimary) : self.titleLabelColor;
    } else {
        if (isCurrent) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.musicItemView setSelected:YES];
                self.titleLabel.textColor = ACCResourceColor(ACCColorPrimary);
            } completion:completion];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                [self.musicItemView setSelected:NO];
                self.titleLabel.textColor = self.titleLabelColor;
            }completion:completion];
        }
    }
}

- (void)setDuration:(NSTimeInterval)duration show:(BOOL)show
{
    [self.musicItemView setDuration:duration show:show];
}

- (void)p_updateAppearance
{
    switch (self.downloadStatus) {
        case AWEPhotoMovieMusicStatusNotDownload: {
            self.downloadIcon.hidden = NO;
            self.loadingIcon.hidden = YES;
            self.alpha = self.useBigLoadingIcon ? 1.0 : 0.5;
            [self.musicItemView setSelected:NO];
            [self p_stopDownloadAnimation];
        }
            break;
        case AWEPhotoMovieMusicStatusDownloading: {
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = NO;
            self.alpha = self.useBigLoadingIcon ? 0.66 : 0.5;
            [self.musicItemView setSelected:NO];
            [self p_startDownloadAnimation];
        }
            break;
        case AWEPhotoMovieMusicStatusDownloaded: {
            self.alpha = 1.f;
            self.downloadIcon.hidden = YES;
            self.loadingIcon.hidden = YES;
            [self.musicItemView setSelected:NO];
            [self p_stopDownloadAnimation];
        }
            break;
    }
    if (self.useBigLoadingIcon) {
        self.downloadIcon.hidden = YES;
    }
}

- (void)updateText:(NSString *)text
{
    _orignalText = text;
    self.titleLabel.text = text;
}

- (void)startPlayingAnimation
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anim.toValue = @(M_PI * 2.0);
    anim.duration = 6;
    anim.cumulative = YES;
    anim.repeatCount = FLT_MAX;
    [self.musicItemView.layer addAnimation:anim forKey:@"rotateAnimation"];
}

- (void)stopPalyingAnimation
{
    [self.musicItemView.layer removeAllAnimations];
}

#pragma mark - Animations
- (void)p_startDownloadAnimation
{
    [self.loadingIcon.layer removeAllAnimations];
    [self.loadingIcon.layer addAnimation:[self createRotationAnimation] forKey:@"rotation"];
}

- (void)p_stopDownloadAnimation
{
    [self.loadingIcon.layer removeAllAnimations];
}

- (CAAnimation *)createRotationAnimation {
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation * rotations * duration*/  ];
    rotationAnimation.duration = 0.8;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VAL;
    return rotationAnimation;
}
@end
