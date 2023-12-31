//
//  CJPaySignPayManager.m
//  Pods
//
//  Created by wangxiaohong on 2022/7/14.
//

#import "CJPaySignPayManager.h"

#import "CJPaySignPayQuerySignInfoResponse.h"
#import "CJPaySignPayViewController.h"
#import "CJPaySignOnlyViewController.h"
#import "CJPaySignOnlyQuerySignTemplateResponse.h"
#import "CJPaySignOnlyQuerySignTemplateRequest.h"
#import "CJPaySignPayQuerySignInfoRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

@interface CJPaySignPayManager()

@property (nonatomic, strong) CJPayNavigationController *navigationController;
@property (nonatomic, assign) BOOL isSignOnly; //区分是否是独立签约

@end

@implementation CJPaySignPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPaySignDYPayModule)
})

+ (instancetype)sharedInstance {
    static CJPaySignPayManager *signManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signManager = [[CJPaySignPayManager alloc] init];
    });
    return signManager;
}

- (void)p_callBackWithSignResult:(CJPayDypayResultType)type delegate:(id<CJPayAPIDelegate>)delegate {
    CJPayErrorCode returnCode = CJPayErrorCodeFail;
    NSString *errorMsg = nil;
    switch (type) {
        case CJPayDypayResultTypeCancel:
            returnCode = CJPayErrorCodeCancel;
            errorMsg = self.isSignOnly ? @"用户取消签约" : @"用户取消支付";
            break;
        case CJPayDypayResultTypeFailed:
            returnCode = CJPayErrorCodeFail;
            errorMsg = self.isSignOnly ? @"签约失败" : @"支付失败";
            break;
        case CJPayDypayResultTypeSuccess:
            returnCode = CJPayErrorCodeSuccess;
            errorMsg = self.isSignOnly ? @"签约成功" : @"支付成功";
            break;;
        case CJPayDypayResultTypeProcessing:
            returnCode = CJPayErrorCodeProcessing;
            errorMsg = self.isSignOnly ? @"签约中" : @"正在处理中，请查询商户订单列表中订单的支付状态";
            break;
        case CJPayDypayResultTypeTimeout:
            returnCode = CJPayErrorCodeOrderTimeOut;
            errorMsg = @"订单超时";
            break;
        default:
            returnCode = CJPayErrorCodeUnknown;
            errorMsg = @"未知错误";
            break;
    }
    
    CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
    apiResponse.scene = self.isSignOnly ? CJPaySceneSign : CJPayScenePay;
    apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:returnCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
    apiResponse.data = @{
        @"sdk_code": @(returnCode),
        @"sdk_msg": CJString(errorMsg)
    };
    if ([delegate respondsToSelector:@selector(onResponse:)]) {
        [delegate onResponse:apiResponse];
    }
}

- (void)p_signOnlyWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate {
    NSError *error;
    
    NSString *querySignInfoDict = [dataDict cj_stringValueForKey:@"sign_page_info"];
    CJPaySignOnlyQuerySignTemplateResponse *response = [[CJPaySignOnlyQuerySignTemplateResponse alloc] initWithString:CJString(querySignInfoDict) error:&error];
    
    if (error) {
        [self p_callBackWithSignResult:CJPayDypayResultTypeFailed delegate:delegate];
        return;
    }
    
    CJPaySignOnlyViewController *signVC = [CJPaySignOnlyViewController new];
    signVC.tradeNo = [dataDict cj_stringValueForKey:@"member_biz_order_no"];
    signVC.zg_app_id = [dataDict cj_stringValueForKey:@"zg_app_id"];
    signVC.zg_merchant_id = [dataDict cj_stringValueForKey:@"zg_merchant_id"];
    signVC.querySignInfo = response;
    signVC.immediatelyClose = [[dataDict cj_stringValueForKey:@"need_delay_close"] isEqualToString:@"0"];
    NSString *returnUrl = [dataDict cj_stringValueForKey:@"return_url"];
    if (!Check_ValidString(returnUrl)) {
        returnUrl = response.dypayReturnUrl;
    }
    signVC.returnURLStr = returnUrl;
    signVC.signType = [self p_signTypeWithSignStr:[dataDict cj_stringValueForKey:@"sign_type"]];
    if (signVC.signType != CJPayOuterTypeInnerPay) {
        [signVC useCloseBackBtn];
    }
    @CJWeakify(self)
    signVC.completion = ^(CJPayDypayResultType type, NSString * _Nonnull msg) {
        @CJStrongify(self)
        [self p_dismissSelfWithDYPayResultType:type delegate:delegate];
    };
    
    if (dataDict.cjpay_referViewController && [dataDict.cjpay_referViewController.navigationController isKindOfClass:CJPayNavigationController.class]) {
        self.navigationController = (CJPayNavigationController *)dataDict.cjpay_referViewController.navigationController;
        @CJWeakify(self)
        [self.navigationController pushViewControllerSingleTop:signVC animated:YES completion:^{
            @CJStrongify(self)
            [self p_callSuccessWithDelegate:delegate];
        }];
    } else {
        @CJWeakify(self);
        self.navigationController = [signVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:NO completion:^{
            @CJStrongify(self)
            [self p_callSuccessWithDelegate:delegate];
        }];
    }
}

