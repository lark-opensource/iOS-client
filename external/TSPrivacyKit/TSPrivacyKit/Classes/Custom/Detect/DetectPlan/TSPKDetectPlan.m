//
//  TSPKDetectPlan.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectPlan.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKDetectTrigger.h"
#import "TSPKDetectTriggerFactory.h"
#import "TSPKLogger.h"

@interface TSPKDetectPlan ()

@property (nonatomic, strong) TSPKDetectPlanModel *model;
@property (nonatomic, strong) TSPKDetectTrigger *detectTrigger;

@end

@implementation TSPKDetectPlan

- (instancetype)initWithPlanModel:(TSPKDetectPlanModel *)planModel
{
    if (self = [super init]) {
        _model = planModel;
        [self initDetectTrigger];
    }
    return self;
}

- (void)updateWithPlanModel:(TSPKDetectPlanModel *)planModel
{
    if (planModel.ruleModel.ruleId == self.model.ruleModel.ruleId) {
        return;
    }
    
    self.model = planModel;
    if (self.detectTrigger) {
        [self.detectTrigger updateWithParams:planModel.ruleModel.params];
        self.detectTrigger.interestAPIType = self.model.interestMethodType;
    } else {
        [self initDetectTrigger];
    }
}

- (void)initDetectTrigger
{
    if (self.model == nil || self.model.ruleModel == nil) {
        return;
    }
    
    TSPKDetectTrigger *trigger = [TSPKDetectTriggerFactory detectTriggerOfDetectPlanModel:self.model];
    __weak typeof(self) weakSelf = self;
    [trigger setDetectAction:^(TSPKDetectEvent * _Nonnull event) {
        [weakSelf handleDetectTriggerWithEvent:event];
        //ALog info
        TSPKSceneRuleModel *ruleModel = event.detectPlanModel.ruleModel;
        NSString *message = [NSString stringWithFormat:@"detection execute, rule:%@ id:%zd params:%@", ruleModel.ruleName, ruleModel.ruleId, ruleModel.params];
        [TSPKLogger logWithTag:TSPKLogCommonTag message:message];
    }];
    self.detectTrigger = trigger;
}


- (void)handleDetectTriggerWithEvent:(TSPKDetectEvent *)event
{
    event.detectPlanModel = self.model;
    [self.delegate handleDetectEvent:event];
}

@end
