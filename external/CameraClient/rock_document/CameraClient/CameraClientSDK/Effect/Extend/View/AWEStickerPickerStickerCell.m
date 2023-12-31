//
//  AWEStickerPickerStickerCell.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import "AWEStickerPickerStickerCell.h"
#import <CameraClient/AWEStickerDownloadManager.h>
#import <CreationKitInfra/AWECircularProgressView.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/AWEStickerPickerLogMarcos.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <Masonry/View+MASAdditions.h>
#import <BDWebImage/BDWebImage.h>

#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"

typedef NS_ENUM(NSUInteger, AWEStickerDownloadStatus) {
    AWEStickerDownloadStatusNotDownloaded,
    AWEStickerDownloadStatusDownloading,
    AWEStickerDownloadStatusDownloaded,
};

@interface AWEStickerPickerStickerCell () <AWEStickerDownloadObserverProtocol>

@property (nonatomic, strong) BDImageView *iconImageView;
@property (nonatomic, strong) UIImageView *downloadImgView;
@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, strong) AWECircularProgressView *progressView;

@property (nonatomic, assign) AWEStickerDownloadStatus downloadStatus;
@property (nonatomic, strong) UITapGestureRecognizer *tapGes;

@end

@implementation AWEStickerPickerStickerCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self setupSubviews];
        [self setupConstraints];
        self.selectedBorderColor = ACCResourceColor(ACCColorPrimary);
        [self addGestureRecognizer:self.tapGes];

        [[AWEStickerDownloadManager manager] addObserver:self];
    }
    return self;
}

- (void)setSelectedBorderColor:(UIColor *)selectedBorderColor {
    self.selectedIndicatorView.layer.borderColor = selectedBorderColor.CGColor;
}

- (void)dealloc {
    [[AWEStickerDownloadManager manager] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.sticker = nil;
    [self setStickerSelected:NO animated:NO];
}

- (void)setupSubviews {
    _iconImageView = [[BDImageView alloc] init];
    _iconImageView.autoPlayAnimatedImage = YES;
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.iconImageView];
    
    _selectedIndicatorView = [[UIView alloc] init];
    _selectedIndicatorView.backgroundColor = [UIColor clearColor];
    _selectedIndicatorView.layer.cornerRadius = 9;
    _selectedIndicatorView.layer.borderWidth = 2;
    _selectedIndicatorView.alpha = 0.0f;
    [self.contentView addSubview:self.selectedIndicatorView];
    
    _downloadImgView = [[UIImageView alloc] init];
    _downloadImgView.hidden = YES;
    _downloadImgView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.downloadImgView];
    
    _progressView.hidden = YES;
    _progressView = [[AWECircularProgressView alloc] init];
    _progressView.lineWidth = 2.0;
    _progressView.backgroundWidth = 3.0;
    _progressView.progressTintColor = ACCResourceColor(ACCUIColorConstBGContainer);
    _progressView.progressBackgroundColor = [ACCResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5];
    [self.contentView addSubview:self.progressView];
}

- (void)setupConstraints
{
    CGFloat ratio = 60 / 71.5;
    CGFloat yOffset = (self.contentView.acc_width * (1 - ratio)) / 2; // Make sure the left edge inset and top edge inset are equal.
    [self.selectedIndicatorView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.height.equalTo(self.contentView.mas_width).multipliedBy(60 / 71.5);
        maker.centerX.equalTo(self);
        maker.top.equalTo(self).mas_offset(yOffset);
    }];

    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.height.equalTo(self.contentView.mas_width).multipliedBy(54 / 71.5);
        maker.center.equalTo(self.selectedIndicatorView);
    }];


    [self.downloadImgView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.height.equalTo(self.contentView.mas_width).multipliedBy(16 / 71.5);
        maker.right.equalTo(self.iconImageView).offset(-1.f);
        maker.bottom.equalTo(self.iconImageView).offset(-1.f);
    }];

    [self.progressView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.edges.equalTo(self.downloadImgView);
    }];
}

- (void)updateStickerIconImage
{
    NSArray *iconURLArray = self.sticker.iconDownloadURLs;
    NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", self.sticker.effectIdentifier];
    BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
    BOOL enableShowingDynamicIcon = ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon) && !ACC_isEmptyArray(self.sticker.dynamicIconURLs) && !isDynamicIconEverClicked;
    if (enableShowingDynamicIcon) {
        iconURLArray = [self.sticker.dynamicIconURLs arrayByAddingObjectsFromArray:self.sticker.iconDownloadURLs];
    }

    [self.iconImageView bd_setImageWithURLs:iconURLArray
                                placeholder:ACCResourceImage(@"imgLoadingStickers")
                                    options:BDImageRequestDefaultPriority
                                transformer:nil
                                   progress:nil
                                 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (error) {
            AWEStickerPickerLogError(@"bd_setImageWithURLs failed, iconDownloadURLs=%@|error", self.sticker.iconDownloadURLs, error);
        }
    }];
}

#pragma mark - Public

