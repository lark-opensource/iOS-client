//
//  CJPaySignCardInfo.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import "CJPaySignCardInfo.h"

@implementation CJPaySignCardInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"titleMsg" : @"status_msg",
                @"buttonText" : @"button_text"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
