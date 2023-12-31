//
//  AWEStickerCommerceEnterView.m
//  Pods
//
//  Created by 郭祁 on 2019/6/9.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerCommerceEnterView.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

@interface AWEStickerCommerceEnterView()

@property (nonatomic, strong) UIImageView *stickerImage;
@property (nonatomic, strong) UIButton *enterButton;
@property (nonatomic, strong) UILabel *enterLabel;
@property (nonatomic, strong) UIImageView *arrowImage;

@property (nonatomic, strong) IESEffectModel *effectModel;

@end

@implementation AWEStickerCommerceEnterView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    UIImageView *stickerImage = [[UIImageView alloc] init];
    stickerImage.layer.masksToBounds = YES;
    stickerImage.layer.cornerRadius = 2.0f;
    [self addSubview:stickerImage];
    ACCMasMaker(stickerImage, {
        make.width.height.equalTo(@20);
        make.left.equalTo(self).offset(5);
        make.centerY.equalTo(self);
    });
    _stickerImage = stickerImage;
    
    UIButton *enterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    enterButton.layer.cornerRadius = 2.0f;
    [self addSubview:enterButton];
    ACCMasMaker(enterButton, {
        make.top.equalTo(self);
        make.height.equalTo(@30);
        make.left.equalTo(stickerImage.mas_right);
        make.right.equalTo(self);
    });
    _enterButton = enterButton;

    UILabel *enterLabel = [[UILabel alloc] init];
    enterLabel.font = [UIFont acc_systemFontOfSize:13.0f weight:ACCFontWeightMedium];
    enterLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    [self addSubview:enterLabel];
    ACCMasMaker(enterLabel, {
        make.left.equalTo(enterButton).offset(5);
        make.right.equalTo(enterButton).offset(-20.0f);
        make.centerY.equalTo(enterButton);
        make.width.lessThanOrEqualTo(@210);
    });
    _enterLabel = enterLabel;

    UIImageView *arrowImage = [[UIImageView alloc] init];
    [arrowImage setImage:ACCResourceImage(@"icBuynow")];
    [self addSubview:arrowImage];
    ACCMasMaker(arrowImage, {
        make.left.equalTo(enterLabel.mas_right);
        make.centerY.equalTo(enterButton);
    });
    _arrowImage = arrowImage;
}

- (void)updateStickerDataWithEffectModel:(IESEffectModel *)effectModel
{
    self.effectModel = effectModel;
    [ACCWebImage() imageView:self.stickerImage setImageWithURLArray:effectModel.iconDownloadURLs];
    self.enterLabel.text = effectModel.commerceBuyText ?: @"";
    CGSize size = [self.enterLabel sizeThatFits:CGSizeMake(210, CGFLOAT_MAX)];
    CGFloat width = MIN(size.width, 210);
    ACCMasUpdate(self.enterLabel, {
        make.width.equalTo(@(width));
    });
}

@end
