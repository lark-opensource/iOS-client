//
//  TSPKDetectPlanModel.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectPlanModel.h"

#import "TSPrivacyKitConstants.h"

@implementation TSPKDetectPlanModel

- (NSString *_Nonnull)planUid
{
    return [NSString stringWithFormat:@"%@-%@-%@", self.interestMethodType, @(self.ruleModel.ruleId), self.ruleModel.ruleName];
}

- (TSPKDetectTriggerType)triggerType
{
    NSString *ruleType = self.ruleModel.type;
    if ([ruleType isEqualToString:TSPKRuleTypeAdvanceAppStatusTrigger]) {
        return TSPKDetectTriggerTypeAdvanceAppStatus;
    } else if ([ruleType isEqualToString:TSPKRuleTypePageStatusTrigger]) {
        return TSPKDetectTriggerTypePageStatus;
    }
    return TSPKDetectTriggerTypeNone;
}

@end
