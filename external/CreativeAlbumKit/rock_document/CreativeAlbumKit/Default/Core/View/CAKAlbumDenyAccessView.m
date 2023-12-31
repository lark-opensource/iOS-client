//
//  CAKAlbumDenyAccessView.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/24.
//

#import "CAKAlbumDenyAccessView.h"
#import "CAKLanguageManager.h"
#import "UIImage+AlbumKit.h"
#import "UIColor+AlbumKit.h"
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface CAKAlbumDenyAccessView ()

@property (nonatomic, strong) UIImageView *displayImageView;
@property (nonatomic, strong) UILabel *accessAlbumLabel;
@property (nonatomic, strong) UILabel *accessAllPhotoLabel;

@end


@implementation CAKAlbumDenyAccessView

@synthesize startSettingButton = _startSettingButton;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat verticalSpacingFactor = self.acc_height / 553;
    CGSize imageSize = CGSizeMake(240, 160);
    CGSize accessAlbumSize = CGSizeMake(311, 24);
    CGSize startSettingSize = CGSizeMake(280, 44);
    
    ACCMasReMaker(self.displayImageView, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.mas_top).offset(62 * verticalSpacingFactor);
        make.size.equalTo(@(imageSize));
    });

    ACCMasReMaker(self.accessAlbumLabel, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.displayImageView.mas_bottom).offset(20 * verticalSpacingFactor);
        make.size.mas_equalTo(@(accessAlbumSize));
    });
    
    ACCMasReMaker(self.accessAllPhotoLabel, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.accessAlbumLabel.mas_bottom).offset(12 * verticalSpacingFactor);
        make.width.mas_equalTo(311);
    });
    
    ACCMasReMaker(self.startSettingButton, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.accessAllPhotoLabel.mas_bottom).offset(64 * verticalSpacingFactor);
        make.size.mas_equalTo(@(startSettingSize));
    });
}

- (void)setupUI
{
    self.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
    
    CGFloat verticalSpacingFactor = self.acc_height / 553;
    CGSize imageSize = CGSizeMake(240, 160);
    CGSize accessAlbumSize = CGSizeMake(311, 24);
    CGSize startSettingSize = CGSizeMake(280, 44);
    
    [self addSubview:self.displayImageView];
    ACCMasMaker(self.displayImageView, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.mas_top).offset(62 * verticalSpacingFactor);
        make.size.equalTo(@(imageSize));
    });

    [self addSubview:self.accessAlbumLabel];
    ACCMasMaker(self.accessAlbumLabel, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.displayImageView.mas_bottom).offset(20 * verticalSpacingFactor);
        make.size.mas_equalTo(@(accessAlbumSize));
    });
    
    [self addSubview:self.accessAllPhotoLabel];
    ACCMasMaker(self.accessAllPhotoLabel, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.accessAlbumLabel.mas_bottom).offset(12 * verticalSpacingFactor);
        make.width.mas_equalTo(311);
    });
    
    [self addSubview:self.startSettingButton];
    ACCMasMaker(self.startSettingButton, {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.accessAllPhotoLabel.mas_bottom).offset(64 * verticalSpacingFactor);
        make.size.mas_equalTo(@(startSettingSize));
    });
}


#pragma mark - getter

- (UIImageView *)displayImageView
{
    if (!_displayImageView) {
        _displayImageView = [[UIImageView alloc] init];
        _displayImageView.image = CAKResourceImage(@"image_deny_access_album");
    }
    return _displayImageView;
}

- (UILabel *)accessAlbumLabel
{
    if (!_accessAlbumLabel) {
        _accessAlbumLabel = [[UILabel alloc] init];
        _accessAlbumLabel.text = CAKLocalizedString(@"authorization_album_noaccess_title", @"Allow access to your photos");
        _accessAlbumLabel.textColor = CAKResourceColor(ACCColorTextReverse);
        _accessAlbumLabel.textAlignment = NSTextAlignmentCenter;
        _accessAlbumLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:17];
    }
    return _accessAlbumLabel;
}

- (UILabel *)accessAllPhotoLabel
{
    if (!_accessAllPhotoLabel) {
        _accessAllPhotoLabel = [[UILabel alloc] init];
        _accessAllPhotoLabel.text = CAKLocalizedString(@"albumsdk_rejection_body", @"当前设置是“不允许访问照片”，请到设置中开启相册访问权限。");
        _accessAllPhotoLabel.textColor = CAKResourceColor(ACCColorTextReverse3);
        _accessAllPhotoLabel.numberOfLines = 0;
        _accessAllPhotoLabel.textAlignment = NSTextAlignmentCenter;
        _accessAllPhotoLabel.font = [UIFont acc_systemFontOfSize:14 weight:ACCFontWeightRegular];
        [_accessAllPhotoLabel sizeToFit];
    }
    return _accessAllPhotoLabel;
}

- (UIButton *)startSettingButton
{
    if (!_startSettingButton) {
        _startSettingButton = [[UIButton alloc] init];
        _startSettingButton.backgroundColor = CAKResourceColor(ACCColorPrimary);
        [_startSettingButton setTitle:CAKLocalizedString(@"authorization_gotosetting", @"Go to settings") forState:UIControlStateNormal];
        [_startSettingButton setTitleColor:CAKResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
        _startSettingButton.titleLabel.font = [UIFont acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
    }
    return _startSettingButton;
}


@end
