//
//  CJPayMarketingMsgView.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/13.
//

#import "CJPayMarketingMsgView.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayStyleErrorLabel.h"


@interface CJPayMarketingMsgView()

@property (nonatomic, strong) UILabel *unitLabel;//人民币符号
@property (nonatomic, strong) UILabel *priceLabel;//优惠后价格
@property (nonatomic, strong) UIView  *priceView;//包括价格和单位
@property (nonatomic, strong) UILabel *discountLabel;//营销信息
@property (nonatomic, assign) BOOL isShowVoucherMsg;//discountLabel是否展示payInfo.voucherMsg (目前指纹面容支付方式为YES)
@property (nonatomic, assign) MarketingMsgViewStyle viewStyle;

@end

@implementation CJPayMarketingMsgView

- (instancetype)init {
    self = [self initWithViewStyle:MarketingMsgViewStyleNormal isShowVoucherMsg:YES];
    return self;
}

- (instancetype)initWithViewStyle:(MarketingMsgViewStyle)viewStyle {
    self = [self initWithViewStyle:viewStyle isShowVoucherMsg:YES];
    return self;
}

- (instancetype)initWithViewStyle:(MarketingMsgViewStyle)viewStyle isShowVoucherMsg:(BOOL)isShowVoucherMsg {
    self = [super init];
    if (self) {
        self.viewStyle = viewStyle;
        self.isShowVoucherMsg = isShowVoucherMsg;
        [self p_setupUI];
        [self addObserver:self forKeyPath:@"priceLabel.text" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)p_setupUI
{
    self.priceView = [UIView new];
    [self addSubview:self.priceView];
    [self.priceView addSubview:self.priceLabel];
    [self.priceView addSubview:self.unitLabel];
    [self addSubview:self.discountLabel];
    
    CJPayMasMaker(self.priceView, {
        make.top.equalTo(self);
        make.centerX.equalTo(self).offset(-2);
    });
    
    CJPayMasMaker(self.discountLabel, {
        make.top.equalTo(self.priceView.mas_bottom).offset(-2);
        make.left.equalTo(self).mas_offset(20);
        make.right.equalTo(self).mas_offset(-20);
        make.height.greaterThanOrEqualTo(@0);
        make.bottom.equalTo(self);
    });
    [self.discountLabel setContentHuggingPriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
    [self.discountLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                        forAxis:UILayoutConstraintAxisVertical];
    
    switch (self.viewStyle) {
        case MarketingMsgViewStyleCompact:
            [self p_setupUIForCompact];
            break;
        case MarketingMsgViewStyleNormal:
            [self p_setupUIForNormal];
            break;
        case MarketingMsgViewStyleDenoiseV2:
            [self p_setupUIForDenoiseV2];
            break;
        case MarketingMsgViewStyleMacro:
            [self p_setupUIForMacro];
            break;
        default:
            CJPayLogAssert(NO, @"Please check the MarketingMsgViewStyle!");
    }
    self.clipsToBounds = NO;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"priceLabel.text"];
}

- (void)hideDiscountLabel {
    self.discountLabel.hidden = YES;
}


- (void)setMinHeightForDiscountLabel {
    CJPayMasUpdate(self.discountLabel, {
        make.height.greaterThanOrEqualTo(@17);
    });
}

- (void)updateWithModel:(CJPayBDCreateOrderResponse *)model {
    [self updateWithModel:model isFromSkipPwdConfirm:NO];
}

- (void)updateWithModel:(CJPayBDCreateOrderResponse *)model isFromSkipPwdConfirm:(BOOL)isFromSkipPwdConfirm {
    if (isFromSkipPwdConfirm) {
        if ([model.secondaryConfirmInfo.style isEqualToString:@"V1"]) {
            [self p_setupUIForSkipPwdConfirm];
        } else if ([model.secondaryConfirmInfo.style isEqualToString:@"V4"]) {
            [self p_setupUIForSkipPwdHalfPageConfirm];
        }
    }
    
    if (model.payInfo.needShowStandardVoucher) { //目前已全量
        [self updateWithPayAmount:CJString(model.payInfo.standardShowAmount) voucherMsg:CJString(model.payInfo.standardRecDesc)];
        return;
    }
    
    CJPayVoucherType voucherType = (CJPayVoucherType)[model.payInfo.voucherType integerValue];
    switch (voucherType) {
        case CJPayVoucherTypeNone: { //无营销
            [self p_updateUIForVoucherTypeNone:model];
            break;
        }
        case CJPayVoucherTypeImmediatelyDiscount: //固定立减营销
        case CJPayVoucherTypeBankCardImmediatelyDiscount: { //银行卡固定立减营销
            [self p_updateUIForVoucherTypeImmediatelyDiscount:model];
            break;
        }
        case CJPayVoucherTypeRandomDiscount://随机立减营销
        case CJPayVoucherTypeBankCardOtherDiscount: { //银行卡有营销无立减
            [self p_updateUIForVoucherTypeRandomDiscount:model];
            break;
        }
        case CJPayVoucherTypeFreeCharge: { //免手续费
            [self p_updateUIForVoucherTypeFreeCharge:model];
            break;
        }
        case CJPayVoucherTypeChargeDiscount: { //手续费打折
            [self p_updateUIForVoucherTypeChargeDiscount:model];
            break;
        }
        case CJPayVoucherTypeChargeNoDiscount: { //手续费不打折
            [self p_updateUIForVoucherTypeChargeNoDiscount:model];
            break;
        }
        case CJPayVoucherTypeStagingWithDiscount: { //手续费不打折+立减
            [self p_updateUIForVoucherTypeStagingWithDiscount:model];
            break;
        }
        case CJPayVoucherTypeStagingWithRandomDiscount: { //手续费不打折+随机立减
            [self p_updateUIForVoucherTypeStagingWithRandomDiscount:model];
            break;
        }
        case CJPayVoucherTypeNonePayAfterUse: { //先用后付文案展示
            [self p_updateUIForVoucherTypeNoneWithPayAfterUse:model];
            break;
        }
        default: {
            self.priceLabel.text = CJString(model.payInfo.realTradeAmount);//无营销取实际金额
            self.discountLabel.text = @"";
            break;
        }
    }
}

- (void)updatePriceColor:(UIColor *)color {
    self.unitLabel.textColor = color;
    self.priceLabel.textColor = color;
}

- (void)updateWithPayAmount:(NSString *)amount voucherMsg:(NSString *)voucherMsg {
    if (Check_ValidString(amount)) {
        if (self.viewStyle == MarketingMsgViewStyleDenoiseV2 || self.viewStyle == MarketingMsgViewStyleMacro) {
            [self p_setupPriceAttributeWithText:amount];
        } else {
            self.priceLabel.text = amount;
        }
    } else {
        self.priceLabel.text = @"";
    }
    
    [self p_updateVoucherMsg:voucherMsg];
}

- (void)p_updateVoucherMsg:(NSString *)voucherMsg {
    if (!Check_ValidString(voucherMsg)) {
        self.discountLabel.text = @"";
        return;
    }
    
    NSArray <NSString *> *array = [voucherMsg componentsSeparatedByString:@"~~"];
    if (array.count != 3) {
        // 说明营销信息中不符合删除线格式，直接展示
        self.discountLabel.text = voucherMsg;
        return;
    }
    
    NSDictionary *separateAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    NSDictionary *nonseparateAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};

    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:CJString([array cj_objectAtIndex:0])
                                                                                     attributes:nonseparateAttributes];
    NSAttributedString *separateAttributeStr = [[NSAttributedString alloc] initWithString:CJString([array cj_objectAtIndex:1])
                                                                               attributes:separateAttributes];
    NSAttributedString *tailAttributeStr = [[NSAttributedString alloc] initWithString:CJString([array cj_objectAtIndex:2])
                                                                           attributes:nonseparateAttributes];

    [attributeStr appendAttributedString:separateAttributeStr];
    [attributeStr appendAttributedString:tailAttributeStr];
    self.discountLabel.attributedText = attributeStr;
}

