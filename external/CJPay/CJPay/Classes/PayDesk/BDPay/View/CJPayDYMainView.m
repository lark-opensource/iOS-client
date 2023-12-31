//
//  CJPayDYMainView.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import "CJPayDYMainView.h"

#import "CJPayBDPayMainMessageView.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayCurrentTheme.h"
#import "CJPayBindCardManager.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayChannelBizModel.h"
#import "CJPayStyleButton.h"
#import "CJPayDeskConfig.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayLineUtil.h"

@interface CJPayDYMainView()

@property (nonatomic, strong) UILabel *paySourceLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *tradeAmountLabel;
@property (nonatomic, strong) CJPayBDPayMainMessageView *payTypeMessageView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

// 组合支付信息
@property (nonatomic, strong) UILabel *balanceLabel;
@property (nonatomic, strong) UILabel *balancePayTextLabel;
@property (nonatomic, strong) UILabel *balanceDetailLabel;
@property (nonatomic, strong) UILabel *combinedBankLabel;
@property (nonatomic, strong) UIImageView *combinedBankArrowImageView;
@property (nonatomic, strong) UILabel *combinedBankPayTextLabel;
@property (nonatomic, strong) UILabel *combinedBankDetailLabel;
@property (nonatomic, assign) BOOL isFacePay;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;

@end

@implementation CJPayDYMainView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupViews];
    }
    return self;
}

- (void)updateWithResponse:(CJPayBDCreateOrderResponse *)orderResponse {
    self.response = orderResponse;
    [self p_hiddenCombinedViews:YES];
    [self p_updateTradeLabel];
    [self p_updateDetailView];
}

- (void)updateCombinedPayInfo:(CJPayDefaultChannelShowConfig *)bizModel bankInfo:(CJPayDefaultChannelShowConfig *)bankModel {
    if (bizModel.type == BDPayChannelTypeBalance && bizModel.showCombinePay) {
        [self p_hiddenCombinedViews:NO];
        self.balanceDetailLabel.text = CJString(bizModel.payAmount);
        self.combinedBankDetailLabel.text = CJString(bizModel.primaryCombinePayAmount);
        if (bankModel.type == BDPayChannelTypeBankCard) {
            self.combinedBankLabel.text = [NSString stringWithFormat:@"%@(%@)",bankModel.title, bankModel.cardTailNumStr];
        } else {
            self.combinedBankLabel.text = bankModel.title;
        }
    } else {
        [self p_hiddenCombinedViews:YES];
    }
}

- (void)setFacePay:(BOOL)isFacePay {
    if (isFacePay) {
        [self.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"面容支付")];
    } else {
        [self.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
    }
    self.isFacePay = isFacePay;
}

- (void)p_updateTradeLabel {
    NSString *amountStr = [NSString stringWithFormat:@"%.2f", self.response.tradeInfo.tradeAmount / (double)100];
    self.tradeAmountLabel.text = amountStr;
}

- (void)p_updateDetailView {
    self.paySourceLabel.text = CJString(self.response.merchant.merchantShortName);

    CJPayChannelType type = [CJPayBDTypeInfo getChannelTypeBy:self.response.payTypeInfo.defaultPayChannel];
       switch (type) {
           case BDPayChannelTypeBalance: {
               [self p_updateDetailViewForBalance:self.response];
               break;
           }
           case BDPayChannelTypeBankCard: {
               [self p_updateDetailViewForBankCard:self.response];
               break;
           }
           default:
               CJPayLogInfo(@"接口错误");
               self.payTypeMessageView.enable = YES;
               [self.payTypeMessageView updateDescLabelText:CJPayLocalizedStr(@"添加新卡支付")];
               break;
       };
}

- (void)p_updateDetailViewForBalance:(CJPayBDCreateOrderResponse *)response {
    CJPayDefaultChannelShowConfig *showCardConfig = [self.response.payTypeInfo.balance buildShowConfig].firstObject;
    CJPayChannelBizModel *bizModel = [showCardConfig toBizModel];
    [self.payTypeMessageView updateDescLabelText:bizModel.title];
    [self.payTypeMessageView updateWithIconUrl:bizModel.iconUrl];
    [self.payTypeMessageView updateSubDescLabelText:bizModel.reasonStr];
    self.payTypeMessageView.enable = [showCardConfig enable];
    [self.confirmButton cj_setBtnTitle:self.response.deskConfig.confirmBtnDesc ?: CJPayLocalizedStr(@"确认支付")];
    if (self.isFacePay) {
        [self setFacePay:YES];
    }
    self.confirmButton.disableHightlightState = NO;
    self.confirmButton.enabled = [showCardConfig enable];
}

- (void)p_updateDetailViewForBankCard:(CJPayBDCreateOrderResponse *)response {
    CJPayDefaultChannelShowConfig *cardModel = [self p_getFirstAvailableCard];
    if (cardModel) { // 有可用卡
        [self p_updateDetailViewForOwnCard:response cardModel:cardModel];
    } else {
        [self p_updateDetailViewForNoCard];
    }
}

