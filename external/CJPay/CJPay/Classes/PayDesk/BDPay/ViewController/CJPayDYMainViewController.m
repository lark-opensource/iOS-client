//
//  CJPayDYMainViewController.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import "CJPayDYMainViewController.h"

#import "CJPayDYMainView.h"
#import "CJPayBizParam.h"
#import "CJPayDYVerifyManager.h"
#import "CJPayBDPayMainMessageView.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayDYChoosePayMethodViewController.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPaySafeManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayLoadingButton.h"
#import "CJPayCardSignResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayDYVerifyManagerQueen.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayChannelBizModel.h"
#import "CJPayCountDownTimerView.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayMetaSecManager.h"
#import "CJPayHalfLoadingItem.h"
#import "CJPayBDResultPageViewController.h"
#import "CJPayDYRecommendPayAgainViewController.h"
#import "CJPayDYRecommendPayAgainListViewController.h"
#import "CJPayHintInfo.h"
#import "CJPayAlertUtil.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayToast.h"
#import "CJPaySafeUtil.h"

typedef NS_ENUM(NSUInteger, CJPayDYMainViewControllerLoadingLocation) {
    kCJPayDYMainViewControllerLoadingLocationNull,
    kCJPayDYMainViewControllerLoadingLocationBottomButton,
    kCJPayDYMainViewControllerLoadingLocationChooseVCAddCard,
    kCJPayDYMainViewControllerLoadingLocationDouyinHalfLoading,
    kCJPayDYMainViewControllerLoadingLocationTopLoading,
};

@interface CJPayDYMainViewController () <CJPayDYChooseMethodDelegate, CJPayHomeVCProtocol, CJPayStateDelegate, CJPayCountDownTimerViewDelegate, CJPayDYRecommendPayAgainDelegate>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, copy) CJPayCompletionBlock completionBlock;

@property (nonatomic, strong) CJPayButton *passCodeVerifyButton;

@property (nonatomic, strong) UIImageView *titleBGImageView;

@property (nonatomic, strong) CJPayDYMainView *mainView;

@property (nonatomic, strong) CJPayCountDownTimerView *countDownView;

@property (nonatomic, strong) CJPayDYVerifyManager *verifyManager;

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showCardConfig;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *primaryCombineShowCardConfig;

@property (nonatomic, strong) NSMutableArray *notSufficientFundIds;

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@property (nonatomic, assign) CJPayDYMainViewControllerLoadingLocation loadingLocation;

@property (nonatomic, strong) UIViewController *mainViewController;

@property (nonatomic, strong) CJPayDYVerifyManagerQueen *queen;

@property (nonatomic, weak) CJPayDYChoosePayMethodViewController *chooseCardVC;
@property (nonatomic, weak) CJPayDYRecommendPayAgainViewController *payAgainVC;
@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap; //支付方式不可用及其原因

@end

@implementation CJPayDYMainViewController

- (instancetype)initWithParams:(NSDictionary *)params createOrderResponse:(CJPayBDCreateOrderResponse *)response completionBlock:(CJPayCompletionBlock)completionBlock
{
    self = [self init];
    if (self) {
        self.completionBlock = [completionBlock copy];
        self.verifyManager = [CJPayDYVerifyManager managerWith:self];
        self.verifyManager.verifyManagerQueen = self.queen;
        self.verifyManager.bizParams = params;
        self.verifyManager.from = @"三方收银台";
        self.animationType = HalfVCEntranceTypeFromBottom;
        self.orderResponse = response;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cjInheritTheme = CJPayThemeModeTypeLight;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (CJ_Pad) {
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
    }
    [self p_setupView];
    [self p_setupCountDownView];
    [self.queen trackCashierWithEventName:@"wallet_cashier_imp" params:@{}];
    
    [self p_updateWithResponse:self.orderResponse];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_silentRefresh) name:CJPayH5BindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess) name:CJPayBindCardSuccessPreCloseNotification object:nil];
}

// 点击导航栏返回按钮
- (void)back {
    // 如果没有走查单接口说明是用户自己触发了取消操作。否则则应该把查询订单的结果返回给业务方
    [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];
    [self.queen trackCashierWithEventName:@"wallet_cashier_back_click" params:@{}];
}

// 开放接口，供外部调用关闭
- (void)close
{
    [self p_dismissAllVCAboveCurrent];
    [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromUnLogin];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self p_updatePassVerifyButtonVisibleStatus];
}

#pragma mark - Private Methods

- (void)p_bindCardSuccess {
    [self p_refreshCreateOrderWithParams:self.verifyManager.bizParams isHiddenToast:YES];
    self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationDouyinHalfLoading;
}

- (void)p_silentRefresh {
    [self p_refreshCreateOrderWithParams:self.verifyManager.bizParams isHiddenToast:NO];
    self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationDouyinHalfLoading;
}

