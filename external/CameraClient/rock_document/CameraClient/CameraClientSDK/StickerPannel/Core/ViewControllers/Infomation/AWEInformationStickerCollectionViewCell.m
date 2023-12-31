//
//  AWEInformationStickerCollectionViewCell.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/21.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEInformationStickerCollectionViewCell.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitInfra/AWECircularProgressView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCStickerPannelUIConfig.h"

@implementation AWEBaseStickerCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)setUiConfig:(ACCStickerPannelUIConfig *)uiConfig {
    if (_uiConfig != nil) {
        return;
    }
    _uiConfig = uiConfig;
    [self setupUI];
}

- (void)setupUI {
    NSAssert(NO, @"should implementation in subclass");
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (UIImageView *)downloadImgView
{
    if (!_downloadImgView) {
        _downloadImgView = [[UIImageView alloc] init];
        _downloadImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _downloadImgView;
}

- (AWECircularProgressView *)downloadProgressView
{
    if (!_downloadProgressView) {
        _downloadProgressView = [[AWECircularProgressView alloc] init];
        _downloadProgressView.lineWidth = 2.0;
        _downloadProgressView.backgroundWidth = 3.0;
        _downloadProgressView.progressTintColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _downloadProgressView.progressBackgroundColor =
                [ACCResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.3];
    }
    return _downloadProgressView;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted) {
        [UIView animateWithDuration:0.1 animations:^{
            self.imageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            self.imageView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

#pragma mark - public

- (void)configCellWithImage:(NSArray<NSString *> *)image
{
    [ACCWebImage() imageView:self.imageView setImageWithURLArray:image placeholder:ACCResourceImage(@"imgLoadingStickers")];
}

- (void)updateDownloadProgress:(CGFloat)progress
{
    if (self.downloadProgressView.hidden) {
        self.downloadProgressView.hidden = NO;
    }
    self.downloadProgressView.progress = progress;
}

#pragma mark - download Animations

- (void)setDownloadStatus:(AWEInfoStickerDownloadStatus)downloadStatus
{
    _downloadStatus = downloadStatus;
    switch (downloadStatus) {
        case AWEInfoStickerDownloadStatusUndownloaded: {
            self.downloadProgressView.hidden = YES;
            break;
        }
        case AWEInfoStickerDownloadStatusDownloading: {
            self.downloadProgressView.hidden = NO;
            break;
        }
        case AWEInfoStickerDownloadStatusDownloaded: {
            if (!self.downloadProgressView.hidden) {
                [self downloadProgressViewScaleDisappear];
            }
            break;
        }
    }
}

- (void)downloadProgressViewScaleDisappear
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.downloadProgressView.transform = CGAffineTransformMakeScale(0.001, 0.001);
                     }
                     completion:^(BOOL finish) {
                         self.downloadProgressView.transform = CGAffineTransformIdentity;
                         self.downloadProgressView.hidden = YES;
                     }];
}

- (void)didMoveToWindow
{
    self.downloadStatus = self.downloadStatus;
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.stickerName?:@"贴纸";
}

@end


@implementation AWEInformationStickerCollectionViewCell

- (void)setupUI
{
    [self addSubview:self.imageView];
    self.imageView.contentMode = self.uiConfig.stickerCollectionViewCellImageContentMode;
    UIEdgeInsets insets = self.uiConfig.stickerCollectionViewCellInsets;
    ACCMasMaker(self.imageView, {
        make.edges.mas_equalTo(insets);
    });
    
    [self addSubview:self.downloadProgressView];
    [self.downloadProgressView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.equalTo(@18);
        maker.height.equalTo(@18);
        maker.right.equalTo(self.imageView);
        maker.bottom.equalTo(self.imageView);
    }];
}

@end

@implementation AWEInformationStickerCollectionViewFooter

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat seperatorViewHeight = 0.5;
        if ([UIScreen mainScreen].scale > 0) {
            seperatorViewHeight = 1.0f/[UIScreen mainScreen].scale;
        }
        _seperatorView = [[UIView alloc] init];
        _seperatorView.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
        [self addSubview:_seperatorView];
        ACCMasMaker(_seperatorView, {
            make.leading.equalTo(@(16));
            make.trailing.equalTo(@(-16));
            make.centerY.equalTo(self.mas_centerY);
            make.height.equalTo(@(seperatorViewHeight));
        });
    }
    return self;
}

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

@end

@interface AWEVideoEditStickerCollectionViewHeaderView ()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation AWEVideoEditStickerCollectionViewHeaderView

- (void)setUiConfig:(ACCStickerPannelUIConfig *)uiConfig {
    if (_uiConfig != nil) {
        return;
    }
    _uiConfig = uiConfig;
    [self setupTitleLabel];
}

- (void)setupTitleLabel {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
    _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
    ACC_LANGUAGE_DISABLE_LOCALIZATION(_titleLabel);
    
    [self addSubview:_titleLabel];
    
    ACCMasMaker(_titleLabel, {
        make.left.equalTo(self).with.offset(16 - 1.5);
        make.top.equalTo(self).with.offset(18);
    });
}

- (void)updateWithTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

+ (NSString *)identifier
{
    return @"AWEVideoEditStickerCollectionViewHeaderView";
}

@end

@interface ACCSearchStickerCollectionViewHeader()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation ACCSearchStickerCollectionViewHeader

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.userInteractionEnabled = YES;
        _titleLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        [self addSubview:_titleLabel];
        ACCMasMaker(_titleLabel, {
            make.top.left.right.equalTo(self);
            make.bottom.equalTo(@-15.f);
        });
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnTitle)];
        [_titleLabel addGestureRecognizer:tapGesture];
    }
    return _titleLabel;
}

- (void)updateWithTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)clickOnTitle
{
    ACCBLOCK_INVOKE(self.didClickBlock);
}

+ (NSString *)identifier
{
    return @"ACCSearchStickerCollectionViewHeader";
}
@end

@implementation ACCSearchStickerCollectionViewCell

- (void)setupUI
{
    if (!self.didSetupUI) {
        self.imageView = [ACCWebImage() animatedImageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
        ACCMasMaker(self.imageView, {
            make.edges.mas_equalTo(self);
        });
        
        [self addSubview:self.downloadProgressView];
        ACCMasMaker(self.downloadProgressView,{
            make.width.equalTo(@18);
            make.height.equalTo(@18);
            make.right.equalTo(self.imageView);
            make.bottom.equalTo(self.imageView);
        });
        self.didSetupUI = YES;
    }
}

@end
