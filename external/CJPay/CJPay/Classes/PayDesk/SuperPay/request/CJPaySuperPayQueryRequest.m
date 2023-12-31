//
//  CJPaySuperPayQueryRequest.m
//  Pods
//
//  Created by 易培淮 on 2022/3/29.
//

#import "CJPaySuperPayQueryRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseResponse.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"

@implementation CJPaySuperPayQueryResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"payStatus" : @"data.status",
        @"loadingMsg" : @"data.msg",
        @"loadingSubMsg" : @"data.sub_msg",
        @"paymentInfo" : @"data.payment_info",
        @"sdkInfo" : @"data.sdk_info",
        @"payAgainInfo" : @"data.pay_again_info",
        @"showToast": @"data.show_toast",
        @"ext": @"data.payment_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayHintInfo *)hintInfo {
    if (!_hintInfo) {
        NSDictionary *dict = [CJPayCommonUtil jsonStringToDictionary:self.payAgainInfo];
        _hintInfo = [[CJPayHintInfo alloc] initWithDictionary:dict error:nil];
        NSString *recPayType = CJString([dict cj_stringValueForKey:@"rec_pay_type"]);
        NSDictionary *recPayDict = [CJPayCommonUtil jsonStringToDictionary:recPayType];
        _hintInfo.recPayType = [[CJPaySubPayTypeInfoModel alloc] initWithDictionary:recPayDict error:nil];
    }
    return _hintInfo;
}

@end

@implementation CJPayPaymentInfoModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"deductType" : @"deduct_type",
        @"channelName" : @"channel_name",
        @"cardMaskCode" : @"card_mask_code",
        @"cardType" : @"card_type",
        @"deductAmount" : @"deduct_amount"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySuperPayQueryRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
                  completion:(void (^)(NSError * _Nonnull, CJPaySuperPayQueryResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableRequestParams = [self buildBaseParams];
    [mutableRequestParams addEntriesFromDictionary:requestParams];
    
    [self startRequestWithUrl:[self requestUrlString] requestParams:[mutableRequestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPaySuperPayQueryResponse *response = [[CJPaySuperPayQueryResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}



+ (NSString *)requestUrlString {
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@", [self superPayServerUrlString],[self apiPath]];
    return serverUrl;
}

+ (NSString *)apiPath {
    return @"/tp/quick_pay/trade_query";
}

@end
