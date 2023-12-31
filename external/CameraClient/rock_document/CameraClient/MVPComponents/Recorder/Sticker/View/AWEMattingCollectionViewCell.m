//
//  AWEMattingCollectionViewCell.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "AWEAlbumImageModel.h"
#import "AWEMattingCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLogProtocol.h>

static const CGFloat kACCSuperScriptContainerViewEdgeLength = 16.0;

@interface AWEMattingCollectionViewCell ()

@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, strong) UIImageView *loadingView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *superscriptContainerView;
@property (nonatomic, strong) UILabel *superscriptNumberLabel;

@property (nonatomic, assign) int32_t requestImageId;

@end

@implementation AWEMattingCollectionViewCell

#pragma mark - Cell Lift Cycle Methods
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubviews];
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)addSubviews
{
    [self.contentView addSubview:self.faceImageView];
    ACCMasMaker(self.faceImageView, {
        make.edges.equalTo(self.contentView);
    });

    [self.contentView addSubview:self.selectedIndicatorView];
    ACCMasMaker(self.selectedIndicatorView, {
        make.edges.equalTo(self.contentView);
    });
    
    [self.contentView addSubview:self.timeLabel];
    ACCMasMaker(self.timeLabel, {
         make.center.equalTo(self);
    });
  //  [self.timeLabel setHidden:YES];
     
    [self.contentView addSubview:self.loadingView];
    ACCMasMaker(self.loadingView, {
        make.center.equalTo(self.contentView);
    });

    [self.contentView addSubview:self.superscriptContainerView];
    ACCMasMaker(self.superscriptContainerView, {
        make.width.height.equalTo(@(kACCSuperScriptContainerViewEdgeLength));
        make.top.equalTo(self.contentView).offset(4);
        make.right.equalTo(self.contentView.mas_right).offset(-4);
    });
    self.superscriptContainerView.hidden = YES;

    [self.superscriptContainerView addSubview:self.superscriptNumberLabel];
    ACCMasMaker(self.superscriptNumberLabel, {
        make.center.equalTo(self.superscriptContainerView);
    });
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.customSelected = NO;
    self.selectedIndicatorView.hidden = YES;
    self.faceImageView.image = nil;
    self.loadingView.hidden = YES;
    self.enableMultiAssetsSelection = NO;
    self.superscriptContainerView.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Public Methods

- (void)configWithAlbumFaceModel:(AWEAlbumImageModel *)faceModel
{
    if (faceModel.image) {
        [self updateFaceImage:faceModel.image];
    } else if (faceModel.asset) {
        [self updateFaceImage:nil];
        [self configCellWithAsset:faceModel.asset needIcloudeContext:faceModel.networkAccessAllowed];
    } else {
        [self updateFaceImage:nil];
    }
    
    if (faceModel.asset.asset.duration > 0) {
        self.timeLabel.text = [NSString stringWithFormat:@"%.1fs", faceModel.asset.asset.duration];
        [self.timeLabel setHidden:NO];
    } else {
        [self.timeLabel setHidden:YES];
    }
    self.faceModel = faceModel;
    if (self.enableMultiAssetsSelection) {
        [self doMultiAssetsSelection];
    }
}

- (void)configCellWithAsset:(AWEAssetModel *)asset needIcloudeContext:(BOOL)needIcloudeContext {
    /// Cancel Pre-Request
    if (self.requestImageId > 0) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestImageId];
    }
    [self updateAccessibilityLabelWithAsset:asset];
    
    /// ImageSize
    CGSize size = self.faceImageView.bounds.size;
    CGFloat imageSizeWidth = size.width * [UIScreen mainScreen].scale;
    CGFloat imageSizeHeight = size.height * [UIScreen mainScreen].scale;
    CGSize imageSize = CGSizeMake(imageSizeWidth, imageSizeHeight);
    
    /// Get Image
    self.requestImageId = [CAKPhotoManager getUIImageWithPHAsset:asset.asset imageSize:imageSize networkAccessAllowed:needIcloudeContext progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        AWELogToolError(AWELogToolTagImport, @"error: %@",error);
    } completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
        acc_dispatch_main_async_safe(^{
            [self updateFaceImage:photo];
        });
    }];
}

- (void)updateAccessibilityLabelWithAsset:(AWEAssetModel *)assetModel
{
    BOOL isTypeImage = assetModel.asset.mediaType == PHAssetMediaTypeImage;
    NSMutableString *mediaInfo = [NSMutableString stringWithString:@""];
    if (isTypeImage) {
        [mediaInfo appendString:@"照片"];
    } else {
        [mediaInfo appendString:[NSString stringWithFormat:@"视频，时长%@",[self durationSpeakString:assetModel.asset.duration]]];
    }
    [mediaInfo appendString:[NSString stringWithFormat:@",拍摄时间%@",[self dateSpeakStringForAssetModel:assetModel]]];
    self.accessibilityLabel = mediaInfo;
    self.isAccessibilityElement = YES;
}


