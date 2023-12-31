//
// Created by 张海阳 on 2020/1/7.
//

#import "CJPayDiscountBanner.h"


@implementation CJPayDiscountBanner

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
            @"banner": @"banner",
            @"url": @"url",
            @"stayTime": @"stay_time",
            @"gotoType": @"goto_type",
            @"resourceNo": @"resource_no",
            @"picUrl": @"pic_url",
            @"jumpUrl": @"jump_url",
            @"sequence": @"sequence",
            @"showTime": @"show_time"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