- (nullable CJPayDefaultChannelShowConfig *)p_getFirstAvailableCard {
    __block CJPayDefaultChannelShowConfig *firstAvailableCard = nil;
    [self.response.payTypeInfo.quickPay.cards enumerateObjectsUsingBlock:^(CJPayQuickPayCardModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayDefaultChannelShowConfig *showConfig = [obj buildShowConfig].firstObject;
        if (showConfig && showConfig.enable) {
            firstAvailableCard = showConfig;
            *stop = YES;
        }
    }];
    return firstAvailableCard;
}

- (void)p_updateDetailViewForOwnCard:(CJPayBDCreateOrderResponse *)response cardModel:(CJPayDefaultChannelShowConfig *)cardModel {
    CJPayChannelBizModel *bizModel = [cardModel toBizModel];
    NSString *title = [NSString stringWithFormat:@"%@(%@)",bizModel.title, bizModel.channelConfig.cardTailNumStr];
    self.payTypeMessageView.enable = [cardModel enable];
    [self.payTypeMessageView updateDescLabelText:title];
    [self.payTypeMessageView updateWithIconUrl:cardModel.iconUrl];
    [self.payTypeMessageView updateSubDescLabelText:cardModel.reason];
    if ([cardModel enable]) {
        [self.confirmButton cj_setBtnTitle:self.response.deskConfig.confirmBtnDesc ?: CJPayLocalizedStr(@"确认支付")];
        if (self.isFacePay) {
            [self setFacePay:YES];
        }
        self.confirmButton.disableHightlightState = NO;
    } else {
        [self.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"添加新卡支付")];
         self.confirmButton.disableHightlightState = YES;
    }
    self.confirmButton.enabled = YES;
}

- (void)p_updateDetailViewForNoCard {
    self.payTypeMessageView.enable = YES;
    [self.payTypeMessageView updateDescLabelText:CJPayLocalizedStr(@"添加新卡支付")];
    [self.payTypeMessageView updateWithIconUrl:@""];
    [self.payTypeMessageView updateSubDescLabelText:@""];
    [self.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"添加新卡支付")];
    self.confirmButton.disableHightlightState = YES;
    self.confirmButton.enabled = YES;
}

- (void)p_setupViews{
    [self addSubview:self.paySourceLabel];
    [self addSubview:self.tradeAmountLabel];
    [self addSubview:self.unitLabel];
    [self addSubview:self.payTypeMessageView];
    [self addSubview:self.confirmButton];
    [self addSubview:self.safeGuardTipView];
    
    [CJPayLineUtil addTopLineToView:self.payTypeMessageView marginLeft:16 marginRight:16 marginTop:0];

    CJPayMasMaker(self.paySourceLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(8);
    });
    
    CJPayMasMaker(self.tradeAmountLabel, {
        make.top.equalTo(self).offset(30);
        make.centerX.mas_equalTo(self.mas_centerX).offset(10);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.right.mas_equalTo(self.tradeAmountLabel.mas_left);
        make.bottom.mas_equalTo(self.tradeAmountLabel.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(30, 32));
    });
    
    CJPayMasMaker(self.payTypeMessageView, {
        make.top.equalTo(self.tradeAmountLabel.mas_bottom).offset(48);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(56);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-20);
        } else {
            make.bottom.equalTo(self).offset(CJ_IPhoneX ? -50 : -20);
        }
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        self.safeGuardTipView.hidden = NO;
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self);
            make.height.mas_equalTo(18);
        });
    }
    
    [self p_setupCombinePayUI];
}

