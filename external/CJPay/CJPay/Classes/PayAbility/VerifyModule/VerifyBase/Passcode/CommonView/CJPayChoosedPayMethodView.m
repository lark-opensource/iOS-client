//
//  CJPayChoosedPayMethodView.m
//  Pods
//
//  Created by xutianxi on 2022/11/25.
//

#import "CJPayChoosedPayMethodView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPayButton.h"

@interface CJPayChoosedPayMethodView ()

@property (nonatomic, strong) UIView *normalContentView; //非组合支付场景contentView
@property (nonatomic, strong) UIView *combineContentView; //组合支付场景contentView

@property (nonatomic, strong) UILabel *payTitleLabel; //标题：”支付方式“
@property (nonatomic, strong) UIImageView *payDescIconImageView; //支付方式icon
@property (nonatomic, strong) UILabel *payDescLabel; //支付方式描述信息（XX银行卡）
@property (nonatomic, strong) UIImageView *arrowImageView; //右箭头
@property (nonatomic, strong) UILabel *payDetailDescLabel; //支付方式详细信息（月付分期数）
@property (nonatomic, strong) CJPayButton *normalMethodChooseButton; //点击按钮

@property (nonatomic, strong) UILabel *combineBalanceTitleLabel; //组合支付-零钱标题
@property (nonatomic, strong) UILabel *combineBalanceDescLabel; //组合支付-零钱描述信息
@property (nonatomic, strong) UILabel *combineBankTitleLabel; //组合支付-卡标题
@property (nonatomic, strong) UILabel *combineBankDescLabel; //组合支付-卡信息

@property (nonatomic, strong) MASConstraint *normalContentViewEdgesBaseSuperConstraint;
@property (nonatomic, strong) MASConstraint *combineContentViewEdgesBaseSuperConstraint;

@end

@implementation CJPayChoosedPayMethodView

- (instancetype)initIsCombinePay:(BOOL)isCombinePay {
    self = [super init];
    if (self) {
        _isCombinedPay = isCombinePay;
        [self p_setupViews];
    };
    return self;
}

- (void)p_setupViews {
    [self addSubview:self.normalContentView];
    [self addSubview:self.combineContentView];
    
    CJPayMasMaker(self.normalContentView, {
        self.normalContentViewEdgesBaseSuperConstraint = make.edges.equalTo(self);
    });
    
    CJPayMasMaker(self.combineContentView, {
        self.combineContentViewEdgesBaseSuperConstraint = make.edges.equalTo(self);
    });
    [self p_setupUIForNormal];
    [self p_setupUIForCombinedPay];
    
    if (self.isCombinedPay) {
        // 组合支付场景，展示combineContentView
        [self.combineContentViewEdgesBaseSuperConstraint activate];
        [self.normalContentViewEdgesBaseSuperConstraint deactivate];
        self.combineContentView.hidden = NO;
        self.normalContentView.hidden = YES;
    } else {
        // 非组合支付场景，展示normalContentView
        [self.combineContentViewEdgesBaseSuperConstraint deactivate];
        [self.normalContentViewEdgesBaseSuperConstraint activate];
        self.combineContentView.hidden = YES;
        self.normalContentView.hidden = NO;
    }
}

