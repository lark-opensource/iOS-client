//
//  CJPayDYManager.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import "CJPayDYManager.h"
#import "CJPayCookieUtil.h"
#import "CJPayDYMainViewController.h"
#import "CJSDKParamConfig.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayDYLoginDataProvider.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayBDCashierModule.h"
#import "CJPayExceptionViewController.h"
#import "CJPayProtocolManager.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayDegradeModel.h"
#import "CJPayMetaSecManager.h"
#import "CJPayH5DeskModule.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPaySDKDefine.h"

@interface BDPayLoadingWrapperDelegate: NSObject<CJPayAPIDelegate>

@property (nonatomic, weak) id<CJPayAPIDelegate> delegate;
@property (nonatomic, assign) BOOL showLoading;

@end

@implementation BDPayLoadingWrapperDelegate

- (instancetype)initWithDelegate:(id<CJPayAPIDelegate>)delegate showLoading:(BOOL)showLoading {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.showLoading = showLoading;
        if (showLoading) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        }
    }
    return self;
}

- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (self.delegate && [self.delegate respondsToSelector:@selector(callState:fromScene:)]) {
        [self.delegate callState:success fromScene:scene];
    }
    if (self.showLoading) {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    [self.delegate onResponse:response];
}

@end

@interface CJPayDYManager()<CJPayBDCashierModule, CJBizWebDelegate>

@property (nonatomic, strong) CJUniversalLoginManager *loginManager;
@property (nonatomic, strong) id<CJPayAPIDelegate> apiDelegate;

@end

@implementation CJPayDYManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayBDCashierModule)
})

+ (instancetype)sharedInstance
{
    static CJPayDYManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayDYManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePage) name:BDPayClosePayDeskNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)p_openPayDeskWithParams:(NSDictionary *)bizParams isHiddenLoading:(BOOL)isHiddenLoading fromVC:(UIViewController *)fromVC delegate:(id<CJPayAPIDelegate>)delegate {
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
    if (bizParams == nil || bizParams.count < 1 || ![bizParams isKindOfClass:[NSDictionary class]]) {
        [self callPayDesk:NO];
        return;
    }
    [self p_openDeskWithBizParams:bizParams fromVC:fromVC delegate:[[BDPayLoadingWrapperDelegate alloc] initWithDelegate:delegate showLoading:!isHiddenLoading]];
}

- (void)callPayDesk:(BOOL)isSuccess {
    // 通知API delegate
    if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(callState:fromScene:)]) {
        [self.apiDelegate callState:isSuccess fromScene:CJPaySceneBDPay];
    }
    if (!isSuccess) {
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
    }
}

- (void)closePayDesk
{
    [self.deskVC close];
}

- (void)closePayDeskWithCompletion:(void (^)(BOOL))completion
{
    [self.deskVC closeWithAnimation:YES comletion:completion];
}

- (void)closePage {
    if (self.deskVC) {
        @CJWeakify(self)
        [self.deskVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
            apiResponse.data = nil;
            apiResponse.scene = CJPaySceneBDPay;
            apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"支付失败", nil)}];
            [self.apiDelegate onResponse:apiResponse];
        }];
    }
}

#pragma mark - CJBizWebDelegate
- (void)needLogin:(void (^)(CJBizWebCode))callback
{
    [[CJPayCookieUtil sharedUtil] cleanCookies];
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayLoginProtocol)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayLoginProtocol) needLogin:^(CJPayLoginBackCode code) {
            [[CJPayDYManager sharedInstance] closePayDeskWithCompletion:^(BOOL isSuccess) {
                if (callback) {
                    CJBizWebCode resultCode = CJBizWebCodeNone;
                    switch (code) {
                        case CJPayLoginBackCodeSuccess:
                            resultCode = CJBizWebCodeLoginSuccess;
                            break;
                        case CJPayLoginBackCodeFailure:
                            resultCode = CJBizWebCodeLoginFailure;
                            break;
                        case CJPayLoginBackCodeCloseDesk:
                            resultCode = CJBizWebCodeCloseDesk;
                            break;
                        default:
                            resultCode = CJBizWebCodeNone;
                            break;
                    }
                    callback(resultCode);
                }
            }];
        }];
    }
}

