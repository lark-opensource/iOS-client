//
//  CJPaySwitchAreaInfoModel.m
//  Pods
//
//  Created by 孔伊宁 on 2022/1/14.
//

#import "CJPaySwitchAreaInfoModel.h"

@implementation CJPaySwitchAreaInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"desc" : @"desc",
        @"action" : @"action",
        @"bioType" : @"bio_type",
        @"downgradeReason" : @"downgrade_reason"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
