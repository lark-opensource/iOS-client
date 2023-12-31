//
//  CJPayUnionBindCardCommonModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/10/11.
//

#import "CJPayUnionBindCardCommonModel.h"
#import "CJPayUnionBindCardKeysDefine.h"

@implementation CJPayUnionBindCardCommonModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"promotionTips" : CJPayUnionBindCardCommonModelKeyPromotionTips,
        @"isShowMask" : CJPayUnionBindCardCommonModelKeyIsShowMask,
        @"isAliveCheck" : CJPayUnionBindCardCommonModelKeyIsAliveCheck,
        @"unionPaySignInfo" : CJPayUnionBindCardCommonModelKeyUnionPaySignInfo
    }];
    
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
