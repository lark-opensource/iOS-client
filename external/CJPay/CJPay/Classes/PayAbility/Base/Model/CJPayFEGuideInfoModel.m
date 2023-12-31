//
//  CJPayFEGuideInfoModel.m
//  Pods
//
//  Created by 尚怀军 on 2021/12/29.
//

#import "CJPayFEGuideInfoModel.h"

@implementation CJPayFEGuideInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"guideType" : @"guide_type",
        @"url" : @"url"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
