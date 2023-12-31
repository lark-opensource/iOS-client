//
//  CJPayUnionCreateOrderResponse.m
//  Pods
//
//  Created by xutianxi on 2021/10/8.
//

#import "CJPayUnionCreateOrderResponse.h"
#import "NSString+CJPay.h"

@implementation CJPayUnionCreateOrderResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"memberBizOrderNo" : @"response.member_biz_order_no",
        @"unionPaySignInfo" : @"response.union_pay_sign_info",
        @"buttonInfo": @"response.button_info",
        @"unionIconUrl" : @"response.bind_card_union_icon_url"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
