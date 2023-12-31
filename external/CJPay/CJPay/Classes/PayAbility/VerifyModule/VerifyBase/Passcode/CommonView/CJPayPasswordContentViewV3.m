//
//  CJPayPasswordContentViewV3.m
//  CJPaySandBox
//
//  Created by xutianxi on 2023/03/01.
//

#import "CJPayPasswordContentViewV3.h"
//#import "CJPayVerifyPasswordViewModel.h"

#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPopUpBaseViewController.h"

#import "CJPayChoosedPayMethodViewV3.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleButton.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayLineUtil.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPaySuggestAddCardView.h"
#import "CJPayChannelBizModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayDynamicLayoutModel.h"
#import "CJPayDynamicLayoutView.h"
#import "CJPayDeductDetailView.h"
#import "CJPayOutDisplayInfoModel.h"
#import "CJPaySDKDefine.h"

#import <ByteDanceKit/UIView+BTDAdditions.h>

@interface CJPayPasswordContentViewV3 () <CJPaySafeInputViewDelegate, CJPayDynamicLayoutViewDelegate>

// subviews
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView; // 金额和营销区
@property (nonatomic, strong) UIView *scrollContentView; // 放scrollView的地方
@property (nonatomic, strong) UIScrollView *scrollView; // 过高的话让deductDetailView可滑动
@property (nonatomic, strong) UIImageView *scrollViewImageView; // scrollView上的渐变蒙层
@property (nonatomic, strong) CJPayDeductDetailView *deductDetailView; // O项目 「签约信息前置」 签约信息区
@property (nonatomic, strong) CJPayChoosedPayMethodViewV3 *choosedPayMethodView; // 支付方式展示区
@property (nonatomic, strong) CJPaySuggestAddCardView *suggestAddCardView; // 支付方式展示区
@property (nonatomic, strong) CJPaySafeInputView *inputPasswordView; // 密码输入框
@property (nonatomic, strong) CJPayErrorInfoActionView *errorInfoActionView; // 错误文案提示
@property (nonatomic, strong) CJPayGuideWithConfirmView *guideView; // 支付中引导
@property (nonatomic, strong) UILabel *inputPasswordTitle; // 请输入支付密码
@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, assign) BOOL isPasswordVerifyStyle;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayButton *forgetPasswordBtn; // 忘记密码按钮
@property (nonatomic, strong) UILabel *merchantNameLabel; // 商户名称

@property (nonatomic, strong) MASConstraint *passwordViewZoneBottomBaseInputviewConstraint; //inputPasswordZone底部约束基于inputPasswordView
@property (nonatomic, strong) MASConstraint *passwordViewZoneBottomBaseForgetBtnConstraint; //inputPasswordZone底部约束基于forgetPwdBtn

@property (nonatomic, strong) CJPayDynamicLayoutView *dynamicContentView; // 自撑开布局view
@property (nonatomic, strong) UIView *inputPasswordViewZone; // 高半屏特有视图（密码输入框+相关提示+忘记密码）
@property (nonatomic, strong) UIView *confirmButtonViewZone; // 矮半屏特有视图（确认按钮+安全险）

@property (nonatomic, strong) NSMutableArray<UIView *> *dynamicViewList; // 参与自适应布局的UI组件list
@property (nonatomic, assign) CGRect lastFrame;

@property (nonatomic, copy) NSString *merchantVoucher; // 商家挽留营销内容【用于「前置签约」合并后返营销】

@end

@implementation CJPayPasswordContentViewV3

//- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
//    return [self initWithViewModel:viewModel originStatus:CJPayPasswordContentViewStatusPassword];
//}

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel originStatus:(CJPayPasswordContentViewStatus)status {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateDeductViewWithMerchantVoucher:) name:CJPayClickRetainPerformNotification object:nil];
        self.viewModel = viewModel;
        if (viewModel.isDynamicLayout) {
            _isPasswordVerifyStyle = status == CJPayPasswordContentViewStatusPassword;
        } else {
            _isPasswordVerifyStyle = YES;
        }
        _status = status;
        [self p_setupUI];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)p_setupUIForSuggestCard {
    [self addSubview:self.marketingMsgView];
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self);
        make.left.right.equalTo(self);
        make.centerX.equalTo(self);
    });
    
    [self addSubview:self.suggestAddCardView];
    CJPayMasMaker(self.suggestAddCardView, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(32);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    });
    
    [self addSubview:self.confirmButton];
    self.confirmButton.hidden = NO;
    [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(self.viewModel.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.tradeConfirmButtonLabel)];
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.suggestAddCardView.mas_bottom).offset(80);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self).offset(-34);
    });
}

