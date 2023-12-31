//
//  CJPayBannerResponse.m
//  Pods
//
//  Created by mengxin on 2020/12/24.
//

#import "CJPayBannerResponse.h"

@implementation CJPayBannerResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"status" : @"response.ret_status",
        @"placeNo" : @"response.place_no",
        @"bannerList" : @"response.resource_info_list",
        @"promotionModels": @"response.lottery_status_put_info.prize_detail_list",
        @"planNo": @"response.lottery_status_put_info.plan_no",
        @"resourceNo": @"response.lottery_status_put_info.resource_no",
        @"materialNo": @"response.lottery_status_put_info.meterial_no",
        @"bizType": @"response.lottery_status_put_info.biz_type"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
