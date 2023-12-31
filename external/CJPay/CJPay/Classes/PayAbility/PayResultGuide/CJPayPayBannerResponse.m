//
//  CJPayPayBannerResponse.m
//  Pods
//
//  Created by chenbocheng on 2021/8/4.
//

#import "CJPayPayBannerResponse.h"

@implementation CJPayPayBannerResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [[self basicDict] mutableCopy];
    [dict addEntriesFromDictionary:@{
        @"status" : @"response.ret_status",
        @"dynamicComponents" : @"response.dynamic_components",
        @"benefitInfo" : @"response.benefit_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

@end
