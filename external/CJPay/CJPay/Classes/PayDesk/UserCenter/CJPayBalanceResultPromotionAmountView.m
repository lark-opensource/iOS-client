//
//  CJPayBalanceResultPromotionAmountView.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import "CJPayBalanceResultPromotionAmountView.h"
#import "CJPayBalanceResultPromotionModel.h"
#import "CJPayUIMacro.h"

@interface CJPayBalanceResultPromotionAmountView ()

@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *amountDescLabel;

@end

@implementation CJPayBalanceResultPromotionAmountView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    UIView *containerView = [UIView new];
    [self addSubview:containerView];
    CJPayMasMaker(containerView, {
        make.center.equalTo(self);
    });
    [containerView addSubview:self.amountLabel];
    [containerView addSubview:self.amountDescLabel];
    CJPayMasMaker(self.amountLabel, {
        make.centerX.equalTo(containerView);
        make.top.left.right.equalTo(containerView);
    });
    CJPayMasMaker(self.amountDescLabel, {
        make.top.equalTo(self.amountLabel.mas_bottom).offset(-2);
        make.centerX.equalTo(self.amountLabel);
        make.bottom.equalTo(containerView);
    });
}

- (void)updateWithPromotionModel:(CJPayBalanceResultPromotionModel *)promotionModel {
    NSDictionary *amountAttribute = @{
        NSForegroundColorAttributeName: UIColor.cj_fe2c55ff,
        NSFontAttributeName: [UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:30]
    };
    NSDictionary *cnyAttribute = @{
        NSForegroundColorAttributeName: UIColor.cj_fe2c55ff,
        NSFontAttributeName: [UIFont cj_fontWithoutFontScaleOfSize:11]
    };
    NSMutableAttributedString *amountAttributedString = [[NSMutableAttributedString alloc] initWithString:CJString(promotionModel.leftDiscountAmount) attributes:amountAttribute];
    NSAttributedString *cnyAttributeString = [[NSAttributedString alloc] initWithString:@"元" attributes:cnyAttribute];
    [amountAttributedString appendAttributedString:cnyAttributeString];
    self.amountLabel.attributedText = amountAttributedString;
    self.amountDescLabel.text = CJString(promotionModel.leftDiscountDesc);
}

- (UILabel *)amountLabel {
    if (!_amountLabel) {
        _amountLabel = [UILabel new];
        _amountLabel.numberOfLines = 1;
    }
    return _amountLabel;
}

- (UILabel *)amountDescLabel {
    if (!_amountDescLabel) {
        _amountDescLabel = [UILabel new];
        _amountDescLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:11];
        _amountDescLabel.textColor = UIColor.cj_fe2c55ff;
        _amountDescLabel.numberOfLines = 1;
    }
    return _amountDescLabel;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
