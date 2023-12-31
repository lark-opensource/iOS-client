//
//  CJPayIAPMonitor.m
//  Pods
//
//  Created by 王新华 on 2021/2/18.
//

#import "CJPayIAPMonitor.h"
#import "CJPaySDKMacro.h"

@interface CJPayIAPMonitor()
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, assign) NSInteger createBizOrderRetryCount;
@property (nonatomic, assign) NSInteger sendTransactionRetryCount;


@end

@implementation CJPayIAPMonitor

- (void)monitor:(CJPayIAPStage)stage category:(NSDictionary *)category extra:(NSDictionary *)extra {
    switch (stage) {
        case CJPayIAPStageInit:
            
            break;
        case CJPayIAPStageWakeup:
            [self p_monitorWakeUpWithCategory:category extra:extra];
            break;
        case CJPayIAPStageRequestProducts:
            [self p_monitorRequestProductsWithCategory:category extra:extra];
            break;
        case CJPayIAPStageCreateBizOrder:
            [self p_monitorCreateBizOrderWithCategory:category extra:extra];
            break;
        case CJPayIAPStageStartPayment:
            [self p_monitorStartPaymentWithCategory:category extra:extra];
            break;
        case CJPayIAPStageReceiveTransaction:
            [self p_monitorReceiveTransactionWithCategory:category extra:extra];
            break;
        case CJPayIAPStageVerifyTransaction:
            [self p_monitorVerifyTransactionWithCategory:category extra:extra];
            break;
        case CJPayIAPStageCallbackResult:
            [self p_monitorCallbackResultWithCategory:category extra:extra];
            break;
            
        default:
            break;
    }
}

- (void)monitorService:(NSString *)service category:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableMetric = [NSMutableDictionary new];
    if (self.startTime > 0) {
        CFAbsoluteTime spendTime = CFAbsoluteTimeGetCurrent() - self.startTime;
        [mutableMetric cj_setObject:@(spendTime) forKey:@"cost_time"];
    }
}

- (void)p_monitorInitWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"iap_init" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
}

- (void)p_monitorWakeUpWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.createBizOrderRetryCount = 0;
    self.sendTransactionRetryCount = 0;
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"wake_up" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
}

- (void)p_monitorRequestProductsWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"request_products" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
}

- (void)p_monitorCreateBizOrderWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    if (self.createBizOrderRetryCount == 0) {
        NSMutableDictionary *mutableCategory = [category mutableCopy];
        [mutableCategory cj_setObject:@"create_biz_order" forKey:@"stage"];
        [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
    }
    self.createBizOrderRetryCount += 1;
}

- (void)p_monitorStartPaymentWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"start_payment" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
    
    NSMutableDictionary *mutableExtra = [NSMutableDictionary dictionaryWithDictionary:extra];
    [mutableExtra cj_setObject:self.businessIdentify forKey:@"business_id"];
    // 记录财经下单重试次数
    [CJMonitor trackService:@"wallet_rd_create_order_retry" category:@{@"retry_count": @(self.createBizOrderRetryCount)} extra:[mutableExtra copy]];
}

- (void)p_monitorReceiveTransactionWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"send_transaction" forKey:@"stage"];
    [mutableCategory cj_setObject:@(self.sendTransactionRetryCount) forKey:@"send_transaction_retry_count"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
    self.sendTransactionRetryCount += 1;
    
    // 同一笔订单连续调用两次sendTransaction 则可以认为存在异常情况
    if (self.sendTransactionRetryCount >= 2) {
        NSMutableDictionary *mutableExtra = [NSMutableDictionary dictionaryWithDictionary:extra];
        [mutableExtra cj_setObject:self.businessIdentify forKey:@"business_id"];
        [CJMonitor trackService:@"wallet_rd_iap_monitor_exception" category:@{@"not_call_check_final": @"1"} extra:[mutableExtra copy]];
    }
}

- (void)p_monitorVerifyTransactionWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"verify_transaction" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
}

- (void)p_monitorCallbackResultWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableCategory = [category mutableCopy];
    [mutableCategory cj_setObject:@"callback_result" forKey:@"stage"];
    [self p_monitorStagesCostTimeWithCategory:[mutableCategory copy] extra:extra];
}

- (void)p_monitorStagesCostTimeWithCategory:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *mutableMetric = [NSMutableDictionary new];
    if (self.startTime > 0) {
        CFAbsoluteTime spendTime = CFAbsoluteTimeGetCurrent() - self.startTime;
        [mutableMetric cj_setObject:@(spendTime * 1000) forKey:@"cost_time"];
    }
    NSMutableDictionary *mutableCategory = [NSMutableDictionary dictionaryWithDictionary:category];
    [mutableCategory cj_setObject:self.businessIdentify forKey:@"business_id"];
    [mutableCategory cj_setObject:self.useProductCache ? @"1" : @"0" forKey:@"use_product_cache"];
    [mutableCategory cj_setObject:CJString(self.version) forKey:@"version"];
    [mutableCategory cj_setObject:CJString(self.iapType) forKey:@"iap_type"];
    [CJMonitor trackService:@"wallet_rd_iap_stages_cost_time" metric:[mutableMetric copy] category:mutableCategory extra:[extra copy]];
    
    [mutableCategory cj_setObject:@([mutableMetric cj_doubleValueForKey:@"cost_time"]) forKey:@"cost_time"];
    [CJTracker event:@"wallet_rd_iap_stages_cost_time" params:[mutableCategory copy]];
}

@end