- (void)p_handleCJPayManagerResult:(CJPayBDOrderResultResponse *)response orderStatus:(CJPayOrderStatus)status {
    // 通知api delegate
    if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSString *errorDesc;
        if (response && response.tradeInfo != nil) {
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusProcess:
                    errorCode = CJPayErrorCodeProcessing;
                    errorDesc = @"支付结果处理中...";
                    break;
                case CJPayOrderStatusFail:
                    errorCode = CJPayErrorCodeFail;
                    errorDesc = @"支付失败";
                    break;
                case CJPayOrderStatusTimeout:
                    errorCode = CJPayErrorCodeOrderTimeOut;
                    errorDesc = @"支付超时";
                    break;
                case CJPayOrderStatusSuccess:
                    errorCode = CJPayErrorCodeSuccess;
                    errorDesc = @"支付成功";
                    break;
                default:
                    break;
            }
        } else if (status == CJPayOrderStatusCancel) { //
            errorCode = CJPayErrorCodeCancel;
            errorDesc = @"用户取消支付";
        } else if (status ==  CJPayOrderStatusTimeout) {
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"订单超时";
        } else {
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
        }
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.data = [response toDictionary];
        apiResponse.scene = CJPaySceneBDPay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        [self.apiDelegate onResponse:apiResponse];
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
    }
}

- (void)p_configCashRegisterVC:(NSDictionary *)bizParams referVC:(UIViewController *)referVC response:(CJPayBDCreateOrderResponse *)response {
    
    if (self.deskVC != nil && self.deskVC.isViewLoaded && self.deskVC.view.window != nil) {
        CJPayLogInfo(@"请不要多次调用收银台");
        return;
    }
    
    @CJWeakify(self)
    CJPayDYMainViewController *payVC = [[CJPayDYMainViewController alloc] initWithParams:bizParams createOrderResponse:response completionBlock:^(CJPayBDOrderResultResponse * _Nonnull resResponse, CJPayOrderStatus orderStatus) {
        @CJStrongify(self)
        [self p_handleCJPayManagerResult:resResponse orderStatus:orderStatus];
    }];

    [payVC presentWithNavigationControllerFrom:referVC useMask:YES completion:nil];
    self.deskVC = payVC;
}

- (void)p_openDeskWithBizParams:(nonnull NSDictionary *)bizParams fromVC:(UIViewController *)fromVC delegate:(id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) correctLocalTime];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
    self.apiDelegate = delegate;
    [CJSDKParamConfig defaultConfig].merchantId = [bizParams cj_stringValueForKey:@"merchant_id"];
    @CJWeakify(self)
    [[CJPayCookieUtil sharedUtil] setupCookie:^(BOOL success) {
        CJPayDYLoginDataProvider *createOrderProvider = [[CJPayDYLoginDataProvider alloc] initWithBizContentParams:bizParams appId:CJString([bizParams cj_stringValueForKey:@"app_id"]) merhcantId:CJString([bizParams cj_stringValueForKey:@"merchant_id"])];
        createOrderProvider.referVC = fromVC;
        createOrderProvider.continueProgressWhenLoginSuccess = YES;
        if ([delegate isKindOfClass:BDPayLoadingWrapperDelegate.class]) {
            BDPayLoadingWrapperDelegate *wrapperDelegate = (BDPayLoadingWrapperDelegate *)delegate;
            createOrderProvider.disableLoading = !wrapperDelegate.showLoading;
        }
        [weak_self.loginManager cleanLoginEvent];
        weak_self.loginManager = [CJUniversalLoginManager bindManager:createOrderProvider];
        weak_self.loginManager.cjpay_referViewController = fromVC;
        [weak_self.loginManager execLogin:^(CJUniversalLoginResultType type, CJPayUniversalLoginModel * _Nullable loginModel) {
            if ([createOrderProvider.response.code hasPrefix:@"GW4009"]) {
                [weak_self callPayDesk:YES];
                [CJPayExceptionViewController gotoThrotterPageWithAppId:CJString([bizParams cj_stringValueForKey:@"app_id"]) merchantId:CJString([bizParams cj_stringValueForKey:@"merchant_id"]) fromVC:fromVC closeBlock:^{
                    [weak_self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusCancel];
                } source:@"支付"];
                return;
            }
            if (type == CJUniversalLoginResultTypeHasLogin || type == CJUniversalLoginResultTypeSuccess) {
                if ([createOrderProvider.response isSuccess]) {
                    if (weak_self.loginManager.universalLoginNavi.viewControllers.count > 0) {
                        [weak_self.loginManager.universalLoginNavi dismissViewControllerAnimated:YES completion:^{
                            [weak_self callPayDesk:YES];
                            [weak_self p_configCashRegisterVC:bizParams referVC:createOrderProvider.referVC response:createOrderProvider.response];
                        }];
                    }else{
                        [weak_self callPayDesk:YES];
                        [weak_self p_configCashRegisterVC:bizParams referVC:createOrderProvider.referVC response:createOrderProvider.response];
                    }
                }else {
                    [CJTracker event:@"wallet_rd_call_pay_desk_error" params:@{@"msg" : CJString(loginModel.error.description)}];
                    if (weak_self.loginManager.universalLoginNavi.viewControllers.count > 0) {
                        [weak_self.loginManager.universalLoginNavi dismissViewControllerAnimated:YES completion:^{
                            [weak_self callPayDesk:NO];
                        }];
                    }else{
                        [weak_self callPayDesk:NO];
                    }
                }
            } else {
                [weak_self callPayDesk:NO];
                CJPayLogInfo(@"统一登录失败 %lu", (unsigned long)type);
            }
        }];
    }]; // 更新cookie信息
}

