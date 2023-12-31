//
//  CJPayBindCardPageBaseModel.m
//  Pods
//
//  Created by xutianxi on 2022/1/17.
//

#import "CJPayBindCardPageBaseModel.h"

@implementation CJPayBindCardPageBaseModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[[self keyMapperDict] copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (NSArray <NSString *> *)keysOfParams {
    NSDictionary *dict = [self keyMapperDict];
    return [dict allValues];
}

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"appId" : CJPayBindCardShareDataKeyAppId,
        @"merchantId" : CJPayBindCardShareDataKeyMerchantId,
    }];
    
    return dict;
}

@end