- (void)p_setupUI {
    // 自适应高度（动态化）布局
    if (self.viewModel.isDynamicLayout) {
        [self p_setupUIForDynamicLayout];
        return;
    }
    
    if ([self.viewModel isSuggestCardStyle]) {
        // 新客推荐卡样式
        [self p_setupUIForSuggestCard];
        return;
    }
    
    [self addSubview:self.marketingMsgView];
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self);
        make.left.right.equalTo(self);
        make.centerX.equalTo(self);
    });
    
    [self addSubview:self.choosedPayMethodView];
    [self addSubview:self.inputPasswordView];
    [self addSubview:self.errorInfoActionView];
    [self addSubview:self.confirmButton];
    if (self.viewModel.hideChoosedPayMethodView) {
        CJPayMasMaker(self.inputPasswordView, {
            make.top.equalTo(self.marketingMsgView.mas_bottom).offset(20);
            make.height.mas_equalTo(48);
            make.left.equalTo(self).offset(24);
            make.right.equalTo(self).offset(-24);
        });
    } else {
        self.choosedPayMethodView.hidden = NO;
        CJPayMasMaker(self.choosedPayMethodView, {
            make.top.greaterThanOrEqualTo(self.marketingMsgView.priceView.mas_bottom).offset(58);
            make.top.equalTo(self.marketingMsgView.mas_bottom).offset(40).priorityLow();
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
        });
        
        [CJPayLineUtil addTopLineToView:self.choosedPayMethodView marginLeft:0 marginRight:0 marginTop:-16];
        [self addSubview:self.inputPasswordTitle];
        CGFloat screenWidth = [UIDevice btd_screenWidth];
        CJPayMasMaker(self.inputPasswordTitle, {
            if (screenWidth >= 390) {
                make.top.equalTo(self.choosedPayMethodView).offset(88);
            } else {
                make.top.equalTo(self.choosedPayMethodView).offset(90);
            }
            make.centerX.equalTo(self);
            make.height.mas_equalTo(18);
        });
        
        CJPayMasMaker(self.inputPasswordView, {
            if (screenWidth >= 390) {
                make.top.equalTo(self.inputPasswordTitle.mas_bottom).offset(10);
                make.height.mas_equalTo(44);
                make.width.mas_equalTo(304);
            } else {
                make.top.equalTo(self.inputPasswordTitle.mas_bottom).offset(12);
                make.height.mas_equalTo(40);
                make.width.mas_equalTo(280);
            }
            make.centerX.equalTo(self);
        });
    }
    
    CJPayMasMaker(self.errorInfoActionView, {
        make.top.equalTo(self.inputPasswordView.mas_bottom).offset(10);
        make.centerX.equalTo(self.inputPasswordView);
    });
    
    CJPayMasMaker(self.confirmButton, {
        if (CJ_IPhoneX) {
            make.top.equalTo(self.choosedPayMethodView).offset(121);
        } else {
            make.top.equalTo(self.choosedPayMethodView).offset(110);
        }
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(44);
    });
    
    if ([self.viewModel isNeedShowGuide]) {
        [self addSubview:self.guideView];
        CJPayMasMaker(self.guideView, {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.top.equalTo(self.inputPasswordView.mas_bottom).offset(35);//offset(43);
            make.bottom.equalTo(self).offset(-16);
        });
    }
}

// 自适应高度（动态化）布局
- (void)p_setupUIForDynamicLayout {
    if ([self.viewModel isSuggestCardStyle]) {
        self.status = CJPayPasswordContentViewStatusOnlyAddCard;
    }
    self.dynamicViewList = [self p_createDynamicLayoutList];
    [self addSubview:self.dynamicContentView];
    CJPayMasMaker(self.dynamicContentView, {
        make.edges.equalTo(self);
    });
    [self.dynamicContentView updateWithContentViews:self.dynamicViewList isLayoutInstantly:NO];
}


// 记录参与自适应布局的UI组件
- (NSMutableArray<UIView *> *)p_createDynamicLayoutList {
    NSMutableArray<UIView *> *layoutViewsRecord = [NSMutableArray new];
    
    BOOL needShowMerchantLabel = !self.viewModel.hideMerchantNameLabel && Check_ValidString(self.viewModel.response.merchant.merchantShortToCustomer);
    [layoutViewsRecord addObject:self.merchantNameLabel];  // 商户名称
    
    [layoutViewsRecord addObject:self.marketingMsgView]; // 金额和营销UI组件
    if (needShowMerchantLabel) {
        self.marketingMsgView.cj_dynamicLayoutModel.topMargin = 0;
    }
    
    if ([self.viewModel.response.payTypeInfo.outDisplayInfo isShowDeductDetailViewMode]) {
        [layoutViewsRecord addObject:self.deductDetailView];// O项目「签约信息前置」 签约信息详情页
    }
    
    if ([self.viewModel isSuggestCardStyle]) {
        [layoutViewsRecord addObject:self.suggestAddCardView]; // 新客绑卡UI组件
    }

    [layoutViewsRecord addObject:self.choosedPayMethodView]; // 切换支付方式UI组件
    if (_deductDetailView && ![_deductDetailView isHidden]) {
        _choosedPayMethodView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:32 bottomMargin:0 leftMargin:20 rightMargin:20];
    }
    [CJPayLineUtil addTopLineToView:self.choosedPayMethodView marginLeft:0 marginRight:0 marginTop:-16];

    self.inputPasswordViewZone = [self p_createInputPasswordViewZone];
    [layoutViewsRecord addObject:self.inputPasswordViewZone]; // 密码输入UI组件（密码文案提示+输入框+忘记密码按钮）
    
    CGFloat guideViewInset = (CJ_SCREEN_WIDTH - [self p_inputPasswordViewWidth]) / 2; //guideView边距与密码输入框对齐
    self.guideView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:12 bottomMargin:0 leftMargin:guideViewInset rightMargin:guideViewInset];
    self.guideView.cj_dynamicLayoutModel.clickViews = @[self.guideView.clickView];
    [layoutViewsRecord addObject:self.guideView]; // 支付中引导UI组件
    
    self.confirmButtonViewZone = [self p_createConfirmButtonZone];
    [layoutViewsRecord addObject:self.confirmButtonViewZone]; // 确认按钮UI组件（确认按钮+安全险）
    
    [self p_updatePasswordViewStatus:self.status];

    return layoutViewsRecord;
}

// 构造用于自适应布局的验密区组件（密码输入框+错误文案提示+忘记密码按钮）
- (UIView *)p_createInputPasswordViewZone {
    UIView *inputPasswordZone = [UIView new];
    inputPasswordZone.backgroundColor = [UIColor clearColor];
    [inputPasswordZone addSubview:self.inputPasswordView];
    [inputPasswordZone addSubview:self.errorInfoActionView];
    [inputPasswordZone addSubview:self.forgetPasswordBtn];
    
    CJPayMasMaker(self.errorInfoActionView, {
        make.top.equalTo(inputPasswordZone);
        make.centerX.equalTo(inputPasswordZone);
        make.left.greaterThanOrEqualTo(self.inputPasswordView);
        make.right.lessThanOrEqualTo(self.inputPasswordView);
        make.height.mas_equalTo(18);
    });
    
    CJPayMasMaker(self.inputPasswordView, {
        make.top.equalTo(self.errorInfoActionView.mas_bottom).offset(12);
        make.centerX.equalTo(inputPasswordZone);
        make.width.mas_equalTo([self p_inputPasswordViewWidth]);
        make.height.mas_equalTo([self p_getPasswordItemWidth]);
        self.passwordViewZoneBottomBaseInputviewConstraint = make.bottom.equalTo(inputPasswordZone);
    });
    
    CJPayMasReMaker(self.forgetPasswordBtn, {
        make.top.equalTo(self.inputPasswordView.mas_bottom).offset(12);
        make.centerX.equalTo(inputPasswordZone);
        make.height.mas_equalTo(18);
        self.passwordViewZoneBottomBaseForgetBtnConstraint = make.bottom.equalTo(inputPasswordZone);
    });
    
    [self p_updatePasswordZoneConstraint];
        
    inputPasswordZone.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:24 bottomMargin:0 leftMargin:0 rightMargin:0];
    return inputPasswordZone;
}

