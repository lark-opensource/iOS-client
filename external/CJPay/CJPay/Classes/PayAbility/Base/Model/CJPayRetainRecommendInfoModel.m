//
//  CJPayRetainRecommendInfoModel.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayRetainRecommendInfoModel.h"

@implementation CJPayRetainRecommendInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"title" : @"title",
        @"topRetainButtonText" : @"top_retain_button_text",
        @"bottomRetainButtonText" : @"bottom_retain_button_text"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}



@end
