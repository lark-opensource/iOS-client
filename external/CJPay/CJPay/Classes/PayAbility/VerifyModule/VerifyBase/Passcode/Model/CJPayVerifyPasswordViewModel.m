//
//  CJPayVerifyPasswordViewModel.m
//  Pods
//
//  Created by chenbocheng on 2022/3/30.
//

#import "CJPayVerifyPasswordViewModel.h"

#import "CJPayMetaSecManager.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayWebViewUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayVerifyPassVCConfigModel.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySettingsManager.h"
#import "CJPayForgetPwdOptController.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayFreqSuggestStyleInfo.h"
#import "CJPayKVContext.h"
#import "CJPayOutDisplayInfoModel.h"

@interface CJPayVerifyPasswordViewModel() <CJPaySafeInputViewDelegate>

@end

@implementation CJPayVerifyPasswordViewModel

#pragma mark - public method

- (void)gotoForgetPwdVCFromVC:(CJPayHalfPageBaseViewController *)sourceVC {
    [self gotoForgetPwdVCFromVC:sourceVC completion:nil];
}

- (void)gotoForgetPwdVCFromVC:(CJPayHalfPageBaseViewController *)sourceVC completion:(void (^)(BOOL))completion {
    [self trackWithEventName:@"wallet_modify_password_forget_click" params:@{}];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeForgetPayPWDRequest];
    if (self.response != nil) {
        [CJKeyboard resignFirstResponder:self.inputPasswordView];
        [self.forgetPwdController forgetPwdWithSourceVC:sourceVC];
    }
}

- (void)updateErrorText:(NSString *)text withTypeString:(NSString *)type currentVC:(CJPayHalfPageBaseViewController *)vc {
    if (!vc.navigationController) { // 有可能VC已经溢出了
        [CJToast toastText:text inWindow:vc.cj_window];
        return;
    }
    
    if ([type isEqualToString:@"next_to_tips"]) {
        [self.errorInfoActionView showActionButton:YES];
        self.otherVerifyButton.hidden = YES;
        self.forgetPasswordBtn.hidden = NO;
    } else if ([type isEqualToString:@"top_right"]) {
        [self.errorInfoActionView showActionButton:NO];
        self.otherVerifyButton.hidden = NO;
        self.forgetPasswordBtn.hidden = NO;
    } else {
        // 支付中引导场景下 忘记密码btn与otherVerfyBtn在同一位置，需要判断是否显示忘记密码btn
        if(![self.otherVerifyButton isHidden] && [self isNeedShowGuide]){
            self.forgetPasswordBtn.hidden = YES;
        } else {
            self.forgetPasswordBtn.hidden = NO;
        }
    }
    
    if (Check_ValidString(text)) {
        self.errorInfoActionView.hidden = NO;
        [self p_hideDiscountLabel];
        UIFont *font = self.errorInfoActionView.errorLabel.font ?: [UIFont cj_fontOfSize:12];
        NSMutableAttributedString *errorAttr = [[NSMutableAttributedString alloc] initWithString:text];
        NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
        paraghStyle.cjMaximumLineHeight = 16;
        paraghStyle.cjMinimumLineHeight = 16;
        NSDictionary *attributes = @{NSFontAttributeName : font,
                                     NSParagraphStyleAttributeName:paraghStyle,
                                     NSBaselineOffsetAttributeName:@(-1)};
        [errorAttr addAttributes:attributes range:NSMakeRange(0, errorAttr.length)];
        
        self.errorInfoActionView.errorLabel.text = text;
        self.errorInfoActionView.errorLabel.attributedText = errorAttr;
        
        CJPayMasUpdate(self.errorInfoActionView, {
            make.height.mas_equalTo([self.errorInfoActionView.errorLabel.text cj_sizeWithFont:self.errorInfoActionView.errorLabel.font width:vc.contentView.cj_width]);
        });
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,self.errorInfoActionView);
        [CJKeyboard becomeFirstResponder:self.inputPasswordView];
    } else {
        self.errorInfoActionView.hidden = YES;
    }
}

