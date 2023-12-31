//
//  CJPayVerifyItem.m
//  CJPay
//
//  Created by 王新华 on 7/18/19.
//

#import "CJPayVerifyItem.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayBaseVerifyManagerQueen.h"
#import "CJPaySDKMacro.h"
#import "CJPayRetainUtil.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPaySettingsManager.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPayRequestParam.h"
#import "CJPaySaasSceneUtil.h"

CJPayVerifyEventKey const CJPayVerifyEventRecommandVerifyKey = @"CJPayVerifyEventRecommandVerifyKey";
CJPayVerifyEventKey const CJPayVerifyEventSwitchToPassword = @"CJPayVerifyEventSwitchToPassword"; 
CJPayVerifyEventKey const CJPayVerifyEventSwitchToBio = @"CJPayVerifyEventSwitchToBio";

@implementation CJPayEvent

- (instancetype)initWithName:(CJPayVerifyEventKey)name data:(nullable id)data {
    self = [super init];
    if (self) {
        self.name = name;
        self.data = data;
    }
    return self;
}

@end

@implementation CJPayVerifyItem

- (void)bindManager:(CJPayBaseVerifyManager *)manager {
    self.manager = manager;
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    
}

- (NSDictionary *)getLatestCacheData {
    return @{};
}

- (void)receiveEvent:(id)event {
    
}

- (NSString *)checkTypeName {
    return @"无";
}

- (NSString *)checkType {
    return @"";
}

- (NSString *)handleSourceType {
    NSString *lastVerifyCheckName = [self.manager lastVerifyCheckTypeName];
    NSString *lastVerifySource = [NSString stringWithFormat:@"%@-%@", lastVerifyCheckName, @"加验"];
    return lastVerifySource;
}

- (void)notifyWakeVerifyItemFail {
    [self.manager sendEventTOVC:CJPayHomeVCEventWakeItemFail obj:@(self.verifyType)];
}

- (void)notifyVerifyCancel {
    [self.manager sendEventTOVC:CJPayHomeVCEventCancelVerify obj:@(self.verifyType)];
}

- (CJPayRetainUtilModel *)buildRetainUtilModel {
    CJPayRetainUtilModel *model = [CJPayRetainUtilModel new];
    model.intergratedTradeNo = self.manager.response.intergratedTradeIdentify;
    model.intergratedMerchantID = self.manager.response.merchant.intergratedMerchantId;
    model.processInfoDic = [self.manager.response.processInfo dictionaryValue];
    model.trackDelegate = self;
    model.retainInfo = self.manager.response.payInfo.retainInfo;
    model.retainInfoV2Config = [self p_buildRetainInfoV2Config];
    model.notSumbitServerEvent = self.manager.isPaymentForOuterApp;
    model.isOnlyShowNormalRetainStyle = self.manager.hasChangeSelectConfigInVerify; //若在验证过程中更改过支付方式，则仅展示无营销挽留弹窗
    
    NSInteger voucherType = [self.manager.response.payInfo.voucherType integerValue];
    model.isHasVoucher = voucherType != 0 && voucherType != 10;
    
    return model;
}

- (CJPayRetainInfoV2Config *)p_buildRetainInfoV2Config {
    CJPayRetainInfoV2Config *retainV2Config = [[CJPayRetainInfoV2Config alloc] init];
    retainV2Config.appId = self.manager.response.merchant.jhAppId;
    retainV2Config.zgAppId = self.manager.response.merchant.appId;
    retainV2Config.merchantId = self.manager.response.merchant.merchantId;
    retainV2Config.jhMerchantId = self.manager.response.merchant.intergratedMerchantId;
    retainV2Config.traceId = [self.manager.trackInfo cj_stringValueForKey:@"trace_id"];
    retainV2Config.retainInfoV2 = self.manager.response.payInfo.retainInfoV2;
    retainV2Config.hostDomain = [CJPayBaseRequest jhHostString];
    NSString *finalRetainSchema = [CJPayRetainUtil defaultLynxRetainSchema];
    
    NSString *settingsRetainSchema = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig.keepDialogStandardNew.scheme;
    NSDictionary *merchantRetainInfo = [self.manager.response.retainInfoV2 cj_dictionaryValueForKey:@"merchant_retain_info"];
    NSString *merchantRetainSchema = [merchantRetainInfo cj_stringValueForKey:@"lynx_schema"];
    if (Check_ValidString(merchantRetainSchema)) {
        finalRetainSchema = merchantRetainSchema;
    } else if (Check_ValidString(settingsRetainSchema)) {
        finalRetainSchema = settingsRetainSchema;
    }
    
    if ([CJPayRequestParam isSaasEnv] && ![finalRetainSchema containsString:CJPaySaasKey]) {
        // 处于SaaS环境时，打开Lynx挽留的schema需拼上is_caijing_saas参数
        finalRetainSchema = [CJPayCommonUtil appendParamsToUrl:finalRetainSchema params:@{CJPaySaasKey : @"1"}];
    }
    retainV2Config.retainSchema = finalRetainSchema;
    retainV2Config.processInfo = [self.manager.response.processInfo dictionaryValue];
    retainV2Config.isOnlyShowNormalRetainStyle = self.manager.hasChangeSelectConfigInVerify;
    return retainV2Config;
}

@end

@implementation CJPayVerifyItem(TrackerProtocol)

#pragma mark - CJPayTrackerProtocol

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary new];
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    
    [trackParamDic cj_setObject:CJString(self.verifySource) forKey:@"risk_source"];
    if ([self.manager.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
        [self.manager.verifyManagerQueen trackVerifyWithEventName:event params:trackParamDic];
    }
}

@end
