//
//  CJPayZoneSplitInfoModel.m
//  cjpayBankLock
//
//  Created by ByteDance on 2023/2/15.
//

#import "CJPayZoneSplitInfoModel.h"

@implementation CJPayZoneSplitInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"zoneIndex": @"zone_index",
        @"zoneTitle": @"zone_title",
        @"combineZoneTitle": @"combine_zone_title",
        @"otherCardInfo": @"other_card_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
