//
//  CJPayWithdrawServiceImp.m
//  CJPay
//
//  Created by wangxinhua on 2020/7/12.
//

#import "CJPayWithdrawServiceImp.h"
#import "CJPayWebViewUtil.h"
#import "CJPaySDKDefine.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPayProtocolManager.h"
#import "CJPayWithdrawService.h"
#import "CJPayNativeWithdrawService.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJPayWithdrawServiceImp()<CJPayWithdrawService>

@property (nonatomic, strong) id<CJPayAPIDelegate> delegate;

@end

@implementation CJPayWithdrawServiceImp

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayWithdrawService)
})

+ (instancetype)sharedInstance {
    static CJPayWithdrawServiceImp *imp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imp = [CJPayWithdrawServiceImp new];
    });
    return imp;
}

- (void)i_openH5WithdrawDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    
    self.delegate = delegate;
    
    NSString *withdrawUrl = [NSString stringWithFormat:@"%@/cashdesk_withdraw",[CJPayBaseRequest deskServerHostString]];
    
    if (!Check_ValidString(withdrawUrl)) {
        [self.delegate callState:NO fromScene:CJPaySceneWithdraw];
        return;
    }
    
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
        
    NSDictionary *urlParams = @{
        @"app_id": CJString([params cj_stringValueForKey:@"app_id"]),
        @"merchant_id": CJString([params cj_stringValueForKey:@"merchant_id"]),
        @"risk_info": CJString([[riskDict cj_toStr] cj_base64EncodeString]),
        @"payment_type": @"balancewithdraw",
        @"product_code": @"withdraw",
        @"is_downgrade": [params cj_stringValueForKey:@"is_downgrade"] ?: @"false"
    };
    
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController] toUrl:withdrawUrl params:urlParams closeCallBack:^(id  _Nonnull data) {
        [self handleCJWithdrawWebCallBack:data];
    }];
}

- (void)i_openWithdrawDeskWithUrl:(NSString *)withdrawUrl delegate:(id<CJPayAPIDelegate>)delegate {
    
    self.delegate = delegate;
    CJ_DECLARE_ID_PROTOCOL(CJPayNativeWithdrawService);
    BOOL nativeWithdrawIsInstalled = objectWithCJPayNativeWithdrawService != nil;
    void(^nativeWithdraw)(void) = ^{
        [objectWithCJPayNativeWithdrawService i_nativeOpenWithdrawDeskWithUrl:withdrawUrl delegate:delegate];
    };
    @CJWeakify(self)
    void(^h5Withdraw)(void) = ^{
        @CJStrongify(self)
        self.delegate = delegate;
        if (!Check_ValidString(withdrawUrl)) {
            [self.delegate callState:NO fromScene:CJPaySceneWithdraw];
            return;
        }
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:withdrawUrl.cjpay_referViewController] toUrl:withdrawUrl params:@{} closeCallBack:^(id  _Nonnull data) {
            [self handleCJWithdrawWebCallBack:data];
        }];
    };
    // 为英文时，降级为H5，因为当前版本提现不支持多语言
    if ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn || !nativeWithdrawIsInstalled) {
        CJ_CALL_BLOCK(h5Withdraw);
        return;
    } else {
        CJ_CALL_BLOCK(nativeWithdraw);
    }
}

- (void)handleCJWithdrawWebCallBack:(id)json {
    
    NSDictionary *dic = (NSDictionary *)json;
    if (dic && [dic isKindOfClass:NSDictionary.class]) {
        NSString *service = [dic cj_stringValueForKey:@"service"];
        if ([service isEqualToString:@"60"]) {
            [self p_processWebCallback:dic];
            return;
        } else if ([service isEqualToString:@"web"]) {
            if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"cancel"]) {
                if ([self.delegate respondsToSelector:@selector(onResponse:)]) {
                    CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
                    baseResponse.scene = CJPaySceneWithdraw;
                    baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeCancel userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"用户取消提现", nil)}];
                    baseResponse.data = [dic copy];
                    [self.delegate onResponse:baseResponse];
                }
                return;
            }
        }
    }
}

- (void)p_processWebCallback:(NSDictionary *)dic {
    CJPayErrorCode errorCode;
    NSString *errorDesc;
    NSString *code = [dic cj_stringValueForKey:@"code"];
    NSDictionary *result = [dic cj_dictionaryValueForKey:@"data"];
    if ([code isEqualToString:@"0"]) {
        CJPayOrderStatus status = CJPayOrderStatusFromString([result cj_stringValueForKey:@"status"]);
        switch (status) {
            case CJPayOrderStatusProcess:
                errorCode = CJPayErrorCodeProcessing;
                errorDesc = @"提现处理中";
                break;
            case CJPayOrderStatusFail:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"提现失败";
                break;
            case CJPayOrderStatusTimeout:
                errorCode = CJPayErrorCodeOrderTimeOut;
                errorDesc = @"提现处理超时";
                break;
            case CJPayOrderStatusSuccess:
                errorCode = CJPayErrorCodeSuccess;
                errorDesc = @"提现成功";
                break;
            default:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"提现失败";
                break;
        }
    } else {
        errorCode = CJPayErrorCodeFail;
        errorDesc = @"提现失败";
    }
    if ([self.delegate respondsToSelector:@selector(onResponse:)]) {
        CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
        baseResponse.scene = CJPaySceneWithdraw;
        baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        baseResponse.data = [dic copy];
        [self.delegate onResponse:baseResponse];
    }
}

@end