- (void)p_updateWithResponse:(CJPayBDCreateOrderResponse *)response
{
    [[CJPayCurrentTheme shared] setCurrentTheme:response.deskConfig.theme];
    [self.mainView updateWithResponse:response];
    [self p_updateShowCardConfigWithResponse:response];
    @CJWeakify(self)
    self.mainView.confirmBlock = ^{
        [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeConfirmPay];
        @CJStrongify(self)
        self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationBottomButton;
        NSString *iconName = self.showCardConfig.type == BDPayChannelTypeAddBankCard ? @"添加新卡支付" : @"确认支付";
        
        NSString *bankName = @"";
        NSString *bankType = @"";
        CJPayChannelModel *channelModel = self.showCardConfig.payChannel;
        if (channelModel && [channelModel isKindOfClass:[CJPayQuickPayCardModel class]]) {
            CJPayQuickPayCardModel *cardModel = (CJPayQuickPayCardModel *)channelModel;
            bankName = cardModel.frontBankCodeName;
            bankType = cardModel.cardTypeName;
        }
        
        [self.queen trackCashierWithEventName:@"wallet_cashier_confirm_click"
                                             params:@{@"icon_name": iconName,
                                                      @"bank_name": CJString(bankName),
                                                      @"bank_type": CJString(bankType)}];
        
        if (!self.countDownView.curTimeIsValid) {
            [self p_showTimeOutAlertVC];
            return;
        }
        
        switch (self.showCardConfig.type) {
            case BDPayChannelTypeBalance:
                if (self.mainView.payTypeMessageView.enable) {
                    [self p_pay];
                }
                break;
            case BDPayChannelTypeBankCard:
                [self p_pay];
                break;
            case BDPayChannelTypeAddBankCard:
                self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationBottomButton;
                [self.queen trackCashierWithEventName:@"wallet_cashier_add_newcard_click"
                                                     params:@{@"from": @"收银台一级页确认按钮",
                                                              @"addcard_info": @"添加新卡支付"}];
                
                [self p_bindCardAndPay];
                break;
            default:
                self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationBottomButton;
                [self p_bindCardAndPay];
                break;
        }
    };
    
    self.mainView.payTypeMessageView.arrowBlock = ^{
        @CJStrongify(self)
        [self p_gotoChooseMethodVCWithShowNotSufficentView:NO text:nil combinedPay:NO completion:nil];
    };
    
    self.mainView.combinedBankArrowBlock = ^{
        @CJStrongify(self)
        [self.queen trackCashierWithEventName:@"wallet_cashier_comavailable_more_method_click"
                                             params:@{}];
        
        [self p_gotoChooseMethodVCWithShowNotSufficentView:NO text:nil combinedPay:YES completion:^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
            self.showCardConfig.isCombinePay = NO;
            self.showCardConfig.combineType = CJPayChannelTypeNone;
            
            if (showConfig.type == CJPayChannelTypeNone) {
                self.showCardConfig = [self p_createAddCardConfigWithResponse:self.createOrderResponse];
            } else {
                self.showCardConfig = showConfig;
            }
            
            self.showCardConfig.isCombinePay = YES;
            self.showCardConfig.combineType = BDPayChannelTypeBalance;
            
            [self p_updateMainViewWithDefaultChannelShowConfig:self.showCardConfig];
            [self.navigationController popViewControllerAnimated:YES];
        }];
    };
}

- (void)p_updateShowCardConfigWithResponse:(CJPayBDCreateOrderResponse *)response
{
    CJPayDefaultChannelShowConfig *defaultConfig = [response.payTypeInfo obtainDefaultConfig];
    if (defaultConfig && [defaultConfig enable]) {
        self.showCardConfig = defaultConfig;
    } else {
        self.showCardConfig = [self p_createAddCardConfigWithResponse:response];
    }
}

- (CJPayDefaultChannelShowConfig *)p_createAddCardConfigWithResponse:(CJPayBDCreateOrderResponse *)response
{
    CJPayDefaultChannelShowConfig *addCardConfig = [CJPayDefaultChannelShowConfig new];
    addCardConfig.title = CJPayLocalizedStr(@"添加新卡支付");
    addCardConfig.type = BDPayChannelTypeAddBankCard;
    addCardConfig.status = @"1";
    return addCardConfig;
}

- (void)p_bindCardAndPay //添加新卡支付
{
    CJPayLogInfo(@"添加新卡支付");
    [self.verifyManager onBindCardAndPayAction];
}

- (void)p_handleBindAndPayResult:(CJPayBindCardResult) result {
    switch (result) {
        case CJPayBindCardResultSuccess:
            [self handleNativeBindAndPayResult:YES isNeedCreateTrade:YES];
            break;
            
        case CJPayBindCardResultFail:
            [self handleNativeBindAndPayResult:NO isNeedCreateTrade:YES];
            break;
            
        case CJPayBindCardResultCancel:
            [self handleNativeBindAndPayResult:NO isNeedCreateTrade:NO];
            break;
        default:
            [self handleNativeBindAndPayResult:NO isNeedCreateTrade:YES];
            break;
    }
}

- (void)p_pay //老卡支付
{
    [self.verifyManager begin];
    CJPayLogInfo(@"老卡支付");
}

// 用户走密码支付
- (void)p_passCodeVerifyPay {
    self.verifyManager.disableBioPay = YES;
    self.mainViewController = nil;
    CJ_CALL_BLOCK(self.mainView.confirmBlock);
}