- (void)p_setupCombinePayUI {
    [self addSubview:self.balanceLabel];
    [self addSubview:self.balancePayTextLabel];
    [self addSubview:self.balanceDetailLabel];
    [self addSubview:self.combinedBankLabel];
    [self addSubview:self.combinedBankArrowImageView];
    [self addSubview:self.combinedBankPayTextLabel];
    [self addSubview:self.combinedBankDetailLabel];
    
    [self.combinedBankLabel cj_viewAddTarget:self
                    action:@selector(p_arrowImageViewTapped)
          forControlEvents:UIControlEventTouchUpInside];
    [self.combinedBankArrowImageView cj_viewAddTarget:self
                    action:@selector(p_arrowImageViewTapped)
          forControlEvents:UIControlEventTouchUpInside];
    
    CJPayMasMaker(self.balanceLabel, {
        make.top.equalTo(self.payTypeMessageView.mas_bottom).offset(12);
        make.left.equalTo(self).offset(16);
    });
    CJPayMasMaker(self.balanceDetailLabel, {
        make.right.equalTo(self).offset(-16);
        make.bottom.equalTo(self.balanceLabel);
    });
    CJPayMasMaker(self.balancePayTextLabel, {
        make.bottom.equalTo(self.balanceLabel);
        make.right.equalTo(self.balanceDetailLabel.mas_left).offset(-4);
    })
    
    CJPayMasMaker(self.combinedBankLabel, {
        make.top.equalTo(self.balanceLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(18);
        make.left.equalTo(self.balanceLabel);
    });
    CJPayMasMaker(self.combinedBankArrowImageView, {
        make.centerY.equalTo(self.combinedBankLabel);
        make.left.equalTo(self.combinedBankLabel.mas_right).offset(-5);
        make.width.height.mas_equalTo(20);
    });
    CJPayMasMaker(self.combinedBankDetailLabel, {
        make.right.equalTo(self.balanceDetailLabel);
        make.centerY.equalTo(self.combinedBankLabel);
    });
    CJPayMasMaker(self.combinedBankPayTextLabel, {
        make.centerY.equalTo(self.combinedBankLabel);
        make.right.equalTo(self.combinedBankDetailLabel.mas_left).offset(-4);
    });
}

- (void)p_hiddenCombinedViews:(BOOL)hidden {
    self.balanceLabel.hidden = hidden;
    self.balancePayTextLabel.hidden = hidden;
    self.balanceDetailLabel.hidden = hidden;
    self.combinedBankLabel.hidden = hidden;
    self.combinedBankArrowImageView.hidden = hidden;
    self.combinedBankPayTextLabel.hidden = hidden;
    self.combinedBankDetailLabel.hidden = hidden;
}

- (void)p_confirmButtonTapped {
    CJ_CALL_BLOCK(self.confirmBlock);
}

- (void)p_arrowImageViewTapped {
    CJ_CALL_BLOCK(self.combinedBankArrowBlock);
}

// MARK: - getter

- (UILabel *)paySourceLabel {
    if (!_paySourceLabel) {
        _paySourceLabel = [UILabel new];
        _paySourceLabel.font = [UIFont cj_fontOfSize:14];
        _paySourceLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _paySourceLabel;
}

- (UILabel *)unitLabel {
    if (!_unitLabel) {
        _unitLabel = [UILabel new];
        _unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:28];
        _unitLabel.textColor = UIColor.cj_222222ff;
        _unitLabel.textAlignment = NSTextAlignmentRight;
        _unitLabel.text = @"￥";
    }
    return _unitLabel;
}

- (UILabel *)tradeAmountLabel {
    if (!_tradeAmountLabel) {
        _tradeAmountLabel = [[UILabel alloc] init];
        _tradeAmountLabel.textAlignment = NSTextAlignmentLeft;
        _tradeAmountLabel.textColor = [UIColor cj_161823ff];
        _tradeAmountLabel.font = [UIFont cj_denoiseBoldFontOfSize:36];
    }
    return _tradeAmountLabel;
}

- (CJPayBDPayMainMessageView *)payTypeMessageView {
    if (!_payTypeMessageView) {
        _payTypeMessageView = [[CJPayBDPayMainMessageView alloc] init];
        [_payTypeMessageView updateTitleLabelText:CJPayLocalizedStr(@"付款方式")];
        _payTypeMessageView.userInteractionEnabled = YES;
        _payTypeMessageView.style = CJPayBDPayMainMessageViewStyleArrow;
    }
    return _payTypeMessageView;
}
// 组合支付
- (UILabel *)balanceLabel {
    if (!_balanceLabel) {
        _balanceLabel = [UILabel new];
        _balanceLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _balanceLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _balanceLabel.text = CJPayLocalizedStr(@"抖音零钱");
    }
    return _balanceLabel;
}

- (UILabel *)balancePayTextLabel {
    if (!_balancePayTextLabel) {
        _balancePayTextLabel = [UILabel new];
        _balancePayTextLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _balancePayTextLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _balancePayTextLabel.text = @"支付";
    }
    return _balancePayTextLabel;
}

- (UILabel *)balanceDetailLabel {
    if (!_balanceDetailLabel) {
        _balanceDetailLabel = [UILabel new];
        _balanceDetailLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _balanceDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _balanceDetailLabel;
}

- (UILabel *)combinedBankLabel {
    if (!_combinedBankLabel) {
        _combinedBankLabel = [UILabel new];
        _combinedBankLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combinedBankLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _combinedBankLabel;
}

- (UIImageView *)combinedBankArrowImageView {
    if (!_combinedBankArrowImageView) {
        _combinedBankArrowImageView = [[UIImageView alloc] init];
        [_combinedBankArrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _combinedBankArrowImageView;
}

- (UILabel *)combinedBankPayTextLabel {
    if (!_combinedBankPayTextLabel) {
        _combinedBankPayTextLabel = [UILabel new];
        _combinedBankPayTextLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combinedBankPayTextLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _combinedBankPayTextLabel.text = @"支付";
    }
    return _combinedBankPayTextLabel;
}

- (UILabel *)combinedBankDetailLabel {
    if (!_combinedBankDetailLabel) {
        _combinedBankDetailLabel = [UILabel new];
        _combinedBankDetailLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combinedBankDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
    }
    return _combinedBankDetailLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.cjEventInterval = 1;
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.layer.cornerRadius = 2;
        _confirmButton.clipsToBounds = YES;
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
        [_confirmButton addTarget:self action:@selector(p_confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

@end
