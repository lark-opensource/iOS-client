//
//  CJPayAuthVerifiedHalfView.m
//  BDAlogProtocol
//
//  Created by qiangang on 2020/7/16.
//

#import "CJPayAuthVerifiedHalfView.h"

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
#import "UIImageView+CJPay.h"

#import <BDWebImage/BDWebImage.h>

@interface CJPayAuthVerifiedHalfView()

@property (nonatomic, strong) UIImageView *closeImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *applyInfoTitle;
@property (nonatomic, strong) UIView *sepView;
@property (nonatomic, strong) UIImageView *exclamatoryMarkImageView;
@property (nonatomic, strong) CJPayAuthVerifiedTipsItemView *tipsItemView;
@property (nonatomic, strong) UIStackView *tipsStackView;
@property (nonatomic, strong) CJPayTouchLabel *protocolLabel;
@property (nonatomic, strong) CJPayStyleButton *authButton;
@property (nonatomic, strong) CJPayButton *notMeButton;
@property (nonatomic, strong) CJPayAuthAgreementContentModel *model;
@property (nonatomic, copy)   NSDictionary *customStyle;

@end

@implementation CJPayAuthVerifiedHalfView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithStyle:(NSDictionary*)style {
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
    self.applyInfoTitle.text = model.proposeDesc;
    
    [self.tipsStackView cj_removeAllSubViews];
    [model.proposeContents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayAuthVerifiedTipsItemView *itemView = [CJPayAuthVerifiedTipsItemView new];
        [itemView updateTitle:obj];
        [self.tipsStackView addArrangedSubview:itemView];
    }];
    NSMutableArray<NSString *> *protocolNameArray = [[model.agreementContents valueForKey:@"displayDesc"] mutableCopy];
    [self.model.secondAgreementContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayAuthDisplayMultiContentModel.class]) {
            CJPayAuthDisplayMultiContentModel *contentModel = (CJPayAuthDisplayMultiContentModel *)obj;
            [protocolNameArray addObject:contentModel.oneDisplayDesc];
        }
    }];
    
    if (protocolNameArray.count > 0) {
        self.protocolLabel.attributedText = [self p_getAttributeStringWithProtocolArray:protocolNameArray];
    }
    
    @CJWeakify(self)
    [self.protocolLabel cj_addAttributeTapActionWithStrings:protocolNameArray tapClicked:^(UILabel * _Nonnull label, NSString * _Nonnull string, NSRange range, NSInteger index) {
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.protocolClickedBlock, label, string, range, index);
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

- (void)hideExclamatoryMark:(BOOL)isHidden {
    self.exclamatoryMarkImageView.hidden = isHidden;
}

#pragma mark - Private Methods
- (NSAttributedString *)p_getAttributeStringWithProtocolArray:(NSArray<NSString *> *)protocolArray
{
    if (protocolArray.count == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.cjMaximumLineHeight = 18;
    paraStyle.cjMinimumLineHeight = 18;
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *weakAttributes = @{NSFontAttributeName : [UIFont cj_fontWithoutFontScaleOfSize:13],
                                     NSForegroundColorAttributeName : [UIColor cj_colorWithHexString:@"8a8b91"],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    UIColor *protocolTextColor = [CJPayThemeStyleManager shared].serverTheme.agreementTextColor;
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont cj_fontWithoutFontScaleOfSize:13],
                                     NSForegroundColorAttributeName : protocolTextColor,
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"阅读并同意") attributes:weakAttributes];
    [protocolArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *protocolName = [NSString stringWithFormat:@"《%@》", obj];
        [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(protocolName) attributes:mainAttributes]];
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
    CJ_CALL_BLOCK(self.authVerifiedBlock);
}

