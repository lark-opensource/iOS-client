//
//  CJPayIAPRetainUtil.m
//  Aweme
//
//  Created by chenbocheng.moon on 2023/3/6.
//

#import "CJPayIAPRetainUtil.h"
#import "CJPayIAPFailPopupConfigModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayIAPConfigRequest.h"
#import "CJPayIAPConfigResponse.h"
#import "CJPayIAPResultEnumHeader.h"
#import "CJPayIAPRetainPopUpViewController.h"
#import "CJPayWebViewService.h"
#import "CJIAPProduct.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJIAPStoreManager+Delegate.h"
#import "CJPayWebViewUtil.h"

NSString static *const CJPayIAPRetainUserAgent = @"CJPayIAPRetainUserAgent";

@interface CJPayIAPRetainUtil()

@property (nonatomic, strong) NSMutableDictionary *failConfigDict;
@property (nonatomic, strong) NSMutableDictionary *retainedOrderDict;//缓存订单展示次数

@end

@implementation CJPayIAPRetainUtil

#pragma mark - public method

- (void)showLoading:(NSString *)productId {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    NSArray<NSString *> *loadingDescription = curSettings.iapConfigModel.loadingDescription;
    NSArray *loadingDescriptionTime = curSettings.iapConfigModel.loadingDescriptionTime;
    if (!curSettings.iapConfigModel || !Check_ValidArray(loadingDescription) || !Check_ValidArray(loadingDescriptionTime)) {
        return;
    }
    
    NSNumber *orderFinishTime = (NSNumber *)[loadingDescriptionTime cj_objectAtIndex:0];
    NSNumber *startPaymentTime = (NSNumber *)[loadingDescriptionTime cj_objectAtIndex:1];
    NSNumber *appleProcessTime = (NSNumber *)[loadingDescriptionTime cj_objectAtIndex:2];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(orderFinishTime.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.orderInProgress) {
            [[CJIAPStoreManager shareInstance] showLoadingWithStage:CJPayIAPLoadingStageOrderFinish productId:productId text:[loadingDescription cj_objectAtIndex:0]];
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(startPaymentTime.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.orderInProgress) {
            [[CJIAPStoreManager shareInstance] showLoadingWithStage:CJPayIAPLoadingStageStartPayment productId:productId text:[loadingDescription cj_objectAtIndex:1]];
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(appleProcessTime.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.orderInProgress) {
            [[CJIAPStoreManager shareInstance] showLoadingWithStage:CJPayIAPLoadingStageAppleProcess productId:productId text:[loadingDescription cj_objectAtIndex:2]];
        }
    });
}

- (void)iapConfigWithAppid:(NSString *)appId merchantId:(NSString *)merchantId uid:(NSString *)uid {
    NSString *key = [NSString stringWithFormat:@"%@_%@", merchantId, uid];
    CJPayIAPFailPopupConfigModel *configModel = [self.failConfigDict cj_objectForKey:key];
    if (configModel && (CFAbsoluteTimeGetCurrent() - configModel.startTime <= 2 * 24 * 60 * 60)) {
        return;
    }
    
    NSDictionary *params = @{@"app_id" : CJString(appId),
                             @"merchant_id" : CJString(merchantId),
                             @"uid" : CJString(uid)
    };
    @CJWeakify(self)
    [CJPayIAPConfigRequest startRequest:params completion:^(NSError * _Nonnull error, CJPayIAPConfigResponse * _Nonnull response) {
        @CJStrongify(self)
        if (!Check_ValidString(response.failPopupConfig)) {
            CJPayLogInfo(@"CJPayIAPConfigRequest failed");
            return;
        }
        
        [self.failConfigDict cj_setObject:[response failPopupConfigModel] forKey:key];
    }];
}

