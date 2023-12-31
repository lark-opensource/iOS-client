//
//  CJPayBizHybridHomePageViewController.m
//  Aweme
//
//  Created by wangxiaohong on 2023/3/3.
//

#import "CJPayBizHybridHomePageViewController.h"

#import "CJPayBaseLynxView.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayInComePayAlertContentView.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayTypeInfo.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayAlertUtil.h"
#import "CJPayManager.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayChannelModel.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayCreateOrderRequest.h"
#import "CJPayCreditPayChannelModel.h"
#import "CJPayBizWebViewController.h"

NSString *kEventGotoCardList = @"cjpay_go_to_cardlist";
NSString *kEventPayMethodClick = @"cjpay_paymethod_click";
NSString *kEventPayMethodDisable = @"cjpay_paymethod_disable";
NSString *kEventCardListPayMethodClick = @"cjpay_cardlist_paymethod_click";
NSString *kEventIncomePayClick = @"cjpay_income_pay_click";
NSString *kEventCombinePayLimit = @"cjpay_combinepay_limit";
NSString *kEventReload = @"cjpay_reload";
NSString *kEventError = @"cjpay_event_error";

@interface CJPayBizHybridHomePageViewController()<CJPayLynxViewDelegate>

@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayBaseLynxView *lynxView;
@property (nonatomic, strong) UIImageView *lynxDefaultImageView;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong) UIView *confirmButtonBgView;

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentPayConfig;

@property (nonatomic, copy, readonly) NSArray<CJPayDefaultChannelShowConfig *> *payChannelConfigs;

@property (nonatomic, copy, readonly) NSArray<CJPayDefaultChannelShowConfig *> *cardListConfigs;

@property (nonatomic, assign) BOOL isLynxViewRenderSuccess;
@property (nonatomic, assign) BOOL isLynxViewHasDowngrade;

@property (nonatomic, strong) NSMutableArray *combinePayNotSufficientFundIds; //组合支付余额不足列表
@property (nonatomic, strong) NSArray *normalNotSufficientFundIds; //非组合支付余额不足列表;

@property (nonatomic, copy) NSDictionary *lynxTrackInfoDict;

@property (nonatomic, assign) BOOL isImpTrackerEvented; //埋点只上报一次

@end

@implementation CJPayBizHybridHomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupBlock];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.lynxDefaultImageView cj_clipTopCorner:8];
    CGFloat timeoutTime = self.response.deskConfig.renderTimeoutTime > 0 ? self.response.deskConfig.renderTimeoutTime / 1000 : 3.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isLynxViewRenderSuccess && !self.isLynxViewHasDowngrade) {
            [self p_downgradeDeskWithInfoStr:@"lynx_code_timeout"];
        }
    });
}

#pragma mark - PrivateMethods
- (void)p_setupBlock {
    @CJWeakify(self)
    self.combinePayLimitBlock = ^(NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self p_sendLynxEvent:kEventCombinePayLimit params:params];
    };
}