// 更新”密码输入区UI“的底部约束逻辑
- (void)p_updatePasswordZoneConstraint {
    
    if ([self.viewModel isNeedShowFixForgetButton]) {
        self.forgetPasswordBtn.hidden = NO;
        [self.passwordViewZoneBottomBaseInputviewConstraint deactivate];
        [self.passwordViewZoneBottomBaseForgetBtnConstraint activate];
    } else {
        self.forgetPasswordBtn.hidden = YES;
        [self.passwordViewZoneBottomBaseInputviewConstraint activate];
        [self.passwordViewZoneBottomBaseForgetBtnConstraint deactivate];
    }
    
}

// 单个密码输入框的宽度
- (CGFloat)p_getPasswordItemWidth {
    return CJ_SCREEN_WIDTH < 390 ? 40 : 44;
}

// inputPasswordView总宽度（输入框间距固定为8）
- (CGFloat)p_inputPasswordViewWidth {
    return 6 * [self p_getPasswordItemWidth] + 5 * 8;
}

// 构造用于自适应布局的确认按钮区组件（确认按钮+安全险）
- (UIView *)p_createConfirmButtonZone {
    UIView *confirmZone = [UIView new];
    confirmZone.backgroundColor = [UIColor clearColor];
    [confirmZone addSubview:self.confirmButton];
    [confirmZone addSubview:self.safeGuardTipView];
    
    self.confirmButton.hidden = NO;
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(confirmZone);
        make.centerX.equalTo(confirmZone);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(44);
    });
    
    self.safeGuardTipView.hidden = ![CJPayAccountInsuranceTipView shouldShow];
    CJPayMasMaker(self.safeGuardTipView, {
        make.top.equalTo(self.confirmButton.mas_bottom).offset(40);
        make.bottom.equalTo(confirmZone);
        make.centerX.equalTo(confirmZone);
        make.height.mas_equalTo(18);
    });
    confirmZone.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:56 bottomMargin:12 leftMargin:0 rightMargin:0];
    return confirmZone;
}

// O项目V3页面切换高矮形态（非动态化场景使用）
- (void)usePasswordVerifyStyle:(BOOL)isPasswordVerifyStyle {
    [self btd_removeAllSubviews];
    [self p_setupUI];
    
    _isPasswordVerifyStyle = isPasswordVerifyStyle;
    if (_isPasswordVerifyStyle) {
        self.confirmButton.hidden = YES;
        self.inputPasswordTitle.hidden = NO;
        self.inputPasswordView.hidden = NO;
        self.errorInfoActionView.hidden = NO;
        self.guideView.hidden = NO;
        [self.safeGuardTipView removeFromSuperview];
    } else {
        self.confirmButton.hidden = NO;
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            [self addSubview:self.safeGuardTipView];
            CJPayMasMaker(self.safeGuardTipView, {
                make.centerX.equalTo(self);
                make.height.mas_equalTo(18);
                make.top.greaterThanOrEqualTo(self.confirmButton.mas_bottom).offset(17);
            });
        }
        self.inputPasswordTitle.hidden = YES;
        self.inputPasswordView.hidden = YES;
        self.errorInfoActionView.hidden = YES;
        self.guideView.hidden = YES;
    }
}

// 更新choosedPayMethodView的显隐状态（动态化场景使用）
- (void)updateChoosedPayMethodViewHiddenStatus:(BOOL)isHidden {
    if (!self.viewModel.isDynamicLayout) {
        return;
    }
    
    self.choosedPayMethodView.hidden = isHidden;
    if ([self.dynamicViewList containsObject:self.choosedPayMethodView]) {
        [self.dynamicContentView setDynamicLayoutSubviewHiddenStatus:@[self.choosedPayMethodView]];
        return;
    }
    
    if (isHidden) {
        [self.dynamicViewList removeObject:self.choosedPayMethodView];
        [self.dynamicContentView removeDynamicLayoutSubview:self.choosedPayMethodView];
    } else {
        NSUInteger preIndex = [self.dynamicViewList indexOfObject:self.marketingMsgView];
        [self.dynamicViewList insertObject:self.choosedPayMethodView atIndex:preIndex+1];
        [self.dynamicContentView insertDynamicLayoutSubview:self.choosedPayMethodView atIndex:preIndex+1];
    }
}

// O项目V3页面切换形态（动态化场景使用）
- (void)switchPasswordViewStatus:(CJPayPasswordContentViewStatus)status {
    if (!self.viewModel.isDynamicLayout) {
        return;
    }

    self.isPasswordVerifyStyle = status == CJPayPasswordContentViewStatusPassword;
    self.status = status;
    [self p_updatePasswordViewStatus:status];
    
    // 更新动态化布局中arrangedSubview的显隐状态
    [self.dynamicContentView setDynamicLayoutSubviewHiddenStatus:self.dynamicViewList];
}