- (CJPayOuterType)p_signTypeWithSignStr:(NSString *)str {
    if ([str isEqualToString:@"inner"]) {
        return CJPayOuterTypeInnerPay;
    }
    if ([str isEqualToString:@"outer_app"]) {
        return CJPayOuterTypeAppPay;
    }
    return CJPayOuterTypeWebPay;
}

- (void)p_signDYPayActionWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate {
    NSError *error;
    CJPayOuterType signType = [self p_signTypeWithSignStr:[dataDict cj_stringValueForKey:@"sign_type"]];
    CJPaySignPayQuerySignInfoResponse *response = nil;
    if (signType == CJPayOuterTypeInnerPay) {
        NSDictionary *querySignInfoDict = [dataDict cj_dictionaryValueForKey:@"sign_page_info"];
        if (querySignInfoDict.count < 1) {
            querySignInfoDict = [[dataDict cj_stringValueForKey:@"sign_page_info_str"] cj_toDic];
        }
        response = [[CJPaySignPayQuerySignInfoResponse alloc] initWithDictionary:@{@"data": querySignInfoDict ?: @{}} error:&error];
    } else {
        NSDictionary *querySignInfoDict = [[dataDict cj_stringValueForKey:@"sign_page_info"] cj_toDic];
        if (querySignInfoDict.count < 1) {
            querySignInfoDict = [[dataDict cj_stringValueForKey:@"sign_page_info_str"] cj_toDic];
        }
        response = [[CJPaySignPayQuerySignInfoResponse alloc] initWithDictionary:querySignInfoDict ?: @{} error:&error];
    }
    
    if (error) {
        [self p_callBackWithSignResult:CJPayDypayResultTypeFailed delegate:delegate];
    }
    
    CJPaySignPayViewController *signVC = [CJPaySignPayViewController new];
    signVC.token = [dataDict cj_stringValueForKey:@"token"];
    signVC.appId = [dataDict cj_stringValueForKey:@"app_id"];
    signVC.querySignInfo = response;
    signVC.immediatelyClose = [[dataDict cj_stringValueForKey:@"need_delay_close"] isEqualToString:@"0"];
    NSString *returnUrl = [dataDict cj_stringValueForKey:@"return_url"];
    if (!Check_ValidString(returnUrl)) {
        returnUrl = response.dypayReturnUrl;
    }
    signVC.returnURLStr = returnUrl;
    signVC.signType = signType;
    if (signVC.signType != CJPayOuterTypeInnerPay) {
        [signVC useCloseBackBtn];
    }
    @CJWeakify(self)
    signVC.completion = ^(CJPayDypayResultType type, NSString * _Nonnull msg) {
        @CJStrongify(self)
        [self p_dismissSelfWithDYPayResultType:type delegate:delegate];
    };
    
    if (dataDict.cjpay_referViewController && [dataDict.cjpay_referViewController.navigationController isKindOfClass:CJPayNavigationController.class]) {
        self.navigationController = (CJPayNavigationController *)dataDict.cjpay_referViewController.navigationController;
        @CJWeakify(self);
        [self.navigationController pushViewControllerSingleTop:signVC animated:YES completion:^{
            @CJStrongify(self);
            [self p_callSuccessWithDelegate:delegate];
        }];
    } else {
        self.navigationController = [signVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:NO completion:^{
            @CJStrongify(self);
            [self p_callSuccessWithDelegate:delegate];
        }];
    }
}

