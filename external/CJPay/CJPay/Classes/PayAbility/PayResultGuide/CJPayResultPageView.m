//
//  CJPayResultPageView.m
//  Pods
//
//  Created by chenbocheng on 2022/4/20.
//

#import "CJPayResultPageView.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayCombinePayDetailView.h"
#import "CJPayResultDetailItemView.h"
#import "CJPayTradeQueryContentList.h"
#import "CJPayButton.h"
#import "CJPayFullResultCardView.h"
#import "CJPayResultPageInfoModel.h"
#import "CJPayBDCreateOrderResponse.h"

@interface CJPayResultPageView ()<CJPayLynxViewDelegate>

@property (nonatomic, strong) CJPayCombinePayDetailView *combinePayDetailView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayFullResultCardView *payBannerView;
@property (nonatomic, strong) CJPayButton *backToMerchantButton;
@property (nonatomic, strong) UILabel *detailDescLabel; // 支付结果信息详情
@property (nonatomic, strong) UILabel *discountLabel; // 优惠信息
@property (nonatomic, strong) UILabel *topLabel;//用于标记
@property (nonatomic, strong) UILabel *guideLabel;
@property (nonatomic, strong) UIView *borderView;

@property (nonatomic, strong) CJPayBDOrderResultResponse *resultResponse;   //抖音支付
@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;

@end

@implementation CJPayResultPageView