- (void)p_setupPriceAttributeWithText:(NSString *)priceText {
    if (!Check_ValidString(priceText)) {
        return;
    }
    
    CGFloat fontSize = self.viewStyle == MarketingMsgViewStyleDenoiseV2 ? 36 : 40;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:priceText attributes:@{
        NSFontAttributeName: [UIFont cj_denoiseBoldFontOfSize:fontSize],
        NSForegroundColorAttributeName: [UIColor cj_161823ff],
        NSParagraphStyleAttributeName: paragraphStyle,
        NSKernAttributeName: @(-1)
    }];
    self.priceLabel.attributedText = attributedString;
}

- (void)p_setupUIForSkipPwdConfirm {
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:22];
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:32];
    self.discountLabel.font = [UIFont cj_fontOfSize:13];
    
    CJPayMasReMaker(self.priceLabel, {
        make.top.bottom.right.equalTo(self.priceView);
        make.height.mas_equalTo(41);
    })
    
    CJPayMasReMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(28);
        make.bottom.equalTo(self.priceView).offset(-3);
    })
    
    CJPayMasReMaker(self.priceView, {
        make.top.centerX.equalTo(self);
    })

    CJPayMasReMaker(self.discountLabel, {
        make.top.equalTo(self.priceView.mas_bottom).offset(8);
        make.left.equalTo(self).mas_offset(16);
        make.right.equalTo(self).mas_offset(-16);
        make.height.greaterThanOrEqualTo(@0);
        make.bottom.equalTo(self);
    })
}

