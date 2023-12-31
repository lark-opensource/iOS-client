//
//  CJPayDeductAgainRequest.m
//  CJPaySandBox
//
//  Created by 高航 on 2023/1/4.
//

#import "CJPayDeductAgainRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseResponse.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
@implementation CJPayDeductAgainResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"payStatus" : @"data.status",
        @"outTradeNo" : @"data.out_trade_no",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayDeductAgainRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams completion:(void (^)(NSError * _Nonnull, CJPayDeductAgainResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableRequestParams = [self buildBaseParams];
    [mutableRequestParams addEntriesFromDictionary:requestParams];
    
    [self startRequestWithUrl:[self requestUrlString] requestParams:[mutableRequestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayDeductAgainResponse *response = [[CJPayDeductAgainResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)requestUrlString {
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@", [self superPayServerUrlString],[self apiPath]];
    return serverUrl;
}

+ (NSString *)apiPath {
    return @"/tp/quick_pay/deduct_again";
}

@end
