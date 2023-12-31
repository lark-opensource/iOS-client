//
//  CJPayAuthVerifiedView.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/22.
//

#import "CJPayAuthVerifiedView.h"

#import "CJPayStyleButton.h"
#import "CJPayTouchLabel.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayDeskTheme.h"
#import "CJPayCurrentTheme.h"
#import "CJPayAuthDisplayContentModel.h"
#import "CJPayAuthAgreementContentModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayAuthVerifiedTipsItemView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"

#import <BDWebImage/BDWebImage.h>
#import "CJPayProtocolPopUpViewController.h"

@interface CJPayAuthVerifiedView()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *closeImageView;
@property (nonatomic, strong) UIView *sepView;
@property (nonatomic, strong) UIImageView *exclamatoryMarkImageView;
@property (nonatomic, strong) UILabel *tipsTitleLabel;
@property (nonatomic, strong) CJPayAuthVerifiedTipsItemView *tipsItemView;
@property (nonatomic, strong) UIStackView *tipsStackView;
@property (nonatomic, strong) CJPayStyleButton *authButton;
@property (nonatomic, strong) CJPayButton *notMeButton;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, copy)   NSDictionary *customStyle;

@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) CJPayAuthAgreementContentModel *model;

@end

@implementation CJPayAuthVerifiedView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithStyle:(NSDictionary*)style
{
    self = [super init];
    if (self) {
        _customStyle = style;
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithModel:(CJPayAuthAgreementContentModel *)model
{
    self.model = model;
    CJPayAuthDisplayContentModel *displayModel = model.businessBriefInfo;
    if (Check_ValidString(displayModel.displayUrl)) {
        [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:displayModel.displayUrl] placeholder:[UIImage cj_imageWithName:@"cj_auth_icon"]];
    }
    self.titleLabel.text = displayModel.displayDesc;
    
    self.tipsTitleLabel.text = model.proposeDesc;
    [self.tipsStackView cj_removeAllSubViews];
    [model.proposeContents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayAuthVerifiedTipsItemView *itemView = [CJPayAuthVerifiedTipsItemView new];
        [itemView updateTitle:obj];
        [self.tipsStackView addArrangedSubview:itemView];
    }];
    
    if (!Check_ValidString(model.disagreeUrl)) {
        self.notMeButton.hidden = YES;
        CJPayMasUpdate(self.notMeButton, {
            make.height.mas_equalTo(0);
        });
    }
    else {
        self.notMeButton.hidden = NO;
        CJPayMasUpdate(self.notMeButton, {
            make.height.mas_equalTo(20);
        });
    }
}

- (void)updateWithCommonModel:(CJPayCommonProtocolModel *)model {
    [self.protocolView updateWithCommonModel:model];
}

- (void)hideExclamatoryMark:(BOOL)isHidden {
    self.exclamatoryMarkImageView.hidden = isHidden;
}

#pragma mark - Private Methods

- (NSAttributedString *)p_getAttributeStringWithProtocolArray:(NSArray<NSString *> *)protocolArray withGuide:(NSString *)guideMessage withSeperate:(NSString *)seperate {
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.cjMaximumLineHeight = 18;
    paraStyle.cjMinimumLineHeight = 18;
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *weakAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.5],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    UIColor *protocolTextColor = [CJPayThemeStyleManager shared].serverTheme.agreementTextColor ?: [UIColor cj_colorWithHexString:@"#155494"];
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName : protocolTextColor,
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:CJString(guideMessage) attributes:weakAttributes];
    [protocolArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *content = [NSString stringWithFormat:@"%@%@", (idx == 0) ? @"" : CJString(seperate), CJString(obj)];
        [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(content) attributes:mainAttributes]];
    }];
    return attributeStr;
}

- (void)p_tapCloseImageView
{
    CJ_CALL_BLOCK(self.closeBlock);
}

- (void)p_tapExclamatoryMarkImageView
{
    CJ_CALL_BLOCK(self.clickExclamatoryMarkBlock);
}

- (void)p_authButtonTapped
{
    @CJWeakify(self)
    [self.protocolView executeWhenProtocolSelected:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.authVerifiedBlock);
    } notSeleted:^{
        @CJStrongify(self)
        CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.protocolView.protocolModel from:[self p_pageName]];
        popupProtocolVC.confirmBlock = ^{
            @CJStrongify(self)
            [self.protocolView setCheckBoxSelected:YES];
            CJ_CALL_BLOCK(self.authVerifiedBlock);
        };
        [[self cj_responseViewController].navigationController pushViewController:popupProtocolVC animated:YES];
    } hasToast:NO];
}

