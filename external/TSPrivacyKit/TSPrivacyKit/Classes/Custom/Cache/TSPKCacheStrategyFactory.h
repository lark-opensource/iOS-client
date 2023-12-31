//
//  TSPKCacheStrategyFactory.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/8.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheUpdateStrategy.h"

@interface TSPKCacheStrategyFactory : NSObject

+ (nullable id<TSPKCacheUpdateStrategy>)getStrategy:(nullable NSString *)name params:(nullable NSDictionary *)params;

+ (void)addStrategy:(id<TSPKCacheUpdateStrategy> _Nullable)strategy withKey:(NSString *_Nullable)key;

@end
