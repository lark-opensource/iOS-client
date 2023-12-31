//
//  CJPayPayAgainHalfView.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainHalfView.h"

#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayPayAgainNewCardCommonView.h"
#import "CJPayPayAgainOldCardCommonView.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayPayAgainCreditPayView.h"
#import "CJPayPayAgainDiscountView.h"
#import "CJPayButtonInfoViewController.h"
#import "CJPayCombineDetailView.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayThemeStyleManager.h"

@interface CJPayPayAgainHalfView()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *discountLabel;
@property (nonatomic, strong) UIView *oldCardContentView;
@property (nonatomic, strong) CJPayPayAgainNewCardCommonView *newCardContentView;
@property (nonatomic, strong) CJPayPayAgainOldCardCommonView *oldCardView;
@property (nonatomic, strong) UILabel *addNewCardHintInfoLabel;
@property (nonatomic, strong) UILabel *oldCardBankTailLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong) CJPayButton *otherPayMethodButton;
@property (nonatomic, strong) UIView *bgCardView;
@property (nonatomic, strong) UIView *voucherTipsView;
@property (nonatomic, strong) UILabel *voucherTipsLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuideView;
@property (nonatomic, strong) UILabel *payTypeLabel;

@property (nonatomic, strong) CJPayPayAgainCreditPayView *creditPayView;
@property (nonatomic, strong) CJPayPayAgainDiscountView *discountView;
@property (nonatomic, copy) NSString *creditInstallment;
@property (nonatomic, strong) CJPayCombineDetailView *combineDetailView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIImageView *infoImgView;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, copy) NSString *discountStr;//用于外部vc获取埋点参数，务必将营销信息赋值
@property (nonatomic, copy, readwrite) NSAttributedString *skipPwdTitle;//免密loading时候的富文本文案


@end

@implementation CJPayPayAgainHalfView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)refreshWithNotSufficientHintInfo:(CJPayHintInfo *)hintInfo {
    if (hintInfo.style == CJPayHintInfoStyleNewHalf) {
        [self refreshNewHalfWithHintInfo:hintInfo];
    } else if (hintInfo.style == CJPayHintInfoStyleVoucherHalfV2) {
        [self refreshWithNewHalfV2HintInfo:hintInfo];
    } else if (hintInfo.style == CJPayHintInfoStyleVoucherHalf) {
        [self refreshWithDiscountNotAvilableHintInfo:hintInfo];
    } else if (hintInfo.style == CJPayHintInfoStyleVoucherHalfV3) {
        [self refreshWithNewHalfV3HintInfo:hintInfo];
    } else {
        [self refreshWithHintInfo:hintInfo];
    }
}

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo {
    
    self.titleLabel.text = [self p_getTitleText:hintInfo];
    [self.confirmPayBtn cj_setBtnTitle:CJString(hintInfo.buttonText)];
    [self.otherPayMethodButton cj_setBtnTitle:CJString(hintInfo.subButtonText)];
    
    self.creditPayView.hidden = YES;
    self.discountView.hidden = YES;
    self.lineView.hidden = YES;
    self.infoImgView.hidden = !hintInfo.buttonInfo;
    
    if (hintInfo.recPayType.channelType == BDPayChannelTypeAddBankCard) { //添加新卡
        self.oldCardContentView.hidden = YES;
        self.discountLabel.hidden = YES;
        self.newCardContentView.hidden = NO;
        self.addNewCardHintInfoLabel.hidden = YES;
        if (Check_ValidString(hintInfo.subStatusMsg)) {
            self.addNewCardHintInfoLabel.hidden = NO;
            self.addNewCardHintInfoLabel.text = hintInfo.subStatusMsg;
        }
        
        [self.newCardContentView refreshWithHintInfo:hintInfo];
    } else { // 老卡|余额
        self.oldCardContentView.hidden = NO;
        self.discountLabel.hidden = NO;
        self.newCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = YES;
        
        [self.oldCardView.bankIconImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.recPayType.iconUrl]];
        self.oldCardView.bankLabel.text = CJString(hintInfo.recPayType.title);
        self.discountStr = CJString(hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);
        self.discountLabel.text = self.discountStr;
    }
}

- (void)refreshWithDiscountNotAvilableHintInfo:(CJPayHintInfo *)hintInfo {
    self.hintInfo = hintInfo;
    self.creditPayView.hidden = YES;
    self.lineView.hidden = YES;
    self.titleLabel.text = [self p_getTitleText:hintInfo];
    self.infoImgView.hidden = !self.hintInfo.buttonInfo;
    self.oldCardContentView.hidden = YES;
    self.newCardContentView.hidden = YES;
    
    self.addNewCardHintInfoLabel.hidden = NO;
    self.addNewCardHintInfoLabel.text = CJPayLocalizedStr(self.hintInfo.subStatusMsg);

    self.addNewCardHintInfoLabel.font = [UIFont cj_fontOfSize:15];
    self.addNewCardHintInfoLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    self.addNewCardHintInfoLabel.numberOfLines = 0;
    self.addNewCardHintInfoLabel.textAlignment = NSTextAlignmentCenter;
    
    NSArray<NSString *> *voucherList = hintInfo.recPayType.payTypeData.voucherMsgList;
    if (Check_ValidArray(voucherList)) {
        self.discountView.hidden = NO;
        self.discountStr = CJString([voucherList cj_objectAtIndex:0]);
        [self.discountView setDiscountStr:self.discountStr];//仅下发一个优惠，但是以后可能会扩展
    } else {
        self.discountView.hidden = YES;
    }
    
    [self.confirmPayBtn cj_setBtnTitle:self.hintInfo.buttonText];
    [self.otherPayMethodButton cj_setBtnTitle:self.hintInfo.subButtonText];
    [self.logoImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.iconUrl]];
    
    CJPayMasReMaker(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(24);
    })
}

