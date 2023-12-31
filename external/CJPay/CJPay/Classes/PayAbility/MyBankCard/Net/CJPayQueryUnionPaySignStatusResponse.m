//
//  CJPayQueryUnionPaySignStatusResponse.m
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/8/31.
//

#import "CJPayQueryUnionPaySignStatusResponse.h"

@implementation CJPayQueryUnionPaySignStatusResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"signStatus" : @"response.sign_status",
        @"needShowUnionPay" : @"response.need_show_union_pay",
        @"bindCardDouyinIconUrl" : @"response.bind_card_douyin_icon_url",
        @"bindCardUnionIconUrl" : @"response.bind_card_union_icon_url",
        @"buttonInfo" : @"response.button_info"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
