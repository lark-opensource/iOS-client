//
//  CJPayChoosedPayMethodViewV3.m
//  Pods
//
//  Created by xutianxi on 2023/03/01.
//

#import "CJPayChoosedPayMethodViewV3.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPayPrimaryCombinePayInfoModel.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayOutDisplayInfoModel.h"

@interface CJPayChoosedPayMethodViewV3 ()

@property (nonatomic, assign) BOOL isCombinedPay; // 当前支付方式是否是组合支付

@property (nonatomic, strong) UIView *normalPayMethodView; //支付方式描述信息
@property (nonatomic, strong) UIView *combinePayDetailView; //组合支付明细（参与组合的卡和零钱/业务收入）
@property (nonatomic, strong) UIView *creditPayDetailView; //抖音月付明细（分期数、每期金额）

@property (nonatomic, strong) UILabel *payTitleLabel; //标题：”支付方式“
@property (nonatomic, strong) UIImageView *payDescIconImageView; //支付方式icon
@property (nonatomic, strong) UILabel *payDescLabel; //支付方式描述信息（XX银行卡）
@property (nonatomic, strong) UIImageView *arrowImageView; //右箭头
@property (nonatomic, strong) UILabel *creditPayDetailLabel; //支付方式详细信息（月付分期数）

@property (nonatomic, strong) UILabel *combineBalanceTitleLabel; //组合支付-零钱标题
@property (nonatomic, strong) UILabel *combineBalanceDescPayLabel; // 组合支付-零钱“支付”文案
@property (nonatomic, strong) UILabel *combineBalanceDescLabel; //组合支付-零钱描述信息
@property (nonatomic, strong) UILabel *combineBankTitleLabel; //组合支付-卡标题
@property (nonatomic, strong) UILabel *combineBankDescPayLabel; // 组合支付-卡“支付”文案
@property (nonatomic, strong) UILabel *combineBankDescLabel; //组合支付-卡信息
@property (nonatomic, strong) UIImageView *combineBankArrowImageView; // 组合支付-银行卡右箭头

@property (nonatomic, strong) UIStackView *payMethodStackView; //支付方式信息展示视图
@property (nonatomic, strong) UIView *normalPayClickView; // “普通支付方式”按钮点击热区
@property (nonatomic, strong) UIView *combinePayClickView; //“组合支付方式”按钮点击热区

@end

@implementation CJPayChoosedPayMethodViewV3

- (instancetype)initIsCombinePay:(BOOL)isCombinePay {
    self = [super init];
    if (self) {
        _isCombinedPay = isCombinePay;
        [self p_setupViews];
    };
    return self;
}

- (void)p_setupViews {
    [self addSubview:self.payMethodStackView];
    CJPayMasMaker(self.payMethodStackView, {
        make.edges.equalTo(self);
    });
    
    [self.payMethodStackView addArrangedSubview:self.normalPayMethodView]; // 通用支付方式信息描述
    [self.payMethodStackView addArrangedSubview:self.combinePayDetailView]; // 组合支付额外信息
    [self.payMethodStackView addArrangedSubview:self.creditPayDetailView]; // 月付额外信息

    [self p_setupUIForNormal];
    [self p_setupUIForCreditPay];
    [self p_setupUIForCombinedPay];

    [self addSubview:self.normalPayClickView];
    [self addSubview:self.combinePayClickView];
    
    if (self.isCombinedPay) {
        self.combinePayDetailView.hidden = NO;
    } else {
        self.combinePayDetailView.hidden = YES;
    }
}

