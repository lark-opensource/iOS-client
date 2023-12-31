//
//  LKRuleEngineReporter.h
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LKRuleEngineReporter <NSObject>

/// 策略引擎自定义埋点，包含 appLog & 端监控，内部有采样和控制逻辑
/// @param event 事件名称
/// @param metric 测量指标
/// @param category 维度信息
- (void)log:(NSString *)event
     metric:(NSDictionary<NSString *, id> *)metric
   category:(NSDictionary<NSString *, id> *)category;

@end

@interface LKRuleEngineReporter : NSObject<LKRuleEngineReporter>

+ (instancetype)sharedInstance;
/// strong reference for reporter
+ (void)registerReporter:(id<LKRuleEngineReporter>)reporter;

@end

NS_ASSUME_NONNULL_END