- (NSString *)durationSpeakString:(NSTimeInterval)duration
{
    NSInteger seconds = (NSInteger)round(duration);
    NSInteger second = seconds % 60;
    NSInteger minute = seconds / 60;
    if (minute > 0) {
        return [NSString stringWithFormat:@"%02ld分%02ld秒", (long)minute, (long)second];
    } else {
        return [NSString stringWithFormat:@"%02ld秒",(long)second];
    }
    
}

- (NSString *)dateSpeakStringForAssetModel:(AWEAssetModel *)assetModel
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH点mm分ss秒 zzzz"];
    NSString *currentDateString = [dateFormatter stringFromDate:assetModel.asset.creationDate];
    return currentDateString;
}


#pragma mark - Setter & Getter Methods

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        _timeLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _timeLabel.layer.shadowColor = ACCResourceColor(ACCUIColorSDSecondary).CGColor;
        _timeLabel.layer.shadowOffset = CGSizeMake(0, 2);
        _timeLabel.layer.shadowOpacity = 1.0;
        _timeLabel.layer.shadowRadius = 1.5f;
    }
    return _timeLabel;
}

- (UIImageView *)faceImageView {
    if (!_faceImageView) {
        _faceImageView = [[UIImageView alloc] init];
        _faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _faceImageView;
}

- (UIView *)selectedIndicatorView {
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] init];
        _selectedIndicatorView.backgroundColor = [UIColor clearColor];
        _selectedIndicatorView.layer.cornerRadius = 4;
        _selectedIndicatorView.layer.borderWidth = 2;
        _selectedIndicatorView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        _selectedIndicatorView.hidden = YES;
    }
    return _selectedIndicatorView;
}

- (UIImageView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIImageView alloc] init];
        _loadingView.image = ACCResourceImage(@"iconAlbumFaceLoadingView");
        _loadingView.hidden = YES;
        [_loadingView acc_addRotateAnimationWithDuration:0.8];
    }
    return _loadingView;
}

- (UIView *)superscriptContainerView
{
    if (!_superscriptContainerView) {
        _superscriptContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _superscriptContainerView.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _superscriptContainerView.layer.cornerRadius = kACCSuperScriptContainerViewEdgeLength / 2;
    }
    return _superscriptContainerView;
}
- (UILabel *)superscriptNumberLabel
{
    if (!_superscriptNumberLabel) {
        _superscriptNumberLabel = [[UILabel alloc] init];
        _superscriptNumberLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightRegular];
        _superscriptNumberLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    }
    return _superscriptNumberLabel;
}

- (void)setCustomSelected:(BOOL)customSelected
{
    self.selectedIndicatorView.hidden = customSelected ? NO : YES;
}


#pragma mark - UI Tools

- (void)doMultiAssetsSelection
{
    BOOL selected = self.faceModel.asset.selectedNum != nil;
    self.selectedIndicatorView.hidden = YES; // show `selectedIndicatorView` only for single-asset selection
    self.superscriptContainerView.hidden = !selected;
    if (selected) {
        self.superscriptNumberLabel.text = [NSString stringWithFormat:@"%@", @([self.faceModel.asset.selectedNum integerValue])];
    }
}

- (void)updateFaceImage:(UIImage *)faceImage {
    if (faceImage) {
        self.loadingView.hidden = YES;
        self.faceImageView.image = faceImage;
    } else {
        self.loadingView.hidden = NO;
        self.backgroundColor = ACCResourceColor(ACCUIColorBGContainer7);
    }
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self mediaInfo];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
}

- (NSString *)mediaInfo
{
    BOOL isTypeImage = self.faceModel.asset.asset.mediaType == AWEAssetModelMediaTypePhoto;
    NSMutableString *mediaInfo = [NSMutableString stringWithString:@""];
    if (isTypeImage) {
        [mediaInfo appendString:@"照片"];
    } else {
        [mediaInfo appendString:[NSString stringWithFormat:@"视频，时长%1.f秒",self.faceModel.asset.asset.duration]];
    }
    [mediaInfo appendString:[NSString stringWithFormat:@",拍摄时间%@",[self dateSpeakString]]];
    return mediaInfo;
}

- (NSString *)dateSpeakString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH点mm分ss秒 zzzz"];
    NSString *currentDateString = [dateFormatter stringFromDate:self.faceModel.asset.asset.creationDate];
    return currentDateString;
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
