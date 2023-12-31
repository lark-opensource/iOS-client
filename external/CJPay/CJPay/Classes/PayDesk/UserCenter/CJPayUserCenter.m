//
//  CJPayUserCenter.m
//  CJPay
//
//  Created by 王新华 on 3/9/20.
//

#import "CJPayRechargeBalanceViewController.h"
#import "CJPayWithDrawBalanceViewController.h"
#import "CJPayUserCenter.h"
#import "CJPayFrontCashierCreateOrderRequest.h"
#import "CJPayLoadingManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayFrontCashierManager.h"
#import "CJPayDegradeModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPayExceptionViewController.h"
#import "CJPayMetaSecManager.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayKVContext.h"

@interface CJPayUserCenter()

@property (nonatomic, weak) CJPayFullPageBaseViewController *deskVC;
@property (nonatomic, weak) id<CJPayAPIDelegate> apiDelegate;
@property (nonatomic, assign) BOOL isNewStyle;

@end

@implementation CJPayUserCenter

+ (instancetype)sharedInstance {
    static CJPayUserCenter *uc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uc = [CJPayUserCenter new];
    });
    return uc;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePage) name:BDPayClosePayDeskNotification object:nil];
    }
    return self;
}

- (void)withdrawBalance:(NSDictionary *)bizContentParams completion:(void (^)(BDUserCenterCode, CJPayBDOrderResultResponse * _Nullable))completion {
    NSString *headerStr = [bizContentParams cj_stringValueForKey:@"lark_union_gateway_strategy"];
    if (Check_ValidString(headerStr)) {
        [CJPayKVContext kv_setValue:CJString(headerStr) forKey:CJPayWithDrawAddHeaderData];
    }
    
    if (!bizContentParams && bizContentParams.count < 1) {
        if (completion) {
            completion(BDUserCenterCodeFailed, nil);
        } else {
            CJPayLogInfo(@"bizcontentParams is nil");
        }
        return;
    }
    [CJPayUserCenter sharedInstance].isNewStyle = [bizContentParams cj_boolValueForKey:@"new_wallet_change"];
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey extra:@{}];
    void(^showVerifiedVC)(CJPayBDCreateOrderResponse *response) = ^(CJPayBDCreateOrderResponse *response) {
        CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
        model.cardBindSource = CJPayCardBindSourceTypeBalanceRecharge;
        model.appId = response.merchant.appId;
        model.merchantId = response.merchant.merchantId;
        model.processInfo = response.processInfo;
        model.userInfo = response.userInfo;
        model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
            if (cardResult.result == CJPayBindCardResultSuccess) {
                [self withdrawBalance:bizContentParams completion:completion];
            } else {
                [CJMonitor trackService:@"wallet_rd_tixian_bindcard_not_success" category:@{@"code": @(cardResult.result)} extra:@{}];
                CJPayLogInfo(@"绑卡失败 code: %ld", cardResult.result);
            }
        };
        model.cjpay_referViewController = bizContentParams.cjpay_referViewController;
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceBalanceWithdraw;
        [[CJPayFrontCashierManager shared] bindCardWithCommonModel:model];
    };
    @CJWeakify(self)
    void(^showBalanceWithdrawVC)(CJPayBDCreateOrderResponse *response) = ^(CJPayBDCreateOrderResponse *response) {
        @CJStrongify(self)
        CJPayWithDrawBalanceViewController *vc = [[CJPayWithDrawBalanceViewController alloc] initWithBizParams:bizContentParams bizurl:@"" response:response completionBlock:^(CJPayBDOrderResultResponse * _Nonnull resResponse, CJPayOrderStatus orderStatus) {
            BDUserCenterCode withDrawCode;
            if (resResponse && resResponse.tradeInfo != nil) {
                switch (resResponse.tradeInfo.tradeStatus) {
                    case CJPayOrderStatusSuccess:
                        withDrawCode = BDUserCenterCodeSuccess;
                        break;
                    case CJPayOrderStatusFail:
                    default:
                        withDrawCode = BDUserCenterCodeFailed;
                        break;
                }
            } else if (orderStatus == CJPayOrderStatusCancel) {
                withDrawCode = BDUserCenterCodeCanceled;
            } else {
                withDrawCode = BDUserCenterCodeFailed;
            }
            CJ_CALL_BLOCK(completion, withDrawCode, resResponse);
            [CJPayKVContext kv_setValue:@"" forKey:CJPayWithDrawAddHeaderData];
            [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey extra:@{}];
        }];
        self.deskVC = vc;
        [vc presentWithNavigationControllerFrom:bizContentParams.cjpay_referViewController useMask:NO completion:nil];
    };
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:bizContentParams.cjpay_referViewController];
    
    NSMutableDictionary *bizConParams = [NSMutableDictionary dictionaryWithDictionary:bizContentParams];
    [bizConParams cj_setObject:@"prewithdraw.balance.confirm" forKey:@"service"];
    
    [CJPayFrontCashierCreateOrderRequest startRequestWithAppid:[bizConParams cj_stringValueForKey:@"app_id"] merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] bizContentParams:@{@"params": bizConParams ?: @{}} completion:^(NSError * _Nullable error, CJPayBDCreateOrderResponse * _Nullable response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if ([response.code hasPrefix:@"GW4009"]) { // 触发限流
            NSString *appid = [bizConParams cj_stringValueForKey:@"app_id"];
            [CJPayExceptionViewController gotoThrotterPageWithAppId:appid merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] fromVC:bizContentParams.cjpay_referViewController  closeBlock:^{
                completion(BDUserCenterCodeFailed, nil);
                [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey extra:@{}];
            } source:@"提现"];
            return;
        }
        if (response && response.isSuccess) {
            if ([response.userInfo.authStatus isEqualToString:@"0"] && response.userInfo.needAuthGuide) { //未实名
               showVerifiedVC(response);
            } else {
               showBalanceWithdrawVC(response);
            }
        } else if (completion) {
            NSString *toastMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
            [CJToast toastText:toastMsg inWindow:[UIViewController cj_topViewController].cj_window];
            completion(BDUserCenterCodeFailed, nil);
            [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey extra:@{}];
        }
   }];
        
}

