//
//  CJPayQuickBindCardTypeChooseView.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import "CJPayQuickBindCardTypeChooseView.h"

#import "CJPayQuickBindCardTypeChooseItemView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayBindCardVoucherInfo.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayBindCardManager.h"

@interface CJPayQuickBindCardTypeChooseView()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *iconBackgroundView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *bankNameLabel;
@property (nonatomic, strong) UILabel *addOtherbankCard;
@property (nonatomic, strong) UIView *chooseView;//两个选择cell的外边框
@property (nonatomic, strong) CJPayQuickBindCardTypeChooseItemView *debitCardView;
@property (nonatomic, strong) CJPayQuickBindCardTypeChooseItemView *creditCardView;
@property (nonatomic, strong, readwrite) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong, readwrite) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) UILabel *chooseTitleLabel;

@property (nonatomic, copy) NSString *debitVoucher;
@property (nonatomic, copy) NSString *creditVoucher;

@property (nonatomic, assign) BOOL isDebitJumpInputCard;  //储蓄卡是否支持跳到绑卡首页
@property (nonatomic, assign) BOOL isCreditCardJumpInputCard;  //储蓄卡是否支持跳到绑卡首页

@end

@implementation CJPayQuickBindCardTypeChooseView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (NSString *)p_concatFrontStr:(NSString *)frontStr andTailStr:(NSString *)tailStr {
    if (Check_ValidString(frontStr) && Check_ValidString(tailStr)) {
        if ([frontStr isEqualToString:tailStr]) {
            return frontStr;
        } else {
            return [NSString stringWithFormat:@"%@，%@", frontStr, tailStr];
        }
    } else if(Check_ValidString(frontStr)) {
        return frontStr;
    } else {
        return CJString(tailStr);
    }
}

- (NSString *)p_voucherWithModel:(CJPayQuickBindCardModel *)quickBindCardModel andIsDebit:(BOOL)isDebit {
    if (isDebit) {
        return [self p_concatFrontStr:quickBindCardModel.debitBindCardVoucherInfo.voucherMsg
                           andTailStr:quickBindCardModel.debitBindCardVoucherInfo.binVoucherMsg];
    } else {
        return [self p_concatFrontStr:quickBindCardModel.creditBindCardVoucherInfo.voucherMsg
                           andTailStr:quickBindCardModel.creditBindCardVoucherInfo.binVoucherMsg];
    }
}

- (void)reloadWithQuickBindCardModel:(CJPayQuickBindCardModel *)quickBindCardModel
{
    [self resetViewData];
    self.bankNameLabel.text = quickBindCardModel.bankName;
    [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:quickBindCardModel.iconUrl]];
    [self.bgImageView cj_setImageWithURL:[NSURL URLWithString:quickBindCardModel.backgroundUrl]];
    if ([quickBindCardModel.cardType isEqualToString:@"ALL"]) { //同时支持储蓄卡和信用卡
        [self p_bothCardSupport:quickBindCardModel];
    } else if ([quickBindCardModel.cardType isEqualToString:@"DEBIT"]) { //只支持储蓄卡
        [self p_onlyForDebit:quickBindCardModel];
    } else if ([quickBindCardModel.cardType isEqualToString:@"CREDIT"]) { //只支持信用卡
        [self p_onlyForCredit:quickBindCardModel];
    }
}

- (void)resetViewData {
    self.debitCardView.enable = YES;
    self.creditCardView.enable = YES;
    
    self.debitCardView.selected = NO;
    self.creditCardView.selected = NO;
    
    self.isDebitJumpInputCard = NO;
    self.isCreditCardJumpInputCard = NO;
    
    [self.creditCardView updateVoucherStr:@""];
    [self.debitCardView updateVoucherStr:@""];
    
    [self.debitCardView updateTitle:CJPayLocalizedStr(@"储蓄卡") withColor:[UIColor cj_222222ff]];
    [self.creditCardView updateTitle:CJPayLocalizedStr(@"信用卡") withColor:[UIColor cj_222222ff]];
    
    self.debitVoucher = @"";
    self.creditVoucher = @"";
}

