//
//  CJPayManager.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "CJPayUIMacro.h"
#import "CJPayCreateOrderRequest.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCookieUtil.h"
#import "CJSDKParamConfig.h"
#import "CJPayBinaryAdapter.h"
#import "CJPayBizParam.h"
#import "CJPayUIMacro.h"
#import "CJPayHomePageViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayRequestParam.h"
#import "CJPayKVContext.h"
#import "CJPaySDKMacro.h"
#import "CJPayDegradeModel.h"
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import "CJPayLoadingManager.h"
#import "CJPayDeskConfig.h"
#import "CJPayBytePayHomePageViewController.h"
#import "CJPayWebViewOfflineWrapper.h"
#import "CJPayResultPageViewController.h"
#import "CJPayKVContext.h"
#import "CJPayMetaSecManager.h"
#import "CJPayOPHomePageViewController.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayBizDeskPlugin.h"

@interface CJPayManager()<CJBizWebDelegate, CJPayCashierModule>

@property (nonatomic, copy) NSString *host;
@property (nonatomic, strong) CJPayNameModel *nameModel;
@property (nonatomic, strong) id<CJPayAPIDelegate> apiDelegate; // 这里是单例，delelgate可以不释放，另外如果使用CJPayAPICallback方式，使用weak会导致被提前释放，故改成strong。

@end

@implementation CJPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayCashierModule)
})

+ (instancetype)defaultService {
    static CJPayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [CJPayCookieUtil sharedUtil]; // 放到这初始化，主要是为了通知监
        _nameModel = [CJPayNameModel new];
        [CJPayBinaryAdapter shared].managerDelegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePage) name:BDPayClosePayDeskNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isSupportPayCallBackURL:(NSURL *)URL {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_canProcessURL:URL];
}

- (void)_openDeskWith:(nonnull NSDictionary *)bizParams bizUrl:(NSString *)bizUrl delegate:(id<CJPayManagerDelegate>)delegate {
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneStandardPayDeskKey extra:@{}];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) correctLocalTime];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
    self.cj_delegate = delegate;
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [CJSDKParamConfig defaultConfig].merchantId = [bizParams cj_stringValueForKey:@"merchant_id"];
    // 双端统一标准化重构实验曝光时机
    [CJPayABTest getABTestValWithKey:CJPayABIsDouPayProcess exposure:YES];
    void(^createOrderBlock)(void) = ^{
        int isShowLoading = [bizParams cj_intValueForKey:@"show_loading"];
        if (isShowLoading == 1) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        }
        [CJPayCreateOrderRequest startWithBizParams:bizParams bizUrl:bizUrl completion:^(NSError *error, CJPayCreateOrderResponse *response) {
            if (isShowLoading == 1) {
                [[CJPayLoadingManager defaultService] stopLoading];
            }
            if ([response isSuccess]) {
                [self callPayDesk:YES];
                [self p_configCashRegisterVC:bizParams bizUrl:bizUrl response:response];
            }else {
                [CJTracker event:@"native_pay_apply_exception_imp" params:@{@"source": CJString([UIApplication btd_bundleIdentifier])}];
                [CJMonitor trackService:@"wallet_rd_paydesk_open_failed" category:@{@"msg":CJString(response.msg), @"code": CJString(response.code), @"error_code": @(error.code), @"result": @"request failed"} extra:@{@"error_msg": CJString(error.description)}];
                [self callPayDesk:NO];
            }
            
            NSString *isSuccess = [response isSuccess] ? @"1" : @"0";
            NSString *requestCostTime = [NSString stringWithFormat:@"%f", response.responseDuration];
            NSString *methodListString = @"";
            if ([response isSuccess]) {
                methodListString = [response.payInfo.payChannels componentsJoinedByString:@" "];
            }
            [CJTracker event:@"wallet_cashier_trade_create" params:@{
                @"is_success": CJString(isSuccess),
                @"loading_time": CJString(requestCostTime),
                @"code" : CJString(response.code),
                @"merchant_id" : CJString(response.merchantInfo.merchantId),
                @"app_id" : CJString(response.merchantInfo.appId),
                @"type" : @"支付",
                @"method" : CJString(response.payInfo.defaultPayChannel),
                @"method_list" : CJString(methodListString)
            }];
            
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            [CJTracker event:@"native_startWithBizParams" params:@{@"used_time":@(endTime - startTime).stringValue, @"app_name": CJPayAppName ?: @""}];
        }];
    };
    
    [[CJPayCookieUtil sharedUtil] setupCookie:^(BOOL success) {
        CJ_CALL_BLOCK(createOrderBlock);
    }]; // 更新cookie信息
}

