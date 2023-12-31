//
//  TSPKCacheProcessor.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/28.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheStore.h"
#import "TSPKCacheUpdateStrategy.h"

@interface TSPKCacheProcessor : NSObject

+ (nullable instancetype)initWithStrategy:(nullable id<TSPKCacheUpdateStrategy>)strategy store:(nullable id<TSPKCacheStore>)store;

- (BOOL)needUpdate:(nullable NSString *)key;
- (nullable id)get:(nullable NSString *)key;
- (void)updateCache:(nullable NSString *)key newValue:(nullable id)value;

@end