- (void)p_setupUI {
    self.navigationBar.titleLabel.hidden = YES;
    self.countDownView.style = CJPayCountDownTimerViewStyleSmall;
    [self p_removeAllSubView];
    self.navigationBar.backgroundColor = [UIColor cj_eff3f5ff];
    self.countDownView.backgroundColor = [UIColor cj_eff3f5ff];
    self.contentView.backgroundColor = [UIColor cj_eff3f5ff];
    
    [self.contentView addSubview:self.marketingMsgView];
    [self.contentView addSubview:self.descLabel];
    [self.contentView addSubview:self.lynxView];
    [self.contentView addSubview:self.lynxDefaultImageView];
    [self.contentView addSubview:self.confirmButtonBgView];
    [self.confirmButtonBgView addSubview:self.confirmPayBtn];
    
    CJPayMasReMaker(self.countDownView, { //倒计时空间调整位置
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(8);
        make.width.equalTo(self.containerView).offset(-100);
        make.height.mas_equalTo(18);
    })
    
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self.countDownView.mas_bottom);
        make.left.right.equalTo(self.contentView);
    })
    
    CJPayMasMaker(self.descLabel, {
        make.top.equalTo(self.marketingMsgView.mas_bottom).offset(2);
        make.left.right.equalTo(self.contentView);
    })
    
    CJPayMasMaker(self.lynxView, {
        make.top.equalTo(self.contentView).offset(62);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.confirmButtonBgView.mas_top);
    });
    
    CJPayMasMaker(self.lynxDefaultImageView, {
        make.top.bottom.equalTo(self.lynxView);
        make.left.right.equalTo(self.lynxView).inset(8);
    });
    
    CJPayMasMaker(self.confirmButtonBgView, {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(68 + CJ_TabBarSafeBottomMargin);
        make.bottom.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.confirmPayBtn, {
        make.left.right.equalTo(self.confirmButtonBgView).inset(16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.top.equalTo(self.confirmButtonBgView).offset(12);
    });

    [self.lynxView reload];
    self.currentPayConfig = [self curSelectConfig];
}

- (void)p_removeAllSubView {
    for (UIView *subView in [self.contentView subviews]) {
        [subView removeFromSuperview];
    }
}

- (void)p_lynxViewDidClickWithParams:(NSDictionary *)params {
    self.isLynxViewRenderSuccess = YES;
    self.lynxDefaultImageView.hidden = YES;
    NSString *payMethodType = [params cj_stringValueForKey:@"paymethod_type"];
    NSInteger methodIndex = [params cj_integerValueForKey:@"paymethod_index"];
    NSString *status = [params cj_stringValueForKey:@"paymethod_status"];
    NSString *combineType = [params cj_stringValueForKey:@"combine_type"];
    NSString *extParams = [params cj_stringValueForKey:@"ext_params"];
    self.lynxTrackInfoDict = [[params cj_stringValueForKey:@"track_info"] cj_toDic];

    self.confirmPayBtn.enabled = ![status isEqualToString:@"0"];
    
    CJPayChannelType channelType = [CJPayTypeInfo getChannelTypeBy:payMethodType];
    CJPayDefaultChannelShowConfig *selectShowConfig = [self p_showConfigWithChannelType:channelType
                                                                            methodIndex:methodIndex
                                                                            combineType:combineType];
    
    
    //确保lynxCard渲染成功后才上报imp埋点
    if (!self.isImpTrackerEvented) {
        [self trackWithEventName:@"wallet_cashier_imp" params:@{
            @"byte_sub_pay_list": [self p_payMethodInfoTrackList] ?: @[]
        }];
        self.isImpTrackerEvented = YES;
    }
    
    if (!selectShowConfig) {
        [CJTracker event:@"wallet_rd_paybiz_lynx_exception" params:params ?: @{}];
        NSMutableDictionary *dict = [params mutableCopy];
        [self p_sendLynxEvent:kEventError params:[dict copy] ?: @{}];
        return;
    }
    selectShowConfig.lynxExtParams = [extParams cj_toDic];
    [self updateSelectConfig:selectShowConfig];
}

- (NSString *)p_installmentWithCreditPayModelsWithIndex:(NSInteger)index showConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    __block NSString *installment = @"1"; //默认分期数为1
    [showConfig.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.index == index) {
            obj.choose = YES;
            installment = obj.installment;
        } else {
            obj.choose = NO;
        }
    }];
    return installment;
}