- (void)refreshNewHalfWithHintInfo:(CJPayHintInfo *)hintInfo {
    self.hintInfo = hintInfo;
    self.lineView.hidden = !hintInfo.recPayType.isCombinePay;
    self.combineDetailView.hidden = !hintInfo.recPayType.isCombinePay;
    [self.combineDetailView updateWithCombineShowInfo:hintInfo.recPayType.payTypeData.combineShowInfo];
    self.titleLabel.text = [self p_getTitleText:hintInfo];
    self.titleLabel.font = [UIFont cj_boldFontOfSize:20];
    self.creditPayView.hidden = YES;
    self.discountLabel.hidden = YES;

    if (self.showStyle == CJPaySecondPayRecSimpleStyle) {
        NSString *suffixText = self.isSuperPay ? CJPayLocalizedStr(@"完成极速付款") : CJPayLocalizedStr(@"可免输卡号绑卡");
        if (hintInfo.recPayType.isCombinePay) {
            self.addNewCardHintInfoLabel.attributedText = [self p_attrStringWithPrefix:CJPayLocalizedStr(@"推荐") Text:CJPayLocalizedStr(@"「添加银行卡组合支付」") suffix:suffixText];
        } else {
            self.addNewCardHintInfoLabel.attributedText = [self p_attrStringWithPrefix:CJPayLocalizedStr(@"推荐") Text:CJPayLocalizedStr(@"「添加银行卡支付」") suffix:suffixText];
        }
        [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_getConfirmTitleV2Style]];
        self.otherPayMethodButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
        self.otherPayMethodButton.titleLabel.textColor = [UIColor cj_161823ff];
        if (Check_ValidString(hintInfo.iconUrl)){
            [self.logoImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.iconUrl]];
        }
        
        CJPayMasReMaker(self.lineView, {
            make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(20);
            make.left.right.equalTo(self.confirmPayBtn);
            make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        });
        
        CJPayMasReMaker(self.combineDetailView, {
            make.top.equalTo(self.lineView.mas_bottom).offset(17);
            make.left.right.equalTo(self.confirmPayBtn);
            make.height.mas_equalTo(42);
        });
    } else {
        if (hintInfo.recPayType.isCombinePay) {
            self.addNewCardHintInfoLabel.text = CJPayLocalizedStr(@"推荐添加银行卡，继续组合支付");
        } else {
            self.addNewCardHintInfoLabel.text = CJPayLocalizedStr(@"推荐添加银行卡支付，可免输卡号绑卡");
        }
        self.addNewCardHintInfoLabel.font = [UIFont cj_fontOfSize:15];
        self.addNewCardHintInfoLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        self.otherPayMethodButton.alpha = 0.75;
        self.otherPayMethodButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        [self.confirmPayBtn cj_setBtnTitle:CJString(hintInfo.buttonText)];
    }

    self.infoImgView.hidden = !hintInfo.buttonInfo;
    if (hintInfo.recPayType.isCombinePay) {
        self.discountStr = CJString(hintInfo.recPayType.payTypeData.combinePayInfo.combinePayVoucherMsgList.firstObject);
    } else {
        self.discountStr = CJString(hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);
    }
    self.discountView.hidden = !Check_ValidString(self.discountStr);
    [self.discountView setDiscountStr:self.discountStr];
    [self.otherPayMethodButton cj_setBtnTitle:CJString(hintInfo.subButtonText)];
    
    if (hintInfo.recPayType.channelType == BDPayChannelTypeAddBankCard) { //添加新卡
        self.oldCardContentView.hidden = YES;
        self.newCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = NO;
        self.oldCardView.bankPreLabel.text = CJPayLocalizedStr(@"可更换为");
        [self p_setupNewHalfNewCardConstraintsWithHintInfo:hintInfo];
        
        if (hintInfo.recPayType.payTypeData.recommendType == 1) {  // 微信常用卡
            self.oldCardContentView.hidden = YES;
            self.newCardContentView.hidden = YES;
            self.addNewCardHintInfoLabel.numberOfLines = 2;
            self.addNewCardHintInfoLabel.textAlignment = NSTextAlignmentCenter;
            
            NSString *suffixStr = hintInfo.recPayType.isCombinePay ? CJPayLocalizedStr(@"继续组合支付") : CJPayLocalizedStr(@" 支付");
            [self p_asyncRefreshLabelWithHintInfoModel:hintInfo prefixStr:CJPayLocalizedStr(@"推荐添加 ") suffixStr:suffixStr];
        }
        
        [self.newCardContentView refreshWithHintInfo:hintInfo];
    } else if (hintInfo.recPayType.channelType == BDPayChannelTypeCreditPay) {
        self.creditPayView.hidden = NO;
        self.newCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = YES;
        self.oldCardContentView.hidden = YES;
        self.titleLabel.font = [UIFont cj_boldFontOfSize:17];
        [self p_setupCreditPayConstraints];
        
        [self.creditPayView.bankIconImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.recPayType.iconUrl]];
        self.creditPayView.bankLabel.text = CJString(hintInfo.recPayType.title);
        self.creditPayView.collectionView.creditPayMethods = hintInfo.recPayType.payTypeData.creditPayMethods;
        for (CJPayBytePayCreditPayMethodModel *model in hintInfo.recPayType.payTypeData.creditPayMethods) {
            if (model.choose == YES) {
                self.creditInstallment = model.installment;
            }
        }
        @CJWeakify(self)
        self.creditPayView.collectionView.clickBlock = ^(NSString * _Nonnull installment) {
            @CJStrongify(self)
            self.creditInstallment = installment;
            [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_getConfirmTitleV2Style]];
        };
        [self.creditPayView.collectionView reloadData];
    } else { // 老卡|余额
        self.oldCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = NO;
        self.newCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.numberOfLines = 2;
        self.addNewCardHintInfoLabel.textAlignment = NSTextAlignmentCenter;
        NSString *suffixStr = hintInfo.recPayType.isCombinePay ? CJPayLocalizedStr(@" 组合支付") : CJPayLocalizedStr(@" 继续支付");
        [self p_asyncRefreshLabelWithHintInfoModel:hintInfo prefixStr:CJPayLocalizedStr(@"可更换为 ") suffixStr:suffixStr];
        [self p_setupNewHalfNewCardConstraintsWithHintInfo:hintInfo];
        
        [self.oldCardView.bankIconImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.recPayType.iconUrl]];
        self.oldCardView.bankLabel.text = CJString(hintInfo.recPayType.title);
    }
    if (self.isSuperPay) {
        [self p_setupUISuperPay];
    }
}


