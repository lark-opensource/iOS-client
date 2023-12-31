//
//  BDRuleEngineReporter.h
//  Indexer
//
//  Created by WangKun on 2021/12/20.
//

#import <Foundation/Foundation.h>

#import "BDRuleEngineDelegate.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BDRELogNameStrategyExecute;
FOUNDATION_EXPORT NSString * const BDRELogNameStrategyGenerate;
FOUNDATION_EXPORT NSString * const BDRELogNameExpressionExecute;
FOUNDATION_EXPORT NSString * const BDRELogNameRulerStart;
FOUNDATION_EXPORT NSString * const BDRELogNameExpressionExecuteAbnormal;

FOUNDATION_EXPORT NSString * const BDRELogSampleTagSourceKey;
FOUNDATION_EXPORT NSString * const BDRELogStartEventSourceValue;
FOUNDATION_EXPORT NSString * const BDRELogExprExecEventSourceValue;
FOUNDATION_EXPORT NSString * const BDRElogExprExecErrorSourceValue;
FOUNDATION_EXPORT NSString * const BDRELogStartEventDelayTimeKey;

@interface BDREReportContent : NSObject<BDRuleEngineReportDataSource>

- (instancetype)initWithMetric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface BDRuleEngineReporter : NSObject

/// 策略引擎自定义埋点
/// 包含 appLog & 端监控，内部有采样和控制逻辑
/// @param event 事件名称
/// @param tags 事件标记（用于采样）
/// @param block 参数获取闭包
+ (void)log:(nonnull NSString *)event
       tags:(nullable NSDictionary *)tags
      block:(nonnull BDRuleEngineReportDataBlock)block;

/// 默认延迟 5s 上报
+ (void)delayLog:(nonnull NSString *)event
            tags:(nullable NSDictionary *)tags
           block:(nonnull BDRuleEngineReportDataBlock)block;

@end

NS_ASSUME_NONNULL_END
