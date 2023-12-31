//Copyright © 2021 Bytedance. All rights reserved.

#import "TSPKCustomAnchorReleaseDetectManager.h"
#import "TSPKUtils.h"
#import "TSPKCustomAnchorModel.h"
#import "TSPKEvent.h"
#import "TSPKDetectManager.h"
#import "TSPKDetectEvent.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "TSPKThreadPool.h"
#import "TSPKLogger.h"
#import "TSPKDelayDetectSchduler.h"
#import "TSPrivacyKitConstants.h"

@interface TSPKCustomAnchorReleaseDetectManager() <TSPKDelayDetectDelegate>

@property (nonatomic, strong) NSMutableArray <TSPKCustomAnchorModel *> *startModels;
@property (nonatomic, strong) NSMutableArray <TSPKCustomAnchorModel *> *stopModels;
@property (nonatomic, assign) NSUInteger resourceCount;
@property (nonatomic, copy) NSString *pipelineType;
@property (nonatomic, strong) TSPKDelayDetectSchduler *delayScheduler;
@property (nonatomic, assign) NSInteger detectTime;

@end

@implementation TSPKCustomAnchorReleaseDetectManager

- (instancetype)initWithPipelineType:(NSString *)pipelineType
                           detectDelay:(NSTimeInterval)detectDelay
                            detectTime:(NSInteger)detectTime {
    self = [super init];
    if (self) {
        self.pipelineType = pipelineType;
        self.startModels = [NSMutableArray array];
        self.stopModels = [NSMutableArray array];
        self.resourceCount = 0;
        self.detectTime = detectTime;
        TSPKDelayDetectModel *delayDetectModel = [TSPKDelayDetectModel new];
        delayDetectModel.detectTimeDelay = detectDelay;
        delayDetectModel.isAnchorPageCheck = YES;
        delayDetectModel.isCancelPrevDetectWhenStartNewDetect = YES;
        
        self.delayScheduler = [[TSPKDelayDetectSchduler alloc] initWithDelayDetectModel:delayDetectModel delegate:self];
    }

    return self;
}

#pragma mark - timer

- (void)scheduleDetectAction {
    [self.delayScheduler startDelayDetect];
}

- (void)cancelDetectAction {
    [self.delayScheduler stopDelayDetect];
}

#pragma mark - public method

- (void)markResourceStartWithCaseId:(NSString *)caseId description:(NSString *)description {
    [TSPKUtils exectuteOnMainThread:^{
        self.resourceCount += 1;
        
        [self cancelDetectAction];
        
        [self removeModelFrom:self.startModels caseId:caseId];
        
        TSPKCustomAnchorModel *model = [TSPKCustomAnchorModel new];
        model.caseId = caseId;
        model.caseDesc = description;
        model.topPageName = [TSPKUtils topVCName];
        [self.startModels addObject:model];
        
        [TSPKLogger logWithTag:TSPKLogCustomAnchorCheckTag message:[NSString stringWithFormat:@"markResourceStart %@ caseId:%@ topPageName:%@ resourceCount:%@", self.pipelineType, caseId, model.topPageName, @(self.resourceCount)]];
    }];
}

- (void)markResourceStopWithCaseId:(NSString *)caseId description:(NSString *)description {
    [TSPKUtils exectuteOnMainThread:^{
        if (self.resourceCount > 0) {
            self.resourceCount -= 1;
        }
        
        if (self.resourceCount == 0) {
            [self scheduleDetectAction];
        }
        
        [self removeModelFrom:self.stopModels caseId:caseId];
        
        TSPKCustomAnchorModel *model = [TSPKCustomAnchorModel new];
        model.caseId = caseId;
        model.caseDesc = description;
        model.topPageName = [TSPKUtils topVCName];
        [self.stopModels addObject:model];
        
        [TSPKLogger logWithTag:TSPKLogCustomAnchorCheckTag message:[NSString stringWithFormat:@"markResourceStop %@ caseId:%@ topPageName:%@ resourceCount:%@", self.pipelineType, caseId, model.topPageName, @(self.resourceCount)]];
    }];
}

#pragma mark - TSPKDelayDetectDelegate

- (nullable NSString *)getComparePage {
    return self.stopModels.lastObject.topPageName;
}

- (void)executeDetectWithActualTimeGap:(NSTimeInterval)actualTimeGap {
    TSPKDetectCondition *condition = [TSPKDetectCondition new];
    
    TSPKDetectPlanModel *plan = [TSPKDetectPlanModel new];
    plan.taskType = TSPKDetectTaskTypeDetectReleaseBadCase;
    plan.interestMethodType = self.pipelineType;
    
    // add detect params for custom anchor, adapt to delay close logic
    TSPKSceneRuleModel *ruleModel = [TSPKSceneRuleModel new];
    ruleModel.params = @{@"detectTime" : @(self.detectTime), @"timeDelay" : @(self.delayScheduler.timeDelay)};
    plan.ruleModel = ruleModel;
    
    TSPKEventData *eventData = [TSPKEventData new];
    
    // add stop info to eventData
    TSPKCustomAnchorModel *stopModel = self.stopModels.lastObject;
    eventData.customAnchorCaseId = stopModel.caseId;
    eventData.customAnchorStopTopPage = stopModel.topPageName;
    eventData.customAnchorStopDesc = stopModel.caseDesc;
    
    // add start info to eventData
    TSPKCustomAnchorModel *startModel;
    for (TSPKCustomAnchorModel *model in self.startModels) {
        if ([model.caseId isEqualToString:stopModel.caseId]) {
            startModel = model;
            break;
        }
    }
    if (startModel) {
        eventData.customAnchorStartTopPage = startModel.topPageName;
        eventData.customAnchorStartDesc = startModel.caseDesc;
    }
    // execute detect
    TSPKDetectEvent *detectEvent = [TSPKDetectEvent new];
    detectEvent.condition = condition;
    detectEvent.detectPlanModel = plan;
    detectEvent.eventData = eventData;
    [[TSPKDetectManager sharedManager] handleDetectEvent:detectEvent];
    
    // remove model
    [self removeModelFrom:self.startModels caseId:stopModel.caseId];
    [self removeModelFrom:self.stopModels caseId:stopModel.caseId];
    
    [TSPKLogger logWithTag:TSPKLogCustomAnchorCheckTag message:[NSString stringWithFormat:@"Monitor execute detect, permissionType:%@ caseId:%@", self.pipelineType, stopModel.caseId]];
}

- (BOOL)isContinueExecuteAction {
    return (self.resourceCount == 0 && self.stopModels.count > 0);
}

#pragma mark - utils

- (void)removeModelFrom:(NSMutableArray <TSPKCustomAnchorModel *> *)models caseId:(NSString *)caseId {
    __block NSInteger repeatModelIndex = -1;
    [models enumerateObjectsUsingBlock:^(TSPKCustomAnchorModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.caseId isEqualToString:caseId]) {
            repeatModelIndex = idx;
            *stop = YES;
        }
    }];
    
    if (repeatModelIndex >= 0) {
        [models removeObjectAtIndex:repeatModelIndex];
    }
}

@end
