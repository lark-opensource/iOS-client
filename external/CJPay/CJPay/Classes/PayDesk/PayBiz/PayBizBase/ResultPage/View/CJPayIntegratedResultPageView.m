//
//  CJPayIntegratedResultPageView.m
//  AlipaySDK-AlipaySDKBundle
//
//  Created by chenbocheng on 2022/7/23.
//

#import "CJPayIntegratedResultPageView.h"
#import "CJPayOrderResultResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayTradeInfo.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayButton.h"

@interface CJPayIntegratedResultPageView ()

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayButton *backToMerchantButton;
@property (nonatomic, strong) UILabel *discountLabel; // 优惠信息

@property (nonatomic, strong) CJPayOrderResultResponse *cjResultResponse; //非抖音支付（微信、支付宝）

@end

@implementation CJPayIntegratedResultPageView

- (instancetype)initWithCJResponse:(CJPayOrderResultResponse *)resultResponse {
    self = [super init];
    if (self) {
        _cjResultResponse = resultResponse;
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private method

- (void)p_setupUI {
    [self p_setDetailUIAndText];
    [self addSubview:self.safeGuardTipView];
    
    CJPayMasMaker(self.safeGuardTipView, {
        make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
        make.height.mas_equalTo(18);
        make.centerX.width.equalTo(self);
    });
}

- (void)p_setDetailUIAndText {
    if (self.cjResultResponse && self.cjResultResponse.tradeInfo.tradeStatus != CJPayOrderStatusSuccess) {
        return;
    }
    NSString *payTypeDesc = [self.cjResultResponse.tradeInfo.bdpayResultResponse payTypeDescText];
    NSString *discountDesc = [self.cjResultResponse.tradeInfo.bdpayResultResponse halfScreenText];
    
    if (discountDesc.length > 0 || payTypeDesc.length > 0) {
        [self addSubview:self.discountLabel];
        CJPayMasMaker(self.discountLabel, {
            make.top.mas_equalTo(self).offset(5);
            make.left.mas_equalTo(self).offset(40);
            make.right.mas_equalTo(self).offset(-40);
        });
        
        [self p_updateDiscountText:CJString(discountDesc) payTypeDescText:CJString(payTypeDesc)];
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

- (void)p_showBackToMerchantBtn {
    [self addSubview:self.backToMerchantButton];
    
    CJPayMasMaker(self.backToMerchantButton, {
        make.bottom.mas_equalTo(self.safeGuardTipView.mas_top).offset(-30);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(165);
        make.height.mas_equalTo(44);
    });
}

- (void)p_tapBtmButton:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stateButtonClick:)]) {
        [self.delegate stateButtonClick:CJString(button.titleLabel.text)];
    }
}

#pragma mark - lazy views

- (void)setResultPageType:(CJPayIntegratedResultPageType)resultPageType {
    _resultPageType = resultPageType;
    
    if (resultPageType & CJPayIntegratedResultPageTypeOuterPay) {
        [self p_showBackToMerchantBtn];
    }
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
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

@end