- (void)p_bothCardSupport:(CJPayQuickBindCardModel *)quickBindCardModel {
    [self.debitCardView updateTitle:CJPayLocalizedStr(@"储蓄卡")];
    self.debitVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:YES];
    [self.debitCardView updateVoucherStr:CJString(self.debitVoucher)];
    self.debitCardView.enable = YES;
    [self.debitCardView showInputHintLabel:NO];

    [self.creditCardView updateTitle:CJPayLocalizedStr(@"信用卡")];
    self.creditVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:NO];
    [self.creditCardView updateVoucherStr:CJString(self.creditVoucher)];
    self.creditCardView.enable = YES;
    [self.creditCardView showInputHintLabel:NO];

    if ([quickBindCardModel.selectedCardType isEqualToString:@"CREDIT"]) {
        self.debitCardView.selected = NO;
        self.creditCardView.selected = YES;
    } else {
        self.debitCardView.selected = YES;
        self.creditCardView.selected = NO;
    }
}

- (void)p_onlyForDebit:(CJPayQuickBindCardModel *)quickBindCardModel {
    [self.debitCardView updateTitle:CJPayLocalizedStr(@"储蓄卡")];
    self.debitVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:YES];
    [self.debitCardView updateVoucherStr:CJString(self.debitVoucher)];
    self.debitCardView.enable = YES;
    self.debitCardView.selected = YES;
    
    self.creditCardView.enable = NO;
    self.creditCardView.selected = NO;

    if ([quickBindCardModel.jumpBankType isEqualToString:@"CREDIT"]) {
        [self.creditCardView showInputHintLabel:YES];
        self.creditVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:NO];
        [self.creditCardView updateVoucherStr:self.creditVoucher];
        self.isCreditCardJumpInputCard = YES;
    } else {
        [self.creditCardView showInputHintLabel:NO];
        [self.creditCardView updateVoucherStr:@""];
        [self.creditCardView updateTitle:CJPayLocalizedStr(@"暂不支持信用卡") withColor:[UIColor cj_161823WithAlpha:0.34]];
    }
}

- (void)p_onlyForCredit:(CJPayQuickBindCardModel *)quickBindCardModel {
    [self.creditCardView updateTitle:CJPayLocalizedStr(@"信用卡")];
    self.creditVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:NO];
    [self.creditCardView updateVoucherStr:CJString(self.creditVoucher)];
    self.creditCardView.enable = YES;
    self.creditCardView.selected = YES;
    
    self.debitCardView.enable = NO;
    self.debitCardView.selected = NO;

    if ([quickBindCardModel.jumpBankType isEqualToString:@"DEBIT"]) {
        [self.debitCardView showInputHintLabel:YES];
        self.debitVoucher = [self p_voucherWithModel:quickBindCardModel andIsDebit:YES];
        [self.debitCardView updateVoucherStr:self.debitVoucher];
        self.isDebitJumpInputCard = YES;
    } else {
        [self.debitCardView showInputHintLabel:NO];
        [self.debitCardView updateVoucherStr:@""];
        [self.debitCardView updateTitle:CJPayLocalizedStr(@"暂不支持储蓄卡") withColor:[UIColor cj_161823WithAlpha:0.34]];
    }
}

- (NSString *)currentSelectedCardType
{
    if (self.debitCardView.selected) {
        return @"DEBIT";
    } else if (self.creditCardView.selected) {
        return @"CREDIT";
    }
    return @"";
}

- (NSString *)currentSelectedCardVoucher
{
    if (self.debitCardView.selected) {
        return self.debitVoucher;
    } else if (self.creditCardView.selected) {
        return self.creditVoucher;
    }
    return @"";
}

