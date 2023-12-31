//
//  CJPayDyPayManager.m
//  CJPay
//
//  Created by xutianxi on 2022/9/22.
//

#import "CJPayDyPayManager.h"

#import "CJPayCookieUtil.h"
#import "CJSDKParamConfig.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayDyPayModule.h"
#import "CJPayExceptionViewController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayDegradeModel.h"
#import "CJPayMetaSecManager.h"
#import "CJPayH5DeskModule.h"
#import "CJPayDyPayCreateOrderRequest.h"
#import "CJPayDySignPayHomePageViewController.h"
#import "CJPayDySignPayDetailViewController.h"
#import "UIViewController+CJPay.h"
#import "CJPayToast.h"
#import "CJPayAlertUtil.h"
#import "CJPayDyPayController.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayDyPayControllerV2.h"
#import "CJPaySignPageInfoModel.h"
#import "CJPaySettingsManager.h"
#import "CJPayOutDisplayInfoModel.h"
#import "CJPayKVContext.h"

typedef void(^CreateOrderRequestCompletionBlock)(NSError * _Nullable error, NSDictionary * _Nullable response);

@interface CJPayDyPayManager() <CJPayDyPayModule>

@property (nonatomic, weak) id<CJPayAPIDelegate> apiDelegate;
@property (nonatomic, strong) NSMutableArray *mutableControllers;
@property (nonatomic, strong) NSMutableDictionary *preRequestCreateOrderCacheDict;
@property (nonatomic, strong) NSMutableDictionary *preRequestCreateOrderCompletionBlocksDict; // key是startTime，value是block数组
@property (nonatomic, assign) BOOL isPreRequestCreateOrderDoing;

@end

@implementation CJPayDyPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayDyPayModule)
})

+ (instancetype)sharedInstance {
    static CJPayDyPayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayDyPayManager alloc] init];
        manager.preRequestCreateOrderCacheDict = [NSMutableDictionary new];
        manager.preRequestCreateOrderCompletionBlocksDict = [NSMutableDictionary new];
        manager.isPreRequestCreateOrderDoing = NO;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)mutableControllers {
    if (!_mutableControllers) {
        _mutableControllers = [NSMutableArray new];
    }
    return _mutableControllers;
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
            if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
                [self.apiDelegate onResponse:apiResponse];
            }
        }];
    }
}

#pragma mark - CJBizWebDelegate
- (void)p_handleCJPayManagerResult:(CJPayBDOrderResultResponse *)response orderStatus:(CJPayOrderStatus)status {
    NSString *resultCode = @"2";
    // 通知api delegate
    if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSString *errorDesc;
        if (response && response.tradeInfo != nil) {
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusProcess:
                    errorCode = CJPayErrorCodeProcessing;
                    errorDesc = @"支付结果处理中...";
                    resultCode = @"3";
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
                    resultCode = @"0";
                    break;
                default:
                    break;
            }
        } else if (status == CJPayOrderStatusCancel) { //
            errorCode = CJPayErrorCodeCancel;
            errorDesc = @"用户取消支付";
            resultCode = @"1";
        } else if (status ==  CJPayOrderStatusTimeout) {
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"订单超时";
        } else if (status == CJPayOrderStatusOrderFail) {
            errorCode = CJPayErrorCodeOrderFail;
            errorDesc = @"下单失败";
        } else {
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
        }
        [self p_trackWithEvent:@"wallet_cashier_outerpay_result" extraParams:@{@"result_code":resultCode}];
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.data = [response toDictionary];
        apiResponse.scene = CJPaySceneBDPay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        [self.apiDelegate onResponse:apiResponse];
        [CJToast toastText:CJString([[response toDictionary] cj_toStr]) inWindow:[UIViewController cj_topViewController].cj_window];
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
    }
}