- (void)pageFirstAppear {
    NSString *showVerifyType = [[NSString alloc] init];
    
    if(!self.otherVerifyButton.isHidden) {
        showVerifyType = CJString(self.otherVerifyButton.titleLabel.text);
        if(showVerifyType.length) {
            [self trackWithEventName:@"wallet_password_verify_page_alivecheck_imp" params:@{
                @"button_position":@"0",
                @"is_awards_show" : @"1",
                @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel)
            }];
        }
    }
    
    if(!self.forgetPasswordBtn.isHidden && showVerifyType.length) {
        showVerifyType = CJConcatStr(showVerifyType,CJString(@","),CJString(self.forgetPasswordBtn.titleLabel.text));
    } else {
        showVerifyType = CJString(self.forgetPasswordBtn.titleLabel.text);
    }
    
    [self trackWithEventName:@"wallet_password_verify_page_imp" params:@{
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self isFingerprintDefault]),
        @"activity_label" : CJString([self trackActivityLabel]),
        @"guide_type" : CJString([self getBioGuideType]),
        @"enable_string" : CJString([self getBioGuideTypeStr]),
        @"tips_label" : CJString(self.downgradePasswordTips),
        @"show_verify_type" : CJString(showVerifyType),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
    }];
}

- (void)trackPageClickWithButtonName:(NSString *)buttonName params:(NSDictionary *)params {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict addEntriesFromDictionary:@{
        @"button_name": CJString(buttonName),
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self isFingerprintDefault]),
        @"time" : @(self.passwordInputCompleteTimes),
        @"confirm_time" : @(self.confirmBtnClickTimes),
        @"guide_choose" : CJString([self getGuideChoose]),
        @"guide_type" : CJString([self getBioGuideType]),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel)
    }];
    if (params.count) {
        [dict addEntriesFromDictionary:params];
    }
    [self trackWithEventName:@"wallet_password_verify_page_click"
                      params:dict];
}

//0关闭，1确认支付，2勾选免密/开启引导，3取消免密/关闭引导，4协议，5切换支付方式
- (void)trackPageClickWithButtonName:(NSString *)buttonName {
    [self trackPageClickWithButtonName:buttonName params:@{}];
}

- (void)reset {
    [self.inputPasswordView clearInput];
    self.errorInfoActionView.hidden = YES;
}

- (NSString *)tipText {
    NSInteger verifyDescType = self.response.payInfo.verifyDescType;
    // 验证方式降级（具体含义参考： verifyDescType 字段注释）
    if (verifyDescType == 4) {
        return @"";
    }
    if (verifyDescType == 3) {
        return self.response.payInfo.verifyDesc;
    } else if (verifyDescType == 2) {
        // ![self p_isBioVerifyAvailable] 被动降级，否则手动降级
        return ![self p_isBioVerifyAvailable] ? self.response.payInfo.verifyDesc : @"";
    }
    
    return Check_ValidString(self.configModel.tipsText) ? self.configModel.tipsText:  self.response.payInfo.verifyDesc;
}

#pragma mark - tracker

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSDictionary *finalParams = [self addObjectWithDeduct:params];
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime)}];
        [trackData addEntriesFromDictionary:finalParams];
        [self.trackDelegate event:eventName params:trackData];
    }
}

- (void)p_trackForForgetClick {
    [self trackWithEventName:@"wallet_password_verify_page_forget_click" params:@{
        @"button_name": CJString(self.forgetPasswordBtn.titleLabel.text),
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self isFingerprintDefault]),
        @"activity_label" : CJString([self trackActivityLabel]),
        @"guide_type" : CJString([self getBioGuideType]),
        @"time" : @(self.passwordInputCompleteTimes),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
    }];
}

- (NSDictionary *)addObjectWithDeduct:(NSDictionary *)params {
    NSMutableDictionary *finalParams = [NSMutableDictionary dictionaryWithDictionary:params];
    if (self.outDisplayInfoModel) {
        NSString *payAndSignCashierStyle = [NSString stringWithFormat:@"%ld", [self.outDisplayInfoModel obtainSignPayCashierStyle]];
        NSString *originalAmount = [NSString stringWithFormat:@"%ld",self.response.tradeInfo.tradeAmount];
        NSString *backDiscount = CJString([self.defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypePayBackVoucher]);
        [finalParams addEntriesFromDictionary:@{
            @"activity_title" : CJString(self.outDisplayInfoModel.promotionDesc),
            @"withhold_project" : CJString(self.outDisplayInfoModel.serviceDescName),
            @"template_id" : CJString(self.outDisplayInfoModel.templateId),
            @"original_amount" : CJString(originalAmount),
            @"discount_amount" : CJString(self.defaultConfig.payAmount),
            @"back_discount" : CJString(backDiscount),
        }];
    }
    return [finalParams copy];
}

