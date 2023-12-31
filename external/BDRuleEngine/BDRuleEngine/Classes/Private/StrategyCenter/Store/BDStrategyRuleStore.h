//
//  BDStrategyRuleStore.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

#import "BDRuleGroupModel.h"
#import "BDREDiGraph.h"

@interface BDStrategyRuleStore : NSObject

- (void)updateStrategies:(nonnull NSDictionary *)strategies;

- (void)loadCommandsAndEnableExecutor:(BOOL)enable;

- (void)loadStrategySelectGraph;

- (BOOL)strategySelectBreak;

- (BOOL)ruleExecBreak;

- (nullable BDRuleGroupModel *)strategyMapRule;

- (nullable BDREDiGraph *)strategyMapGraph;

- (nullable BDRuleGroupModel *)strategyRuleWithName:(nonnull NSString *)name;

- (nonnull NSDictionary *)jsonFormat;

@end