#pragma mark - CJPayDyPayModule
- (void)i_openDyPayDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    NSString *platform = [params cj_stringValueForKey:@"platform"];
    if (Check_ValidString(platform)) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        [trackData addEntriesFromDictionary:@{@"platform":platform}];
        [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
    }

    if (delegate) {
        self.apiDelegate = delegate;
    }
    
    //CJPayLogInfo(@"[CJPayDyPayManager i_openDyPayDeskWithParams:%@]", [CJPayCommonUtil dictionaryToJson:params]);
    NSMutableDictionary *allParamsDict = [[NSMutableDictionary alloc] initWithDictionary:params];
    NSString *allParamsString = [[params cj_stringValueForKey:@"all_params"] stringByRemovingPercentEncoding];// 中文解码
    if (Check_ValidString(allParamsString)) {
        [allParamsDict removeObjectForKey:@"all_params"];
        [allParamsDict addEntriesFromDictionary:[CJPayCommonUtil jsonStringToDictionary:allParamsString]];
    }
    
    NSString *openMerchantId = [allParamsDict cj_stringValueForKey:@"partnerid" defaultValue:@""];
    if (!Check_ValidString(openMerchantId)) {
        openMerchantId = [allParamsDict cj_stringValueForKey:@"merchant_id" defaultValue:@""];
    }
    
    CJPayLoadingType loadingType = CJPayLoadingTypeDouyinOpenDeskLoading;
    if ([self p_fromInner:params]) {
        loadingType = CJPayLoadingTypeDouyinLoading;
    }
    if (![[CJPayLoadingManager defaultService] isLoading]) {
        [[CJPayLoadingManager defaultService] startLoading:loadingType vc:[UIViewController cj_topViewController]];
    }
    
    @CJWeakify(self)
    __auto_type completionBlock = ^(NSError *error, CJPayBDCreateOrderResponse *response) {
        @CJStrongify(self);
        NSString *merchantId = response.merchant.merchantId;
        
        [self p_trackWithEvent:@"wallet_cashier_SDK_pull_result"
                   extraParams:@{
            @"code":CJString(response.code),
            @"message":CJString(response.msg),
            @"merchant_id":CJString(merchantId),
        }];
        
        if ([response isSuccess]) {
            if ([delegate respondsToSelector:@selector(callState:fromScene:params:)]) {
                [delegate callState:YES fromScene:CJPaySceneOuterDyPay params:@{
                    @"mobile" : CJString(response.userInfo.accountMobile),
                    @"need_animated": @(YES)}];
            }
            if (response.signPageInfo) { // 这里的逻辑是signPageInfo字段不为空则走签约并支付
                @CJStrongify(self);
                [self p_startOuterSignPay:params allParamsDict:allParamsDict response:response error:error];
                [[CJPayLoadingManager defaultService] stopLoading:loadingType];
            } else {
                if (![response.deskConfig isFastEnterBindCard]) {
                    [[CJPayLoadingManager defaultService] stopLoading:loadingType];
                }
                [self p_startOuterPay:allParamsDict response:response error:error openMerchantId:openMerchantId];
            }
        } else {
            [[CJPayLoadingManager defaultService] stopLoading:loadingType];
            NSString *errorMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayLocalizedStr(@"网络异常，请稍后再试");
            [CJPayAlertUtil singleAlertWithTitle:errorMsg content:nil buttonDesc:@"我知道了" actionBlock:^{
                [self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusOrderFail];
            } useVC:[UIViewController cj_topViewController]];
            
            [self p_trackWithEvent:@"wallet_cashier_douyin_to_pay_error_pop"
                       extraParams:@{@"error_msg": CJString(errorMsg),
                                     @"error_code":CJString(response.code)}];
        }
    };
    
    [self p_trackWithEvent:@"wallet_cashier_douyin_to_pay_sys" extraParams:@{}];
    if ([[CJPayABTest getABTestValWithKey:CJPayEnableLaunchOptimize exposure:YES] isEqualToString:@"1"]) {
        [self i_requestCreateOrderBeforeOpenDyPayDeskWith:allParamsDict completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull responseDict) {
            @CJStrongify(self)
            CJPayBDCreateOrderResponse *response = [responseDict cj_objectForKey:@"dypay_create_order_response"];
            if (response && [response isKindOfClass:[CJPayBDCreateOrderResponse class]]) {
                CJ_CALL_BLOCK(completionBlock, error, response);
            } else {
                [[CJPayLoadingManager defaultService] stopLoading:loadingType];
                NSString *errorMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayLocalizedStr(@"网络异常，请稍后再试");
                [CJPayAlertUtil singleAlertWithTitle:errorMsg content:nil buttonDesc:@"我知道了" actionBlock:^{
                    [self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusOrderFail];
                } useVC:[UIViewController cj_topViewController]];
                
                [self p_trackWithEvent:@"wallet_cashier_douyin_to_pay_error_pop"
                           extraParams:@{@"error_msg": CJString(errorMsg),
                                         @"error_code":CJString(response.code)}];
            }
        }];
    } else {
        [self p_trackWithEvent:@"wallet_cashier_SDK_pull_start" extraParams:@{}];
        [CJPayDyPayCreateOrderRequest startWithMerchantId:openMerchantId
                                                bizParams:allParamsDict
                                               completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
            @CJStrongify(self)
            [self p_trackWithEvent:@"wallet_cashier_SDK_pull_result"
                       extraParams:@{@"error_msg":CJString(response.msg),
                                     @"error_code":CJString(response.code)}];
            CJ_CALL_BLOCK(completionBlock, error, response);
        }];
    }
}

