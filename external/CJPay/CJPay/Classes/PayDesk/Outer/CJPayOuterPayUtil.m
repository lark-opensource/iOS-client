//
//  CJPayOuterPayUtil.m
//  Pods
//
//  Created by wangxiaohong on 2022/7/11.
//

#import "CJPayOuterPayUtil.h"

#import "CJPayPrivacyMethodUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayUIMacro.h"
#import "CJPayPerformanceTracker.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"
#import "CJPayKVContext.h"

static CGFloat const kDypaySupportVersion = 5;

@implementation CJPayOuterPayUtil

+ (CJPayDypayResultType)dypayResultTypeWithOrderStatus:(CJPayOrderStatus)orderStatus {
    if (orderStatus == CJPayOrderStatusSuccess) {
        return CJPayDypayResultTypeSuccess;
    }
    if (orderStatus == CJPayOrderStatusFail) {
        return CJPayDypayResultTypeFailed;
    }
    if (orderStatus == CJPayOrderStatusProcess) {
        return CJPayDypayResultTypeProcessing;
    }
    if (orderStatus == CJPayOrderStatusCancel) {
        return CJPayDypayResultTypeCancel;
    }
    return CJPayDypayResultTypeUnknow;
}

+ (CJPayDypayResultType)dypayResultTypeWithErrorCode:(CJPayErrorCode)errorCode {
    CJPayDypayResultType type = CJPayDypayResultTypeUnknow;
    switch (errorCode) {
        case CJPayErrorCodeSuccess:
            type = CJPayDypayResultTypeSuccess;
            break;
        case CJPayErrorCodeFail:
            type = CJPayDypayResultTypeFailed;
            break;
        case CJPayErrorCodeProcessing:
            type = CJPayDypayResultTypeProcessing;
            break;
        case CJPayErrorCodeCancel:
            type = CJPayDypayResultTypeCancel;
            break;
        case CJPayErrorCodeOrderTimeOut:
            type = CJPayDypayResultTypeTimeout;
            break;
        default:
            break;
    }
    return type;
}

+ (void)closeCashierDeskVC:(UIViewController *)vc signType:(CJPayOuterType)signType jumpBackURL:(NSString *)jumpBackURL jumpBackResult:(CJPayDypayResultType)resultType complettion:(void (^)(BOOL isSuccess))completion {
    NSMutableDictionary *emptyDict = [NSMutableDictionary dictionaryWithDictionary:@{}];
    [CJPayKVContext kv_setValue:emptyDict forKey:CJPayOuterPayTrackData];//清空唤端支付埋点
    NSURL *backURL = nil;
    if (signType == CJPayOuterTypeAppPay) {
        backURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?resultStatus=%d", CJString(jumpBackURL), [self p_statusCodeByResult:resultType]]];
    } else {
        backURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", CJString(jumpBackURL)]];
    }
    
    if (backURL) {
        // 调用AppJump敏感方法，需走BPEA鉴权
        [CJPayPrivacyMethodUtil applicationOpenUrl:backURL
                                        withPolicy:@"bpea-caijing_homepage_cashier_jump_back"
                                   completionBlock:^(NSError * _Nullable error) {
            if (error) {
                [CJToast toastText:CJPayLocalizedStr(@"无法跳转回原App") inWindow:vc.cj_window];
                CJPayLogError(@"error in bpea-caijing_homepage_cashier_jump_back");
            }
            
            [vc.presentingViewController dismissViewControllerAnimated:YES completion:^{
                CJ_CALL_BLOCK(completion, YES);
            }];
        }];
    }
    [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneOuterPay extra:@{}];
}

//0    订单支付成功
//10   用户中途取消
//20   正在处理中
//30   版本过低
//40   失败

+ (int)p_statusCodeByResult:(CJPayDypayResultType)resultType {
    int code = -1;
    switch (resultType) {
        case CJPayDypayResultTypeSuccess:
            code = 0;
            break;
        case CJPayDypayResultTypeCancel:
            code = 10;
            break;
        case CJPayDypayResultTypeProcessing:
            code = 20;
            break;
        case CJPayDypayResultTypeLowVersion:
            code = 30;
            break;
        case CJPayDypayResultTypeFailed:
            code = 40;
            break;
        default:
            break;
    }
    
    return code;
}

+ (void)checkAuthParamsValid:(NSDictionary *)schemaParams completion:(void (^)(CJPayDypayResultType resultType, NSString *errorMsg))completion {
    if (![schemaParams isKindOfClass:NSDictionary.class] || schemaParams.count == 0) {
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeFailed , CJPayLocalizedStr(@"参数错误"));
        return;
    }
    
    NSString *bindContent = [schemaParams cj_stringValueForKey:@"bind_content"];
    if (!Check_ValidString(bindContent)) {
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeFailed, CJPayLocalizedStr(@"缺少 bind_content 参数"));
        return;
    }
    
    NSString *paySource = [schemaParams cj_stringValueForKey:@"pay_source"];
    if (!Check_ValidString(paySource)) {
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeFailed, CJPayLocalizedStr(@"缺少 pay_source 参数"));
        return;
    }
    
    NSString *dypayVersion = [schemaParams cj_stringValueForKey:@"dypay_version"];
    if (dypayVersion && [dypayVersion intValue] > kDypaySupportVersion) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                              @"result_code":@"100"}];
        [CJTracker event:@"wallet_cashier_outerpay_result" params:trackData];
        // 拉起抖音支付的 SDK 版本高于目前抖音支付支持的版本，弹框提示
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeLowVersion, CJPayLocalizedStr(@"当前抖音版本过低，请您升级抖音 App 继续完成支付"));
        return;
    }
    
    CJ_CALL_BLOCK(completion, CJPayDypayResultTypeSuccess, @"");
}

+ (void)checkPaymentParamsValid:(NSDictionary *)schemaParams completion:(void (^)(CJPayDypayResultType resultType, NSString *errorMsg))completion {
    if (![schemaParams isKindOfClass:NSDictionary.class] || schemaParams.count == 0) {
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeFailed , CJPayLocalizedStr(@"参数错误"));
        return;
    }
    
    NSString *dypayVersion = [schemaParams cj_stringValueForKey:@"dypay_version"];
    if (dypayVersion && [dypayVersion intValue] > kDypaySupportVersion) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                              @"result_code":@"100"}];
        [CJTracker event:@"wallet_cashier_outerpay_result" params:trackData];
        // 拉起抖音支付的 SDK 版本高于目前抖音支付支持的版本，弹框提示
        CJ_CALL_BLOCK(completion, CJPayDypayResultTypeLowVersion, CJPayLocalizedStr(@"当前抖音版本过低，请您升级抖音 App 继续完成支付"));
        return;
    }
    
    CJ_CALL_BLOCK(completion, CJPayDypayResultTypeSuccess, @"");
}

@end