- (void)setSticker:(IESEffectModel *)sticker {
    [super setSticker:sticker];

    [self updateStickerIconImage];

    // 更新下载状态，可下载道具根据下载状态设置状态视图。
    // 不可下载道具（集合道具，商业化scheme道具）设置为已下载状态。
    if (self.sticker.fileDownloadURLs.count > 0 && self.sticker.fileDownloadURI.length > 0) {
        if (self.sticker.downloaded) {
            self.downloadStatus = AWEStickerDownloadStatusDownloaded;
        } else {
            NSNumber *progress = [[AWEStickerDownloadManager manager] stickerDownloadProgress:self.sticker];
            if (progress != nil) {
                self.downloadStatus = AWEStickerDownloadStatusDownloading;
            } else {
                self.downloadStatus = AWEStickerDownloadStatusNotDownloaded;
            }
        }
    } else {
        self.downloadStatus = AWEStickerDownloadStatusDownloaded;
    }
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

- (UITapGestureRecognizer *)tapGes {
    if (!_tapGes) {
        _tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnimation)];
        _tapGes.cancelsTouchesInView = NO;
    }
    return _tapGes;
}

- (void)setStickerSelected:(BOOL)stickerSelected animated:(BOOL)animated
{
    [super setStickerSelected:stickerSelected animated:animated];
    if (self.stickerSelected) {
        if (animated) {
            [UIView animateWithDuration:0.15
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                self.selectedIndicatorView.alpha = 1.0f;
            }
                             completion:nil];
        } else {
            self.selectedIndicatorView.alpha = 1.0f;
        }
    } else {
        if (animated) {
            [UIView animateWithDuration:0.15
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                self.selectedIndicatorView.alpha = 0.0f;
            }
                             completion:nil];
            
        } else {
            self.selectedIndicatorView.alpha = 0.0f;
        }
    }
}

- (void)setDownloadStatus:(AWEStickerDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    switch (downloadStatus) {
        case AWEStickerDownloadStatusNotDownloaded: {
            self.downloadImgView.hidden = NO;
            self.downloadImgView.image = ACCResourceImage(@"iconStickerCellDownload");
            self.progressView.hidden = YES;
            break;
        }
        case AWEStickerDownloadStatusDownloading: {
            self.downloadImgView.image = nil;
            self.downloadImgView.hidden = YES;
            self.progressView.hidden = NO;
            break;
        }
        case AWEStickerDownloadStatusDownloaded: {
            self.downloadImgView.image = nil;
            self.downloadImgView.hidden = YES;
            self.progressView.hidden = YES;
            break;
        }
    }
}

#pragma mark - AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didBeginDownloadSticker:(IESEffectModel *)sticker {
    if ([self.sticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        self.downloadStatus = AWEStickerDownloadStatusDownloading;
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager sticker:(IESEffectModel *)sticker downloadProgressChange:(CGFloat)progress {
    if ([self.sticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        self.progressView.progress = progress;
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)sticker {
    if ([self.sticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        self.downloadStatus = AWEStickerDownloadStatusDownloaded;
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error {
    if ([self.sticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        AWEStickerPickerLogError(@"sticker downloader download failed, id=%@|error=%@", sticker.effectIdentifier, error);
        self.downloadStatus = AWEStickerDownloadStatusNotDownloaded;
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager needUpdateCellDownloadedSticker:(IESEffectModel *)sticker
{
    if ([self.sticker.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
        self.downloadStatus = AWEStickerDownloadStatusDownloaded;
    }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    BOOL selected = self.stickerSelected;
    NSString *effectName = self.sticker.effectName ?: @"";
    if (selected && self.selectedIndicatorView.alpha > 0) {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_selected_8i1pf2"), effectName];
    } else {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_unselected"), effectName];
    }
}

- (NSString *)accessibilityHint {
    return self.sticker.hintLabel ?: @"";
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (void)accessibilityElementDidBecomeFocused {
    if ([self.superview isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.superview;
        [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally|UICollectionViewScrollPositionCenteredVertically animated:NO];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self);
    }
}

@end

#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/AWEScrollStringLabel.h>

@interface AWEStickerPickerStickerPropNameCell ()

@property (nonatomic, strong) AWEScrollStringLabel *propNameLabel;
@property (nonatomic, strong) CAGradientLayer *propNameGradientLayer;

@end

@implementation AWEStickerPickerStickerPropNameCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.propNameLabel];
        ACCMasMaker(self.propNameLabel, {
            make.top.equalTo(self.selectedIndicatorView.mas_bottom);
            make.width.equalTo(self.contentView).multipliedBy(50 / 71.5);
            make.height.equalTo(@(14));
            make.centerX.equalTo(self.selectedIndicatorView);
        });
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.propNameLabel layoutIfNeeded];
    self.propNameGradientLayer.frame = self.propNameLabel.bounds;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.propNameLabel.layer removeAllAnimations];
}

#pragma mark - Override

- (void)setSticker:(IESEffectModel *)sticker
{
    [super setSticker:sticker];
    
    [self.propNameLabel configWithTitleWithTextAlignCenter:sticker.effectName
                                                titleColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                  fontSize:[ACCFont() getAdaptiveFontSize:10]
                                                    isBold:YES
                                               contentSize:CGSizeMake(self.contentView.acc_width * 50/71.5, 14.0)];
    
    if (self.propNameLabel.shouldScroll) {
        self.propNameLabel.layer.mask = self.propNameGradientLayer;
    } else {
        self.propNameLabel.layer.mask = nil;
    }
}

- (void)setStickerSelected:(BOOL)stickerSelected animated:(BOOL)animated
{
    [super setStickerSelected:stickerSelected animated:animated];
    if (stickerSelected) {
        [self.propNameLabel startAnimation];
    } else {
        [self.propNameLabel stopAnimation];
    }
}

#pragma mark - Getters

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

@end
