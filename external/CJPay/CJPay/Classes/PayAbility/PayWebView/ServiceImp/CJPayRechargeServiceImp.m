//
//  CJPayRechargeServiceImp.m
//  Pods
//
//  Created by wangxiaohong on 2020/12/5.
//

#import "CJPayRechargeServiceImp.h"

#import "CJPayWebViewUtil.h"
#import "CJPaySDKDefine.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPayRechargeService.h"
#import "CJPaySDKDefine.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJPayRechargeServiceImp()<CJPayRechargeService>

@property (nonatomic, strong) id<CJPayAPIDelegate> delegate;

@end

@implementation CJPayRechargeServiceImp

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayRechargeService)
})

+ (instancetype)sharedInstance {
    static CJPayRechargeServiceImp *imp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imp = [CJPayRechargeServiceImp new];
    });
    return imp;
}

- (void)i_openH5RechargeDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    self.delegate = delegate;
    
    NSString *rechargeUrl = [NSString stringWithFormat:@"%@/cashdesk/balance_recharge",[CJPayBaseRequest deskServerHostString]];
    
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    
    NSDictionary *urlParams = @{
        @"app_id": CJString([params cj_stringValueForKey:@"app_id"]),
        @"merchant_id": CJString([params cj_stringValueForKey:@"merchant_id"]),
        @"tag": @"cash_recharge",
        @"risk_info": CJString([[riskDict cj_toStr] cj_base64EncodeString]),
        @"is_downgrade" : [params cj_stringValueForKey:@"is_downgrade"] ?: @"false"
    };
    
    if (!Check_ValidString(rechargeUrl)) {
        [self.delegate callState:NO fromScene:CJPaySceneWithdraw];
        return;
    }
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController] toUrl:rechargeUrl params:urlParams closeCallBack:^(id  _Nonnull data) {
        [self p_handleCJRechargeWebCallBack:data];
    }];
}

- (void)p_handleCJRechargeWebCallBack:(id)json {
    
    NSDictionary *dic = (NSDictionary *)json;
    if (dic && [dic isKindOfClass:NSDictionary.class]) {
        NSString *service = [dic cj_stringValueForKey:@"service"];
        if ([service isEqualToString:@"60"]) { //TODO: 需要与前端确定充值的回调错误码
            [self p_processWebCallback:dic];
            return;
        } else if ([service isEqualToString:@"web"]) {
            if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"cancel"]) {
                if ([self.delegate respondsToSelector:@selector(onResponse:)]) {
                    CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
                    baseResponse.scene = CJPaySceneWithdraw;
                    baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeCancel userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"用户取消充值", nil)}];
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
                errorDesc = @"充值处理中";
                break;
            case CJPayOrderStatusFail:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"充值失败";
                break;
            case CJPayOrderStatusTimeout:
                errorCode = CJPayErrorCodeOrderTimeOut;
                errorDesc = @"充值处理超时";
                break;
            case CJPayOrderStatusSuccess:
                errorCode = CJPayErrorCodeSuccess;
                errorDesc = @"充值成功";
                break;
            default:
                errorCode = CJPayErrorCodeFail;
                errorDesc = @"充值失败";
                break;
        }
    } else {
        errorCode = CJPayErrorCodeFail;
        errorDesc = @"充值失败";
    }
    if ([self.delegate respondsToSelector:@selector(onResponse:)]) {
        CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
        baseResponse.scene = CJPaySceneBalanceRecharge;
        baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
        baseResponse.data = [dic copy];
        [self.delegate onResponse:baseResponse];
    }
}

@end
