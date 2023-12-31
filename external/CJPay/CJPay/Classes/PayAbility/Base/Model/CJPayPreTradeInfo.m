//
//  CJPayPreTradeInfo.m
//  Pods
//
//  Created by 王新华 on 2022/2/25.
//

#import "CJPayPreTradeInfo.h"

@implementation CJPayPreTradeTrackInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"creditStatus" : @"credit_status",
        @"bankCardStatus" : @"bank_card_status",
        @"balanceStatus" : @"balance_status",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayPreTradeInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"bankCardID" : @"bank_card_id",
        @"cardNoMask" : @"card_no_mask",
        @"mobileMask" : @"mobile_mask",
        @"bankName" : @"bank_name",
        @"exts" : @"exts",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayPreTradeTrackInfo *)trackInfo {
    if (!_trackInfo && self.exts.length > 0) {
        _trackInfo = [[CJPayPreTradeTrackInfo alloc] initWithString:self.exts error:nil];
    }
    return _trackInfo;
}

@end