// 根据当前形态决定各UI组件的显隐状态
- (void)p_updatePasswordViewStatus:(CJPayPasswordContentViewStatus)status {
    
    self.merchantNameLabel.hidden = self.viewModel.hideMerchantNameLabel || !Check_ValidString(self.viewModel.response.merchant.merchantShortToCustomer);
    self.marketingMsgView.hidden = self.viewModel.hideMarketingView;
    
    BOOL needShowChooseMethodView = [self.viewModel isNeedShowChooseMethodView];
    switch (status) {
        case CJPayPasswordContentViewStatusPassword: {
            self.choosedPayMethodView.hidden = !needShowChooseMethodView;
            self.suggestAddCardView.hidden = YES;
            self.confirmButtonViewZone.hidden = YES;
            self.inputPasswordViewZone.hidden = NO;
            self.guideView.hidden = ![self.viewModel isNeedShowGuide];
            break;
        }
        case CJPayPasswordContentViewStatusLowConfirm: {
            self.choosedPayMethodView.hidden = !needShowChooseMethodView;
            self.suggestAddCardView.hidden = YES;
            self.confirmButtonViewZone.hidden = NO;
            self.inputPasswordViewZone.hidden = YES;
            self.guideView.hidden = YES;
            break;
        }
        case CJPayPasswordContentViewStatusOnlyAddCard: {
            self.choosedPayMethodView.hidden = YES;
            self.suggestAddCardView.hidden = ![self.viewModel isSuggestCardStyle];
            self.confirmButtonViewZone.hidden = NO;
            self.inputPasswordViewZone.hidden = YES;
            self.guideView.hidden = YES;
            break;
        }
        default:
            break;
    }
}

// 根据选中支付方式更新页面信息
- (void)updatePayConfigContent:(NSArray<CJPayDefaultChannelShowConfig *> *)configs {
    if (!Check_ValidArray(configs)) {
        return;
    }
    [self.choosedPayMethodView updateContentByChannelConfigs:configs]; // 更新支付方式信息
    if (configs.count >= 1) {
        CJPayDefaultChannelShowConfig *selectConfig = [configs cj_objectAtIndex:0];
        NSString *payAmountStr = CJString(selectConfig.payAmount);
        NSString *payVoucherStr = CJString(selectConfig.payVoucherMsg);
        if (selectConfig.isCombinePay && selectConfig.payTypeData.combinePayInfo) {
            // 组合支付
            payAmountStr = CJString(selectConfig.payTypeData.combinePayInfo.standardShowAmount);
            payVoucherStr = CJString(selectConfig.payTypeData.combinePayInfo.standardRecDesc);
        }
        if (selectConfig.type == BDPayChannelTypeCreditPay) {
            payAmountStr = CJString(selectConfig.payTypeData.curSelectCredit.standardShowAmount);
            payVoucherStr = CJString(selectConfig.payTypeData.curSelectCredit.standardRecDesc);
        }
        if (self.viewModel.outDisplayInfoModel) {
            // 如果走到了O项目「签约信息前置」则更新金额和营销
            payAmountStr = [self p_updateSignPayMarketingAmount:payAmountStr];
            payVoucherStr = [self p_updateSignPayMarketingVoucher:payVoucherStr];
        }
        [self.marketingMsgView updateWithPayAmount:payAmountStr voucherMsg:payVoucherStr]; // 更新金额和营销
        // 这里还要更新签约详情View。
        [self p_updateDeductDetailView:self.deductDetailView defaultConfig:selectConfig];
    }
}

- (void)updateDeductViewWhenNewCustomer:(CJPayDefaultChannelShowConfig *)config {
    if (!config) {
        return;
    }
    [self p_updateDeductDetailView:self.deductDetailView defaultConfig:config];
}

//更新O项目「签约信息前置」的签约详情信息。
- (void)p_updateDeductDetailView:(CJPayDeductDetailView *)deductDetailView defaultConfig:(CJPayDefaultChannelShowConfig *)defaultConfig {
    CJPayBDCreateOrderResponse *response = self.viewModel.response;
    CJPayOutDisplayInfoModel *outDisplayInfo = response.payTypeInfo.outDisplayInfo;
    CJPaySignPayCashierStyleType cashierStyleType = [outDisplayInfo obtainSignPayCashierStyle];
    
    if (![outDisplayInfo isShowDeductDetailViewMode]) {
        return;
    }
    
    // 标题数组
    NSString *serviceTitle = CJString(outDisplayInfo.serviceDescText);
    NSString *originAmountTitle = CJString([defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypeOrderAmountText]);
    NSString *voucherTitle = CJString(defaultConfig.payTypeData.voucherDescText);
    NSString *addGiftTitle = CJString(outDisplayInfo.afterPaySuccessText);
    // 相关描述数组
    NSString *serviceDesc = CJString(outDisplayInfo.serviceDescName);
    NSString *originAmountDesc = [NSString stringWithFormat:@"¥%.2f", response.tradeInfo.tradeAmount / (double)100];
    originAmountDesc = CJString(originAmountDesc);
    NSString *addGiftDesc = CJString([defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypePayBackVoucher]);
    NSString *finalGiftDesc = addGiftDesc;
    if (Check_ValidString(self.merchantVoucher) && Check_ValidString(addGiftDesc)) {
        finalGiftDesc = [NSString stringWithFormat:@"%@，%@",self.merchantVoucher,addGiftDesc];
    } else if (Check_ValidString(self.merchantVoucher)) {
        finalGiftDesc = self.merchantVoucher;
    }
    finalGiftDesc = CJString(finalGiftDesc);
    
    // 只需要在模式2，3的时候 才需要设置签约信息前置。
    if (cashierStyleType == CJPaySignPayCashierStyleTypeFrontSignPayComplex) {
        NSString *voucherDesc = CJString([defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypeSubPayTypeVoucher]);
        if (defaultConfig.isCombinePay) {
            voucherDesc = CJString([defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypeSubPayTypeCombineVoucher]);
        }
        NSArray *titleArray = @[serviceTitle, originAmountTitle, voucherTitle, addGiftTitle];
        NSArray *descArray = @[serviceDesc,originAmountDesc,voucherDesc,finalGiftDesc];
        NSArray *isDescHighLightArray = @[@(NO),@(NO),@(YES),@(YES)];
        [deductDetailView updateDeductDetailWithTitleArray:titleArray descArray:descArray isDescHighLightArray:isDescHighLightArray];
        // 这里可能会更新deductDetailView的显隐态
        [self.dynamicContentView setDynamicLayoutSubviewHiddenStatus:self.dynamicViewList];
        [self deductDetailViewNeedScroll:NO deductDetailHeight:0]; // 需要在这里刷刷一下可滑动状态（手动改变一下验密页的frame），防止验密页顶到最上面，frame无法改变。
    } else if (CJPaySignPayCashierStyleTypeFrontSignDeductSimple) {
        NSString *voucherDesc;
        if (self.viewModel.response.userInfo.isNewUser) { // 模式3的时候，新客立减营销描述 取area里面的营销，老客取汇总营销
            voucherDesc = CJString([defaultConfig.payTypeData obtainOutDisplayMsg:CJPayOutDisplayTradeAreaMsgTypeSubPayTypeVoucher]);
        } else {
            voucherDesc = CJString(outDisplayInfo.promotionDesc);
        }
        NSArray *titleArray = @[originAmountTitle, voucherTitle, addGiftTitle];
        NSArray *descArray = @[originAmountDesc,voucherDesc,finalGiftDesc];
        NSArray *isDescHighLightArray = @[@(NO),@(YES),@(YES)];
        [deductDetailView updateDeductDetailWithTitleArray:titleArray descArray:descArray isDescHighLightArray:isDescHighLightArray];
        // 这里可能会更新deductDetailView的显隐态
        [self.dynamicContentView setDynamicLayoutSubviewHiddenStatus:self.dynamicViewList];
        [self deductDetailViewNeedScroll:NO deductDetailHeight:0]; // 需要在这里刷刷一下可滑动状态（手动改变一下验密页的frame），防止验密页顶到最上面，frame无法改变。
    }
}