// 更新导航栏上密码支付按钮的显隐状态
- (void)p_updatePassVerifyButtonVisibleStatus {
    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
    if (![objectWithCJPayBioPaymentPlugin pluginHasInstalled]) {
        CJPayLogInfo(@"未引入指纹/面容模块");
        self.passCodeVerifyButton.hidden = YES;
        return;
    }
    BOOL isBioValid = [objectWithCJPayBioPaymentPlugin isValidForCurrentUid:self.orderResponse.userInfo.uid];
    BOOL isTokenValid = isBioValid && [objectWithCJPayBioPaymentPlugin hasValidToken];
    BOOL isStateViewShow = !self.stateView.isHidden;
    BOOL isNeedResignCard = self.showCardConfig.isNeedReSigning;
    CJPayChannelType type = self.showCardConfig.type;
    if (type == BDPayChannelTypeBankCard || type == BDPayChannelTypeBalance) {
        // 银行卡老卡支付或余额支付,token无效或者显示了stateview或者补签约都将按钮隐藏掉
        self.passCodeVerifyButton.hidden = isNeedResignCard || isStateViewShow || !isTokenValid || [self.orderResponse.userInfo.pwdCheckWay isEqualToString:@"0"];
    } else {
        self.passCodeVerifyButton.hidden = YES;
    }
}

// 跳转二级页面
- (void)p_gotoChooseMethodVCWithShowNotSufficentView:(BOOL)showNotSufficentFund
                                                text:(NSString *)text
                                         combinedPay:(BOOL)isFromCombinedPay
                                          completion:(CJPayDYSelectPayMethodCompletion)selectPayMethodCompletion {
    
    [self.queen trackCashierWithEventName:@"wallet_cashier_more_method_click"
                                   params:@{}];
    
    NSMutableArray *titles = [NSMutableArray new];
    for (CJPayQuickPayCardModel *cardModel in self.orderResponse.payTypeInfo.quickPay.cards) {
        NSString *cardTitle = [NSString stringWithFormat:@"%@%@", CJString(cardModel.frontBankCodeName), CJString(cardModel.cardTypeName) ];
        [titles addObject:cardTitle];
    }
    NSString *bankListStr = [titles componentsJoinedByString:@","];
    
    [self.queen trackCashierWithEventName:@"wallet_cashier_method_page_imp"
                                   params:@{@"bank_list": CJString(bankListStr),
                                            @"page_type": isFromCombinedPay ? @(3) : @(2)
                                          }];
    
    CJPayDefaultChannelShowConfig *defaultConfig = nil;
    if (self.showCardConfig.isCombinePay && !isFromCombinedPay) {
        defaultConfig = self.primaryCombineShowCardConfig;
    } else {
        defaultConfig = self.showCardConfig;
    }
    CJPayDYChoosePayMethodViewController *vc = [[CJPayDYChoosePayMethodViewController alloc] initWithOrderResponse:self.orderResponse defaultConfig:defaultConfig combinedPay:isFromCombinedPay selectPayMethodCompletion:selectPayMethodCompletion];
    vc.showNotSufficientFundsHeaderLabel = showNotSufficentFund;
    [vc.notSufficientFundsView updateTitle:CJString(text)];
    vc.notSufficientFundsIDs = [self.notSufficientFundIds copy];
    vc.delegate = self;
    vc.queen = self.queen;
    self.chooseCardVC = vc;
    
    __block NSUInteger lastHalfScreenIndex = NSNotFound;
    [self.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([viewController isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            lastHalfScreenIndex = idx;
            *stop = YES;
        }
    }];
    
    if (lastHalfScreenIndex < self.navigationController.viewControllers.count - 1) {
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack insertObject:vc atIndex:lastHalfScreenIndex];
        self.navigationController.viewControllers = [vcStack copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToViewController:vc animated:YES];
        });
    } else {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)p_setupView
{
    [self useCloseBackBtn];
    [self.navigationBar addSubview:self.passCodeVerifyButton];
    
    if (Check_ValidString(self.orderResponse.payTypeInfo.homePagePictureUrl)) {
        [self.containerView addSubview:self.titleBGImageView];
        [self.containerView bringSubviewToFront:self.navigationBar];
        CJPayMasMaker(self.titleBGImageView, {
            make.top.equalTo(self.navigationBar.mas_top);
            make.left.right.equalTo(self.navigationBar);
            make.height.mas_equalTo(80);
        });
    }
    
    [self.contentView addSubview:self.mainView];
    
    CJPayMasMaker(self.mainView, {
        make.edges.equalTo(self.contentView);
    });
    
    [self.mainView setFacePay:[self p_isFacePayment]];
    
    CJPayMasMaker(self.passCodeVerifyButton, {
        make.right.equalTo(self.navigationBar.mas_right).offset(-16);
        make.centerY.equalTo(self.navigationBar.titleLabel);
        make.height.mas_equalTo(18);
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
    });
}

- (void)p_setupCountDownView {
    [self.containerView addSubview:self.countDownView];
    CJPayMasMaker(self.countDownView, {
        make.centerY.equalTo(self.navigationBar);
        make.right.equalTo(self.navigationBar).offset(-16);
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
    });
    [self.countDownView startTimerWithCountTime:@(self.orderResponse.deskConfig.leftTime).intValue];
//    对齐Android，追光收银台不展示剩余时间
//    if (self.orderResponse.deskConfig.whetherShowLeftTime) {
//        self.countDownView.hidden = NO;
//    }
}