- (void)p_setupUIForSkipPwdHalfPageConfirm {
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:22];
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:36];
    self.discountLabel.font = [UIFont cj_fontOfSize:12];
    
    CJPayMasReMaker(self.priceLabel, {
        make.top.bottom.right.equalTo(self.priceView);
        make.height.mas_equalTo(46);
    })
    
    CJPayMasReMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(28);
        make.bottom.equalTo(self.priceView).offset(-3);
    })
    
    CJPayMasReMaker(self.priceView, {
        make.top.centerX.equalTo(self);
    })

    CJPayMasReMaker(self.discountLabel, {
        make.top.equalTo(self.priceView.mas_bottom).offset(4);
        make.left.equalTo(self).mas_offset(20);
        make.right.equalTo(self).mas_offset(-20);
        make.height.greaterThanOrEqualTo(@0);
        make.bottom.equalTo(self);
    })
}

- (void)p_setupUIForCompact {
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:32];
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:24];
    self.discountLabel.font = [UIFont cj_fontOfSize:12];
    
    CJPayMasMaker(self.priceLabel, {
        make.top.equalTo(self.priceView);
        make.bottom.equalTo(self.priceView.mas_bottom);
        make.right.equalTo(self.priceView);
        make.height.mas_equalTo(38);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(28);
        make.bottom.equalTo(self.priceView).offset(-3);
    });
}

- (void)p_setupUIForNormal {
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:36];
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:28];
    self.discountLabel.font = [UIFont cj_fontOfSize:12];
    
    CJPayMasMaker(self.priceLabel, {
        make.top.equalTo(self.priceView);
        make.bottom.equalTo(self.priceView.mas_bottom);
        make.right.equalTo(self.priceView);
        make.height.mas_equalTo(43);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(34);
        make.bottom.equalTo(self.priceView).offset(-2);
    });
}

- (void)p_setupUIForDenoiseV2 {
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:38];
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:24];
    self.discountLabel.font = [UIFont cj_fontOfSize:13];
    
    CJPayMasMaker(self.priceLabel, {
        make.top.equalTo(self.priceView);
        make.bottom.equalTo(self.priceView.mas_bottom);
        make.right.equalTo(self.priceView);
        make.height.mas_equalTo(49);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(31);
        make.bottom.equalTo(self.priceView).offset(-4);
    });
}

- (void)p_setupUIForMacro {
    self.priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:40];
    self.unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:30];
    self.discountLabel.font = [UIFont cj_fontOfSize:13];
    
    CJPayMasMaker(self.priceLabel, {
        make.top.equalTo(self.priceView);
        make.bottom.equalTo(self.priceView.mas_bottom);
        make.right.equalTo(self.priceView);
        make.height.mas_equalTo(52);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.left.equalTo(self.priceView);
        make.right.equalTo(self.priceLabel.mas_left).offset(-2);
        make.height.mas_equalTo(30);
        make.bottom.equalTo(self.priceView).offset(-7);
    });
}
#pragma mark - Private Methods

- (void)p_updateUIForVoucherTypeNone:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);//无营销取实际金额
    self.discountLabel.text = model.payInfo.isGuideCheck ? CJString(model.payInfo.guideVoucherLabel) : @"";
}

- (void)p_updateUIForVoucherTypeImmediatelyDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);//显示优惠后价格
    // 原价嵌入到营销信息里面
    NSDictionary *headAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    NSDictionary *separateAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone),
                                         NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    NSDictionary *tailAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    
    NSString *originTradeAmountStr = [NSString stringWithFormat:@"原价¥%@",CJString(model.payInfo.originTradeAmount)];
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:originTradeAmountStr
                                                                                     attributes:headAttributes];
    NSAttributedString *separateAttributeStr = [[NSAttributedString alloc] initWithString:@"，"
                                                                               attributes:separateAttributes];
    NSAttributedString *tailAttributeStr = [[NSAttributedString alloc] initWithString:CJString(model.payInfo.voucherMsg)
                                                                           attributes:tailAttributes];
    
    [attributeStr appendAttributedString:separateAttributeStr];
    [attributeStr appendAttributedString:tailAttributeStr];
    if (model.payInfo.isGuideCheck && (model.payInfo.guideVoucherLabel.length > 0)) {
        [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@",CJString(model.payInfo.guideVoucherLabel)] attributes:tailAttributes]];
    }
    self.discountLabel.attributedText = attributeStr;
}

