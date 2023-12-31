//
//  AWEVideoEffectSimplifiedPanelCollectionViewCell.m
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import "AWEVideoEffectSimplifiedPanelCollectionViewCell.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCResourceUnion.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <IESLiveResourcesButler/IESLiveResourceBundle+File.h>
#import <YYImage/YYImage.h>

static CGFloat const kImageWidthHeight = 52.f;
static CGFloat const kDownloadStatusWidthHeight = 16.f;
static CGFloat const kLoadingImageWidthHeight = 32.f;
static CGFloat const kImageLabelSpacing = 4.f;
static CGFloat const kLabelHeight = 22.f;
static CGFloat const kAWEVideoEffectViewCollectionCellFontSize = 12.f;
static NSString * const kIconUndownloaded = @"icStickersEffectsDownload";
static NSString * const kIconDownloading = @"icStickersEffectsLoading";

@interface AWEVideoEffectSimplifiedPanelCollectionViewCell ()

@property (nonatomic, strong, nullable) UIView *imageBackgroundView;
@property (nonatomic, strong, nullable) UIImageView *effectLoadingImageView;
@property (nonatomic, strong, nullable) YYAnimatedImageView *effectImageView;
@property (nonatomic, strong, nullable) UILabel *effectNameLabel;
@property (nonatomic, strong, nullable) UIImageView *downloadStatusImageView;
@property (nonatomic, strong, nullable) UITapGestureRecognizer *tapGesture;

@end

@implementation AWEVideoEffectSimplifiedPanelCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        [self p_setupGesture];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageBackgroundView.frame = CGRectMake(0,
                                                0,
                                                kImageWidthHeight,
                                                kImageWidthHeight);
    self.effectLoadingImageView.frame = CGRectMake(0,
                                                   0,
                                                   kLoadingImageWidthHeight,
                                                   kLoadingImageWidthHeight);
    self.effectLoadingImageView.center = CGPointMake(kImageWidthHeight / 2.f, kImageWidthHeight / 2.f);
    self.effectImageView.frame = CGRectMake(0,
                                            0,
                                            kImageWidthHeight * 1.15,
                                            kImageWidthHeight * 1.15);
    self.effectImageView.center = CGPointMake(kImageWidthHeight / 2.f, kImageWidthHeight / 2.f);
    self.imageBackgroundView.layer.cornerRadius = kImageWidthHeight / 2.f;
    self.effectNameLabel.frame = CGRectMake(0,
                                            kImageWidthHeight + kImageLabelSpacing,
                                            kImageWidthHeight,
                                            kLabelHeight);
    self.downloadStatusImageView.frame = CGRectMake(kImageWidthHeight - kDownloadStatusWidthHeight,
                                                    kImageWidthHeight - kDownloadStatusWidthHeight,
                                                    kDownloadStatusWidthHeight,
                                                    kDownloadStatusWidthHeight);
}

#pragma mark - Public Methods

+ (CGSize)calculateCellSize
{
    return CGSizeMake(kImageWidthHeight, kImageWidthHeight + kImageLabelSpacing + kLabelHeight);
}

- (void)updateWithEffectModel:(IESEffectModel *)effectModel
{
    /* Image */
    if (effectModel.builtinIcon) {
        NSMutableString *gifName = [NSMutableString stringWithString:effectModel.builtinIcon];
        if (![[gifName lowercaseString] containsString:@".gif"]) {
            [gifName appendString:@".gif"];
        }
        NSString *path = ACCResourceUnion.cameraResourceBundle.filePath(gifName);
        if (![path length]) {
            NSMutableString *webpName = [NSMutableString stringWithString:effectModel.builtinIcon];
            if (![[webpName lowercaseString] containsString:@".webp"]) {
                [webpName appendString:@".webp"];
            }
            path = ACCResourceFile(webpName);
        }
        @autoreleasepool {
            YYImage *image = [YYImage imageWithContentsOfFile:path];
            self.effectImageView.image = [self p_optimizeImageIfNeeded:image];;
        }
    } else {
        @weakify(self);
        [ACCWebImage() imageView:self.effectImageView
            setImageWithURLArray:effectModel.iconDownloadURLs
                     placeholder:nil
                      completion:^(UIImage *image, NSURL *url, NSError *error) {
            @strongify(self);
            if (error) {
                return;
            }
            if ([self p_shouldOptimizeImage:image]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.effectImageView.image = [self p_optimizeImageIfNeeded:image];
                });
            }
        }];
    }
    
    /* Text */
    self.effectNameLabel.text = effectModel.effectName;
}