- (void)p_callSuccessWithDelegate:(id<CJPayAPIDelegate>)delegate{
    if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
        [delegate callState:YES fromScene:CJPaySceneSign];
    }
}

- (void)p_dismissSelfWithDYPayResultType:(CJPayDypayResultType)type delegate:(id<CJPayAPIDelegate>)delegate {
    [self p_callBackWithSignResult:type delegate:delegate];
}

- (void)i_signAndPayWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate {
    [self p_signDYPayActionWithDataDict:dataDict delegate:delegate];
}

- (void)i_signOnlyWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate {
    [self p_signOnlyWithDataDict:dataDict delegate:delegate];
}

- (void)i_requestSignAndPayInfoWithBizParams:(NSDictionary *)bizParams completion:(nonnull void (^)(BOOL, JSONModel * _Nonnull, NSDictionary * _Nonnull))completionBlock {
    [CJPaySignPayQuerySignInfoRequest startWithBizParams:bizParams completion:^(NSError * _Nonnull error, CJPaySignPayQuerySignInfoResponse * _Nonnull response) {
        NSString *errorText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
        NSDictionary *extraParmas = @{
            @"return_url" : CJString(response.dypayReturnUrl),
            @"error_msg" : CJString(errorText)
        };
        CJ_CALL_BLOCK(completionBlock,[response isSuccess], response, extraParmas);
    }];
}

- (void)i_requestSignOnlyInfoWithBizParams:(NSDictionary *)bizParams completion:(nonnull void (^)(BOOL, JSONModel * _Nonnull, NSDictionary * _Nonnull))completionBlock {
    [CJPaySignOnlyQuerySignTemplateRequest startWithBizParams:bizParams completion:^(NSError * _Nonnull error, CJPaySignOnlyQuerySignTemplateResponse * _Nonnull response) {
        NSString *errorText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
        NSDictionary *extraParmas = @{
            @"return_url" : CJString(response.dypayReturnUrl),
            @"error_msg" : CJString(errorText)
        };
        CJ_CALL_BLOCK(completionBlock, [response isSuccess], response, extraParmas);
    }];
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    self.isSignOnly = [[dictionary cj_stringValueForKey:@"pay_source"] isEqualToString:@"sign_only"];
    if (self.isSignOnly) {
        [self p_innerSignOnlyWithDict:dictionary withDelegate:delegate];
        return YES;
    }
    [self i_signAndPayWithDataDict:dictionary delegate:delegate];
    return YES;
}

- (void)p_innerSignOnlyWithDict:(NSDictionary *)paramsDict withDelegate:(id<CJPayAPIDelegate>)delegate {
    if (![paramsDict isKindOfClass:NSDictionary.class] || paramsDict.count == 0) {
        [self p_callBackWithSignResult:CJPayDypayResultTypeFailed delegate:delegate];
        return;
    }
    NSDictionary *responseDict = @{@"response": paramsDict};
    NSDictionary *params = @{
        @"sign_page_info": CJString([responseDict cj_toStr]),
        @"zg_app_id": CJString([paramsDict cj_stringValueForKey:@"zg_app_id"]),
        @"zg_merchant_id": CJString([paramsDict cj_stringValueForKey:@"zg_merchant_id"]),
        @"sign_type":  @"inner",
        @"member_biz_order_no": CJString([paramsDict cj_stringValueForKey:@"member_biz_order_no"]),
        @"need_delay_close" : CJString([paramsDict cj_stringValueForKey:@"need_delay_close"]),
    };
    [self p_signOnlyWithDataDict:params delegate:delegate];
}

@end