- (NSString *)p_updateSignPayMarketingAmount:(NSString *)amountStr {
    NSString *payAmountStr;
    if ([self.viewModel.outDisplayInfoModel isDeductPayMode]) {
        payAmountStr = CJString(self.viewModel.outDisplayInfoModel.realTradeAmount);
    } else {
        payAmountStr = amountStr;
    }
    return payAmountStr;
}

// 更新O项目「签约信息前置」 金额下面的营销
- (NSString *)p_updateSignPayMarketingVoucher:(NSString *)voucherStr {
    NSString *payVoucherStr;
    CJPaySignPayCashierStyleType cashierStyleType = [self.viewModel.outDisplayInfoModel obtainSignPayCashierStyle];
    if (cashierStyleType == CJPaySignPayCashierStyleTypeFrontSignDeductComplex) {
        payVoucherStr = CJString(self.viewModel.outDisplayInfoModel.promotionDesc);
    } else if (cashierStyleType == CJPaySignPayCashierStyleTypeFrontSignPayComplex || cashierStyleType == CJPaySignPayCashierStyleTypeFrontSignDeductSimple) {
        payVoucherStr = @"";
    } else {
        payVoucherStr = CJString(voucherStr);
    }
    return payVoucherStr;
}

- (void)p_updateDeductViewWithMerchantVoucher:(NSNotification *)notification {
    if (![notification isKindOfClass:NSNotification.class]) {
        return;
    }
    if ([notification.object isKindOfClass:NSDictionary.class]) {
        NSDictionary *params = notification.object;
        self.merchantVoucher = [params cj_stringValueForKey:@"merchant_voucher"];
        [self p_updateDeductDetailView:self.deductDetailView defaultConfig:self.viewModel.defaultConfig];
        return;
    }
    if ([notification.object isKindOfClass:NSString.class]) {
        self.merchantVoucher = notification.object;
        [self p_updateDeductDetailView:self.deductDetailView defaultConfig:self.viewModel.defaultConfig];
    }
}

- (void)deductDetailViewNeedScroll:(BOOL)isNeedScroll deductDetailHeight:(CGFloat)deductScrollHeight {
    if (![self.viewModel.outDisplayInfoModel isShowDeductDetailViewMode]) {
        //这两种模式下不会展示签约信息详情View
        return;
    }
    if (!Check_ValidArray(self.dynamicViewList)) { // 在未初始化的时候就可能会调用该方法，这里加一个判断
        return;
    }
    NSInteger insertIndex;
    NSInteger deductDetailViewIndex = [self.dynamicViewList indexOfObject:self.deductDetailView];
    NSInteger scrollContentViewIndex = [self.dynamicViewList indexOfObject:self.scrollContentView];
    
    if (deductDetailViewIndex != NSNotFound) {
        insertIndex = deductDetailViewIndex;
    } else if (scrollContentViewIndex != NSNotFound) {
        insertIndex = scrollContentViewIndex;
    }
    if(isNeedScroll) {
        [self.scrollContentView addSubview:self.scrollView];
        [self.scrollContentView addSubview:self.scrollViewImageView];
        [self.scrollView addSubview:self.deductDetailView];
        // 强制scrollView的高度
        self.scrollContentView.cj_dynamicLayoutModel.forceHeight = deductScrollHeight;
        
        CJPayMasReMaker(self.scrollViewImageView, {
            make.bottom.mas_equalTo(self.scrollContentView);
            make.height.mas_equalTo(20);
            make.width.mas_equalTo(CJ_SCREEN_WIDTH - 8);
        });
        
        CJPayMasReMaker(self.scrollView, {
            make.edges.width.mas_equalTo(self.scrollContentView);
        });
        
        CJPayMasReMaker(self.deductDetailView, {
            make.edges.width.mas_equalTo(self.scrollView);
        });
        
        [self p_removeDeductDetailViewComponent];
        
        [self.dynamicViewList btd_insertObject:self.scrollContentView atIndex:insertIndex];
        [self.dynamicContentView insertDynamicLayoutSubview:self.scrollContentView atIndex:insertIndex];
    } else {
        [self.scrollView cj_removeAllSubViews];
        [self.scrollContentView cj_removeAllSubViews];
        
        [self p_removeDeductDetailViewComponent];
        
        [self.dynamicViewList btd_insertObject:self.deductDetailView atIndex:insertIndex];
        [self.dynamicContentView insertDynamicLayoutSubview:self.deductDetailView atIndex:insertIndex];
    }
}

