//
//  CJPayCombinePayDetailView.m
//  Pods
//
//  Created by youerwei on 2021/4/15.
//

#import "CJPayCombinePayDetailView.h"
#import "CJPayUIMacro.h"
#import "CJPayCombinePayFund.h"

@interface CJPayCombinePayDetailView ()

@end

@implementation CJPayCombinePayDetailView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.balanceDescLabel];
    [self addSubview:self.balanceAmountLabel];
    [self addSubview:self.bankDescLabel];
    [self addSubview:self.bankAmountLabel];
    
    CJPayMasMaker(self.balanceDescLabel, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self);
        make.height.mas_equalTo(16);
    });
    CJPayMasMaker(self.balanceAmountLabel, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.balanceDescLabel);
        make.height.mas_equalTo(16);
    });
    CJPayMasMaker(self.bankDescLabel, {
        make.left.equalTo(self.balanceDescLabel);
        make.top.equalTo(self.balanceDescLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(16);
    });
    CJPayMasMaker(self.bankAmountLabel, {
        make.right.equalTo(self.balanceAmountLabel);
        make.centerY.equalTo(self.bankDescLabel);
        make.height.mas_equalTo(16);
    });
}

- (void)upateDetailViewLayout {
    self.balanceDescLabel.font = [UIFont cj_fontOfSize:12];
    self.balanceAmountLabel.font = [UIFont cj_fontOfSize:12];
    self.bankDescLabel.font = [UIFont cj_fontOfSize:12];
    self.bankAmountLabel.font = [UIFont cj_fontOfSize:12];
    
    CJPayMasReMaker(self.bankDescLabel, {
        make.left.equalTo(self.balanceDescLabel);
        make.top.equalTo(self.balanceDescLabel.mas_bottom).offset(3);
        make.height.mas_equalTo(16);
    });
    
    [self setNeedsLayout];
}

- (void)updateBalanceMsgWithFund:(CJPayCombinePayFund *)fund {
    self.balanceDescLabel.text = fund.fundTypeDesc;
    self.balanceAmountLabel.text = fund.fundAmountDesc;
}

- (void)updateBankMsgWithFund:(CJPayCombinePayFund *)fund {
    self.bankDescLabel.text = fund.fundTypeDesc;
    self.bankAmountLabel.text = fund.fundAmountDesc;
}

- (UILabel *)balanceDescLabel {
    if (!_balanceDescLabel) {
        _balanceDescLabel = [UILabel new];
        _balanceDescLabel.font = [UIFont cj_fontOfSize:13];
        _balanceDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _balanceDescLabel;
}

- (UILabel *)balanceAmountLabel {
    if (!_balanceAmountLabel) {
        _balanceAmountLabel = [UILabel new];
        _balanceAmountLabel.font = [UIFont cj_fontOfSize:13];
        _balanceAmountLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _balanceAmountLabel.textAlignment = NSTextAlignmentRight;
    }
    return _balanceAmountLabel;
}

- (UILabel *)bankDescLabel {
    if (!_bankDescLabel) {
        _bankDescLabel = [UILabel new];
        _bankDescLabel.font = [UIFont cj_fontOfSize:13];
        _bankDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _bankDescLabel;
}

- (UILabel *)bankAmountLabel {
    if (!_bankAmountLabel) {
        _bankAmountLabel = [UILabel new];
        _bankAmountLabel.font = [UIFont cj_fontOfSize:13];
        _bankAmountLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _bankAmountLabel.textAlignment = NSTextAlignmentRight;
    }
    return _bankAmountLabel;
}
@end
