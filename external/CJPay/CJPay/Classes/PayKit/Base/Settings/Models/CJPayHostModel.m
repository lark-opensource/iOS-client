//
//  CJPayHostModel.m
//  Pods
//
//  Created by chenbocheng on 2021/10/27.
//

#import "CJPayHostModel.h"

@implementation CJPayHostModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"bdHostDomain" : @"bd_host_domain",
        @"h5PathList" : @"h5_path_list",
        @"integratedHostDomain" : @"integrated_host_domain"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
