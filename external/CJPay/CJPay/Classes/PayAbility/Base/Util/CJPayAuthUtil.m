//
//  CJPayAuthUtil.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/10.
//

#import "CJPayAuthUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayUserInfo.h"
#import "CJPayAlertUtil.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayUIMacro.h"

@implementation CJPayAuthUtil

+ (void)authWithUserInfo:(CJPayUserInfo *)userInfo
                  fromVC:(UIViewController *)fromVC
           trackDelegate:(id<CJPayTrackerProtocol>)trackDelegate
              completion:(void (^)(CJPayAuthResultType resultType, NSString * _Nonnull msg, NSString * _Nonnull token, BOOL isBindCardSuccess))completion {
    if (!userInfo) {
        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeFail, @"无法获取开户状态", nil, NO);
        return;
    }
    
    if ([userInfo.authStatus isEqualToString:@"1"]) {
        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeAuthed, @"用户已开户", nil, NO);
        return;
    }
    
    // 未实名展示弹窗
    @CJWeakify(self)
    NSString *leftDesc = CJPayLocalizedStr(@"取消");
    NSString *rightDesc = CJPayLocalizedStr(@"去认证");
    UIViewController *vc = fromVC ?: [UIViewController cj_topViewController];
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"根据监管要求，使用钱包收入支付前需先完成抖音零钱开户认证") content:nil leftButtonDesc:leftDesc rightButtonDesc:rightDesc leftActionBlock:^{
        if ([trackDelegate respondsToSelector:@selector(event:params:)]) {
            [trackDelegate event:@"wallet_cashier_identified_pop_click" params:@{
                @"button_name": leftDesc
            }];
        }
        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeCancel, @"实名开户取消", nil, NO);
    } rightActioBlock:^{
        @CJStrongify(self)
        if ([trackDelegate respondsToSelector:@selector(event:params:)]) {
            [trackDelegate event:@"wallet_cashier_identified_pop_click" params:@{
                @"button_name": rightDesc
            }];
        }
        [self p_gotoAuthWithUserInfo:userInfo completion:completion];
    } useVC:vc];
    
    if ([trackDelegate respondsToSelector:@selector(event:params:)]) {
        [trackDelegate event:@"wallet_cashier_identified_pop_imp" params:@{}];
    }
}

+ (void)p_gotoAuthWithUserInfo:(CJPayUserInfo *)userInfo completion:(void (^)(CJPayAuthResultType resultType, NSString * _Nonnull msg, NSString * _Nonnull token, BOOL isBindCardSuccess))completion {
    NSString *schema = userInfo.lynxAuthUrl;
    @CJWeakify(self)
    if (!Check_ValidString(schema)) {
        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeFail, @"Lynx开户schema为空", nil, NO);
        return;
    }
    // Lynx开户流程
    NSMutableDictionary *param = [NSMutableDictionary new];
    NSMutableDictionary *sdkInfo = [NSMutableDictionary new];
    [sdkInfo cj_setObject:schema forKey:@"schema"];
    [param cj_setObject:@(98) forKey:@"service"];
    [param cj_setObject:sdkInfo forKey:@"sdk_info"];
    
    CJ_DECLARE_ID_PROTOCOL(CJPayUniversalPayDeskService);
    if (objectWithCJPayUniversalPayDeskService) {
        [objectWithCJPayUniversalPayDeskService i_openUniversalPayDeskWithParams:param
                                                                    withDelegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
            @CJStrongify(self)
            // Lynx实名开户回调
            [self p_authCallBackWithResponse:response completion:completion];
        }]];
    } else {
        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeFail, @"Lynx实名开户拉起失败", nil, NO);
    }
}

+ (void)p_authCallBackWithResponse:(CJPayAPIBaseResponse *)response completion:(void (^)(CJPayAuthResultType resultType, NSString * _Nonnull msg, NSString * _Nonnull token, BOOL isBindCardSuccess))completion {
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = [response.data cj_dictionaryValueForKey:@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *msg = [data cj_dictionaryValueForKey:@"msg"];
            if (msg && [msg isKindOfClass:[NSDictionary class]]) {
                NSInteger code = [msg cj_integerValueForKey:@"code"];
                NSString *token = [msg cj_stringValueForKey:@"token"];
                if (code == 1) {
                    // 开户成功
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        CJ_CALL_BLOCK(completion, CJPayAuthResultTypeSuccess, @"开户成功", CJString(token), NO);
                    });
                } else {
                    // 开户取消
                    BOOL isBindCardSuccess = [msg cj_dictionaryValueForKey:@"card_info"].count > 0;
                    CJ_CALL_BLOCK(completion, CJPayAuthResultTypeCancel, @"实名开户取消", nil, isBindCardSuccess);
                }
                return;
            }
        }
    }
    CJ_CALL_BLOCK(completion, CJPayAuthResultTypeFail, @"未知错误", nil, NO);
}

@end