// ”普通支付方式信息“，支付方式标题和图案
- (void)p_setupUIForNormal {
    
    [self.normalPayMethodView addSubview:self.payTitleLabel];
    [self.normalPayMethodView addSubview:self.payDescIconImageView];
    [self.normalPayMethodView addSubview:self.payDescLabel];
    [self.normalPayMethodView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.payTitleLabel, {
        make.left.top.equalTo(self.normalPayMethodView);
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
        make.right.equalTo(self.arrowImageView.mas_left).offset(6);
        make.centerY.equalTo(self.payTitleLabel);
        make.bottom.equalTo(self.normalPayMethodView);
    });
    [self.payDescLabel setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];
    [self.payDescLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                       forAxis:UILayoutConstraintAxisVertical];
    
    CJPayMasMaker(self.arrowImageView, {
        make.width.height.mas_equalTo(20);
        make.right.equalTo(self.normalPayMethodView);
        make.centerY.equalTo(self.payTitleLabel);
    });
}

- (void)p_normalPayMethodViewTapped {
    CJ_CALL_BLOCK(self.clickedPayMethodBlock);
}

- (void)p_combinePayMethodViewTapped {
    CJ_CALL_BLOCK(self.clickedCombineBankPayMethodBlock);
}

// ”支付方式额外描述信息“，例如月付的分期信息
- (void)p_setupUIForCreditPay {
    [self.creditPayDetailView addSubview:self.creditPayDetailLabel];
    CJPayMasMaker(self.creditPayDetailLabel, {
        make.right.equalTo(self.creditPayDetailView).offset(-16);
        make.top.bottom.equalTo(self.creditPayDetailView);
    });
    [self.creditPayDetailLabel setContentHuggingPriority:UILayoutPriorityRequired
                                               forAxis:UILayoutConstraintAxisVertical];
    [self.creditPayDetailLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                             forAxis:UILayoutConstraintAxisVertical];
}

// ”组合支付方式详细信息“，组合的银行卡和零钱资产明细
- (void)p_setupUIForCombinedPay {
    [self.combinePayDetailView addSubview:self.combineBalanceTitleLabel];
    [self.combinePayDetailView addSubview:self.combineBalanceDescPayLabel];
    [self.combinePayDetailView addSubview:self.combineBalanceDescLabel];
    [self.combinePayDetailView addSubview:self.combineBankTitleLabel];
    [self.combinePayDetailView addSubview:self.combineBankArrowImageView];
    [self.combinePayDetailView addSubview:self.combineBankDescLabel];
    [self.combinePayDetailView addSubview:self.combineBankDescPayLabel];

    CJPayMasMaker(self.combineBalanceTitleLabel, {
        make.left.top.equalTo(self.combinePayDetailView);
        make.height.mas_equalTo(18);
    });
    [self.combineBalanceTitleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisVertical];
    [self.combineBalanceTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                   forAxis:UILayoutConstraintAxisVertical];
    
    CJPayMasMaker(self.combineBalanceDescLabel, {
        make.centerY.equalTo(self.combineBalanceTitleLabel);
        make.right.equalTo(self.combinePayDetailView);
        make.left.greaterThanOrEqualTo(self.combineBalanceTitleLabel.mas_right);
    });
    CJPayMasMaker(self.combineBalanceDescPayLabel, {
        make.centerY.equalTo(self.combineBalanceTitleLabel);
        make.right.equalTo(self.combineBalanceDescLabel.mas_left).offset(-4);
    });
    
    CJPayMasMaker(self.combineBankTitleLabel, {
        make.left.equalTo(self.combineBalanceTitleLabel);
        make.top.equalTo(self.combineBalanceTitleLabel.mas_bottom).offset(4);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self.combinePayDetailView);
    });
    [self.combineBankTitleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                                  forAxis:UILayoutConstraintAxisVertical];
    [self.combineBankTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                forAxis:UILayoutConstraintAxisVertical];
    
    CJPayMasMaker(self.combineBankArrowImageView, {
        make.left.equalTo(self.combineBankTitleLabel.mas_right).offset(-6);
        make.centerY.equalTo(self.combineBankTitleLabel);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.combineBankDescLabel, {
        make.centerY.equalTo(self.combineBankTitleLabel);
        make.right.equalTo(self.combineBalanceDescLabel);
    });
    CJPayMasMaker(self.combineBankDescPayLabel, {
        make.centerY.equalTo(self.combineBankDescLabel);
        make.right.equalTo(self.combineBankDescLabel.mas_left).offset(-4);
    });
}

