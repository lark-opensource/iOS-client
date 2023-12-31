//
//  AWEModernStickerCollectionViewCell.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWEModernStickerCollectionViewCell.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/AWEStickerMusicManager.h>
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import "AWEStickerMusicManager+Local.h"

#import <BDWebImage/BDWebImage.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <QuartzCore/QuartzCore.h>
#import <Masonry/View+MASAdditions.h>

#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"

@interface AWEModernStickerCollectionViewCell ()

@property (nonatomic, strong) BDImageView *iconImageView;
@property (nonatomic, strong) UIImageView *downloadImgView;
@property (nonatomic, strong) AWECircularProgressView *progressView;
@property (nonatomic, strong) UIImageView *loadingImgView;
@property (nonatomic, strong) AWEScrollStringLabel *propNameLabel;
@property (nonatomic, strong) CAGradientLayer *propNameGradientLayer;
@property (nonatomic, strong) IESEffectModel *effectModel;
@property (nonatomic, readwrite) IESEffectModel *childEffect;
@property (nonatomic, strong) UITapGestureRecognizer *tapGes;
@property (nonatomic, strong) UILongPressGestureRecognizer *longGes;

@property (nonatomic, strong) UIView *containerView;

@end

@implementation AWEModernStickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubviews];
        [self.contentView addGestureRecognizer:self.tapGes];
        [self.contentView addGestureRecognizer:self.longGes];
    }
    return self;
}

- (void)addSubviews
{
    [self.contentView addSubview:self.selectedIndicatorView];
    CGFloat yOffset = (self.contentView.acc_width * (1 - (60 / 71.5))) / 2; // Make sure the left edge inset and top edge inset are equal.
    ACCMasMaker(self.selectedIndicatorView, {
        make.width.height.equalTo(self.contentView.mas_width).multipliedBy(60 / 71.5);
        make.centerX.equalTo(self);
        make.top.equalTo(self).mas_offset(yOffset);
    });

    [self.contentView addSubview:self.iconImageView];
    ACCMasMaker(self.iconImageView, {
        make.width.height.equalTo(self.contentView.mas_width).multipliedBy(54 / 71.5);
        make.center.equalTo(self.selectedIndicatorView);
    });

    [self.contentView addSubview:self.downloadImgView];
    ACCMasMaker(self.downloadImgView, {
        make.width.height.equalTo(self.contentView.mas_width).multipliedBy(16 / 71.5);
        make.right.equalTo(self.iconImageView).offset(-1.f);
        make.bottom.equalTo(self.iconImageView).offset(-1.f);
    });
    
    [self.contentView addSubview:self.progressView];
    ACCMasMaker(self.progressView, {
        make.edges.equalTo(self.downloadImgView);
    });

    [self.contentView addSubview:self.loadingImgView];
    ACCMasMaker(self.loadingImgView, {
        make.center.equalTo(self.iconImageView);
    });

    [self.contentView addSubview:self.propNameLabel];
    ACCMasMaker(self.propNameLabel, {
        make.top.equalTo(self.selectedIndicatorView.mas_bottom);
        make.width.equalTo(self.contentView).multipliedBy(50 / 71.5);
        make.height.equalTo(@(14));
        make.centerX.equalTo(self.selectedIndicatorView);
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.propNameLabel layoutIfNeeded];
    self.propNameGradientLayer.frame = self.propNameLabel.bounds;
}

- (UILongPressGestureRecognizer *)longGes
{
    if (_longGes == nil) {
        _longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedAnimationWithGesture:)];
        _longGes.minimumPressDuration = 0.1;
        _longGes.cancelsTouchesInView = NO;
    }
    return _longGes;
}

- (UITapGestureRecognizer *)tapGes
{
    if (!_tapGes) {
        _tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnimation)];
        _tapGes.cancelsTouchesInView = NO;
    }
    return _tapGes;
}

- (void)longPressedAnimationWithGesture:(UILongPressGestureRecognizer *)ges
{
    CATransform3D transform = CATransform3DIdentity;
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:{
            transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
            break;
        }
        default:
            transform = CATransform3DIdentity;
            break;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.layer.transform = transform;
    }];
}

