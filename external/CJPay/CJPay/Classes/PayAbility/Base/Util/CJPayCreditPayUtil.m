//
//  CJPayCreditPayUtil.m
//  Pods
//
//  Created by 易培淮 on 2022/5/12.
//

#import "CJPayCreditPayUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayAPI.h"
#import "CJPayInfo.h"
#import "CJPayKVContext.h"
#import "CJPayDeskUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPayUIMacro.h"
#import "CJPayAlertUtil.h"

@implementation CJPayCreditPayUtil

+ (void)activateCreditPayWithPayInfo:(CJPayInfo *)payInfo completion:(void(^)(CJPayCreditPayServiceResultType type, NSString *msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString *token))completion {
    [self activateCreditPayWithStatus:payInfo.isCreditActivate
                          activateUrl:payInfo.creditActivateUrl
                           completion:completion];
}

+ (void)doCreditTargetActionWithPayInfo:(CJPayInfo *)payInfo completion:(nonnull void (^)(CJPayCreditPayServiceResultType type, NSString * _Nonnull result, NSString *payToken))completion {
    if (!payInfo.isNeedJumpTargetUrl || !Check_ValidString(payInfo.targetUrl)) {
        CJPayLogAssert(NO, @"不需要跳转或者传入的跳转URL为空");
        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNoUrl, @"不需要跳转或者传入的跳转URL为空", @"");
        return;
    }
    void(^callbackBlock)(CJPayAPIBaseResponse * _Nonnull) = ^(CJPayAPIBaseResponse * _Nonnull response) {
        NSDictionary *outDataDic = [response.data cj_dictionaryValueForKey:@"data"];
        NSDictionary *dataDic = [outDataDic cj_dictionaryValueForKey:@"msg"];
        NSString *service = [dataDic cj_stringValueForKey:@"service"];
        if ([service isEqualToString:@"credit_pay_notify_common"]) {
            NSInteger code = [dataDic cj_integerValueForKey:@"code"];
            NSString *token = [dataDic cj_stringValueForKey:@"pay_token"];
            if (code == 0) {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeSuccess, @"操作成功", token);
            } else if (code == -1) {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeFail, @"操作失败", @"");
            } else {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeFail, [NSString stringWithFormat:@"回调错误码异常code = %ld", (long)code], @"");
            }
        } else {
            CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeFail, [NSString stringWithFormat:@"service = %@传入不正确", service], @"");
        }
    };
    [self p_openCreditScheme:payInfo.targetUrl callback:callbackBlock];
}

+ (void)activateCreditPayWithStatus:(BOOL)activateStatus
                        activateUrl:(NSString *)activateUrl
                         completion:(void (^)(CJPayCreditPayServiceResultType, NSString * _Nonnull, NSInteger, CJPayCreditPayActivationLoadingStyle, NSString * _Nonnull))completion {
  
    if (activateStatus) {
        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeActivated, @"", -1, 0, @"");
        return;
    } else {
        NSString *schema = activateUrl;
        if (!Check_ValidString(schema)) {
            CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNoUrl, CJPayLocalizedStr(@"无法进入抖音月付激活流程，请您联系客服"), -1, 0, @"");
            CJPayLogAssert(NO, @"没有下发开通抖音月付的 URL，请检查接口数据");
            return;
        }
        void(^callbackBlock)(CJPayAPIBaseResponse * _Nonnull) = ^(CJPayAPIBaseResponse * _Nonnull response) {
            if (!response.data && response.error) {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNoNetwork, CJPayLocalizedStr(CJPayNoNetworkMessage), -1, 0, @"");
                return;
            }
            if (response.data != nil && [response.data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dic;
                if ([response.data btd_dictionaryValueForKey:@"data"]) {
                    dic = [[response.data btd_dictionaryValueForKey:@"data"] btd_dictionaryValueForKey:@"msg"];
                } else {
                    dic = (NSDictionary *)response.data;
                }
                NSString *service = [dic cj_stringValueForKey:@"service"];
                // 是否支持额度判断
                BOOL creditAmountComparison = [dic.allKeys containsObject:@"amount"];
                NSInteger amount = [dic cj_integerValueForKey:@"amount"];
                
                NSString *successDesc = [dic cj_stringValueForKey:@"success_desc" defaultValue:CJPayLocalizedStr(@"抖音月付激活成功")];
                NSString *failureDesc = [dic cj_stringValueForKey:@"fail_desc" defaultValue:CJPayLocalizedStr(@"抖音月付激活失败，请选择其他支付方式")];
                NSInteger code = [dic cj_integerValueForKey:@"code"];
                NSString *payToken = [dic cj_stringValueForKey:@"pay_token"];
                NSString *stylestr = [dic cj_stringValueForKey:@"style"];
                NSString *alreadyActive = [dic cj_stringValueForKey:@"already_active"];
                if ([alreadyActive isEqualToString:@"1"]) {
                    successDesc = @"";//聚合收银台不再展示月付激活成功toast
                }
                CJPayCreditPayActivationLoadingStyle style = CJPayCreditPayActivationLoadingStyleOld;
                if ([stylestr isEqualToString:@"1"]) {
                    style = CJPayCreditPayActivationLoadingStyleNew;
                }
                
                if ([service isEqualToString:@"credit_pay_notify"]) {
                    if (code == 0) { //激活成功
                        if (creditAmountComparison) {
                            CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeSuccess, CJPayLocalizedStr(successDesc), amount, style, payToken);
                        } else {
                            CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeSuccess, CJPayLocalizedStr(successDesc), -1, style, payToken);
                        }
                    } else if (code == -1) {
                        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeFail, CJPayLocalizedStr(failureDesc), -1, style, @"");
                    } else if (code == -2) {
                        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeCancel, CJPayLocalizedStr(@"取消激活"), -1, style, @"");
                    } else if (code == -3) { // 激活超时
                        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeTimeOut, CJPayLocalizedStr(failureDesc), -1, style, @"");
                    } else {
                        [CJMonitor trackService:@"wallet_rd_creditActivate_result" extra:@{@"data" : dic ?: @{}}];
                        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeTimeOut, CJPayLocalizedStr(failureDesc), -1,style, @"");
                    }
                } else {
                    // 不处理，不回调，依赖前端回调
                }
            } else {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeCancel, CJPayLocalizedStr(@"取消激活"), -1, 0, @"");
            }
        };
        [self p_openCreditScheme:schema callback:callbackBlock];
    }
}