- (void)p_removeDeductDetailViewComponent {
    [self.dynamicViewList btd_removeObject:self.scrollContentView];
    [self.dynamicContentView removeDynamicLayoutSubview:self.scrollContentView];
    [self.dynamicViewList btd_removeObject:self.deductDetailView];
    [self.dynamicContentView removeDynamicLayoutSubview:self.deductDetailView];
}

// 使用viewModel.response刷新验密区和引导区UI（绑卡成功支付失败时调用）
- (void)refreshDynamicViewContent {
    if (!self.viewModel.isDynamicLayout) {
        return;
    }
    [self p_refreshGuideView];
    [self p_updatePasswordZoneConstraint];
    [self.errorInfoActionView showActionButton:NO];
    if (Check_ValidString(self.viewModel.passwordFixedTips)) {
        [self.errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypePasswordInputTips errorText:self.viewModel.passwordFixedTips];
    }
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

// 使用viewModel.response刷新支付中引导UI
- (void)p_refreshGuideView {
    BOOL isSkipppwdGuide = self.viewModel.response.skipPwdGuideInfoModel.needGuide;
    CJPayCommonProtocolModel *protocolModel = isSkipppwdGuide? [self buildProtocolModelBySkippwdGuide]: [self buildProtocolModelByBioGuide];
    [self.guideView updateProtocolModel:protocolModel isShowButton:[self.viewModel isShowComfirmButton]];
    [self p_resetGuideViewBtnTextWithChoose:protocolModel.isSelected];
}

// 构建支付中免密引导数据model
- (CJPayCommonProtocolModel *)buildProtocolModelBySkippwdGuide {
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    CJPaySkipPwdGuideInfoModel *guideModel = self.viewModel.response.skipPwdGuideInfoModel;
    protocolModel.guideDesc = guideModel.guideMessage;
    protocolModel.groupNameDic = guideModel.protocolGroupNames;
    protocolModel.agreements = guideModel.protocoList;
    protocolModel.isSelected = guideModel.isChecked || guideModel.isSelectedManually;
    
    self.viewModel.isGuideSelected = protocolModel.isSelected;
    protocolModel.selectPattern = [guideModel.style isEqualToString:@"SWITCH"] ? CJPaySelectButtonPatternSwitch : CJPaySelectButtonPatternCheckBox;
    protocolModel.protocolDetailContainerHeight = @(self.viewModel.passwordViewHeight);
    
    if (self.viewModel.isDynamicLayout) {
        protocolModel.isHorizontalCenterLayout = YES;
        protocolModel.protocolColor = [UIColor cj_161823WithAlpha:0.6];
        protocolModel.protocolFont = [UIFont cj_fontOfSize:12];
        protocolModel.protocolLineHeight = 17;
    }
    return protocolModel;
}

// 构建支付中生物引导数据model
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
    if (self.viewModel.isDynamicLayout) {
        protocolModel.isHorizontalCenterLayout = YES;
        protocolModel.protocolColor = [UIColor cj_161823WithAlpha:0.6];
        protocolModel.protocolFont = [UIFont cj_fontOfSize:12];
        protocolModel.protocolLineHeight = 17;
    }
    return protocolModel;
}

// 重置支付中引导的按钮文案
- (void)p_resetGuideViewBtnTextWithChoose:(BOOL)isChoosed {
    _guideView.confirmButton.enabled = NO;
    NSString *selectedBtnText = [self p_getGuideSelectedBtnText];
    NSString *buttonText = isChoosed ? selectedBtnText : CJPayLocalizedStr(@"确认支付");
    [_guideView.confirmButton cj_setBtnTitle:buttonText];
}

// 获取支付中引导选中时的按钮文案
- (NSString *)p_getGuideSelectedBtnText {
    BOOL isSkipppwdGuide = self.viewModel.response.skipPwdGuideInfoModel.needGuide;
    NSString *serverSelectedBtnText = isSkipppwdGuide ? self.viewModel.response.skipPwdGuideInfoModel.buttonText : self.viewModel.response.preBioGuideInfo.btnDesc;
    NSString *defaultSelectedBtnText = isSkipppwdGuide ? CJPayLocalizedStr(@"开通并支付") : CJPayLocalizedStr(@"确认升级并支付");
    
    NSString *selectedBtnText = Check_ValidString(serverSelectedBtnText) ? serverSelectedBtnText : defaultSelectedBtnText;
    return selectedBtnText;
}

#pragma mark - CJPaySafeInputViewDelegate

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    self.viewModel.passwordInputCompleteTimes = self.viewModel.passwordInputCompleteTimes + 1;
    CJ_CALL_BLOCK(self.inputCompleteBlock, currentStr);
}

- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr {
    if ([@[@(CJPayErrorInfoStatusTypeDowngradeTips), @(CJPayErrorInfoStatusTypePasswordErrorTips)] containsObject:@(self.errorInfoActionView.statusType)] && Check_ValidString(currentStr)) {
        
        if ([self.viewModel isNeedShowPasswordFixedTips]) {
            [self.errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypePasswordInputTips errorText:CJString(self.viewModel.passwordFixedTips)];
        } else {
            [self.errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypeHidden errorText:@""];
        }
    }
    
    if ([self.viewModel isNeedShowGuide]) {
        self.guideView.confirmButton.enabled = currentStr.length == 6;
    }
}

- (void)p_comfirmInputComplete {
    CJ_CALL_BLOCK(self.confirmBtnClickBlock, self.inputPasswordView.contentText);
    [CJKeyboard resignFirstResponder:self.inputPasswordView];
}

#pragma mark - CJPayPasswordViewProtocol
// 展示键盘
- (void)showKeyBoardView {
    [CJKeyboard becomeFirstResponder:self.inputPasswordView];
}

// 收起键盘
- (void)retractKeyBoardView {
    [CJKeyboard resignFirstResponder:self.inputPasswordView];
}

