//
//  AWEDouPlusEffectHintView.m
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/6/23.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEDouPlusEffectHintView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEDouPlusEffectHintView ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation AWEDouPlusEffectHintView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupSubviews];
    }
    return self;
}

- (void)p_setupSubviews
{
    [self addSubview:self.iconImageView];
    [self addSubview:self.textLabel];
    ACCMasMaker(self.iconImageView, {
        make.leading.equalTo(self);
        make.centerY.equalTo(self);
        make.width.equalTo(@18);
        make.height.equalTo(@18);
    });
    ACCMasMaker(self.textLabel, {
        make.leading.equalTo(self.iconImageView.mas_trailing).offset(6);
        make.centerY.equalTo(self.iconImageView);
        make.trailing.equalTo(self);
    });
}

- (void)showWithImageUrlList:(NSArray<NSString *> *)urlList
{
    if (!ACC_isEmptyArray(urlList)) {
        [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:urlList];
        self.iconImageView.hidden = NO;
    }
    self.textLabel.hidden = NO;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.hidden = YES;
    }
    return _iconImageView;
}

- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.numberOfLines = 1;
        _textLabel.hidden = YES;
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = ACCColorFromRGBA(0, 0, 0, 0.15);
        shadow.shadowOffset = CGSizeMake(0, 0.5);
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"用道具，赢 " attributes:@{NSFontAttributeName:[ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium], NSForegroundColorAttributeName:ACCResourceColor(ACCColorConstTextInverse),NSShadowAttributeName:shadow}];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = ACCResourceImage(@"icon_dou_plus_hint");
        attachment.bounds = CGRectMake(0, 0, 38, 8);
        NSAttributedString *attributedStringImage = [NSAttributedString attributedStringWithAttachment:attachment];
        NSAttributedString *attributedStringBack = [[NSAttributedString alloc] initWithString:@" 流量奖励" attributes:@{NSFontAttributeName:[ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium], NSForegroundColorAttributeName:ACCResourceColor(ACCColorConstTextInverse),NSShadowAttributeName:shadow}];
        [attributedString appendAttributedString:attributedStringImage];
        [attributedString appendAttributedString:attributedStringBack];
        _textLabel.attributedText = attributedString;
    }
    return _textLabel;
}




@end
