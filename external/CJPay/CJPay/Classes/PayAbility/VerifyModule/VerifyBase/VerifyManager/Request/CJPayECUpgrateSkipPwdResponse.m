//
//  CJPayECUpgrateSkipPwdResponse.m
//  Pods
//
//  Created by 孟源 on 2021/10/13.
//

#import "CJPayECUpgrateSkipPwdResponse.h"

@implementation CJPayECUpgrateSkipPwdResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
       [dict addEntriesFromDictionary:@{
               @"modifyResult": @"response.nopwd_modify_result",
               @"buttonText":@"response.nopwd_button_text"
       }];
       
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}
@end
