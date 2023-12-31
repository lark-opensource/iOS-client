//
//  CJPayUnionBindCardSignResponse.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardSignResponse.h"
#import "CJPayErrorButtonInfo.h"

@implementation CJPayUnionBindCardSignResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [self basicDict];
    [dic addEntriesFromDictionary:@{
        @"buttonInfo": @"response.button_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
