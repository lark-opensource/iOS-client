//
//  CAKAlbumListBlankView.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/3.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>

#import "CAKAlbumListBlankView.h"
#import "UIColor+AlbumKit.h"
#import "CAKLanguageManager.h"

@interface CAKAlbumListBlankView ()

@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *toSetupButton;

@end

@implementation CAKAlbumListBlankView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.containerView = [[UIView alloc] initWithFrame:frame];
        [self addSubview:self.containerView];

        UILabel *mainTitleLabel = [[UILabel alloc] init];
        mainTitleLabel.font = [UIFont acc_systemFontOfSize:17 weight:ACCFontWeightBold];
        mainTitleLabel.text = CAKLocalizedString(@"com_mig_allow_access_to_photos_and_videos_from_your_device_in_your_settings", @"Allow access to photos and videos from your device in your settings");
        mainTitleLabel.textColor = CAKResourceColor(ACCUIColorConstTextPrimary);
        mainTitleLabel.textAlignment = NSTextAlignmentCenter;
        mainTitleLabel.numberOfLines = 0;
        self.mainTitleLabel = mainTitleLabel;
        [self.containerView addSubview:mainTitleLabel];

        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.font = [UIFont acc_systemFontOfSize:15];
        subtitleLabel.text = CAKLocalizedString(@"com_mig_to_grant_musically_photo_access_go_to_system_settings_privacy_photos_and_find_musically", @"To grant Douyin photo access, go to System Settings - Privacy - Photos and find Douyin");
        subtitleLabel.textColor = CAKResourceColor(ACCUIColorConstTextTertiary);
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.numberOfLines = 0;
        self.subtitleLabel = subtitleLabel;
        [self.containerView addSubview:subtitleLabel];

        UIButton *toSetupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        toSetupButton.backgroundColor = CAKResourceColor(ACCUIColorConstTextPrimary);
        toSetupButton.layer.cornerRadius = 2;
        toSetupButton.layer.masksToBounds = YES;
        [toSetupButton setTitle:CAKLocalizedString(@"com_mig_allow_access_to_photos_and_videos_from_your_device", @"Allow access to photos and videos from your device") forState:UIControlStateNormal];
        toSetupButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [toSetupButton setTitleColor:CAKResourceColor(ACCUIColorConstBGContainer) forState:UIControlStateNormal];
        toSetupButton.titleLabel.font = [UIFont acc_systemFontOfSize:15];
        toSetupButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        toSetupButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        toSetupButton.titleLabel.minimumScaleFactor = 11.0 / 15;
        self.toSetupButton = toSetupButton;
        [self.containerView addSubview:toSetupButton];

        ACCMasMaker(mainTitleLabel, {
            make.bottom.equalTo(subtitleLabel.mas_top).offset(-6);
            make.width.equalTo(@(ACC_SCREEN_WIDTH - 64));
            make.centerX.equalTo(self.mas_centerX);
        });
        
        ACCMasMaker(subtitleLabel, {
            make.bottom.equalTo(self.mas_centerY).offset(-13.5);
            make.width.equalTo(@(ACC_SCREEN_WIDTH - 64));
            make.centerX.equalTo(mainTitleLabel.mas_centerX);
        });

        [toSetupButton setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
        
        ACCMasMaker(toSetupButton, {
            make.leading.greaterThanOrEqualTo(self).offset(32);
            make.trailing.lessThanOrEqualTo(self).offset(-32);
            make.centerX.equalTo(self.mas_centerX);
            make.height.equalTo(@(44));
            make.top.equalTo(self.mas_centerY).offset(46.5);
        });
    }
    return self;
}

- (void)setType:(CAKAlbumListBlankViewType)type
{
    self.mainTitleLabel.hidden = NO;
    BOOL setupButtonHidden = NO;
    NSString *text = @"";
    switch (type) {
        case CAKAlbumListBlankViewTypeNoPermissions: {
            setupButtonHidden = NO;
            text = CAKLocalizedString(@"com_mig_allow_access_to_photos_and_videos_from_your_device_in_your_settings", @"Allow access to photos and videos from your device in your settings");
        }
            break;
        case CAKAlbumListBlankViewTypeNoPhoto: {
            setupButtonHidden = YES;
            text = CAKLocalizedString(@"com_mig_no_photos_available", @"No photos available");
        }
            break;
        case CAKAlbumListBlankViewTypeNoVideo: {
            setupButtonHidden = YES;
            text = CAKLocalizedString(@"com_mig_cannot_find_videos_in_gallery", @"Cannot find videos in gallery");
        }
            break;
        case CAKAlbumListBlankViewTypeNoVideoAndPhoto: {
            setupButtonHidden = YES;
            text = CAKLocalizedString(@"com_mig_no_photos_or_videos_available", @"No photos or videos available");
        }
            break;
    }
    self.subtitleLabel.hidden = setupButtonHidden;
    self.toSetupButton.hidden = setupButtonHidden;
    self.mainTitleLabel.text = text;

}

@end