- (void)refreshWithNewHalfV2HintInfo:(CJPayHintInfo *)hintInfo {
    self.hintInfo = hintInfo;
    [self p_setupVoucherHalfV2Style];//通用样式
    
    if (hintInfo.recPayType.channelType == BDPayChannelTypeAddBankCard) { //添加新卡
        self.oldCardContentView.hidden = YES;
        self.newCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = NO;
        self.oldCardView.bankPreLabel.text = CJPayLocalizedStr(@"可更换为");
                
        if (self.hintInfo.recPayType.payTypeData.recommendType == 1) {  // 微信常用卡
            self.oldCardContentView.hidden = YES;
            self.newCardContentView.hidden = YES;
            self.addNewCardHintInfoLabel.numberOfLines = 2;
            self.addNewCardHintInfoLabel.textAlignment = NSTextAlignmentCenter;
            
            NSString *suffixStr = self.hintInfo.recPayType.isCombinePay ? CJPayLocalizedStr(@"继续组合支付") : CJPayLocalizedStr(@" 支付");
            [self p_asyncRefreshLabelWithHintInfoModel:self.hintInfo prefixStr:CJPayLocalizedStr(@"推荐添加 ") suffixStr:suffixStr];
        }
        if (hintInfo.recPayType.isCombinePay) {
            [self p_setupUICombineV2Style];
        } else {
            [self p_setupUICardV2Style];
        }
        [self.newCardContentView refreshWithHintInfo:hintInfo];
    } else if (hintInfo.recPayType.channelType == BDPayChannelTypeCreditPay) {
        [self p_setupUICreditV2Style];
        //下面在主要处理月付的点击事件和collectionView的设置
        [self.creditPayView.bankIconImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.recPayType.iconUrl]];
        self.creditPayView.bankLabel.text = CJString(hintInfo.recPayType.title);
        self.creditPayView.collectionView.creditPayMethods = hintInfo.recPayType.payTypeData.creditPayMethods;
        for (CJPayBytePayCreditPayMethodModel *model in hintInfo.recPayType.payTypeData.creditPayMethods) {
            if (model.choose == YES) {
                self.creditInstallment = model.installment;
            }
        }
        @CJWeakify(self)
        self.creditPayView.collectionView.clickBlock = ^(NSString * _Nonnull installment) {
            @CJStrongify(self)
            self.creditInstallment = installment;
            [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_getConfirmTitleV2Style]];//根据月付金额修改button文案
        };
        [self.creditPayView.collectionView reloadData];
    } else { // 老卡|余额
        self.oldCardContentView.hidden = YES;
        self.addNewCardHintInfoLabel.hidden = NO;
        self.newCardContentView.hidden = YES;
        
        self.titleLabel.numberOfLines = 0;
        self.addNewCardHintInfoLabel.numberOfLines = 2;
        self.addNewCardHintInfoLabel.textAlignment = NSTextAlignmentCenter;
        NSString *paySuffixStr = [hintInfo.failType isEqualToString:@"2"] ? CJPayLocalizedStr(@" 继续支付") : CJPayLocalizedStr(@" 支付");
        NSString *suffixStr = hintInfo.recPayType.isCombinePay ? CJPayLocalizedStr(@" 组合支付") : paySuffixStr;
        NSString *prefixStr = [hintInfo.failType isEqualToString:@"2"] ? CJPayLocalizedStr(@"可用 ") : CJPayLocalizedStr(@"可更换 ");
        [self p_asyncRefreshLabelWithHintInfoModel:hintInfo prefixStr:prefixStr suffixStr:suffixStr];
        if (hintInfo.recPayType.channelType == BDPayChannelTypeBalance) {
            [self p_setupUIBalanceV2Style];
        } else if (hintInfo.recPayType.channelType == BDPayChannelTypeFundPay) {
            [self p_setupUIFundPayV2Style];
        } else if (hintInfo.recPayType.isCombinePay) {
            [self p_setupUICombineV2Style];
        } else {
            [self p_setupUICardV2Style];
        }
    }
}

