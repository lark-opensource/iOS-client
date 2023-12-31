//
//  CJPayECVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayECVerifyManagerQueen.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayKVContext.h"
#import "CJPayECVerifyManager.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPaySkipPwdGuideInfoModel.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"

@interface CJPayECVerifyManagerQueen ()

@property (nonatomic, assign) NSTimeInterval beforeConfirmRequestTimestamp;
@property (nonatomic, assign) NSTimeInterval afterConfirmRequestTimestamp;
@property (nonatomic, assign) NSTimeInterval afterQueryResultTimestamp;

@end

@implementation CJPayECVerifyManagerQueen

- (void)beforeConfirmRequest {

    // 发起确认支付前耗时埋点，统计拉起 ttpay 到用户交互完成的耗时(请求确认支付前的耗时)
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
    self.beforeConfirmRequestTimestamp = currentTimestamp;

    if ([self.verifyManager isKindOfClass:CJPayECVerifyManager.class] && [CJPaySettingsManager shared].currentSettings.isHitEventUploadSampled) {
        CJPayECVerifyManager *ecVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
        CJPayFrontCashierContext *payContext = ecVerifyManager.payContext;

        NSString *checkType = [self p_checkTypeMapString:[[ecVerifyManager lastConfirmVerifyItem] checkType]];
        NSMutableDictionary *timestampInfo = [[payContext.extParams cj_dictionaryValueForKey:@"timestamp_info"] mutableCopy];
        if (timestampInfo && timestampInfo.count) {
            NSTimeInterval ttpayEnterCjpay = [timestampInfo cj_doubleValueForKey:@"ttpay_enter_cjpay"];
            if (ttpayEnterCjpay > 100000) {
                // 过滤无效数据
                [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                    @"scenes_name" : @"电商",
                    @"check_type" : CJString(checkType),
                    @"sub_section" : @"发起确认支付前耗时",
                    @"time" : @(currentTimestamp - ttpayEnterCjpay)
                }];
            }
        }
    }
    
    [self trackCashierWithEventName:@"wallet_cashier_confirm_loading"
                             params:@{}];
}

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse {
    [self trackVerifyWithEventName:@"wallet_cashier_confirm_error_info"
                            params:@{@"error_code": CJString(orderResponse.code),
                                     @"error_message": CJString(orderResponse.msg)}];
    NSString *userOpenStatusStr = [orderResponse.exts cj_stringValueForKey:@"pay_after_use_open_status" defaultValue:@""];
    if (self.verifyManager.defaultConfig.type == BDPayChannelTypeAfterUsePay &&
        !self.verifyManager.response.userInfo.payAfterUseActive &&
        Check_ValidString(userOpenStatusStr)) {
        // 先用后付走开通并支付
        NSString *activityIdStr = [orderResponse.exts cj_stringValueForKey:@"activity_id" defaultValue:@""];
        NSString *activityLabelStr = [orderResponse.exts cj_stringValueForKey:@"bill_page_display_text" defaultValue:@""];
        [self trackVerifyWithEventName:@"wallet_cashier_payafteruse_open_result"
                                params:@{@"open_source": @"支付中",
                                         @"result": [userOpenStatusStr isEqualToString:@"success"] ? @"1" : @"0",
                                         @"activity_id": CJString(activityIdStr),
                                         @"activity_label": CJString(activityLabelStr),
                                         @"error_code": CJString(orderResponse.code),
                                         @"error_message": CJString(orderResponse.msg)}];
    }
}