- (void)p_setupUIForNormal {
    
    [self.normalContentView addSubview:self.payTitleLabel];
    [self.normalContentView addSubview:self.payDescIconImageView];
    [self.normalContentView addSubview:self.payDescLabel];
    [self.normalContentView addSubview:self.arrowImageView];
    [self.normalContentView addSubview:self.payDetailDescLabel];
    [self.normalContentView addSubview:self.normalMethodChooseButton];
    
    CJPayMasMaker(self.payTitleLabel, {
        make.left.top.equalTo(self.normalContentView);
        make.right.lessThanOrEqualTo(self.payDescIconImageView.mas_left);
        make.width.mas_equalTo(100).priorityLow();
    });
    [self.payTitleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    [self.payTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    CJPayMasMaker(self.payDescIconImageView, {
        make.width.height.mas_equalTo(16);
        make.right.equalTo(self.payDescLabel.mas_left).offset(-4);
        make.centerY.equalTo(self.payTitleLabel);
    });
    
    CJPayMasMaker(self.payDescLabel, {
        make.right.equalTo(self.arrowImageView.mas_left);
        make.centerY.equalTo(self.payTitleLabel);
    });
    [self.payDescLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    [self.payDescLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    CJPayMasMaker(self.arrowImageView, {
        make.width.height.mas_equalTo(20);
        make.right.equalTo(self.normalContentView);
        make.centerY.equalTo(self.payTitleLabel);
    });
    
    CJPayMasMaker(self.payDetailDescLabel, {
        make.left.greaterThanOrEqualTo(self.payTitleLabel);
        make.right.equalTo(self.payDescLabel);
        make.top.equalTo(self.payDescLabel.mas_bottom).offset(4);
        make.height.greaterThanOrEqualTo(@0);
        make.bottom.equalTo(self.normalContentView);
    });
    [self.payDetailDescLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    [self.payDetailDescLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];

    CJPayMasMaker(self.normalMethodChooseButton, {
        make.left.equalTo(self.payTitleLabel.mas_right);
        make.right.equalTo(self.normalContentView).priorityMedium();
        make.top.equalTo(self.normalContentView).offset(-10).priorityMedium();
        make.bottom.equalTo(self.normalContentView).offset(10).priorityMedium();
    });
}

- (void)p_setupUIForCombinedPay {
    [self.combineContentView addSubview:self.combineBalanceTitleLabel];
    [self.combineContentView addSubview:self.combineBalanceDescLabel];
    [self.combineContentView addSubview:self.combineBankTitleLabel];
    [self.combineContentView addSubview:self.combineBankDescLabel];

    CJPayMasMaker(self.combineBalanceTitleLabel, {
        make.left.top.equalTo(self.combineContentView);
    });
    [self.combineBalanceTitleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    CJPayMasMaker(self.combineBalanceDescLabel, {
        make.centerY.equalTo(self.combineBalanceTitleLabel);
        make.right.equalTo(self.combineContentView);
        make.left.greaterThanOrEqualTo(self.combineBalanceTitleLabel.mas_right);
    });
    
    CJPayMasMaker(self.combineBankTitleLabel, {
        make.left.equalTo(self.combineBalanceTitleLabel);
        make.top.equalTo(self.combineBalanceTitleLabel.mas_bottom).offset(4);
        make.bottom.equalTo(self.combineContentView);
    });
    [self.combineBankTitleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    CJPayMasMaker(self.combineBankDescLabel, {
        make.centerY.equalTo(self.combineBankTitleLabel);
        make.right.equalTo(self.combineBalanceDescLabel);
    });
}

- (void)updateContentByChannelConfigs:(NSArray<CJPayDefaultChannelShowConfig *>*)configs {
    if (!Check_ValidArray(configs)) {
        return;
    }
    
    if (self.isCombinedPay) {
        self.combineContentView.hidden = NO;
        self.normalContentView.hidden = YES;
        [self.combineContentViewEdgesBaseSuperConstraint activate];
        [self.normalContentViewEdgesBaseSuperConstraint deactivate];
        [self p_updateCombineContentView:configs];
    } else {
        self.combineContentView.hidden = YES;
        self.normalContentView.hidden = NO;
        [self.combineContentViewEdgesBaseSuperConstraint deactivate];
        [self.normalContentViewEdgesBaseSuperConstraint activate];
        CJPayDefaultChannelShowConfig *config = [configs cj_objectAtIndex:0];
        [self p_updateNormalContentView:config];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

// 根据支付方式更新视图
-(void)p_updateNormalContentView:(CJPayDefaultChannelShowConfig *)config {
    self.payDescLabel.text = CJString(config.title);
    [self.payDescIconImageView cj_setImageWithURL:[NSURL URLWithString:config.iconUrl]
                                      placeholder:[UIImage cj_roundImageWithColor:UIColor.clearColor]];
    
    self.payDetailDescLabel.hidden = YES;
    if (config.type == BDPayChannelTypeCreditPay) {
        NSString *creditDetailDesc = @"";
        if (Check_ValidString(config.paymentInfo)) {
            creditDetailDesc = CJString(config.paymentInfo);
        } else {
            CJPayBytePayCreditPayMethodModel *creditModel = config.payTypeData.curSelectCredit;
            NSString *totalAmountMsg = CJString(creditModel.payTypeDesc);
            NSString *creditFeeMsg = CJString(creditModel.feeDesc);
            if (![creditModel.installment isEqualToString:@"1"] && creditModel.fee == 0) {
                // 无手续费 且 非”不分期“ 场景，不展示手续费信息
                creditDetailDesc = totalAmountMsg;
            } else {
                creditDetailDesc = [NSString stringWithFormat:@"%@(%@)", totalAmountMsg, creditFeeMsg];
            }
        }
        self.payDetailDescLabel.text = creditDetailDesc;
        if (Check_ValidString(creditDetailDesc)) {
            self.payDetailDescLabel.hidden = NO;
//            [self setNeedsUpdateConstraints];
//            [self updateConstraintsIfNeeded];
        }
    }
}

// 更新组合支付视图内容
- (void)p_updateCombineContentView:(NSArray<CJPayDefaultChannelShowConfig *>*)configs {
    [configs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((obj.type == BDPayChannelTypeBalance || obj.type == BDPayChannelTypeIncomePay) && Check_ValidString(obj.paymentInfo)) {
            self.combineBalanceTitleLabel.text = obj.title;
            if ([obj.paymentInfo containsString:@"$"]) {
                [self.combineBalanceDescLabel setAttributedText:[self p_stringSeparatedWithDollar:obj.paymentInfo textAlignment:NSTextAlignmentRight]];
            } else {
                self.combineBalanceDescLabel.text = obj.paymentInfo;
            }
        } else if (obj.type == BDPayChannelTypeBankCard) {
            self.combineBankTitleLabel.text = obj.title;
            if ([obj.paymentInfo containsString:@"$"]) {
                [self.combineBankDescLabel setAttributedText:[self p_stringSeparatedWithDollar:obj.paymentInfo textAlignment:NSTextAlignmentRight]];
            } else {
                self.combineBankDescLabel.text = obj.paymentInfo;
            }
        }
    }];
}

// 根据$符区分文案颜色
- (NSMutableAttributedString *)p_stringSeparatedWithDollar:(NSString *)string textAlignment:(NSTextAlignment)textAlignment {
    NSArray * arr = [string componentsSeparatedByString:@"$"];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paraStyle.alignment = textAlignment;
    NSDictionary *lightAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:12],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.5],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *darkAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:12],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.9],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[arr cj_objectAtIndex:0] ?: @"" attributes:lightAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:1] ?: @"" attributes:darkAttributes]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:2] ?: @"" attributes:lightAttributes]];
    return attributedString;
}

