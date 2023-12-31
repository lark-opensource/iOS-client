//
//  CJPayECCreateOrderModel.m
//  Pods
//
//  Created by 徐天喜 on 2023/06/05.
//

#import "CJPayECCreateOrderModel.h"

@implementation CJPayECCreateOrderModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"st" : @"st",
        @"data" : @"data",
        @"msg" : @"msg"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