- (void)refreshWithNewHalfV3HintInfo:(CJPayHintInfo *)hintInfo {
    self.hintInfo = hintInfo;
    self.newCardContentView.hidden = YES;
    self.addNewCardHintInfoLabel.hidden = YES;
    self.oldCardContentView.hidden = YES;
    
    [self p_setupVoucherHalfV2Style];
    
    self.logoImageView.hidden = NO;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.font = [UIFont cj_boldFontOfSize:18];
    
    [self.logoImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.iconUrl]];
    
    NSArray<NSString *> *voucherList = hintInfo.recPayType.payTypeData.voucherMsgList;
    if (Check_ValidArray(voucherList)) {
        self.discountView.hidden = NO;
        self.discountStr = CJString([voucherList cj_objectAtIndex:0]);
        [self.discountView setDiscountStr:self.discountStr];//仅下发一个优惠，但是以后可能会扩展
    } else {
        self.discountView.hidden = YES;
    }
    
    CJPayMasUpdate(self.logoImageView, {
        make.top.equalTo(self).offset(40);
    });
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(24);
    });
}

- (NSString *)getDiscount {
    return self.discountStr;
}

#pragma mark - private method

- (NSString *)p_changeCreditPayAmount {
    __block NSString *buttonAmount = @"";
    [self.hintInfo.recPayType.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.choose) {
            buttonAmount = [self p_getBtnPayAmountWithVoucher:obj.orderSubFixedVoucherAmount];//根据选择更换button文案
            *stop = YES;
        }
    }];
    return buttonAmount;
}

- (NSString *)p_getBtnPayAmountWithVoucher:(NSInteger)voucherAmount {
    NSString *buttonAmount = [NSString stringWithFormat:@"¥%.2f", (self.hintInfo.tradeAmount - voucherAmount)/(double)100];
    return buttonAmount;
}

- (NSAttributedString *)p_getConfirmTitleV2Style {//处理下发button文案中的金额字段$|$
    NSMutableAttributedString *mutableStr = [[NSMutableAttributedString alloc] init];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.minimumLineHeight = 21;
    
    NSDictionary *descAttr = @{
        NSFontAttributeName:[UIFont cj_boldFontWithoutFontScaleOfSize:15],
        NSForegroundColorAttributeName:[UIColor cj_ffffffWithAlpha:1],
        NSParagraphStyleAttributeName:paragraphStyle,
    };
    
    NSDictionary *dinAttr = @{
        NSFontAttributeName:[UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:17],
        NSForegroundColorAttributeName:[UIColor cj_ffffffWithAlpha:1],
        NSParagraphStyleAttributeName:paragraphStyle,
        NSBaselineOffsetAttributeName:@(-1),
    };
    
    if (!self.skipPwdTitle) {
        self.skipPwdTitle = [[NSAttributedString alloc] initWithString:CJPayLocalizedStr(@"免密支付中...") attributes:descAttr];
    }
    NSString *buttonStr = CJString(self.hintInfo.buttonText);
    NSArray<NSString *> *buttonStrArr = [buttonStr componentsSeparatedByString:@"$"];
    
    NSMutableAttributedString *textAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", buttonStrArr.firstObject] attributes:descAttr];
    [mutableStr appendAttributedString:textAttr];
    NSString *numStr = CJString([buttonStrArr cj_objectAtIndex:1]);//分割后一定在奇数位，目前只存在一个数字
    if (Check_ValidString(numStr) && ![numStr isEqualToString:@"|"]) {//有数字，为|需要端上自己算
        NSMutableAttributedString *numAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", numStr] attributes:dinAttr];
        [mutableStr appendAttributedString:numAttr];
    } else if ([numStr isEqualToString:@"|"]) {
        CJPaySubPayTypeInfoModel *recPayType = self.hintInfo.recPayType;
        NSString *buttonAmount = @"";
        if (recPayType.channelType == BDPayChannelTypeCreditPay) {
            buttonAmount = [self p_changeCreditPayAmount];
        } else if (recPayType.isCombinePay) {
            buttonAmount = [self p_getBtnPayAmountWithVoucher:recPayType.payTypeData.combinePayInfo.combinePayVoucherInfo.orderSubFixedVoucherAmount];
        } else {
            buttonAmount = [self p_getBtnPayAmountWithVoucher:recPayType.payTypeData.voucherInfo.orderSubFixedVoucherAmount];
        }
        NSMutableAttributedString *numAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", buttonAmount] attributes:dinAttr];
        [mutableStr appendAttributedString:numAttr];
    }
    return mutableStr;
}

- (void)p_asyncRefreshLabelWithHintInfoModel:(CJPayHintInfo *)hintInfo prefixStr:(NSString *)prefixStr suffixStr:(NSString *)suffixStr { //图文混排耗时，异步刷新避免卡顿
    // 优化展示推荐卡的体验，先把推荐支付方式展示出来，图片异步刷新
    UIImage *placeholderImg = [UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]];
    NSString *imageStr = [hintInfo.failType isEqualToString:@"2"] ? @"" : hintInfo.recPayType.iconUrl;
    self.addNewCardHintInfoLabel.attributedText = [self p_attrStringWithPrefix:CJString(prefixStr)
                                                                          Text:CJString(hintInfo.recPayType.title)
                                                                        suffix:CJString(suffixStr)
                                                                      imageStr:imageStr
                                                                placeholderImg:placeholderImg];
    dispatch_queue_t processQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(processQueue, ^{
        NSAttributedString *attributeStr = [self p_attrStringWithPrefix:CJString(prefixStr)
                                                                   Text:CJString(hintInfo.recPayType.title)
                                                                 suffix:CJString(suffixStr)
                                                               imageStr:imageStr
                                                         placeholderImg:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.addNewCardHintInfoLabel.attributedText = attributeStr;
        });
    });
}

