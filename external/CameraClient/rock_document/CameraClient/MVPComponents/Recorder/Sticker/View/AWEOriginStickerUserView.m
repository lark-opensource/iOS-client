//
//  AWEOriginStickerUserView.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/9/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEOriginStickerUserView.h"
#import <CreationKitArch/ACCCommerceStickerDetailModelProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSDate+ACCAdditions.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitArch/ACCUserModelProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static NSString * const ACCOriginStickerUserViewNeedValidateLabel = @"acc.origin_sticker_user_view.need_validate_label";

@interface AWEOriginStickerUserView ()

/**
To anyone who might be confused of this class:

Despite the name `AWEOriginStickerUserView`, it might be utilized to display commerce info, prop creator and prop name under different circumstances. Specific usage of each property is listed below.

`iconImageView`: For commerce icon, prop icon or creator avatar.
`titleLabel`:  For commerce prop description or prop name.
`createdByLabel`: This label displays "创作者：" in Chinese and "Creator:" in English.
`creatorNameLabel`: For creator name only.
`validateLabel`: This label displays expire time of commerce prop.

 */

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *createdByLabel;
@property (nonatomic, strong) UILabel *creatorNameLabel;
@property (nonatomic, strong) UILabel *validateLabel;

@end

@implementation AWEOriginStickerUserView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.createdByLabel];
        [self addSubview:self.iconImageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.creatorNameLabel];
        
        ACCMasMaker(self.createdByLabel, {
            make.left.equalTo(self);
            make.centerY.equalTo(self.mas_centerY);
        });

        ACCMasMaker(self.iconImageView, {
            make.width.height.equalTo(@20);
            make.centerY.equalTo(self.mas_centerY);
            make.left.equalTo(self.createdByLabel.mas_right);
        });
        
        ACCMasMaker(self.titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(4);
            make.centerY.equalTo(self.mas_centerY);
            make.right.equalTo(self.mas_right);
        });

        ACCMasMaker(self.creatorNameLabel, {
            make.left.equalTo(self.createdByLabel.mas_right);
            make.centerY.equalTo(self.createdByLabel.mas_centerY);
        });
        
        if (ACCBoolConfig(ACCOriginStickerUserViewNeedValidateLabel)) {
            [self addSubview:self.validateLabel];
            ACCMasMaker(self.validateLabel, {
                make.left.right.equalTo(self.titleLabel);
                make.top.equalTo(self.titleLabel.mas_bottom).offset(1);
                make.height.offset(13);
            });
        }
        
        [self.createdByLabel setContentCompressionResistancePriority:[self.titleLabel contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal]  forAxis:UILayoutConstraintAxisHorizontal];
    }
    return self;
}


- (void)updateWithCommerceModel:(id<ACCCommerceStickerDetailModelProtocol>)commerceModel
{
    self.createdByLabel.hidden = YES;
    CGFloat offsetY = 0;
    if (ACCBoolConfig(ACCOriginStickerUserViewNeedValidateLabel)) {
        if (commerceModel.expireTime > 0) {
            self.validateLabel.hidden = NO;
            self.validateLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"out_date_time", @"过期时间: %@"), [[NSDate dateWithTimeIntervalSince1970:commerceModel.expireTime] acc_stringWithFormat:@"yyyy.MM.dd"]];
            // The height of `validateLabel` is 13pt, with an offset of 1pt to `titleLabel`, making the y offset of its center to be 7pt.
            offsetY = 7;
        } else {
            self.validateLabel.hidden = YES;
        }
    }
    self.titleLabel.numberOfLines = 2;
    self.iconImageView.layer.cornerRadius = 2;
    ACCMasReMaker(self.iconImageView, {
        make.width.height.equalTo(@20);
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(self);
    });
    CGFloat containerWidth = ACC_SCREEN_WIDTH - 16 - 105;
    CGFloat height = [commerceModel.screenDesc acc_heightWithFont:self.titleLabel.font width:(containerWidth - 28)];
    if (ACC_FLOAT_GREATER_THAN(height, 15)) { // More than two lines
        ACCMasReMaker(self.titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(4);
            make.top.equalTo(self.iconImageView).offset(-offsetY);
            make.right.equalTo(self.mas_right);
        });
    } else {
        ACCMasReMaker(self.titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(4);
            make.centerY.equalTo(self.mas_centerY).offset(-offsetY);
            make.right.equalTo(self.mas_right);
        });
    }
    @weakify(self);
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:[commerceModel.screenIconURL URLList] placeholder:nil completion:^(UIImage *image, NSURL *url, NSError *error) {
        CGFloat width = 0;
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"set web image failed: %@", error);
        }
        if (!error && image != nil && !ACC_FLOAT_EQUAL_ZERO(image.size.height)) {
            width = image.size.width * 20 / image.size.height;
        }
        @strongify(self);
        ACCMasUpdate(self.iconImageView, {
            make.width.equalTo(@(width));
        });
    }];
    self.titleLabel.text = commerceModel.screenDesc;
}

