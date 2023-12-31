//
//  CJPayFreqSuggestStyleInfo.m
//  sandbox
//
//  Created by xutianxi on 2023/5/24.
//

#import "CJPayFreqSuggestStyleInfo.h"

@implementation CJPayFreqSuggestStyleInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"hasSuggestCard" : @"has_suggest_card",
        @"freqSuggestStyleIndexList" : @"freq_suggest_style_index_list",
        @"titleButtonLabel" : @"title_button_label",
        @"tradeConfirmButtonLabel" : @"trade_confirm_button_label"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