- (void)i_requestCreateOrderBeforeOpenDyPayDeskWith:(NSDictionary *)params completion:(CreateOrderRequestCompletionBlock)completion {
    [self p_trackWithEvent:@"wallet_rd_cashier_request_create_order_before_open_dypay" extraParams:@{}];
    
    BOOL isColdLaunch = NO;
    if ([params cj_objectForKey:@"is_cold_launch"]) {
        isColdLaunch = [params cj_boolValueForKey:@"is_cold_launch"];
    }
    
    long long handledLastTime = [params btd_longLongValueForKey:@"start_time" default:0];
    NSString *cacheKey = [NSString stringWithFormat:@"%ld", handledLastTime];
    if (isColdLaunch) {
        CJPayBDCreateOrderResponse *cachedResponse = [self.preRequestCreateOrderCacheDict cj_objectForKey:cacheKey];
        if (cachedResponse && [cachedResponse isKindOfClass:[CJPayBDCreateOrderResponse class]]) {
            [self p_trackWithEvent:@"wallet_rd_cashier_request_create_order_before_open_dypay_cached" extraParams:@{}];
            CJ_CALL_BLOCK(completion, nil, @{@"dypay_create_order_response": cachedResponse});
            return;
        }
        
        if (self.isPreRequestCreateOrderDoing && completion) {
            NSMutableArray *blockArray = [self.preRequestCreateOrderCompletionBlocksDict cj_objectForKey:cacheKey];
            if (blockArray) {
                [blockArray addObject:completion];
            } else {
                [self.preRequestCreateOrderCompletionBlocksDict setObject:[NSMutableArray arrayWithObject:completion] forKey:cacheKey];
            }
            return;
        }
    }
    
    self.isPreRequestCreateOrderDoing = YES;
    
    NSString *openMerchantId = [params cj_stringValueForKey:@"partnerid" defaultValue:@""];
    if (!Check_ValidString(openMerchantId)) {
        openMerchantId = [params cj_stringValueForKey:@"merchant_id" defaultValue:@""];
    }
    
    [self p_trackWithEvent:@"wallet_cashier_SDK_pull_start" extraParams:@{}];
    @CJWeakify(self);
    [CJPayDyPayCreateOrderRequest startWithMerchantId:openMerchantId
                                            bizParams:params
                                         highPriority:YES // 提高请求优先级
                                           completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self);
        [self p_trackWithEvent:@"wallet_cashier_SDK_pull_result"
                   extraParams:@{@"code":CJString(response.code),
                                 @"message":CJString(response.msg)}];
        self.isPreRequestCreateOrderDoing = NO;
        CJ_CALL_BLOCK(completion, error, response ? @{@"dypay_create_order_response": response} : nil);
        
        if (isColdLaunch) {
            if (!response || ![response isSuccess]) {
                [self p_trackWithEvent:@"wallet_rd_cashier_request_create_order_before_open_dypay_failed" extraParams:@{
                    @"error": error.localizedDescription ?: @""
                }];
            }
            
            [self.preRequestCreateOrderCacheDict removeAllObjects];
            if (response && [response isSuccess]) {
                [self.preRequestCreateOrderCacheDict btd_setObject:response forKey:cacheKey];
            }
            
            NSMutableArray *blockArray = [self.preRequestCreateOrderCompletionBlocksDict cj_objectForKey:cacheKey];
            for (CreateOrderRequestCompletionBlock block in blockArray) {
                CJ_CALL_BLOCK(block, error, response ? @{@"dypay_create_order_response": response} : nil);
            }
            
            [self.preRequestCreateOrderCompletionBlocksDict removeObjectForKey:cacheKey];
        }
    }];
}