// 根据当前选中的支付方式来更新“支付方式信息”UI组件
- (void)updateContentByChannelConfigs:(NSArray<CJPayDefaultChannelShowConfig *>*)configs {
    if (!Check_ValidArray(configs)) {
        return;
    }

    self.isCombinedPay = configs.count >= 2;
    if (self.isCombinedPay) {
        self.combinePayDetailView.hidden = NO;

        if (self.canChangeCombineStatus) { // 若组合支付状态不允许更改，则不展示描述信息和右箭头
            self.normalPayMethodView.hidden = NO;
            self.combineBankArrowImageView.hidden = NO;
        } else {
            self.normalPayMethodView.hidden = YES;
            self.combineBankArrowImageView.hidden = YES;
        }
        [self p_updateCombineContentView:configs];
    } else {
        self.combinePayDetailView.hidden = YES;
        self.normalPayMethodView.hidden = NO;
        
        CJPayDefaultChannelShowConfig *config = [configs cj_objectAtIndex:0];
        [self p_updateNormalContentView:config];
    }
    [self p_updateClickViewConstraint];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)updatePayTypeTitle:(NSString *)title {
    self.payTitleLabel.text = title;
}

// 更新非组合支付UI内容
-(void)p_updateNormalContentView:(CJPayDefaultChannelShowConfig *)config {
    self.payDescLabel.text = CJString(config.title);
    self.payDescIconImageView.hidden = NO;
    [self.payDescIconImageView cj_setImageWithURL:[NSURL URLWithString:config.iconUrl]
                                      placeholder:[UIImage cj_roundImageWithColor:UIColor.clearColor]];
        
    self.creditPayDetailView.hidden = YES;
    if ([self.outDisplayInfoModel isDeductPayMode]) {
        // 如果走到了「签约信息前置」
        NSString *deductMethodSubDesc = self.outDisplayInfoModel.deductMethodSubDesc;
        self.creditPayDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        self.creditPayDetailLabel.text = CJString(deductMethodSubDesc);
        if (Check_ValidString(deductMethodSubDesc)) {
            self.creditPayDetailView.hidden = NO;
        }
        return;
    }
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
        self.creditPayDetailLabel.text = creditDetailDesc;
        self.creditPayDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        if (Check_ValidString(creditDetailDesc)) {
            self.creditPayDetailView.hidden = NO;
        }
    }
}