- (NSAttributedString *)p_attrStringWithPrefix:(NSString *)prefix
                                          Text:(NSString *)text
                                        suffix:(nullable NSString *)suffix {
    return [self p_attrStringWithPrefix:prefix Text:text suffix:suffix imageStr:nil placeholderImg:nil];
}

- (NSAttributedString *)p_attrStringWithPrefix:(NSString *)prefix
                                          Text:(NSString *)text
                                        suffix:(nullable NSString *)suffix
                                      imageStr:(nullable NSString *)imageStr
                                placeholderImg:(nullable UIImage *)placeholderImg {
    BOOL hasImageURL = Check_ValidString(imageStr);//复用能力，兼容无图片的情况；避免图片链接为空导致崩溃
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    if (placeholderImg) {
        attachment.image = placeholderImg;
    } else {
        if (hasImageURL){
            attachment.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageStr]]];
        }
    }
    
    if (self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2 && self.hintInfo.recPayType.channelType == BDPayChannelTypeBankCard) {
        text = [self p_shortHandWithBankName:text];//缩写银行卡名称
    }
    
    attachment.bounds = CGRectMake(0, -2, 16, 16);
    
    NSAttributedString *imageAttr = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.minimumLineHeight = 21;
    
    NSDictionary *attributes = @{
        NSFontAttributeName:[UIFont cj_fontWithoutFontScaleOfSize:(self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2) ? 16 : 15],
        NSParagraphStyleAttributeName:paragraphStyle,
    };
    
    NSDictionary *textAttributes = @{
        NSFontAttributeName:[UIFont cj_boldFontWithoutFontScaleOfSize:(self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2) ? 16 : 15],
        NSParagraphStyleAttributeName:paragraphStyle,
        NSForegroundColorAttributeName : [UIColor cj_161823ff] //原来是灰的
    };
    NSAttributedString *preTextAttr = [[NSMutableAttributedString alloc] initWithString:prefix attributes:attributes];
    
    NSMutableAttributedString *mutableAttr = [[NSMutableAttributedString alloc] init];
    NSMutableAttributedString *textAttr = [[NSMutableAttributedString alloc] init];
    
    [mutableAttr appendAttributedString:preTextAttr];
    if (hasImageURL) {
        [mutableAttr appendAttributedString:imageAttr];
    }
    if (self.showStyle == CJPaySecondPayRecSimpleStyle || self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2) {//精简样式 || 营销样式
        textAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", text] attributes:textAttributes];
        [mutableAttr appendAttributedString:textAttr];
        if (Check_ValidString(suffix)) {
            NSMutableAttributedString *suffixAttr = [[NSMutableAttributedString alloc] init];
            suffixAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", suffix] attributes:attributes];
            [mutableAttr appendAttributedString:suffixAttr];
        }
    } else {//线上
        textAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@%@", text, suffix] attributes:attributes];
        [mutableAttr appendAttributedString:textAttr];
    }
    if (hasImageURL) {
        NSRange range = [mutableAttr.string rangeOfString:imageAttr.string]; //获取图片位置
        NSRange imageRange = NSMakeRange(range.location, range.length + 1); //增加一个空格用来控制图文间距
        [mutableAttr addAttribute:NSKernAttributeName value:@(-1) range:imageRange];
    }
    
    return [mutableAttr copy];
}

- (NSString *)p_shortHandWithBankName:(NSString *)text {
    NSString *shortName = text;
    if(text.length > 14) {
        NSRange range = NSMakeRange(4, text.length - 14);//银行卡名前4后3，加尾号6，加空格1 = 14
        shortName = [text stringByReplacingCharactersInRange:range withString:@"..."];
    }
    return shortName;
}


