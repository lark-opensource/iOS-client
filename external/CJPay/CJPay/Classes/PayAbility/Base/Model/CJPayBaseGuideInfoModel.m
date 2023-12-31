//
//  CJPayBaseGuideInfoModel.m
//  Pods
//
//  Created by mengxin on 2021/5/23.
//

#import "CJPayBaseGuideInfoModel.h"

@implementation CJPayBaseGuideInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"needGuide": @"need_guide",
                @"title": @"title",
                @"buttonText": @"button_text",
                @"protocolGroupNames": @"protocol_group_names",
                @"protocoList": @"protocol_list",
                @"guideMessage": @"guide_message",
                @"voucherAmount" : @"voucher_amount",
                @"isButtonFlick" : @"is_button_flick"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (NSMutableDictionary *)basicDict {
    return [@{@"needGuide": @"need_guide",
              @"title": @"title",
              @"buttonText": @"button_text",
              @"protocolGroupNames": @"protocol_group_names",
              @"protocoList": @"protocol_list",
              @"guideMessage": @"guide_message",
              @"voucherAmount" : @"voucher_amount",
              @"isButtonFlick" : @"is_button_flick"
    } mutableCopy];
}

@end