- (void)p_bindCard //独立支付绑卡
{
    CJPayLogInfo(@"添加新卡");
    CJPayBindCardSharedDataModel *bindCardCommonModel = [CJPayBindCardSharedDataModel new];
    bindCardCommonModel.appId = self.orderResponse.merchant.appId;
    bindCardCommonModel.merchantId = self.orderResponse.merchant.merchantId;
    bindCardCommonModel.cardBindSource = CJPayCardBindSourceTypeQuickPay;
    bindCardCommonModel.processInfo = self.orderResponse.processInfo;
    @CJWeakify(self)
    bindCardCommonModel.completion = ^(CJPayBindCardResultModel *resultModel) {
        [weak_self p_handleBindAndPayResult:resultModel.result];
    };
    bindCardCommonModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceQuickPay;
    [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:bindCardCommonModel];
}

- (void)p_showTimeOutAlertVC {
    @CJWeakify(self)
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"订单已超时，请重新下单") content:nil buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:^{
        @CJStrongify(self)
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromOrderTimeOut];
    } useVC:self];
}

- (CJPayOrderStatus) p_convertSourceToStatus:(CJPayHomeVCCloseActionSource)source {
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromBack:
            return CJPayOrderStatusCancel;
        case CJPayHomeVCCloseActionSourceFromOrderTimeOut:
            return CJPayOrderStatusTimeout;
        default:
            return CJPayOrderStatusNull;
    }
}

- (void)p_notifyNotSufficientFunds:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    if (self.verifyManager.isBindCardAndPay) {
        [self p_bindCardSuccessAndPayFailWithData:response];
        return ;
    }
   
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    if (![self.notSufficientFundIds containsObject:[self curSelectConfig].cjIdentify] && Check_ValidString([self curSelectConfig].cjIdentify)) {
        [self.notSufficientFundIds btd_insertObject:[self curSelectConfig].cjIdentify atIndex:0];
    }
    @CJWeakify(self)
    [self p_gotoChooseMethodVCWithShowNotSufficentView:YES text:(NSString *)confirmResponse.msg combinedPay:NO completion:^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
        @CJStrongify(self)
        if ([self.showCardConfig isNeedReSigning] || [showConfig isNeedReSigning]) { // 普通卡切补签约卡&补签约卡切普通卡&补签约卡切补签约卡
            if ([self.showCardConfig isNeedReSigning] && ![showConfig isNeedReSigning]) { //补签约卡切普通卡
                NSArray *viewControllers = self.navigationController.viewControllers;
                [viewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:self.class]) {
                        self.mainViewController = obj;
                        *stop = YES;
                    }
                }];
                [self changePayMethodTo:showConfig];
                [self p_dismissAllVCAboveCurrent];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_pay];
                });
            } else {
                [self changePayMethodTo:showConfig];
                [self p_dismissAllVCAboveCurrent];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_pay];
                });
            }
        } else {
            [self changePayMethodTo:showConfig];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)p_addToContentView:(nonnull UIView *)view {
    [self.contentView addSubview:view];
}

- (void)p_updateConfirmBtnTitle:(nonnull NSString *)title {
    [self.mainView.confirmButton cj_setBtnTitle:title];
    [self.mainView setFacePay:[self p_isFacePayment]];
}

- (void)p_enableConfirmBtn:(id)enable {
    if (![enable isKindOfClass:NSNumber.class]) {
        return;
    }
    self.mainView.confirmButton.enabled = [enable boolValue];
}

- (void)p_invalidateCountDownView {
    [self.countDownView invalidate];
    self.countDownView.hidden = YES;
}

- (void)p_dismissAllVCAboveCurrent {
    if (self.presentedViewController && CJ_Pad) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self.navigationController popToViewController:self animated:NO];
}

- (void)p_updateStateStyle:(nonnull CJPayBDOrderResultResponse *)response {
    self.buttonInfo = response.buttonInfo;
    self.stateView.pageDesc = response.buttonInfo.page_desc;
    self.stateView.buttonDesc = response.buttonInfo.button_desc;
}

- (void)p_handleButtonInfoWithCardSignResponse:(CJPayCardSignResponse *)response
{
    CJPayButtonInfoHandlerActionsModel *actionsModel = [CJPayButtonInfoHandlerActionsModel new];
    @CJWeakify(self)
    actionsModel.cardListAction = ^{
        [weak_self p_gotoChooseMethodVCWithShowNotSufficentView:NO text:nil combinedPay:NO completion:nil];
    };
    
    actionsModel.bindCardAction = ^{
        [weak_self p_bindCard];
    };
    
    response.buttonInfo.code = response.code;
    [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                      fromVC:self
                                                    errorMsg:response.msg
                                                 withActions:actionsModel
                                                   withAppID:self.createOrderResponse.merchant.appId
                                                  merchantID:self.createOrderResponse.merchant.merchantId];
}

