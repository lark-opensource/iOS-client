//
//  CJPayQueryOneKeySignResponse.m
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayQueryOneKeySignResponse.h"

@implementation CJPayQueryOneKeySignResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *keyV = [self basicDict];
    [keyV addEntriesFromDictionary:@{
        @"orderStatus": @"response.order_status",
        @"status": @"response.ret_status",
        @"signNo": @"response.sign_no",
        @"token": @"response.token",
        @"buttonInfo": @"response.button_info",
        @"bankCardId": @"response.bank_card_id"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:keyV];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