- (instancetype)initWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse {
    self = [super init];
    if (self) {
        _resultResponse = resultResponse;
        _createOrderResponse = createOrderResponse;
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public method

- (void)updateBannerContentWithModel:(CJPayDynamicComponents *)model benefitStr:(NSString*)benefitStr {
    CGRect frame = CGRectMake(0, 0, CJ_SCREEN_WIDTH, 200);
    NSDictionary *dic =
    @{
        @"result_page_info" : @{
            @"dynamic_components": @[[model toDictionary]],
            @"dynamic_data": CJString(benefitStr)
        },
        @"trade_info": @{
            @"trade_no" : CJString(self.createOrderResponse.intergratedTradeIdentify),
            @"amount" : @(self.resultResponse.tradeInfo.tradeAmount).stringValue,
            @"merchant_id": CJString(self.resultResponse.merchant.intergratedMerchantId),
            @"app_id" : CJString(self.resultResponse.merchant.jhAppId)
        }
    };
    NSString *str = [dic btd_jsonStringEncoded];
    self.payBannerView = [[CJPayFullResultCardView alloc] initWithFrame:frame scheme:model.schema initDataStr:str];
    self.payBannerView.delegate = self;
    [self.payBannerView reload];
}

- (void)hideSafeGuard {
    self.safeGuardTipView.showEnable = NO;
    self.safeGuardTipView.hidden = YES;
}

#pragma mark - private method

- (void)p_setDetailUIAndText {
    if (self.resultResponse && self.resultResponse.tradeInfo.tradeStatus != CJPayOrderStatusSuccess && self.resultPageType != CJPayResultPageTypeOuterPay) {
        return;
    }
    
    self.guideLabel.text = self.resultResponse.resultConfig.bottomGuideInfo.text;
    self.guideLabel.textColor = [UIColor cj_colorWithHexString:CJString(self.resultResponse.resultConfig.bottomGuideInfo.color)];
    self.borderView.hidden = ![self.resultResponse.resultConfig.bottomGuideInfo isShowText];
    
    NSString *payTypeDesc = [self.resultResponse payTypeDescText];
    NSString *discountDesc = [self.resultResponse halfScreenText];
    
    if (discountDesc.length > 0 || payTypeDesc.length > 0) {
        [self addSubview:self.discountLabel];
        CJPayMasMaker(self.discountLabel, {
            make.top.mas_equalTo(self);
            make.left.mas_equalTo(self).offset(40);
            make.right.mas_equalTo(self).offset(-40);
        });
        
        [self p_updateDiscountText:CJString(discountDesc) payTypeDescText:CJString(payTypeDesc)];
        self.topLabel = self.discountLabel;
        return;
    }
    if (Check_ValidString(self.resultResponse.tradeInfo.tradeDescMessage)) {
        [self addSubview:self.detailDescLabel];
        CJPayMasMaker(self.detailDescLabel, {
            if (self.resultResponse.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
                make.top.mas_equalTo(self).offset(9);
            } else {
                make.top.mas_equalTo(self).offset(160);
            }
            make.left.mas_equalTo(self).offset(40);
            make.right.mas_equalTo(self).offset(-40);
        });
        self.detailDescLabel.text = self.resultResponse.tradeInfo.tradeDescMessage;
        self.topLabel = self.detailDescLabel;
    }
}

- (void)p_updateDiscountText:(NSString *)discountText payTypeDescText:(NSString *)payTypeDescText {
    NSMutableAttributedString *attributeStr = [NSMutableAttributedString new];
    if (Check_ValidString(payTypeDescText)) {
        [attributeStr appendAttributedStringWith:CJConcatStr(payTypeDescText, @" ")
                                       textColor:[UIColor cj_161823WithAlpha:0.75]
                                            font:[UIFont cj_fontOfSize:13]];
    }
    [attributeStr appendAttributedStringWith:discountText
                                   textColor:[UIColor cj_colorWithHexRGBA:@"ff7a38ff"]
                                        font:[UIFont cj_fontOfSize:13]];
    self.discountLabel.attributedText = attributeStr;
}

- (void)p_setupUI {
    [self p_setDetailUIAndText];
    [self addSubview:self.safeGuardTipView];
    [self addSubview:self.borderView];
    [self addSubview:self.guideLabel];
    
    CJPayMasMaker(self.safeGuardTipView, {
        make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
        make.height.mas_equalTo(18);
        make.centerX.width.equalTo(self);
    });
    CJPayMasMaker(self.borderView, {
        make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-76);
        make.left.right.mas_equalTo(self).inset(16);
        make.height.mas_equalTo(35);
    });
    CJPayMasMaker(self.guideLabel, {
        make.left.right.top.bottom.equalTo(self.borderView);
    });
}

- (BOOL)p_isCombinePay {
    return [self.resultResponse.tradeInfo.payType isEqualToString:@"combinepay"];
}

- (void)p_showCombinePay {
    if (self.resultResponse.contentList.count > 0) {
        return;
    }
    [self addSubview:self.combinePayDetailView];
    
    CJPayMasMaker(self.combinePayDetailView, {
        make.left.right.equalTo(self);
        make.top.equalTo(self).offset(42);
        make.height.mas_equalTo(50);
    });
    
    [self p_updateCombinePayDetail:self.resultResponse.tradeInfo.combinePayFundList];
}

- (void)p_showSignDetail {
    UIView *lastView = self;
    for (CJPayTradeQueryContentList *contentItem in self.resultResponse.contentList) {
        CJPayResultDetailItemView *signDetailView = [CJPayResultDetailItemView new];
        [signDetailView updateWithTitle:CJString(contentItem.subTitle) detail:CJString(contentItem.subContent)];
        
        [self addSubview:signDetailView];
        CJPayMasMaker(signDetailView, {
            make.left.equalTo(lastView);
            make.right.equalTo(lastView);
            make.height.mas_equalTo(18);
            if (lastView == self) {
                make.top.equalTo(lastView).offset(42);
            } else {
                make.top.equalTo(lastView).offset(28);
            }
        });
        lastView = signDetailView;
    }
}

- (void)p_showPayBanner {
    [self addSubview:self.payBannerView];
    
    if (self.resultResponse.contentList.count > 0 || self.resultResponse.tradeInfo.combinePayFundList > 0) {
        CJPayMasMaker(self.payBannerView, {
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.height.mas_equalTo(94);
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-82);
        });
    } else {
        CJPayMasMaker(self.payBannerView, {
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.height.mas_equalTo(94);
            if (self.topLabel.text.length > 0) {
                make.top.equalTo(self).offset(42);
            } else {
                make.top.equalTo(self).offset(24);
            }
        });
    }
}

- (void)p_showBackToMerchantBtn {
    [self.backToMerchantButton cj_setBtnTitle:self.resultResponse.resultConfig.successBtnDesc ?: CJPayLocalizedStr(@"返回")];
    [self addSubview:self.backToMerchantButton];
    
    CJPayMasMaker(self.backToMerchantButton, {
        make.bottom.mas_equalTo(self.safeGuardTipView.mas_top).offset(-16);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(165);
        make.height.mas_equalTo(44);
    });
}

- (CJPayCommonProtocolModel *)p_buildCommonModelWithGuideModel:(CJPayBaseGuideInfoModel *)guideModel {
    CJPayCommonProtocolModel *model = [CJPayCommonProtocolModel new];
    model.title = guideModel.title;
    model.buttonText = guideModel.buttonText;
    model.guideDesc = Check_ValidString(guideModel.guideMessage) ? guideModel.guideMessage : @"同意并开通";
    model.agreements = guideModel.protocoList;
    model.groupNameDic = guideModel.protocolGroupNames;
    model.protocolFont = [UIFont cj_fontOfSize:11];
    model.protocolLineHeight = 16;
    
    return model;
}

