//
//  TSPKDetectManager.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import "TSPKDetectManager.h"
#import "TSPKLock.h"
#import "TSPKDetectPlan.h"
#import "TSPKDetectPlanModel.h"
#import "TSPKDetectTaskFactory.h"
#import "TSPKThreadPool.h"
#import "TSPKEventManager.h"
#import "TSPKEvent.h"
#import "TSPKUtils.h"
#import "TSPKAspectModel.h"
#import "TSPKConfigs.h"
#import "TSPKDetectPipeline.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface TSPKDetectManager ()<TSPKDetectPlanDelegate, TSPKDetectTaskProtocol>
{
    id<TSPKLock> _lock;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, TSPKDetectTask *> *taskPool;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TSPKDetectPlan *> *allPlans;
@property (nonatomic, strong) NSMutableDictionary *detectorConfigs;
@property (nonatomic, strong) NSMutableDictionary *rules;

@end

@implementation TSPKDetectManager

+ (instancetype)sharedManager
{
    static TSPKDetectManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKDetectManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _taskPool = [NSMutableDictionary dictionary];
        _allPlans = [NSMutableDictionary dictionary];
        _context = [TSPKContext new];
        _detectorConfigs = [NSMutableDictionary dictionary];
        _rules = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerDetectPlan:(TSPKDetectPlanModel *)planModel
{
    NSString *planUid = planModel.planUid;
    
    if (_allPlans[planUid] != nil) {
        return;
    }
    
    TSPKDetectPlan *newPlan = [[TSPKDetectPlan alloc] initWithPlanModel:planModel];
    newPlan.delegate = self;
    [_lock lock];
    _allPlans[planUid] = newPlan;
    [_lock unlock];
}

- (void)unregisterAllDetectPlans {
    [_lock lock];
    [_allPlans enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TSPKDetectPlan * _Nonnull plan, BOOL * _Nonnull stop) {
        plan.delegate = nil;
    }];
    [_allPlans removeAllObjects];
    [_lock unlock];
}

#pragma mark -
- (void)handleDetectEvent:(TSPKDetectEvent *)detectEvent
{    
    if (![self shouldHandleDetectEvent:detectEvent]) {
        return;
    }
    
    TSPKDetectTask *task = [TSPKDetectTaskFactory taskOfType:detectEvent.taskType event:detectEvent];
    task.context = self.context;
    task.delegate = self;
    // fix misreport when app enter forground and open auido before task execute
    NSTimeInterval scheduleTimeStamp = [TSPKUtils getRelativeTime];
    if (task.onCurrentThread) {
        [task executeWithScheduleTime:scheduleTimeStamp];
        dispatch_async([[TSPKThreadPool shardPool] workQueue], ^{
            [self addDetetTaskToPool:task];
        });
        return;
    } else {
        dispatch_async([[TSPKThreadPool shardPool] workQueue], ^{
            [task executeWithScheduleTime:scheduleTimeStamp];
            [self addDetetTaskToPool:task];
        });
    }
}

- (BOOL)shouldHandleDetectEvent:(TSPKDetectEvent *)detectEvent
{
    NSMutableSet *ruleIgnoreCondition = detectEvent.detectPlanModel.ruleModel.ruleIgnoreCondition.mutableCopy;
    if ([ruleIgnoreCondition count] == 0) {
        return YES;
    }
    NSSet *contextSymbols = [self.context contextSymbolsForApiType:detectEvent.detectPlanModel.interestMethodType];
    
    [ruleIgnoreCondition intersectSet:contextSymbols];
    
    BOOL shouldHandle = (ruleIgnoreCondition.count == 0);
    
    [self dispatchWithDetectEvent:detectEvent
                   ignoreContexts:[ruleIgnoreCondition allObjects]
                         isIgnore:!shouldHandle];
    
    return shouldHandle;
}

#pragma mark - TSPKDetectTaskProtocol
- (void)detectTaskDidFinsh:(TSPKDetectTask *)detectTask
{
    dispatch_async([[TSPKThreadPool shardPool] workQueue], ^{
        [self removeTaskFromPool:detectTask];
    });
}

- (void)addDetetTaskToPool:(TSPKDetectTask *)detectTask
{
    if (detectTask == nil) {
        return;
    }
    
    NSString *taskId = [NSString stringWithFormat:@"%p", detectTask];
    self.taskPool[taskId] = detectTask;
}

- (void)removeTaskFromPool:(TSPKDetectTask *)detectTask
{
    if (detectTask == nil) {
        return;
    }
    
    NSString *taskId = [NSString stringWithFormat:@"%p", detectTask];
    self.taskPool[taskId] = nil;
}

#pragma mark - other

- (void)dispatchWithDetectEvent:(TSPKDetectEvent *)detectEvent
                 ignoreContexts:(NSArray <NSString*> *)ignoreContexts
                isIgnore:(BOOL)isIgnore
{
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeIgnoreDetect;
    
    event.ignoreSymbolContexts = ignoreContexts;
    event.methodType = detectEvent.detectPlanModel.interestMethodType;
    event.ruleId = detectEvent.detectPlanModel.ruleModel.ruleId;
    event.isIgnore = isIgnore;

    [TSPKEventManager dispatchEvent:event];
}

#pragma mark - plan & pipeline

+ (NSArray<TSPKDetectPlanModel *> *_Nullable)createPlanModelsWithAspectInfo:(TSPKAspectModel *_Nullable)aspectInfo
{
    return [self createPlanModelsWithPipelineType:aspectInfo.pipelineType detectType:aspectInfo.detector dataType:aspectInfo.dataType];
}

+ (NSArray<TSPKDetectPlanModel *> *_Nullable)createPlanModelsWithPipeline:(TSPKDetectPipeline *_Nullable)pipeline
{
    NSString *apiType = [[pipeline class] pipelineType];
    NSString *detectType = [NSString stringWithFormat:@"%@Detector", apiType];
    return [self createPlanModelsWithPipelineType:apiType detectType:detectType dataType:[[pipeline class] dataType]];
}

+ (NSArray<TSPKDetectPlanModel *> *_Nullable)createPlanModelsWithPipelineType:(NSString *)pipelineType detectType:(NSString *)detectType dataType:(NSString *)dataType {
    if ([detectType length] == 0) {
        return nil;
    }
    
    if ([dataType length] == 0) {
        return nil;
    }
    
    NSArray *ruleArray = [[TSPKDetectManager sharedManager].detectorConfigs btd_arrayValueForKey:detectType];
    if ([ruleArray count] == 0) {
        return nil;
    }
    
    NSMutableArray *planArrays = [NSMutableArray array];
    for (id ruleObj in ruleArray) {
        if (![ruleObj isKindOfClass:[TSPKSceneRuleModel class]]) {
            continue;
        }
        TSPKSceneRuleModel *ruleModel = (TSPKSceneRuleModel *)ruleObj;
        if ([ruleModel.type length] == 0) {
            continue;
        }
        
        TSPKDetectPlanModel *planModel = [TSPKDetectPlanModel new];
        planModel.interestMethodType = pipelineType;
        planModel.taskType = [[[self ruleTypeToTaskType] objectForKey:ruleModel.type] intValue];
        planModel.ruleModel = ruleModel;
        planModel.dataType = dataType;
        
        [planArrays addObject:planModel];
    }
    return [NSArray arrayWithArray:planArrays];
}

- (void)setupPlan:(TSPKDetectPipeline *)pipeline {
    NSArray<TSPKDetectPlanModel *> *allPlans = [TSPKDetectManager createPlanModelsWithPipeline:pipeline];
    for (TSPKDetectPlanModel *plan in allPlans) {
        [self registerDetectPlan:plan];
    }
}

- (void)setupRules {
    for (NSDictionary *jsonDict in [[TSPKConfigs sharedConfig] ruleConfigs]) {
        TSPKSceneRuleModel *ruleModel = [TSPKSceneRuleModel createWithDictionary:jsonDict];
        if (ruleModel.ruleId > 0) {
            _rules[@(ruleModel.ruleId)] = ruleModel;
        }
    }
}

- (void)generateSceneRuleModelList {
    NSDictionary *configs = [[TSPKConfigs sharedConfig] detectorConfigs];
    if (configs) {
        for (NSString *key in configs) {
            NSArray *attachedRuleIds = [configs btd_arrayValueForKey:key];
            if (![attachedRuleIds isKindOfClass:[NSArray class]]) {
                NSAssert(false, @"monitor config is not correct.");
                continue;
            }

            NSMutableArray *attachedRules = [NSMutableArray new];
            for (NSNumber *ruleId in attachedRuleIds) {
                if ([ruleId integerValue] > 0 && _rules[ruleId] != nil) {
                    [attachedRules btd_addObject:_rules[ruleId]];
                }
            }
            _detectorConfigs[key] = attachedRules;
        }
    }
}

+ (NSDictionary<NSString *, NSNumber *> *_Nullable)ruleTypeToTaskType
{
    return @{
        TSPKRuleTypeAdvanceAppStatusTrigger: @(TSPKDetectTaskTypeDetectReleaseBadCase),
        TSPKRuleTypePageStatusTrigger: @(TSPKDetectTaskTypeDetectReleaseBadCase)
    };
}

@end