// 清空密码输入
- (void)clearPasswordInput {
    self.guideView.confirmButton.enabled = NO;
    [self.inputPasswordView clearInput];
}

// 输错密码后展示 错误提示文案
- (void)updateErrorText:(NSString *)text{
    if ([self.viewModel isDynamicLayout]) {
        [self.errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypePasswordErrorTips errorText:CJString(text)];
        [self.errorInfoActionView showActionButton:![self.viewModel isNeedShowFixForgetButton]];
    } else {
        self.errorInfoActionView.hidden = !Check_ValidString(text);
        self.errorInfoActionView.errorLabel.text = CJString(text);
    }
    [self.inputPasswordView becomeFirstResponder];
}

// 是否允许输入
- (void)setPasswordInputAllow:(BOOL)isAllow {
    self.inputPasswordView.allowBecomeFirstResponder = isAllow;
}

- (BOOL)hasInputHistory {
    return self.inputPasswordView.hasInputHistory;
}

#pragma mark - CJPayDynamicLayoutViewDelegate
// 动态化布局页面的frame发生变化时，通知外部
- (void)dynamicViewFrameChange:(CGRect)newFrame {
    CJ_CALL_BLOCK(self.dynamicViewFrameChangeBlock, newFrame);
}

#pragma mark - lazy views

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        MarketingMsgViewStyle style = self.viewModel.isDynamicLayout? MarketingMsgViewStyleDenoiseV2: MarketingMsgViewStyleMacro;
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:style isShowVoucherMsg:NO];
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
            if (self.viewModel.outDisplayInfoModel) {
                // 如果走到了O项目「签约信息前置」则更新金额和营销
                payAmountStr = [self p_updateSignPayMarketingAmount:payAmountStr];
                payVoucherStr = [self p_updateSignPayMarketingVoucher:payVoucherStr];
            }
            [_marketingMsgView updateWithPayAmount:payAmountStr voucherMsg:payVoucherStr];
        }
        _marketingMsgView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:8 bottomMargin:0 leftMargin:20 rightMargin:20];
    }
    return _marketingMsgView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [UIView new];
        _scrollContentView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:24 bottomMargin:0 leftMargin:4 rightMargin:4];
    }
    return _scrollContentView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = UIColor.clearColor;
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.clipsToBounds = YES;
        _scrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            [_scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _scrollView;
}

- (UIImageView *)scrollViewImageView {
    if (!_scrollViewImageView) {
        _scrollViewImageView = [[UIImageView alloc] initWithImage:[UIImage cj_imageWithName:@"cj_deduct_scroll_mask"]];
        CJPayDynamicLayoutModel *dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:-20 bottomMargin:0 leftMargin:4 rightMargin:4];
        dynamicLayoutModel.forceHeight = 20;
        _scrollViewImageView.cj_dynamicLayoutModel = dynamicLayoutModel;
    }
    return _scrollViewImageView;
}

- (CJPayDeductDetailView *)deductDetailView {
    if (!_deductDetailView) {
        _deductDetailView = [CJPayDeductDetailView new];
        
        [self p_updateDeductDetailView:_deductDetailView defaultConfig:self.viewModel.defaultConfig];
        _deductDetailView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:24 bottomMargin:0 leftMargin:4 rightMargin:4];
    }
    return _deductDetailView;
}

- (CJPaySuggestAddCardView *)suggestAddCardView {
    if (!_suggestAddCardView) {
        CJPaySuggestAddCardViewStyle style = [self.viewModel isHasSuggestCard] ? CJPaySuggestAddCardViewStyleWithSuggestCard : CJPaySuggestAddCardViewStyleWithoutSuggestCard;
        _suggestAddCardView = [[CJPaySuggestAddCardView alloc] initWithStyle:style];
        [_suggestAddCardView updateContent:[self.viewModel getSuggestChannelModelList]];
        if (style == CJPaySuggestAddCardViewStyleWithSuggestCard) {
            _suggestAddCardView.moreBankTipsLabel.text = CJString(self.viewModel.response.payTypeInfo.subPayTypeSumInfo.freqSuggestStyleInfo.titleButtonLabel);
        } else {
            CJPayDefaultChannelShowConfig *config = [self.viewModel getSuggestChannelByIndex:0];
            if ([config.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
                CJPaySubPayTypeInfoModel *channelModel = (CJPaySubPayTypeInfoModel *)config.payChannel;
                _suggestAddCardView.moreBankTipsLabel.text = CJString(channelModel.subTitle);
            }
        }
        @weakify(self);
        _suggestAddCardView.didClickedMoreBankBlock = ^{
            @strongify(self);
            CJ_CALL_BLOCK(self.didClickedMoreBankBlock);
        };
        _suggestAddCardView.didSelectedNewSuggestBankBlock = ^(int index) {
            @strongify(self);
            CJ_CALL_BLOCK(self.didSelectedNewSuggestBankBlock, index);
        };
        _suggestAddCardView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:32 bottomMargin:0 leftMargin:16 rightMargin:16];
    }
    
    return _suggestAddCardView;
}

- (CJPayChoosedPayMethodViewV3 *)choosedPayMethodView {
    if (!_choosedPayMethodView) {
        _choosedPayMethodView = [[CJPayChoosedPayMethodViewV3 alloc] initIsCombinePay:[self.viewModel isCombinedPay]];
        _choosedPayMethodView.canChangeCombineStatus = self.viewModel.canChangeCombineStatus;
        CJPayOutDisplayInfoModel *outDisplayInfo = self.viewModel.response.payTypeInfo.outDisplayInfo;
        if (outDisplayInfo) {
            [_choosedPayMethodView updatePayTypeTitle:CJString(outDisplayInfo.payTypeText)];
            _choosedPayMethodView.outDisplayInfoModel = outDisplayInfo;
        }
        [_choosedPayMethodView updateContentByChannelConfigs:self.viewModel.displayConfigs];
        
        @weakify(self);
        _choosedPayMethodView.clickedPayMethodBlock = ^{
            @strongify(self);
            CJ_CALL_BLOCK(self.clickedPayMethodBlock, @"0");
        };
        _choosedPayMethodView.clickedCombineBankPayMethodBlock = ^{
            @strongify(self);
            CJ_CALL_BLOCK(self.clickedCombinedPayBankPayMethodBlock, @"0");
        };
        _choosedPayMethodView.hidden = YES;
        _choosedPayMethodView.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:40 bottomMargin:0 leftMargin:20 rightMargin:20];
        _choosedPayMethodView.cj_dynamicLayoutModel.clickViews = @[_choosedPayMethodView.normalPayClickView, _choosedPayMethodView.combinePayClickView];
    }
    
    return _choosedPayMethodView;
}

