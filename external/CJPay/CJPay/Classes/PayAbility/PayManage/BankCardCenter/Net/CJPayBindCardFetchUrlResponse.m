//
//  CJPayBindCardFetchUrlResponse.m
//  Pods
//
//  Created by youerwei on 2022/4/25.
//

#import "CJPayBindCardFetchUrlResponse.h"

@implementation CJPayBindCardFetchUrlResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"signCardMap" : @"response.sign_card_map",
        @"bizAuthInfoModel" : @"response.busi_authorize_info",
        @"endPageUrl": @"response.end_page_url",
        @"bindPageInfoResponse" : @"response.bind_card_page_info"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

- (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
