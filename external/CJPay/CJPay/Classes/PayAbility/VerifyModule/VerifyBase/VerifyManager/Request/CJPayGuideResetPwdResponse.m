//
//  CJPayGuideResetPwdResponse.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayGuideResetPwdResponse.h"

@implementation CJPayGuideResetPwdResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"jumpUrl":@"response.jump_url"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}


@end
