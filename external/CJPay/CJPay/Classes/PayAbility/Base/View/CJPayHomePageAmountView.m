//
//  CJPayHomePageAmountView.m
//  Pods
//
//  Created by xiuyuanLee on 2021/4/13.
//

#import "CJPayHomePageAmountView.h"
#import "CJPayUIMacro.h"

@interface CJPayHomePageAmountView ()

@property (nonatomic, strong) UILabel *rmbUnitLabel;
@property (nonatomic, strong) UILabel *totalAmountLabel;
@property (nonatomic, strong) UILabel *amountDetailLabel;

@end

@implementation CJPayHomePageAmountView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateTextColor:(UIColor *)color {
    self.rmbUnitLabel.textColor = color;
    self.totalAmountLabel.textColor = color;
}

- (void)updateWithTotalAmount:(NSString *)totalAmount withDetailInfo:(NSString *)detailInfo {
    self.totalAmountLabel.text = totalAmount;
    self.amountDetailLabel.text = detailInfo;
}

#pragma mark - private method
- (void)p_setupUI {
    UIView *amountBGView = [UIView new];
    [amountBGView addSubview:self.rmbUnitLabel];
    [amountBGView addSubview:self.totalAmountLabel];
    
    [self addSubview:amountBGView];
    [self addSubview:self.amountDetailLabel];

    CJPayMasMaker(self.rmbUnitLabel, {
        make.left.equalTo(amountBGView);
        make.right.equalTo(self.totalAmountLabel.mas_left).offset(-2);
        make.height.mas_equalTo(34);
        make.bottom.equalTo(self.totalAmountLabel).offset(-2);
    })
    CJPayMasMaker(self.totalAmountLabel, {
        make.top.bottom.equalTo(amountBGView);
        make.right.equalTo(amountBGView);
        make.height.mas_equalTo(43);
    })
    CJPayMasMaker(amountBGView, {
        make.top.equalTo(self);
        make.left.greaterThanOrEqualTo(self);
        make.right.lessThanOrEqualTo(self);
        make.centerX.equalTo(self).offset(-2);
    })
    
    CJPayMasMaker(self.amountDetailLabel, {
        make.top.equalTo(amountBGView.mas_bottom);
        make.centerX.equalTo(self);
        make.bottom.equalTo(self);
    })
}

#pragma mark - lazy views
- (UILabel *)rmbUnitLabel {
    if (!_rmbUnitLabel) {
        _rmbUnitLabel = [UILabel new];
        _rmbUnitLabel.font = [UIFont cj_denoiseBoldFontOfSize:28];
        _rmbUnitLabel.text = @"¥";
        _rmbUnitLabel.textColor = [UIColor cj_161823ff];
    }
    return _rmbUnitLabel;
}

- (UILabel *)totalAmountLabel {
    if (!_totalAmountLabel) {
        _totalAmountLabel = [UILabel new];
        _totalAmountLabel.font = [UIFont cj_denoiseBoldFontOfSize:36];
        _totalAmountLabel.textColor = [UIColor cj_161823ff];
    }
    return _totalAmountLabel;
}

- (UILabel *)amountDetailLabel {
    if (!_amountDetailLabel) {
        _amountDetailLabel = [UILabel new];
        _amountDetailLabel.font = [UIFont cj_fontOfSize:12];
        _amountDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _amountDetailLabel;
}

@end
