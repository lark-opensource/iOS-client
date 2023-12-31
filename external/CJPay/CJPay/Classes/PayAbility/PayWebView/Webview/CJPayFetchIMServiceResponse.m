//
//  CJPayFetchIMServiceResponse.m
//  Pods
//
//  Created by youerwei on 2021/11/24.
//

#import "CJPayFetchIMServiceResponse.h"

@implementation CJPayFetchIMServiceResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [self basicDict];
    [dic addEntriesFromDictionary:@{
        @"linkChatUrl": @"response.link_chat_url"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)isSuccess {
    return [self.code isEqualToString:@"UM0000"];
}

@end
