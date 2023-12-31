//
//  CJPayForceHttpsModel.m
//  Pods
//
//  Created by 尚怀军 on 2021/2/24.
//

#import "CJPayForceHttpsModel.h"

@implementation CJPayForceHttpsModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"forceHttpsEnable" : @"force_https_enable",
                @"allowHttpList" : @"allow_http_list",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