#pragma mark - CJPaySafeInputViewDelegate

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    self.passwordInputCompleteTimes = self.passwordInputCompleteTimes + 1;
    
    [self trackWithEventName:@"wallet_password_verify_page_input"
                      params:@{
        @"time": @(self.passwordInputCompleteTimes),
        @"activity_label" : CJString([self trackActivityLabel]),
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self isFingerprintDefault]),
        @"guide_type" : CJString([self getBioGuideType]),
        @"enable_string" : CJString([self getBioGuideTypeStr]),
        @"tips_label" : CJString(self.downgradePasswordTips),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel)
    }];
    
    if (!self.inputCompleteBlock) {
        return;
    }
    
    if ([self isShowComfirmButton]) { //有确认按钮
        return;
    }
    CJ_CALL_BLOCK(self.inputCompleteBlock, currentStr);
    [CJKeyboard resignFirstResponder:self.inputPasswordView];
    if ([self.response.topRightBtnInfo.action isEqualToString:@"forget_pwd_verify"]) {
        self.otherVerifyButton.hidden = YES;
    }
    [self reset];
}

- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr {
    if (![self isNeedShowGuide]) {
        return;
    }
    CJ_CALL_BLOCK(self.inputChangeBlock, inputView.contentText);
}

#pragma mark - private method

- (void)p_handleWebViewCloseCallBack:(id)data completion:(void (^)(BOOL))completion{
    if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)data;
        NSString *service = [dic cj_stringValueForKey:@"service"];
        if (Check_ValidString(service) && [service isEqualToString:@"resetPassword"]) {
            CJ_CALL_BLOCK(completion, YES);
            NSDictionary *dict = [CJPayCommonUtil jsonStringToDictionary:data[@"data"]];
            int cardFlag = [dict cj_intValueForKey:@"card"];
            if (cardFlag == 1) {
                //通过H5绑卡找回支付密码 发送刷新卡列表通知，解决聚合支付下单接口刷新后
                //                    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayH5BindCardSuccessNotification object:nil];
            }
        }
    }
}

#pragma mark - getter

//检查指纹/面容是否可用
- (BOOL)p_isBioVerifyAvailable {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioPayAvailableWithResponse:self.response];
}

// 获取生物引导类型描述
- (NSString *)getBioGuideTypeStr {
    NSString *guideBioType = @"";
    if (Check_ValidString(self.response.topRightBtnInfo.desc)) {
        if ([self.response.topRightBtnInfo.desc isEqualToString:@"面容支付"]) {
            guideBioType = @"面容";
        } else if([self.response.topRightBtnInfo.desc isEqualToString:@"指纹支付"]) {
            guideBioType = @"指纹";
        }
    }
    return guideBioType;
}

- (void)p_hideDiscountLabel {
    if ([self isNeedShowGuide]) {
        [self.marketingMsgView hideDiscountLabel];
    }
}

- (void)setShowKeyBoardSafeGuard:(BOOL)isShow {
    [self.inputPasswordView setIsNotShowKeyboardSafeguard:!isShow];
}

- (BOOL)p_isShowMarketing {
    return [self.response.payInfo.voucherType integerValue] != 0;
}

// 是否需要补签约
- (BOOL)isNeedResignCard {
    if (self.response.needResignCard || [self.defaultConfig isNeedReSigning]) {
        return YES;
    }
    return NO;
}

// 判断是否需要展示生物引导
- (BOOL)isNeedShowOpenBioGuide {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin)) {
        BOOL isBioGuideAvailable = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioGuideAvailable];
        return self.response.preBioGuideInfo != nil && isBioGuideAvailable;
    }
    return NO;
}

// 判断是否需要展示支付中引导
- (BOOL)isNeedShowGuide {
    return [self isNeedShowOpenBioGuide] || self.response.skipPwdGuideInfoModel.needGuide;
}

// 判断生物引导是否默勾
- (NSString *)isFingerprintDefault {
    NSString *isFingerprintDefault = @"";
    if ([self isNeedShowOpenBioGuide]) {
        isFingerprintDefault = self.response.preBioGuideInfo.choose ? @"1" : @"0";
    }
    return isFingerprintDefault;
}

// 判断生物引导类型
- (NSString *)getBioGuideType {
    NSString *guideType = @"";
    if ([self isNeedShowOpenBioGuide]) {
        guideType = [self.response.preBioGuideInfo.guideStyle isEqualToString:@"CHECKBOX"] ? @"checkbox" : @"switch";
    }
    return guideType;
}