- (void)openPayDeskWithUrl:(nonnull NSString *)bizUrl delegate:(id<CJPayManagerDelegate>)delegate {
    [self _openDeskWith:@{} bizUrl:bizUrl delegate:delegate];
}

- (void)setupTitlesModel:(CJPayNameModel *)nameModel {
    self.nameModel = nameModel;
    [CJPayKVContext kv_setValue:nameModel forKey:CJPayDeskTitleKVKey];
}

- (void)openPayDeskWith:(nonnull NSDictionary *)bizParams delegate:(id<CJPayManagerDelegate>)delegate{
    
    if (bizParams == nil || bizParams.count < 1 || ![bizParams isKindOfClass:[NSDictionary class]]) {
        [self callPayDesk:NO];
        return;
    }
    [self _openDeskWith:bizParams bizUrl:@"" delegate:delegate];
}

- (void)downgradeDeskVCWithParams:(NSDictionary *)params completion:(nonnull void(^)(CJPayHomePageViewController *deskVC))completionBlock {
    NSMutableDictionary *dict = [params mutableCopy];
    [dict cj_setObject:@"HOMEPAGE_SHOW_STYLE" forKey:@"sdk_fallback"];
    if (dict.count < 1 || ![dict isKindOfClass:NSDictionary.class]) {
        return;
    }
    __block CJPayHomePageViewController *deskVC = nil;
    [CJPayCreateOrderRequest startWithBizParams:[dict copy] bizUrl:@"" completion:^(NSError *error, CJPayCreateOrderResponse *response) {
        if ([response isSuccess]) {
            deskVC = [self p_deskVCWithBizParams:[dict copy] bizUrl:@"" response:response];
            self.deskVC = deskVC;
        }
        CJ_CALL_BLOCK(completionBlock, deskVC);
    }];
}

- (void)openWebView:(NSString *)url params:(NSDictionary *)params closeCallBack:(void (^)(id))closeCallBack{
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController] toUrl:url params:params closeCallBack:closeCallBack];
}

- (void)closePayDesk{
    [self.deskVC close];
    self.deskVC = nil;
}

- (void)closePayDeskWithCompletion:(void (^)(BOOL))completion {
    if (self.deskVC) {
        [self.deskVC closeWithAnimation:YES comletion:completion];
    } else {
        CJ_CALL_BLOCK(completion, NO);
    }
}

- (void)closePage {
    if (self.deskVC) {
        @CJWeakify(self)
        [self.deskVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            [self.cj_delegate handleCJPayManagerResult:CJPayManagerResultFailed payResult:nil];
        }];
    }
}

- (void)callPayDesk:(BOOL)isSuccess {
    if ([self.cj_delegate respondsToSelector:@selector(callPayDesk:)]) {
        [self.cj_delegate callPayDesk:isSuccess];
    }
    
    // 通知API delegate
    if ([self.apiDelegate respondsToSelector:@selector(callState:fromScene:)]) {
        [self.apiDelegate callState:isSuccess fromScene:CJPayScenePay];
    }
}