#pragma mark - Other
- (void)openDySignPayDesk:(NSDictionary *)params response:(CJPayBDCreateOrderResponse *)response completion:(void (^)(void))completion {
    if ([self p_isDouPayProcess]) {
        CJPayDyPayControllerV2 *dypayControllerV2 = [CJPayDyPayControllerV2 new];
        @CJWeakify(self)
        @CJWeakify(dypayControllerV2)
        [self.mutableControllers btd_addObject:dypayControllerV2];
        if ([[params cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"]) {
            [self p_operateSignPayResponse:response];
        }
        [dypayControllerV2 startSignPaymentWithParams:params
                                  createOrderResponse:response
                                      completionBlock:^(CJPayErrorCode resultCode, NSString * _Nonnull msg) {
            @CJStrongify(self)
            @CJStrongify(dypayControllerV2)
            if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
                CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
                apiResponse.data = @{@"msg": CJString(msg)};
                apiResponse.scene = CJPaySceneOuterDyPay;
                apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:resultCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)}];
                [self.apiDelegate onResponse:apiResponse];
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
            }
            [self.mutableControllers removeObject:dypayControllerV2];
        }];
        return;
    }
    
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [allParams cj_setObject:@(YES) forKey:@"is_cancel_retain_window"];
    if ([[params cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"]) {
        [allParams cj_setObject:@(YES) forKey:@"is_simple_verify_style"];
        [self p_operateSignPayResponse:response];
    }
    NSString *openMerchantId = [params cj_stringValueForKey:@"partnerid" defaultValue:@""];
    CJPayDyPayController *dypayController = [CJPayDyPayController new];
    dypayController.isPayOuterMerchant = Check_ValidString(openMerchantId);
    [self.mutableControllers addObject:dypayController];
    @CJWeakify(self)
    @CJWeakify(dypayController)
    [dypayController startPaymentWithParams:allParams createOrderResponse:response completionBlock:^(CJPayBDOrderResultResponse * _Nonnull resResponse, CJPayOrderStatus orderStatus) {
        @CJStrongify(self);
        @CJStrongify(dypayController)
        if (resResponse) {
            //这里判断的是 response是否存在。
            [self p_handleCJPayManagerResult:resResponse orderStatus:orderStatus];
            [self.mutableControllers removeObject:dypayController];
        }
    }];
}

- (BOOL)p_fromInner:(NSDictionary *)params {
    return [[params cj_stringValueForKey:@"invoke_source"] isEqualToString:@"0"];
}

- (void)p_startOuterSignPay:(NSDictionary *)params allParamsDict:(NSDictionary *)allParamsDict response:(CJPayBDCreateOrderResponse *)response error:(NSError *)error {
    UINavigationController *navigationController = params.cjpay_referViewController.navigationController;
    CJPaySignPayConfig *signPayConfig = [CJPaySettingsManager shared].currentSettings.signPayConfig;
    BOOL useNativeSignAndPay = signPayConfig ? signPayConfig.useNativeSignAndPay : YES;
    if (useNativeSignAndPay) {
        // native版本
        CJPayDySignPayDetailViewController *signPayVC = [[CJPayDySignPayDetailViewController alloc] initWithResponse:response allParamsDict:allParamsDict];
        signPayVC.clickBackBlock = ^{
            [self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusCancel];
        };
        
        if (navigationController) {
            [navigationController pushViewController:signPayVC animated:YES];
        } else {
            [signPayVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:NO completion:nil];
        }
    } else {
        CJPayDySignPayHomePageViewController *signPayVC = [[CJPayDySignPayHomePageViewController alloc] initPageWithParams:allParamsDict response:response];
        @CJWeakify(signPayVC)
        @CJWeakify(self)
        signPayVC.resultBlock = ^(BOOL isSuccess, NSError * _Nullable loadError) {
            @CJStrongify(signPayVC)
            @CJStrongify(self)
            [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinOpenDeskLoading];
            if (!isSuccess) {
                if (loadError.code == CJPayOrderStatusFail) {
                    //加载失败拉起一个弹窗告知用户拉起失败并返回业务方app
                    [CJPayAlertUtil singleAlertWithTitle:@"加载出错啦"
                                                 content:error.domain
                                              buttonDesc:@"我知道了"
                                             actionBlock:^{[self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusNull];}
                                                   useVC:[UIViewController cj_topViewController]];
                } else if (loadError.code == CJPayOrderStatusCancel) {
                    [self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusCancel];
                } else {
                    [self p_handleCJPayManagerResult:nil orderStatus:CJPayOrderStatusNull];
                }
            }
        };
        [signPayVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:NO completion:nil];
    }
}

- (void)p_startOuterPay:(NSDictionary *)allParamsDict response:(CJPayBDCreateOrderResponse *)response error:(NSError *)error openMerchantId:(NSString *)openMerchantId {
    if ([self p_isDouPayProcess]) {
        __block CJPayDyPayControllerV2 *dypayController = [CJPayDyPayControllerV2 new];
        BOOL isPayOuterMerchant = Check_ValidString(openMerchantId);
        @CJWeakify(self)
        dypayController.trackEventBlock = ^(NSString *event, NSDictionary *params) {
            @CJStrongify(self)
            [self p_trackWithEvent:event extraParams:params];
        };
        
        [dypayController startPaymentWithParams:allParamsDict createOrderResponse:response isPayOuterMerchant:isPayOuterMerchant completionBlock:^(CJPayErrorCode resultCode, NSString * _Nonnull msg) {
            @CJStrongify(self)
            if (self.apiDelegate && [self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
                CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
                apiResponse.data = @{@"msg": CJString(msg)};
                apiResponse.scene = CJPaySceneOuterDyPay;
                apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:resultCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)}];
                [self.apiDelegate onResponse:apiResponse];
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOwnPayKey extra:@{}];
            }
            dypayController = nil;
        }];
        return;
    }
    
    CJPayDyPayController *dypayController = [CJPayDyPayController new];
    dypayController.isPayOuterMerchant = Check_ValidString(openMerchantId);
    [self.mutableControllers addObject:dypayController];
    @CJWeakify(dypayController);
    @CJWeakify(self)
    [dypayController startPaymentWithParams:allParamsDict createOrderResponse:response completionBlock:^(CJPayBDOrderResultResponse * _Nonnull resResponse, CJPayOrderStatus orderStatus) {
        @CJStrongify(self)
        @CJStrongify(dypayController)
        [self p_handleCJPayManagerResult:resResponse orderStatus:orderStatus];
        [self.mutableControllers removeObject:dypayController];
    }];
}