// 更新组合支付UI内容
- (void)p_updateCombineContentView:(NSArray<CJPayDefaultChannelShowConfig *>*)configs {
    self.payDescLabel.text = CJPayLocalizedStr(@"组合支付");
    self.creditPayDetailView.hidden = YES;
    self.payDescIconImageView.hidden = YES;
    [configs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.type == BDPayChannelTypeBankCard || obj.type == BDPayChannelTypeAddBankCard) {
                self.combineBankTitleLabel.text = obj.title;
                
                NSString *bankcardPayAmount = @"";
                NSString *balancePayAmount = @"";

                if (Check_ValidString(obj.paymentInfo)) { // 非O项目场景首次提单时，从paymentInfo取得组合支付信息
                    if ([obj.paymentInfo containsString:@"$"]) {
                        NSArray<NSString *> *arr = [obj.paymentInfo componentsSeparatedByString:@"$"];
                        bankcardPayAmount = CJString([arr cj_objectAtIndex:1]);
                    } else {
                        bankcardPayAmount = CJString(obj.paymentInfo);
                    }
                }
                
                // O项目场景从primaryPayInfoList取得组合支付信息
                id primartInfoModel = [obj.payTypeData.combinePayInfo.primaryPayInfoList cj_objectAtIndex:0];
                if (primartInfoModel && [primartInfoModel isKindOfClass:CJPayPrimaryCombinePayInfoModel.class]) {
                    CJPayPrimaryCombinePayInfoModel *primaryInfo = (CJPayPrimaryCombinePayInfoModel *)primartInfoModel;
                        bankcardPayAmount = CJString(primaryInfo.primaryAmountString);
                        balancePayAmount = CJString(primaryInfo.secondaryAmountString);
                }
                
                if (Check_ValidString(balancePayAmount)) {
                    self.combineBalanceDescLabel.text = CJString(balancePayAmount);
                }
                if (Check_ValidString(bankcardPayAmount)) {
                    self.combineBankDescLabel.text = CJString(bankcardPayAmount);
                } else {
                    CJPayLogInfo(@"六位密码展示组合支付信息时未取得银行卡支付金额");
                }
                
            } else if (obj.type == BDPayChannelTypeBalance || obj.type == BDPayChannelTypeIncomePay) {
                if (Check_ValidString(obj.paymentInfo)) {
                    if ([obj.paymentInfo containsString:@"$"]) {
                        NSArray<NSString *> *arr = [obj.paymentInfo componentsSeparatedByString:@"$"];
                        self.combineBalanceDescLabel.text = CJString([arr cj_objectAtIndex:1]);
                    } else {
                        self.combineBalanceDescLabel.text = CJString(obj.paymentInfo);
                    }
                }
                self.combineBalanceTitleLabel.text = obj.type == BDPayChannelTypeIncomePay ? CJPayLocalizedStr(@"钱包收入") : CJPayLocalizedStr(@"抖音零钱");
            }
    }];
}

- (void)p_updateClickViewConstraint {
    [self p_updateNormalClickViewConstraint];
    [self p_updateCombineClickViewConstraint];
}

- (void)p_updateNormalClickViewConstraint {
    if (self.normalPayClickView.superview != self) {
        return;
    }
    self.normalPayClickView.userInteractionEnabled = !self.normalPayMethodView.isHidden;
    CJPayMasReMaker(self.normalPayClickView, {
        make.left.top.equalTo(self.payDescLabel).offset(-10);
        make.right.equalTo(self).offset(20);
        make.height.mas_equalTo(self.creditPayDetailView.isHidden ? 40 : 60);
    });
}

- (void)p_updateCombineClickViewConstraint {
    if (self.combinePayClickView.superview != self) {
        return;
    }
    self.combinePayClickView.userInteractionEnabled = self.canChangeCombineStatus && !self.combinePayDetailView.isHidden;
    CJPayMasReMaker(self.combinePayClickView, {
        make.left.top.bottom.equalTo(self.combineBankTitleLabel).inset(-10);
        make.right.equalTo(self.combineBankArrowImageView).offset(10);
    });
    
}

#pragma mark - lazy init

- (UIView *)normalPayMethodView {
    if (!_normalPayMethodView) {
        _normalPayMethodView = [UIView new];
        _normalPayMethodView.backgroundColor = [UIColor clearColor];
    }
    return _normalPayMethodView;
}

- (UIView *)combinePayDetailView {
    if (!_combinePayDetailView) {
        _combinePayDetailView = [UIView new];
        _combinePayDetailView.backgroundColor = [UIColor clearColor];
    }
    return _combinePayDetailView;
}

- (UIView *)creditPayDetailView {
    if (!_creditPayDetailView) {
        _creditPayDetailView = [UIView new];
        _creditPayDetailView.backgroundColor = [UIColor clearColor];
    }
    return _creditPayDetailView;
}

- (UILabel *)payTitleLabel {
    if (!_payTitleLabel) {
        _payTitleLabel = [[UILabel alloc] init];
        _payTitleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:14];
        _payTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
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
        _payDescLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:14];
        _payDescLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
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