- (BOOL)p_isFacePayment {
    CJPayVerifyType verifyType = [self firstVerifyType];
    if (verifyType == CJPayVerifyTypeBioPayment && [self.orderResponse.userInfo.pwdCheckWay isEqualToString:@"2"]) {
        if (CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin)) {
            BOOL isBioGuideAvailable = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioGuideAvailable];
            BOOL isBioValid = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isValidForCurrentUid:self.orderResponse.userInfo.uid];
            BOOL isTokenValid = isBioValid && [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) hasValidToken];
            return isBioGuideAvailable & isTokenValid;
        }
    }
    
    return NO;
}

#pragma mark - CJPayDYChooseMethodDelegate

- (void)countDownTimerRunOut {
    [self p_showTimeOutAlertVC];
    self.countDownView.hidden = YES;
}

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *)choosedConfig
{
    NSString *iconName = choosedConfig.type == BDPayChannelTypeBalance ? @"零钱" : @"银行卡";
    
    [self.queen trackCashierWithEventName:@"wallet_cashier_method_page_click"
                                   params:@{@"icon_name": iconName}];
    if (choosedConfig.type == BDPayChannelTypeBalance && choosedConfig.showCombinePay) {
            CJPayDefaultChannelShowConfig *defaultConfig = [self.createOrderResponse.payTypeInfo obtainDefaultConfig];
            if (defaultConfig && [defaultConfig enable]) {
                self.showCardConfig = defaultConfig;
            } else {
                self.showCardConfig = [self p_createAddCardConfigWithResponse:self.createOrderResponse];
            }
            self.showCardConfig.isCombinePay = YES;
            self.showCardConfig.combineType = BDPayChannelTypeBalance;
            self.primaryCombineShowCardConfig = choosedConfig;
    } else {
        self.showCardConfig = choosedConfig;
        self.showCardConfig.isCombinePay = NO;
        self.showCardConfig.combineType = CJPayChannelTypeNone;
        self.primaryCombineShowCardConfig = nil;
    }
    
    [self p_updateMainViewWithDefaultChannelShowConfig:self.showCardConfig];
}

- (void)handleNativeBindAndPayResult:(BOOL)isSuccess isNeedCreateTrade:(BOOL)isNeedCreateTrade
{
    if (isSuccess) {
        @CJStartLoading(self)
        [self.verifyManager submitQueryRequest];
    } else {
        if (isNeedCreateTrade) {
            [self p_refreshOrderResponseWithForce:NO];
        }
    }
}

- (void)bindCardAndPay {
    [self.queen trackCashierWithEventName:@"wallet_cashier_add_newcard_click"
                                   params:@{@"from": @"收银台二级页底部",
                                            @"addcard_info": @"添加新卡支付"}];

    self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationChooseVCAddCard;
    [self p_bindCardAndPay];
}

- (void)closeDesk {
    // 自己处理导航栈，解决转场问题
    self.navigationController.viewControllers = @[self];
    [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
}

- (void)p_updateMainViewWithDefaultChannelShowConfig:(CJPayDefaultChannelShowConfig *)showConfig
{
    CJPayChannelBizModel *bizModel = [showConfig toBizModel];
    NSString *title = CJString(bizModel.title);
    if (bizModel.type == BDPayChannelTypeBankCard) {
        title = [title stringByAppendingFormat:@"(%@)",CJString(bizModel.channelConfig.cardTailNumStr)];
    }
    
    if (showConfig.isCombinePay) {
        title = @"组合支付";
    }
    [self.mainView updateCombinedPayInfo:self.primaryCombineShowCardConfig bankInfo:showConfig];
    
    self.mainView.payTypeMessageView.enable = bizModel.enable;
    self.mainView.confirmButton.enabled = bizModel.enable;
    [self.mainView.payTypeMessageView updateDescLabelText:title];
    [self.mainView.payTypeMessageView updateSubDescLabelText:bizModel.reasonStr];
        
    switch (bizModel.type) {
        case BDPayChannelTypeAddBankCard:
            [self.mainView.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"添加新卡支付")];
            [self.mainView.payTypeMessageView updateWithIconUrl:@""];
            break;
        case BDPayChannelTypeBankCard:
        case BDPayChannelTypeBalance:
            [self.mainView.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
            [self.mainView setFacePay:[self p_isFacePayment]];
            if (!showConfig.isCombinePay) {
                [self.mainView.payTypeMessageView updateWithIconUrl:bizModel.channelConfig.iconUrl];
            } else {
                [self.mainView.payTypeMessageView updateWithIconUrl:nil];
            }
            break;
        default:
            break;
    }
}

- (void)p_refreshOrderResponseWithForce:(BOOL)isForceQuickpay {
    [self p_dismissAllVCAboveCurrent];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:self.verifyManager.bizParams];
    if (isForceQuickpay) {
        [bizContentParams cj_setObject:@"force_quickpay_default" forKey:@"service"];
    }
    
    [self p_refreshCreateOrderWithParams:bizContentParams isHiddenToast:NO];
}