- (void)p_updateUIForVoucherTypeRandomDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    self.discountLabel.text = [self p_discountStringWithModel:model];
}

- (void)p_updateUIForVoucherTypeFreeCharge:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    if (self.isShowVoucherMsg) {
        self.discountLabel.text = [self p_discountStringWithModel:model];
    } else {
        NSString *discountText = [NSString stringWithFormat:@"¥%@x%@期（免手续费）", CJString(model.payInfo.payAmountPerInstallment), CJString(model.payInfo.creditPayInstallment)];
        self.discountLabel.text = (model.payInfo.isGuideCheck && Check_ValidString(model.payInfo.guideVoucherLabel)) ? [NSString stringWithFormat:@"%@, %@", discountText, CJString(model.payInfo.guideVoucherLabel)] : discountText;
    }
}

- (void)p_updateUIForVoucherTypeChargeDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    if (self.isShowVoucherMsg) {
        self.discountLabel.text = [self p_discountStringWithModel:model];
    } else {
        NSString *realCharge = [NSString stringWithFormat:@"¥%@x%@期（手续费¥%@ ¥", CJString(model.payInfo.payAmountPerInstallment), CJString(model.payInfo.creditPayInstallment), CJString(model.payInfo.realFeePerInstallment)];
        NSMutableAttributedString *realChargeStr = [[NSMutableAttributedString alloc] initWithString:realCharge attributes:@{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleNone)}];
        NSMutableAttributedString *originFeeStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", CJString(model.payInfo.originFeePerInstallment)] attributes:@{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)}];
        NSMutableAttributedString *endstr = [[NSMutableAttributedString alloc] initWithString:@"/期）" attributes:@{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleNone)}];
        [realChargeStr appendAttributedString:originFeeStr];
        [realChargeStr appendAttributedString:endstr];
        if (model.payInfo.isGuideCheck && (model.payInfo.guideVoucherLabel.length > 0)) {
            [realChargeStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@",CJString(model.payInfo.guideVoucherLabel)] attributes:@{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleNone)}]];
        }
        self.discountLabel.attributedText = realChargeStr;
    }
}

- (void)p_updateUIForVoucherTypeChargeNoDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    if (self.isShowVoucherMsg) {
        self.discountLabel.text = model.payInfo.isGuideCheck ? CJString(model.payInfo.guideVoucherLabel) : @"";
    } else {
        NSString *str = [NSString stringWithFormat:@"¥%@x%@期（手续费¥%@/期）", CJString(model.payInfo.payAmountPerInstallment), CJString(model.payInfo.creditPayInstallment), Check_ValidString(model.payInfo.originFeePerInstallment) ? CJString(model.payInfo.originFeePerInstallment): CJString(model.payInfo.realFeePerInstallment)];//优先显示原手续费
        NSMutableAttributedString *voucherStr = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName: [UIColor cj_ff6e26ff]}];
        if (model.payInfo.isGuideCheck && (model.payInfo.guideVoucherLabel.length > 0)) {
            [voucherStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@",CJString(model.payInfo.guideVoucherLabel)] attributes:@{NSForegroundColorAttributeName: [UIColor cj_ff6e26ff]}]];
        }
        self.discountLabel.attributedText = voucherStr;
    }
}