- (CJPayDefaultChannelShowConfig *)p_showConfigWithChannelType:(CJPayChannelType)channelType
                                                   methodIndex:(NSInteger)index
                                                   combineType:(NSString *)combineType {
    __block CJPayDefaultChannelShowConfig *showConfig = nil;
    if (channelType == CJPayChannelTypeWX || channelType == CJPayChannelTypeTbPay) {
        [self.payChannelConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.type == channelType) {
                showConfig = obj;
                *stop = YES;
            }
        }];
    } else if (channelType == BDPayChannelTypeCreditPay) {
        @CJWeakify(self);
        [self.payChannelConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @CJStrongify(self);
            if (obj.type == channelType) {
                showConfig = obj;
                showConfig.payTypeData.creditPayInstallment = [self p_installmentWithCreditPayModelsWithIndex:index showConfig:obj];
                *stop = YES;
            }
        }];
    } else if (channelType == BDPayChannelTypeCardCategory) {
        [self.cardListConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.index == index) {
                showConfig = obj;
                if ([combineType isEqualToString:@"income"]) {
                    showConfig.isCombinePay = YES;
                    showConfig.combineType = BDPayChannelTypeIncomePay;
                } else if ([combineType isEqualToString:@"balance"]) {
                    showConfig.isCombinePay = YES;
                    showConfig.combineType = BDPayChannelTypeBalance;
                } else {
                    showConfig.isCombinePay = NO;
                    showConfig.combineType = CJPayChannelTypeNone;
                }
                *stop = YES;
            };
        }];
    }
    return showConfig;
}

- (void)p_showIncomeAlertTipsWithData:(NSDictionary *)data {
    NSString *iconTipsStr = [data cj_stringValueForKey:@"icon_tips"];
    NSError *error = nil;
    CJPaySubPayTypeIconTipModel *iconTips = [[CJPaySubPayTypeIconTipModel alloc] initWithString:CJString(iconTipsStr) error:&error];
    if (error) {
        return;
    }
    CJPayInComePayAlertContentView *alertContentView = [[CJPayInComePayAlertContentView alloc] initWithIconTips:iconTips];
    CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
    model.type = CJPayTextPopUpTypeDefault;
    CJPayDyTextPopUpViewController *alertVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model contentView:alertContentView];
    [alertVC showOnTopVC:self];
}

- (void)p_gotoCardList {
    [self gotoChooseMethodVC:NO];
}

- (void)p_sendLynxEvent:(NSString *)eventName params:(NSDictionary *)params {
    [self.lynxView publishEvent:eventName data:params];
}

- (void)p_onConfirmPayAction {
    if (self.isStandardDouPayProcess) {
        [super confirmButtonClick];
        return;
    }
    
    if (self.currentPayConfig.type == BDPayChannelTypeIncomePay) {
        [self p_checkAuthStatusAndPay];
    } else {
        [super confirmButtonClick];
    }
}

- (void)p_checkAuthStatusAndPay {
    if ([self.response.userInfo.authStatus isEqualToString:@"0"] || self.response.userInfo.isNewUser) {
        @CJWeakify(self);
        [self p_showAuthAlertWithAuthUrl:self.response.userInfo.authUrl completion:^{
            @CJStrongify(self);
            self.response.payInfo.bdPay.userInfo.authStatus = @"1";
            self.response.payInfo.bdPay.userInfo.isNewUser = NO;
            [super onConfirmPayAction];
        }];
    } else {
        [super onConfirmPayAction];
    }
}

- (void)p_showAuthAlertWithAuthUrl:(NSString *)authUrl completion:(void (^)(void))completion
{
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"根据监管要求，使用钱包收入支付前需先完成抖音零钱开户认证")
                                       content:nil
                                leftButtonDesc:CJPayLocalizedStr(@"取消")
                               rightButtonDesc:CJPayLocalizedStr(@"去认证")
                               leftActionBlock:nil
                               rightActioBlock:^{
        @CJStrongify(self)
        if (Check_ValidString(authUrl)) {
            CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:authUrl];
            webVC.closeCallBack = ^(id  _Nonnull data) {
                NSDictionary *dic = (NSDictionary *)data;
                if (dic && [dic isKindOfClass:NSDictionary.class]) {
                    NSString *service = [dic cj_stringValueForKey:@"service"];
                    if ([service isEqualToString:@"openAccount"]) {
                        CJ_CALL_BLOCK(completion);
                    }
                }
            };
            [self.navigationController pushViewController:webVC animated:YES];
        }
    } useVC:self];
}

