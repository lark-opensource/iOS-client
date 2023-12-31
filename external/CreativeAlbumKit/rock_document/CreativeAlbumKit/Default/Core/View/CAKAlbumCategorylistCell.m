//
//  CAKAlbumCategorylistCell.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2020/7/27.
//

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIFont+ACCAdditions.h>

#import "CAKAlbumCategorylistCell.h"
#import "UIColor+AlbumKit.h"
#import "CAKAlbumAssetModel.h"
#import "CAKPhotoManager.h"

@interface CAKAlbumCategorylistCell()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIImageView *iconView;

@end

@implementation CAKAlbumCategorylistCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (@available(iOS 14.0, *)) {
            self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
        
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.subTitleLabel];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.iconView.image = nil;
    self.titleLabel.text = nil;
    self.subTitleLabel.text = nil;
}

- (void)configCellWithAlbumModel:(CAKAlbumModel *)albumModel
{
    self.titleLabel.text = albumModel.name;
    // do alp_disableLocalizations
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSString *photoCount = [numberFormatter stringFromNumber:@(albumModel.count)];
    self.subTitleLabel.text = photoCount;
    
    @weakify(self);
    PHAsset *asset = albumModel.result.lastObject;
    if (!asset) {
        asset = albumModel.models.firstObject.phAsset;
    }
    if (asset) {
        const CGFloat scale = [UIScreen mainScreen].scale;
        const CGSize targetSize = CGSizeMake(72 * scale, 72 * scale);
        [CAKPhotoManager getUIImageWithPHAsset:asset
                                    targetSize:targetSize
                                   contentMode:PHImageContentModeAspectFill
                                       options:nil
                                 resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            @strongify(self);
            if (@available(iOS 14.0, *)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.iconView.image = result;
                    [self setNeedsLayout];
                    [self layoutIfNeeded];
                });
            } else {
                self.iconView.image = result;
            }
        }];
    }
}

- (void)configBlackBackgroundStyle
{
    [self.titleLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
    [self.subTitleLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.3981]];
}

#pragma mark - Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 25, self.bounds.size.width - 120, 18)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = CAKResourceColor(ACCUIColorConstTextPrimary);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = [UIFont acc_systemFontOfSize:15.0 weight:ACCFontWeightSemibold];
    }
    
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 47, self.bounds.size.width - 120, 16)];
        _subTitleLabel.backgroundColor = [UIColor clearColor];
        _subTitleLabel.textColor = CAKResourceColor(ACCUIColorConstTextTertiary);
        _subTitleLabel.textAlignment = NSTextAlignmentLeft;
        _subTitleLabel.font = [UIFont acc_systemFontOfSize:13.0 weight:ACCFontWeightRegular];
    }
    
    return _subTitleLabel;
}

- (UIImageView *)iconView
{
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 8, 72, 72)];
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        _iconView.layer.masksToBounds = YES;
    }
    
    return _iconView;
}

@end
