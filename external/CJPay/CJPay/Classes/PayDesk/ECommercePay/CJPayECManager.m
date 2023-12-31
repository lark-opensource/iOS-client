//
//  CJPayECManager.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayECManager.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayECController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayTracker.h"
#import "CJPayECVerifyManager.h"
#import "CJPayMetaSecManager.h"
#import "CJPayTransferPayModule.h"
#import "CJPayCashierModule.h"
#import "CJPayBioPaymentPlugin.h"
#import "NSObject+CJPay.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayKVContext.h"
#import "CJPayECControllerV2.h"
#import "CJPayABTestManager.h"
#import "CJPaySaasSceneUtil.h"

@interface CJPayECManager() <CJPayEcommerceDeskService>

@property (nonatomic, assign) BOOL isInPaying;
@property (nonatomic, strong) NSMutableArray *mutableControllers;

@end

@implementation CJPayECManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayEcommerceDeskService)
})

+ (instancetype)defaultService {
    static CJPayECManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayECManager alloc] init];
    });
    return manager;
}

- (NSMutableArray *)mutableControllers {
    if (!_mutableControllers) {
        _mutableControllers = [NSMutableArray new];
    }
    return _mutableControllers;
}

- (void)i_openEcommercePayDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    NSString *isDouPayProcess = [CJPayABTest getABTestValWithKey:CJPayABIsDouPayProcess exposure:YES];
    if ([isDouPayProcess isEqualToString:@"1"]) { //命中新架构
        [self p_openECPayDeskWithParams:params delegate:delegate];
        return;
    }
    
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) correctLocalTime];
    [CJTracker event:@"finance_ecommerce_open_desk" params:params];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
    if (self.isInPaying) {
        if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:NO fromScene:CJPayScenePay];
            [CJTracker event:@"finance_ecommerce_callState" params:params];
        }
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
            apiResponse.scene = CJPaySceneEcommercePay;
            apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail    userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"有正在处理的订单，请不要重复下单", nil)}];
            [delegate onResponse:apiResponse];
            [CJTracker event:@"finance_ecommerce_result" params:@{@"error": @"有正在处理的订单"}];
        }
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
        return; // 有点风险，看是否拦截
    }
    self.isInPaying = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayRleasePayingState) object:nil];
    [self performSelector:@selector(delayRleasePayingState) withObject:nil afterDelay:1.0];
    @CJWeakify(self)
    CJPayECController *ecommerceController = [CJPayECController new];
    @CJWeakify(ecommerceController)
    [self.mutableControllers addObject:ecommerceController];
    
    NSTimeInterval currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    NSString *saasRecordKey = [NSString stringWithFormat:@"%ld_%d", (long)CJPaySceneEcommercePay, (int)currentTimestamp];
    [CJPaySaasSceneUtil addSaasKey:saasRecordKey saasSceneValue:[params cj_stringValueForKey:@"saas_scene"]]; //设置全局SaaS环境标识

    [CJTracker event:@"wallet_rd_ecommerce_paydesk_call"
              params:@{@"type": @"call"}];
    [ecommerceController startPaymentWithParams:params completion:^(CJPayManagerResultType resultType, NSString * _Nonnull errorMsg) {
        [CJTracker event:@"wallet_rd_ecommerce_paydesk_call"
                  params:@{@"type": @"call_back"}];
        
        [CJPaySaasSceneUtil removeSaasSceneByKey:saasRecordKey]; //结束支付流程时清除全局SaaS标识
        
        @CJStrongify(self)
        @CJStrongify(ecommerceController)
        if (resultType == CJPayManagerResultOpenFailed) {
            
            [CJMonitor trackService:@"wallet_rd_ecommerce_desk_open_fail" extra:@{
                @"params": CJString([params cj_toStr]),
                @"error_desc": CJString(errorMsg)
            }];
            
            if ([delegate respondsToSelector:@selector(callState:fromScene:)]) {
                [delegate callState:NO fromScene:CJPaySceneEcommercePay];
                [CJTracker event:@"finance_ecommerce_callState" params:params];
            }
            self.isInPaying = NO;
            [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
            return;
        }
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        switch (resultType) {
            case CJPayManagerResultCancel:
                errorCode = CJPayErrorCodeCancel;
                break;
            case CJPayManagerResultFailed:
                errorCode = CJPayErrorCodeFail;
                break;
            case CJPayManagerResultSuccess:
                errorCode = CJPayErrorCodeSuccess;
                break;;
            case CJPayManagerResultTimeout:
                errorCode = CJPayErrorCodeOrderTimeOut;
                break;
            case CJPayManagerResultProcessing:
                errorCode = CJPayErrorCodeProcessing;
                break;
            case CJPayManagerResultError:
                errorCode = CJPayErrorCodeUnknown;
                break;
            case CJPayManagerResultOpenFailed:
                errorCode = CJPayErrorCodeFail;
                break;
            case CJPayManagerResultInsufficientBalance:
                errorCode = CJPayErrorCodeInsufficientBalance;
                break;
            default:
                break;
        }
        BOOL isEcommerceScene = ecommerceController.cashierScene == CJPayCashierSceneEcommerce;
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = isEcommerceScene ? CJPaySceneEcommercePay : CJPayScenePreStandardPay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
        
        CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
        // 回调业务方参数
        NSDictionary *newCreateOrderResponse = [params cj_dictionaryValueForKey:@"create_order_response"];
        apiResponse.data = @{
            @"sdk_code": @(errorCode),
            @"sdk_msg": CJString(errorMsg),
            @"sdk_check_type": CJString([ecommerceController.verifyManager.lastWakeVerifyItem checkTypeName]),
            @"sdk_performance": [ecommerceController getPerformanceInfo] ?: @{},  //性能参数
            @"has_cashier_show_retain": model.hasShow ? @"1" : @"0", //是否在native流程展示过挽留
            @"create_order_response" : Check_ValidDictionary(newCreateOrderResponse) ? newCreateOrderResponse : @{}
        };
        //只有电商场景才走if里的逻辑
        if ([[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController].navigationController isKindOfClass:CJPayNavigationController.class] && isEcommerceScene) {

            [CJMonitor trackService:@"wallet_rd_ecommerce_callback_exception" extra:@{
                @"topVC": CJString(NSStringFromClass([UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController].class)),
                @"ecommerce_result": CJString([apiResponse.data cj_toStr])
            }];
            
            [CJTracker event:@"ecommerce_callback_has_vc" params:@{}];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(onResponse:)]) {
                    [delegate onResponse:apiResponse];
                    [CJTracker event:@"finance_ecommerce_result" params:apiResponse.data];
                }
                self.isInPaying = NO;
                [self.mutableControllers removeObject:ecommerceController];
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
            });
            return;
        }
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
            [CJTracker event:@"finance_ecommerce_result" params:apiResponse.data];
        }
        [self.mutableControllers removeObject:ecommerceController];
        self.isInPaying = NO;
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
    }];
}