- (void)p_setupUI {
    [self addSubview:self.logoImageView];
    [self addSubview:self.titleLabel];
    
    [self.oldCardContentView addSubview:self.oldCardView];
    [self.oldCardContentView addSubview:self.oldCardBankTailLabel];
    [self addSubview:self.oldCardContentView];
    
    [self addSubview:self.newCardContentView];
    [self addSubview:self.addNewCardHintInfoLabel];
    [self addSubview:self.discountLabel];
    [self addSubview:self.confirmPayBtn];
    [self addSubview:self.otherPayMethodButton];
    [self addSubview:self.creditPayView];
    [self addSubview:self.discountView];
    
    [self addSubview:self.combineDetailView];
    [self addSubview:self.lineView];
    [self addSubview:self.infoImgView];
    
    CJPayMasMaker(self.logoImageView, {
        make.top.equalTo(self).offset(80);
        make.width.height.mas_equalTo(60);
        make.centerX.equalTo(self);
    });
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(24);
    });
    
    CJPayMasMaker(self.oldCardView, {
        make.top.left.bottom.equalTo(self.oldCardContentView);
    })
    CJPayMasMaker(self.oldCardBankTailLabel, {
        make.left.equalTo(self.oldCardView.mas_right).offset(4);
        make.right.top.equalTo(self.oldCardContentView);
    })
    [self.oldCardBankTailLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.oldCardContentView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(16);
        make.right.lessThanOrEqualTo(self).offset(-16);
    });
    
    CJPayMasMaker(self.newCardContentView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.newCardContentView.mas_bottom).offset(4);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.discountLabel, {
        make.top.equalTo(self.oldCardContentView.mas_bottom).offset(4);
        make.centerX.equalTo(self);
    })
    
    CJPayMasMaker(self.otherPayMethodButton, {
        make.top.equalTo(self.confirmPayBtn.mas_bottom).offset(13);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self).offset(-13);
        make.left.right.equalTo(self).inset(16);
    });
    
    CJPayMasMaker(self.confirmPayBtn, {
        make.bottom.equalTo(self.otherPayMethodButton.mas_top).offset(-13);
        make.left.right.equalTo(self.otherPayMethodButton);
        make.height.mas_equalTo(44);
    });

    CJPayMasMaker(self.creditPayView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(40);
        make.left.equalTo(self.confirmPayBtn);
        make.right.equalTo(self);
        make.height.mas_equalTo(100);
    });
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.confirmPayBtn.mas_top).offset(-32);
        make.height.mas_equalTo(50);
        make.right.equalTo(self.confirmPayBtn);
    });
    
    CJPayMasMaker(self.combineDetailView, {
        make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(37);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.lineView, {
        make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(20);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.infoImgView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(6);
        make.centerY.equalTo(self.titleLabel);
        make.height.width.mas_equalTo(@20);
    });
}

- (void)p_setupVoucherHalfV2Style {
    [self addSubview:self.safeGuideView];
    
    self.logoImageView.hidden = YES;//主logo
    self.discountView.hidden = YES;//主button右上角营销标签
    self.lineView.hidden = !self.hintInfo.recPayType.isCombinePay;
    self.combineDetailView.hidden = !self.hintInfo.recPayType.isCombinePay;
    [self.combineDetailView updateWithCombineShowInfo:self.hintInfo.recPayType.payTypeData.combineShowInfo];
    self.creditPayView.hidden = YES;
    self.discountLabel.hidden = YES;
    self.infoImgView.hidden = !self.hintInfo.buttonInfo;
    
    if (self.hintInfo.recPayType.isCombinePay) {
        self.addNewCardHintInfoLabel.attributedText = [self p_attrStringWithPrefix:CJPayLocalizedStr(@"推荐") Text:CJPayLocalizedStr(@"「添加银行卡组合支付」") suffix:CJPayLocalizedStr(@"可免输卡号绑卡")];
    } else {
        self.addNewCardHintInfoLabel.attributedText = [self p_attrStringWithPrefix:CJPayLocalizedStr(@"推荐") Text:CJPayLocalizedStr(@"「添加银行卡」") suffix:CJPayLocalizedStr(@"继续支付")];
    }
    
    [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_getConfirmTitleV2Style]];
    [self.otherPayMethodButton cj_setBtnTitle:CJString(self.hintInfo.subButtonText)];
    
    self.titleLabel.text = [self p_getTitleText:self.hintInfo];
    self.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:18];
    self.discountLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:16];
    self.otherPayMethodButton.layer.borderColor = [UIColor cj_161823WithAlpha:0.5].CGColor;
    self.otherPayMethodButton.layer.borderWidth = 0.5;
    CJPayServerThemeStyle *serverThemeStyle = [CJPayThemeStyleManager shared].serverTheme; // 解决button圆角和主题圆角差异过大的问题
    self.otherPayMethodButton.layer.cornerRadius = serverThemeStyle ? serverThemeStyle.buttonStyle.cornerRadius : 8;
    self.otherPayMethodButton.titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:15];
    self.otherPayMethodButton.titleLabel.textColor = [UIColor cj_161823ff];
    
    CJPayMasReMaker(self.confirmPayBtn, {
        make.bottom.equalTo(self.otherPayMethodButton.mas_top).offset(-16);
        make.left.right.equalTo(self.otherPayMethodButton);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasReMaker(self.otherPayMethodButton, {
        make.left.right.equalTo(self).inset(24);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self.safeGuideView.mas_top).offset(-16);//有安全感图片
    });
    
    CJPayMasMaker(self.safeGuideView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.mas_bottom).offset(0);
        make.height.mas_equalTo(18);
    });
      
}

- (void)p_setupUIBalanceV2Style {
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self).offset(50);
    });
    
    CJPayMasUpdate(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
    });
}

- (void)p_setupUIFundPayV2Style {
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self).offset(50);
    });
    
    CJPayMasUpdate(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
    });
    
    if (Check_ValidArray(self.hintInfo.recPayType.payTypeData.voucherMsgList)) {
        self.discountLabel.hidden = NO;
        self.discountLabel.text = CJString(self.hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);;
        self.discountLabel.textColor = [UIColor cj_fe2c55ff]; //有营销，红色
        CJPayMasReMaker(self.discountLabel, {
            make.centerX.equalTo(self.addNewCardHintInfoLabel);
            make.left.mas_greaterThanOrEqualTo(self).offset(12);
            make.right.mas_lessThanOrEqualTo(self).offset(-12);
            make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(8);
        });
    }
}

