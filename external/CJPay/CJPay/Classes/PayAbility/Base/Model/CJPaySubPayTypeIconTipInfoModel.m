//
//  CJPaySubPayTypeIconTipInfoModel.m
//  Pods
//
//  Created by bytedance on 2021/7/2.
//

#import "CJPaySubPayTypeIconTipInfoModel.h"

@implementation CJPaySubPayTypeIconTipInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"subTitle": @"sub_title",
        @"subContent": @"sub_content",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
