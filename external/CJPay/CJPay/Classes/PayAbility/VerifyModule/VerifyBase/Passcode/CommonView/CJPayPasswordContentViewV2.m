//
//  CJPayPasswordContentViewV2.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/30.
//

#import "CJPayPasswordContentViewV2.h"

#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPopUpBaseViewController.h"

#import "CJPayChoosedPayMethodView.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleButton.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPayMarketingMsgView.h"

#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeData.h"

#import "CJPayDynamicLayoutModel.h"
#import "CJPayDynamicLayoutView.h"

@interface CJPayPasswordContentViewV2 () <CJPaySafeInputViewDelegate, CJPayDynamicLayoutViewDelegate>

// subviews
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView; // 金额和营销区
@property (nonatomic, strong) CJPayChoosedPayMethodView *choosedPayMethodView; // 支付方式展示区
@property (nonatomic, strong) CJPaySafeInputView *inputPasswordView; // 密码输入框
@property (nonatomic, strong) CJPayErrorInfoActionView *errorInfoActionView; // 错误文案提示
@property (nonatomic, strong) CJPayButton *forgetPasswordBtn; // 忘记密码按钮
@property (nonatomic, strong) CJPayGuideWithConfirmView *guideView; // 支付中引导

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;

@end

@implementation CJPayPasswordContentViewV2

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.choosedPayMethodView];
    [self addSubview:self.inputPasswordView];
    [self addSubview:self.errorInfoActionView];
    [self addSubview:self.forgetPasswordBtn];
    
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self).offset(8);
        make.left.right.equalTo(self);
        make.centerX.equalTo(self);
    });
    UIView *inputPasswordViewTopBaseConstraintView = self.marketingMsgView;
    
    // 判断是否隐藏choosedPayMethodView
    if (!self.viewModel.hideChoosedPayMethodView) {
        self.choosedPayMethodView.hidden = NO;
        inputPasswordViewTopBaseConstraintView = self.choosedPayMethodView;
    }
    
    CJPayMasMaker(self.choosedPayMethodView, {
        make.top.greaterThanOrEqualTo(self.marketingMsgView.priceView.mas_bottom).offset(38);
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(20).priorityLow();
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    });
    
    CJPayMasMaker(self.inputPasswordView, {
        make.top.equalTo(inputPasswordViewTopBaseConstraintView.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(46);
    });
    
    CJPayMasMaker(self.errorInfoActionView, {
        make.top.equalTo(self.inputPasswordView.mas_bottom).offset(12);
        make.left.equalTo(self.inputPasswordView);
        make.right.lessThanOrEqualTo(self.forgetPasswordBtn.mas_left);
    });
    
    CJPayMasMaker(self.forgetPasswordBtn, {
        make.top.equalTo(self.inputPasswordView.mas_bottom).offset(12);
        make.right.equalTo(self.inputPasswordView);
        make.height.mas_equalTo(18);
    });
    
    if ([self.viewModel isNeedShowGuide]) {
        [self addSubview:self.guideView];
        CJPayMasMaker(self.guideView, {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.top.greaterThanOrEqualTo(self.forgetPasswordBtn.mas_bottom);
            make.bottom.equalTo(self).offset(-16);
        });
    }
}

- (void)updateForChoosedPayMethod:(BOOL)isHidden {
    if (isHidden) {
        CJPayMasReMaker(self.inputPasswordView, {
            make.top.equalTo(self.marketingMsgView.mas_bottom).offset(20);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(46);
        });
    } else {
        CJPayMasReMaker(self.choosedPayMethodView, {
            make.top.greaterThanOrEqualTo(self.marketingMsgView.priceView.mas_bottom).offset(38);
            make.top.equalTo(self.marketingMsgView.mas_bottom).offset(20).priorityLow();
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
        });
        
        CJPayMasReMaker(self.inputPasswordView, {
            make.top.equalTo(self.choosedPayMethodView.mas_bottom).offset(20);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(46);
        });
    }
}

// 根据选中支付方式更新页面信息
- (void)updatePayConfigContent:(NSArray<CJPayDefaultChannelShowConfig *> *)configs {
    if (!Check_ValidArray(configs)) {
        return;
    }
    [self.choosedPayMethodView updateContentByChannelConfigs:configs]; // 更新支付方式信息
    if (configs.count == 1) {
        CJPayDefaultChannelShowConfig *selectConfig = [configs cj_objectAtIndex:0];
        NSString *payAmountStr = CJString(selectConfig.payAmount);
        NSString *payVoucherStr = CJString(selectConfig.payVoucherMsg);
        if (selectConfig.type == BDPayChannelTypeCreditPay) {
            payAmountStr = CJString(selectConfig.payTypeData.curSelectCredit.standardShowAmount);
            payVoucherStr = CJString(selectConfig.payTypeData.curSelectCredit.standardRecDesc);
        }
        [self.marketingMsgView updateWithPayAmount:payAmountStr voucherMsg:payVoucherStr]; // 更新金额和营销
    }
}

