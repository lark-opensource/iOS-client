//
//  CJPayBioGuideInfoModel.m
//  Pods
//
//  Created by 孔伊宁 on 2021/9/26.
//

#import "CJPayBioGuideInfoModel.h"

@implementation CJPayBioGuideInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title" : @"title",
                @"choose" : @"choose",
                @"bioType" : @"bio_type",
                @"guideStyle" : @"style",
                @"btnDesc" : @"btn_desc",
                @"isShowButton": @"is_show_button",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