- (void)rechargeBalance:(NSDictionary *)bizContentParams completion:(void (^)(BDUserCenterCode, CJPayBDOrderResultResponse * _Nullable))completion {
    [CJPayKVContext kv_setValue:@"" forKey:CJPayWithDrawAddHeaderData];
    if (!bizContentParams && bizContentParams.count < 1) {
        if (completion) {
            completion(BDUserCenterCodeFailed, nil);
        } else {
            CJPayLogInfo(@"bizcontentParams is nil");
            [CJMonitor trackService:@"wallet_rd_change_null_params" category:@{@"service" : @"banlanceRecharge"} extra:@{}];
        }
    }
    [CJPayUserCenter sharedInstance].isNewStyle = [bizContentParams cj_boolValueForKey:@"new_wallet_change"];
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBalanceRechargePayDeskKey extra:@{}];
    @CJWeakify(self)
    void(^showRechargeBalanceVC)(CJPayBDCreateOrderResponse *response) = ^(CJPayBDCreateOrderResponse *response) {
        @CJStrongify(self)
            CJPayRechargeBalanceViewController *vc = [[CJPayRechargeBalanceViewController alloc] initWithBizParams:bizContentParams bizurl:@"" response:response completionBlock:^(CJPayBDOrderResultResponse * _Nonnull resResponse, CJPayOrderStatus orderStatus) {
                BDUserCenterCode rechargeCode;
                if (resResponse && resResponse.tradeInfo != nil) {
                    switch (resResponse.tradeInfo.tradeStatus) {
                        case CJPayOrderStatusSuccess:
                            rechargeCode = BDUserCenterCodeSuccess;
                            break;
                        case CJPayOrderStatusFail:
                        default:
                            rechargeCode = BDUserCenterCodeFailed;
                            break;
                    }
                } else if (orderStatus == CJPayOrderStatusCancel) {
                    rechargeCode = BDUserCenterCodeCanceled;
                } else {
                    rechargeCode = BDUserCenterCodeFailed;
                }
                CJ_CALL_BLOCK(completion, rechargeCode, resResponse);
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceRechargePayDeskKey extra:@{}];
            }];
            self.deskVC = vc;
            [vc presentWithNavigationControllerFrom:bizContentParams.cjpay_referViewController useMask:NO completion:nil];
       
    };
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:bizContentParams.cjpay_referViewController];
    
    NSMutableDictionary *bizConParams = [NSMutableDictionary dictionaryWithDictionary:bizContentParams];
    [bizConParams cj_setObject:@"prepay.balance.confirm" forKey:@"service"];
    
    [CJPayFrontCashierCreateOrderRequest startRequestWithAppid:[bizConParams cj_stringValueForKey:@"app_id"] merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] bizContentParams:@{@"params": bizConParams ?: @{}} completion:^(NSError * _Nullable error, CJPayBDCreateOrderResponse * _Nullable response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if ([response.code hasPrefix:@"GW4009"]) { // 触发限流
            [CJPayExceptionViewController gotoThrotterPageWithAppId:[bizConParams cj_stringValueForKey:@"app_id"] merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] fromVC:bizContentParams.cjpay_referViewController closeBlock:^{
                completion(BDUserCenterCodeFailed, nil);
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceRechargePayDeskKey extra:@{}];
            } source:@"支付"];
            return;
        }
        if (response && response.isSuccess) {
            showRechargeBalanceVC(response);
        } else if (completion) {
            NSString *toastMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
            [CJToast toastText:toastMsg inWindow:[UIViewController cj_topViewController].cj_window];
            completion(BDUserCenterCodeFailed, nil);
            [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceRechargePayDeskKey extra:@{}];
        }
    }];
}

