//
//  CJPayPasswordView.m
//  Pods
//
//  Created by xutianxi on 2022/8/4.
//

#import "CJPayPasswordView.h"
#import "CJPayStyleButton.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPaySettingsManager.h"
#import "CJPayLoadingManager.h"

@implementation CJPayPassCodePageModel

@end

@interface CJPayPasswordView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIImageView *safeImageView;
@property (nonatomic, strong) CJPaySafeInputView *safeInputView;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, strong) UIButton *forgetPasswordBtn;
@property (nonatomic, strong) CJPayStyleButton *completeButton;
@property (nonatomic, assign) BOOL isInLoading;

@property (nonatomic, strong) MASConstraint *errorLabelTopConstraint;

@end

@implementation CJPayPasswordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.safeInputView];
    [self addSubview:self.errorLabel];
    [self addSubview:self.forgetPasswordBtn];
    [self addSubview:self.completeButton];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self);
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.centerX.equalTo(self);
    });
    
    [self addSubview:self.safeImageView];
    CJPayMasMaker(self.safeImageView, {
        make.centerY.equalTo(self.subTitleLabel);
        make.width.mas_equalTo(15);
        make.height.mas_equalTo(15.5);
        make.right.equalTo(self.subTitleLabel.mas_left).offset(-6);
    });
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.left.greaterThanOrEqualTo(self).offset(12);
        make.right.lessThanOrEqualTo(self).offset(-12);
        make.centerX.equalTo(self).offset(10);
    });
    
    if (!CJ_Pad) {
        CJPayMasMaker(self.safeInputView, {
            make.top.equalTo(self.subTitleLabel.mas_bottom).offset(28);
            make.left.equalTo(self).offset(24);
            make.right.equalTo(self).offset(-24);
            make.height.mas_equalTo(48);
            make.bottom.equalTo(self).offset(-150);
        });
    } else {
        CJPayMasMaker(self.safeInputView, {
            make.top.equalTo(self.subTitleLabel.mas_bottom).offset(28);
            make.centerX.equalTo(self);
            make.left.equalTo(self).offset(24).priorityMedium();
            make.right.equalTo(self).offset(-24).priorityMedium();
            make.width.mas_lessThanOrEqualTo(327).priorityHigh();
            make.height.mas_equalTo(48);
            make.bottom.equalTo(self).offset(-118);
        });
    }
    
    CJPayMasMaker(self.errorLabel, {
        self.errorLabelTopConstraint = make.top.equalTo(self.safeInputView.mas_bottom).offset(24);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.centerX.equalTo(self.safeInputView);
    });
    
    CJPayMasMaker(self.forgetPasswordBtn, {
        make.top.equalTo(self.safeInputView.mas_bottom).offset(24);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(14);
    });
    
    CJPayMasMaker(self.completeButton, {
        make.top.equalTo(self.safeInputView.mas_bottom).offset(40);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(48);
    });
}

- (void)updateWithPassCodeType:(CJPayPassCodeType)type {
    CJPayPassCodePageModel *pageModel;
    pageModel = [self p_buildSafetyPassCodeModelBy:type];
    
    [self p_updateWithPassCodePageModel:pageModel];
}

- (void)updateWithPassCodeType:(CJPayPassCodeType)type title:(NSString *)title subTitle:(NSString *)subTitle {
    if (Check_ValidString(title) && Check_ValidString(subTitle)) {
        CJPayPassCodePageModel *model = [CJPayPassCodePageModel new];
        model.title = title;
        model.subTitle = subTitle;
        model.type = type;
        [self p_updateWithPassCodePageModel:model];
    } else {
        [self updateWithPassCodeType:type];
    }
}

- (void)startLoading {
    self.isInLoading = YES;
    CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    if (model && model.showNewLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    } else {
        @CJStartLoading(self.completeButton)
    }
}