// CJPayBDCashierModule
- (void)i_openBDPayDeskWithConfig:(NSDictionary<CJPayPropertyKey,NSString *> *)configDic orderParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    CJPayLogInfo(@"[CJPayDYManager i_openBDPayDeskWithConfig:%@]", [CJPayCommonUtil dictionaryToJson:params]);
    CJPaySettings *settings = [CJPaySettingsManager shared].currentSettings;
    id obj = [configDic cj_objectForKey:CJPayPropertyReferVCKey];
    BOOL isHiddenLoading = [configDic cj_boolValueForKey:CJPayPropertyIsHiddenLoadingKey];
    UIViewController *referVC = [obj isKindOfClass:UIViewController.class] ? (UIViewController *)obj : nil;
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    __block BOOL isUseH5 = false;
    [settings.degradeModels enumerateObjectsUsingBlock:^(CJPayDegradeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bdpayAppId isEqualToString:appId] && [obj.bdpayMerchantId isEqualToString:merchantId] && obj.isBDPayUseH5) {
            isUseH5 = true;
            *stop = YES;
        }
    }];
    
    if (isUseH5) {
        [CJTracker event:@"wallet_cashier_downgrade_h5" params:@{@"app_id": CJString(appId),
                                                                 @"merhcant_id": CJString(merchantId),
                                                                 @"is_chaselight" : @"1"}];
        params.cjpay_referViewController = referVC;
        [self p_openH5BDPayWithParams:params delegate:delegate];
    } else {
        [self p_openPayDeskWithParams:params isHiddenLoading:isHiddenLoading fromVC:referVC delegate:delegate];
    }
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    NSDictionary *bizParams = [dictionary cj_dictionaryValueForKey:@"sdk_info"];
    id ext = [dictionary valueForKey:@"ext"];
    int showLoading = 0;
    if (ext && [ext isKindOfClass:NSString.class]) { // 兼容编码的情况
        showLoading = [[CJPayCommonUtil jsonStringToDictionary:(NSString *)ext] cj_intValueForKey:@"show_loading"];
    }
    [self p_openDeskWithBizParams:bizParams fromVC:nil delegate:[[BDPayLoadingWrapperDelegate alloc] initWithDelegate:delegate showLoading:showLoading == 1]];
    return YES;
}

- (void)p_openH5BDPayWithParams:(NSDictionary *)params delegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5BDPayDesk:params withDelegate:delegate];
}

@end
