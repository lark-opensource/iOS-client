//
//  CJPayQueryPayOrderInfoRequest.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/4.
//

#import "CJPayQueryPayOrderInfoRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+Outer.h"

@implementation CJPayLoginTradeInfo

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"currency" : @"currency",
        @"payAmount" : @"pay_amount",
        @"tradeAmount" :@"trade_amount",
        @"tradeName" :@"trade_name",
        @"tradeDesc" :@"trade_desc"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayLoginMerchantInfo

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"merchantId" : @"merchant_id",
        @"merchantName" : @"merchant_name",
        @"merchantShortToCustomer" : @"merchant_short_to_customer"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayQueryPayOrderInfoResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"tradeInfo" : @"trade_info",
        @"merchantInfo" : @"merchant_info",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayLoginOrderStatus)resultStatus {
    if ([self.code isEqualToString:@"CD000000"]) {
        return CJPayLoginOrderStatusSuccess;
    } else if ([self.code isEqualToString:@"CD000502"] || [self.code isEqualToString:@"CD000503"]) {
        return CJPayLoginOrderStatusWarning;
    } else {
        return CJPayLoginOrderStatusError;
    }
}

@end

@implementation CJPayQueryPayOrderInfoRequest

+ (void)startWithRequestParams:(NSDictionary *)requestParams completion:(void (^)(NSError * _Nonnull, CJPayQueryPayOrderInfoResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableRequestParams = [self buildBaseParams];
    [mutableRequestParams addEntriesFromDictionary:requestParams];
    
    [self startRequestWithUrl:[self requestUrlString] requestParams:[mutableRequestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        NSDictionary *result;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            result = (NSDictionary *)jsonObj;
        }
        CJPayQueryPayOrderInfoResponse *response = [[CJPayQueryPayOrderInfoResponse alloc] initWithDictionary:[result cj_dictionaryValueForKey:@"response"] error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)requestUrlString {
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@", [self outerDeskServerUrlString],[self apiPath]];
    return serverUrl;
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/query_pay_order_info";
}

@end