- (BOOL)showRetainPopWithIapType:(CJPayIAPType)iapType
                           error:(NSError *)error
                      completion:(void(^)(void))completionBlock {
    CJPayIAPFailPopupConfigModel *configModel = [self.failConfigDict cj_objectForKey:self.merchantKey];
    if (!configModel) {
        return NO;
    }
    NSString *title = @"";
    NSString *content = @"";
    BOOL isNetworkRetain = NO;
    if (iapType == CJPayIAPTypeSwiftSK1) {
        if ([configModel.sk1Network containsObject:[[NSNumber numberWithInteger:error.code] stringValue]]) {
            title = configModel.titleNetwork;
            content = configModel.contentNetwork;
            isNetworkRetain = YES;
        } else if ([configModel.sk1Others containsObject:[[NSNumber numberWithInteger:error.code] stringValue]]) {
            title = configModel.titleOthers;
            content = configModel.contentOthers;
        } else {
            return NO;
        }
    } else if (iapType == CJPayIAPTypeSwiftSK2) {
        if ([configModel.sk2Network containsObject:[[NSNumber numberWithInteger:error.code] stringValue]]) {
            title = configModel.titleNetwork;
            content = configModel.contentNetwork;
            isNetworkRetain = YES;
        } else if ([configModel.sk2Others containsObject:[[NSNumber numberWithInteger:error.code] stringValue]]) {
            title = configModel.titleOthers;
            content = configModel.contentOthers;
        } else {
            return NO;
        }
    } else {
        CJPayLogError(@"IAP type error")
        return NO;
    }
    
    if (!Check_ValidString(title) || !Check_ValidString(content)) {
        CJPayLogInfo(@"IAP retain title:%@ content:%@", title, content);
        return NO;
    }
    
    BOOL timesControlled = [self p_timesControlled:configModel];
    if (timesControlled && !isNetworkRetain) {
        return NO;
    }

    CJPayIAPRetainPopUpViewController *alertVC = [[CJPayIAPRetainPopUpViewController alloc] initWithTitle:title content:content];
    @CJWeakify(alertVC)
    @CJWeakify(self)
    alertVC.clickConfirmBlock = ^{
        @CJStrongify(alertVC)
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_cashier_iap_pay_finish_pop_click"
                         errorCode:[[NSNumber numberWithInteger:error.code] stringValue]
                           message:content
                            params:@{@"button_name" : @"继续支付"}];
        [alertVC dismissSelfWithCompletionBlock:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.confirmBlock);
        }];
    };
    
    alertVC.clickHelpBlock = ^{
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_cashier_iap_pay_finish_pop_click"
                         errorCode:[[NSNumber numberWithInteger:error.code] stringValue]
                           message:content
                            params:@{@"button_name" : @"问题帮助"}];
        if ([configModel.linkChatUrl hasPrefix:@"https://"]) {
            if (CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService)) {
                [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_openScheme:configModel.linkChatUrl callBack:^(CJPayAPIBaseResponse * _Nonnull response) {}];
            } else {
                CJPayLogInfo(@"webview能力未包含");
            }
        } else {
            [[CJPayWebViewUtil sharedUtil] openCJScheme:configModel.linkChatUrl];//aweme://webview?xxx
        }
    };
    
    alertVC.clickCancelBlock = ^{
        @CJStrongify(alertVC)
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_cashier_iap_pay_finish_pop_click"
                         errorCode:[[NSNumber numberWithInteger:error.code] stringValue]
                           message:content
                            params:@{@"button_name" : @"放弃支付"}];
        [alertVC dismissSelfWithCompletionBlock:completionBlock];
    };
    
    [self p_trackWithEventName:@"wallet_cashier_iap_pay_finish_pop_show"
                     errorCode:[[NSNumber numberWithInteger:error.code] stringValue]
                       message:content
                        params:@{@"tab_list" : @"继续支付，问题帮助，放弃支付"}];
    self.isRetainShown = YES;
    [alertVC showOnTopVC:[UIViewController cj_topViewController]];
    [self p_saveRetainShownData];
    return YES;
}

#pragma mark - private method

- (void)p_trackWithEventName:(NSString *)eventName
                   errorCode:(NSString *)errorCode
                     message:(NSString *)message
                      params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"result" : @"0",
        @"error_code" : CJString(errorCode),
        @"error_message" : CJString(message),
        @"merchant_id" : CJString(self.merchantId),
        @"trade_no" : CJString(self.tradeNo)
    }];
    [mutableDic addEntriesFromDictionary:params];
    [CJTracker event:eventName params:mutableDic];
}

- (void)p_saveRetainShownData {
    NSNumber *orderTimes = [self.retainedOrderDict cj_objectForKey:CJString(self.tradeNo)];
    if (orderTimes) {
        [self.retainedOrderDict setValue:@(orderTimes.intValue + 1) forKey:CJString(self.tradeNo)];
    } else {
        [self.retainedOrderDict setValue:@(1) forKey:CJString(self.tradeNo)];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [[userDefaults objectForKey:CJPayIAPRetainUserAgent] mutableCopy];
    NSString *currentDateStr = [self p_currentDay];
    
    if (!dict) {
        //第一次存储
        dict = [NSMutableDictionary new];
        [dict setValue:@{CJString(self.merchantKey):@1} forKey:CJString(currentDateStr)];
    } else {
        NSMutableDictionary *merchantIdDict = [[dict cj_dictionaryValueForKey:CJString(currentDateStr)] mutableCopy];
        if (merchantIdDict) {
            //当天的数据
            NSNumber *times = [merchantIdDict cj_objectForKey:CJString(self.merchantKey)];
            if (times) {
                [merchantIdDict setValue:@(times.intValue + 1) forKey:CJString(self.merchantKey)];
            } else {
                [merchantIdDict setValue:@1 forKey:CJString(self.merchantKey)];
            }
            [dict setValue:merchantIdDict forKey:CJString(currentDateStr)];
        } else {
            //历史的数据
            dict = [NSMutableDictionary new];
            [dict setValue:@{CJString(self.merchantKey):@1} forKey:CJString(currentDateStr)];
        }
        [userDefaults removeObjectForKey:CJPayIAPRetainUserAgent];
    }
    [userDefaults setValue:dict forKey:CJPayIAPRetainUserAgent];
}

- (BOOL)p_timesControlled:(CJPayIAPFailPopupConfigModel *)configModel {
    if (!configModel.merchantFrequency || configModel.merchantFrequency <= 0 || !configModel.orderFrequency || configModel.orderFrequency <= 0) {
        return NO;
    }
    
    NSNumber *orderTimes = [self.retainedOrderDict cj_objectForKey:CJString(self.tradeNo)];
    if (orderTimes && orderTimes.intValue >= configModel.orderFrequency) {
        return YES;
    }
    
    NSMutableDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:CJPayIAPRetainUserAgent];
    if (Check_ValidDictionary(dict)) {
        NSDictionary *merchantIdDict = [dict cj_dictionaryValueForKey:CJString([self p_currentDay])];
        if (Check_ValidDictionary(merchantIdDict)) {
            NSNumber *merchantTimes = [merchantIdDict cj_objectForKey:self.merchantKey];
            if (merchantTimes && merchantTimes.intValue >= configModel.merchantFrequency) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSString *)p_currentDay {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSMutableDictionary *)failConfigDict {
    if (!_failConfigDict) {
        _failConfigDict = [NSMutableDictionary dictionary];
    }
    return _failConfigDict;
}

- (NSMutableDictionary *)retainedOrderDict {
    if (!_retainedOrderDict) {
        _retainedOrderDict = [NSMutableDictionary dictionary];
    }
    return _retainedOrderDict;
}

@end