- (void)p_setupUICombineV2Style {
    self.discountLabel.hidden = Check_ValidString(self.hintInfo.subStatusMsg);//这个字段下发，代表无营销
    
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self).offset(14);
    });
    
    CJPayMasUpdate(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
    });
    
    if (!self.discountLabel.hidden) {
        self.discountLabel.textColor = [UIColor cj_ff264aff];
        self.discountStr = self.hintInfo.recPayType.payTypeData.voucherMsgList.firstObject;
        self.discountLabel.text = self.discountStr;
        CJPayMasReMaker(self.discountLabel, {
            make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(8);
            make.centerX.equalTo(self);
        });
        
        CJPayMasReMaker(self.lineView, {
            make.top.equalTo(self.discountLabel.mas_bottom).offset(20);
            make.left.right.equalTo(self.confirmPayBtn);
            make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        });
        
        CJPayMasReMaker(self.combineDetailView, {
            make.top.equalTo(self.lineView).offset(17);
            make.left.right.equalTo(self.confirmPayBtn);
            make.height.mas_equalTo(42);
        });
    } else {
        CJPayMasUpdate(self.lineView, {
            make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(20);
        });
    }
}

- (void)p_setupUICreditV2Style {
    self.creditPayView.hidden = NO;
    self.newCardContentView.hidden = YES;
    self.addNewCardHintInfoLabel.hidden = YES;
    self.oldCardContentView.hidden = YES;
    
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self).offset(20);
    });
    
    CJPayMasReMaker(self.creditPayView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(40);
        make.left.equalTo(self.confirmPayBtn);
        make.right.equalTo(self);
        make.height.mas_equalTo(100);
    });
}

- (void)p_setupUICardV2Style {
    [self addSubview:self.bgCardView];
    [self addSubview:self.voucherTipsView];
    [self addSubview:self.voucherTipsLabel];
        
    self.discountLabel.hidden = NO;
    
    self.voucherTipsLabel.text = self.hintInfo.topRightDescText;

    if (Check_ValidArray(self.hintInfo.recPayType.payTypeData.voucherMsgList)) {
        self.discountStr = CJString(self.hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);
        self.discountLabel.text = self.discountStr;
        self.discountLabel.textColor = [UIColor cj_fe2c55ff];//有营销，红色
    } else {
        self.discountStr = @"";
        self.discountLabel.text = CJString(self.hintInfo.subStatusMsg);
        self.discountLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        self.discountLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:14];
        self.voucherTipsView.hidden = YES;
        self.voucherTipsLabel.hidden = YES;
    }
    
    CJPayMasUpdate(self.titleLabel, {
        make.top.equalTo(self).offset(14);
    });
    
    CJPayMasMaker(self.bgCardView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(28);
        make.height.mas_equalTo(100);
        make.left.right.equalTo(self).inset(24);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.voucherTipsView, {
        make.top.right.equalTo(self.bgCardView);
    });
    
    CJPayMasMaker(self.voucherTipsLabel, {
        make.top.equalTo(self.voucherTipsView).offset(2);
        make.bottom.equalTo(self.voucherTipsView).offset(-1);
        make.left.right.equalTo(self.voucherTipsView).inset(10);
    });
    
    CJPayMasReMaker(self.discountLabel, {
        make.centerX.equalTo(self.bgCardView);
        make.top.equalTo(self.addNewCardHintInfoLabel.mas_bottom).offset(8);
        make.bottom.equalTo(self.bgCardView.mas_bottom).offset(-24);
    });
    
    CJPayMasUpdate(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.bgCardView).offset(24);
    });
    
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self.voucherTipsView cj_customCorners:UIRectCornerTopRight | UIRectCornerBottomLeft radius:8];
}

- (void)p_setupCreditPayConstraints {
    CJPayMasReMaker(self.logoImageView, {
        make.top.equalTo(self).offset(36);
        make.width.height.mas_equalTo(60);
        make.centerX.equalTo(self);
    });
}

- (void)p_setupNewHalfNewCardConstraintsWithHintInfo:(CJPayHintInfo *)hintInfo {
    CJPayMasMaker(self.logoImageView, {
        make.top.equalTo(self).offset(hintInfo.recPayType.isCombinePay ? 40 : 80);
        make.width.height.mas_equalTo(60);
        make.centerX.equalTo(self);
    });
    
    CJPayMasReMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(hintInfo.recPayType.isCombinePay ? 20 : 24);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(16);
        make.right.lessThanOrEqualTo(self).offset(-16);
    });
    
    CJPayMasReMaker(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self).offset(hintInfo.recPayType.isCombinePay ? 156 : 204);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(24);
        make.right.lessThanOrEqualTo(self).offset(-24);
    });
}

- (void)p_setupUISuperPay {
    [self addSubview:self.payTypeLabel];
    self.creditPayView.hidden = YES;
    self.addNewCardHintInfoLabel.hidden = NO;
    CJPayMasReMaker(self.logoImageView, {
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(60);
        make.top.equalTo(self).offset(60);
    })
    
    CJPayMasReMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(16);
    });
    
    CJPayMasMaker(self.payTypeLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
    });
    
    CJPayMasReMaker(self.addNewCardHintInfoLabel, {
        make.top.equalTo(self.payTypeLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self);
    });
    
    if (self.hintInfo.recPayType.channelType == BDPayChannelTypeCreditPay) {
        [self p_asyncRefreshLabelWithHintInfoModel:self.hintInfo prefixStr:CJPayLocalizedStr(@"可授权 ") suffixStr:CJPayLocalizedStr(@"付款")];
    }
}

#pragma mark - click method
- (void)p_aboutButtonClick {
    CJPayButtonInfoViewController *vc = [CJPayButtonInfoViewController new];
    vc.buttonInfo = self.hintInfo.buttonInfo;
    [[UIViewController cj_topViewController].navigationController pushViewController:vc animated:YES];
}

