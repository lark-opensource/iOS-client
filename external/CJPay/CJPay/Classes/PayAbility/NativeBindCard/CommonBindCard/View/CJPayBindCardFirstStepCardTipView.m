//
//  CJPayBindCardFirstStepCardTipView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import "CJPayBindCardFirstStepCardTipView.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayVoucherBankInfo.h"

#import <BDWebImage/BDWebImage.h>

@interface CJPayBindCardFirstStepCardTipView()

#pragma mark - view
@property (nonatomic, strong) UIImageView *cardIconImageView;
@property (nonatomic, strong) UILabel *cardNameLabel;
@property (nonatomic, strong) CJPayMethodCellTagView *mainVoucherView;
@property (nonatomic, strong) CJPayMethodCellTagView *subVoucherView;
@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) MASConstraint *mainVoucherViewLeftAlighCardNameLabelConstraint;
@property (nonatomic, strong) MASConstraint *mainVoucherViewLeftAlighViewConstraint;

@end

@implementation CJPayBindCardFirstStepCardTipView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
        [self p_updateViewStyle];
    }
    return self;
}

- (void)setupUI {
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.cardIconImageView];
    [self addSubview:self.cardNameLabel];
    [self addSubview:self.mainVoucherView];
    [self addSubview:self.subVoucherView];
    
    [self addSubview:self.tipsLabel];
    
    CJPayMasMaker(self.cardIconImageView, {
        make.left.equalTo(self);
        make.centerY.equalTo(self.cardNameLabel);
        make.size.mas_equalTo(CGSizeMake(13, 13));
    });
    
    CJPayMasMaker(self.cardNameLabel, {
        make.top.greaterThanOrEqualTo(self);
        make.left.equalTo(self.cardIconImageView.mas_right).offset(2);
        make.right.lessThanOrEqualTo(self.mainVoucherView.mas_left);
        make.centerY.equalTo(self);
    });
    [self.cardNameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.mainVoucherView, {
        self.mainVoucherViewLeftAlighCardNameLabelConstraint =  make.left.equalTo(self.cardNameLabel.mas_right).offset(4);
        self.mainVoucherViewLeftAlighViewConstraint = make.left.equalTo(self);
        make.right.lessThanOrEqualTo(self);
        make.height.mas_equalTo(16);
        make.centerY.equalTo(self);
    });
        
    [self.mainVoucherViewLeftAlighCardNameLabelConstraint deactivate];
    [self.mainVoucherViewLeftAlighViewConstraint activate];
    
    CJPayMasMaker(self.subVoucherView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.mainVoucherView.mas_right).offset(8);
        make.height.mas_equalTo(16);
        make.right.lessThanOrEqualTo(self);
    })
        
    CJPayMasMaker(self.tipsLabel, {
        make.top.greaterThanOrEqualTo(self);
        make.bottom.lessThanOrEqualTo(self);
        make.left.equalTo(self);
        make.right.lessThanOrEqualTo(self);
    });
}

