//
//  CJPayPayAgainTradeCreateResponse.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/19.
//

#import "CJPayPayAgainTradeCreateResponse.h"

#import "CJPayBDCreateOrderResponse.h"

@implementation CJPayPayAgainTradeCreateResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"verifyPageInfoDict" : @"response.verify_page_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

- (CJPayBDCreateOrderResponse *)pageInfo {
    if (!_pageInfo) {
        _pageInfo = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": self.verifyPageInfoDict ?: @{}} error:nil];
    }
    return _pageInfo;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
