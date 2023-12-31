//
//  CJPaySkipPwdConfirmHalfPageView.m
//  Aweme
//
//  Created by 陈博成 on 2023/5/21.
//

#import "CJPaySkipPwdConfirmHalfPageView.h"
#import "CJPayButton.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayCombineDetailView.h"
#import "CJPayUIMacro.h"

@interface CJPaySkipPwdConfirmHalfPageView ()

@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong) CJPayStyleCheckBox *checkBox;
@property (nonatomic, strong) UILabel *checkDescLabel;
@property (nonatomic, strong) UIView *checkContentView;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *confirmInfo;

@end

@implementation CJPaySkipPwdConfirmHalfPageView

- (instancetype)initWithModel:(CJPaySecondaryConfirmInfoModel *)model {
    self = [super init];
    if (self) {
        self.confirmInfo = model;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.checkContentView];
    [self addSubview:self.confirmPayBtn];
    
    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.equalTo(@44);
        make.top.equalTo(self.checkContentView.mas_bottom).offset(16);
    })
    
    CJPayMasMaker(self, {
        make.bottom.equalTo(self.confirmPayBtn).offset(16);
    })
    
    if ([self.confirmInfo.style isEqualToString:@"V4"]) {
        [self p_setupUIForV4];
        return;
    }
    if ([self.confirmInfo.style isEqualToString:@"bindcard_halfpage"]) {
        [self p_setupUIForBindCardHalfPage];
        return;
    }
    
    [self p_setupUIForV5];
}

- (void)p_setupUIForV4 {
    [self addSubview:self.marketingMsgView];
    self.subTitleLabel.font = [UIFont cj_boldFontOfSize:15];
    [self.confirmPayBtn setTitle:self.confirmInfo.buttonText forState:UIControlStateNormal];
    
    CJPayMasMaker(self.marketingMsgView, {
        make.centerX.top.equalTo(self);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    })
    
    NSInteger topOffset = Check_ValidString(self.confirmInfo.standardRecDesc) ? 6 : 8;
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(topOffset);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    })
    
    CJPayMasMaker(self.checkContentView, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(56);
        make.left.equalTo(self).offset(16);
    })
}

- (void)p_setupUIForV5 {
    self.subTitleLabel.font = [UIFont cj_boldFontOfSize:17];
    NSString *btnText = [NSString stringWithFormat:@"%@ ¥%@", self.confirmInfo.buttonText, self.confirmInfo.standardShowAmount];
    [self.confirmPayBtn setTitle:btnText forState:UIControlStateNormal];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self).offset(4);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    })
    
    CJPayMasMaker(self.checkContentView, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(44);
        make.left.equalTo(self).offset(16);
    })
}

- (void)p_setupUIForBindCardHalfPage {
    self.subTitleLabel.font = [UIFont cj_boldFontOfSize:17];
    [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_stringSeparatedWithDollar:self.confirmInfo.buttonText]];
    self.checkContentView.hidden = YES;
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self).offset(4);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.equalTo(@48);
    })
    
    CJPayMasReMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.equalTo(@44);
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(28);
    })
}

- (NSMutableAttributedString *)p_stringSeparatedWithDollar:(NSString *)string {
    NSArray * arr = [string componentsSeparatedByString:@"$"];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paraStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *textAttributes = @{NSFontAttributeName : [UIFont cj_boldFontOfSize:17],
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *amountAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:17],
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[arr cj_objectAtIndex:0]?:@"" attributes:textAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:1]?:@"" attributes:amountAttributes]];
    return attributedString;
}

#pragma mark - getter

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [UIColor cj_161823ff];
        _subTitleLabel.numberOfLines = 0;
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.text = self.confirmInfo.subTitle;
    }
    return _subTitleLabel;
}

- (CJPayStyleButton *)confirmPayBtn {
    if (!_confirmPayBtn) {
        _confirmPayBtn = [[CJPayStyleButton alloc] init];
        _confirmPayBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmPayBtn.titleLabel setTextColor:[UIColor whiteColor]];
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_f85959ff]];
        _confirmPayBtn.layer.cornerRadius = 8;
    }
    return _confirmPayBtn;
}

- (CJPayStyleCheckBox *)checkBox {
    if (!_checkBox) {
        _checkBox = [CJPayStyleCheckBox new];
        _checkBox.clipsToBounds = YES;
        _checkBox.layer.cornerRadius = 8;
        [_checkBox updateWithCheckImgName:@"cj_front_select_card_icon"
                           noCheckImgName:@"cj_noselect_icon"];
        _checkBox.selected = [self.confirmInfo.checkboxSelectDefault isEqualToString:@"1"];
    }
    return _checkBox;
}

- (UILabel *)checkDescLabel {
    if (!_checkDescLabel) {
        _checkDescLabel = [UILabel new];
        _checkDescLabel.text = self.confirmInfo.tipsCheckbox;
        _checkDescLabel.font = [UIFont cj_fontOfSize:13];
        _checkDescLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
    }
    return _checkDescLabel;
}

- (UIView *)checkContentView {
    if (!_checkContentView) {
        _checkContentView = [UIView new];
        [_checkContentView addSubview:self.checkBox];
        [_checkContentView addSubview:self.checkDescLabel];
        
        CJPayMasMaker(self.checkDescLabel, {
            make.top.right.bottom.equalTo(self.checkContentView);
            make.height.mas_equalTo(18);
        });
        
        CJPayMasMaker(self.checkBox, {
            make.centerY.equalTo(self.checkDescLabel);
            make.right.equalTo(self.checkDescLabel.mas_left).offset(-4);
            make.left.equalTo(self.checkContentView);
            make.width.height.mas_equalTo(16);
        });
    }
    return _checkContentView;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleCompact isShowVoucherMsg:YES];
    }
    return _marketingMsgView;
}

@end
