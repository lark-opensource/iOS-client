//
//  CJPayMemBankActivityResponse.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayMemBankActivityResponse.h"
#import "CJPayBankActivityInfoModel.h"

@implementation CJPayMemBankActivityResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"placeNo" : @"response.promotion_title_info.place_no",
        @"mainTitle" : @"response.promotion_title_info.main_title",
        @"ifShowSubTitle" : @"response.promotion_title_info.if_show_sub_title",
        @"subTitle" : @"response.promotion_title_info.sub_title",
        @"bankActivityInfoArray" : @"response.bank_card_activity_info.bank_activity_list"
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

- (NSArray<CJPayBankActivityInfoModel *> *)bankActivityInfoArray {
    // 若营销活动为奇数则补充一个空营销位
    if (_bankActivityInfoArray.count % 2 == 1) {
        NSMutableArray *eventBankActivityArray = [NSMutableArray arrayWithArray:_bankActivityInfoArray];
        CJPayBankActivityInfoModel *emptyInfoModel = [CJPayBankActivityInfoModel new];
        emptyInfoModel.isEmptyResource = YES;
        [eventBankActivityArray addObject:emptyInfoModel];
        _bankActivityInfoArray = [eventBankActivityArray copy];
    }
    return _bankActivityInfoArray;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
