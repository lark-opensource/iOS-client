//
//  CJPayOpenSkipPwdResponse.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/11.
//

#import "CJPayOpenSkipPwdResponse.h"

@implementation CJPayOpenSkipPwdResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
       [dict addEntriesFromDictionary:@{
               @"openResultStr": @"response.nopwd_open_result",
               @"buttonText":@"response.nopwd_button_text"
       }];
       
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

@end
