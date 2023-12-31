//
//  AWEPhotoPickerCollectionViewCell.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEPhotoPickerCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <Masonry/View+MASAdditions.h>
#import <CameraClient/AWEAssetModel.h>

@interface AWEPhotoPickerCollectionViewCell ()

@property (nonatomic, strong) UIView *selectedIndicatorView;

@property (nonatomic, strong) UIImageView *loadingView;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, assign) int32_t imageRequestId;

@end

@implementation AWEPhotoPickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        
        [self.contentView addSubview:self.imageView];
        ACCMasMaker(self.imageView, {
            make.edges.equalTo(self.contentView);
        });

        [self.contentView addSubview:self.selectedIndicatorView];
        ACCMasMaker(self.selectedIndicatorView, {
            make.edges.equalTo(self.contentView);
        });
        
        [self.contentView addSubview:self.timeLabel];
        ACCMasMaker(self.timeLabel, {
            make.center.equalTo(self.contentView);
        });
         
        [self.contentView addSubview:self.loadingView];
        ACCMasMaker(self.loadingView, {
            make.center.equalTo(self.contentView);
        });
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.selectedIndicatorView.hidden = YES;
    _assetSelected = NO;
    self.loadingView.hidden = YES;
    self.assetModel = nil;
}

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (void)setAssetModel:(AWEAssetModel *)assetModel {
    if (_assetModel != assetModel) {
        _assetModel = assetModel;
        if (assetModel) {
            if (assetModel.coverImage) {
                self.imageView.image = _assetModel.coverImage;
            } else {
                CGSize imageSize = self.imageView.frame.size;
                CGFloat scale = [UIScreen mainScreen].scale;
                CGSize imagePixelSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
                [CAKPhotoManager getUIImageWithPHAsset:assetModel.asset
                                         imageSize:imagePixelSize
                              networkAccessAllowed:YES
                                   progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
                    if (error) {
                        AWELogToolError(AWELogToolTagRecord, @"getUIImageWithPHAsset error: %@", error);
                    }
                }
                                        completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        assetModel.coverImage = photo;
                        if (assetModel == self.assetModel) {
                            self.imageView.image = photo;
                        }
                    });
                }];
            }
        } else {
            self.imageView.image = nil;
        }
        
        if (assetModel.asset.duration > 0) {
            self.timeLabel.text = [NSString stringWithFormat:@"%.1fs", assetModel.asset.duration];
            [self.timeLabel setHidden:NO];
        } else {
            [self.timeLabel setHidden:YES];
        }
    }
}

- (void)setAssetSelected:(BOOL)assetSelected
{
    if (_assetSelected != assetSelected) {
        _assetSelected = assetSelected;
        _selectedIndicatorView.hidden = !_assetSelected;
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

- (UILabel *)timeLabel {
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

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self mediaInfo];
}

- (NSString *)mediaInfo
{
    BOOL isTypeImage = self.assetModel.mediaType == AWEAssetModelMediaTypePhoto;
    NSMutableString *mediaInfo = [NSMutableString stringWithString:@""];
    if (isTypeImage) {
        [mediaInfo appendString:@"照片"];
    } else {
        [mediaInfo appendString:[NSString stringWithFormat:@"视频，时长%1.f秒",self.assetModel.asset.duration]];
    }
    [mediaInfo appendString:[NSString stringWithFormat:@",拍摄时间%@",[self dateSpeakString]]];
    return mediaInfo;
}

- (NSString *)dateSpeakString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH点mm分ss秒 zzzz"];
    NSString *currentDateString = [dateFormatter stringFromDate:self.assetModel.asset.creationDate];
    return currentDateString;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
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

@interface AWEPhotoPickerCollectionViewMultiAssetsCell ()

@property (nonatomic, strong) UILabel *selectedNumberLabel;

@end

@implementation AWEPhotoPickerCollectionViewMultiAssetsCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.selectedIndicatorView removeFromSuperview];
        _selectedNumberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _selectedNumberLabel.layer.cornerRadius = 8;
        _selectedNumberLabel.layer.masksToBounds = YES;
        _selectedNumberLabel.textAlignment = NSTextAlignmentCenter;
        _selectedNumberLabel.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _selectedNumberLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightRegular];
        _selectedNumberLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _selectedNumberLabel.hidden = YES;
        [self.contentView addSubview:self.selectedNumberLabel];
        ACCMasMaker(self.selectedNumberLabel, {
            make.width.height.equalTo(@(16));
            make.top.equalTo(self.contentView).offset(4);
            make.right.equalTo(self.contentView.mas_right).offset(-4);
        });
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectedNumberLabel.hidden = YES;
}

- (void)setAssetSelected:(BOOL)assetSelected
{
    [super setAssetSelected:assetSelected];
    self.selectedNumberLabel.hidden = !assetSelected;
    self.selectedNumberLabel.text = [NSString stringWithFormat:@"%@", self.assetModel.selectedNum];
}

@end