// 根据选中的支付方式更新金额区UI
- (void)p_updateAmountViewByShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    if (!showConfig) {
        return;
    }
    
    if (![self.response.payInfo.bdPay.subPayTypeSumInfo.priceZoneShowStyle isEqualToString:@"LINE"]) {
        return;
    }
    
    NSString *payAmount = @"";
    NSString *payVoucherMsg = @"";
    
    CJPaySubPayTypeData *payTypeData = showConfig.payTypeData;
    
    if (showConfig.type == BDPayChannelTypeCreditPay) {
        // 抖分期,需要从里面取出分期数对应的支付金额和营销信息
        __block CJPayBytePayCreditPayMethodModel *selectedCreditPayMethodModel = nil;
        [payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.choose) {
                selectedCreditPayMethodModel = obj;
                *stop = YES;
            }
        }];
        // 若有分期信息，则取对应的支付金额和营销信息，否则从payTypeData取支付金额和营销信息
        if (selectedCreditPayMethodModel) {
            payAmount = selectedCreditPayMethodModel.standardShowAmount;
            payVoucherMsg = selectedCreditPayMethodModel.standardRecDesc;
        } else {
            payAmount = payTypeData.standardShowAmount;
            payVoucherMsg = payTypeData.standardRecDesc;
        }
    } else {
        // 银行卡、余额等二级支付方式直接取payAmount和payVoucherMsg
        if (showConfig.isCombinePay) {
            payAmount = payTypeData.combinePayInfo.standardShowAmount;
            payVoucherMsg = payTypeData.combinePayInfo.standardRecDesc;
        } else {
            payAmount = payTypeData.standardShowAmount;
            payVoucherMsg = payTypeData.standardRecDesc;
        }
    }
    // payAmount 或 payVoucherMsg 为空时，兜底走线上逻辑
    if (!Check_ValidString(payAmount) || !Check_ValidString(payVoucherMsg)) {
        payAmount = [NSString stringWithFormat:@"%.2f", [self.response totalAmountWithDiscount] / 100.0];
        payVoucherMsg = @"";
    }

    [self.marketingMsgView updateWithPayAmount:CJString(payAmount) voucherMsg:CJString(payVoucherMsg)];
}

- (void)p_downgradeDeskWithInfoStr:(NSString *)infoStr {
    CJPayLogInfo(@"聚合收银台lynxView渲染失败,触发降级策略");
    [CJTracker event:@"wallet_rd_cashier_info" params:@{
        @"lynx_url": CJString(self.response.deskConfig.containerViewLynxUrl),
        @"from" : @"hybrid_lynx_card_downgrade",
        @"detailInfo": CJString(infoStr)
    }];
    [[CJPayManager defaultService] downgradeDeskVCWithParams:self.processManager.createOrderParams completion:^(CJPayHomePageViewController * _Nonnull deskVC) {
        if (deskVC && [self.navigationController isKindOfClass:CJPayNavigationController.class]) {
            CJPayNavigationController *nav = (CJPayNavigationController *)self.navigationController;
            [nav pushViewControllerSingleTop:deskVC animated:NO completion:nil];
            self.isLynxViewHasDowngrade = YES;
        }
    }];
}