- (CJPayHomePageViewController *)p_deskVCWithBizParams:(NSDictionary *)bizParams bizUrl:(NSString *)bizUrl response:(CJPayCreateOrderResponse *)response {
    CJPayHomePageViewController *confirmVC = nil;
    @CJWeakify(self);
    if ([response.deskConfig currentDeskType] == CJPayDeskTypeBytePay) {
        confirmVC = [[CJPayBytePayHomePageViewController alloc] initWithBizParams:bizParams bizurl:bizUrl response:response completionBlock:^(CJPayOrderResultResponse *resResponse,CJPayOrderStatus orderStatus) {
            @CJStrongify(self)
            [self handleCJPayManagerResult: resResponse orderStatus:orderStatus];
        }];
    } else if ([response.deskConfig currentDeskType] == CJPayDeskTypeBytePayHybrid) {
        if (CJ_OBJECT_WITH_PROTOCOL(CJPayBizDeskPlugin)) {
            UIViewController *hybridVC = [CJ_OBJECT_WITH_PROTOCOL(CJPayBizDeskPlugin) deskVCBizParams:bizParams bizurl:bizUrl response:response completionBlock:^(CJPayOrderResultResponse * _Nullable resResponse, CJPayOrderStatus orderStatus) {
                @CJStrongify(self)
                [self handleCJPayManagerResult: resResponse orderStatus:orderStatus];
            }];
            if ([hybridVC isKindOfClass:CJPayHomePageViewController.class]) {
                confirmVC = (CJPayHomePageViewController *)hybridVC;
            }
        } else {
            CJPayLogAssert(YES, @"未接入PayBizHybrid模块，请检查！");
        }
    } else {
        confirmVC =  [[CJPayHomePageViewController alloc] initWithBizParams:bizParams bizurl:bizUrl response:response completionBlock:^(CJPayOrderResultResponse *resResponse,CJPayOrderStatus orderStatus) {
            @CJStrongify(self)
            [self handleCJPayManagerResult: resResponse orderStatus:orderStatus];
        }];
    }
    return confirmVC;
}

- (void)p_configCashRegisterVC:(NSDictionary *)bizParams bizUrl:(NSString *)bizUrl response:(CJPayCreateOrderResponse *)response {

    if (self.deskVC != nil && self.deskVC.isViewLoaded && self.deskVC.view.window != nil) {
        CJPayLogInfo(@"请不要多次调用收银台");
        [CJMonitor trackService:@"wallet_rd_paydesk_open_failed" category:@{@"msg":CJString(response.msg), @"code": CJString(response.code), @"result": @"has waked pay desk"} extra:@{}];
        if (self.apiDelegate) {
            CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
            baseResponse.scene = CJPayScenePay;
            baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeHasOpeningDesk userInfo:@{NSLocalizedDescriptionKey : @"已有打开的收银台，不支持打开多个收银台"}];
            [self.apiDelegate onResponse:baseResponse];
        }
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneStandardPayDeskKey extra:@{}];
        return;
    }
    CJPayHomePageViewController *confirmVC = [self p_deskVCWithBizParams:bizParams bizUrl:bizUrl response:response];
    self.deskVC = confirmVC;  // 防止提前释放
    dispatch_async(dispatch_get_main_queue(), ^{
       [confirmVC presentWithNavigationControllerFrom:bizParams.cjpay_referViewController useMask:YES completion:nil];
    });

    NSString *isBankCard = @"0"; // [response.payInfo.bdPay.quickPayModel hasValidBankCard] ? @"1" : @"0";
    [CJTracker event:@"pay_apply_click" params:@{@"source": CJPayAppName, @"sdk_version": @"3.0", @"identity_type": @"", @"is_bankcard": isBankCard}];
}

- (void)needLogin:(void (^)(CJBizWebCode))callback{
    [[CJPayCookieUtil sharedUtil] cleanCookies];
    if (self.cj_delegate) {
        [self.cj_delegate needLogin:^(CJBizWebCode code) {
            [[CJPayManager defaultService] closePayDeskWithCompletion:^(BOOL isSuccess) {
                if (callback) {
                    callback(code);
                }
            }];
        }];
    }
}

