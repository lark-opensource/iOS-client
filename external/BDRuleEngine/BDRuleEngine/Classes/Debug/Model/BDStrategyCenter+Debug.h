//
//  BDStrategyCenter+Debug.h
//  BDRuleEngine
//
//  Created by WangKun on 2022/1/4.
//

#import "BDStrategyCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyCenter (Debug)
+ (NSArray<id<BDStrategyProvider>>*)providers;
+ (NSDictionary *)mergedStrategies;
@end

NS_ASSUME_NONNULL_END