- (UILabel *)inputPasswordTitle {
    if (!_inputPasswordTitle) {
        _inputPasswordTitle = [UILabel new];
        _inputPasswordTitle.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _inputPasswordTitle.textColor = [UIColor cj_161823WithAlpha:0.5];
        _inputPasswordTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _inputPasswordTitle;
}

- (CJPaySafeInputView *)inputPasswordView {
    if (!_inputPasswordView) {
        CJPaySafeInputViewStyleModel *model = [CJPaySafeInputViewStyleModel new];
        model.viewStyle = CJPayViewTypeDenoiseV2;
        model.needKeyboard = !CJ_Pad; // iPad场景不需要键盘
        model.fixedSpacing = 8;
        model.isDenoise = YES;
        _inputPasswordView = [[CJPaySafeInputView alloc] initWithInputViewStyleModel:model];

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
        if (self.viewModel.isDynamicLayout) {
            [_errorInfoActionView.verifyItemBtn cj_setBtnTitle:CJPayLocalizedStr(@"忘记密码")];
            if (Check_ValidString(self.viewModel.downgradePasswordTips)) {
                [_errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypeDowngradeTips errorText:CJString(self.viewModel.downgradePasswordTips)];
            } else if ([self.viewModel isNeedShowPasswordFixedTips]) {
                [_errorInfoActionView updateStatusWithType:CJPayErrorInfoStatusTypePasswordInputTips errorText:CJString(self.viewModel.passwordFixedTips)];
            }
        }
        
        @CJWeakify(self)
        [_errorInfoActionView.verifyItemBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.errorInfoActionView.verifyItemBtn);
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock, CJString(self.errorInfoActionView.verifyItemBtn.titleLabel.text));
        }];
    }
    return _errorInfoActionView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.cjEventInterval = 1;
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.layer.cornerRadius = 2;
        _confirmButton.clipsToBounds = YES;
        _confirmButton.hidden = YES;
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
        @CJWeakify(self)
        [_confirmButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.confirmBtnClickBlock, self.inputPasswordView.contentText);
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayGuideWithConfirmView *)guideView {
    if (!_guideView) {
        BOOL isSkipppwdGuide = self.viewModel.response.skipPwdGuideInfoModel.needGuide;
        CJPayCommonProtocolModel *protocolModel = isSkipppwdGuide? [self buildProtocolModelBySkippwdGuide]: [self buildProtocolModelByBioGuide];
        _guideView = [[CJPayGuideWithConfirmView alloc] initWithCommonProtocolModel:protocolModel isShowButton:[self.viewModel isShowComfirmButton]];
        
        [self p_resetGuideViewBtnTextWithChoose:protocolModel.isSelected];
        @CJWeakify(self)
        [_guideView.confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            [self p_comfirmInputComplete];
        }];
        _guideView.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.clickProtocolViewBlock);
        };
        _guideView.protocolView.checkBoxClickBlock = ^{
            @CJStrongify(self);
            BOOL isCheckBoxSelected = [self.guideView.protocolView isCheckBoxSelected];
            NSString *selectedBtnText = [self p_getGuideSelectedBtnText];
            [self.guideView.confirmButton cj_setBtnTitle:isCheckBoxSelected? CJString(selectedBtnText) : CJPayLocalizedStr(@"确认支付")];
            
            CJ_CALL_BLOCK(self.clickedGuideCheckboxBlock, isCheckBoxSelected);
        };
    }
    return _guideView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (UILabel *)merchantNameLabel {
    if (!_merchantNameLabel) {
        _merchantNameLabel = [UILabel new];
        _merchantNameLabel.font = [UIFont cj_fontOfSize:15];
        _merchantNameLabel.textColor = [UIColor cj_161823ff];
        _merchantNameLabel.textAlignment = NSTextAlignmentCenter;
        _merchantNameLabel.text = CJString(self.viewModel.response.merchant.merchantShortToCustomer);
        [_merchantNameLabel setContentHuggingPriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
        [_merchantNameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
        _merchantNameLabel.cj_dynamicLayoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:8 bottomMargin:0 leftMargin:0 rightMargin:0];
    }
    return _merchantNameLabel;
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
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock, CJString(self.forgetPasswordBtn.titleLabel.text));
        }];
    }
    return _forgetPasswordBtn;
}

- (NSMutableArray<UIView *> *)dynamicViewList {
    if (!_dynamicViewList) {
        _dynamicViewList = [NSMutableArray new];
    }
    return _dynamicViewList;
}

- (CJPayDynamicLayoutView *)dynamicContentView {
    if (!_dynamicContentView) {
        _dynamicContentView = [[CJPayDynamicLayoutView alloc] init];
        _dynamicContentView.delegate = self;
    }
    return _dynamicContentView;
}

- (UIView *)inputPasswordViewZone {
    if (!_inputPasswordViewZone) {
        _inputPasswordViewZone = [UIView new];
        _inputPasswordViewZone.backgroundColor = [UIColor clearColor];
    }
    return _inputPasswordViewZone;
}

- (UIView *)confirmButtonViewZone {
    if (!_confirmButtonViewZone) {
        _confirmButtonViewZone = [UIView new];
        _confirmButtonViewZone.backgroundColor = [UIColor clearColor];
    }
    return _confirmButtonViewZone;
}
@end