- (void)tapAnimation
{
    [UIView animateWithDuration:0.1 animations:^{
        self.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.layer.transform = CATransform3DIdentity;
            }];
        }
    }];
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        _containerView.layer.cornerRadius = 4;
        _containerView.layer.masksToBounds = YES;
    }
    return _containerView;
}

- (BDImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[BDImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.autoPlayAnimatedImage = YES;
    }
    return _iconImageView;
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] init];
        _selectedIndicatorView.backgroundColor = [UIColor clearColor];
        _selectedIndicatorView.layer.cornerRadius = 9;
        _selectedIndicatorView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        _selectedIndicatorView.layer.borderWidth = 2;
        _selectedIndicatorView.alpha = 0.0f;
    }
    return _selectedIndicatorView;
}

- (AWEScrollStringLabel *)propNameLabel
{
    if (!_propNameLabel) {
        _propNameLabel = [[AWEScrollStringLabel alloc] initWithHeight:14.0f];
    }
    return _propNameLabel;
}

- (CAGradientLayer *)propNameGradientLayer
{
    if (!_propNameGradientLayer) {
        UIColor *fromColor = UIColor.whiteColor;
        UIColor *toColor = UIColor.clearColor;
        _propNameGradientLayer = [CAGradientLayer layer];
        _propNameGradientLayer.startPoint = CGPointMake(0.75, 0.5);
        _propNameGradientLayer.endPoint = CGPointMake(1, 0.5);
        _propNameGradientLayer.backgroundColor = UIColor.clearColor.CGColor;
        _propNameGradientLayer.colors = @[(__bridge id)fromColor.CGColor, (__bridge id)toColor.CGColor];
    }
    return _propNameGradientLayer;
}