- (CJPayCommonProtocolModel *)buildProtocolModelBySkippwdGuide {
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.guideDesc = self.viewModel.response.skipPwdGuideInfoModel.guideMessage;
    protocolModel.groupNameDic = self.viewModel.response.skipPwdGuideInfoModel.protocolGroupNames;
    protocolModel.agreements = self.viewModel.response.skipPwdGuideInfoModel.protocoList;
    protocolModel.isSelected = self.viewModel.response.skipPwdGuideInfoModel.isChecked || self.viewModel.response.skipPwdGuideInfoModel.isSelectedManually;
    
    self.viewModel.isGuideSelected = protocolModel.isSelected;
    protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
    protocolModel.protocolDetailContainerHeight = @(self.viewModel.passwordViewHeight);
    return protocolModel;
    
}

- (CJPayCommonProtocolModel *)buildProtocolModelByBioGuide {
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.guideDesc = self.viewModel.response.preBioGuideInfo.title;
    protocolModel.isSelected = self.viewModel.response.preBioGuideInfo.choose;
    
    self.viewModel.isGuideSelected = protocolModel.isSelected;
    protocolModel.protocolFont = [UIFont cj_fontOfSize:13];
    if ([self.viewModel.response.preBioGuideInfo.guideStyle isEqualToString:@"SWITCH"]) {
        protocolModel.selectPattern = CJPaySelectButtonPatternSwitch;
    } else {
        protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
    }
    return protocolModel;
}

#pragma mark - CJPaySafeInputViewDelegate

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    self.viewModel.passwordInputCompleteTimes = self.viewModel.passwordInputCompleteTimes + 1;
    CJ_CALL_BLOCK(self.inputCompleteBlock, currentStr);
}

- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr {
    if ([self.viewModel isNeedShowGuide]) {
        self.guideView.confirmButton.enabled = currentStr.length == 6;
    }
}

- (void)p_comfirmInputComplete {
    CJ_CALL_BLOCK(self.confirmBtnClickBlock, self.inputPasswordView.contentText);
    [CJKeyboard resignFirstResponder:self.inputPasswordView];
}

#pragma mark - CJPayPasswordViewProtocol
- (void)showKeyBoardView {
    [CJKeyboard becomeFirstResponder:self.inputPasswordView];
}

- (void)retractKeyBoardView {
    [CJKeyboard resignFirstResponder:self.inputPasswordView];
}

// 清空密码输入
- (void)clearPasswordInput {
    self.guideView.confirmButton.enabled = NO;
    [self.inputPasswordView clearInput];
}

// 输错密码后展示 错误提示文案
- (void)updateErrorText:(NSString *)text {
    self.errorInfoActionView.hidden = !Check_ValidString(text);
    self.errorInfoActionView.errorLabel.text = CJString(text);
    [self.inputPasswordView becomeFirstResponder];
}

// 是否允许输入
- (void)setPasswordInputAllow:(BOOL)isAllow {
    self.inputPasswordView.allowBecomeFirstResponder = isAllow;
}

- (BOOL)hasInputHistory {
    return self.inputPasswordView.hasInputHistory;
}

#pragma mark - lazy views

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleDenoiseV2 isShowVoucherMsg:NO];
        if ([self.viewModel isCombinedPay]) {
            [_marketingMsgView updateWithModel:self.viewModel.response];
        } else {
            CJPayDefaultChannelShowConfig *config = self.viewModel.defaultConfig;
            NSString *payAmountStr = CJString(config.payAmount);
            NSString *payVoucherStr = CJString(config.payVoucherMsg);
            if (config.type == BDPayChannelTypeCreditPay) {
                payAmountStr = CJString(config.payTypeData.curSelectCredit.standardShowAmount);
                payVoucherStr = CJString(config.payTypeData.curSelectCredit.standardRecDesc);
            }
            [_marketingMsgView updateWithPayAmount:payAmountStr voucherMsg:payVoucherStr];
        }
    }
    return _marketingMsgView;
}

- (CJPayChoosedPayMethodView *)choosedPayMethodView {
    if (!_choosedPayMethodView) {
        _choosedPayMethodView = [[CJPayChoosedPayMethodView alloc] initIsCombinePay:[self.viewModel isCombinedPay]];
        [_choosedPayMethodView updateContentByChannelConfigs:self.viewModel.displayConfigs];
        
        @weakify(self);
        _choosedPayMethodView.clickedPayMethodBlock = ^{
            @strongify(self);
            CJ_CALL_BLOCK(self.clickedPayMethodBlock, @"0");
        };
        _choosedPayMethodView.hidden = YES;
    }
    
    return _choosedPayMethodView;
}