- (void)registerOffline:(nonnull NSString *)appid{
    [[CJPayWebViewOfflineWrapper shared] i_registerOffline:appid];
}

- (void)handleCJPayManagerResult:(CJPayOrderResultResponse *)response orderStatus:(CJPayOrderStatus)orderStatus {
    [self handleCJPayManagerResult:response orderStatus:orderStatus extraDict:nil];
}

- (void)handleCJPayManagerResult:(CJPayOrderResultResponse *)response orderStatus:(CJPayOrderStatus) orderStatus extraDict:(NSDictionary *)extraDict {
    self.deskVC = nil;
    if ([self.cj_delegate respondsToSelector:@selector(handleCJPayManagerResult:payResult:)]) {
        CJPayManagerResultType type = CJPayManagerResultError;
        if (response && response.tradeInfo) {
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusProcess:
                    type = CJPayManagerResultProcessing;
                    break;
                case CJPayOrderStatusFail:
                    type = CJPayManagerResultFailed;
                    break;
                case CJPayOrderStatusTimeout:
                    type = CJPayManagerResultTimeout;
                    break;
                case CJPayOrderStatusSuccess:
                    type = CJPayManagerResultSuccess;
                    break;
                default:
                    break;
            }
        }
        else if (orderStatus && orderStatus == CJPayOrderStatusCancel) { //用户取消
            type = CJPayManagerResultCancel;
        }
        else if (orderStatus && orderStatus == CJPayOrderStatusTimeout) { //端上计时器超时
            type = CJPayManagerResultTimeout;
        }
        else {
            type = CJPayManagerResultError;
        }
        if (type >= 0) {
            CJPayLogInfo(@"支付结果%ld", type);
        }
        [CJMonitor trackService:@"wallet_rd_paydesk_callback" category:@{@"type": @(type), @"by_api": @"0"} extra:@{}];

        [self.cj_delegate handleCJPayManagerResult:type payResult:response];
    }
    
    // 通知api delegate
    if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSString *errorDesc;
        if (response && response.tradeInfo) {
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
        }
        else if (orderStatus && orderStatus == CJPayOrderStatusCancel) {
            errorCode = CJPayErrorCodeCancel;
            errorDesc = @"用户取消支付";
        }
        else if (orderStatus && orderStatus == CJPayOrderStatusTimeout) { //端上计时器超时
            errorCode = CJPayErrorCodeOrderTimeOut;
            errorDesc = @"支付超时";
        }
         else {
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
        }
                
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.data = [response toDictionary];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo addEntriesFromDictionary:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        if (extraDict.count > 0) {
            [userInfo addEntriesFromDictionary:extraDict];
        }
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:[userInfo copy]];
        [CJMonitor trackService:@"wallet_rd_paydesk_callback" category:@{@"code": @(errorCode), @"msg": CJString(errorDesc), @"by_api": @"1"} extra:@{}];
        [self.apiDelegate onResponse:apiResponse];
    }
    [CJPayKVContext kv_setValue:@"" forKey:CJPayTrackerCommonParamsCreditStageList];
    [CJPayKVContext kv_setValue:@"" forKey:CJPayTrackerCommonParamsIsCreavailable];
    [CJPayKVContext kv_setValue:@"" forKey:CJPayTrackerCommonParamsCreditStage];
    
    [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneStandardPayDeskKey extra:@{}];
}

#pragma mark - service

- (void)i_setupTitlesModel:(CJPayNameModel *)nameModel {
    [self setupTitlesModel:nameModel];
}

