//
//  CJPayQueryPayTypeResponse.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/19.
//

#import "CJPayQueryPayTypeResponse.h"

@implementation CJPayQueryPayTypeResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{ @"tradeInfo" : @"response.pre_trade_info"}];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
