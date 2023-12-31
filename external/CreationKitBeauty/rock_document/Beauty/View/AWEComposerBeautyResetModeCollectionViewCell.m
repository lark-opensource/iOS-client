//
//  AWEComposerBeautyResetModeCollectionViewCell.m
//  CreationKitBeauty-Pods-Aweme
//
//  Created by bytedance on 2021/9/11.
//

#import "AWEComposerBeautyResetModeCollectionViewCell.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>


@interface AWEComposerBeautyResetModeCollectionViewCell ()

@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) UILabel *nameLabel;
@property (nonatomic, assign) CGFloat iconWidth;

@end

@implementation AWEComposerBeautyResetModeCollectionViewCell


+ (NSString *)identifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.clipsToBounds = NO;

        _iconWidth = 52.f;
        [self addSubviews];

    }
    return self;
}

- (void)addSubviews
{
    [self.contentView addSubview:self.backView];
    ACCMasMaker(self.backView, {
        make.width.height.equalTo(@(self.iconWidth));
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(4);
    });

    [self.backView addSubview:self.iconImageView];
    ACCMasMaker(self.iconImageView, {
        make.edges.equalTo(self.backView);
    });

    [self.contentView addSubview:self.nameLabel];
    ACCMasMaker(self.nameLabel, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.backView.mas_bottom).offset(8);
        make.width.lessThanOrEqualTo(@(self.iconWidth));
    });
}

#pragma mark - config

- (void)setAvailable:(BOOL)available
{
    self.iconImageView.alpha = available ? 1.f : 0.34f;
    self.nameLabel.alpha = available ? 1.f : 0.34f;
}

- (void)setTitle:(NSString *)title
{
    self.nameLabel.text = title;
}

- (void)setIconImage:(UIImage *)image
{
    self.iconImageView.image = image;
}

#pragma mark - lazy init property

- (UIView *)backView
{
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectZero];
        _backView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _backView.layer.cornerRadius = 4;
        _backView.layer.masksToBounds = YES;
    }
    return _backView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.alpha = 0.34f;
    }
    return _iconImageView;
}


- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _nameLabel.font = [ACCFont() acc_systemFontOfSize:11 weight:ACCFontWeightRegular];
        _nameLabel.numberOfLines = 1;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.alpha = 0.34f;
    }
    return _nameLabel;
}

@end