- (void)p_refreshCreateOrderWithParams:(NSDictionary *)params isHiddenToast:(BOOL)isHiddenToast {
    @CJWeakify(self)
    [CJPayBDCreateOrderRequest startWithAppId:self.orderResponse.merchant.appId merchantId:self.orderResponse.merchant.merchantId bizParams:params completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([self.verifyManager needInvokeLoginAndReturn:response]) {
            return;
        }
        if (!response) {
            if (!isHiddenToast) {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            }
            return;
        }
        if ([response isSuccess]) {
            self.orderResponse = response;
            [self p_updateWithResponse:response];
        } else {
            if (!isHiddenToast) {
                [CJToast toastText:CJString(response.msg) inWindow:self.cj_window];
            }
            CJPayLogInfo(@"trade create 接口异常");
        }
    }];
}

- (void)p_recommendPayAgain {
    if (self.verifyManager.isBindCardAndPay) {
        [self p_silentRefresh];
    }
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    NSString *cjIdentify;
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        cjIdentify = self.verifyManager.confirmResponse.bankCardId;
    } else {
        cjIdentify = curSelectConfig.cjIdentify;
    }
    
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:self.verifyManager.confirmResponse.hintInfo.statusMsg forKey:cjIdentify];
    }
    
    CJPayDYRecommendPayAgainViewController *recommendVC = [CJPayDYRecommendPayAgainViewController new];
    recommendVC.createResponse = self.createOrderResponse;
    recommendVC.verifyManager = self.verifyManager;
    recommendVC.payDisabledFundID2ReasonMap = [self.payDisabledFundID2ReasonMap copy];
    recommendVC.delegate = self;
    @CJWeakify(self);
    recommendVC.closeActionCompletionBlock = ^(BOOL isSuccess) {
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.completionBlock, self.verifyManager.resResponse, [self p_convertSourceToStatus:CJPayHomeVCCloseActionSourceFromBack]);
    };
    self.payAgainVC = recommendVC;
    [self push:recommendVC animated:NO];
}

- (void)p_bindCardSuccessAndPayFailWithData:(id)data {
    if (self.verifyManager.isPayAgainRecommend) {
        [self.payAgainVC bindCardSuccessAndPayFailedWithData:data];
    } else {
        [self p_dismissAllVCAboveCurrent];
        NSString *toastMsg = CJPayNoNetworkMessage;
        if ([data isKindOfClass:CJPayOrderConfirmResponse.class]) {
            NSString *msg = ((CJPayOrderConfirmResponse *)data).msg;
            toastMsg = Check_ValidString(msg)? msg : CJPayNoNetworkMessage;
        }
        [CJToast toastText:CJString(toastMsg) inWindow:[self topVC].cj_window];
        [self p_silentRefresh];
    }
}

#pragma mark - CJPayStateDelegate
- (void)stateButtonClick:(NSString *)buttonName {
    if ([self.buttonInfo.action intValue] == 2) {
        [[CJPayLoadingManager defaultService] stopLoading];
    } else {
        [self close];
    }
}

#pragma mark - CJPayDYRecommendPayAgainDelegate
- (void)payWithChannel:(CJPayDefaultChannelShowConfig *)payChannel {
    self.showCardConfig = payChannel;
    self.verifyManager.isPayAgainRecommend = YES;
    if (payChannel.type == BDPayChannelTypeAddBankCard) {
        [self p_bindCardAndPay];
    } else {
        [self p_pay];
    }
}

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self.queen trackCashierWithEventName:eventName params:params];
}

#pragma mark - CJPayBaseLoadingProtocol

- (void)startLoading {
    if (self.verifyManager.isPayAgainRecommend) {
        [self.payAgainVC startLoading];
        return;
    }
    
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] ||
        [vc isKindOfClass:CJPayDYChoosePayMethodViewController.class]) {
        switch (self.loadingLocation) {
            case kCJPayDYMainViewControllerLoadingLocationChooseVCAddCard:
                [self.chooseCardVC.payMethodView startLoadingAnimationOnAddBankCardCell];
                break;
            case kCJPayDYMainViewControllerLoadingLocationBottomButton:
                @CJStartLoading(self.mainView.confirmButton)
                break;
            case kCJPayDYMainViewControllerLoadingLocationNull:
            default:
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
                self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationDouyinHalfLoading;
                break;
        }
    } else if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationDouyinHalfLoading;
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingLocation = kCJPayDYMainViewControllerLoadingLocationTopLoading;
    }
}

