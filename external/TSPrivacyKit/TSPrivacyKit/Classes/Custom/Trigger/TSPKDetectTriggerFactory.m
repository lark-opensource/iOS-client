//
//  TSPKDetectTriggerFactory.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectTriggerFactory.h"

#import "TSPKPageStatusTrigger.h"
#import "TSPKAdvanceAppStatusTrigger.h"

@implementation TSPKDetectTriggerFactory

+ (TSPKDetectTrigger * _Nullable)detectTriggerOfDetectPlanModel:(TSPKDetectPlanModel * _Nonnull)planModel
{
    TSPKDetectTriggerType type = planModel.triggerType;
    NSDictionary *params = planModel.ruleModel.params;
    NSString *interestMethod = planModel.interestMethodType;

    NSDictionary *dict = @{
        @(TSPKDetectTriggerTypePageStatus) : [TSPKPageStatusTrigger class],
        @(TSPKDetectTriggerTypeAdvanceAppStatus) : [TSPKAdvanceAppStatusTrigger class]
    };
    
    if (dict[@(type)] == nil) {
        return nil;
    }
    
    Class className = (Class)dict[@(type)];
    TSPKDetectTrigger *unit = [[className alloc] initWithParams:params apiType:interestMethod];
    if ([unit isKindOfClass:[TSPKDetectTrigger class]]) {
        return unit;
    }
    return nil;
}

@end