- (void)closePage {
    if (self.deskVC) {
        @CJWeakify(self)
        [self.deskVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            [self p_handleBindCardConflictReturn];
        }];
    }
}

- (void)p_handleBindCardConflictReturn {
    CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
    apiResponse.data = nil;
    
    if ([self.deskVC isKindOfClass:CJPayWithDrawBalanceViewController.class]) {
        apiResponse.scene = CJPaySceneBalanceWithdraw;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"提现失败", nil)}];
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey extra:@{}];
    } else {
        apiResponse.scene = CJPaySceneBalanceRecharge;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"充值失败", nil)}];
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBalanceRechargePayDeskKey extra:@{}];
    }
    
    if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        [self.apiDelegate onResponse:apiResponse];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@interface CJPayUserCenter(ModuleSupport)<CJPayUserCenterModule>

@end

@implementation CJPayUserCenter(ModuleSupport)

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shareInstance), CJPayUserCenterModule)
})

#pragma - mark wake by scheme
- (BOOL)openPath:(NSString *)path withParams:(NSDictionary *)params {
    NSMutableDictionary *bizParmas = [NSMutableDictionary new];
    [bizParmas cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [bizParmas cj_setObject:[params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [bizParmas cj_setObject:[params cj_stringValueForKey:@"new_wallet_change"] forKey:@"new_wallet_change"];
    [bizParmas cj_setObject:[params cj_stringValueForKey:@"lark_union_gateway_strategy"] forKey:@"lark_union_gateway_strategy"];
    bizParmas.cjpay_referViewController = params.cjpay_referViewController;
    if ([path isEqualToString:@"bdtopupdesk"]) {
        [self i_openNativeBalanceRechargeDeskWithParams:bizParmas delegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
            if (params[CJPayRouterParameterCompletion]) {
                void(^completion)(id) = params[CJPayRouterParameterCompletion];
                CJ_CALL_BLOCK(completion, response);
            }
        }]];
        return YES;
    } else if ([path isEqualToString:@"bdwithdrawaldesk"]) {
        [self i_openNativeBalanceWithdrawDeskWithParams:bizParmas delegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
            if (params[CJPayRouterParameterCompletion]) {
                void(^completion)(id) = params[CJPayRouterParameterCompletion];
                CJ_CALL_BLOCK(completion, response);
            }
        }]];
        return YES;
    }
    return NO;
}


#pragma mark - BDPayNativeUserCenterService
- (void)i_openNativeBalanceRechargeDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    CJPaySettings *settings = [CJPaySettingsManager shared].currentSettings;
    self.apiDelegate = delegate;
    
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];

    __block NSString *cjpayAppId = appId;
    __block NSString *cjpayMerchantId = merchantId;
    __block BOOL isUseH5 = false;
    [settings.degradeModels enumerateObjectsUsingBlock:^(CJPayDegradeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bdpayAppId isEqualToString:appId] && [obj.bdpayMerchantId isEqualToString:merchantId] && obj.isBalanceRechargeUseH5) {
            isUseH5 = true;
            cjpayAppId = obj.cjpayAppId;
            cjpayMerchantId = obj.cjpayMerchantId;
            *stop = YES;
        }
    }];
    
    if (isUseH5) {
        NSMutableDictionary *newParams = [params mutableCopy];
        [newParams cj_setObject:cjpayAppId forKey:@"app_id"];
        [newParams cj_setObject:cjpayMerchantId forKey:@"merchant_id"];
        [newParams cj_setObject:@"true" forKey:@"is_downgrade"];
        
        [self p_openH5BalanceRechargeDeskWithParams:[newParams copy] delegate:delegate];
        
        [CJPayTracker event:@"wallet_change_downgrade_h5" params:@{@"app_id": CJString(cjpayAppId),
                                                                   @"merhcant_id": CJString(cjpayMerchantId),
                                                                   @"is_chaselight": @"1"
        }];
    } else {
        [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
        [self p_openNativeBalanceRechargeDeskWithParams:params delegate:delegate];
    }
}