- (void)stopLoading {
    if (self.verifyManager.isPayAgainRecommend) {
        [self.payAgainVC stopLoading];
        return;
    }
    
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] || [vc isKindOfClass:CJPayDYChoosePayMethodViewController.class]) {
        switch (self.loadingLocation) {
            case kCJPayDYMainViewControllerLoadingLocationChooseVCAddCard:
                [self.chooseCardVC.payMethodView stopLoadingAnimationOnAddBankCardCell];
                break;
            case kCJPayDYMainViewControllerLoadingLocationBottomButton:
                @CJStopLoading(self.mainView.confirmButton)
                break;
            case kCJPayDYMainViewControllerLoadingLocationNull:
            default:
                [[CJPayLoadingManager defaultService] stopLoading];
                break;
        }
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

#pragma mark - CJPayHomeVCProtocol

- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventShowState:
            if ([object isKindOfClass:NSNumber.class]) {
                [self showState:[object integerValue]];
            }
            [self p_updatePassVerifyButtonVisibleStatus];
            break;
        case CJPayHomeVCEventAddToContentView:
            [self p_addToContentView:object];
            break;
        case CJPayHomeVCEventEnableConfirmBtn:
            [self p_enableConfirmBtn:object];
            break;
        case CJPayHomeVCEventNotifySufficient:
            [self p_notifyNotSufficientFunds:object];
            break;
        case CJPayHomeVCEventUpdateStateStyle:
            [self p_updateStateStyle:object];
            break;
        case CJPayHomeVCEventBindCardNoPwdCancel:
            [self p_dismissAllVCAboveCurrent];
            [self p_silentRefresh];
            break;
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self p_dismissAllVCAboveCurrent];
            break;
        case CJPayHomeVCEventUpdateConfirmBtnTitle:
            [self p_updateConfirmBtnTitle:object];
            break;
        case CJPayHomeVCEventInvalidateCountDownView:
            [self p_invalidateCountDownView];
            break;
        case CJPayHomeVCEventHandleButtonInfo:
            [self p_handleButtonInfoWithCardSignResponse:object];
            break;
        case CJPayHomeVCEventSignAndPayFailed:
            [self handleNativeBindAndPayResult:NO isNeedCreateTrade:YES];
            break;
        case CJPayHomeVCEventGotoCardList:
            [self p_gotoChooseMethodVCWithShowNotSufficentView:NO text:@"" combinedPay:NO completion:nil];
            break;
        case CJPayHomeVCEventRecommendPayAgain:
            [self p_recommendPayAgain];
            break;
        case CJPayHomeVCEventBindCardSuccessPayFail:
            [self p_bindCardSuccessAndPayFailWithData:object];
            break;
        default:
            break;
    }
    return YES;
}

- (UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self];
}

- (CJPayDYVerifyManager *)verifyManager {
    return _verifyManager;
}

- (CJPayBDCreateOrderResponse *)createOrderResponse {
    return _orderResponse;
}

- (CJPayDefaultChannelShowConfig *)curSelectConfig {
    return self.showCardConfig;
}

- (CJPayVerifyType)firstVerifyType {
    CJPayVerifyType type = [self.verifyManager getVerifyTypeWithPwdCheckWay:self.verifyManager.response.userInfo.pwdCheckWay];
    if (self.verifyManager.response.needResignCard || [self.curSelectConfig isNeedReSigning]) {
        type = CJPayVerifyTypeSignCard;
    }
    return type;
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    if (![resultResponse isSuccess]) {
        [self.verifyManager sendEventTOVC:CJPayHomeVCEventShowState obj:@(CJPayStateTypeNone)];
        [CJToast toastText:CJString(resultResponse.msg) inWindow:[self topVC].cj_window];
        return;
    }
    
    @CJWeakify(self)
    void(^resultPageBlock)(void) = ^(){
        @CJStrongify(self)
        if ([resultResponse closeAfterTime] == 0 || resultResponse.resultConfig.hiddenResultPage) {
            [self.verifyManager.homePageVC closeActionAfterTime:0
                                              closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        } else {
            CJPayBDResultPageViewController *resultPage = [CJPayBDResultPageViewController new];
            resultPage.resultResponse = resultResponse;
            resultPage.animationType = HalfVCEntranceTypeFromBottom;
            resultPage.closeActionCompletionBlock = ^(BOOL isCancel) {
                CJ_CALL_BLOCK(self.completionBlock, resultResponse, CJPayOrderStatusCancel);
            };
            resultPage.verifyManager = self.verifyManager;
            UINavigationController *navi = [self topVC].navigationController;
            if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) { // 有可能找不到
                [((CJPayNavigationController *)navi) pushViewControllerSingleTop:resultPage animated:NO completion:nil];
            } else {
                [self closeActionAfterTime:[resultResponse closeAfterTime]
                                                        closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
            }
        }
    };
    
    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
    if ([objectWithCJPayBioPaymentPlugin shouldShowGuideWithResultResponse:resultResponse]) {
        [objectWithCJPayBioPaymentPlugin showGuidePageVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(resultPageBlock);
        }];
    } else if (self.createOrderResponse.preBioGuideInfo != nil && self.verifyManager.isNeedOpenBioPay) {
        // 支付中引导开通生物识别，支付后在此发送请求
        NSMutableDictionary *requestModel = [NSMutableDictionary new];
        [requestModel cj_setObject:self.createOrderResponse.merchant.appId forKey:@"app_id"];
        [requestModel cj_setObject:self.createOrderResponse.merchant.merchantId forKey:@"merchant_id"];
        [requestModel cj_setObject:self.createOrderResponse.userInfo.uid forKey:@"uid"];
        [requestModel cj_setObject:self.createOrderResponse.tradeInfo.tradeNo forKey:@"trade_no"];
        [requestModel cj_setObject:[self.createOrderResponse.processInfo dictionaryValue] forKey:@"process_info"];
        [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
        
        NSMutableDictionary *pwdDic = [NSMutableDictionary dictionary];
        NSMutableDictionary *extDic = [NSMutableDictionary dictionary];
        NSString *safePwd = [CJPaySafeUtil encryptPWD:self.verifyManager.lastPWD];
        [pwdDic cj_setObject:CJString(safePwd) forKey:@"mobile_pwd"];
        [pwdDic cj_setObject:[objectWithCJPayBioPaymentPlugin bioType] forKey:@"pwd_type"];
        [extDic cj_setObject:[requestModel cj_objectForKey:@"trade_no"] forKey:@"trade_no"];
        [pwdDic cj_setObject:extDic forKey:@"exts"];
        [pwdDic cj_setObject:[requestModel cj_objectForKey:@"process_info"] forKey:@"process_info"];
        
        [objectWithCJPayBioPaymentPlugin openBioPay:requestModel withExtraParams:pwdDic completion:^(NSError * _Nonnull error, BOOL result) {
            if (result) {
                NSString *msg = [[objectWithCJPayBioPaymentPlugin bioType] isEqualToString:@"1"] ? @"指纹支付已开通" : @"面容支付已开通";
                [CJToast toastText:msg code:@"" duration:1 inWindow:[UIViewController cj_topViewController].cj_window];
            } else {
                NSString *msg = [[objectWithCJPayBioPaymentPlugin bioType] isEqualToString:@"1"] ? @"指纹支付开通失败" : @"面容支付开通失败";
                [CJToast toastText:msg code:@"" duration:1 inWindow:[UIViewController cj_topViewController].cj_window];
            }
        }];
        
        CJ_CALL_BLOCK(resultPageBlock);
    } else {
        CJ_CALL_BLOCK(resultPageBlock);
    }
}

- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    [self p_invalidateCountDownView];
    [self p_dismissAllVCAboveCurrent];
    
    if (time < 0) { // 小于等于0的话，不关闭收银台，让业务方手动关闭
        return;
    }
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self closeWithAnimation:YES comletion:^(BOOL finish) {
            @CJStrongify(self)
            if (self.navigationController) {
                [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            } else {
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            //消失后执行
            CJ_CALL_BLOCK(self.completionBlock,self.verifyManager.resResponse, [self p_convertSourceToStatus:source]);
        }];
    });
}