- (UIImageView *)downloadImgView
{
    if (!_downloadImgView) {
        _downloadImgView = [[UIImageView alloc] init];
        _downloadImgView.hidden = YES;
        _downloadImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _downloadImgView;
}

- (UIImageView *)loadingImgView
{
    if (!_loadingImgView) {
        _loadingImgView = [[UIImageView alloc] init];
        _loadingImgView.image = ACCResourceImage(@"icon60LoadingMiddle");
        _loadingImgView.hidden = YES;
    }
    return _loadingImgView;
}

- (AWECircularProgressView *)progressView
{
    if (!_progressView) {
        _progressView.hidden = YES;
        _progressView = [[AWECircularProgressView alloc] init];
        _progressView.lineWidth = 2.0;
        _progressView.progressRadius = 4.f;
        _progressView.backgroundWidth = 8.f;
        _progressView.progressTintColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _progressView.progressBackgroundColor = [ACCResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5];
    }
    return _progressView;
}

- (void)configWithEffectModel:(IESEffectModel *)model childEffectModel:(IESEffectModel *)childEffectModel
{
    self.effectModel = model;
    self.childEffect = childEffectModel;
    IESEffectModel *downloadModel = childEffectModel ?: model;
    
    self.loadingImgView.hidden = YES;
    
   if (model.acc_iconImage) {// 无论是effect还是childEffect都是用model的iconURL
       [ACCWebImage() cancelImageViewRequest:self.iconImageView];
        self.iconImageView.image = model.acc_iconImage;
    } else {
        [self updateStickerIconImage];
    }

    [self configPropNameLabelWithModel:model];
    if (model.downloaded) {
        // 关联特效子项特效下载之后，在面板上相同id的道具需要强制刷新
        downloadModel.downloadStatus = AWEEffectDownloadStatusDownloaded;
    }
    else if (downloadModel.downloadStatus == 0) {
        downloadModel.downloadStatus =
                downloadModel.downloaded ? AWEEffectDownloadStatusDownloaded : AWEEffectDownloadStatusUndownloaded;
    }
    
    switch (downloadModel.downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded: {
            self.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
            break;
        }
        case AWEEffectDownloadStatusDownloading: {
            self.downloadStatus = AWEModernStickerDownloadStatusDownloading;
            break;
        }
        case AWEEffectDownloadStatusDownloaded: {
            // 音乐强绑定逻辑，如果是强绑定道具则判断音乐缓存是否存在 1.不是强绑定音乐道具 2.强绑定道具音乐是否已经下载到本地
            BOOL needToDownloadMusic = [AWEStickerMusicManager needToDownloadMusicWithEffectModel:downloadModel];
            // 道具已缓存，音乐强绑定道具并且音乐缓存不存在
            if (needToDownloadMusic) {
                self.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
            } else {
                self.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
            }
            break;
        }
    }

    [self forceHideDownloadIconWithModel:model];
}

- (void)configPropNameLabelWithModel:(IESEffectModel *)model
{
    if (self.isInPropPanel) {
        self.propNameLabel.hidden = NO;
        [self.propNameLabel configWithTitleWithTextAlignCenter:model.effectName titleColor:ACCResourceColor(ACCUIColorConstTextInverse) fontSize:10 isBold:YES contentSize:CGSizeMake(self.contentView.acc_width * 50/71.5, 14.0)];
        if (self.propNameLabel.shouldScroll) {
            self.propNameLabel.layer.mask = self.propNameGradientLayer;
        } else {
            self.propNameLabel.layer.mask = nil;
        }
    } else {
        self.propNameLabel.hidden = YES;
    }
}

- (void)updateStickerIconImage
{
    NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", self.effectModel.effectIdentifier];
    BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
    BOOL enableShowingDynamicIcon = ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon) && !ACC_isEmptyArray(self.effectModel.dynamicIconURLs) && !isDynamicIconEverClicked;
    if (enableShowingDynamicIcon) {
        // use dynamic icon
        [ACCWebImage() imageView:self.iconImageView
            setImageWithURLArray:self.effectModel.dynamicIconURLs
                     placeholder:ACCResourceImage(@"imgLoadingStickers")
                      completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (error) {
                ACC_LogError(@"bd_setImageWithURLs failed and retry with staticIconURLS, dynamicIconURLs=%@|error: %@", self.effectModel.dynamicIconURLs, error);
                return;
            }
            self.effectModel.acc_iconImage = image;
        }];
    } else {
        // use static icon
        [ACCWebImage() imageView:self.iconImageView
            setImageWithURLArray:self.effectModel.iconDownloadURLs
                     placeholder:ACCResourceImage(@"imgLoadingStickers")
                      completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (error) {
                ACC_LogError(@"bd_setImageWithURLs failed, staticIconURL=%@|error: %@", self.effectModel.iconDownloadURLs, error);
                return;
            }
            self.effectModel.acc_iconImage = image;
        }];
    }
}

- (IESEffectModel *)effect
{
    return self.effectModel;
}

#pragma mark -

- (void)forceHideDownloadIconWithModel:(IESEffectModel *)effectModel
{
    if (effectModel.effectType == IESEffectModelEffectTypeSchema) {
        self.downloadImgView.image = nil;
        self.downloadImgView.hidden = YES;
        self.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
    }
}

#pragma mark - download Animations

- (void)setDownloadStatus:(AWEModernStickerDownloadStatus)downloadStatus
{
    self.downloadImgView.transform = CGAffineTransformIdentity;
    self.progressView.transform = CGAffineTransformIdentity;
    _downloadStatus = downloadStatus;
    switch (downloadStatus) {
        case AWEModernStickerDownloadStatusUndownloaded: {
            self.downloadImgView.hidden = NO;
            self.progressView.hidden = YES;
            [self.downloadImgView.layer removeAllAnimations];
            self.downloadImgView.image = ACCResourceImage(@"icStickersEffectsDownload");
            self.iconImageView.alpha = 1;
            break;
        }
        case AWEModernStickerDownloadStatusDownloading: {
            self.downloadImgView.hidden = YES;
            self.progressView.hidden = NO;
            self.iconImageView.alpha = 1;
            break;
        }
        case AWEModernStickerDownloadStatusDownloaded: {
            void (^completionBlock)(void)  = ^ {
                self.downloadImgView.transform = CGAffineTransformIdentity;
                self.progressView.transform = CGAffineTransformIdentity;

                self.iconImageView.alpha = 1;
                self.downloadImgView.image = nil;
                self.downloadImgView.hidden = YES;
                self.progressView.hidden = YES;
            };
            if (!self.downloadImgView.hidden) {
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     self.progressView.transform = CGAffineTransformMakeScale(0.001, 0.001);
                                 }
                                 completion:^(BOOL finish) {
                                     ACCBLOCK_INVOKE(completionBlock);
                                 }];
            } else {
                ACCBLOCK_INVOKE(completionBlock);
            }
            break;
        }
    }
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

