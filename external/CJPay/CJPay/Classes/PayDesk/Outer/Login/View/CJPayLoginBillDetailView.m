//
//  CJPayLoginBillDetailView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/3.
//

#import "CJPayLoginBillDetailView.h"

#import "CJPayUIMacro.h"

@interface CJPayLoginBillDetailView ()

@property (nonatomic, strong) UILabel *currencyLabel; // 币种
@property (nonatomic, strong) UILabel *tradeAmountLabel; //金额

@property (nonatomic, strong) UILabel *merchantLabel; // 收款方

@end

@implementation CJPayLoginBillDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        [self p_setupConstraints];
    }
    return self;
}

#pragma mark - public func

- (void)updateLoginBillDetail:(NSString *)tradeAmount merchantName:(NSString *)merchantName {
    self.tradeAmountLabel.text = tradeAmount;
    self.merchantLabel.text = [NSString stringWithFormat:@"收款方·%@",merchantName];
}


#pragma mark - private func

- (void)p_setupUI {
    [self addSubview:self.currencyLabel];
    [self addSubview:self.tradeAmountLabel];
    [self addSubview:self.merchantLabel];
}

- (void)p_setupConstraints {
    CJPayMasMaker(self.tradeAmountLabel, {
        make.top.mas_equalTo(self).mas_offset(22);
        make.centerX.mas_equalTo(self);
        make.height.mas_equalTo(80);
    });
    
    CJPayMasMaker(self.currencyLabel, {
        make.right.mas_equalTo(self.tradeAmountLabel.mas_left);
        make.bottom.mas_equalTo(self.tradeAmountLabel);
        make.height.mas_equalTo(54);
        make.baseline.mas_equalTo(self.tradeAmountLabel);
    });
    
    CJPayMasMaker(self.merchantLabel, {
        make.bottom.mas_equalTo(self).mas_offset(-24);
        make.centerX.mas_equalTo(self);
    });
}

#pragma mark - lazy load

- (UILabel *)currencyLabel {
    if (!_currencyLabel) {
        _currencyLabel = [UILabel new];
        _currencyLabel.font = [UIFont cj_fontOfSize:32];
        _currencyLabel.textColor = [UIColor cj_161823ff];
        _currencyLabel.text = @"¥";
    }
    return _currencyLabel;
}

- (UILabel *)tradeAmountLabel {
    if (!_tradeAmountLabel) {
        _tradeAmountLabel = [UILabel new];
        _tradeAmountLabel.font = [UIFont cj_fontOfSize:62];
        _tradeAmountLabel.textColor = [UIColor cj_161823ff];
    }
    return _tradeAmountLabel;
}

- (UILabel *)merchantLabel {
    if (!_merchantLabel) {
        _merchantLabel = [UILabel new];
        _merchantLabel.font = [UIFont cj_fontOfSize:14];
        _merchantLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
    }
    return _merchantLabel;
}

@end