- (void)updateWithBankInfoModel:(CJPayMemBankInfoModel *)infoModel {
    NSString *cardName = CJString(infoModel.bankName);
    NSString *cardTypeStr = CJString(infoModel.cardType);
    self.mainVoucherView.hidden = YES;
    self.subVoucherView.hidden = YES;
    
    CJPayBindCardVoucherInfo *voucherInfo = nil;
    if ([infoModel.cardType isEqualToString:@"CREDIT"]) {
        voucherInfo = infoModel.creditBindCardVoucherInfo;
    } else if ([infoModel.cardType isEqualToString:@"DEBIT"]) {
        voucherInfo = infoModel.debitBindCardVoucherInfo;
    }
    NSString *voucherStr = Check_ValidString(voucherInfo.binVoucherMsg) ? voucherInfo.binVoucherMsg : voucherInfo.voucherMsg;
    NSString *iconUrl = CJString(infoModel.iconURL);
    
    self.hidden = NO;
    self.tipsLabel.hidden = YES;
    self.cardIconImageView.hidden = NO;
    self.cardNameLabel.hidden = NO;
    
    NSString *cardTypeName = [cardTypeStr.uppercaseString isEqualToString:@"CREDIT"] ? CJPayLocalizedStr(@"信用卡") : CJPayLocalizedStr(@"储蓄卡");
    
    self.cardNameLabel.text = [NSString stringWithFormat:@"%@%@", cardName, cardTypeName];
    [self.mainVoucherViewLeftAlighViewConstraint deactivate];
    [self.mainVoucherViewLeftAlighCardNameLabelConstraint activate];
    
    [self.mainVoucherView updateTitle:voucherStr];
    [self.cardIconImageView cj_setImageWithURL:[NSURL URLWithString:iconUrl]
                                   placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
}

- (BOOL)isShowContent {
    BOOL showCard = self.cardNameLabel.hidden == NO && Check_ValidString(self.cardNameLabel.text);
    BOOL showMainVoucher = self.mainVoucherView.hidden == NO && Check_ValidString(self.mainVoucherView.titleLabel.text);
    BOOL showSubVoucher = self.subVoucherView.hidden == NO && Check_ValidString(self.subVoucherView.titleLabel.text);
    BOOL showTips = self.tipsLabel.hidden == NO && Check_ValidString(self.tipsLabel.text);
    BOOL isShowContent = showCard || showMainVoucher || showSubVoucher || showTips;
    return self.hidden == NO && isShowContent;
}

- (void)updateTipsWithSupportListResponse:(CJPayMemBankSupportListResponse *)response {
    self.tipsLabel.hidden = YES;
    self.cardIconImageView.hidden = YES;
    
    NSString *voucherBank = response.voucherBankInfo.voucherBank;
    NSString *cardVoucherMsg = response.voucherBankInfo.cardVoucherMsg;
    NSString *cardBinVoucherMsg = response.voucherBankInfo.cardBinVoucherMsg;
    
    if (Check_ValidString(cardVoucherMsg) && Check_ValidString(cardBinVoucherMsg)) {
        [self.mainVoucherView updateTitle:cardVoucherMsg];
        if ([self p_fitDownSubVoucherWithBank:voucherBank mainVoucher:cardVoucherMsg subVoucher:cardBinVoucherMsg]) {
            [self.subVoucherView updateTitle:cardBinVoucherMsg];
        }
    } else if (Check_ValidString(cardVoucherMsg)) {
        [self.mainVoucherView updateTitle:cardVoucherMsg];
    } else if (Check_ValidString(cardBinVoucherMsg)) {
        [self.mainVoucherView updateTitle:cardBinVoucherMsg];
    } else if (Check_ValidString(response.voucherMsg)) {
        [self.mainVoucherView updateTitle:response.voucherMsg];
        [self.mainVoucherViewLeftAlighCardNameLabelConstraint deactivate];
        [self.mainVoucherViewLeftAlighViewConstraint activate];
    }
    
    if (Check_ValidString(voucherBank) &&
        (Check_ValidString(cardVoucherMsg) || Check_ValidString(cardBinVoucherMsg))) {
        self.cardNameLabel.hidden = NO;
        self.cardIconImageView.hidden = NO;
        [self.cardIconImageView cj_setImageWithURL:[NSURL URLWithString:response.voucherBankInfo.iconUrl]];
        [self.mainVoucherViewLeftAlighCardNameLabelConstraint activate];
        [self.mainVoucherViewLeftAlighViewConstraint deactivate];
        self.cardNameLabel.text = CJString(voucherBank);
    }
}

- (BOOL)p_fitDownSubVoucherWithBank:(NSString *)bankName mainVoucher:(NSString *)mainVoucher subVoucher:(NSString *)subVoucher {
    CGFloat intervalWidth = 13 + 2 + 4 + 8;//图片宽度+每个view中间的间距
    intervalWidth = intervalWidth + 6 * 2;//两个voucherView边框间距
    CGFloat bankNameWidth = [bankName sizeWithAttributes:@{NSFontAttributeName:self.cardNameLabel.font}].width;
    CGFloat mainVoucherWidth = [mainVoucher sizeWithAttributes:@{NSFontAttributeName:self.mainVoucherView.titleLabel.font}].width;
    CGFloat subVoucherWidth = [subVoucher sizeWithAttributes:@{NSFontAttributeName:self.subVoucherView.titleLabel.font}].width;
    
    return intervalWidth + bankNameWidth + mainVoucherWidth + subVoucherWidth < self.cj_width;
}


- (void)updateCardTipsWithQuickBindCardModel:(CJPayQuickBindCardModel *)model {
    if (!Check_ValidString(model.voucherMsg)) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    self.tipsLabel.hidden = YES;
    self.cardNameLabel.hidden = NO;
    self.cardIconImageView.hidden = NO;
    self.mainVoucherView.hidden = NO;
    self.subVoucherView.hidden = YES;
    
    NSString *bankName = model.bankName;
    if ([model.selectedCardType isEqualToString:@"CREDIT"]) {
        bankName = [NSString stringWithFormat:@"%@%@", bankName, CJPayLocalizedStr(@"信用卡")];
    } else if ([model.selectedCardType isEqualToString:@"DEBIT"]) {
        bankName = [NSString stringWithFormat:@"%@%@", bankName, CJPayLocalizedStr(@"储蓄卡")];
    }
    
    self.cardNameLabel.text = CJString(bankName);
    [self.cardIconImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.iconUrl)]];
    [self.mainVoucherView updateTitle:CJString(model.voucherMsg)];
    
    [self.mainVoucherViewLeftAlighViewConstraint deactivate];
    [self.mainVoucherViewLeftAlighCardNameLabelConstraint activate];
}