- (void)i_openPayDeskWithConfig:(NSDictionary *)configDic params:(NSDictionary *)bizParams delegate:(id<CJPayAPIDelegate>)delegate {
    
    self.apiDelegate = delegate;
    
    CJPayLogInfo(@"[CJPayManager i_openPayDeskWithConfig:%@]", [CJPayCommonUtil dictionaryToJson:bizParams])
    
    CJPaySettings *settings = [CJPaySettingsManager shared].currentSettings;
    
    NSString *appId = [bizParams cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [bizParams cj_stringValueForKey:@"merchant_id"];
    __block BOOL isUseH5 = false;
    [settings.degradeModels enumerateObjectsUsingBlock:^(CJPayDegradeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cjpayAppId isEqualToString:appId] && [obj.cjpayMerchantId isEqualToString:merchantId] && obj.isPayUseH5) {
            isUseH5 = true;
            *stop = YES;
        }
    }];
    if (isUseH5) {
        NSMutableDictionary *h5Params = [bizParams mutableCopy];
        [h5Params removeObjectForKey:@"cashier_source"];
        [h5Params removeObjectForKey:@"show_loading"];
        [h5Params cj_setValue:@"0" forKeyPath:@"cashdesk_scene"];
        [self p_openH5PayDeskWith:[h5Params copy] delegate:delegate];
    } else {
        [self openPayDeskWith:bizParams delegate:nil];
    }
}

- (void)i_openDYPayBizDeskWithDeskModel:(CJPayDYPayBizDeskModel *)deskModel delegate:(id<CJPayAPIDelegate>)delegate {
    self.apiDelegate = delegate;
    CJPayCreateOrderResponse *response = [deskModel.response isKindOfClass:[CJPayCreateOrderResponse class]] ? deskModel.response : nil;
    CJPayLogAssert([deskModel.response isKindOfClass:[CJPayCreateOrderResponse class]], @"deskModel.response should be CJPayCreateOrderResponse");
    
    @CJWeakify(self)
    CJPayOPHomePageViewController *dypayBizVC = [[CJPayOPHomePageViewController alloc] initWithBizParams:deskModel.bizParams ?: @{} bizurl:@"" response:response completionBlock:^(CJPayOrderResultResponse *resResponse,CJPayOrderStatus orderStatus) {
        @CJStrongify(self)
        BOOL isCloseFromRetain = NO;
        if ([self.deskVC isKindOfClass:CJPayOPHomePageViewController.class]) {
            isCloseFromRetain = ((CJPayOPHomePageViewController *)self.deskVC).isCloseFromRetain;
        }
        [self handleCJPayManagerResult:resResponse orderStatus:orderStatus extraDict:@{@"is_close_from_retain": isCloseFromRetain ? @"1" : @"0"}];
    }];
    
    self.deskVC = dypayBizVC;
    dypayBizVC.lastTimestamp = deskModel.lastTimestamp; // self.lastTimestamp;
    dypayBizVC.isColdLaunch = deskModel.isColdLaunch; // self.isColdLaunch;
    NSString *appName = deskModel.appName;
    if (appName && appName.length) {
        dypayBizVC.outerAppName = [appName stringByRemovingPercentEncoding];
    }
    NSString *appID = deskModel.appId;
    if (Check_ValidString(appID)) {
        dypayBizVC.outerAppID = appID;
    }
    dypayBizVC.isSignAndPay = deskModel.isSignAndPay;
    dypayBizVC.isPaymentForOuterApp = deskModel.isPaymentOuterApp;
    dypayBizVC.animationType = HalfVCEntranceTypeFromBottom;
    [dypayBizVC presentWithNavigationControllerFrom:deskModel.cjpay_referViewController useMask:deskModel.isUseMask completion:nil];
}

- (void)p_openH5PayDeskWith:(NSDictionary *)bizParams delegate:(id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5PayDesk:bizParams deskStyle:CJH5CashDeskStyleVertivalHalfScreen withDelegate:delegate];
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self i_openPayDeskWithConfig:dictionary params:dictionary delegate:delegate];
    return YES;
}

@end