- (void)updateDownloadProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
}

- (void)startDownloadAnimation {
    [self.downloadImgView.layer removeAllAnimations];
    [self.downloadImgView.layer addAnimation:[self createRotationAnimation] forKey:@"transform.rotation.z"];
}

- (void)stopDownloadAnimation {
    [self.downloadImgView.layer removeAllAnimations];
}

- (void)makeSelectedWithDelay
{
    [self indicatorAppearWithDelay:YES];
    [self startPropNameScrollingAnimation];
}

- (void)makeSelected
{
    [self indicatorAppearWithDelay:NO];
    [self startPropNameScrollingAnimation];
}

- (void)makeUnselected
{
    [self indicatorDisappear];
    [self stopPropNameScrollingAnimation];
}

- (void)startPropNameScrollingAnimation
{
    if (self.isInPropPanel) {
        [self.propNameLabel startAnimation];
    }
}

- (void)stopPropNameScrollingAnimation
{
    if (self.isInPropPanel) {
        [self.propNameLabel stopAnimation];
    }
}

- (void)indicatorAppearWithDelay:(BOOL)shouldDelay
{
    self.isStickerSelected = YES;
    [self stopLoadingAnimation];
    [UIView animateWithDuration:0.15
                          delay:shouldDelay ? 0.15 : 0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.selectedIndicatorView.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void)indicatorDisappear
{
    self.isStickerSelected = NO;
    [self stopLoadingAnimation];
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.selectedIndicatorView.alpha = 0.0f;
                     }
                     completion:nil];
}

- (void)p_startLoadingAnimation {
    self.loadingImgView.hidden = NO;
    self.iconImageView.alpha = 0.5;
    [self loadingImgStartRotate];
}

- (void)startLoadingAnimation {
    [self performSelector:@selector(p_startLoadingAnimation) withObject:nil afterDelay:0.3];
}

- (void)stopLoadingAnimation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(p_startLoadingAnimation) object:nil];

    [self loadingImgStopRotate];
    self.loadingImgView.hidden = YES;
    self.iconImageView.alpha = 1;
}

- (void)loadingImgStartRotate {

    [self.loadingImgView.layer removeAllAnimations];
    [self.loadingImgView.layer addAnimation:[self createRotationAnimation] forKey:@"transform.rotation.z"];
}

- (void)loadingImgStopRotate {

    [self.loadingImgView.layer removeAllAnimations];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectedIndicatorView.alpha = 0.0f;
    [self.propNameLabel.layer removeAllAnimations];
    self.downloadImgView.hidden = YES;
}

- (void)didMoveToWindow
{
    self.downloadStatus = self.downloadStatus;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel {
    BOOL selected = self.isStickerSelected;
    NSString *effectName = self.effect.effectName ?: @"";
    if (selected && self.selectedIndicatorView.alpha > 0) {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_selected_8i1pf2"), effectName];
    } else {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_unselected"), effectName];
    }
}

- (NSString *)accessibilityHint {
    return self.effect.hintLabel ?: @"";
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (void)accessibilityElementDidBecomeFocused
{
    if ([self.superview isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.superview;
        [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally|UICollectionViewScrollPositionCenteredVertically animated:NO];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self);
    }
}

@end