- (void)p_openH5BalanceRechargeDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayRechargeService) i_openH5RechargeDeskWithParams:params delegate:delegate];
}

- (void)p_openNativeBalanceRechargeDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    [self rechargeBalance:params completion:^(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSString *errorDesc;
        
        switch (resultCode) {
            case BDUserCenterCodeSuccess:
                errorCode = CJPayErrorCodeSuccess;
                errorDesc = @"充值成功";
                break;
            case BDUserCenterCodeFailed:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"充值失败";
                break;
            case BDUserCenterCodeCanceled:
                errorCode = CJPayErrorCodeCancel;
                errorDesc = @"充值取消";
                break;
            case BDUserCenterCodeCustom:
                errorCode = CJPayErrorCodeUnknown;
                errorDesc = @"未知错误";
                
                [CJMonitor trackService:@"wallet_rd_change_unknown_error" metric:@{} category:@{@"code" : CJString(response.code)} extra:@{@"params" : params}];
                
                break;
            default:
                break;
        }
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.data = [response toDictionary];
        apiResponse.scene = CJPaySceneBalanceRecharge;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        } else {
            [CJMonitor trackService:@"wallet_rd_change_null_delegate" metric:@{} category:@{@"code" : CJString(response.code)} extra:@{@"params" : params}];
        }
    }];
}

- (void)i_openNativeBalanceWithdrawDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    CJPaySettings *settings = [CJPaySettingsManager shared].currentSettings;
    self.apiDelegate = delegate;
    
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    
    __block NSString *cjpayAppId = appId;
    __block NSString *cjpayMerchantId = merchantId;
    __block BOOL isUseH5 = false;
    [settings.degradeModels enumerateObjectsUsingBlock:^(CJPayDegradeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bdpayAppId isEqualToString:appId] && [obj.bdpayMerchantId isEqualToString:merchantId] && obj.isBalanceWithdrawUseH5) {
            isUseH5 = true;
            cjpayAppId = obj.cjpayAppId;
            cjpayMerchantId = obj.cjpayMerchantId;
            *stop = YES;
        }
    }];
    
    if (isUseH5) {
        NSMutableDictionary *newParams = [params mutableCopy];
        [newParams cj_setObject:cjpayAppId forKey:@"app_id"];
        [newParams cj_setObject:cjpayMerchantId forKey:@"merchant_id"];
        [newParams cj_setObject:@"true" forKey:@"is_downgrade"];
        [self p_openH5BalanceWithdrawDeskWithParams:[newParams copy] delegate:delegate];
        
        [CJPayTracker event:@"wallet_tixian_downgrade_h5" params:@{
            @"app_id": CJString(appId),
            @"merchant_id": CJString(merchantId),
            @"is_chaselight": @"1"
        }];
        
    } else {
        [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
        [self p_openNativeBalanceWithdrawDeskWithParams:params delegate:delegate];
    }
    
}

- (void)p_openNativeBalanceWithdrawDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    [self withdrawBalance:params completion:^(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response) {
        
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSString *errorDesc;
        
        switch (resultCode) {
            case BDUserCenterCodeSuccess:
                errorCode = CJPayErrorCodeSuccess;
                errorDesc = @"提现成功";
                break;
            case BDUserCenterCodeFailed:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"提现失败";
                break;
            case BDUserCenterCodeCanceled:
                errorCode = CJPayErrorCodeCancel;
                errorDesc = @"提现取消";
                break;;
            case BDUserCenterCodeCustom:
                errorCode = CJPayErrorCodeUnknown;
                errorDesc = @"未知错误";
                break;
            default:
                break;
        }
        
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.data = [response toDictionary];
        apiResponse.scene = CJPaySceneBalanceWithdraw;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }
    }];
}

- (void)p_openH5BalanceWithdrawDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayWithdrawService) i_openH5WithdrawDeskWithParams:params delegate:delegate];
}

@end
