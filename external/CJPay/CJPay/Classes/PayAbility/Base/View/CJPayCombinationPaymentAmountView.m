//
//  CJPayCombinationPaymentAmountView.m
//  Pods
//
//  Created by xiuyuanLee on 2021/4/12.
//

#import "CJPayCombinationPaymentAmountView.h"

#import "CJPayHomePageAmountView.h"
#import "CJPayCombinePaymentAmountModel.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayThemeStyleManager.h"

@interface CJPayCombinationPaymentAmountView ()

#pragma mark - views
@property (nonatomic, strong) CJPayHomePageAmountView *amountView;
@property (nonatomic, strong) UILabel *cashPaymentLabel;
@property (nonatomic, strong) UILabel *cashAmountLabel;
@property (nonatomic, strong) UILabel *bankCardPaymentLabel;
@property (nonatomic, strong) UILabel *bankCardAmountLabel;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, strong) CJPayNotSufficientFundsView *notSufficientFundsView;
@property (nonatomic, strong) UILabel *cardInfoLabel;

#pragma mark -flag
@property (nonatomic, assign, readwrite) BOOL showNotSufficient;
@property (nonatomic, assign) CJPayChannelType type;

@end

@implementation CJPayCombinationPaymentAmountView

- (instancetype)initWithType:(CJPayChannelType)type
{
    self = [super init];
    if (self) {
        self.type = type;
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private method
- (void)p_setupUI {
    [self addSubview:self.amountView];
    [self addSubview:self.cashPaymentLabel];
    [self addSubview:self.cashAmountLabel];
    [self addSubview:self.bankCardPaymentLabel];
    [self addSubview:self.bankCardAmountLabel];
    [self addSubview:self.sepLine];
    [self addSubview:self.notSufficientFundsView];
    [self addSubview:self.cardInfoLabel];
    
    CJPayMasMaker(self.amountView, {
        make.top.equalTo(self);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self);
        make.right.lessThanOrEqualTo(self);
    })
    CJPayMasMaker(self.cashPaymentLabel, {
        make.top.equalTo(self.amountView.mas_bottom).offset(16);
        make.left.equalTo(self).offset(16);
        make.right.lessThanOrEqualTo(self.cashAmountLabel.mas_left);
    })
    CJPayMasMaker(self.cashAmountLabel, {
        make.centerY.equalTo(self.cashPaymentLabel);
        make.left.greaterThanOrEqualTo(self.cashPaymentLabel.mas_right);
        make.right.equalTo(self).offset(-16);
    })
    CJPayMasMaker(self.bankCardPaymentLabel, {
        make.top.equalTo(self.cashPaymentLabel.mas_bottom).offset(6);
        make.left.equalTo(self.cashPaymentLabel);
        make.right.lessThanOrEqualTo(self.bankCardAmountLabel.mas_left);
    })
    CJPayMasMaker(self.bankCardAmountLabel, {
        make.centerY.equalTo(self.bankCardPaymentLabel);
        make.left.greaterThanOrEqualTo(self.bankCardPaymentLabel.mas_right);
        make.right.equalTo(self.cashAmountLabel);
    })
    CJPayMasMaker(self.sepLine, {
        make.top.equalTo(self.bankCardPaymentLabel.mas_bottom).offset(16);
        make.left.equalTo(self.mas_left).offset(16);
        make.right.equalTo(self.mas_right).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    })
    CJPayMasMaker(self.notSufficientFundsView, {
        make.top.equalTo(self.sepLine.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self);
    })
    CJPayMasMaker(self.cardInfoLabel, {
        make.top.equalTo(self.sepLine).offset(12);
        make.left.equalTo(self).offset(16);
        make.right.lessThanOrEqualTo(self);
        make.bottom.equalTo(self).offset(-12);
    })
}

#pragma  mark - public method
- (void)updateStyleIfShowNotSufficient:(BOOL)showNotSufficient {
    self.showNotSufficient = showNotSufficient;
    self.sepLine.hidden = showNotSufficient;
    self.cardInfoLabel.hidden = showNotSufficient;
    if (showNotSufficient) {
        [self.notSufficientFundsView updateTitle:CJPayLocalizedStr(@"银行卡可用余额不足，请选择其他银行卡")];
    }
    self.notSufficientFundsView.hidden = !showNotSufficient;
}

- (void)updateAmount:(CJPayCombinePaymentAmountModel *)amountModel {
    self.cashAmountLabel.text = [NSString stringWithFormat:@"¥%@", amountModel.cashAmount];
    self.bankCardAmountLabel.text = [NSString stringWithFormat:@"¥%@", amountModel.bankCardAmount];
    [self.amountView updateWithTotalAmount:CJString(amountModel.totalAmount) withDetailInfo:CJString(amountModel.detailInfo)];
}

#pragma mark - lazy views
- (CJPayHomePageAmountView *)amountView {
    if (!_amountView) {
        _amountView = [CJPayHomePageAmountView new];
    }
    return _amountView;
}

- (UILabel *)cashPaymentLabel {
    if (!_cashPaymentLabel) {
        _cashPaymentLabel = [UILabel new];
        _cashPaymentLabel.font = [UIFont cj_fontOfSize:13];
        if (self.type == BDPayChannelTypeBalance) {
            _cashPaymentLabel.text = CJPayLocalizedStr(@"零钱支付");
        } else if (self.type == BDPayChannelTypeIncomePay) {
            _cashPaymentLabel.text = CJPayLocalizedStr(@"钱包收入支付");
        }

        _cashPaymentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _cashPaymentLabel;
}

- (UILabel *)cashAmountLabel {
    if (!_cashAmountLabel) {
        _cashAmountLabel = [UILabel new];
        _cashAmountLabel.font = [UIFont cj_fontOfSize:13];
        _cashAmountLabel.textColor = [UIColor cj_161823ff];
    }
    return _cashAmountLabel;
}

- (UILabel *)bankCardPaymentLabel {
    if (!_bankCardPaymentLabel) {
        _bankCardPaymentLabel = [UILabel new];
        _bankCardPaymentLabel.font = [UIFont cj_fontOfSize:13];
        _bankCardPaymentLabel.text = CJPayLocalizedStr(@"银行卡支付");
        _bankCardPaymentLabel.textColor = [UIColor cj_colorWithHexString:@"#ff6f28"];
    }
    return _bankCardPaymentLabel;
}

- (UILabel *)bankCardAmountLabel {
    if (!_bankCardAmountLabel) {
        _bankCardAmountLabel = [UILabel new];
        _bankCardAmountLabel.font = [UIFont cj_fontOfSize:13];
        _bankCardAmountLabel.textColor = [UIColor cj_colorWithHexString:@"#FF7A38"];
    }
    return _bankCardAmountLabel;
}

- (UIView *)sepLine {
    if (!_sepLine) {
        _sepLine = [UIView new];
        _sepLine.backgroundColor = [UIColor cj_161823WithAlpha:0.12];
    }
    return _sepLine;
}

- (CJPayNotSufficientFundsView *)notSufficientFundsView {
    if (!_notSufficientFundsView) {
        _notSufficientFundsView = [CJPayNotSufficientFundsView new];
    }
    return _notSufficientFundsView;
}

- (UILabel *)cardInfoLabel {
    if (!_cardInfoLabel) {
        _cardInfoLabel = [UILabel new];
        _cardInfoLabel.font = [UIFont cj_fontOfSize:13];
        _cardInfoLabel.textColor = [UIColor cj_161823ff];
        _cardInfoLabel.text = CJPayLocalizedStr(@"选择支付的银行卡");
    }
    return _cardInfoLabel;
}

@end
