//
//  CJPayCreateOrderResponse.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayCreateOrderResponse.h"
#import "CJPayTradeInfo.h"
#import "CJPayUserInfo.h"
#import "CJPayChannelModel.h"
#import "CJPayUIMacro.h"

@interface CJPayCreateOrderResponse()

@property (nonatomic, copy) NSDictionary *dataInfo;

@end

@implementation CJPayCreateOrderResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"dataInfo" : @"data", // 这里包含payinfo和tradeinfo
        @"deskConfig": @"data.cashdesk_show_conf",
        @"merchantInfo" : @"data.merchant_info",
        @"feMetrics" : @"data.fe_metrics",
        @"dypayReturnURL" : @"data.dypay_return_url",
        @"paySource" : @"data.pay_source",
        @"toastMsg": @"data.exts.toast"
    }]];
}

- (void)setDataInfo:(NSDictionary *)dataInfo {
    _dataInfo = dataInfo;
    self.payInfo = [[CJPayTypeInfo alloc] initWithDictionary:dataInfo error:nil];
    self.tradeInfo = [[CJPayTradeInfo alloc] initWithDictionary:[dataInfo cj_dictionaryValueForKey:@"trade_info"] error:nil];
}

- (CJPayUserInfo *)userInfo {
    return self.payInfo.bdPay.userInfo;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSInteger)totalAmountWithDiscount {
    return self.tradeInfo.amount;
}

- (NSInteger)closeAfterTime {
    return self.deskConfig.remainTime;
}

@end