// 判断是否勾选了引导
- (NSString *)getGuideChoose {
    NSString *guideChoose = @"";
    if ([self isNeedShowGuide]) {
        guideChoose = self.isGuideSelected ? @"1" : @"0";
        self.response.payInfo.isGuideCheck = self.isGuideSelected;
        [self.marketingMsgView updateWithModel:self.response];
    }
    return guideChoose;
}

- (NSString *)trackActivityLabel {
    if ([self p_isShowMarketing]) {
        return CJString(self.response.payInfo.voucherMsg);
    }
    return @"";
}

// 判断是否是组合支付
- (BOOL)isCombinedPay {
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:self.response.payInfo.businessScene];
    return channelType == BDPayChannelTypeCombinePay;
}

// 判断支付中引导是否需要展示确认按钮
- (BOOL)isShowComfirmButton {
    if (self.response.skipPwdGuideInfoModel.needGuide) {
        return self.response.skipPwdGuideInfoModel.isShowButton;
    } else if ([self isNeedShowOpenBioGuide]) {
        return self.response.preBioGuideInfo.isShowButton;
    } else {
        return NO;
    }
}

// 是否展示“选择支付方式”UI组件
- (BOOL)isNeedShowChooseMethodView {
    return (Check_ValidArray(self.response.payInfo.subPayTypeDisplayInfoList) || Check_ValidArray(self.response.payTypeInfo.subPayTypeGroupInfoList)) && !self.hideChoosedPayMethodView;
}

// 是否展示“输入密码提示文案”
- (BOOL)isNeedShowPasswordFixedTips {
    return Check_ValidString(self.passwordFixedTips) && !self.hidePasswordFixedTips;
}

// “忘记密码”按钮是否固定展示
- (BOOL)isNeedShowFixForgetButton {
    if (!self.isDynamicLayout) {
        return YES;
    }
    if ([self isNeedShowGuide]) {
        return NO;
    }
    return self.isStillShowForgetBtn || [self.response.payInfo.cashierTags containsObject:@"fe_tag_static_forget_pwd_style"];
}

- (BOOL)isSuggestCardStyle {
    return [self.response.payTypeInfo.subPayTypeSumInfo.homePageShowStyle isEqualToString:@"freq_suggest"] && self.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo;
}

- (BOOL)isHasSuggestCard {
    return [self isSuggestCardStyle] &&
    self.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.hasSuggestCard &&
    self.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.freqSuggestStyleIndexList.count;
}

- (NSArray <CJPayChannelBizModel *>*)getSuggestChannelModelList {
    if (![self isSuggestCardStyle]) {
        return nil;
    }
    
    NSMutableArray <CJPayChannelBizModel *>*array = [NSMutableArray new];
    if (![self isHasSuggestCard]) {
        NSArray<CJPayDefaultChannelShowConfig *> *defaultChannelShowConfigArray = self.response.payTypeInfo.allSumInfoPayChannels;
        CJPayChannelBizModel *model = [[defaultChannelShowConfigArray cj_objectAtIndex:0] toBizModel];
        model.selectPageGuideText = @""; // 产品需要 在新客的样式下不展示这个字段， 与安卓对齐
        [array addObject:model];
    } else {
        NSArray<CJPayDefaultChannelShowConfig *> *defaultChannelShowConfigArray = self.response.payTypeInfo.allSumInfoPayChannels;
        [self.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.freqSuggestStyleIndexList enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objIndex, NSUInteger idx, BOOL * _Nonnull stop) {
            if (objIndex) {
                int indexInAllPayChannel = objIndex.intValue;
                [defaultChannelShowConfigArray enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.index == indexInAllPayChannel) {
                        CJPayChannelBizModel *model = [obj toBizModel];
                        model.selectPageGuideText = @""; // 产品需要 在新客的样式下不展示这个字段， 与安卓对齐
                        [array addObject:model];
                        *stop = YES;
                    }
                }];
            }
        }];
    }
    
    return [array copy];
}

- (CJPayDefaultChannelShowConfig *)getSuggestChannelByIndex:(int)index {
    NSNumber *indexNumber = [self.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.freqSuggestStyleIndexList cj_objectAtIndex:index];
    if (indexNumber) {
        int indexInAllPayChannel = indexNumber.intValue;
        NSArray<CJPayDefaultChannelShowConfig *> *defaultChannelShowConfigArray = self.response.payTypeInfo.allSumInfoPayChannels;
        __block CJPayDefaultChannelShowConfig *findedConfig;
        [defaultChannelShowConfigArray enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.index == indexInAllPayChannel) {
                findedConfig = obj;
                *stop = YES;
            }
        }];
        return findedConfig;
    }
    
    return nil;
}

