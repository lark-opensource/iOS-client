//
//  TSPKDetectManager.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectPlan.h"
#import "TSPKContext.h"

@class TSPKAspectModel;
@class TSPKDetectPipeline;

@interface TSPKDetectManager : NSObject

@property (nonatomic, strong, nullable) TSPKContext * context;

+ (nullable instancetype)sharedManager;

- (void)registerDetectPlan:(nullable TSPKDetectPlanModel *)planModel;
- (void)unregisterAllDetectPlans;
- (void)handleDetectEvent:(nonnull TSPKDetectEvent *)detectEvent;

- (void)setupRules;
- (void)generateSceneRuleModelList;
- (void)setupPlan:(TSPKDetectPipeline *_Nullable)pipeline;

+ (NSArray<TSPKDetectPlanModel *> *_Nullable)createPlanModelsWithAspectInfo:(TSPKAspectModel *_Nullable)aspectInfo;
+ (NSArray<TSPKDetectPlanModel *> *_Nullable)createPlanModelsWithPipeline:(TSPKDetectPipeline *_Nullable)pipeline;
+ (NSDictionary<NSString *, NSNumber *> *_Nullable)ruleTypeToTaskType;

@end