#pragma mark - Getter
- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
        [_logoImageView cj_setImage:@"cj_sorry_icon"];
    }
    return _logoImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)discountLabel {
    if (!_discountLabel) {
        _discountLabel = [UILabel new];
        _discountLabel.textColor = [UIColor cj_ff7a38ff];
        _discountLabel.font = [UIFont cj_fontOfSize:14];
    }
    return _discountLabel;
}

- (UIView *)oldCardContentView {
    if (!_oldCardContentView) {
        _oldCardContentView = [UIView new];
    }
    return _oldCardContentView;
}

- (CJPayPayAgainOldCardCommonView *)oldCardView {
    if (!_oldCardView) {
        _oldCardView = [CJPayPayAgainOldCardCommonView new];
    }
    return _oldCardView;
}

- (UILabel *)oldCardBankTailLabel {
    if (!_oldCardBankTailLabel) {
        _oldCardBankTailLabel = [UILabel new];
        _oldCardBankTailLabel.textColor = [UIColor cj_161823ff];
        _oldCardBankTailLabel.font = [UIFont cj_fontOfSize:14];
        _oldCardBankTailLabel.text = CJPayLocalizedStr(@"继续支付?");
    }
    return _oldCardBankTailLabel;
}

- (CJPayPayAgainNewCardCommonView *)newCardContentView {
    if (!_newCardContentView) {
        _newCardContentView = [[CJPayPayAgainNewCardCommonView alloc] initWithType:CJPayNotSufficientNewCardCommonViewTypeNormal];
    }
    return _newCardContentView;
}

- (UILabel *)addNewCardHintInfoLabel {
    if (!_addNewCardHintInfoLabel) {
        _addNewCardHintInfoLabel = [UILabel new];
        _addNewCardHintInfoLabel.textColor = [UIColor cj_161823ff];
        _addNewCardHintInfoLabel.font = [UIFont cj_fontOfSize:14];
    }
    return _addNewCardHintInfoLabel;
}

- (CJPayStyleButton *)confirmPayBtn {
    if (!_confirmPayBtn) {
        _confirmPayBtn = [[CJPayStyleButton alloc] init];
        _confirmPayBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmPayBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
    }
    return _confirmPayBtn;
}

- (CJPayButton *)otherPayMethodButton {
    if (!_otherPayMethodButton) {
        _otherPayMethodButton = [CJPayButton new];
        [_otherPayMethodButton cj_setBtnTitleColor:[UIColor cj_161823ff]];
        _otherPayMethodButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
    }
    return _otherPayMethodButton;
}

- (CJPayPayAgainCreditPayView *)creditPayView {
    if (!_creditPayView) {
        _creditPayView = [CJPayPayAgainCreditPayView new];
    }
    return _creditPayView;
}

- (CJPayPayAgainDiscountView *)discountView {
    if (!_discountView) {
        _discountView = [CJPayPayAgainDiscountView new];
        _discountView.backgroundColor = [UIColor clearColor];
        _discountView.layer.cornerRadius = 4;
        _discountView.layer.masksToBounds = YES;
    }
    return _discountView;
}

- (CJPayCombineDetailView *)combineDetailView {
    if (!_combineDetailView) {
        _combineDetailView = [[CJPayCombineDetailView alloc] init];
    }
    return _combineDetailView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = [UIColor cj_161823WithAlpha:0.12];
    }
    return _lineView;
}

- (UIImageView *)infoImgView {
    if (!_infoImgView) {
        _infoImgView = [UIImageView new];
        [_infoImgView cj_setImage:@"cj_income_pay_about_icon"];
        _infoImgView.userInteractionEnabled = YES;
        [_infoImgView cj_viewAddTarget:self
                                action:@selector(p_aboutButtonClick)
                      forControlEvents:UIControlEventTouchUpInside];
    }
    return _infoImgView;
}

- (UIView *)bgCardView {
    if (!_bgCardView) {
        _bgCardView = [UIView new];
        _bgCardView.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.08];
        _bgCardView.layer.cornerRadius = 8;
        _bgCardView.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.5].CGColor;
        _bgCardView.layer.borderWidth = 0.5;
    }
    return _bgCardView;
}

- (UIView *)voucherTipsView {
    if (!_voucherTipsView) {
        _voucherTipsView = [UIView new];
        _voucherTipsView.backgroundColor = [UIColor cj_fe2c55ff];
    }
    return _voucherTipsView;
}

- (UILabel *)voucherTipsLabel {
    if (!_voucherTipsLabel) {
        _voucherTipsLabel = [UILabel new];
        _voucherTipsLabel.textColor = [UIColor whiteColor];
        _voucherTipsLabel.font = [UIFont cj_fontOfSize:11];
    }
    return _voucherTipsLabel;
}

- (CJPayAccountInsuranceTipView *)safeGuideView {
    if (!_safeGuideView) {
        _safeGuideView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuideView;
}

- (UILabel *)payTypeLabel {
    if (!_payTypeLabel) {
        _payTypeLabel = [UILabel new];
        _payTypeLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:12];
        _payTypeLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _payTypeLabel.text = self.hintInfo.failPayTypeMsg;
    }
    return _payTypeLabel;
}

- (NSString *)p_getTitleText:(CJPayHintInfo *)hintInfo {
    return Check_ValidString(CJString(hintInfo.titleMsg)) ? CJString(hintInfo.titleMsg) : CJString(hintInfo.statusMsg);
}

@end