- (void)updateUIWithoutProtocol {
    CJPayMasReMaker(self.confirmButton, {
        make.top.equalTo(self.creditCardView.mas_bottom).offset(36);
        make.left.equalTo(self.chooseView).offset(16);
        make.right.equalTo(self.chooseView).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.bottom.equalTo(self.chooseView.mas_bottom).offset(-20);
    });
}

- (void)p_setupUI {
    [self addSubview:self.chooseView];
    [self.chooseView addSubview:self.bgImageView];
    [self.chooseView addSubview:self.bankNameLabel];
    [self.chooseView addSubview:self.debitCardView];
    [self.chooseView addSubview:self.creditCardView];
    [self.chooseView addSubview:self.protocolView];
    [self.chooseView addSubview:self.confirmButton];
    [self.chooseView addSubview:self.iconBackgroundView];
    [self.chooseView addSubview:self.iconImageView];
    
    CJPayMasMaker(self.chooseView, {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    });
    
    CJPayMasMaker(self.bankNameLabel, {
        make.left.equalTo(self.chooseView).offset(56);
        make.top.equalTo(self.chooseView).offset(15);
        make.right.lessThanOrEqualTo(self.chooseView).offset(-16);
        make.height.equalTo(@22);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.left.equalTo(self.chooseView).offset(20);
        make.top.equalTo(self.chooseView).offset(14);
        make.width.height.equalTo(@24);
    });
    
    CJPayMasMaker(self.iconBackgroundView, {
        make.left.equalTo(self.chooseView).offset(16);
        make.top.equalTo(self.chooseView).offset(10);
        make.width.height.equalTo(@32);
    });
    
    CJPayMasMaker(self.bgImageView, {
        make.left.right.top.equalTo(self.chooseView);
        make.height.equalTo(@52);
    });
    
    CJPayMasMaker(self.debitCardView, {
        make.top.equalTo(self).offset(76);
        make.left.equalTo(self.chooseView).offset(16);
        make.right.equalTo(self.chooseView).offset(-16);
    });
    
    CJPayMasMaker(self.creditCardView, {
        make.top.equalTo(self.debitCardView.mas_bottom).offset(12);
        make.left.equalTo(self.chooseView).offset(16);
        make.right.equalTo(self.chooseView).offset(-16);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.creditCardView.mas_bottom).offset(36);
        make.left.equalTo(self.chooseView).offset(16);
        make.right.equalTo(self.chooseView).offset(-16);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(12);
        make.left.equalTo(self.chooseView).offset(16);
        make.right.equalTo(self.chooseView).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.bottom.equalTo(self.chooseView.mas_bottom).offset(-20);
    });
}

- (void)p_didSelected {
    CJ_CALL_BLOCK(self.didSelectedAddOtherCardBlock);
}

- (void)p_confirmButtonTapped
{
    CJ_DelayEnableView(self.confirmButton);
    CJ_CALL_BLOCK(self.confirmButtonClickBlock);
}

- (void)p_debitCardViewDidTap {
    if (self.isDebitJumpInputCard) {
        CJ_CALL_BLOCK(self.inputCardClickBlock, self.debitVoucher, @"DEBIT"); //跳转输入卡号页
        return;
    }
    if (!self.debitCardView.enable || self.debitCardView.selected) {
        return;
    }
    
    self.debitCardView.selected = YES;
    self.creditCardView.selected = NO;
    
    if (self.didSelectedCardTypeBlock) {
        CJ_DelayEnableView(self.debitCardView);
        CJ_CALL_BLOCK(self.didSelectedCardTypeBlock);
    }
}

- (void)p_creditCardViewDidTap {
    if (self.isCreditCardJumpInputCard) {
        CJ_CALL_BLOCK(self.inputCardClickBlock, self.creditVoucher, @"CREDIT"); //跳转输入卡号页
        return;
    }
    if (!self.creditCardView.enable || self.creditCardView.selected) {
        return;
    }
    
    self.creditCardView.selected = YES;
    self.debitCardView.selected = NO;

    if (self.didSelectedCardTypeBlock) {
        CJ_DelayEnableView(self.creditCardView);
        CJ_CALL_BLOCK(self.didSelectedCardTypeBlock);
    }
}

