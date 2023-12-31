//
//  CJPayCardSignInfoModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/4/12.
//

#import "CJPayCardSignInfoModel.h"

@implementation CJPayCardSignInfoModel

+ (JSONKeyMapper *)keyMapper {
    
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"signOrderNo" : @"sign_order_no",
                @"smchId": @"smch_id"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