- (void)p_updateConfirmButtonTitle {
    // 当选中的卡不可用时，需要修改底下的button，和点击行为 跳转到绑卡页面
    CJPayDefaultChannelShowConfig *curSelectConfig = self.currentPayConfig;
    if (!curSelectConfig) {
        return;
    }
    
    NSString *payStr = [self.response.deskConfig.complianceBtnChangeTag isEqualToString:@"1"] ? @"付款" : @"支付"; //合规要求
    
    BOOL isSkipPwd = [curSelectConfig.payChannel.identityVerifyWay isEqualToString:@"3"];
    if (curSelectConfig.isCombinePay && curSelectConfig.combineType == BDPayChannelTypeBalance) {
        NSString *confirmBtnTitle = isSkipPwd ? [NSString stringWithFormat:@"零钱+银行卡免密%@", payStr] : [NSString stringWithFormat:@"零钱+银行卡%@", payStr];
        [self p_updateConfirmBtnTitle:CJPayLocalizedStr(confirmBtnTitle)];
        return;
    }
    if (curSelectConfig.isCombinePay && curSelectConfig.combineType == BDPayChannelTypeIncomePay) {
        NSString *confirmBtnTitle = isSkipPwd ? [NSString stringWithFormat:@"钱包收入+银行卡免密%@", payStr] : [NSString stringWithFormat:@"钱包收入+银行卡%@", payStr];
        [self p_updateConfirmBtnTitle:CJPayLocalizedStr(confirmBtnTitle)];
        return;
    }
    
    if (Check_ValidString(self.response.deskConfig.confirmBtnDesc)) {
        [self p_updateConfirmBtnTitle:self.response.deskConfig.confirmBtnDesc];
        return;
    }
    
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        NSString *btnStr = [NSString stringWithFormat:@"添加银行卡%@", payStr];
        [self p_updateConfirmBtnTitle:CJPayLocalizedStr(btnStr)];
        return;
    }
    
    if ([curSelectConfig.payChannel.identityVerifyWay isEqualToString:@"3"]) {
        if ([@[@(BDPayChannelTypeBankCard), @(BDPayChannelTypeBalance), @(BDPayChannelTypeCreditPay)] containsObject:@(curSelectConfig.type)]) {
            // 免密并且是自有支付的支付方式
            NSString *btnStr = [NSString stringWithFormat:@"免密%@", payStr];
            [self p_updateConfirmBtnTitle:CJPayLocalizedStr(btnStr)];
            return;
        }
    }

    NSString *btnStr = [NSString stringWithFormat:@"确认%@", payStr];
    [self p_updateConfirmBtnTitle:CJPayLocalizedStr(btnStr)];
}

- (void)p_updateConfirmBtnTitle:(NSString *)title {
    [self.confirmPayBtn cj_setBtnTitle:CJString(title)];
}

- (NSArray *)p_payMethodInfoTrackList {
    NSArray *showConfigs = [self.response.payInfo showConfigForCardList];
    NSMutableArray *subPayMethodLists = [NSMutableArray array];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [subPayMethodLists btd_addObject:[obj toSubPayMethodInfoTrackerDic]];
    }];
    return [subPayMethodLists copy];
}

- (void)p_onPay:(NSDictionary *)data {
    // 复写父类 p_onPay
    self.processManager.lynxRetainTrackerParams = [data cj_dictionaryValueForKey:@"tea_params"];
    [self confirmButtonClick];
}

- (void)p_onSelectPay:(NSDictionary *)data {
    // 复写父类 p_onSelectPay
    [self p_sendLynxEvent:@"cjpay_choose_method_with_index" params:data];
    if ([CJString([data cj_stringValueForKey:@"need_pay"]) isEqualToString:@"need"]) {
        // 可配置成选择支付方式并支付，或者直接支付。
        [self p_onPay:data];
    }
}


#pragma mark - OverWrite
- (void)notifyNotsufficient:(NSString *)bankCardId {
    NSString *cjIdentify = Check_ValidString(bankCardId) ? CJString(bankCardId) : self.currentPayConfig.cjIdentify;
    [self p_sendDisableEventWithIdentity:cjIdentify errorMsg:@""];
    if (self.currentPayConfig.isCombinePay) {
        if (Check_ValidString(cjIdentify) && ![self.combinePayNotSufficientFundIds containsObject:cjIdentify]) {
            [self.combinePayNotSufficientFundIds addObject:cjIdentify];
        }
    }
    [super notifyNotsufficient:bankCardId];
}