- (void)p_openECPayDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) correctLocalTime];
    [CJTracker event:@"finance_ecommerce_open_desk" params:params];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeOpenCashdesk];
    if (self.isInPaying) {
        if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:NO fromScene:CJPayScenePay];
            [CJTracker event:@"finance_ecommerce_callState" params:params];
        }
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
            apiResponse.scene = CJPaySceneEcommercePay;
            apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail    userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"有正在处理的订单，请不要重复下单", nil)}];
            [delegate onResponse:apiResponse];
            [CJTracker event:@"finance_ecommerce_result" params:@{@"error": @"有正在处理的订单"}];
        }
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
        return; // 有点风险，看是否拦截
    }
    self.isInPaying = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayRleasePayingState) object:nil];
    [self performSelector:@selector(delayRleasePayingState) withObject:nil afterDelay:1.0];
    @CJWeakify(self)
    CJPayECControllerV2 *ecController = [CJPayECControllerV2 new];
    [self.mutableControllers addObject:ecController];
    
    NSTimeInterval currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    NSString *saasRecordKey = [NSString stringWithFormat:@"%ld_%d", (long)CJPaySceneEcommercePay, (int)currentTimestamp];
    [CJPaySaasSceneUtil addSaasKey:saasRecordKey saasSceneValue:[params cj_stringValueForKey:@"saas_scene"]]; //设置全局SaaS环境标识
    
    @CJWeakify(ecController)
    [CJTracker event:@"wallet_rd_ecommerce_paydesk_call"
              params:@{@"type": @"call"}];
    [ecController startPaymentWithParams:params completion:^(CJPayDouPayResultCode resultCode, NSString * _Nonnull errorMsg) {
        
        [CJPaySaasSceneUtil removeSaasSceneByKey:saasRecordKey]; //结束支付流程时清除全局SaaS标识
        [CJTracker event:@"wallet_rd_ecommerce_paydesk_call"
                  params:@{@"type": @"call_back"}];
        
        @CJStrongify(self)
        @CJStrongify(ecController)
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        switch (resultCode) {
            case CJPayDouPayResultCodeCancel:
                errorCode = CJPayErrorCodeCancel;
                break;
            case CJPayDouPayResultCodeFail:
                errorCode = CJPayErrorCodeFail;
                break;
            case CJPayDouPayResultCodeOrderSuccess:
                errorCode = CJPayErrorCodeSuccess;
                break;;
            case CJPayDouPayResultCodeOrderTimeout:
                errorCode = CJPayErrorCodeOrderTimeOut;
                break;
            case CJPayDouPayResultCodeOrderProcess:
                errorCode = CJPayErrorCodeProcessing;
                break;
            case CJPayDouPayResultCodeUnknown:
                errorCode = CJPayErrorCodeUnknown;
                break;
            case CJPayDouPayResultCodeParamsError:
                errorCode = CJPayErrorCodeFail;
                break;
            case CJPayDouPayResultCodeInsufficientBalance:
                errorCode = CJPayErrorCodeInsufficientBalance;
                break;
            default:
                errorCode = CJPayErrorCodeUnknown;
                break;
        }
        BOOL isEcommerceScene = ecController.cashierScene == CJPayCashierSceneEcommerce;
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = isEcommerceScene ? CJPaySceneEcommercePay : CJPayScenePreStandardPay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
        
        CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
        // 回调业务方参数
        NSDictionary *newCreateOrderResponse = [params cj_dictionaryValueForKey:@"create_order_response"];
        apiResponse.data = @{
            @"sdk_code": @(errorCode),
            @"sdk_msg": CJString(errorMsg),
            @"sdk_check_type": CJString([ecController checkTypeName]),
            @"sdk_performance": [ecController getPerformanceInfo] ?: @{}, //性能参数
            @"has_cashier_show_retain": model.hasShow ? @"1" : @"0", //是否在native流程展示过挽留
            @"create_order_response" : Check_ValidDictionary(newCreateOrderResponse) ? newCreateOrderResponse : @{}
        };
        //只有电商场景才走if里的逻辑
        if ([[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController].navigationController isKindOfClass:CJPayNavigationController.class] && isEcommerceScene) {

            [CJMonitor trackService:@"wallet_rd_ecommerce_callback_exception" extra:@{
                @"topVC": CJString(NSStringFromClass([UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController].class)),
                @"ecommerce_result": CJString([apiResponse.data cj_toStr])
            }];
            
            [CJTracker event:@"ecommerce_callback_has_vc" params:@{}];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(onResponse:)]) {
                    [delegate onResponse:apiResponse];
                    [CJTracker event:@"finance_ecommerce_result" params:apiResponse.data];
                }
                [self.mutableControllers removeObject:ecController];
                self.isInPaying = NO;
                [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
            });
            return;
        }
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
            [CJTracker event:@"finance_ecommerce_result" params:apiResponse.data];
        }
        [self.mutableControllers removeObject:ecController];
        self.isInPaying = NO;
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneEcommercePayDeskKey extra:@{}];
    }];
}

