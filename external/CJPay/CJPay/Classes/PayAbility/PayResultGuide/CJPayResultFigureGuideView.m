//
//  CJPayResultFigureGuideView.m
//  Pods
//
//  Created by 利国卿 on 2021/12/8.
//

#import "CJPayResultFigureGuideView.h"
#import "CJPayResultPageGuideInfoModel.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayPayAgainDiscountView.h"

@interface CJPayResultFigureGuideView ()

@property (nonatomic, strong) CJPayResultPageGuideInfoModel *model;
@property (nonatomic, assign) BOOL showBackView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) CJPayPayAgainDiscountView *bubbleView;

@end

@implementation CJPayResultFigureGuideView


- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model {
    return [self initWithGuideInfoModel:model showBackView:NO];
}

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model showBackView:(BOOL)showBackView; {
    self = [super init];
    if (self) {
        _model = model;
        _showBackView = showBackView;
        [self setupUI];
    };
    return self;
}

- (void)setupUI {
    [self addSubview:self.mainGuideLabel];
    [self addSubview:self.subGuideLabel];
    [self addSubview:self.guideFigure];
    [self addSubview:self.confirmButton];
    if (Check_ValidString(self.model.bubbleText)) {
        [self addSubview:self.bubbleView];
    }
    [self addSubview:self.iconImage];
    [self addSubview:self.voucherAmountLabel];
    [self.confirmButton addSubview:self.flickView];
    
    CJPayMasMaker(self.mainGuideLabel, {
        make.centerX.equalTo(self);
        if ([self.model isNewGuideShowStyleForOldPeople]) {
            make.top.equalTo(self).offset(66);
        } else if ([self.model isNewGuideShowStyle]) {
            make.top.equalTo(self).offset(36);
        } else {
            make.top.equalTo(self).offset(40);
        }
    });
    
    CJPayMasMaker(self.subGuideLabel, {
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(24);
        make.right.lessThanOrEqualTo(self).offset(-24);
        if ([self.model isNewGuideShowStyle] || [self.model isNewGuideShowStyleForOldPeople]) {
            make.top.equalTo(self.mainGuideLabel.mas_bottom).offset(8);
        } else {
            make.top.equalTo(self.mainGuideLabel.mas_bottom).offset(6);
        }
    });
    
    if (self.showBackView) {
        [self addSubview:self.backView];
        [self.backView addSubview:self.guideFigure];

        CJPayMasMaker(self.backView, {
            make.left.equalTo(self).offset(24);
            make.right.equalTo(self).offset(-24);
            make.top.equalTo(self.subGuideLabel.mas_bottom).offset(24);
            make.height.mas_equalTo(180);
        });

        CJPayMasMaker(self.guideFigure, {
            make.centerX.equalTo(self.backView);
            make.centerY.equalTo(self.backView);
            // UI稿子267，因为有阴影，实际299
            make.width.mas_equalTo(299);
            make.height.mas_equalTo(138);
        });
    } else {
        CJPayMasMaker(self.guideFigure, {
            make.centerX.equalTo(self);
            if ([self.model isNewGuideShowStyleForOldPeople]) {
                make.top.equalTo(self.subGuideLabel.mas_bottom);
            } else {
                make.top.equalTo(self.subGuideLabel.mas_bottom).offset(24);
            }
            make.width.mas_equalTo(375);
            make.height.mas_equalTo(180);
        });
    }
    
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(44);
        if (([self.model isNewGuideShowStyle] || [self.model isNewGuideShowStyleForOldPeople]) && [self p_shouldShowProtocolView]) {
            make.bottom.equalTo(self).offset(-42 - CJ_TabBarSafeBottomMargin);
        } else {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
        }
    });
    
    if (Check_ValidString(self.model.bubbleText)) {
        CJPayMasMaker(self.bubbleView, {
            make.bottom.equalTo(self.confirmButton.mas_top).offset(1);
            make.height.mas_equalTo(33);
            make.right.equalTo(self.confirmButton);
        });
    }
    
    CJPayMasMaker(self.iconImage, {
        make.centerY.equalTo(self.subGuideLabel);
        make.right.equalTo(self.subGuideLabel.mas_left).offset(-6);
        make.height.width.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.flickView, {
        make.top.bottom.left.equalTo(self.confirmButton);
        make.width.mas_equalTo(48);
    });
    
    CJPayMasMaker(self.voucherAmountLabel, {
        make.top.equalTo(self.guideFigure).offset(40);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(36);
    });

    if ([self p_shouldShowProtocolView]) {
        [self addSubview:self.protocolView];
        CJPayMasMaker(self.protocolView, {
            make.left.equalTo(self).offset(24);
            if (Check_ValidString(self.model.bubbleText)) {
                make.right.equalTo(self.bubbleView.mas_left).offset(-5);
            } else {
                make.right.equalTo(self).offset(-24);
            }
            if ([self.model isNewGuideShowStyle] || [self.model isNewGuideShowStyleForOldPeople]) {
                make.top.equalTo(self.confirmButton.mas_bottom).offset(12);
            } else {
                make.bottom.equalTo(self.confirmButton.mas_top).offset(-12);
            }
        });
    }
}

