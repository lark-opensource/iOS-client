//
//  CJPayFastPayManager.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/4.
//

#import "CJPayFastPayManager.h"

#import "CJPayCashierModule.h"
#import "CJPaySDKMacro.h"
#import "CJPayFastPayHomePageViewController.h"
#import "CJPayUIMacro.h"

@interface CJPayFastPayManager()<CJPayFastPayService>

@property (nonatomic, copy) NSString *host;
@property (nonatomic, strong) CJPayNameModel *nameModel;
@property (nonatomic, strong) id<CJPayAPIDelegate> apiDelegate; // 这里是单例，delelgate可以不释放，另外如果使用CJPayAPICallback方式，使用weak会导致被提前释放，故改成strong。
@property (nonatomic, strong, nullable) CJPayHalfPageBaseViewController *deskVC;  // 强持有是为了支付完成的回调能够正确的被处理。

@end

@implementation CJPayFastPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayFastPayService)
})

+ (instancetype)defaultService {
    static CJPayFastPayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayFastPayManager alloc] init];
    });
    return manager;
}

- (void)i_openFastPayDeskWithConfig:(NSDictionary *)configDic params:(NSDictionary *)bizParams delegate:(id<CJPayAPIDelegate>)delegate {
    self.apiDelegate = delegate;
    CJPayLogInfo(@"[CJPayManager i_openFastPayDeskWithConfig:%@]", [CJPayCommonUtil dictionaryToJson:bizParams])
    
    @CJWeakify(self)
    CJPayFastPayHomePageViewController *createVC =  [[CJPayFastPayHomePageViewController alloc] initWithBizParams:bizParams bizurl:@"" delegate:delegate completionBlock:^(CJPayOrderResultResponse *_Nullable resResponse, CJPayOrderStatus orderStatus) {
        @CJStrongify(self)
        [self handleCJPayManagerResult:resResponse orderStatus:orderStatus extraDict:@{}];
    }];
    self.deskVC = createVC;
    [createVC presentWithNavigationControllerFrom:bizParams.cjpay_referViewController useMask:YES completion:nil];
   
    [CJTracker event:@"wallet_cashier_fastpay_pull" params:@{@"app_id": [bizParams cj_stringValueForKey:@"app_id"],
                                                             @"merchant_id": [bizParams cj_stringValueForKey:@"merchant_id"],
                                                             @"amount": [bizParams cj_stringValueForKey:@"total_amount"],
                                                             @"is_chaselight" : @"1",
    }];
}

- (void)handleCJPayManagerResult:(CJPayOrderResultResponse *)response orderStatus:(CJPayOrderStatus) orderStatus extraDict:(NSDictionary *)extraDict {
    self.deskVC = nil;
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
    
    [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneStandardPayDeskKey extra:@{}];
}

- (BOOL)wakeByUniversalPayDesk:(nonnull NSDictionary *)dictionary withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    [self i_openFastPayDeskWithConfig:@{} params:dictionary delegate:delegate];
    return YES;
}

@end
