//
//  BDStrategyStore.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

#import "BDRuleGroupModel.h"
#import "BDREDiGraph.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyStore : NSObject

/// 预处理策略 表达式指令队列解析与存储
/// @param strategy dict which is a strategy from a provider
- (void)preprocessStrategy:(nonnull NSDictionary *)strategy;

/// 加载策略 解析后立刻生效
/// @param strategy dict which is a strategy from a provider
- (void)loadStrategy:(nonnull NSDictionary *)strategy;

- (BOOL)strategySelectBreakInSet:(NSString *)setName;

- (BOOL)ruleExecBreakInSet:(NSString *)setName;

- (nullable NSArray *)strategyMapKeysInSet:(NSString *)setName;

- (nullable BDRuleGroupModel *)strategyMapRuleInSet:(NSString *)setName;

- (nullable BDREDiGraph *)strategyMapGraphInSet:(NSString *)setName;

- (nullable BDRuleGroupModel *)strategyRuleWithName:(NSString *)name inSet:(NSString *)setName;

- (NSDictionary *)jsonFormat;

- (nullable NSString *)signature;

@end

NS_ASSUME_NONNULL_END