#pragma mark - lazy views

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.font = [UIFont cj_fontOfSize:12];
        _tipsLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipsLabel;
}

- (CJPaySafeInputView *)inputPasswordView {
    if (!_inputPasswordView) {
        // iPad场景不需要键盘
        _inputPasswordView = [[CJPaySafeInputView alloc] initWithKeyboardForDenoise:!CJ_Pad];
        _inputPasswordView.showCursor = NO;
        _inputPasswordView.textColor = UIColor.clearColor;
        _inputPasswordView.safeInputDelegate = self;
        [self setShowKeyBoardSafeGuard:NO];
    }
    return _inputPasswordView;
}

- (CJPayErrorInfoActionView *)errorInfoActionView {
    if (!_errorInfoActionView) {
        _errorInfoActionView = [CJPayErrorInfoActionView new];
        _errorInfoActionView.hidden = YES;
        @CJWeakify(self)
        [_errorInfoActionView.verifyItemBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.errorInfoActionView.verifyItemBtn);
            [self p_trackForForgetClick];
            CJ_CALL_BLOCK(self.otherVerifyPayBlock, @"forget_pwd_verify");
        }];
    }
    return _errorInfoActionView;
}

- (CJPayButton *)forgetPasswordBtn {
    if (!_forgetPasswordBtn) {
        _forgetPasswordBtn = [CJPayButton new];
        _forgetPasswordBtn.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_forgetPasswordBtn setTitleColor:[UIColor cj_forgetPWDColor] forState:UIControlStateNormal];
        [_forgetPasswordBtn cj_setBtnSelectColor:[UIColor cj_forgetPWDSelectColor]];
        [_forgetPasswordBtn setTitle:CJPayLocalizedStr(@"忘记密码") forState:UIControlStateNormal];
        @CJWeakify(self)
        [_forgetPasswordBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.forgetPasswordBtn);
            [self p_trackForForgetClick];
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock);
        }];
    }
    return _forgetPasswordBtn;
}

- (CJPayButton *)otherVerifyButton {
    if (!_otherVerifyButton) {
        _otherVerifyButton = [CJPayButton new];
        _otherVerifyButton.hidden = YES;//懒加载的地方可能并没有addsubview
        _otherVerifyButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_otherVerifyButton setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        
        if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FACEID"]) {
            [_otherVerifyButton setTitle:CJPayLocalizedStr(@"面容支付") forState:UIControlStateNormal];
        } else if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FINGER"]) {
            [_otherVerifyButton setTitle:CJPayLocalizedStr(@"指纹支付") forState:UIControlStateNormal];
        } else if (self.isFromOpenBioPayVerify) {
            [_otherVerifyButton setTitle:CJPayLocalizedStr(@"刷脸验证") forState:UIControlStateNormal];
        } else {
            [_otherVerifyButton setTitle:CJPayLocalizedStr(self.response.topRightBtnInfo.desc) forState:UIControlStateNormal];
        }
        
        _otherVerifyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _otherVerifyButton.titleLabel.minimumScaleFactor = 0.1;
        @CJWeakify(self)
        [_otherVerifyButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.otherVerifyButton);
            [self trackWithEventName:@"wallet_password_verify_page_right_click"
                              params:@{@"button_name": CJString(self.otherVerifyButton.titleLabel.text)}];
            CJ_CALL_BLOCK(self.otherVerifyPayBlock, nil);
        }];
    }
    return _otherVerifyButton;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleCompact isShowVoucherMsg:NO];
        self.response.payInfo.isGuideCheck = self.response.skipPwdGuideInfoModel.isChecked || self.response.preBioGuideInfo.choose;
        [_marketingMsgView updateWithModel:self.response];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,_marketingMsgView);
    }
    return _marketingMsgView;
}

#pragma mark - lazy object
- (CJPayForgetPwdOptController *)forgetPwdController {
    if (!_forgetPwdController) {
        _forgetPwdController = [CJPayForgetPwdOptController new];
        _forgetPwdController.response = self.response;
        _forgetPwdController.faceRecogPayBlock = [self.faceRecogPayBlock copy];
        @CJWeakify(self)
        _forgetPwdController.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
            @CJStrongify(self)
            [self trackWithEventName:event params:params];
        };
    }
    return _forgetPwdController;
}

@end