- (void)p_notMeButtonTapped
{
    CJ_CALL_BLOCK(self.notMeBlock, self.model.disagreeUrl);
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.closeImageView];
    [self addSubview:self.sepView];
    [self addSubview:self.tipsTitleLabel];
    [self addSubview:self.exclamatoryMarkImageView];
    [self addSubview:self.tipsStackView];
    [self addSubview:self.protocolView];
    [self addSubview:self.authButton];
    [self addSubview:self.notMeButton];
    
    CJPayMasMaker(self.iconImageView, {
        make.left.top.equalTo(self).offset(16);
        make.width.height.mas_equalTo(40);
    });
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.centerY.equalTo(self.iconImageView);
    });
    CJPayMasMaker(self.sepView, {
        make.top.equalTo(self.iconImageView.mas_bottom).offset(16);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });

    CJPayMasMaker(self.closeImageView, {
        make.top.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.width.height.mas_equalTo(24);
    });

    CJPayMasMaker(self.tipsTitleLabel, {
        make.left.equalTo(self.iconImageView);
        make.top.equalTo(self.iconImageView.mas_bottom).offset(32);
    });

    CJPayMasMaker(self.exclamatoryMarkImageView, {
        make.centerY.equalTo(self.tipsTitleLabel);
        make.left.equalTo(self.tipsTitleLabel.mas_right).offset(4);
        make.height.width.mas_equalTo(16);
    });

    CJPayMasMaker(self.tipsStackView, {
        make.top.equalTo(self.tipsTitleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.iconImageView);
        make.right.equalTo(self).offset(-16);
    });
    CJPayMasMaker(self.protocolView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.centerX.equalTo(self.authButton);
        make.bottom.equalTo(self.authButton.mas_top).offset(-17);
    });
    CJPayMasMaker(self.authButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.bottom.equalTo(self.notMeButton.mas_top).offset(-13);
        make.height.mas_equalTo(48);
    });
    CJPayMasMaker(self.notMeButton, {
        make.left.right.equalTo(self.authButton);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.mas_bottom).offset(CJ_IPhoneX ? -CJ_TabBarSafeBottomMargin-13 : -13);
    });
}

- (NSString *)p_pageName {
    return @"实名授权";
}

#pragma mark - Getter
- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
        [_iconImageView cj_showCornerRadius:8];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _titleLabel.textColor = [UIColor cj_161823ff];
    }
    return _titleLabel;
}

- (UIImageView *)closeImageView
{
    if (!_closeImageView) {
        _closeImageView = [UIImageView new];
        [_closeImageView cj_setImage:@"cj_close_icon"];
        _closeImageView.userInteractionEnabled = YES;
        [_closeImageView cj_viewAddTarget:self
                                   action:@selector(p_tapCloseImageView)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeImageView;;
}

- (UILabel *)tipsTitleLabel
{
    if (!_tipsTitleLabel) {
        _tipsTitleLabel = [UILabel new];
        _tipsTitleLabel.font = [UIFont cj_boldFontOfSize:15];
        _tipsTitleLabel.textColor = [UIColor cj_161823ff];
        _tipsTitleLabel.numberOfLines = 2;
    }
    return _tipsTitleLabel;
}

- (UIStackView *)tipsStackView
{
    if (!_tipsStackView) {
        _tipsStackView = [[UIStackView alloc] init];
        _tipsStackView.axis = UILayoutConstraintAxisVertical;
        _tipsStackView.distribution = UIStackViewDistributionFillProportionally;
        _tipsStackView.spacing = 12;
    }
    return _tipsStackView;
}

- (CJPayCommonProtocolView *)protocolView
{
    if(!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

- (CJPayStyleButton *)authButton
{
    if (!_authButton) {
        _authButton = [CJPayStyleButton new];
        _authButton.disablesInteractionWhenLoading = NO;
        CJPayDeskTheme *theme = [CJPayCurrentTheme shared].currentTheme;
        if (self.customStyle != nil) {
            [self.authButton cj_showCornerRadius:[self.customStyle cj_intValueForKey:@"corner_radius"]];
            [self.authButton cj_setBtnTitleColor:[UIColor cj_colorWithHexString:[self.customStyle cj_stringValueForKey:@"text_color"]]];
            [self.authButton cj_setBtnBGColor:[UIColor cj_colorWithHexString:[self.customStyle cj_stringValueForKey:@"btn_color"]]];
        } else if (theme != nil){
            [_authButton cj_setBtnTitleColor:[theme fontColor]];
            [_authButton cj_setBtnBGColor:[theme bgColor]];
            [_authButton cj_showCornerRadius:[theme confirmButtonShape]];
        } else {
            [_authButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
            [_authButton cj_setBtnTitleColor:UIColor.whiteColor];
            [_authButton cj_showCornerRadius:5];
        }
        [_authButton cj_setBtnTitle:CJPayLocalizedStr(@"同意协议并授权")];
        [_authButton addTarget:self action:@selector(p_authButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _authButton.titleLabel.font = [UIFont cj_fontOfSize:15];
        _authButton.cjEventInterval = 1;
    }
    return _authButton;
}

- (CJPayButton *)notMeButton
{
    if (!_notMeButton) {
        _notMeButton = [CJPayButton new];
        [_notMeButton cj_setBtnTitle:CJPayLocalizedStr(@"不是本人信息")];
        [_notMeButton cj_setBtnTitleColor:[UIColor cj_161823ff]];
        [_notMeButton addTarget:self action:@selector(p_notMeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _notMeButton.titleLabel.font = [UIFont cj_boldFontOfSize:14];
        _notMeButton.cjEventInterval = 1;
    }
    return _notMeButton;
}

- (UIView *)sepView
{
    if (!_sepView) {
        _sepView = [[UIView alloc] init];
        _sepView.backgroundColor = [UIColor cj_e8e8e8ff];
    }
    return _sepView;
}

- (UIImageView *)exclamatoryMarkImageView
{
    if (!_exclamatoryMarkImageView) {
        _exclamatoryMarkImageView = [UIImageView new];
        [_exclamatoryMarkImageView cj_setImage:@"cj_exclamatory_mark_icon"];
        _exclamatoryMarkImageView.userInteractionEnabled = YES;
        [_exclamatoryMarkImageView cj_viewAddTarget:self
                                             action:@selector(p_tapExclamatoryMarkImageView)
                                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _exclamatoryMarkImageView;
}

@end