- (UILabel *)creditPayDetailLabel {
    if (!_creditPayDetailLabel) {
        _creditPayDetailLabel = [[UILabel alloc] init];
        _creditPayDetailLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:12];
        _creditPayDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _creditPayDetailLabel.textAlignment = NSTextAlignmentRight;
    }
    return _creditPayDetailLabel;
}

- (UILabel *)combineBalanceTitleLabel {
    if (!_combineBalanceTitleLabel) {
        _combineBalanceTitleLabel = [[UILabel alloc] init];
        _combineBalanceTitleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBalanceTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _combineBalanceTitleLabel.textAlignment = NSTextAlignmentLeft;
        _combineBalanceTitleLabel.text = CJPayLocalizedStr(@"抖音零钱");
    }
    return _combineBalanceTitleLabel;
}

- (UILabel *)combineBalanceDescPayLabel {
    if (!_combineBalanceDescPayLabel) {
        _combineBalanceDescPayLabel = [[UILabel alloc] init];
        _combineBalanceDescPayLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBalanceDescPayLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _combineBalanceDescPayLabel.textAlignment = NSTextAlignmentRight;
        _combineBalanceDescPayLabel.text = CJPayLocalizedStr(@"支付");
    }
    return _combineBalanceDescPayLabel;
}

- (UILabel *)combineBalanceDescLabel {
    if (!_combineBalanceDescLabel) {
        _combineBalanceDescLabel = [[UILabel alloc] init];
        _combineBalanceDescLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBalanceDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _combineBalanceDescLabel.textAlignment = NSTextAlignmentRight;
    }
    return _combineBalanceDescLabel;
}

- (UILabel *)combineBankTitleLabel {
    if (!_combineBankTitleLabel) {
        _combineBankTitleLabel = [[UILabel alloc] init];
        _combineBankTitleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBankTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _combineBankTitleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _combineBankTitleLabel;
}

- (UIImageView *)combineBankArrowImageView {
    if (!_combineBankArrowImageView) {
        _combineBankArrowImageView = [[UIImageView alloc] init];
        [_combineBankArrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _combineBankArrowImageView;
}

- (UILabel *)combineBankDescPayLabel {
    if (!_combineBankDescPayLabel) {
        _combineBankDescPayLabel = [[UILabel alloc] init];
        _combineBankDescPayLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBankDescPayLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _combineBankDescPayLabel.textAlignment = NSTextAlignmentRight;
        _combineBankDescPayLabel.text = CJPayLocalizedStr(@"支付");
    }
    return _combineBankDescPayLabel;
}

- (UILabel *)combineBankDescLabel {
    if (!_combineBankDescLabel) {
        _combineBankDescLabel = [[UILabel alloc] init];
        _combineBankDescLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _combineBankDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _combineBankDescLabel.textAlignment = NSTextAlignmentRight;
    }
    return _combineBankDescLabel;
}

- (UIStackView *)payMethodStackView {
    if (!_payMethodStackView) {
        _payMethodStackView = [UIStackView new];
        _payMethodStackView.axis = UILayoutConstraintAxisVertical;
        _payMethodStackView.distribution = UIStackViewDistributionFillProportionally;
        _payMethodStackView.spacing = 4;
    }
    return _payMethodStackView;
}

- (UIView *)normalPayClickView {
    if (!_normalPayClickView) {
        _normalPayClickView = [UIView new];
        _normalPayClickView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_normalPayMethodViewTapped)];
        [_normalPayClickView addGestureRecognizer:tapGesture];
    }
    return _normalPayClickView;
}

- (UIView *)combinePayClickView {
    if (!_combinePayClickView) {
        _combinePayClickView = [UIView new];
        _combinePayClickView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_combinePayMethodViewTapped)];
        [_combinePayClickView addGestureRecognizer:tapGesture];
    }
    return _combinePayClickView;
}
@end
