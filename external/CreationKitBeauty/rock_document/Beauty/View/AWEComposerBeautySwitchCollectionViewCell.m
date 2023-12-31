//
//  AWEComposerBeautySwitchCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/3/29.
//

#import "AWEComposerBeautySwitchCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEComposerBeautySwitchCollectionViewCell()

@property (nonatomic, strong, readwrite) UILabel *switchLabel;
@property (nonatomic, strong) UIView *switchIconView;
@property (nonatomic, strong) UIView *separatorLineView;
@property (nonatomic, strong) UIImageView *iconImageView;

@end

@implementation AWEComposerBeautySwitchCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.switchIconView];
    ACCMasMaker(self.switchIconView, {
        make.top.equalTo(self).offset(4);
        make.left.equalTo(self.mas_left).offset(-6);
        make.height.equalTo(@(52));
        make.width.equalTo(@(52));
    });

    [self addSubview:self.separatorLineView];
    ACCMasMaker(self.separatorLineView, {
        make.left.equalTo(self.mas_right).offset(-1);
        make.centerY.equalTo(self.iconImageView.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(0.5, 45));
    });

    [self addSubview:self.switchLabel];
    ACCMasMaker(self.switchLabel, {
        make.top.equalTo(self.switchIconView.mas_bottom).offset(9);
        make.centerX.equalTo(self.iconImageView.mas_centerX);
        make.height.equalTo(@(15));
        make.width.equalTo(@(60));
    });
}

- (void)updateSwitchViewIfIsOn:(BOOL)isOn
{
    self.iconImageView.image = isOn ? ACCResourceImage(@"icStickerEditComplete") : ACCResourceImage(@"icStickerEditNone");
    [self.switchLabel setText:(isOn ? ACCLocalizedString(@"on", nil) : ACCLocalizedString(@"off", nil))];
}

- (UIView *)switchIconView
{
    if (!_switchIconView) {
        _switchIconView = [[UIView alloc] init];
        [_switchIconView addSubview:self.iconImageView];
        ACCMasMaker(self.iconImageView, {
            make.center.equalTo(_switchIconView);
        });
    }
    return _switchIconView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 17)];
        _iconImageView.userInteractionEnabled = YES;
    }
    return _iconImageView;
}

- (UILabel *)switchLabel
{
    if (!_switchLabel) {
        _switchLabel = [[UILabel alloc] init];
        _switchLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _switchLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightRegular];
        _switchLabel.numberOfLines = 1;
        _switchLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _switchLabel;
}

- (UIView *)separatorLineView
{
    if (!_separatorLineView) {
        _separatorLineView = [[UIView alloc] init];
        _separatorLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
    }
    return _separatorLineView;
}

@end
