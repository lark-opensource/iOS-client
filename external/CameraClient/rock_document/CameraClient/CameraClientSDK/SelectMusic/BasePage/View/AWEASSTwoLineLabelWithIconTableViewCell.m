//
//  AWEASSTwoLineLabelWithIconTableViewCell.m
//  AWEStudio
//
//  Created by liunan on 2018/11/26.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEASSTwoLineLabelWithIconTableViewCell.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEASSTwoLineLabelWithIconTableViewCell()
@property (nonatomic, strong, readwrite) UIImageView *icon;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@end

@implementation AWEASSTwoLineLabelWithIconTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

#pragma mark - Private

- (void)setupUI {
    [self.contentView addSubview:self.icon];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subtitleLabel];
    ACCMasMaker(self.icon, {
        make.top.mas_equalTo(57.5);
        make.centerX.equalTo(self);
    });
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.icon.mas_bottom).offset(16);
        make.leading.equalTo(self).offset(32);
        make.trailing.equalTo(self).offset(-32);
    });
    ACCMasMaker(self.subtitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.leading.equalTo(self).offset(32);
        make.trailing.equalTo(self).offset(-32);
    });
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
        _titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:17.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textColor = ACCResourceColor(ACCUIColorConstTextSecondary);
        _subtitleLabel.font = [ACCFont() systemFontOfSize:14.0];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
    }
    return _subtitleLabel;
}

- (UIImageView *)icon {
    if (!_icon) {
        _icon = [[UIImageView alloc] initWithImage:ACCResourceImage(@"imgEmptyfavorites")];
    }
    return _icon;
}

@end
