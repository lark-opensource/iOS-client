//
//  BDRuleEngineSettings.h
//  Indexer
//
//  Created by WangKun on 2021/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineSettings : NSObject
/// 是否开启埋点上报
+ (BOOL)enableAppLog;
/// 是否开启策略引擎
+ (BOOL)enableRuleEngine;
/// 是否开启表达式预解析
+ (BOOL)enablePrecacheCel;
/// 是否开启策略选取缓存
+ (BOOL)enableCacheSelectStrategy;
/// 是否开启指令队列
+ (BOOL)enableInstructionList;
/// 是否开启快速执行
+ (BOOL)enableQuickExecutor;
/// 是否是开启FFF策略选取算法
+ (BOOL)enableFFF;
/// 全局采样率
+ (NSDictionary *)globalSampleRate;
/// 表达式解析缓存大小
+ (NSUInteger)expressionCacheSize;
/// 本地日志等级
+ (NSUInteger)localLogLevel;
@end

NS_ASSUME_NONNULL_END