- (void)updateWithUserModel:(id<ACCUserModelProtocol>)userModel
{
    BOOL shouldHideCreationInfo = (userModel == nil);
    self.titleLabel.hidden = YES;
    self.validateLabel.hidden = YES;
    self.createdByLabel.hidden = shouldHideCreationInfo;
    self.createdByLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
    ACCMasReMaker(self.createdByLabel, {
        make.left.equalTo(self);
        make.centerY.equalTo(self);
    })

    self.iconImageView.hidden = shouldHideCreationInfo;
    self.iconImageView.layer.cornerRadius = 10;
    ACCMasReMaker(self.iconImageView, {
        make.width.height.equalTo(@20);
        make.top.equalTo(self);
        make.left.equalTo(self.createdByLabel.mas_right);
    });
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:userModel.avatarThumb.URLList];

    self.creatorNameLabel.hidden = shouldHideCreationInfo;
    self.creatorNameLabel.text = userModel.nickname;
    self.creatorNameLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
    ACCMasReMaker(self.creatorNameLabel, {
        make.left.equalTo(self.iconImageView.mas_right).offset(4);
        make.centerY.equalTo(self.mas_centerY);
        make.right.equalTo(self.mas_right);
    });

}

#pragma mark - getter

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.layer.cornerRadius = 10;
        _iconImageView.layer.masksToBounds = YES;
    }
    return _iconImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _titleLabel.shadowColor = ACCResourceColor(ACCUIColorConstSDSecondary);
        _titleLabel.shadowOffset = CGSizeMake(0, 0.5);
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UILabel *)createdByLabel
{
    if (!_createdByLabel) {
        _createdByLabel = [[UILabel alloc] init];
        _createdByLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        _createdByLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _createdByLabel.shadowColor = ACCResourceColor(ACCUIColorConstSDSecondary);
        _createdByLabel.shadowOffset = CGSizeMake(0, 0.5);
        _createdByLabel.text = @"原创作者：";
    }
    return _createdByLabel;
}

- (UILabel *)validateLabel
{
    if (!_validateLabel) {
        _validateLabel = [[UILabel alloc] init];
        _validateLabel.font = [ACCFont() systemFontOfSize:10 weight:ACCFontWeightRegular];
        _validateLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse3);
        _validateLabel.shadowColor = ACCResourceColor(ACCUIColorConstSDSecondary);
        _validateLabel.shadowOffset = CGSizeMake(0, 0.5);
    }
    return _validateLabel;
}

- (UILabel *)creatorNameLabel
{
    if (!_creatorNameLabel) {
        _creatorNameLabel = [[UILabel alloc] init];
        _creatorNameLabel.font = [ACCFont() systemFontOfSize:10 weight:ACCFontWeightRegular];
        _creatorNameLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _creatorNameLabel.shadowColor = ACCResourceColor(ACCUIColorConstSDSecondary);
        _creatorNameLabel.shadowOffset = CGSizeMake(0, 0.5);
    }
    return _creatorNameLabel;
}

@end
