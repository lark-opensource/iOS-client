//
//  TSPKRuleExecuteResultModel.m
//  Aweme
//
//  Created by ByteDance on 2022/9/28.
//

#import "TSPKRuleExecuteResultModel.h"
#import "TSPKRuleEngineSubscriber.h"
#import <BytedanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKSingleRuleExecuteResultModel

@end

@implementation TSPKRuleExecuteResultModel

- (BOOL)isCompliant
{
    BOOL isCompliant = YES;
    for (TSPKSingleRuleExecuteResultModel *singleResult in _hitRules) {
        NSString *action = [singleResult.config btd_stringValueForKey:@"action"];
        if ([action isEqualToString:TSPKRuleEngineActionReport] || [action isEqualToString:TSPKRuleEngineActionFuse] || [action isEqualToString:TSPKRuleEngineActionDowngrade]) {
            isCompliant = NO;
            break;
        }
    }
    return isCompliant;
}
@end
