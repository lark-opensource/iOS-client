//
//  CJPayDyPayControllerV2.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/14.
//

#import "CJPayDyPayControllerV2.h"
#import "CJPayDouPayProcessController.h"
#import "CJPayUIMacro.h"
#import "CJPayDyPayCreateOrderRequest.h"

@interface CJPayDyPayControllerV2()

@property (nonatomic, copy) void (^completion)(CJPayErrorCode errorCode, NSString * _Nonnull msg);
@property (nonatomic, strong) NSMutableArray *mutableControllers;

@end

@implementation CJPayDyPayControllerV2

- (void)startPaymentWithParams:(NSDictionary *)params createOrderResponse:(CJPayBDCreateOrderResponse *)response isPayOuterMerchant:(BOOL)isPayOuterMerchant completionBlock:(void (^)(CJPayErrorCode errorCode, NSString * _Nonnull msg))completionBlock {
    self.completion = completionBlock;
    [CJPayLoadingManager defaultService].loadingStyleInfo = response.loadingStyleInfo;
    
    CJPayDouPayProcessController *douController = [CJPayDouPayProcessController new];
    CJPayDouPayProcessModel *douModel = [CJPayDouPayProcessModel new];
    douModel.isFrontPasswordVerify = YES;
    douModel.createResponse = response;
    douModel.resultPageStyle = CJPayDouPayResultPageStyleShowAll;
    douModel.cashierType = CJPayCashierTypeFullPage;
    douModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceOuterDypay;
    douModel.showConfig = [response.payTypeInfo getDefaultDyPayConfig];
    douModel.isFromOuterApp = isPayOuterMerchant;
    douModel.bizParams = params;
    douModel.refreshCreateOrderBlock = ^(CJPayRefreshCreateOrderCompletionBlock _Nonnull refreshCompletionBlock) {
        CJ_CALL_BLOCK(self.trackEventBlock, @"wallet_cashier_SDK_pull_start", @{});
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        [CJPayDyPayCreateOrderRequest startWithMerchantId:[params cj_stringValueForKey:@"partnerid" defaultValue:@""]
                                                bizParams:params
                                               completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
            CJ_CALL_BLOCK(self.trackEventBlock, @"wallet_cashier_SDK_pull_result", @{@"error_msg":CJString(response.msg), @"error_code":CJString(response.code)});
            CJ_CALL_BLOCK(refreshCompletionBlock, response);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
            });
        }];
    };
    @CJWeakify(self)
    @CJWeakify(douController)
    [self.mutableControllers btd_addObject:douController];
    [douController douPayProcessWithModel:douModel completion:^(CJPayDouPayProcessResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        @CJStrongify(douController)
        [self p_handleDouPayResult:resultModel];
        [self.mutableControllers removeObject:douController];
    }];
}


- (void)startSignPaymentWithParams:(NSDictionary *)params
               createOrderResponse:(CJPayBDCreateOrderResponse *)response
                   completionBlock:(nonnull void (^)(CJPayErrorCode errorCode, NSString * _Nonnull msg))completionBlock {
    self.completion = completionBlock;
    
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [bizParams cj_setObject:@(YES) forKey:@"is_cancel_retain_window"];
    if ([[params cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"]) {
        [bizParams cj_setObject:@(YES) forKey:@"is_simple_verify_style"];
    }
    NSString *openMerchantId = [params cj_stringValueForKey:@"partnerid" defaultValue:@""];
    [CJPayLoadingManager defaultService].loadingStyleInfo = response.loadingStyleInfo;
    CJPayDouPayProcessController *douPayController = [CJPayDouPayProcessController new];
    CJPayDouPayProcessModel *douModel = [CJPayDouPayProcessModel new];
    douModel.createResponse = response;
    douModel.resultPageStyle = CJPayDouPayResultPageStyleShowAll;
    douModel.cashierType = CJPayCashierTypeFullPage;
    douModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceOuterDypay;
    douModel.showConfig = [response.payTypeInfo getDefaultDyPayConfig];
    douModel.isFromOuterApp = Check_ValidString(openMerchantId);
    douModel.bizParams = bizParams;
    douModel.isFrontPasswordVerify = YES;
    if ([[params cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"]) {
        // 签约并支付走v2密码页样式, 隐藏选择支付方式区域
        douModel.pwdPageStyle = CJPayDouPayPwdPageStyleV2;
        douModel.isFrontPasswordVerify = NO;
    }
    @CJWeakify(self)
    @CJWeakify(douPayController)
    [self.mutableControllers btd_addObject:douPayController];
    [douPayController douPayProcessWithModel:douModel
                                  completion:^(CJPayDouPayProcessResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        @CJStrongify(douPayController)
        if ([resultModel isReachOrderFinalState]) {
            [self p_handleDouPayResult:resultModel];
        }
        [self.mutableControllers removeObject:douPayController];
    }];
}

- (NSMutableArray *)mutableControllers {
    if (!_mutableControllers) {
        _mutableControllers = [NSMutableArray new];
    }
    return _mutableControllers;
}

- (void)p_handleDouPayResult:(CJPayDouPayProcessResultModel *)resultModel {
    // 通知api delegate
    CJPayErrorCode errorCode = CJPayErrorCodeFail;
    NSString *errorDesc;
    switch (resultModel.resultCode) {
        case CJPayDouPayResultCodeOrderSuccess:
            errorCode = CJPayErrorCodeSuccess;
            errorDesc = @"支付成功";
            break;
        case CJPayDouPayResultCodeOrderFail:
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"支付失败";
            break;
        case CJPayDouPayResultCodeOrderProcess:
            errorCode = CJPayErrorCodeProcessing;
            errorDesc = @"支付结果处理中...";
            break;
        case CJPayDouPayResultCodeOrderTimeout:
            errorCode = CJPayErrorCodeOrderTimeOut;
            errorDesc = @"支付超时";
            break;
        case CJPayDouPayResultCodeCancel:
            errorCode = CJPayErrorCodeCancel;
            errorDesc = @"用户取消支付";
            break;
        case CJPayDouPayResultCodeClose:
            errorCode = CJPayErrorCodeCancel;
            errorDesc = @"用户取消支付";
            break;
        case CJPayDouPayResultCodeUnknown:
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
            break;
        default:
            errorCode = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
            break;
    }
    CJ_CALL_BLOCK(self.completion, errorCode, errorDesc);
}

@end
