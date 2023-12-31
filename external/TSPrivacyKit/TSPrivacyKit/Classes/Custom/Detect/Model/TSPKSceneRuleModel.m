//
//  TSPKSceneRuleModel.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/16.
//

#import "TSPKSceneRuleModel.h"
#import "TSPrivacyKitConstants.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKSceneRuleModel

+ (instancetype)createWithDictionary:(NSDictionary *)dict {
    NSInteger ruleId = [dict[TSPKRuleIdKey] integerValue];
    NSString *ruleName = [dict btd_stringValueForKey:TSPKRuleNameKey];
    NSString *ruleType = [dict btd_stringValueForKey:TSPKRuleTypeKey];
    NSDictionary *params = [dict btd_dictionaryValueForKey:TSPKRuleParamsKey];
    NSArray *ruleIgnoreCondition = [dict btd_arrayValueForKey:TSPKRuleIgnoreConditionKey];
    
    if (ruleId <= 0 ||
        [ruleName length] == 0 ||
        [ruleType length] == 0) {
        NSAssert(false, @"input value is illegal");
        return nil;
    }
    
    TSPKSceneRuleModel *model = [TSPKSceneRuleModel new];
    model.ruleId = ruleId;
    model.ruleName = ruleName;
    model.type = ruleType;
    model.params = params;
    
    if (ruleIgnoreCondition.count > 0) {
        model.ruleIgnoreCondition = [NSSet setWithArray:ruleIgnoreCondition];
    }
    
    return model;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TSPKSceneRuleModel class]]) {
        return NO;
    }
    
    TSPKSceneRuleModel *compareModel = (TSPKSceneRuleModel *)object;
    if (self.ruleId != compareModel.ruleId ||
        [self.ruleName isEqualToString:compareModel.ruleName] ||
        [self.type isEqualToString:compareModel.type]) {
        return NO;
    }
    
    NSSet *keys = [NSSet setWithArray:self.params.allKeys];
    NSSet *compareKeys = [NSSet setWithArray:compareModel.params.allKeys];
    if (![keys isEqualToSet:compareKeys]) {
        return NO;
    }
    for (NSString *key in keys) {
        if (![self.params[key] isEqual:compareModel.params[key]]) {
            return NO;
        }
    }
    return YES;
}

@end