#pragma mark - Override
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        CGPoint temPoint = [self.normalMethodChooseButton convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.normalMethodChooseButton.bounds, temPoint)) {
            view = self.normalMethodChooseButton;
        }
    }
    return view;
}

#pragma mark - lazy init

- (UIView *)normalContentView {
    if (!_normalContentView) {
        _normalContentView = [UIView new];
        _normalContentView.backgroundColor = [UIColor clearColor];
    }
    return _normalContentView;
}

- (UIView *)combineContentView {
    if (!_combineContentView) {
        _combineContentView = [UIView new];
        _combineContentView.backgroundColor = [UIColor clearColor];
    }
    return _combineContentView;
}

- (UILabel *)payTitleLabel {
    if (!_payTitleLabel) {
        _payTitleLabel = [[UILabel alloc] init];
        _payTitleLabel.font = [UIFont cj_fontOfSize:14];
        _payTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _payTitleLabel.textAlignment = NSTextAlignmentLeft;
        _payTitleLabel.text = CJPayLocalizedStr(@"支付方式");
    }
    return _payTitleLabel;
}

- (UIImageView *)payDescIconImageView {
    if (!_payDescIconImageView) {
        _payDescIconImageView = [[UIImageView alloc] init];
    }
    return _payDescIconImageView;
}

- (UILabel *)payDescLabel {
    if (!_payDescLabel) {
        _payDescLabel = [[UILabel alloc] init];
        _payDescLabel.font = [UIFont cj_fontOfSize:14];
        _payDescLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _payDescLabel.textAlignment = NSTextAlignmentRight;
    }
    return _payDescLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
        [_arrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _arrowImageView;
}

- (UILabel *)payDetailDescLabel {
    if (!_payDetailDescLabel) {
        _payDetailDescLabel = [[UILabel alloc] init];
        _payDetailDescLabel.font = [UIFont cj_fontOfSize:12];
        _payDetailDescLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _payDetailDescLabel.textAlignment = NSTextAlignmentRight;
        _payDetailDescLabel.hidden = YES;
    }
    return _payDetailDescLabel;
}

- (CJPayButton *)normalMethodChooseButton {
    if (!_normalMethodChooseButton) {
        _normalMethodChooseButton = [CJPayButton new];
        [_normalMethodChooseButton cj_setBtnSelectColor:[UIColor cj_forgetPWDSelectColor]];
        [_normalMethodChooseButton setTitle:CJPayLocalizedStr(@"") forState:UIControlStateNormal];
        @weakify(self);
        [_normalMethodChooseButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @strongify(self);
            CJ_CALL_BLOCK(self.clickedPayMethodBlock);
        }];
    }
    
    return _normalMethodChooseButton;
}

- (UILabel *)combineBalanceTitleLabel {
    if (!_combineBalanceTitleLabel) {
        _combineBalanceTitleLabel = [[UILabel alloc] init];
        _combineBalanceTitleLabel.font = [UIFont cj_fontOfSize:12];
        _combineBalanceTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _combineBalanceTitleLabel.textAlignment = NSTextAlignmentLeft;
        _combineBalanceTitleLabel.text = CJPayLocalizedStr(@"零钱");
    }
    return _combineBalanceTitleLabel;
}

- (UILabel *)combineBalanceDescLabel {
    if (!_combineBalanceDescLabel) {
        _combineBalanceDescLabel = [[UILabel alloc] init];
        _combineBalanceDescLabel.font = [UIFont cj_fontOfSize:12];
        _combineBalanceDescLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _combineBalanceDescLabel.textAlignment = NSTextAlignmentRight;
    }
    return _combineBalanceDescLabel;
}

- (UILabel *)combineBankTitleLabel {
    if (!_combineBankTitleLabel) {
        _combineBankTitleLabel = [[UILabel alloc] init];
        _combineBankTitleLabel.font = [UIFont cj_fontOfSize:12];
        _combineBankTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _combineBankTitleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _combineBankTitleLabel;
}

- (UILabel *)combineBankDescLabel {
    if (!_combineBankDescLabel) {
        _combineBankDescLabel = [[UILabel alloc] init];
        _combineBankDescLabel.font = [UIFont cj_fontOfSize:12];
        _combineBankDescLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _combineBankDescLabel.textAlignment = NSTextAlignmentRight;
    }
    return _combineBankDescLabel;
}
@end
