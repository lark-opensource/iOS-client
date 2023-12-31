//
//  CJPayPayAgainPopUpView.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainPopUpView.h"

#import "CJPayPayAgainOldCardCommonView.h"
#import "CJPayPayAgainNewCardCommonView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"

@interface CJPayPayAgainPopUpView()

@property (nonatomic, strong) CJPayButton *closeBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayPayAgainNewCardCommonView *newCardContentView;
@property (nonatomic, strong) CJPayPayAgainOldCardCommonView *oldCardContentView;
@property (nonatomic, strong) UILabel *oldCardDiscountLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong) CJPayButton *otherPayMethodButton;

@property (nonatomic, strong) MASConstraint *confirmButtonTopBaseOldCardBottomConstraint;
@property (nonatomic, strong) MASConstraint *confirmButtonTopBaseNewCardBottomConstraint;

@end

@implementation CJPayPayAgainPopUpView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo {
    self.titleLabel.text = [self p_getTitleText:hintInfo];
    [self.confirmPayBtn cj_setBtnTitle:CJString(hintInfo.buttonText)];
    [self.otherPayMethodButton cj_setBtnTitle:CJString(hintInfo.subButtonText)];
    
    if (hintInfo.recPayType.channelType == BDPayChannelTypeAddBankCard && hintInfo.recPayType.payTypeData.recommendType != 1) { //添加新卡
        self.oldCardContentView.hidden = YES;
        self.oldCardDiscountLabel.hidden = YES;
        self.newCardContentView.hidden = NO;

        [self.newCardContentView refreshWithHintInfo:hintInfo];
        
        [self.confirmButtonTopBaseOldCardBottomConstraint deactivate];
        [self.confirmButtonTopBaseNewCardBottomConstraint activate];
        
    } else { // 老卡|余额|常用卡
        self.oldCardContentView.hidden = NO;
        self.oldCardDiscountLabel.hidden = NO;
        self.newCardContentView.hidden = YES;
        
        [self.oldCardContentView.bankIconImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.recPayType.iconUrl]];
        self.oldCardContentView.bankLabel.text = CJString(hintInfo.recPayType.title);
        if (hintInfo.recPayType.payTypeData.recommendType == 1) {  // 微信常用卡
            self.oldCardContentView.bankPreLabel.text = CJPayLocalizedStr(@"推荐添加");
            self.oldCardContentView.bankLabel.text = [NSString stringWithFormat:@"%@支付",CJString(hintInfo.recPayType.title)];
        }
        self.oldCardDiscountLabel.attributedText = [self p_getAttributeStringWithHintInfo:hintInfo];
        
        [self.confirmButtonTopBaseNewCardBottomConstraint deactivate];
        [self.confirmButtonTopBaseOldCardBottomConstraint activate];
    }
}

- (NSAttributedString *)p_getAttributeStringWithHintInfo:(CJPayHintInfo *)hintInfo {
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paraStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *descAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823ff],
                                     NSParagraphStyleAttributeName : paraStyle,
    };
    
    NSDictionary *discountAttributes = @{NSFontAttributeName : [UIFont cj_boldFontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_ff7a38ff],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"继续支付？") attributes:descAttributes];
    
    NSString *discountStr = CJString(hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);
    if (hintInfo.recPayType.channelType == BDPayChannelTypeAddBankCard && hintInfo.recPayType.payTypeData.recommendType == 1) {
        attributeStr = [[NSMutableAttributedString alloc] initWithString:discountStr attributes:discountAttributes];
    } else {
        [attributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:discountStr attributes:discountAttributes]];
    }
    
    return [attributeStr copy];
}

- (void)p_setupUI {
    
    [self addSubview:self.closeBtn];
    [self addSubview:self.titleLabel];
    [self addSubview:self.newCardContentView];
    [self addSubview:self.oldCardContentView];
    [self addSubview:self.oldCardDiscountLabel];
    [self addSubview:self.confirmPayBtn];
    [self addSubview:self.otherPayMethodButton];
    
    CJPayMasMaker(self.closeBtn, {
        make.top.equalTo(self).offset(12);
        make.left.equalTo(self).offset(12);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(40);
        make.left.mas_greaterThanOrEqualTo(self).offset(20);
        make.right.mas_lessThanOrEqualTo(self).offset(-20);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.oldCardContentView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.left.greaterThanOrEqualTo(self).offset(20);
        make.right.lessThanOrEqualTo(self).offset(-20);
        make.centerX.equalTo(self);
    });
    CJPayMasMaker(self.oldCardDiscountLabel, {
        make.top.equalTo(self.oldCardContentView.mas_bottom).offset(2);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(20);
        make.right.lessThanOrEqualTo(self).offset(-20);
    });
    CJPayMasMaker(self.newCardContentView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.left.greaterThanOrEqualTo(self).offset(28);
        make.right.lessThanOrEqualTo(self).offset(-28);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.confirmPayBtn, {
        self.confirmButtonTopBaseNewCardBottomConstraint = make.top.equalTo(self.newCardContentView.mas_bottom).offset(24);
        self.confirmButtonTopBaseOldCardBottomConstraint = make.top.equalTo(self.oldCardDiscountLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })
    
    CJPayMasMaker(self.otherPayMethodButton, {
        make.top.equalTo(self.confirmPayBtn.mas_bottom).offset(13);
        make.bottom.equalTo(self).offset(-18);
        make.left.right.equalTo(self.confirmPayBtn);
        make.height.mas_equalTo(18);
    })
    
    self.newCardContentView.hidden = YES;
    [self.confirmButtonTopBaseNewCardBottomConstraint deactivate];
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (CJPayPayAgainNewCardCommonView *)newCardContentView {
    if (!_newCardContentView) {
        _newCardContentView = [[CJPayPayAgainNewCardCommonView alloc] initWithType:CJPayNotSufficientNewCardCommonViewTypeCompact];
    }
    return _newCardContentView;
}

- (CJPayPayAgainOldCardCommonView *)oldCardContentView {
    if (!_oldCardContentView) {
        _oldCardContentView = [CJPayPayAgainOldCardCommonView new];
    }
    return _oldCardContentView;
}

- (UILabel *)oldCardDiscountLabel {
    if (!_oldCardDiscountLabel) {
        _oldCardDiscountLabel = [UILabel new];
        _oldCardDiscountLabel.font = [UIFont cj_boldFontOfSize:14];
        _oldCardDiscountLabel.textAlignment = NSTextAlignmentCenter;
        _oldCardDiscountLabel.numberOfLines = 0;
    }
    return _oldCardDiscountLabel;
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
        [_otherPayMethodButton cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.6]];
        _otherPayMethodButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
    }
    return _otherPayMethodButton;
}


- (CJPayButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [CJPayButton new];
        [_closeBtn cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
    }
    return _closeBtn;
}

- (NSString *)p_getTitleText:(CJPayHintInfo *)hintInfo {
    return Check_ValidString(CJString(hintInfo.titleMsg)) ? CJString(hintInfo.titleMsg) : CJString(hintInfo.statusMsg);
}

@end
