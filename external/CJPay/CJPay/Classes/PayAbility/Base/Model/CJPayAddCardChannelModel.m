//
//  CJPayAddCardChannelModel.m
//  Pods
//
//  Created by wangxinhua on 2020/8/12.
//

#import "CJPayAddCardChannelModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayAddCardChannelModel

- (NSDictionary *)requestNeedParams {
    NSDictionary *superParams = [super requestNeedParams];
    NSMutableDictionary *selfPrams = [NSMutableDictionary new];
    [selfPrams addEntriesFromDictionary:superParams];
    NSDictionary *ptcodeInfo = @{@"business_scene": @"Pre_Pay_NewCard"};
    [selfPrams cj_setObject:[CJPayCommonUtil dictionaryToJson:ptcodeInfo] forKey:@"ptcode_info"];
    [selfPrams cj_setObject:@"bytepay" forKey:@"ptcode"];
    return [selfPrams copy];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *addCardConfig = [CJPayDefaultChannelShowConfig new];
    addCardConfig.title = CJPayLocalizedStr(@"添加银行卡");
    addCardConfig.type = BDPayChannelTypeAddBankCard;
    addCardConfig.status = @"1";
    return @[addCardConfig];
}

@end
