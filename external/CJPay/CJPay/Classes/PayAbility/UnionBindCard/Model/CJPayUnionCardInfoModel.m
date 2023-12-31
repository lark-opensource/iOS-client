//
//  CJPayUnionCardInfoModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionCardInfoModel.h"

@implementation CJPayUnionCardInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"bankCode": @"bank_code",
                @"bankName": @"bank_name",
                @"cardType" : @"card_type",
                @"cardNoMask": @"card_no_mask",
//                @"mobileMask" : @"mobile_mask",
                @"iconUrl" : @"icon_url",
                @"status" : @"status",
                @"displayDesc" : @"display_desc",
                @"guideMessage" : @"protocol_group_contents.guide_message",
                @"protocolGroupNames" : @"protocol_group_contents.protocol_group_names",
                @"agreements" : @"protocol_group_contents.protocol_list",
                @"bankCardId" : @"bank_card_id"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