- (void)confirmButtonAnimation {
    [UIView animateWithDuration:1.0 animations:^{
        CJPayMasReMaker(self.flickView, {
            make.top.bottom.equalTo(self.confirmButton);
            make.left.equalTo(self.confirmButton.mas_right);
            make.width.mas_equalTo(48);
        });
        [self.confirmButton layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.flickView.alpha = 0;
    }];
}

- (BOOL)p_shouldShowProtocolView {
    return (self.model.protocoList && self.model.protocolGroupNames) &&
    ([self.model.guideType isEqualToString:@"nopwd_guide"] || [self.model.guideType isEqualToString:@"upgrade"]);
}

#pragma mark - Private Methods

- (NSMutableAttributedString *)p_stringSeparatedWithDollar:(NSString *)desc {
    NSArray *arr = [desc componentsSeparatedByString:@"$"];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *textAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.5],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *lineAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:12],
                                     NSForegroundColorAttributeName : [UIColor cj_colorWithHexString:@"505158" alpha:0.2],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[arr cj_objectAtIndex:0] ?: @"" attributes:textAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:1] ?: @"" attributes:lineAttributes]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:2] ?: @"" attributes:textAttributes]];
    return attributedString;
}

- (NSMutableAttributedString *)p_voucherAmountString {
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paraStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *amountAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:30],
                                     NSForegroundColorAttributeName : [UIColor cj_fe2c55ff],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *appendAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:13],
                                     NSForegroundColorAttributeName : [UIColor cj_fe2c55ff],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:CJString(self.model.voucherAmount) attributes:amountAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"元" attributes:appendAttributes]];
    return attributedString;
}

#pragma mark - ClickAction

- (void)confirmButtonClick {
    CJ_CALL_BLOCK(self.confirmBlock);
}

#pragma mark - Getter

- (UILabel *)mainGuideLabel {
    if (!_mainGuideLabel) {
        _mainGuideLabel = [UILabel new];
        [_mainGuideLabel setFont:[UIFont cj_boldFontOfSize:22]];
        [_mainGuideLabel setTextColor:[UIColor cj_161823ff]];
        [_mainGuideLabel setText:CJString(self.model.title)];
    }
    return _mainGuideLabel;
}

- (UILabel *)subGuideLabel {
    if (!_subGuideLabel) {
        _subGuideLabel = [UILabel new];
        if (Check_ValidString(self.model.subTitle)) {
            if ([self.model.subTitle containsString:@"$"]) {
                NSMutableAttributedString *attributedString = [self p_stringSeparatedWithDollar:self.model.subTitle];
                [_subGuideLabel setAttributedText:attributedString];
            } else {
                [_subGuideLabel setText:self.model.subTitle];
                [_subGuideLabel setFont:Check_ValidString(self.model.subTitleIconUrl) ? [UIFont cj_boldFontOfSize:14]: [UIFont cj_fontOfSize:14]];
                if (Check_ValidString(self.model.subTitleColor)) {
                    [_subGuideLabel setTextColor : [UIColor cj_colorWithHexString:CJString(self.model.subTitleColor)]];
                } else {
                    [_subGuideLabel setTextColor:[UIColor cj_161823WithAlpha:0.5]];
                }
            }
        } else {
            [_subGuideLabel setText:CJPayLocalizedStr(@"")];
        }
        [_subGuideLabel setTextAlignment:NSTextAlignmentCenter];
        [_subGuideLabel setNumberOfLines:0];
    }
    return _subGuideLabel;
}

- (UIImageView *)guideFigure {
    if (!_guideFigure) {
        _guideFigure = [UIImageView new];
        [_guideFigure setBackgroundColor:[UIColor clearColor]];
        if (Check_ValidString(self.model.pictureUrl)) {
            [_guideFigure cj_setImageWithURL:[NSURL URLWithString:self.model.pictureUrl] placeholder:nil];
        }
    }
    return _guideFigure;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmButton setTitle:CJString(self.model.confirmBtnDesc) forState:UIControlStateNormal];
        [_confirmButton.titleLabel setFont:[UIFont cj_boldFontOfSize:15]];
        [_confirmButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_confirmButton addTarget:self action:@selector(confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
        protocolModel.guideDesc = CJString(self.model.guideMessage);
        protocolModel.agreements = [self.model.protocoList copy];
        protocolModel.groupNameDic = self.model.protocolGroupNames;
        protocolModel.protocolFont = [UIFont cj_fontOfSize:12];
        
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:protocolModel];
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.protocolClickBlock);
        };
    }
    return _protocolView;
}

- (UIView *)backView {
    if (!_backView) {
        _backView = [UIView new];
        _backView.backgroundColor = [UIColor cj_fafafaff];
        _backView.layer.cornerRadius = 4;
        _backView.clipsToBounds = YES;
    }
    return _backView;
}

- (UIImageView *)iconImage {
    if (!_iconImage) {
        _iconImage = [UIImageView new];
        _iconImage.hidden = !Check_ValidString(self.model.voucherAmount);
        [_iconImage cj_setImageWithURL:[NSURL URLWithString:CJString(self.model.subTitleIconUrl)] placeholder:nil];
    }
    return _iconImage;
}

- (UILabel *)voucherAmountLabel {
    if (!_voucherAmountLabel) {
        _voucherAmountLabel = [UILabel new];
        if (Check_ValidString(self.model.voucherAmount)) {
            _voucherAmountLabel.attributedText = [self p_voucherAmountString];
        }
    }
    return _voucherAmountLabel;
}

- (CJPayPayAgainDiscountView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[CJPayPayAgainDiscountView alloc] initWithFrame:CGRectZero hiddenImageView:YES];
        _bubbleView.backgroundColor = [UIColor clearColor];
        _bubbleView.layer.cornerRadius = 4;
        _bubbleView.layer.masksToBounds = YES;
        [_bubbleView setDiscountStr:self.model.bubbleText];
    }
    return _bubbleView;
}

- (UIImageView *)flickView {
    if (!_flickView) {
        _flickView = [UIImageView new];
        [_flickView cj_setImage:@"cj_guide_flick_icon"];
        _flickView.hidden = !self.model.isButtonFlick;
    }
    return _flickView;
}

@end
