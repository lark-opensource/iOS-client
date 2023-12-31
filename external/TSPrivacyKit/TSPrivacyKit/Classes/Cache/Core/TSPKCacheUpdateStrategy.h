//
//  TSPKCacheUpdateStrategy.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/28.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheStore.h"

@protocol TSPKCacheUpdateStrategy <NSObject>

- (BOOL)needUpdate:(nullable NSString *)key cacheStore:(nullable id<TSPKCacheStore>)store;

@end