- (CJPayDefaultChannelShowConfig *)curSelectConfig {
    return self.currentPayConfig;
}

- (void)p_sendDisableEventWithIdentity:(NSString *)identity errorMsg:(NSString *)msg {
    [self p_sendLynxEvent:kEventPayMethodDisable params:@{
        @"paymethod_type" : self.currentPayConfig.type == BDPayChannelTypeCreditPay ? @"creditpay" : @"bytepay",
        @"paymethod_identity" : CJString(identity),
        @"error_msg" : CJString(msg)
    }];
}

- (void)payLimitWithTipsMsg:(NSString *)tipsMsg iconTips:(CJPaySubPayTypeIconTipModel *)iconTips { //通知lynx首页隐藏支付受限的支付方式
    [self p_sendDisableEventWithIdentity:CJString(self.currentPayConfig.cjIdentify) errorMsg:tipsMsg];
    [super payLimitWithTipsMsg:tipsMsg iconTips:iconTips];
}

- (void)creditPayFailWithTipsMsg:(NSString *)tipsMsg disableMsg:(NSString *)disableMsg {
    [self p_sendDisableEventWithIdentity:CJString(self.currentPayConfig.cjIdentify) errorMsg:disableMsg];
    [super creditPayFailWithTipsMsg:tipsMsg disableMsg:disableMsg];
}

- (CJPayBizChoosePayMethodViewController *)choosePayMethodVCWithshowNotSufficentFund:(BOOL)showNotSufficentFund {
    CJPayBizChoosePayMethodViewController *chooseVC = [super choosePayMethodVCWithshowNotSufficentFund:showNotSufficentFund];
    self.normalNotSufficientFundIds = chooseVC.notSufficientFundsIDs;
    if (self.currentPayConfig.isCombinePay) {
        chooseVC.notSufficientFundsIDs = self.combinePayNotSufficientFundIds;
    } else {
        chooseVC.notSufficientFundsIDs = self.normalNotSufficientFundIds;
    }
    return chooseVC;
}

//更新当前支付方式
- (void)updateSelectConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    self.currentPayConfig = selectConfig;
    // 卡列表页面切卡时，应该更新金额区UI
    [self p_updateAmountViewByShowConfig:self.currentPayConfig];
    [self p_updateConfirmButtonTitle];
    
}
    
- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *)defaultModel {
    [self p_sendLynxEvent:kEventCardListPayMethodClick params:@{
        @"paymethod_index": @(defaultModel.index)
    }];
}

- (void)updateOrderResponse:(CJPayCreateOrderResponse *)response {
    [super updateOrderResponse:response];
    [self p_sendLynxEvent:kEventReload params:@{
        @"response_data": CJString(response.originJsonString)
    }];
}

- (NSDictionary *)trackerParams {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict addEntriesFromDictionary:[super trackerParams]];
    if (self.lynxTrackInfoDict.count > 0) {
        [dict addEntriesFromDictionary:self.lynxTrackInfoDict];
    }
    return [dict copy];
}

- (void)startLoading {
    CJ_DelayEnableView(self.view);
    if ([self p_isLoadingFromConfirmButton]) {
        [self.confirmPayBtn startLoading];
        return;
    }
    [super startLoading];
}

- (void)stopLoading {

    CJ_DelayEnableView(self.view);
    if ([self p_isLoadingFromConfirmButton]) {
        [self.confirmPayBtn stopLoading];
        return;
    }
    [super stopLoading];
}

- (void)enableConfirmBtn:(BOOL)enable {
    self.confirmPayBtn.userInteractionEnabled = enable;
}

- (BOOL)p_isLoadingFromConfirmButton {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    return (self.loadingType == CJPayLoadingTypeConfirmBtnLoading && [vc isKindOfClass:self.class]); //新版收银台confirmButton单独写的，需要拦截处理loading事件
}

