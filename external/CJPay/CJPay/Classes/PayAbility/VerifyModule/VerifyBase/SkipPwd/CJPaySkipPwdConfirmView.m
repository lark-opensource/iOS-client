//
//  CJPaySkipPwdConfirmView.m
//  Pods
//
//  Created by wangxiaohong on 2021/12/21.
//

#import "CJPaySkipPwdConfirmView.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayEnumUtil.h"
#import "CJPayMarketingMsgView.h"

@interface CJPaySkipPwdConfirmView()

@property (nonatomic, strong, readwrite) CJPayButton *closeButton;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong, readwrite) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong, readwrite) CJPayStyleCheckBox *checkBox;
@property (nonatomic, strong, readwrite) UILabel *checkDescLabel;
@property (nonatomic, strong) UIView *checkContentView;
@property (nonatomic, strong, readwrite) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readwrite) CJPayCombineDetailView * combineDetailView;

@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *confirmInfo;

@end

@implementation CJPaySkipPwdConfirmView

- (instancetype)initWithModel:(CJPaySecondaryConfirmInfoModel *)model {
    self = [super init];
    if (self) {
        self.confirmInfo = model;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.closeButton];
    [self addSubview:self.confirmPayBtn];
    [self addSubview:self.checkContentView];
    
    CJPayMasMaker(self.closeButton, {
        make.top.left.equalTo(self).offset(12);
        make.width.height.mas_equalTo(20);
    })
    
    if ([self.confirmInfo.style isEqualToString:@"V1"]) {
        [self p_setupUIForV1];
        return;
    }
    
    if ([self.confirmInfo.style isEqualToString:@"V2"]) {
        [self p_setupUIForV2];
        return;
    }
    
    if ([self.confirmInfo.style isEqualToString:@"V3"]) {
        [self p_setupUIForV3];
        return;
    }
    
    if ([self.confirmInfo.style isEqualToString:@"bindcard_popup"]) {
        [self p_setupUIForBindCardPopUp];
        return;
    }
    
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.combineDetailView];
    
    CJPayMasReMaker(self.marketingMsgView, {
        make.top.equalTo(@40);
        make.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self).offset(40);
    });
    
    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.checkContentView, {
        make.top.equalTo(self.confirmPayBtn.mas_bottom).offset(13);
        make.bottom.equalTo(self).offset(-13);
        make.centerX.equalTo(self);
    })
    
    CJPayMasMaker(self.combineDetailView, {
        make.top.equalTo(self).offset(110);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(38);
    });
}

- (void)p_setupUIForV1 {
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.subTitleLabel];
    
    self.checkDescLabel.text = self.confirmInfo.tipsCheckbox;
    [self.confirmPayBtn setTitle:self.confirmInfo.buttonText forState:UIControlStateNormal];
        
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self).offset(28);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })
    
    NSInteger offset = Check_ValidString(self.confirmInfo.standardRecDesc) ? 6 : 4;
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(offset);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })
    
    [self p_setupUIForV1_2_3];
}

- (void)p_setupUIForV2 {
    [self p_setupSubTitleForV2OrV3];
    NSString *btnText = [NSString stringWithFormat:@"%@ ¥%@", self.confirmInfo.buttonText, self.confirmInfo.standardShowAmount];
    [self.confirmPayBtn setTitle:btnText forState:UIControlStateNormal];
    [self p_setupUIForV1_2_3];
}

- (void)p_setupUIForV3 {
    [self p_setupSubTitleForV2OrV3];
    [self.confirmPayBtn setTitle:self.confirmInfo.buttonText forState:UIControlStateNormal];
    [self p_setupUIForV1_2_3];
}

- (void)p_setupUIForBindCardPopUp {
    [self p_setupSubTitleForV2OrV3];
    [self.confirmPayBtn cj_setBtnAttributeTitle:[self p_stringSeparatedWithDollar:self.confirmInfo.buttonText]];
    self.confirmPayBtn.layer.cornerRadius = 8;
    self.checkContentView.hidden = YES  ;

    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
    })
    
    CJPayMasMaker(self, {
        make.bottom.equalTo(self.confirmPayBtn).offset(20);
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

- (void)p_setupSubTitleForV2OrV3 {
    [self addSubview:self.subTitleLabel];
    self.subTitleLabel.font = [UIFont cj_boldFontOfSize:17];
    self.subTitleLabel.textColor = [UIColor cj_161823ff];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self).offset(40);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })
}

- (void)p_setupUIForV1_2_3 {
    self.confirmPayBtn.layer.cornerRadius = 8;
    
    CJPayMasMaker(self.checkContentView, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(24);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })

    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.checkContentView.mas_bottom).offset(12);
        make.height.mas_equalTo(44);
    })
    
    CJPayMasMaker(self, {
        make.bottom.equalTo(self.confirmPayBtn).offset(20);
    })
}

- (void)updateWithIsShowCombine:(BOOL)isShowCombine {
    self.mainTitleLabel.hidden = isShowCombine;
    self.marketingMsgView.hidden = !isShowCombine;
    self.combineDetailView.hidden = !isShowCombine;
    CJPayMasReMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        if (isShowCombine) {
            make.top.mas_equalTo(172);
        } else {
            make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(24);
        }
        make.height.mas_equalTo(44);
    });
}

#pragma mark - Getter
- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.text = CJPayLocalizedStr(@"已开通免密支付，无需验证密码");
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:17];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
        _mainTitleLabel.numberOfLines = 0;
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
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
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        _confirmPayBtn.layer.cornerRadius = 4;
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
        _checkDescLabel.text = Check_ValidString(self.confirmInfo.tipsCheckbox) ? self.confirmInfo.tipsCheckbox : CJPayLocalizedStr(@"以后不再提示");
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

- (CJPayCombineDetailView *)combineDetailView {
    if (!_combineDetailView) {
        _combineDetailView = [[CJPayCombineDetailView alloc] init];
    }
    return _combineDetailView;
 }

@end
