//
//  CJPayMemProtocolListResponse.m
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayMemProtocolListResponse.h"

#import "CJPayQuickPayUserAgreement.h"
#import "CJPayMemAgreementModel.h"

#import "NSString+CJPay.h"
#import "CJPaySDKMacro.h"

@implementation CJPayMemProtocolListResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"guideMessage" : @"response.guide_message",
        @"protocolCheckBox" : @"response.protocol_check_box",
        @"protocolGroupNames" : @"response.protocol_group_names",
        @"agreements" : @"response.protocol_list",
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

@end