/// 更新downloadStatus，并更新image view
/// @param downloadStatus AWEEffectDownloadStatus
- (void)updateDownloadStatus:(AWEEffectDownloadStatus)downloadStatus
{
    switch (downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded:
        {
            /* 显示待下载的icon，无animation */
            [self.downloadStatusImageView.layer removeAllAnimations];
            self.downloadStatusImageView.layer.transform = CATransform3DIdentity;
            self.downloadStatusImageView.hidden = NO;
            self.downloadStatusImageView.image = ACCResourceImage(kIconUndownloaded);
            break;
        }
        case AWEEffectDownloadStatusDownloading:
        {
            /* 显示下载中的icon，开始不断旋转的animation */
            [self.downloadStatusImageView.layer removeAllAnimations];
            self.downloadStatusImageView.layer.transform = CATransform3DIdentity;
            self.downloadStatusImageView.hidden = NO;
            self.downloadStatusImageView.image = ACCResourceImage(kIconDownloading);
            CABasicAnimation* rotationAnimation;
            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation * rotations * duration*/  ];
            rotationAnimation.duration = 0.8;
            rotationAnimation.cumulative = YES;
            rotationAnimation.repeatCount = HUGE_VAL;
            [self.downloadStatusImageView.layer addAnimation:rotationAnimation forKey:@"transform.rotation.z"];
            break;
        }
        case AWEEffectDownloadStatusDownloaded:
        {
            /* 停止animation，hide下载icon */
            if (!self.downloadStatusImageView.isHidden) {
                [self.downloadStatusImageView.layer removeAllAnimations];
                self.downloadStatusImageView.layer.transform = CATransform3DIdentity;
                [CATransaction begin];
                CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                scaleAnimation.duration = 0.2;
                scaleAnimation.fromValue = [NSNumber numberWithFloat:1.f];
                scaleAnimation.toValue = [NSNumber numberWithFloat:0.001f];
                scaleAnimation.fillMode = kCAFillModeForwards;
                scaleAnimation.removedOnCompletion = NO;
                [CATransaction setCompletionBlock:^{
                    self.downloadStatusImageView.hidden = YES;
                }];
                [self.downloadStatusImageView.layer addAnimation:scaleAnimation forKey:@"transform.scale"];
                [CATransaction commit];
            }
            break;
        }
        default:
            break;
    }
}

- (void)hideDownloadIndicator
{
    self.downloadStatusImageView.hidden = YES;
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    self.contentView.backgroundColor = UIColor.clearColor;
    self.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.imageBackgroundView];
    [self.imageBackgroundView addSubview:self.effectLoadingImageView];
    [self.imageBackgroundView addSubview:self.effectImageView];
    [self.contentView addSubview:self.effectNameLabel];
    [self.contentView addSubview:self.downloadStatusImageView];
}

- (void)p_setupGesture
{
    [self.contentView addGestureRecognizer:self.tapGesture];
}

- (BOOL)p_shouldOptimizeImage:(nullable UIImage *)image
{
    if (!image) {
        return NO;
    }
    if ([UIDevice acc_isPoorThanIPhone6S]) {
        return YES;
    }
    return NO;
}

- (nullable UIImage *)p_optimizeImageIfNeeded:(UIImage *)image
{
    if (![self p_shouldOptimizeImage:image]) {
        return image;
    }
    if ([image isMemberOfClass:[UIImage class]]) {
        return image;
    }
    return [UIImage imageWithCGImage:image.CGImage];
}

- (void)p_didTapCell:(id)sender
{
    [self.imageBackgroundView.layer removeAllAnimations];
    self.imageBackgroundView.layer.transform = CATransform3DIdentity;
    [CATransaction begin];
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.duration = 0.1;
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.f];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1.1f];
    scaleAnimation.autoreverses = YES;
    [self.imageBackgroundView.layer addAnimation:scaleAnimation forKey:@"transform.scale"];
    [CATransaction commit];
    
    [self.delegate didTapCell:self];
}

- (CAAnimation *)p_createRotationAnimation
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0]; // full rotation * rotations * duration
    rotationAnimation.duration = 0.8;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VAL;
    return rotationAnimation;
}

#pragma mark - Getters and Setters

- (UIImageView *)effectLoadingImageView
{
    if (!_effectLoadingImageView) {
        _effectLoadingImageView = [[UIImageView alloc] init];
        _effectLoadingImageView.image = ACCResourceImage(@"tool_EffectLoadingIcon");
    }
    return _effectLoadingImageView;
}

- (YYAnimatedImageView *)effectImageView
{
    if (!_effectImageView) {
        _effectImageView = [[YYAnimatedImageView alloc] init];
    }
    return _effectImageView;
}

- (UIView *)imageBackgroundView
{
    if (!_imageBackgroundView) {
        _imageBackgroundView = [[UIImageView alloc] init];
        _imageBackgroundView.backgroundColor = ACCUIColorFromRGBA(0xffffff, 0.15f);
        _imageBackgroundView.layer.masksToBounds = YES;
    }
    return _imageBackgroundView;
}

- (UILabel *)effectNameLabel
{
    if (!_effectNameLabel) {
        _effectNameLabel = [[UILabel alloc] init];
        _effectNameLabel.textAlignment = NSTextAlignmentCenter;
        _effectNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _effectNameLabel.font = [ACCFont() acc_systemFontOfSize:kAWEVideoEffectViewCollectionCellFontSize
                                                         weight:ACCFontWeightSemibold];
        _effectNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _effectNameLabel.textAlignment = NSTextAlignmentCenter;
        _effectNameLabel.numberOfLines = 2;
        _effectNameLabel.text = @"特效";
    }
    return _effectNameLabel;
}

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_didTapCell:)];
    }
    return _tapGesture;
}

- (UIImageView *)downloadStatusImageView
{
    if (!_downloadStatusImageView) {
        _downloadStatusImageView = [[UIImageView alloc] init];
        _downloadStatusImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _downloadStatusImageView;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.effectNameLabel.textColor = ACCResourceColor(ACCColorPrimary);
        self.imageBackgroundView.layer.borderWidth = 2.f;
        self.imageBackgroundView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
    } else {
        self.effectNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        self.imageBackgroundView.layer.borderWidth = 0;
        self.imageBackgroundView.layer.borderColor = UIColor.clearColor.CGColor;
    }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"%@, %@", self.effectNameLabel.text, self.isSelected ? @"已选中" : @"未选中"];
}

- (NSString *)accessibilityValue
{
    return nil;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
}

@end
