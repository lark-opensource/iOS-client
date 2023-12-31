//
//  BDPAppController+ExitMonitorStrategy.h
//  Timor
//
//  Created by changrong on 2020/10/9.
//

#import <Foundation/Foundation.h>
#import "BDPAppController.h"

NS_ASSUME_NONNULL_BEGIN

@class StrategyService;
@class StrategyParam;

@interface BDPAppController(ExitMonitorStrategy)
/// 白屏探测的策略配置
@property (nonatomic, readonly) StrategyService *exitMonitorStrategy;

/// 当前task已经被判定白屏的次数
@property (nonatomic, readonly) NSInteger blankCount;

/// 根据规则引擎的参数判断是否需要清理热缓存，处理非正常启动的场景
- (BOOL)isCleanWarmCache:(NSArray<StrategyParam *> *)param withError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
