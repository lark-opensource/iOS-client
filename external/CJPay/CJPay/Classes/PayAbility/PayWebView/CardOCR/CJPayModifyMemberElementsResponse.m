//
//  CJPayModifyMemberElementsResponse.m
//  CJPay
//
//  Created by youerwei on 2022/6/22.
//

#import "CJPayModifyMemberElementsResponse.h"

@implementation CJPayModifyMemberElementsResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                    @"buttonInfo" : @"response.button_info",
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
