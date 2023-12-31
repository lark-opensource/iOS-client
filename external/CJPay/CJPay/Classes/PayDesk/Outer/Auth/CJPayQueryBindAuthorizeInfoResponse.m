//
//  CJPayQueryBindAuthorizeInfoResponse.m
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayQueryBindAuthorizeInfoResponse.h"
#import "CJPayBaseResponse.h"

@implementation CJPayQueryBindAuthorizeBriefInfoModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"displayDesc" : @"display_desc",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

- (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayQueryBindAuthorizeProtocolModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"guideMessage" : @"guide_message",
        @"protocolCheckBox" : @"protocol_check_box",
        @"protocolGroupNames" : @"protocol_group_names",
        @"agreements" : @"protocol_list",
        @"tailGuideMessage" : @"tail_guide_message",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

- (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayQueryBindAuthorizeInfoResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"authBriefModel" : @"response.authorize_brief_info",
        @"protocolModel" : @"response.protocol_group_contents",
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

- (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
