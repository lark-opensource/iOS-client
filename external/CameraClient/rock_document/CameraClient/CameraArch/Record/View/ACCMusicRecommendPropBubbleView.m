//
//  ACCMusicRecommendPropBubbleView.m
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/11.
//

#import "ACCMusicRecommendPropBubbleView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <Masonry/Masonry.h>

@interface ACCMusicRecommendPropBubbleView ()

@property (nonatomic, strong) UIImageView *propImageView;

@property (nonatomic, strong) UILabel *propNameLabel;

@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) UIButton *usePropButton;

@property (nonatomic, strong) IESEffectModel *propModel;

@property (nonatomic, copy) ACCUseRecommendPropBlock useRecommendPropBlock;

@property (nonatomic, assign) CGSize bubbleViewSize;

@end

@implementation ACCMusicRecommendPropBubbleView

- (instancetype)initWithPropModel:(IESEffectModel *)propModel
                     usePropBlock:(ACCUseRecommendPropBlock)usePropBlock
{
    self = [super init];
    if (self) {
        self.propModel = propModel;
        self.useRecommendPropBlock = usePropBlock;
        [self configBubbleViewUI];
    }
    return self;
}

#pragma mark - UI

- (void)configBubbleViewUI
{
    CGSize propImageViewSize = CGSizeMake(40, 40);
    CGSize usePropButtonSize = CGSizeMake(48, 24);
    CGSize propNameLabelTextSize = [self.propNameLabel.text acc_sizeWithFont:self.propNameLabel.font width:95 maxLine:1];
    propNameLabelTextSize.height = 18;
    CGSize hintLabelTextSize = [self.hintLabel.text acc_sizeWithFont:self.hintLabel.font width:50 maxLine:1];
    hintLabelTextSize.height = 17;

    CGSize tempSize = CGSizeZero;
    tempSize.width = propImageViewSize.width + usePropButtonSize.width + MAX(propNameLabelTextSize.width, hintLabelTextSize.width) + 44;
    tempSize.height = propImageViewSize.height + 24;
    self.bubbleViewSize = tempSize;

    [self addSubview:self.propImageView];
    [self addSubview:self.propNameLabel];
    [self addSubview:self.hintLabel];
    [self addSubview:self.usePropButton];

    ACCMasMaker(self.propImageView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(12);
        make.size.equalTo(@(propImageViewSize));
    });

    ACCMasMaker(self.propNameLabel, {
        make.left.equalTo(self).offset(60);
        make.top.equalTo(self).offset(12);
        make.size.equalTo(@(propNameLabelTextSize));
    });

    ACCMasMaker(self.hintLabel, {
        make.left.equalTo(self).offset(60);
        make.bottom.equalTo(self).offset(-13);
        make.size.equalTo(@(hintLabelTextSize));
    });

    ACCMasMaker(self.usePropButton, {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-12);
        make.size.equalTo(@(usePropButtonSize));
    });
}

# pragma mark - Lazy load

- (UIImageView *)propImageView
{
    if (!_propImageView) {
        _propImageView = [[UIImageView alloc] init];
        _propImageView.layer.cornerRadius = 2;
        _propImageView.layer.masksToBounds = YES;
        [ACCWebImage() imageView:_propImageView setImageWithURLArray:self.propModel.iconDownloadURLs];
    }
    return _propImageView;
}

- (UILabel *)propNameLabel
{
    if (!_propNameLabel) {
        _propNameLabel = [[UILabel alloc] init];
        _propNameLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightBold];
        _propNameLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _propNameLabel.textAlignment = NSTextAlignmentCenter;
        _propNameLabel.text = self.propModel.effectName;
    }
    return _propNameLabel;
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        _hintLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
        _hintLabel.textAlignment = NSTextAlignmentCenter;
        _hintLabel.text = ACCLocalizedString(@"music_effect_for_you", @"推荐道具");
    }
    return _hintLabel;
}

- (UIButton *)usePropButton
{
    if (!_usePropButton) {
        _usePropButton = [[UIButton alloc] init];
        [_usePropButton setBackgroundColor:ACCResourceColor(ACCColorPrimary)];
        _usePropButton.layer.cornerRadius = 2;
        _usePropButton.layer.masksToBounds = YES;
        [_usePropButton setTitle:ACCLocalizedString(@"com_mig_use", @"使用") forState:UIControlStateNormal];
        [_usePropButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
        _usePropButton.titleLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightBold];
        _usePropButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_usePropButton addTarget:self action:@selector(didClickUsePropButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _usePropButton;
}

- (CGSize)intrinsicContentSize
{
    return self.bubbleViewSize;
}

#pragma mark - action

- (void)didClickUsePropButton
{
    ACCBLOCK_INVOKE(self.useRecommendPropBlock, self.propModel);
}

@end