- (BOOL)p_isDouPayProcess {
    return [[[CJPayABTestManager sharedInstance] getABTestValWithKey:CJPayABIsDouPayProcess exposure:NO] isEqualToString:@"1"];
}

- (void)p_operateSignPayResponse:(CJPayBDCreateOrderResponse *)response {
    NSDecimalNumber *realTradeNumber = [NSDecimalNumber decimalNumberWithString:response.signPageInfo.realTradeAmount];
    NSString *realTradeAmount;
     if ([realTradeNumber compare:[NSDecimalNumber zero]] == NSOrderedSame || [[NSDecimalNumber notANumber] isEqualToNumber:realTradeNumber]) {
         realTradeAmount = @"--";
         CJPayLogInfo(@"真实金额错误 signPageInfo.realTradeAmount");
     } else {
         CGFloat realTradeFloat = [[realTradeNumber decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] floatValue] ;
         realTradeAmount = [NSString stringWithFormat:@"%.2f",realTradeFloat];
     }
    NSString *voucher = CJString(response.signPageInfo.promotionDesc);
    CJPaySubPayTypeInfoModel *model = [response.payTypeInfo.subPayTypeSumInfo.subPayTypeInfoList cj_objectAtIndex:0];
    model.payTypeData.standardShowAmount = realTradeAmount;
    model.payTypeData.standardRecDesc = voucher;    //修改营销展示字段，与签约页对齐
    response.payTypeInfo.allPayChannels = nil; //allPayChannels置空原因：让密码页强制刷新构造defaultShowConfig的逻辑，确保营销替换可以生效
    CJPayInfo *payInfo = response.payInfo ?: [CJPayInfo new];
    payInfo.retainInfo = response.retainInfo;
    payInfo.retainInfoV2 = response.retainInfoV2;
    response.payInfo = payInfo;
}

// 追光唤端埋点方法
- (void)p_trackWithEvent:(NSString *)event extraParams:(NSDictionary *)extraParams {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                          @"is_chaselight":@"1"}];
    [trackData addEntriesFromDictionary:extraParams];
    [CJPayTracker event:event params:trackData];
}

@end