- (void)p_notMeButtonTapped
{
    CJ_CALL_BLOCK(self.notMeBlock,self.model.disagreeUrl);
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.closeImageView];
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.applyInfoTitle];
    [self addSubview:self.sepView];
    [self addSubview:self.tipsStackView];
    [self addSubview:self.exclamatoryMarkImageView];
    [self addSubview:self.protocolLabel];
    [self addSubview:self.authButton];
    [self addSubview:self.notMeButton];
    
    CJPayMasMaker(self.closeImageView, {
        make.left.equalTo(self).offset(13);
        make.top.equalTo(self).offset(15);
        make.width.height.mas_equalTo(24);
    });
    CJPayMasMaker(self.iconImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(36);
        make.width.height.mas_equalTo(60);
    });
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.iconImageView);
        make.top.equalTo(self.iconImageView.mas_bottom).offset(13);
        make.height.mas_equalTo(22);
        make.width.lessThanOrEqualTo(self);
    });
    CJPayMasMaker(self.applyInfoTitle, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(19);
    });
    CJPayMasMaker(self.exclamatoryMarkImageView, {
        make.centerY.equalTo(self.applyInfoTitle);
        make.left.equalTo(self.applyInfoTitle.mas_right).offset(4);
        make.height.width.mas_equalTo(16);
    });
    CJPayMasMaker(self.sepView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self.applyInfoTitle.mas_bottom).offset(13);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    CJPayMasMaker(self.tipsStackView, {
        make.top.equalTo(self.sepView.mas_bottom).offset(14);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.bottom.lessThanOrEqualTo(self.protocolLabel.mas_top).offset(-13);
    });
    CJPayMasMaker(self.protocolLabel, {
        make.left.equalTo(self).offset(16);
        make.bottom.equalTo(self.authButton.mas_top).offset(-13);
        make.right.equalTo(self).offset(-16);
    });
    CJPayMasMaker(self.authButton, {
        make.left.right.equalTo(self.protocolLabel);
        make.bottom.equalTo(self.notMeButton.mas_top).offset(-13);
        make.height.mas_equalTo(48);
    });
    CJPayMasMaker(self.notMeButton, {
        make.left.right.equalTo(self.authButton);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.mas_bottom).offset(CJ_IPhoneX ? -CJ_TabBarSafeBottomMargin-20 : -20);
    });
}

#pragma mark - Getter
- (UIImageView*)closeImageView
{
    if(!_closeImageView){
        _closeImageView = [UIImageView new];
        [_closeImageView cj_setImage:@"cj_close_icon"];
        _closeImageView.userInteractionEnabled = YES;
        [_closeImageView cj_viewAddTarget:self
                                   action:@selector(p_tapCloseImageView)
                         forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeImageView;
}

- (UIImageView*)iconImageView
{
    if(!_iconImageView){
        _iconImageView = [UIImageView new];
        [_iconImageView cj_setImage:@"cj_auth_icon"];
        [_iconImageView cj_showCornerRadius:8];
    }
    return _iconImageView;
}

- (UILabel*)titleLabel
{
    if(!_titleLabel){
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:16];
        _titleLabel.textColor = [UIColor cj_161823ff];
    }
    return _titleLabel;
}

- (UILabel*)applyInfoTitle
{
    if(!_applyInfoTitle){
        _applyInfoTitle = [UILabel new];
        _applyInfoTitle.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _applyInfoTitle.textColor = [UIColor cj_colorWithHexString:@"999999"];
    }
    return _applyInfoTitle;
}

- (UIView*)sepView{
    if(!_sepView){
        _sepView = [UIView new];
        _sepView.backgroundColor = [UIColor cj_colorWithHexString:@"e8e8e8"];
    }
    return _sepView;
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

- (CJPayTouchLabel *)protocolLabel
{
    if (!_protocolLabel) {
        _protocolLabel = [CJPayTouchLabel new];
        _protocolLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _protocolLabel.numberOfLines = 0;
    }
    return _protocolLabel;
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
        }
        else if (theme != nil){
            [_authButton cj_setBtnTitleColor:[theme fontColor]];
            [_authButton cj_setBtnBGColor:[theme bgColor]];
            [_authButton cj_showCornerRadius:[theme confirmButtonShape]];
        } else {
            [_authButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
            [_authButton cj_setBtnTitleColor:UIColor.whiteColor];
            [_authButton cj_showCornerRadius:5];
        }
        
        
        [_authButton cj_setBtnTitle:CJPayLocalizedStr(@"同意协议并继续")];
        [_authButton addTarget:self action:@selector(p_authButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _authButton.titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:17];
        _authButton.cjEventInterval = 1;
    }
    return _authButton;
}

- (CJPayButton *)notMeButton
{
    if (!_notMeButton) {
        _notMeButton = [CJPayButton new];
        [_notMeButton cj_setBtnTitle:CJPayLocalizedStr(@"非本人信息")];
        [_notMeButton cj_setBtnTitleColor:[UIColor cj_222222ff]];
        [_notMeButton addTarget:self action:@selector(p_notMeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _notMeButton.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:14];
        _notMeButton.cjEventInterval = 1;
    }
    return _notMeButton;
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
