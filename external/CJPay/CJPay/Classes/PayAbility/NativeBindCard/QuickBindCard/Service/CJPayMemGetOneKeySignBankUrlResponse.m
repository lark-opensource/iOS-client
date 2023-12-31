//
//  CJPayMemGetOneKeySignBankUrlResponse.m
//  Pods
//
//  Created by renqiang on 2021/6/3.
//

#import "CJPayMemGetOneKeySignBankUrlResponse.h"
#import "CJPayErrorButtonInfo.h"

@implementation CJPayMemGetOneKeySignBankUrlResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"bankUrl" : @"response.bank_url",
        @"postData" : @"response.post_data",
        @"buttonInfo" : @"response.button_info",
        @"isMiniApp" : @"response.is_mini_app"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