#pragma mark - CJPayLynxViewDelegate
- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if ([event isEqualToString:kEventGotoCardList]) {
        [self p_gotoCardList];
        return;
    }
    
    if ([event isEqualToString:kEventPayMethodClick]) {
        [self p_lynxViewDidClickWithParams:data];
        return;
    }
    
    if ([event isEqualToString:kEventIncomePayClick]) {
        [self p_showIncomeAlertTipsWithData:data];
        return;
    }
    
    [CJTracker event:@"wallet_rd_paybiz_lynx_exception" params:@{
        @"eventName" : CJString(event),
        @"eventData" : data ?: @{}
    }];
}

- (void)viewDidFinishLoadWithURL:(NSString *)url {
    CJPayLogInfo(@"容器加载成功：%@", CJString(url));
}

- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error {
    [self p_downgradeDeskWithInfoStr:CJString(error.description)];
}

- (void)viewDidRecieveError:(NSError *)error {
    [self p_downgradeDeskWithInfoStr:CJString(error.description)];
}

#pragma mark -Getter

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleCompact isShowVoucherMsg:NO];
        UIColor *priceColor = [self.response.deskConfig.theme amountColor];
        [_marketingMsgView updatePriceColor:priceColor];
        NSString *amountStr = [NSString stringWithFormat:@"%.2f", [self.response totalAmountWithDiscount] / (double)100];
        [_marketingMsgView updateWithPayAmount:CJString(amountStr) voucherMsg:@""];
        _marketingMsgView.discountLabel.numberOfLines = 1;
    }
    return _marketingMsgView;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.font = [UIFont cj_fontOfSize:13];
        _descLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.text = CJString(self.response.tradeInfo.tradeName);
    }
    return _descLabel;
}

- (CJPayBaseLynxView *)lynxView {
    if (!_lynxView) {
        _lynxView = [[CJPayBaseLynxView alloc] initWithFrame:CGRectMake(0, 0, 300, 400) scheme:CJString((self.response.deskConfig.containerViewLynxUrl))
 initDataStr:CJString(self.response.originJsonString)];
        _lynxView.delegate = self;
    }
    return _lynxView;
}

- (UIImageView *)lynxDefaultImageView {
    if (!_lynxDefaultImageView) {
        _lynxDefaultImageView = [UIImageView new];
        _lynxDefaultImageView.backgroundColor = [UIColor cj_eff3f5ff];
        [_lynxDefaultImageView cj_setImage:@"cj_paybiz_default_icon"];
    }
    return _lynxDefaultImageView;
}

- (UIView *)confirmButtonBgView {
    if (!_confirmButtonBgView) {
        _confirmButtonBgView = [UIView new];
        _confirmButtonBgView.backgroundColor = [UIColor whiteColor];
    }
    return _confirmButtonBgView;
}

- (CJPayStyleButton *)confirmPayBtn {
    if (!_confirmPayBtn) {
        _confirmPayBtn = [[CJPayStyleButton alloc] init];
        _confirmPayBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmPayBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        CJPayDeskTheme *theme = self.response.deskConfig.theme;
        if (theme) {
            [_confirmPayBtn cj_showCornerRadius:[theme confirmButtonShape]];
        } else {
            [_confirmPayBtn cj_showCornerRadius:4];
        }
        NSString *titleContent = self.response.deskConfig.confirmBtnDesc ?: CJPayLocalizedStr(@"确认支付");
        [_confirmPayBtn setTitle:titleContent forState:UIControlStateNormal];
        [_confirmPayBtn addTarget:self action:@selector(p_onConfirmPayAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmPayBtn;
}

- (NSMutableArray *)combinePayNotSufficientFundIds {
    if (!_combinePayNotSufficientFundIds) {
        _combinePayNotSufficientFundIds = [NSMutableArray array];
    }
    return _combinePayNotSufficientFundIds;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)payChannelConfigs {
    return [self.response.payInfo showConfigForHomePageWithId:@""];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)cardListConfigs {
   
    return [self.response.payInfo showConfigForCardList];
}

@end
