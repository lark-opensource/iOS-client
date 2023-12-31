//
//  BDStrategySelectCacheManager.h
//  Indexer
//
//  Created by WangKun on 2022/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategySelectCacheManager : NSObject

+ (nonnull NSString *)signature;

/// 缓存 ruleSetNames 结果
/// @param ruleSetNames the name of strategy
/// @param input params
/// @param filterKeys the keys in strategy_map
/// @param setName the key of strategy_set
+ (void)setRuleSetNames:(NSArray *)ruleSetNames
               forInput:(NSDictionary *)input
         withFilterKeys:(NSArray *)filterKeys
                  inSet:(NSString *)setName;

/// 获取 ruleSetNames 结果
/// @param input params
/// @param filterKeys the keys in strategy_map
/// @param setName the key of strategy_set
+ (NSArray *)ruleSetNamesForInput:(NSDictionary *)input
                   withFilterKeys:(nullable NSArray *)filterKeys
                            inSet:(NSString *)setName;

/// 加载并更新策略选取缓存
/// @param md5Map dict for [ setName : rule_md5 ]
+ (void)loadStrategySelectCacheWithMD5Map:(nonnull NSDictionary *)md5Map signature:(nonnull NSString *)signature;

/// 加载策略选取缓存
+ (void)loadStrategySelectCache;

@end

NS_ASSUME_NONNULL_END