- (void)updateTips:(NSString *)tipsText withColor:(UIColor *)color {
    [self updateTips:tipsText];
    self.tipsLabel.textColor = color;
}

- (void)updateTips:(NSString *)tipsText {
    self.hidden = NO;
    self.tipsLabel.hidden = NO;
    self.cardIconImageView.hidden = YES;
    self.cardNameLabel.hidden = YES;
    self.mainVoucherView.hidden = YES;
    self.subVoucherView.hidden = YES;
    
    self.tipsLabel.text = CJPayLocalizedStr(tipsText);
    self.tipsLabel.textColor = [UIColor cj_fe3824ff];
}

#pragma mark - private method
- (void)p_updateViewStyle {
    CGFloat fontSize = 12;
    self.cardNameLabel.font = [UIFont cj_fontOfSize:fontSize];
    self.tipsLabel.font = [UIFont cj_fontOfSize:fontSize];
}

#pragma mark - getter & setter
- (UIImageView *)cardIconImageView {
    if (!_cardIconImageView) {
        _cardIconImageView = [UIImageView new];
    }
    return _cardIconImageView;
}

- (UILabel *)cardNameLabel {
    if (!_cardNameLabel) {
        _cardNameLabel = [UILabel new];
        _cardNameLabel.textColor = [UIColor cj_161823ff];
        _cardNameLabel.font = [UIFont cj_fontOfSize:12];
        _cardNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _cardNameLabel;
}

- (CJPayMethodCellTagView *)mainVoucherView {
    if (!_mainVoucherView) {
        _mainVoucherView = [[CJPayMethodCellTagView alloc] init];
        _mainVoucherView.hidden = YES;
    }
    return _mainVoucherView;
}

- (CJPayMethodCellTagView *)subVoucherView {
    if (!_subVoucherView) {
        _subVoucherView = [[CJPayMethodCellTagView alloc] init];
        _subVoucherView.hidden = YES;
    }
    return _subVoucherView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.textColor = [UIColor cj_fe3824ff];
        _tipsLabel.font = [UIFont cj_boldFontOfSize:12];
    }
    return _tipsLabel;
}

@end
