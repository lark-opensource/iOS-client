//
//  TSPKTimeCacheStrategy.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/29.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheUpdateStrategy.h"
#import "TSPKCacheStrategyGenerator.h"

@interface TSPKTimeCacheStrategy : NSObject<TSPKCacheUpdateStrategy, TSPKCacheStrategyGenerator>

+ (nonnull instancetype)initWithDuration:(NSInteger)duration;

@end
