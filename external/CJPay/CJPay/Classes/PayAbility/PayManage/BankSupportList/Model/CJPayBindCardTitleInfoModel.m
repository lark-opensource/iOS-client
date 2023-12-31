//
//  CJPayBindCardTitleInfoModel.m
//  Pods
//
//  Created by renqiang on 2021/7/5.
//

#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayUIMacro.h"
@implementation CJPayBindCardTitleInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"displayIcon" : @"display_icon",
        @"displayDesc" : @"display_desc",
        @"title" : @"title",
        @"subTitle" : @"sub_title",
        @"orderInfo" : @"order_display_desc",
        @"iconURL" : @"order_display_icon"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