- (void)p_updateCombinePayDetail:(NSArray <CJPayCombinePayFund> *)combinePayFundList {
    if (combinePayFundList.count < 2) {
        return;
    }
    [self.combinePayDetailView updateBalanceMsgWithFund:combinePayFundList[0]];
    [self.combinePayDetailView updateBankMsgWithFund:combinePayFundList[1]];
}

- (void)p_tapBtmButton:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stateButtonClick:)]) {
        [self.delegate stateButtonClick:CJString(button.titleLabel.text)];
    }
}

#pragma mark - lazy views

- (void)setResultPageType:(CJPayResultPageType)type {
    _resultPageType = type;
    if (![self.resultResponse.resultConfig.successBtnPosition isEqualToString:@"top"]) {
        [self p_showBackToMerchantBtn];
    }
    [self p_setDetailUIAndText];
    
    if (type & CJPayResultPageTypeCombinePay) {
        [self p_showCombinePay];
    }
    
    if (type & CJPayResultPageTypeSignDYPay) {
        [self p_showSignDetail];
    }
    
    if (type & CJPayResultPageTypeBanner) {
        [self p_showPayBanner];
    }
}

#pragma mark CJPayLynxViewDelegate

- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if (![lynxView isKindOfClass:CJPayFullResultCardView.class]) {
        return;
    }
    CJPayFullResultCardView *cardView = (CJPayFullResultCardView *)lynxView;
    if ([event isEqualToString:@"cj_component_action"]) {
        cardView.isLynxViewButtonClickStr = @"1";
    }
    
    if ([event isEqualToString:@"cj_set_component_height"]) {
        CGFloat height = [[data cj_stringValueForKey:@"height"] floatValue];
        CGSize size = CGSizeMake(0, height);
        [cardView resetLynxCardSize:size];
    }
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (CJPayCombinePayDetailView *)combinePayDetailView {
    if (!_combinePayDetailView) {
        _combinePayDetailView = [CJPayCombinePayDetailView new];
    }
    return _combinePayDetailView;
}

- (CJPayButton *)backToMerchantButton {
    if (!_backToMerchantButton) {
        _backToMerchantButton = [CJPayButton new];
        [_backToMerchantButton setTitle:CJPayLocalizedStr(@"返回") forState:UIControlStateNormal];
        [_backToMerchantButton setTitleColor:[UIColor cj_colorWithHexString:@"#161823" alpha:1.0] forState:UIControlStateNormal];
        _backToMerchantButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _backToMerchantButton.backgroundColor = [UIColor cj_161823WithAlpha:0.05];
        _backToMerchantButton.layer.cornerRadius = 4;
        [_backToMerchantButton addTarget:self action:@selector(p_tapBtmButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backToMerchantButton;
}

- (UILabel *)detailDescLabel
{
    if (!_detailDescLabel) {
        _detailDescLabel = [UILabel new];
        _detailDescLabel.textAlignment = NSTextAlignmentCenter;
        _detailDescLabel.font = [UIFont cj_fontOfSize:14];
        _detailDescLabel.textColor = [UIColor cj_999999ff];
        _detailDescLabel.numberOfLines = 0;
    }
    return _detailDescLabel;
}

- (UILabel *)discountLabel
{
   if (!_discountLabel) {
       _discountLabel = [UILabel new];
       _discountLabel.textAlignment = NSTextAlignmentCenter;
       _discountLabel.font = [UIFont cj_fontOfSize:13];
       _discountLabel.textColor = [UIColor cj_colorWithHexRGBA:@"ff7a38ff"];
       _discountLabel.numberOfLines = 0;
    }
    return _discountLabel;
}

- (UIView *)borderView {
    if (!_borderView) {
        _borderView = [[UIView alloc] init];
        _borderView.layer.borderWidth = 0.5;
        _borderView.layer.cornerRadius = 8;
        _borderView.layer.borderColor = [UIColor cj_colorWithHexString:@"000000" alpha:0.08].CGColor;
    }
    return _borderView;
}

- (UILabel *)guideLabel {
    if (!_guideLabel) {
        _guideLabel = [[UILabel alloc] init];
        _guideLabel.font = [UIFont cj_fontOfSize:11];
        _guideLabel.textColor = [UIColor cj_colorWithHexString:@"#161823"];
        _guideLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _guideLabel;
}


@end