- (CJPaySafeInputView *)inputPasswordView {
    if (!_inputPasswordView) {
        _inputPasswordView = [[CJPaySafeInputView alloc] initWithKeyboardForDenoise:!CJ_Pad denoiseStyle:CJPayViewTypeDenoiseV2];
        _inputPasswordView.showCursor = NO;
        _inputPasswordView.textColor = UIColor.clearColor;
        _inputPasswordView.safeInputDelegate = self;
        [_inputPasswordView setIsNotShowKeyboardSafeguard:YES];
        [_inputPasswordView setKeyboardDenoise:CJPaySafeKeyboardTypeDenoiseV2];
    }
    return _inputPasswordView;
}

- (CJPayErrorInfoActionView *)errorInfoActionView {
    if (!_errorInfoActionView) {
        _errorInfoActionView = [CJPayErrorInfoActionView new];
        [_errorInfoActionView showActionButton:NO];
    }
    return _errorInfoActionView;
}

- (CJPayButton *)forgetPasswordBtn {
    if (!_forgetPasswordBtn) {
        _forgetPasswordBtn = [CJPayButton new];
        _forgetPasswordBtn.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_forgetPasswordBtn setTitleColor:[UIColor cj_forgetPWDSelectColor] forState:UIControlStateNormal];
        [_forgetPasswordBtn setTitle:CJPayLocalizedStr(@"忘记密码") forState:UIControlStateNormal];
        @CJWeakify(self)
        [_forgetPasswordBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.forgetPasswordBtn);
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock);
        }];
    }
    return _forgetPasswordBtn;
}

- (CJPayGuideWithConfirmView *)guideView {
    if (!_guideView) {
        if (self.viewModel.response.skipPwdGuideInfoModel.needGuide) {
            // 支付中免密引导
            CJPayCommonProtocolModel *protocolModel = [self buildProtocolModelBySkippwdGuide];
            _guideView = [[CJPayGuideWithConfirmView alloc] initWithCommonProtocolModel:protocolModel isShowButton:[self.viewModel isShowComfirmButton]];
            _guideView.confirmButton.enabled = NO;
            
            NSString *choosedBtnText = Check_ValidString(self.viewModel.response.skipPwdGuideInfoModel.buttonText) ? self.viewModel.response.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"同意协议并支付");
            NSString *buttonText = protocolModel.isSelected ? choosedBtnText : CJPayLocalizedStr(@"确认支付");
            [_guideView.confirmButton cj_setBtnTitle:buttonText];
            
            @CJWeakify(self)
            [_guideView.confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
                @CJStrongify(self)
                [self p_comfirmInputComplete];
            }];
            _guideView.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
                @CJStrongify(self)
                [self.viewModel trackPageClickWithButtonName:@"4"];
            };
            _guideView.protocolView.checkBoxClickBlock = ^{
                @CJStrongify(self);
                if ([self.guideView.protocolView isCheckBoxSelected]) {
                    NSString *buttonText = Check_ValidString(self.viewModel.response.skipPwdGuideInfoModel.buttonText) ? self.viewModel.response.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"开通并支付");
                    [self.guideView.confirmButton cj_setBtnTitle:buttonText];
                } else {
                    [self.guideView.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
                }
                
                self.viewModel.isGuideSelected = [self.guideView.protocolView isCheckBoxSelected];
                NSString *buttonName = self.viewModel.isGuideSelected ? @"2" : @"3";
                [self.viewModel trackPageClickWithButtonName: buttonName];
            };
        } else {
            // 支付中生物引导
            CJPayCommonProtocolModel *protocolModel = [self buildProtocolModelByBioGuide];

            _guideView = [[CJPayGuideWithConfirmView alloc] initWithCommonProtocolModel:protocolModel isShowButton:[self.viewModel isShowComfirmButton]];
            _guideView.confirmButton.enabled = NO;
            
            @CJWeakify(self)
            [_guideView.confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
                @CJStrongify(self)
                [self p_comfirmInputComplete];
            }];
            _guideView.protocolView.checkBoxClickBlock = ^{
                @CJStrongify(self)
                NSString *choosedBtnText = Check_ValidString(self.viewModel.response.preBioGuideInfo.btnDesc) ? self.viewModel.response.preBioGuideInfo.btnDesc : CJPayLocalizedStr(@"确认升级并支付");
                NSString *defaultBtnText = CJPayLocalizedStr(@"确认支付");
                [self.guideView.confirmButton cj_setBtnTitle:self.guideView.protocolView.isCheckBoxSelected ? choosedBtnText : defaultBtnText];
                
                self.viewModel.isGuideSelected = self.guideView.protocolView.isCheckBoxSelected;
                NSString *buttonName = self.viewModel.isGuideSelected ? @"2" : @"3";
                [self.viewModel trackPageClickWithButtonName: buttonName];
            };
            
            NSString *choosedBtnText = Check_ValidString(self.viewModel.response.preBioGuideInfo.btnDesc) ? self.viewModel.response.preBioGuideInfo.btnDesc : CJPayLocalizedStr(@"确认升级并支付");
            [_guideView.confirmButton cj_setBtnTitle:self.viewModel.response.preBioGuideInfo.choose ? choosedBtnText : CJPayLocalizedStr(@"确认支付")];
        }
    }
    return _guideView;
}

@end