- (void)stopLoading {
    if (!self.isInLoading) {
        return;
    } else {
        self.isInLoading = NO;
    }
    
    CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    if (model && model.showNewLoading) {
        [[CJPayLoadingManager defaultService] stopLoading];
    } else {
        @CJStopLoading(self.completeButton)
    }
}

- (void)p_updateWithPassCodePageModel:(CJPayPassCodePageModel *)pageModel {
    switch (pageModel.type) {
        case CJPayPassCodeTypePayVerify:
        case CJPayPassCodeTypeIndependentBindCardVerify:
            self.forgetPasswordBtn.hidden = NO;
            self.completeButton.hidden = YES;
            self.errorLabel.hidden = NO;
            break;
            
        case CJPayPassCodeTypeSet:
            self.forgetPasswordBtn.hidden = YES;
            self.completeButton.hidden = YES;
            self.errorLabel.hidden = NO;
            break;
            
        case CJPayPassCodeTypeSetAgain:
            self.forgetPasswordBtn.hidden = YES;
            self.completeButton.hidden = YES;
            self.errorLabel.hidden = YES;
            break;
            
        case CJPayPassCodeTypeSetAgainAndPay:
            self.forgetPasswordBtn.hidden = YES;
            self.completeButton.hidden = NO;
            self.errorLabel.hidden = YES;
            break;
            
        default:
            break;
    }
    if ([CJPayBrandPromoteABTestManager shared].model.halfInputPasswordTitle) {
        CJPayPassCodePageModel *model;
        model = [self p_buildSafetyPassCodeModelBy:pageModel.type];
        self.titleLabel.text = CJPayLocalizedStr(model.title);
        self.subTitleLabel.text = CJPayLocalizedStr(model.subTitle);
        [self.completeButton setTitle:CJPayLocalizedStr(model.btnTitle) forState:UIControlStateNormal];
    } else {
        self.titleLabel.text = pageModel.title;
        self.subTitleLabel.text = pageModel.subTitle;
        [self.completeButton setTitle:pageModel.btnTitle forState:UIControlStateNormal];
    }
    [self.safeInputView clearInput];
    
    self.errorLabelTopConstraint.offset = self.forgetPasswordBtn.hidden ? 24 : 62;
}

- (CJPayPassCodePageModel *)p_buildSafetyPassCodeModelBy:(CJPayPassCodeType)type {
    CJPayPassCodePageModel *model = [CJPayPassCodePageModel new];
    model.type = type;
    
    NSString *subTitle = CJPayLocalizedStr(@"中国人保财险提供百万保障");
    if (Check_ValidString(self.subTitle)) {
        subTitle = self.subTitle;
    }
    if(Check_ValidString([CJPayBrandPromoteABTestManager shared].model.halfInputPasswordTitle)) {
        switch (type) {
            case CJPayPassCodeTypeSetAgain:
                model.title = [CJPayBrandPromoteABTestManager shared].model.fullSetPasswordTitleAgain;
                if (!Check_ValidString(model.title)) {
                    model.title = CJPayLocalizedStr(@"确认支付密码");
                }
                model.subTitle = subTitle;
                break;
            case CJPayPassCodeTypeSetAgainAndPay:
                model.title = CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.fullSetPasswordTitleAgain);
                if (!Check_ValidString(model.title)) {
                    model.title = CJPayLocalizedStr(@"确认支付密码");
                }
                model.subTitle = subTitle;
                model.btnTitle = CJPayLocalizedStr(@"确认并支付");
                break;
            case CJPayPassCodeTypeSet:
                model.title = CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.fullSetPasswordTitle);
                if (!Check_ValidString(model.title)) {
                    model.title = CJPayLocalizedStr(@"设置支付密码");
                }
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请设置密码用于验证身份");
                break;
            case CJPayPassCodeTypePayVerify:
                model.title = CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.fullVerifyPasswordTitle);
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请输入密码用于验证身份");
                break;
            case CJPayPassCodeTypeIndependentBindCardVerify:
                model.title = CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.fullVerifyPasswordTitle);
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请输入密码用于验证身份");
                break;
            default:
                break;
        }
    } else {
        switch (type) {
            case CJPayPassCodeTypeSetAgain:
                model.title = CJPayLocalizedStr(@"确认支付密码");
                model.subTitle = subTitle;
                model.btnTitle = CJPayLocalizedStr(@"完成");
                break;
            case CJPayPassCodeTypeSetAgainAndPay:
                model.title = CJPayLocalizedStr(@"确认支付密码");
                model.subTitle = subTitle;
                model.btnTitle = CJPayLocalizedStr(@"确认并支付");
                break;
            case CJPayPassCodeTypeSet:
                model.title = CJPayLocalizedStr(@"设置支付密码");
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请设置密码用于验证身份");
                break;
            case CJPayPassCodeTypePayVerify:
                model.title = CJPayLocalizedStr(@"验证支付密码");
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请输入密码用于验证身份");
                break;
            case CJPayPassCodeTypeIndependentBindCardVerify:
                model.title = CJPayLocalizedStr(@"验证支付密码");
                model.subTitle = CJPayLocalizedStr(@"为保障资金安全，请输入密码用于验证身份");
                break;
            default:
                break;
        }
    }
    return model;
}

