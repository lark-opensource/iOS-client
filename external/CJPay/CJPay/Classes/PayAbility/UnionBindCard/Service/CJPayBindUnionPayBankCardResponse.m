//
//  CJPayBindUnionPayBankCardResponse.m
//  CJPay-5b542da5
//
//  Created by bytedance on 2022/9/7.
//

#import "CJPayBindUnionPayBankCardResponse.h"

@implementation CJPayBindUnionPayBankCardResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"bindCardIdList" : @"response.bind_card_id_list",
        @"buttonInfo" : @"response.button_info",
        @"isSetPwd" : @"response.is_set_pwd"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