- (void)p_updateUIForVoucherTypeStagingWithDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    NSString *originTradeAmountStr = [NSString stringWithFormat:@"原价¥%@",CJString(model.payInfo.originTradeAmount)];
    // 原价嵌入到营销信息里面
    NSDictionary *headAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    NSDictionary *separateAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    NSDictionary *tailAttributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName:[UIColor cj_ff6e26ff]};
    
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:originTradeAmountStr
                                                                                     attributes:headAttributes];
    NSAttributedString *separateAttributeStr = [[NSAttributedString alloc] initWithString:@"，"
                                                                               attributes:separateAttributes];
    [attributeStr appendAttributedString:separateAttributeStr];
    
    if (self.isShowVoucherMsg) {
        NSAttributedString *tailAttributeStr = [[NSAttributedString alloc] initWithString:CJString(model.payInfo.voucherMsg)
                                                                               attributes:tailAttributes];
        [attributeStr appendAttributedString:tailAttributeStr];
        if (model.payInfo.isGuideCheck && (model.payInfo.guideVoucherLabel.length > 0)) {
            [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@",CJString(model.payInfo.guideVoucherLabel)] attributes:tailAttributes]];
        }
        self.discountLabel.attributedText = attributeStr;
    } else {
        NSAttributedString *tailAttributeStr = [[NSAttributedString alloc] initWithString:[self p_buildMarketingString:model]
                                                                                attributes:tailAttributes];
        [attributeStr appendAttributedString:tailAttributeStr];
        if (model.payInfo.isGuideCheck && (model.payInfo.guideVoucherLabel.length > 0)) {
            [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@",CJString(model.payInfo.guideVoucherLabel)] attributes:tailAttributes]];
        }
        self.discountLabel.attributedText = attributeStr;
    }
}

- (void)p_updateUIForVoucherTypeStagingWithRandomDiscount:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    if (self.isShowVoucherMsg) {
        self.discountLabel.text = [self p_discountStringWithModel:model];
    } else {
        self.discountLabel.text = [self p_buildMarketingString:model];
    }
}

- (void)p_updateUIForVoucherTypeNoneWithPayAfterUse:(CJPayBDCreateOrderResponse *)model {
    self.priceLabel.text = CJString(model.payInfo.realTradeAmount);
    self.discountLabel.text = [self p_discountStringWithModel:model];
}

- (NSString *)p_buildMarketingString:(CJPayBDCreateOrderResponse *)model {
    NSString *chargeStr = CJString(model.payInfo.originFeePerInstallment);
    NSString *feePerInstallment = [chargeStr isEqualToString:@"0"] ? @"（免手续费）" : [NSString stringWithFormat:@"（手续费¥%@/期）",chargeStr];
    NSString *str = [NSString stringWithFormat:@"，¥%@x%@期%@", CJString(model.payInfo.payAmountPerInstallment), CJString(model.payInfo.creditPayInstallment),  feePerInstallment];
    NSMutableString *marketingStr = [[NSMutableString alloc] initWithString:CJString(model.payInfo.voucherMsg)];
    [marketingStr appendString:str];
    if (model.payInfo.isGuideCheck && Check_ValidString(model.payInfo.guideVoucherLabel)) {
        [marketingStr appendString:[NSString stringWithFormat:@", %@", CJString(model.payInfo.guideVoucherLabel)]];
    }
    return [marketingStr copy];
}

- (NSString *)p_discountStringWithModel:(CJPayBDCreateOrderResponse *)model {
    if (model.payInfo.isGuideCheck && Check_ValidString(model.payInfo.guideVoucherLabel)) {
        return [NSString stringWithFormat:@"%@, %@", CJString(model.payInfo.voucherMsg), CJString(model.payInfo.guideVoucherLabel)];
    } else {
        return CJString(model.payInfo.voucherMsg);
    }
}

#pragma mark - Getter

- (UILabel *)unitLabel
{
    if (!_unitLabel) {
        _unitLabel = [UILabel new];
        _unitLabel.text = @"¥";
        _unitLabel.font = [UIFont cj_denoiseBoldFontOfSize:28];
        _unitLabel.textColor = [UIColor cj_161823ff];
        _unitLabel.isAccessibilityElement = NO;
    }
    return _unitLabel;
}

- (UILabel *)priceLabel
{
    if (!_priceLabel) {
        _priceLabel = [UILabel new];
        _priceLabel.font = [UIFont cj_denoiseBoldFontOfSize:38];
        _priceLabel.textColor = [UIColor cj_161823ff];
    }
    return _priceLabel;
}

- (UILabel *)discountLabel
{
    if (!_discountLabel) {
        _discountLabel = [UILabel new];
        _discountLabel.font = [UIFont cj_fontOfSize:13];
        _discountLabel.textAlignment = NSTextAlignmentCenter;
        _discountLabel.numberOfLines = 2;
        _discountLabel.textColor = [UIColor cj_colorWithHexString:@"#FF6e26"];
    }
    return _discountLabel;
}

#pragma mark - KVO methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context { 
    NSString *price = [change cj_stringValueForKey:NSKeyValueChangeNewKey];
    self.priceLabel.accessibilityLabel = [NSString stringWithFormat:@"%@元",price];
}

@end
