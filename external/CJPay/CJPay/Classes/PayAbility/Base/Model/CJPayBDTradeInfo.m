//
//  CJPayBDTradeInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import "CJPayBDTradeInfo.h"

@implementation CJPayBDTradeInfo

+ (CJBDPayWithdrawTradeStatus)statusFromString:(NSString *)string {
    CJBDPayWithdrawTradeStatus result = CJBDPayWithdrawTradeStatusUnknown;
    NSDictionary *statusDict = @{
            @"INIT": @(CJBDPayWithdrawTradeStatusInit),
            @"SUCCESS": @(CJBDPayWithdrawTradeStatusSuccess),
            @"FAIL": @(CJBDPayWithdrawTradeStatusFail),
            @"REVIEWING": @(CJBDPayWithdrawTradeStatusReviewing),
            @"PROCESSING": @(CJBDPayWithdrawTradeStatusProcessing),
            @"CLOSED": @(CJBDPayWithdrawTradeStatusClosed),
            @"TIMEOUT": @(CJBDPayWithdrawTradeStatusTimeout),
            @"REEXCHANGE": @(CJBDPayWithdrawTradeStatusReexchange),
    };

    NSNumber *value = statusDict[string];
    if (value != nil) {
        result = value.intValue;
    }
    return result;
}


+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"createTime": @"create_time",
        @"expireTime": @"expire_time",
        @"outTradeNo": @"out_trade_no",
        @"returnUrl": @"return_url",
        @"tradeAmount": @"trade_amount",
        @"tradeDesc": @"trade_desc",
        @"tradeName": @"trade_name",
        @"tradeNo": @"trade_no",
        @"tradeStatusString": @"trade_status",
        @"tradeTime": @"trade_time",
        @"tradeType": @"trade_type",
        @"productID": @"product_id",
        @"amountCanChange": @"amount_can_change",
        @"tradeDescMessage": @"trade_status_desc_msg",
        @"payAmount": @"pay_amount",
        @"bankCodeMask": @"bank_code_mask",
        @"bankName": @"bank_name",
        @"cardType": @"card_type",
        @"failMsg": @"fail_msg",
        @"expectedTime": @"expected_time",
        @"iconUrl": @"icon_url",
        @"rechargeType": @"recharge_type",
        @"serviceFee": @"service_fee",
        @"remark": @"remark",
        @"tradeInfoType": @"trade_info_type",
        @"finishTime":@"finish_time",
        @"withdrawType":@"withdraw_type",
        @"appID": @"app_id",
        @"merchantID": @"merchant_id",
        @"payType": @"pay_type",
        @"combinePayFundList": @"combine_pay_fund_list",
        @"reduceAmount" : @"reduce_amount",
        @"creditPayInstallmentDesc": @"credit_pay_installment_desc",
        @"isTradeCreateAgain": @"is_trade_create_again",
        @"discountDesc": @"discount_desc",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSString *)formattedCreateTime {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.createTime.doubleValue];
    return [formatter stringFromDate:date];
}

- (BOOL)isFailed {
    switch ([CJPayBDTradeInfo statusFromString:self.tradeStatusString]) {
        case CJBDPayWithdrawTradeStatusFail:
        case CJBDPayWithdrawTradeStatusClosed:
        case CJBDPayWithdrawTradeStatusTimeout:
        case CJBDPayWithdrawTradeStatusReexchange:
            return YES;

        default:
            return NO;
    }
}

@end