- (void)push:(UIViewController *)vc animated:(BOOL)animated {
    __block NSUInteger index = 0;
    if (self.mainViewController) {  //补签约卡切普通卡的时候无感拉起验密页
        NSMutableArray *subVCs = [self.navigationController.viewControllers mutableCopy];
        [subVCs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj == self.mainViewController) {
                index = idx;
                *stop = YES;
            }
        }];
        if (index + 1 < subVCs.count && index > 0) {
            [subVCs insertObject:vc atIndex:index + 1];
            self.navigationController.viewControllers = subVCs;
            [self.navigationController popToViewController:vc animated:NO];
        }
    } else {
        [self.navigationController pushViewController:vc animated:animated];
    }
}

#pragma mark - Getter

- (UIImageView *)titleBGImageView {
    if (!_titleBGImageView) {
        _titleBGImageView = [UIImageView new];
        _titleBGImageView.backgroundColor = [UIColor clearColor];
        if (Check_ValidString(self.orderResponse.payTypeInfo.homePagePictureUrl)) {
            [_titleBGImageView cj_setImageWithURL:[NSURL URLWithString:self.orderResponse.payTypeInfo.homePagePictureUrl]];
        }
    }
    return _titleBGImageView;
}

- (CJPayButton *)passCodeVerifyButton {
    if (!_passCodeVerifyButton) {
        _passCodeVerifyButton = [CJPayButton new];
        _passCodeVerifyButton.titleLabel.font = [UIFont cj_fontOfSize:15];
        [_passCodeVerifyButton setTitle:CJPayLocalizedStr(@"密码支付") forState:UIControlStateNormal];
        [_passCodeVerifyButton setTitleColor:[UIColor cj_douyinBlueColor] forState:UIControlStateNormal];
        [_passCodeVerifyButton addTarget:self action:@selector(p_passCodeVerifyPay) forControlEvents:UIControlEventTouchUpInside];
        _passCodeVerifyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _passCodeVerifyButton;
}

- (CJPayDYMainView *)mainView
{
    if (!_mainView) {
        _mainView = [[CJPayDYMainView alloc] init];
        _mainView.userInteractionEnabled = YES;
    }
    return _mainView;
}

- (CJPayCountDownTimerView *)countDownView {
    if (!_countDownView) {
        _countDownView = [CJPayCountDownTimerView new];
        _countDownView.hidden = YES;
        _countDownView.delegate = self;
    }
    return _countDownView;
}

- (NSMutableArray *)notSufficientFundIds {
    if (!_notSufficientFundIds) {
        _notSufficientFundIds = [NSMutableArray new];
    }
    return _notSufficientFundIds;
}

- (NSMutableDictionary *)payDisabledFundID2ReasonMap {
    if (!_payDisabledFundID2ReasonMap) {
        _payDisabledFundID2ReasonMap = [NSMutableDictionary dictionary];
    }
    return _payDisabledFundID2ReasonMap;
}

- (CJPayDYVerifyManagerQueen *)queen
{
    if (!_queen) {
        _queen = [CJPayDYVerifyManagerQueen new];
        [_queen bindManager:self.verifyManager];
    }
    return _queen;
}

@end