#pragma mark - Lazy Views

- (UIView *)chooseView {
    if (!_chooseView) {
        _chooseView = [UIView new];
        _chooseView.layer.cornerRadius = 8;
        _chooseView.backgroundColor = [UIColor whiteColor];
        _chooseView.clipsToBounds = YES;
    }
    return _chooseView;
}

- (UILabel *)chooseTitleLabel {
    if (!_chooseTitleLabel) {
        _chooseTitleLabel = [UILabel new];
        _chooseTitleLabel.text = CJPayLocalizedStr(@"选择卡类型");
        _chooseTitleLabel.font = [UIFont cj_boldFontOfSize:14];
        _chooseTitleLabel.textColor = [UIColor cj_161823ff];
        
    }
    return _chooseTitleLabel;
}

- (UIImageView *)backgroundImageView
{
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
        _backgroundImageView.backgroundColor = [UIColor grayColor];
        _backgroundImageView.layer.cornerRadius = 5;
        _backgroundImageView.clipsToBounds = YES;
    }
    return _backgroundImageView;
}

- (UIView *)iconBackgroundView
{
    if (!_iconBackgroundView) {
        _iconBackgroundView = [UIView new];
        _iconBackgroundView.backgroundColor = [UIColor cj_colorWithHexString:@"#ffffff" alpha:0.9];
        _iconBackgroundView.layer.cornerRadius = 16;
        _iconBackgroundView.clipsToBounds = YES;
    }
    return _iconBackgroundView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UIImageView *)bgImageView
{
    if (!_bgImageView) {
        _bgImageView = [UIImageView new];
        _bgImageView.alpha = 0.17;
        _bgImageView.clipsToBounds = YES;
    }
    return _bgImageView;
}

- (UILabel *)bankNameLabel
{
    if (!_bankNameLabel) {
        _bankNameLabel = [UILabel new];
        _bankNameLabel.textColor = [UIColor cj_161823ff];
        _bankNameLabel.font = [UIFont cj_boldFontOfSize:14];
    }
    return _bankNameLabel;
}

- (CJPayQuickBindCardTypeChooseItemView *)debitCardView
{
    if (!_debitCardView) {
        _debitCardView = [[CJPayQuickBindCardTypeChooseItemView alloc] initWithFrame:CGRectZero];
        [_debitCardView updateTitle:CJPayLocalizedStr(@"储蓄卡")];
        [_debitCardView cj_viewAddTarget:self
                                  action:@selector(p_debitCardViewDidTap)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _debitCardView;
}

- (CJPayQuickBindCardTypeChooseItemView *)creditCardView
{
    if (!_creditCardView) {
        _creditCardView = [[CJPayQuickBindCardTypeChooseItemView alloc] initWithFrame:CGRectZero];
        [_creditCardView updateTitle:CJPayLocalizedStr(@"信用卡")];
        [_creditCardView cj_viewAddTarget:self
                                  action:@selector(p_creditCardViewDidTap)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _creditCardView;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        [_confirmButton setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton addTarget:self action:@selector(p_confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UILabel *)addOtherbankCard {
    if (! _addOtherbankCard) {
        _addOtherbankCard = [UILabel new];
        _addOtherbankCard.textColor = [UIColor cj_161823ff];
        _addOtherbankCard.font = [UIFont cj_fontOfSize:13];
        _addOtherbankCard.textAlignment = NSTextAlignmentCenter;
        _addOtherbankCard.text = CJPayLocalizedStr(@"添加其他银行 或 手动输入卡号");
        [_addOtherbankCard cj_viewAddTarget:self action:@selector(p_didSelected) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addOtherbankCard;
}
@end
