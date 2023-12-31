//
//  CJPayIAPConfigResponse.m
//  Aweme
//
//  Created by bytedance on 2022/12/16.
//

#import "CJPayIAPConfigResponse.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPayIAPConfigResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"failPopupConfig" : @"response.extension.fail_popup_config"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

-(CJPayIAPFailPopupConfigModel *)failPopupConfigModel {
    NSDictionary *dict = [CJPayCommonUtil jsonStringToDictionary:self.failPopupConfig];
    CJPayIAPFailPopupConfigModel *model = [CJPayIAPFailPopupConfigModel new];
    model.sk1Network = [[dict cj_dictionaryValueForKey:@"error_code"] cj_arrayValueForKey:@"sk1_network"];
    model.sk2Network = [[dict cj_dictionaryValueForKey:@"error_code"] cj_arrayValueForKey:@"sk2_network"];
    model.sk1Others = [[dict cj_dictionaryValueForKey:@"error_code"] cj_arrayValueForKey:@"sk1_others"];
    model.sk2Others = [[dict cj_dictionaryValueForKey:@"error_code"] cj_arrayValueForKey:@"sk2_others"];
    model.linkChatUrl = [dict cj_stringValueForKey:@"link_chat_url"];
    model.contentNetwork = [[dict cj_dictionaryValueForKey:@"popup_config"] cj_stringValueForKey:@"content_network"];
    model.contentOthers = [[dict cj_dictionaryValueForKey:@"popup_config"] cj_stringValueForKey:@"content_others"];
    model.titleNetwork = [[dict cj_dictionaryValueForKey:@"popup_config"] cj_stringValueForKey:@"title_network"];
    model.titleOthers = [[dict cj_dictionaryValueForKey:@"popup_config"] cj_stringValueForKey:@"title_others"];
    model.startTime = CFAbsoluteTimeGetCurrent();
    model.merchantFrequency = [dict cj_intValueForKey:@"merchant_frequency"];
    model.orderFrequency = [dict cj_intValueForKey:@"order_frequency"];
    
    return model;
}

@end
