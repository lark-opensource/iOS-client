//
//  CJPayUnionBindCardListResponse.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayUnionBindCardListResponse.h"

@implementation CJPayUnionBindCardListResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"cardList" : @"response.union_pay_banks",
        @"hasBindableCard": @"response.has_bindable_card",
        @"unionCopywritingInfo" : @"response.unbindable_copywriting_info"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end


@implementation CJPayUnionCopywritingInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title": @"title",
                @"subTitle": @"sub_title",
                @"displayDesc" : @"display_desc",
                @"displayIcon" : @"display_icon"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