- (void)p_forgetButtonTapped {
    CJ_CALL_BLOCK(self.forgetButtonTappedBlock);
}

- (void)p_completeButtonTapped {
    CJ_CALL_BLOCK(self.completeButtonTappedBlock);
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:22];
        _titleLabel.textColor = [UIColor cj_222222ff];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)safeImageView {
    if(!_safeImageView) {
        _safeImageView = [UIImageView new];
        [_safeImageView cj_setImage:@"cj_safe_blue_icon"];
    }
    return _safeImageView;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font =([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn)? [UIFont cj_fontOfSize:12]:[UIFont cj_fontOfSize:14];
        
        _subTitleLabel.textColor = [UIColor cj_999999ff];
        _subTitleLabel.numberOfLines = 2;
    }
    return _subTitleLabel;
}

- (CJPaySafeInputView *)safeInputView {
    if (!_safeInputView) {
        _safeInputView = [[CJPaySafeInputView alloc] initWithKeyboardForDenoise:NO];
        _safeInputView.allowBecomeFirstResponder = NO;
        _safeInputView.showCursor = NO;
        _safeInputView.mineSecureSupportShortShow = NO;
    }
    return _safeInputView;
}

- (CJPayStyleErrorLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [CJPayStyleErrorLabel new];
        _errorLabel.numberOfLines = 0;
        _errorLabel.textAlignment = NSTextAlignmentCenter;
        _errorLabel.font =([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn)? [UIFont cj_fontOfSize:11]:[UIFont cj_fontOfSize:14];

    }
    return _errorLabel;
}

- (UIButton *)forgetPasswordBtn {
    if (!_forgetPasswordBtn) {
        _forgetPasswordBtn = [CJPayButton new];
        _forgetPasswordBtn.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_forgetPasswordBtn setTitleColor:[UIColor cj_04498dff] forState:UIControlStateNormal];
        [_forgetPasswordBtn setTitle:CJPayLocalizedStr(@"忘记密码") forState:UIControlStateNormal];
        [_forgetPasswordBtn addTarget:self action:@selector(p_forgetButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _forgetPasswordBtn;
}

- (CJPayStyleButton *)completeButton {
    if (!_completeButton) {
        _completeButton = [CJPayStyleButton new];
        _completeButton.enabled = NO;
        [_completeButton setTitle:CJPayLocalizedStr(@"完成") forState:UIControlStateNormal];
        [_completeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _completeButton.titleLabel.font = [UIFont cj_boldFontOfSize:17];
        [_completeButton addTarget:self action:@selector(p_completeButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    }
    return _completeButton;
}

@end