// 调用query查询前的处理。一次支付或提现流程最多一次
- (void)beforQueryResult {

    // 统计确认支付发起与响应的耗时
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    self.afterConfirmRequestTimestamp = [date timeIntervalSince1970] * 1000;
    if ([self.verifyManager isKindOfClass:CJPayECVerifyManager.class] && [CJPaySettingsManager shared].currentSettings.isHitEventUploadSampled) {
        CJPayECVerifyManager *ecVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
        CJPayFrontCashierContext *payContext = ecVerifyManager.payContext;
        NSString *checkType = [self p_checkTypeMapString:[[ecVerifyManager lastConfirmVerifyItem] checkType]];
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
            @"scenes_name" : @"电商",
            @"check_type" : CJString(checkType),
            @"sub_section" : @"确认支付耗时",
            @"time" : @(self.afterConfirmRequestTimestamp - self.beforeConfirmRequestTimestamp)
        }];
    }
}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {
    // 统计查询结果的耗时
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    self.afterQueryResultTimestamp = [date timeIntervalSince1970] * 1000;
    
    if ([self.verifyManager isKindOfClass:CJPayECVerifyManager.class]) {

        CJPayECVerifyManager *ecVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
        CJPayFrontCashierContext *payContext = ecVerifyManager.payContext;
        NSString *checkType = [self p_checkTypeMapString:[[ecVerifyManager lastConfirmVerifyItem] checkType]];
        NSMutableDictionary *timestampInfo = [[payContext.extParams cj_dictionaryValueForKey:@"timestamp_info"] mutableCopy];
        NSTimeInterval createOrder = [timestampInfo cj_doubleValueForKey:@"create_order"]; //创建订单时间戳
        NSTimeInterval createOrderResponse = [timestampInfo cj_doubleValueForKey:@"create_order_response"]; //下单完成时间戳
        NSTimeInterval launchTTpay = [timestampInfo cj_doubleValueForKey:@"launch_ttpay"]; //解析完下单数据时间戳
        
        // 旧有性能埋点（settings控制50%采样率）
        if ([CJPaySettingsManager shared].currentSettings.isHitEventUploadSampled) {
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                @"scenes_name" : @"电商",
                @"check_type" : CJString(checkType),
                @"sub_section" : @"财经查询结果耗时",
                @"time" : @(self.afterQueryResultTimestamp - self.afterConfirmRequestTimestamp)
            }];
            if (createOrder > 100000) {
                // 过滤无效数据，上报提交订单到查询到成功支付结果的耗时
                [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                    @"scenes_name" : @"电商",
                    @"check_type" : CJString(checkType),
                    @"sub_section" : @"总和",
                    @"time" : @(self.afterQueryResultTimestamp - createOrder)
                }];
            }
        }
        // 埋点统计免密接口合并与非合并的耗时
        if ([CJPaySettingsManager shared].currentSettings.performanceMonitorIsOpened &&
            createOrder > 100000 && [self.verifyManager.response.nopwdPreShow isEqualToString:@"1"] &&
            [[self.verifyManager lastVerifyCheckTypeName] isEqualToString:@"免密"]) {
            
            [self trackVerifyWithEventName:@"wallet_rd_no_pwd_pre_merged_time" params:@{
                @"is_merged": self.verifyManager.response.confirmResponse != nil ? @"1" : @"0", //是否接口合并
                @"create_order_time": @(createOrderResponse - createOrder), //下单耗时（接口合并后，表示下单并支付耗时）
                @"order_ttcjpay_time": @(launchTTpay - createOrderResponse), //前端解析下单数据耗时
                @"order_trade_confirm_time": @(self.afterConfirmRequestTimestamp - self.beforeConfirmRequestTimestamp), //确认支付耗时
                @"order_trade_query_time": @(self.afterQueryResultTimestamp - self.afterConfirmRequestTimestamp), //查单耗时
                @"sum_time": @(self.afterQueryResultTimestamp - createOrder) //是否接口合并
            }];
        }
    }
    
    [self trackCashierWithEventName:@"wallet_cashier_result" params:@{
        @"result" : (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"risk_type" : CJString([self.verifyManager allRiskVerifyTypes]),
        @"activity_info" : [self p_activityInfoParamsWithVoucherArray:response.voucherDetails],
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    }];
    
    if (Check_ValidString(response.skipPwdOpenMsg)) {
        NSString *result = response.skipPwdOpenStatus ? @"1" : @"0";
        [self trackCashierWithEventName:@"wallet_onesteppswd_setting_result"
                                 params:@{@"pswd_source": @"支付验证页",
                                          @"result": result,
                                          @"error_code": CJString(response.code),
                                          @"error_message": CJString(response.msg)}];
    }

}

- (NSArray *)p_activityInfoParamsWithVoucherArray:(NSArray<NSDictionary *> *)voucherArray {
    NSMutableArray *activityInfos = [NSMutableArray array];
    [voucherArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count > 0) {
            [activityInfos addObject:@{
                @"id" : CJString([obj cj_stringValueForKey:@"voucher_no"]),
                @"type": [[obj cj_stringValueForKey:@"voucher_type"] isEqualToString:@"discount_voucher"] ? @"0" : @"1",
                @"front_bank_code": Check_ValidString([obj cj_stringValueForKey:@"credit_pay_installment"]) ?
                    CJString([obj cj_stringValueForKey:@"credit_pay_installment"]) : CJString([obj cj_stringValueForKey:@"front_bank_code"]),
                @"reduce" : @([obj cj_intValueForKey:@"used_amount"]),
                @"label": CJString([obj cj_stringValueForKey:@"label"])
            }];
        }
    }];
    return activityInfos;
}

- (NSDictionary *)cashierExtraTrackerParams {
    CJPayBDCreateOrderResponse *response = self.verifyManager.response;
    
    NSString *preMethod = CJString(response.payInfo.businessScene);
    if([preMethod isEqualToString:@"Pre_Pay_Combine"]) {
        if([response.payInfo.primaryPayType isEqualToString:@"bank_card"]) {
            preMethod = @"Pre_Pay_Balance_Bankcard";
        }
        else if ([response.payInfo.primaryPayType isEqualToString:@"new_bank_card"]) {
            preMethod = @"Pre_Pay_Balance_Newcard";
        }
    }
    
    NSMutableDictionary *mutableDic = [@{
        @"check_type" : CJString([self p_checkTypeMapString:response.userInfo.pwdCheckWay]),
        @"pre_method" : preMethod,
        @"is_pswd_guide" : response.skipPwdGuideInfoModel.needGuide ? @"1" : @"0",
        @"is_pswd_default" : response.skipPwdGuideInfoModel.isChecked ? @"1" : @"0",
        @"pswd_pay_type" : [response.userInfo.pwdCheckWay isEqualToString:@"3"] ? @"1" : @"0",
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    } mutableCopy];
    
    if (response.skipPwdGuideInfoModel.needGuide) {
       NSString *guideType = [response.skipPwdGuideInfoModel.guideType isEqualToString:@"upgrade"] ? @"promote_quota" : @"open";
        [mutableDic addEntriesFromDictionary:@{
            @"pswd_guide_type" : CJString(guideType),
            @"pswd_quota" : @(response.skipPwdGuideInfoModel.quota / 100.0)
        }];
    }
    
    if ([self.verifyManager isKindOfClass:CJPayECVerifyManager.class]) {
        CJPayECVerifyManager *ecVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
        [mutableDic addEntriesFromDictionary:[ecVerifyManager.payContext.extParams cj_dictionaryValueForKey:@"track_info"]];
    }
    return [mutableDic copy];
}

- (NSString *)p_checkTypeMapString:(NSString *)verifyType {
    NSDictionary *map = @{
        @"0" : @"密码",
        @"1" : @"指纹",
        @"2" : @"面容",
        @"3" : @"免密"
    };
    return [map cj_stringValueForKey:verifyType];
}

@end