- (void)i_openECLargePayDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayTransferPayModule) startTransferPayWithParams:params
                                                                     completion:^(CJPayManagerResultType type, NSString * _Nonnull errorMsg) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        switch (type) {
            case CJPayManagerResultCancel:
                errorCode = CJPayErrorCodeCancel;
                break;
            case CJPayManagerResultFailed:
                errorCode = CJPayErrorCodeFail;
                break;
            case CJPayManagerResultSuccess:
                errorCode = CJPayErrorCodeSuccess;
                break;;
            case CJPayManagerResultTimeout:
                errorCode = CJPayErrorCodeOrderTimeOut;
                break;
            case CJPayManagerResultProcessing:
                errorCode = CJPayErrorCodeProcessing;
                break;
            default:
                break;
        }
        
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneEcommercePay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain
                                                code:errorCode
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
        apiResponse.data = @{
            @"sdk_code": @(errorCode),
            @"sdk_msg": CJString(errorMsg),
            @"sdk_check_type": @""
        };
        
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }
    }];
}

- (void)delayRleasePayingState {
    self.isInPaying = NO;
}

#pragma - mark wake by universalPayDesk
- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    
    // 此处根据way来分流大额支付与普通前置支付（电商、本地生活等）
    int way = [dictionary cj_intValueForKey:@"way"];
    if (way == 17) {
        [self i_openECLargePayDeskWithParams:dictionary
                                    delegate:delegate];
        return YES;
    }
    
    NSMutableDictionary *data = [dictionary mutableCopy];
    [data cj_setObject:[data cj_stringValueForKey:@"zg_info"] forKey:@"channel_data"];
    
    [self i_openEcommercePayDeskWithParams:[data copy] delegate:delegate];
    return YES;
}

@end