+ (void)p_openCreditScheme:(NSString *)scheme callback:(void(^)(CJPayAPIBaseResponse * _Nonnull response)) callback {
    NSURL *url = [NSURL btd_URLWithString:scheme];
    NSString *pageType = [url.btd_queryItems btd_stringValueForKey:@"cj_page_type"];
    if ([pageType isEqualToString:@"lynx"]) { //打开lynx
        [CJPayDeskUtil openLynxPageBySchema:scheme
                           completionBlock:callback];
    } else if ([pageType isEqualToString:@"h5"]){// 分为h5/lynx两种
        [CJPayAPI openScheme:scheme callBack:callback];
    } else {// 兜底
        [CJPayAPI openScheme:scheme callBack:callback];
    }
}

+ (void)creditPayActiveWithPayInfo:(CJPayInfo *)payInfo completion:(void (^)(CJPayCreditPayServiceResultType, NSString * _Nonnull msg, NSString * _Nonnull token))completion {
    //月付解锁流程
    if (payInfo.isNeedJumpTargetUrl) {
        [self doCreditTargetActionWithPayInfo:payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSString * _Nonnull payToken) {
            CJPayLogInfo(@"月付解锁流程: result:%d, msg:%@, payToken:%@", type, CJString(msg), CJString(payToken));
            CJ_CALL_BLOCK(completion, type, msg, payToken);
        }];
        return;
    }
    // 月付激活流程
    [self activateCreditPayWithPayInfo:payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString * _Nonnull token) {
        CJPayLogInfo(@"月付激活结果：result:%d, msg:%@, creditLimit:%d, style:%d, token:%@", type, CJString(msg), creditLimit, style, CJString(token));
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
            case CJPayCreditPayServiceResultTypeCancel:
                CJ_CALL_BLOCK(completion, type, msg, token);
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail: {
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活失败")];
                }
                CJ_CALL_BLOCK(completion, type, msg, token);
                break;
            }
            case CJPayCreditPayServiceResultTypeTimeOut: {
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活超时")];
                }
                CJ_CALL_BLOCK(completion, type, msg, token);
                break;
            }
            case CJPayCreditPayServiceResultTypeSuccess: {
                if (creditLimit == -1 || creditLimit > payInfo.realTradeAmountRaw) { //不限额 | 额度充足
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (style == CJPayCreditPayActivationLoadingStyleOld) {
                            [CJToast toastText:msg inWindow:[UIViewController cj_topViewController].cj_window];
                        }
                    });
                    CJ_CALL_BLOCK(completion, type, msg, token);
                    return;
                }
                // 额度不足
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"额度不足")];
                    CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNotEnoughQuota, CJPayLocalizedStr(@"抖音月付激活成功，额度不足"), token);
                } else {
                    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"抖音月付额度不足，请选择其他支付方式") content:nil buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
                        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNotEnoughQuota, CJPayLocalizedStr(@"抖音月付激活成功，额度不足，请更换支付方式"), token);
                    } useVC:[UIViewController cj_topViewController]];
                }
                break;
            }
            default:
                CJ_CALL_BLOCK(completion, type, msg, token);
                break;
        }
    }];
}

@end
