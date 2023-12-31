//
//  CJPaySignSetMemberFirstPayTypeResponse.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPaySignSetMemberFirstPayTypeResponse.h"

@implementation CJPaySignSetMemberFirstPayTypeResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"displayName" : @"response.display_name"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
